#!/usr/bin/env python3
"""Build and audit the local package input for the clean-room acceptance lab."""

from __future__ import annotations

import argparse
import atexit
from dataclasses import dataclass
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import signal
import socket
import struct
import subprocess
import sys
import tempfile
import time
from typing import Iterable, Sequence
from urllib.parse import quote
import uuid


PROJECT_ROOT = Path(__file__).resolve().parents[3]
TEMPLATE_ROOT = PROJECT_ROOT / "test" / "clean_room"
ROLES = ("provider_host", "confidential_client")


class PackageInputError(RuntimeError):
    pass


_OWNED_SESSIONS: dict[int, subprocess.Popen] = {}
_OWNED_IDENTITIES: dict[int, OwnedSessionIdentity] = {}
_SESSION_SIGNAL_HANDLERS_INSTALLED = False
_SESSION_REGISTRY_ENV = "LOCKSPIRE_OWNED_SESSION_REGISTRY"
_SESSION_SOCKET_ENV = "LOCKSPIRE_OWNED_SESSION_SOCKET"
_SESSION_LAUNCHING = False
_SESSION_PENDING_SIGNAL: tuple[int, object] | None = None
_SESSION_STOPPING = False


@dataclass(frozen=True)
class OwnedSessionIdentity:
    pid: int
    parent_pid: int
    pgid: int
    sid: int
    start: tuple[int, ...]

    def same_process(self, other: OwnedSessionIdentity) -> bool:
        # Reparenting does not revoke an already authenticated child's custody.
        return (self.pid, self.pgid, self.sid, self.start) == (other.pid, other.pgid, other.sid, other.start)

    def safe_record(self) -> dict:
        return {"pid": self.pid, "parent_pid": self.parent_pid, "pgid": self.pgid,
                "sid": self.sid, "start": list(self.start)}


def owned_process_identity(pid: int) -> OwnedSessionIdentity:
    """Read one exact PID's kernel parent/session/creation identity, never argv."""
    if type(pid) is not int or pid <= 1:
        raise PackageInputError("owned process identity is invalid")
    if sys.platform == "linux":
        try:
            raw = (Path("/proc") / str(pid) / "stat").read_bytes()
        except FileNotFoundError:
            raise ProcessLookupError from None
        fields = raw.rsplit(b")", 1)[1].split()
        return OwnedSessionIdentity(pid, int(fields[1]), int(fields[2]), int(fields[3]), (int(fields[19]),))
    if sys.platform == "darwin":
        import ctypes
        import errno

        class BSDInfo(ctypes.Structure):
            _fields_ = [(name, ctypes.c_uint32) for name in (
                "flags", "status", "xstatus", "pid", "ppid", "uid", "gid", "ruid", "rgid", "svuid", "svgid", "reserved"
            )] + [("comm", ctypes.c_char * 16), ("name", ctypes.c_char * 32)] + [
                (name, ctypes.c_uint32) for name in ("nfiles", "pgid", "jobc", "tdev", "tpgid", "nice")
            ] + [("start_sec", ctypes.c_uint64), ("start_usec", ctypes.c_uint64)]

        library = ctypes.CDLL("/usr/lib/libSystem.B.dylib", use_errno=True)
        library.proc_pidinfo.argtypes = [ctypes.c_int, ctypes.c_int, ctypes.c_uint64, ctypes.c_void_p, ctypes.c_int]
        library.proc_pidinfo.restype = ctypes.c_int
        info = BSDInfo()
        size = library.proc_pidinfo(pid, 3, 0, ctypes.byref(info), ctypes.sizeof(info))
        if size != ctypes.sizeof(info):
            error = ctypes.get_errno()
            if error in (errno.ESRCH, errno.ENOENT):
                raise ProcessLookupError from None
            raise PermissionError from None
        if info.pid != pid:
            raise PackageInputError("owned process identity is unavailable")
        return OwnedSessionIdentity(pid, info.ppid, info.pgid, os.getsid(pid), (info.start_sec, info.start_usec))
    raise PackageInputError("authoritative process identity is unavailable")


def owned_session_state(identity: OwnedSessionIdentity) -> str:
    try:
        actual = owned_process_identity(identity.pid)
    except (OSError, PackageInputError, ValueError, IndexError):
        try:
            os.killpg(identity.pgid, 0)
        except ProcessLookupError:
            return "absent"
        except OSError:
            return "unconfirmed"
        # An absent leader with a surviving group cannot prove that a reused
        # numeric PGID still denotes our original group. Preserve custody.
        return "unconfirmed"
    return "owned" if identity.same_process(actual) else "unconfirmed"


def signal_owned_session(identity: OwnedSessionIdentity, signum: int) -> bool:
    state = owned_session_state(identity)
    if state == "absent":
        return True
    if state != "owned":
        return False
    try:
        os.killpg(identity.pgid, signum)
        return True
    except ProcessLookupError:
        return True
    except OSError:
        return False


def _signal_before_deadline(process: subprocess.Popen, identity: OwnedSessionIdentity,
                            signum: int, deadline: float) -> bool:
    while True:
        process.poll()
        if signal_owned_session(identity, signum):
            return True
        if owned_session_state(identity) != "unconfirmed" or time.monotonic() >= deadline:
            return False
        # A direct child can become a zombie between poll and the identity read.
        # Reap/recheck within the same deadline; uncertainty never grants signal
        # authority and a changed creation identity never matches the old pin.
        time.sleep(min(0.02, max(0, deadline - time.monotonic())))


def _session_request(action: str, pid: int) -> None:
    endpoint = os.environ.get(_SESSION_SOCKET_ENV)
    if endpoint is None:
        return
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
            connection.settimeout(2)
            connection.connect(endpoint)
            connection.sendall(json.dumps({"action": action, "pid": pid}).encode("ascii") + b"\n")
            response = b""
            while b"\n" not in response and len(response) < 32:
                part = connection.recv(32 - len(response))
                if not part:
                    break
                response += part
            if response != b"OK\n":
                raise PackageInputError("owned session registration was refused")
    except OSError:
        raise PackageInputError("owned session supervisor is unavailable") from None


class OwnedSessionSupervisor:
    """Helper-private kill authority; diagnostic files are output only."""

    def __init__(self, custody: Path):
        self.custody = custody
        self.endpoint = custody / "s"
        self.sessions: dict[int, OwnedSessionIdentity] = {}
        self.creators: dict[int, OwnedSessionIdentity] = {}
        self.pending: dict[int, OwnedSessionIdentity] = {}
        self.unconfirmed_roots: dict[int, int] = {}
        self.refused = False
        self.listener = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.listener.bind(str(self.endpoint))
        self.listener.listen(16)
        self.listener.setblocking(False)

    def admit_root(self, process: subprocess.Popen) -> None:
        self.unconfirmed_roots[process.pid] = os.getpid()
        identity = owned_process_identity(process.pid)
        if identity.parent_pid != os.getpid() or identity.pid != identity.pgid or identity.pid != identity.sid:
            raise PackageInputError("owned root session identity is unavailable")
        self.sessions[identity.pid] = identity
        self._record(identity)
        self.unconfirmed_roots.pop(identity.pid)

    def _record(self, identity: OwnedSessionIdentity) -> None:
        path = self.custody / f"{identity.pid}.json"
        descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC | os.O_NOFOLLOW, 0o600)
        with os.fdopen(descriptor, "w", encoding="ascii") as output:
            json.dump(identity.safe_record(), output, sort_keys=True)
            output.flush()
            os.fsync(output.fileno())

    def _descendant(self, peer: OwnedSessionIdentity) -> bool:
        for _ in range(64):
            cached = self.sessions.get(peer.pid)
            if cached is not None and cached.same_process(peer):
                return True
            if peer.parent_pid <= 1:
                return False
            peer = owned_process_identity(peer.parent_pid)
        return False

    def _peer_pid(self, connection: socket.socket) -> int:
        if sys.platform == "linux":
            pid, uid, _gid = struct.unpack("3i", connection.getsockopt(socket.SOL_SOCKET, socket.SO_PEERCRED, 12))
            if uid != os.getuid():
                raise PackageInputError("owned session peer is unavailable")
            return pid
        if sys.platform == "darwin":
            # Darwin SDK sys/un.h: SOL_LOCAL=0, LOCAL_PEERPID=2.
            return struct.unpack("i", connection.getsockopt(0, 2, 4))[0]
        raise PackageInputError("authoritative session peer is unavailable")

    def service(self) -> None:
        try:
            connection, _address = self.listener.accept()
        except BlockingIOError:
            return
        accepted = False
        with connection:
            connection.settimeout(0.2)
            try:
                peer = owned_process_identity(self._peer_pid(connection))
                packet = b""
                while b"\n" not in packet and len(packet) <= 512:
                    part = connection.recv(513 - len(packet))
                    if not part:
                        break
                    packet += part
                row = json.loads(packet)
                if (set(row) != {"action", "pid"} or type(row["pid"]) is not int
                        or row["pid"] <= 1 or not self._descendant(peer)):
                    raise PackageInputError("owned registration identity is unavailable")
                if row["action"] == "prepare" and row["pid"] == peer.pid:
                    self.pending[peer.pid] = peer
                    accepted = True
                elif row["action"] == "cancel" and row["pid"] == peer.pid:
                    pending = self.pending.get(peer.pid)
                    if pending is not None and pending.same_process(peer):
                        self.pending.pop(peer.pid)
                        accepted = True
                elif row["action"] == "register":
                    target = owned_process_identity(row["pid"])
                    pending = self.pending.get(peer.pid)
                    if (pending is None or not pending.same_process(peer)
                            or target.parent_pid != peer.pid or target.pid != target.pgid or target.pid != target.sid
                            or not target.same_process(owned_process_identity(target.pid))):
                        raise PackageInputError("owned registration ancestry is unproven")
                    self.sessions[target.pid] = target
                    self.creators[target.pid] = peer
                    self._record(target)
                    self.pending.pop(peer.pid)
                    accepted = True
                elif row["action"] == "release":
                    target = self.sessions.get(row["pid"])
                    creator = self.creators.get(row["pid"])
                    if (target is not None and creator is not None and creator.same_process(peer)
                            and owned_session_state(target) == "absent"):
                        self.sessions.pop(target.pid)
                        self.creators.pop(target.pid)
                        (self.custody / f"{target.pid}.json").unlink(missing_ok=True)
                        accepted = True
            except (OSError, PackageInputError, ValueError, TypeError, KeyError, IndexError):
                pass
            if not accepted:
                self.refused = True
            try:
                connection.sendall(b"OK\n" if accepted else b"NO\n")
            except OSError:
                self.refused = True

    def close(self) -> None:
        self.listener.close()
        self.endpoint.unlink(missing_ok=True)
        # Retained custody is reconstructed from trusted RAM. Never retain an
        # injected row as if it represented an owned process, or decode its bytes.
        expected = {f"{pid}.json" for pid in self.sessions}
        for path in self.custody.iterdir():
            if path.name not in expected:
                if path.is_dir() and not path.is_symlink():
                    shutil.rmtree(path)
                else:
                    path.unlink()
        for identity in self.sessions.values():
            self._record(identity)
        if self.pending:
            path = self.custody / "pending-launches.json"
            with path.open("x", encoding="ascii") as output:
                json.dump({"schema": "lockspire-pending-owned-launch-v1",
                           "owners": [identity.safe_record() for identity in self.pending.values()]}, output)
        if self.unconfirmed_roots:
            with (self.custody / "unconfirmed-root.json").open("x", encoding="ascii") as output:
                json.dump({"schema": "lockspire-unconfirmed-root-v1", "roots": [
                    {"pid": pid, "parent_pid": parent} for pid, parent in self.unconfirmed_roots.items()
                ]}, output)


def _register_session(process: subprocess.Popen) -> None:
    _OWNED_IDENTITIES[process.pid] = owned_process_identity(process.pid)
    _session_request("register", process.pid)


def _forget_session(process: subprocess.Popen) -> None:
    process.poll()  # Reap our direct child before accepting group absence.
    _session_request("release", process.pid)
    _OWNED_SESSIONS.pop(process.pid, None)
    _OWNED_IDENTITIES.pop(process.pid, None)


_OWNED_EXEC_GATE = """import errno,os,signal,sys
gate,status=int(sys.argv[1]),int(sys.argv[2])
os.set_inheritable(status,False)
token=os.read(gate,1)
os.close(gate)
if token!=b'1':
    os.close(status)
    os._exit(125)
try:
    for value in sys.argv[3].split(','):
        number,ignored=value.split(':')
        signal.signal(int(number),signal.SIG_IGN if ignored=='1' else signal.SIG_DFL)
    os.execvpe(sys.argv[4],sys.argv[5:],os.environ)
except OSError as error:
    os.write(status,str(error.errno or errno.EIO).encode('ascii'))
    os._exit(127)
"""


def _spawn_gated_session(command: Sequence[str], **kwargs) -> tuple[subprocess.Popen, int, int]:
    """Hold exec until admission; no preexec callback or untrusted startup code."""
    arguments = [command] if isinstance(command, (str, bytes, os.PathLike)) else list(command)
    if not arguments:
        raise ValueError("owned command is empty")
    executable = kwargs.pop("executable", None)
    if kwargs.pop("shell", False):
        executable = executable or "/bin/sh"
        arguments = [executable, "-c", *arguments]
    else:
        executable = executable or arguments[0]
    gate_read, gate_write = os.pipe()
    try:
        status_read, status_write = os.pipe()
    except BaseException:
        os.close(gate_read)
        os.close(gate_write)
        raise
    try:
        kwargs["pass_fds"] = (*kwargs.get("pass_fds", ()), gate_read, status_write)
        restored = []
        for name in ("SIGPIPE", "SIGXFZ", "SIGXFSZ"):
            number = getattr(signal, name, None)
            if number is not None:
                ignored = not kwargs.get("restore_signals", True) and signal.getsignal(number) == signal.SIG_IGN
                restored.append(f"{number}:{int(ignored)}")
        process = subprocess.Popen(
            [sys.executable, "-I", "-S", "-B", "-c", _OWNED_EXEC_GATE,
             str(gate_read), str(status_write), ",".join(restored), executable, *arguments], **kwargs,
        )
    except BaseException:
        os.close(gate_write)
        os.close(status_read)
        raise
    finally:
        os.close(gate_read)
        os.close(status_write)
    process.args = command
    return process, gate_write, status_read


def _activate_registered_session(gate: int, status: int) -> int | None:
    """Return only the trusted launcher's errno; successful exec closes status."""
    import select

    os.write(gate, b"1")
    deadline = time.monotonic() + 2
    payload = b""
    while True:
        remaining = deadline - time.monotonic()
        if remaining <= 0 or not select.select([status], [], [], remaining)[0]:
            raise PackageInputError("owned command activation could not be confirmed")
        chunk = os.read(status, 32 - len(payload))
        if not chunk:
            if not payload:
                return None
            if payload.isdigit() and 0 < int(payload) < 65536:
                return int(payload)
            raise PackageInputError("owned command activation status is invalid")
        payload += chunk
        if len(payload) >= 32:
            raise PackageInputError("owned command activation status is invalid")


def start_owned_session(command: Sequence[str], **kwargs) -> subprocess.Popen:
    """Register an isolated child session for process-tree cleanup."""
    global _SESSION_SIGNAL_HANDLERS_INSTALLED, _SESSION_LAUNCHING, _SESSION_PENDING_SIGNAL
    if kwargs.get("start_new_session", True) is not True:
        raise PackageInputError("owned child must start in an isolated session")
    if kwargs.get("preexec_fn") is not None:
        raise PackageInputError("owned session preexec callbacks are unsupported")
    kwargs["start_new_session"] = True
    if os.environ.get(_SESSION_REGISTRY_ENV):
        raise PackageInputError("caller-writable session registry is unsupported")
    endpoint = os.environ.get(_SESSION_SOCKET_ENV)
    if endpoint is not None and kwargs.get("env") is not None:
        kwargs["env"] = dict(kwargs["env"], **{_SESSION_SOCKET_ENV: endpoint})
    if not _SESSION_SIGNAL_HANDLERS_INSTALLED:
        _SESSION_SIGNAL_HANDLERS_INSTALLED = True
        for signum in (signal.SIGTERM, signal.SIGINT):
            previous = signal.getsignal(signum)
            signal.signal(signum, _owned_session_signal(previous))
        atexit.register(_exit_cleanup_owned_sessions)
    # Defer a stop during launch until durable registration is complete. Unlike
    # blocking the OS signal mask, this does not pass blocked TERM to children.
    _SESSION_LAUNCHING = True
    gate = status = None
    try:
        _session_request("prepare", os.getpid())
        try:
            process, gate, status = _spawn_gated_session(command, **kwargs)
        except OSError:
            # Popen failed before yielding a child; this reservation had no
            # activated target. Other interruptions remain fail-closed pending.
            _session_request("cancel", os.getpid())
            raise
        if not isinstance(process.pid, int):
            return process
        _OWNED_SESSIONS[process.pid] = process
        try:
            _register_session(process)
            execution_error = _activate_registered_session(gate, status)
        except (OSError, PackageInputError):
            if not stop_process_group(process):
                raise PackageInputError("owned session custody and cleanup are unconfirmed") from None
            raise PackageInputError("owned session custody could not be recorded") from None
        if execution_error is not None:
            if not stop_process_group(process):
                raise PackageInputError("owned command exec and cleanup are unconfirmed") from None
            executable = kwargs.get("executable") or (
                command if isinstance(command, (str, bytes, os.PathLike)) else command[0]
            )
            raise OSError(execution_error, os.strerror(execution_error), executable)
    finally:
        for descriptor in (gate, status):
            if descriptor is not None:
                os.close(descriptor)
        _SESSION_LAUNCHING = False
        pending, _SESSION_PENDING_SIGNAL = _SESSION_PENDING_SIGNAL, None
        if pending is not None:
            signal.getsignal(pending[0])(*pending)
    return process


def _owned_session_signal(previous):
    def handle(signum, frame):
        global _SESSION_PENDING_SIGNAL, _SESSION_STOPPING
        if _SESSION_LAUNCHING:
            _SESSION_PENDING_SIGNAL = (signum, frame)
            return
        if _SESSION_STOPPING:
            return
        _SESSION_STOPPING = True
        try:
            if not stop_all_owned_sessions():
                raise SystemExit(125)
            if callable(previous):
                previous(signum, frame)
                return
            raise SystemExit(128 + signum)
        finally:
            _SESSION_STOPPING = False
    return handle


def _exit_cleanup_owned_sessions() -> None:
    if not stop_all_owned_sessions():
        os._exit(125)


def stop_all_owned_sessions() -> bool:
    # One shared bound, rather than a separate three-second grace per child.
    processes = tuple(_OWNED_SESSIONS.values())
    started = time.monotonic()
    for process in processes:
        identity = _OWNED_IDENTITIES.get(process.pid)
        if identity is not None:
            signal_owned_session(identity, signal.SIGTERM)
    stopped = True
    for process in processes:
        if not stop_process_group(process, grace=max(0, started + 3 - time.monotonic()),
                                  _deadline=started + 5):
            stopped = False
    return stopped


@dataclass(frozen=True)
class PackageSource:
    kind: str
    value: str | None = None
    expected_sha256: str | None = None
    source_revision: str | None = None
    source_proof: str | None = None
    owner_manifest: str | None = None


@dataclass(frozen=True)
class PackageIdentity:
    kind: str
    version: str
    sha256: str
    archive_sha256: str | None = None
    tree_sha256: str | None = None
    source_revision: str | None = None
    runner_revision: str | None = None
    source_proof: str | None = None

    def safe_receipt(self) -> dict[str, object]:
        return {
            "schema_version": 1,
            "source": self.kind,
            "package": "lockspire",
            "version": self.version,
            "sha256": self.sha256,
            "archive_sha256": self.archive_sha256 or self.sha256,
            "tree_sha256": self.tree_sha256 or "unavailable",
            "source_revision": self.source_revision or "unavailable",
        }


def require_command(command: str) -> None:
    if shutil.which(command) is None:
        raise PackageInputError(f"required command is unavailable: {command}")


def probe_environment() -> None:
    """Fail before child setup when a required clean-room boundary is unavailable."""
    require_command("mix")
    require_command("pg_isready")
    run(
        (
            "pg_isready",
            "-q",
            "-h",
            os.environ.get("CLEAN_ROOM_DB_HOST", "127.0.0.1"),
            "-p",
            os.environ.get("CLEAN_ROOM_DB_PORT", "5432"),
            "-U",
            os.environ.get("CLEAN_ROOM_DB_USER", "postgres"),
            "-d",
            os.environ.get("CLEAN_ROOM_DB_NAME", "postgres"),
        ),
        cwd=PROJECT_ROOT,
    )

    import socket

    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as listener:
            listener.bind(("127.0.0.1", 0))
    except OSError as error:
        raise PackageInputError("loopback listener allocation is unavailable") from error


def clean_room_database_url(role: str) -> str:
    """Return an isolated database URL using the same explicit CI/local seam as the probe."""
    if not re.fullmatch(r"[a-z][a-z0-9_]{0,39}", role):
        raise PackageInputError("invalid clean-room database role")

    user = quote(os.environ.get("CLEAN_ROOM_DB_USER", "postgres"), safe="")
    password = quote(os.environ.get("CLEAN_ROOM_DB_PASSWORD", "postgres"), safe="")
    host = os.environ.get("CLEAN_ROOM_DB_HOST", "127.0.0.1")
    port = os.environ.get("CLEAN_ROOM_DB_PORT", "5432")
    database = f"lockspire_clean_room_{role}_{uuid.uuid4().hex}"
    return f"postgres://{user}:{password}@{host}:{port}/{database}"


def stop_process_group(process: subprocess.Popen, grace: float = 3, *, _deadline: float | None = None) -> bool:
    """Stop only this child's session, including descendants after its leader exits."""
    process.poll()  # Reap an already exited direct child before identity checks.
    deadline = time.monotonic() + grace + 4 if _deadline is None else _deadline
    identity = _OWNED_IDENTITIES.get(process.pid)
    if identity is None or not _signal_before_deadline(process, identity, signal.SIGTERM, deadline):
        return False
    try:
        process.wait(timeout=min(grace, max(0, deadline - time.monotonic())))
    except subprocess.TimeoutExpired:
        pass
    if not _signal_before_deadline(process, identity, signal.SIGKILL, deadline):
        return False
    try:
        process.wait(timeout=min(2, max(0, deadline - time.monotonic())))
    except subprocess.TimeoutExpired:
        return False
    while time.monotonic() < deadline:
        if owned_session_state(identity) == "absent":
            _forget_session(process)
            return True
        time.sleep(0.05)
    return False


def bounded_run(command: Sequence[str], *, timeout: float = 120, stop_grace: float = 4, **kwargs) -> subprocess.CompletedProcess:
    """Run a finite, owned child session; timeout/interruption cannot orphan it."""
    kwargs.pop("check", None)
    input_value = kwargs.pop("input", None)
    process = start_owned_session(command, **kwargs)
    try:
        stdout, stderr = process.communicate(input_value, timeout=timeout)
    except BaseException:
        if not stop_process_group(process, grace=stop_grace):
            raise PackageInputError("owned child cleanup could not be confirmed") from None
        raise
    if not stop_process_group(process, grace=stop_grace):
        raise PackageInputError("owned child cleanup could not be confirmed")
    return subprocess.CompletedProcess(command, process.returncode, stdout, stderr)


def run(command: Sequence[str], *, cwd: Path, env: dict[str, str] | None = None) -> None:
    completed = bounded_run(
        command,
        cwd=cwd,
        env=env,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )

    if completed.returncode != 0:
        rendered = " ".join(command[:3])
        raise PackageInputError(f"{rendered} failed with exit status {completed.returncode}")


def inventory(root: Path) -> tuple[str, ...]:
    entries: list[str] = []

    for path in sorted(root.rglob("*")):
        if path.is_symlink():
            raise PackageInputError(f"package input contains a symlink: {path.name}")
        if path.is_file():
            entries.append(str(path.relative_to(root)))

    if not entries:
        raise PackageInputError("unpacked Lockspire package has no files")

    if any(entry.startswith("test/support/") for entry in entries):
        raise PackageInputError("unpacked Lockspire package contains test support")

    return tuple(entries)


def build_package(run_root: Path) -> tuple[Path, tuple[str, ...]]:
    """Build and unpack one concrete local Hex archive before any child starts."""
    require_command("mix")
    package_root = run_root / "package" / "lockspire"
    package_root.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    archive = run_root / "package" / f"lockspire-{package_version(PROJECT_ROOT)}.tar"
    run(("mix", "hex.build", "--output", str(archive)), cwd=PROJECT_ROOT)
    unpack_hex_tarball(archive, package_root)

    return package_root.resolve(strict=True), inventory(package_root)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def package_tree_digest(root: Path) -> str:
    """Hash sorted relative names and bytes, rejecting links and empty trees."""
    digest = hashlib.sha256()
    paths = sorted(root.rglob("*"))
    for path in paths:
        if path.is_symlink():
            raise PackageInputError("candidate tree contains a symlink")
        if path.is_file():
            digest.update(path.relative_to(root).as_posix().encode("utf-8"))
            digest.update(b"\0")
            with path.open("rb") as handle:
                for chunk in iter(lambda: handle.read(1024 * 1024), b""):
                    digest.update(chunk)
            digest.update(b"\0")
    if not any(path.is_file() for path in paths):
        raise PackageInputError("candidate tree contains no files")
    return digest.hexdigest()


def source_revision() -> str:
    result = subprocess.run(
        ("git", "rev-parse", "HEAD"), cwd=PROJECT_ROOT, stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, check=False, timeout=10,
    )
    value = result.stdout.decode().strip()
    if result.returncode != 0 or not re.fullmatch(r"[0-9a-f]{40,64}", value):
        raise PackageInputError("candidate source revision could not be identified")
    return value


def authenticated_frozen_source(project_root: Path = PROJECT_ROOT) -> PackageSource | None:
    """Resolve the explicitly selected Phase 178 frozen candidate owner."""
    selected = os.environ.get("LOCKSPIRE_FROZEN_INPUTS")
    if not selected:
        return None
    manifest = Path(selected)
    if not manifest.is_absolute():
        manifest = project_root / manifest
    try:
        expected_manifest_sha = os.environ["LOCKSPIRE_EXPECTED_FROZEN_MANIFEST_SHA256"]
        expected_runner = os.environ["LOCKSPIRE_EXPECTED_FROZEN_RUNNER_REVISION"]
        expected_revision = os.environ["LOCKSPIRE_EXPECTED_CANDIDATE_SOURCE_REVISION"]
        expected_archive_sha = os.environ["LOCKSPIRE_EXPECTED_CANDIDATE_ARCHIVE_SHA256"]
        expected_tree_sha = os.environ["LOCKSPIRE_EXPECTED_CANDIDATE_TREE_SHA256"]
        if (not re.fullmatch(r"[0-9a-f]{64}", expected_manifest_sha)
                or not re.fullmatch(r"[0-9a-f]{40,64}", expected_runner)
                or not re.fullmatch(r"[0-9a-f]{40,64}", expected_revision)
                or not re.fullmatch(r"[0-9a-f]{64}", expected_archive_sha)
                or not re.fullmatch(r"[0-9a-f]{64}", expected_tree_sha)
                or sha256(manifest) != expected_manifest_sha):
            raise ValueError
        document = json.loads(manifest.read_text(encoding="utf-8"))
        owner = document["candidate_owner"]
        archive_relative = owner["archive_path"]
        revision = owner["source_revision"]
        archive_sha = owner["archive_sha256"]
        owner_digest = owner["owner_sha256"]
    except (OSError, ValueError, KeyError, TypeError):
        raise PackageInputError("frozen candidate owner manifest is unavailable") from None
    if (not isinstance(archive_relative, str) or Path(archive_relative).is_absolute()
            or ".." in Path(archive_relative).parts
            or not isinstance(revision, str) or not re.fullmatch(r"[0-9a-f]{40,64}", revision)
            or not isinstance(archive_sha, str) or not re.fullmatch(r"[0-9a-f]{64}", archive_sha)
            or not isinstance(owner_digest, str) or not re.fullmatch(r"[0-9a-f]{64}", owner_digest)
            or document.get("runner_revision") != expected_runner
            or revision != expected_revision or archive_sha != expected_archive_sha
            or owner.get("tree_sha256") != expected_tree_sha):
        raise PackageInputError("frozen candidate owner manifest is malformed")
    return PackageSource("frozen", str(project_root / archive_relative), archive_sha,
                         revision, owner_digest, str(manifest))


def verify_frozen_source_owner(
    source: PackageSource, archive: Path, package_root: Path, *, project_root: Path = PROJECT_ROOT,
) -> tuple[str, str]:
    """Bind the selected archive/tree to tracked bytes in its claimed Git commit."""
    if source.owner_manifest is None:
        raise PackageInputError("external candidate source owner is unavailable")
    try:
        manifest_path = Path(source.owner_manifest).resolve(strict=True)
        document = json.loads(manifest_path.read_text(encoding="utf-8"))
        owner = document["candidate_owner"]
        expected_keys = {
            "schema", "source_revision", "source_tree", "archive_path", "archive_sha256",
            "extracted_tree_path", "tree_sha256", "package_files", "source_build", "owner_sha256",
        }
        if set(owner) != expected_keys or owner["schema"] != "lockspire-frozen-candidate-owner-v1":
            raise ValueError
        claim = {key: value for key, value in owner.items() if key != "owner_sha256"}
        expected_owner = hashlib.sha256(
            json.dumps(claim, sort_keys=True, separators=(",", ":")).encode()
        ).hexdigest()
        revision = owner["source_revision"]
        if (owner["owner_sha256"] != expected_owner or revision != source.source_revision
                or source.source_proof != owner["owner_sha256"]
                or not re.fullmatch(r"[0-9a-f]{40,64}", revision)):
            raise ValueError
        archive_relative = Path(owner["archive_path"])
        artifact_root = (project_root / ".artifacts" / "phase178").resolve(strict=True)
        resolved_archive = archive.resolve(strict=True)
        if (archive_relative.is_absolute() or ".." in archive_relative.parts
                or resolved_archive != (project_root / archive_relative).resolve(strict=True)
                or resolved_archive == artifact_root or artifact_root not in resolved_archive.parents
                or archive.is_symlink() or sha256(resolved_archive) != owner["archive_sha256"]
                or source.expected_sha256 != owner["archive_sha256"]):
            raise ValueError
        tree = package_tree_digest(package_root)
        if tree != owner["tree_sha256"]:
            raise ValueError
        listed = owner["package_files"]
        if (not isinstance(listed, list) or not listed
                or any(not isinstance(row, dict) or set(row) != {"path", "sha256"}
                       or not isinstance(row["path"], str)
                       or not re.fullmatch(r"[0-9a-f]{64}", row["sha256"])
                       for row in listed)):
            raise ValueError
        actual_files = sorted(
            ({"path": path.relative_to(package_root).as_posix(), "sha256": sha256(path)}
             for path in package_root.rglob("*") if path.is_file() and not path.is_symlink()),
            key=lambda row: row["path"],
        )
        if sorted(listed, key=lambda row: row["path"]) != actual_files:
            raise ValueError
        source_build = owner["source_build"]
        if (not isinstance(source_build, dict)
                or source_build.get("git_archive_exit_code") != 0
                or source_build.get("package_build_exit_code") != 0
                or source_build.get("rebuilt_tree_sha256") != owner["tree_sha256"]
                or any(not isinstance(source_build.get(field), int) or source_build[field] < 0
                       for field in ("package_stdout_bytes", "package_stderr_bytes"))
                or any(not isinstance(source_build.get(field), str)
                       or not re.fullmatch(r"[0-9a-f]{64}", source_build[field])
                       for field in ("package_stdout_sha256", "package_stderr_sha256", "rebuilt_archive_sha256"))):
            raise ValueError
        result = subprocess.run(
            ("git", "rev-parse", f"{revision}^{{tree}}"), cwd=project_root,
            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
            check=False, timeout=10,
        )
        source_tree = result.stdout.decode("ascii", errors="strict").strip()
        if result.returncode != 0 or source_tree != owner["source_tree"]:
            raise ValueError
        for row in actual_files:
            if row["path"] == "hex_metadata.config":
                continue
            blob = subprocess.run(
                ("git", "show", f"{revision}:{row['path']}"), cwd=project_root,
                stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                check=False, timeout=10,
            )
            if blob.returncode != 0 or hashlib.sha256(blob.stdout).hexdigest() != row["sha256"]:
                raise ValueError
    except (OSError, ValueError, KeyError, TypeError, subprocess.TimeoutExpired):
        raise PackageInputError("frozen candidate source-to-archive binding is unproven") from None
    return revision, owner["owner_sha256"]


def expected_package_files() -> frozenset[str]:
    """Read Mix's evaluated package file set without starting the application."""
    expression = (
        'files = Mix.Project.config() |> Keyword.fetch!(:package) |> Keyword.fetch!(:files) '
        '|> Enum.filter(&File.regular?/1); '
        'IO.puts("LOCKSPIRE_PACKAGE_FILES_BEGIN"); Enum.each(files, &IO.puts/1); '
        'IO.puts("LOCKSPIRE_PACKAGE_FILES_END")'
    )
    completed = bounded_run(
        ("mix", "run", "--no-compile", "--no-deps-check", "--no-start", "-e", expression),
        cwd=PROJECT_ROOT, env=dict(os.environ), stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False, timeout=60,
    )
    if completed.returncode != 0:
        raise PackageInputError("Mix package file set could not be observed")
    try:
        lines = completed.stdout.decode("utf-8", errors="strict").splitlines()
        start = lines.index("LOCKSPIRE_PACKAGE_FILES_BEGIN")
        end = lines.index("LOCKSPIRE_PACKAGE_FILES_END", start + 1)
        if lines.count("LOCKSPIRE_PACKAGE_FILES_BEGIN") != 1 or lines.count("LOCKSPIRE_PACKAGE_FILES_END") != 1:
            raise ValueError
        entries = lines[start + 1:end]
        if not entries or any(
            not isinstance(entry, str)
            or Path(entry).is_absolute()
            or ".." in Path(entry).parts
            or not re.fullmatch(r"[A-Za-z0-9_./-]+", entry)
            for entry in entries
        ) or len(entries) != len(set(entries)):
            raise ValueError
        return frozenset(entries)
    except (UnicodeError, ValueError):
        raise PackageInputError("Mix package file set could not be validated") from None


def verify_local_tar_source_owner(
    revision: str, runner_revision: str, package_root: Path,
    archive_sha256: str, tree_sha256: str,
) -> tuple[str, str]:
    """Bind a locally built tar to every packaged tracked blob at this checkout."""
    try:
        if (not re.fullmatch(r"[0-9a-f]{40,64}", revision)
                or revision != runner_revision
                or package_tree_digest(package_root) != tree_sha256):
            raise ValueError

        def require_clean_tracked_source() -> None:
            observed = subprocess.run(
                ("git", "diff", "--quiet", revision, "--"), cwd=PROJECT_ROOT,
                stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                check=False, timeout=10,
            )
            if observed.returncode != 0:
                raise ValueError

        # Mix expands package globs against this checkout. A tracked deletion
        # must not shrink both the observed file set and tar while claiming HEAD.
        # This is a single-user invocation boundary, like the package path guard.
        require_clean_tracked_source()
        source_tree = subprocess.run(
            ("git", "rev-parse", f"{revision}^{{tree}}"), cwd=PROJECT_ROOT,
            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
            check=False, timeout=10,
        )
        if (source_tree.returncode != 0
                or not re.fullmatch(r"[0-9a-f]{40,64}", source_tree.stdout.decode("ascii", errors="strict").strip())):
            raise ValueError
        entries = inventory(package_root)
        if "mix.exs" not in entries or "hex_metadata.config" not in entries:
            raise ValueError
        actual_sources = set(entries) - {"hex_metadata.config"}
        if actual_sources != expected_package_files():
            raise ValueError
        for entry in entries:
            # Hex generates this metadata file from the package manifest.
            if entry == "hex_metadata.config":
                continue
            blob = subprocess.run(
                ("git", "show", f"{revision}:{entry}"), cwd=PROJECT_ROOT,
                stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                check=False, timeout=10,
            )
            packaged = (package_root / entry).read_bytes()
            if (blob.returncode != 0
                    or hashlib.sha256(blob.stdout).digest() != hashlib.sha256(packaged).digest()):
                raise ValueError
        require_clean_tracked_source()
        proof = _source_binding_digest(revision, archive_sha256, tree_sha256)
        return revision, proof
    except (OSError, ValueError, UnicodeError, PackageInputError, subprocess.TimeoutExpired):
        raise PackageInputError("local package tar source-to-archive binding is unproven") from None


def verify_candidate_input(archive: Path, package_root: Path, identity: PackageIdentity) -> None:
    """Verify the source artifact and extracted tree before any child can reuse them."""
    if not archive.is_file() or sha256(archive) != (identity.archive_sha256 or identity.sha256):
        raise PackageInputError("candidate archive identity mismatch")
    if not package_root.is_dir() or package_tree_digest(package_root) != identity.tree_sha256:
        raise PackageInputError("candidate extracted tree identity mismatch")
    if package_version(package_root) != identity.version:
        raise PackageInputError("candidate package version identity mismatch")
    with tempfile.TemporaryDirectory(prefix="lockspire-candidate-verify-") as temporary:
        extracted = Path(temporary) / "lockspire"
        try:
            unpack_hex_tarball(archive, extracted)
        except PackageInputError:
            raise PackageInputError("candidate archive could not be verified against its extracted tree") from None
        if package_tree_digest(extracted) != identity.tree_sha256:
            raise PackageInputError("candidate archive and extracted tree differ")


def _compiled_candidate_digest(child_root: Path, vendor_root: Path) -> str | None:
    # MIX_BUILD_PATH is an exact path override, so it omits Mix's default
    # environment subdirectory. Accept that direct shape as well as default
    # dev/test paths used by older clean-room hosts.
    roots = (
        child_root / "_build" / "lib" / "lockspire",
        child_root / "_build" / "dev" / "lib" / "lockspire",
        child_root / "_build" / "test" / "lib" / "lockspire",
    )
    existing = [root for root in roots if root.exists()]
    if not existing:
        return None
    vendor_realpath = vendor_root.resolve(strict=True)
    digest = hashlib.sha256()
    for root in existing:
        for path in sorted(root.rglob("*")):
            if path.is_symlink():
                try:
                    resolved_target = path.resolve(strict=True)
                except OSError:
                    raise PackageInputError(
                        "compiled candidate contains a broken symlink: "
                        + path.name
                        + " -> "
                        + os.readlink(path)
                    ) from None
                if resolved_target == vendor_realpath or vendor_realpath not in resolved_target.parents:
                    raise PackageInputError("compiled candidate contains an unapproved symlink: " + path.name)
                digest.update(path.relative_to(child_root).as_posix().encode("utf-8"))
                digest.update(b"\0")
                digest.update(resolved_target.relative_to(vendor_realpath).as_posix().encode("utf-8"))
                digest.update(b"\0")
            if path.is_file():
                digest.update(path.relative_to(child_root).as_posix().encode("utf-8"))
                digest.update(b"\0")
                digest.update(path.read_bytes())
                digest.update(b"\0")
    return digest.hexdigest()


def bind_compiled_candidate(child_root: Path, identity: PackageIdentity, vendor_root: Path, resolved_root: Path) -> None:
    try:
        compiled = _compiled_candidate_digest(child_root, vendor_root)
    except PackageInputError as error:
        print("compiled candidate provenance rejected: " + type(error).__name__)
        raise
    if compiled is None:
        raise PackageInputError("compiled candidate is missing after host preparation")
    marker = {
        "source_revision": identity.source_revision,
        "archive_sha256": identity.archive_sha256,
        "tree_sha256": identity.tree_sha256,
        "vendor_tree_sha256": package_tree_digest(vendor_root),
        "compiled_candidate_sha256": compiled,
        "resolved_dependency": str(resolved_root.resolve(strict=True)),
        "resolved_dependency_verified": True,
    }
    marker_path = child_root / ".lockspire-candidate.json"
    marker_path.write_text(json.dumps(marker, sort_keys=True, separators=(",", ":")) + "\n", encoding="utf-8")


def verify_candidate_host(
    package_root: Path, child_root: Path, identity: PackageIdentity,
    vendor_root: Path, resolved_dependency: Path,
) -> None:
    """Reject package, vendor, resolver, or compiled drift before a host is reused."""
    expected = identity.tree_sha256
    if not expected or package_tree_digest(package_root) != expected:
        raise PackageInputError("candidate source tree identity mismatch")
    if package_tree_digest(vendor_root) != expected:
        raise PackageInputError("candidate vendor tree identity mismatch")
    vendor = vendor_root.resolve(strict=True)
    resolved = resolved_dependency.resolve(strict=True)
    if resolved != vendor:
        raise PackageInputError("candidate resolved dependency identity mismatch")
    compiled = _compiled_candidate_digest(child_root, vendor_root)
    marker_path = child_root / ".lockspire-candidate.json"
    if compiled is None and not marker_path.exists():
        return
    if compiled is None or not marker_path.is_file():
        raise PackageInputError("candidate compiled state identity mismatch")
    try:
        marker = json.loads(marker_path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        raise PackageInputError("candidate compiled state identity mismatch") from None
    expected_marker = {
        "source_revision": identity.source_revision,
        "archive_sha256": identity.archive_sha256,
        "tree_sha256": expected,
        "vendor_tree_sha256": expected,
        "compiled_candidate_sha256": compiled,
        "resolved_dependency": str(vendor),
        "resolved_dependency_verified": True,
    }
    if marker != expected_marker:
        raise PackageInputError("candidate compiled state identity mismatch")


def candidate_host_provenance(child_root: Path) -> dict[str, object]:
    """Return only non-path provenance fields from a previously verified host binding."""
    try:
        marker = json.loads((child_root / ".lockspire-candidate.json").read_text(encoding="utf-8"))
    except (OSError, ValueError):
        raise PackageInputError("candidate compiled state identity mismatch") from None
    return {
        "vendor_tree_sha256": marker.get("vendor_tree_sha256"),
        "compiled_candidate_sha256": marker.get("compiled_candidate_sha256"),
        "resolved_dependency_verified": marker.get("resolved_dependency_verified") is True,
    }


def exact_version(value: str) -> str:
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z][0-9A-Za-z.-]*)?", value):
        raise PackageInputError("Lockspire package version must be exact")
    return value


def package_version(package_root: Path) -> str:
    match = re.search(r'^\s*version:\s*"([^"]+)"', (package_root / "mix.exs").read_text(), re.MULTILINE)
    if match is None:
        raise PackageInputError("unpacked Lockspire package has no exact version")
    return exact_version(match.group(1))


def unpack_hex_tarball(tarball: Path, package_root: Path) -> None:
    """Ask the installed Hex archive to validate and unpack its own package format."""
    require_command("elixir")
    package_root.mkdir(mode=0o700, parents=True, exist_ok=False)
    expression = """
Mix.start()
Mix.Local.append_archives()
tarball = File.read!(Enum.at(System.argv(), 0))
destination = Enum.at(System.argv(), 1) |> String.to_charlist()
case :mix_hex_tarball.unpack(tarball, destination) do
  {:ok, _metadata} -> :ok
  {:error, reason} -> raise "Hex package validation failed: #{inspect(reason)}"
end
"""
    run(("elixir", "-e", expression, str(tarball), str(package_root)), cwd=PROJECT_ROOT)


def validate_local_tarball(path: Path, allowed_root: Path, expected_sha256: str | None) -> tuple[Path, str, str]:
    if path.is_symlink():
        raise PackageInputError("Lockspire package tar must be a regular file")
    resolved = path.resolve(strict=True)
    allowed = allowed_root.resolve(strict=True)
    if not resolved.is_file():
        raise PackageInputError("Lockspire package tar must be a regular file")
    if resolved.parent != allowed and allowed not in resolved.parents:
        raise PackageInputError("Lockspire package tar escapes its declared root")
    match = re.fullmatch(r"lockspire-([0-9A-Za-z.-]+)\.tar", resolved.name)
    if match is None:
        raise PackageInputError("Lockspire package tar has an unexpected name")
    version = exact_version(match.group(1))
    checksum = sha256(resolved)
    if expected_sha256 is not None:
        if not re.fullmatch(r"[0-9a-f]{64}", expected_sha256) or checksum != expected_sha256:
            raise PackageInputError("Lockspire package tar checksum mismatch")
    return resolved, version, checksum


def _frozen_archive_destination(run_root: Path, version: str, checksum: str) -> Path:
    """Refuse stale or redirected private paths without changing their bytes."""
    parent = run_root / "package"
    for directory in (run_root, parent):
        if directory.is_symlink() or (directory.exists() and not directory.is_dir()):
            raise PackageInputError("frozen private package directory is unsafe")
    destination = parent / f"lockspire-{version}.tar"
    if (destination.is_symlink() or (destination.exists()
            and (not destination.is_file() or sha256(destination) != checksum))):
        raise PackageInputError("frozen private archive is stale or unsafe")
    return destination


def _materialize_frozen_archive(source: Path, run_root: Path, version: str, checksum: str) -> None:
    destination = _frozen_archive_destination(run_root, version, checksum)
    if destination.exists():
        return  # An exact cached copy is reusable; never replace an existing file.
    destination.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    descriptor = os.open(destination, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    created = os.fstat(descriptor)
    try:
        digest = hashlib.sha256()
        with os.fdopen(descriptor, "wb") as output, source.open("rb") as original:
            while chunk := original.read(1024 * 1024):
                output.write(chunk)
                digest.update(chunk)
            output.flush()
            os.fsync(output.fileno())
        current = destination.lstat()
        if ((current.st_dev, current.st_ino) != (created.st_dev, created.st_ino)
                or digest.hexdigest() != checksum or sha256(destination) != checksum):
            raise PackageInputError("frozen private archive copy differs from its owner")
    except BaseException:
        # Remove only the file this call exclusively created, never a replacement.
        try:
            current = destination.lstat()
            if (current.st_dev, current.st_ino) == (created.st_dev, created.st_ino):
                destination.unlink()
        except OSError:
            pass
        raise


def prepare_package(run_root: Path, source: PackageSource | None = None) -> tuple[Path, tuple[str, ...], PackageIdentity]:
    frozen_source = authenticated_frozen_source()
    if source is None or (source.kind == "checkout" and frozen_source is not None):
        source = frozen_source or source or PackageSource("checkout")
    package_root = run_root / "package" / "lockspire"
    runner = source_revision()

    if source.kind == "checkout":
        tarball = run_root / "package" / f"lockspire-{package_version(PROJECT_ROOT)}.tar"
        if package_root.is_dir() and tarball.is_file():
            version = package_version(package_root)
            checksum = sha256(tarball)
            tree = package_tree_digest(package_root)
            if not checkout_package_inputs_are_clean():
                raise PackageInputError("checkout package inputs must be clean before source attribution")
            proof = _source_binding_digest(runner, checksum, tree)
            identity = PackageIdentity("checkout", version, checksum, checksum, tree, runner, runner, proof)
            verify_candidate_input(tarball, package_root, identity)
            return package_root.resolve(strict=True), inventory(package_root), identity
        package_root, entries = build_package(run_root)
        version = package_version(package_root)
        checksum = sha256(tarball)
        tree = package_tree_digest(package_root)
        if not checkout_package_inputs_are_clean():
            raise PackageInputError("checkout package inputs must be clean before source attribution")
        proof = _source_binding_digest(runner, checksum, tree)
        return package_root, entries, PackageIdentity("checkout", version, checksum, checksum, tree, runner, runner, proof)

    if source.kind == "frozen":
        if source.owner_manifest is None:
            raise PackageInputError("frozen candidate owner is unavailable")
        tarball = Path(source.value or "")
        allowed_root = (PROJECT_ROOT / ".artifacts" / "phase178").resolve(strict=True)
    elif source.kind == "hex":
        version = exact_version(source.value or "")
        downloads = run_root / "package" / "downloads"
        downloads.mkdir(mode=0o700, parents=True, exist_ok=True)
        tarball = downloads / f"lockspire-{version}.tar"
        run(("mix", "hex.package", "fetch", "lockspire", version, "--output", str(downloads)), cwd=run_root)
        allowed_root = downloads
    elif source.kind == "tar":
        tarball = Path(source.value or "")
        configured_root = os.environ.get("LOCKSPIRE_PACKAGE_ROOT")
        allowed_root = Path(configured_root) if configured_root else PROJECT_ROOT
    else:
        raise PackageInputError("unknown Lockspire package source")

    tarball, version, checksum = validate_local_tarball(tarball, allowed_root, source.expected_sha256)
    if source.kind == "frozen":
        _frozen_archive_destination(run_root, version, checksum)
    if package_root.is_dir():
        tree = package_tree_digest(package_root)
        if source.kind == "frozen":
            source_revision_claim, source_proof = verify_frozen_source_owner(source, tarball, package_root)
        elif source.kind == "tar" and source.source_revision is not None:
            source_revision_claim, source_proof = verify_local_tar_source_owner(
                source.source_revision, runner, package_root, checksum, tree,
            )
        else:
            source_revision_claim, source_proof = _external_source_claim(source, checksum, tree)
        identity = PackageIdentity(
            source.kind, version, checksum, checksum, tree,
            source_revision_claim, runner, source_proof,
        )
        verify_candidate_input(tarball, package_root, identity)
        if source.kind == "frozen":
            _materialize_frozen_archive(tarball, run_root, version, checksum)
        return package_root.resolve(strict=True), inventory(package_root), identity
    unpack_hex_tarball(tarball, package_root)
    unpacked_version = package_version(package_root)
    if unpacked_version != version:
        raise PackageInputError("Lockspire package filename and metadata versions differ")

    entries = inventory(package_root)
    package_root = package_root.resolve(strict=True)
    tree = package_tree_digest(package_root)
    if source.kind == "frozen":
        source_revision_claim, source_proof = verify_frozen_source_owner(source, tarball, package_root)
        _materialize_frozen_archive(tarball, run_root, version, checksum)
    elif source.kind == "tar" and source.source_revision is not None:
        source_revision_claim, source_proof = verify_local_tar_source_owner(
            source.source_revision, runner, package_root, checksum, tree,
        )
    else:
        source_revision_claim, source_proof = _external_source_claim(source, checksum, tree)
    return package_root, entries, PackageIdentity(
        source.kind, version, checksum, checksum, tree, source_revision_claim, runner, source_proof
    )


def _external_source_claim(source: PackageSource, archive_sha256: str, tree_sha256: str) -> tuple[str | None, str | None]:
    if source.source_proof is None:
        return None, None
    raise PackageInputError("external package source owner requires a frozen owner manifest")


def _source_binding_digest(revision: str, archive_sha256: str, tree_sha256: str) -> str:
    if not re.fullmatch(r"[0-9a-f]{40,64}", revision):
        raise PackageInputError("candidate source revision is unavailable")
    binding = json.dumps(
        {"archive_sha256": archive_sha256, "source_revision": revision, "tree_sha256": tree_sha256},
        sort_keys=True, separators=(",", ":"),
    ).encode()
    return hashlib.sha256(binding).hexdigest()


def checkout_package_inputs_are_clean() -> bool:
    """Require the exact files Hex packages before tying a checkout SHA to output."""
    completed = subprocess.run(
        ("git", "status", "--porcelain", "--untracked-files=all", "--", "lib", "priv", "mix.exs", "mix.lock", "README.md", "LICENSE", "LICENSE.md"),
        cwd=PROJECT_ROOT, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL, check=False, timeout=10,
    )
    return completed.returncode == 0 and not completed.stdout.strip()


def assert_below(path: Path, root: Path, label: str) -> Path:
    resolved = path.resolve(strict=True)
    root_resolved = root.resolve(strict=True)

    if resolved == root_resolved or root_resolved not in resolved.parents:
        raise PackageInputError(f"{label} escapes its child root")

    return resolved


def copy_child_template(role: str, run_root: Path, package_root: Path) -> Path:
    template = TEMPLATE_ROOT / role
    if not (template / "mix.exs").is_file() or not (template / "mix.lock").is_file():
        raise PackageInputError(f"{role} template must contain checked-in mix.exs and mix.lock")

    child_root = run_root / role
    shutil.copytree(template, child_root, ignore=shutil.ignore_patterns("vendor", "_build", "deps"))
    vendor_root = child_root / "vendor" / "lockspire"
    vendor_root.parent.mkdir(mode=0o700, parents=True)
    shutil.copytree(package_root, vendor_root, symlinks=False)

    package_inventory = inventory(package_root)
    if inventory(vendor_root) != package_inventory:
        raise PackageInputError(f"{role} package inventory differs from unpacked input")

    vendor_realpath = assert_below(vendor_root, child_root, f"{role} Lockspire dependency")
    checkout = PROJECT_ROOT.resolve()
    if vendor_realpath == checkout or checkout in vendor_realpath.parents:
        raise PackageInputError(f"{role} Lockspire dependency resolves to the live checkout")

    return child_root


def locked_environment(child_root: Path, role: str, cache_root: Path | None) -> dict[str, str]:
    environment = os.environ.copy()
    mix_env = environment.get("MIX_ENV")
    if mix_env not in {"dev", "test", "prod"}:
        mix_env = "dev"
    # MIX_BUILD_PATH is the exact build directory, not the root that Mix
    # augments with an environment segment. Keep the environment segment so
    # path-dependency asset links (notably priv/) resolve inside the host.
    # Canonicalize the build path before Mix calculates relative `priv/`
    # links. On macOS, TMPDIR commonly enters through /var but resolves to
    # /private/var; mixing those spellings makes valid package links point
    # past the host root.
    environment["MIX_BUILD_PATH"] = str((child_root / "_build" / mix_env).resolve())

    if cache_root is not None:
        cache_realpath = cache_root.resolve()
        allowed_root = cache_root.parent.resolve()
        if cache_realpath != allowed_root and allowed_root not in cache_realpath.parents:
            raise PackageInputError("external dependency cache escapes its declared root")

        cache_role = "provider" if role == "provider_host" else "client"
        role_deps = cache_realpath / cache_role / "deps"
        role_deps.mkdir(mode=0o700, parents=True, exist_ok=True)
        environment["MIX_DEPS_PATH"] = str(role_deps)

    return environment


def verify_child(
    role: str, child_root: Path, cache_root: Path | None, extra_environment: dict[str, str] | None = None
) -> Path:
    before_manifest = (child_root / "mix.exs").read_bytes()
    before_lock = (child_root / "mix.lock").read_bytes()
    environment = locked_environment(child_root, role, cache_root)
    if extra_environment:
        environment.update(extra_environment)

    run(("mix", "deps.get", "--check-locked"), cwd=child_root, env=environment)
    run(("mix", "deps"), cwd=child_root, env=environment)

    dependency_path = bounded_run(
        (
            "mix",
            "run",
            "--no-compile",
            "--no-deps-check",
            "--no-start",
            "-e",
            'IO.puts("LOCKSPIRE_DEPS_PATH=" <> Mix.Project.deps_paths()[:lockspire])',
        ),
        cwd=child_root,
        env=environment,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )

    if dependency_path.returncode != 0:
        raise PackageInputError(f"{role} dependency provenance probe failed")

    marker = b"LOCKSPIRE_DEPS_PATH="
    observed = next(
        (line[len(marker) :] for line in dependency_path.stdout.splitlines() if line.startswith(marker)),
        None,
    )

    if observed is None:
        raise PackageInputError(f"{role} dependency provenance probe returned no path")

    if before_manifest != (child_root / "mix.exs").read_bytes():
        raise PackageInputError(f"{role} manifest changed during locked dependency resolution")
    if before_lock != (child_root / "mix.lock").read_bytes():
        raise PackageInputError(f"{role} lock changed during locked dependency resolution")

    vendor_root = child_root / "vendor" / "lockspire"
    resolved = assert_below(vendor_root, child_root, f"{role} Lockspire dependency")
    if resolved != vendor_root.resolve(strict=True) or Path(observed.decode()).resolve() != resolved:
        raise PackageInputError(f"{role} Lockspire provenance does not match its vendor path")

    label = "provider" if role == "provider_host" else "client"
    print(f"{label} provenance verified")
    return resolved


def prepare_children(run_root: Path, cache_root: Path | None = None) -> None:
    probe_environment()
    package_root, _package_inventory = build_package(run_root)

    for role in ROLES:
        child_root = copy_child_template(role, run_root, package_root)
        verify_child(role, child_root, cache_root)


def update_locks() -> None:
    with tempfile.TemporaryDirectory(prefix="lockspire-clean-room-locks-") as temporary:
        run_root = Path(temporary)
        package_root, _package_inventory = build_package(run_root)

        for role in ROLES:
            template = TEMPLATE_ROOT / role
            child_root = run_root / role
            shutil.copytree(template, child_root, ignore=shutil.ignore_patterns("vendor", "_build", "deps"))
            vendor_root = child_root / "vendor" / "lockspire"
            vendor_root.parent.mkdir(mode=0o700, parents=True)
            shutil.copytree(package_root, vendor_root, symlinks=False)
            run(("mix", "deps.get"), cwd=child_root)
            shutil.copy2(child_root / "mix.lock", template / "mix.lock")


def package_source(
    package_tar: Path | None,
    hex_version: str | None,
    expected_sha256: str | None = None,
    source_revision: str | None = None,
) -> PackageSource:
    if package_tar is not None and hex_version is not None:
        raise PackageInputError("choose either a local package tar or exact Hex version")
    if package_tar is not None:
        return PackageSource("tar", str(package_tar), expected_sha256, source_revision)
    if hex_version is not None:
        if source_revision is not None:
            raise PackageInputError("package source revision requires a local package tar")
        return PackageSource("hex", exact_version(hex_version), expected_sha256)
    if expected_sha256 is not None:
        raise PackageInputError("--package-sha256 requires --package-tar or --hex-version")
    if source_revision is not None:
        raise PackageInputError("package source revision requires a local package tar")
    return PackageSource("checkout")


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--update-locks", action="store_true")
    parser.add_argument("--cache-root", type=Path)
    parser.add_argument("--package-tar", type=Path)
    parser.add_argument("--package-sha256")
    parser.add_argument("--source-revision")
    parser.add_argument("--hex-version")
    parser.add_argument("--inspect", action="store_true")
    return parser.parse_args(argv)


def main(argv: Sequence[str]) -> int:
    args = parse_args(argv)

    try:
        if args.package_tar and args.hex_version:
            raise PackageInputError("choose either --package-tar or --hex-version")

        if args.inspect:
            source = package_source(
                args.package_tar, args.hex_version, args.package_sha256,
                args.source_revision,
            )
            with tempfile.TemporaryDirectory(prefix="lockspire-clean-room-inspect-") as temporary:
                _root, _entries, identity = prepare_package(Path(temporary), source)
            print(json.dumps(identity.safe_receipt(), sort_keys=True, separators=(",", ":")))
            return 0

        if args.update_locks:
            update_locks()
            return 0

        if args.self_test:
            with tempfile.TemporaryDirectory(prefix="lockspire-clean-room-input-") as temporary:
                prepare_children(Path(temporary), args.cache_root)
            return 0

        raise PackageInputError("choose --self-test or --update-locks")
    except PackageInputError as error:
        print(f"clean-room package input failed: {type(error).__name__}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
