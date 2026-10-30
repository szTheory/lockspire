"""Private, one-use startup booleans bound to an owned listener VM."""
from __future__ import annotations

import os
from pathlib import Path
import re
import secrets
import shutil
import stat

from package_input import PackageInputError, _OWNED_IDENTITIES, owned_session_state

_CHANNELS = {}
_PAYLOAD = re.compile(
    rb"lockspire-startup-v1\nnonce=([0-9a-f]{64})\npid=([1-9][0-9]{0,19})\n"
    rb"context_valid=(true|false)\nprotecting_key=(true|false)\n"
)


def _logical(path):
    value = Path(path)
    return value.parent.resolve(strict=True) / value.name


class StartupWitness:
    def __init__(self, path, environment):
        self.path = _logical(path)
        parent = self.path.parent.stat()
        if (parent.st_uid != os.getuid() or parent.st_mode & 0o077
                or self.path.exists() or self.path.is_symlink() or self.path in _CHANNELS):
            raise PackageInputError("startup witness ownership is unavailable")
        self.nonce = secrets.token_hex(32)
        self.directory = self.path.parent / (".startup-" + self.nonce)
        self.directory.mkdir(mode=0o700)
        info = self.directory.stat()
        self.directory_identity = (info.st_dev, info.st_ino)
        self.payload = self.directory / "witness"
        self.process = self.identity = None
        self.consumed = False
        environment["LOCKSPIRE_RECOVERY_STARTUP_DIRECTORY"] = str(self.directory)
        environment["LOCKSPIRE_RECOVERY_STARTUP_NONCE"] = self.nonce
        _CHANNELS[self.path] = self

    def bind(self, process):
        identity = _OWNED_IDENTITIES.get(process.pid)
        if identity is None or owned_session_state(identity) != "owned":
            raise PackageInputError("startup witness listener ownership is unavailable")
        self.process, self.identity = process, identity

    def published(self):
        return self.payload.exists() or self.payload.is_symlink()

    def consume(self):
        if (self.consumed or self.process is None or self.process.poll() is not None
                or owned_session_state(self.identity) != "owned"):
            raise PackageInputError("startup witness listener is stale or unavailable")
        try:
            descriptor = os.open(self.payload, os.O_RDONLY | os.O_NOFOLLOW)
            with os.fdopen(descriptor, "rb") as stream:
                info = os.fstat(stream.fileno())
                if (not stat.S_ISREG(info.st_mode) or info.st_uid != os.getuid()
                        or info.st_mode & 0o077 or not 0 < info.st_size <= 256):
                    raise ValueError
                raw = stream.read(257)
            match = _PAYLOAD.fullmatch(raw)
            if (match is None or match[1].decode("ascii") != self.nonce
                    or match[2].decode("ascii") != str(self.process.pid)):
                raise ValueError
            current = self.payload.lstat()
            if (current.st_dev, current.st_ino) != (info.st_dev, info.st_ino):
                raise ValueError
            result = (match[3] == b"true", match[4] == b"true")
            self.payload.unlink()
            self.consumed = True
            return result
        except (OSError, ValueError):
            raise PackageInputError("startup witness is unavailable or invalid") from None

    def close(self):
        info = self.directory.lstat()
        if (not stat.S_ISDIR(info.st_mode)
                or (info.st_dev, info.st_ino) != self.directory_identity):
            raise PackageInputError("startup witness cleanup ownership is unavailable")
        shutil.rmtree(self.directory)
        if _CHANNELS.get(self.path) is self:
            _CHANNELS.pop(self.path)


def consume(path):
    try:
        selected = _CHANNELS.get(_logical(path))
    except OSError:
        selected = None
    if selected is None:
        raise PackageInputError("owned startup witness context is required")
    return selected.consume()
