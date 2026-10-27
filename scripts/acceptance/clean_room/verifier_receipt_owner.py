"""Independent package and selected/observed runtime authority for raw receipts."""
from __future__ import annotations

from dataclasses import dataclass
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[3]
PROFILES = {"local-current": ("ELIXIR_VERSION", "OTP_VERSION"),
            "hosted-current": ("ELIXIR_VERSION", "OTP_VERSION"),
            "hosted-minimum": ("MIN_ELIXIR_VERSION", "MIN_OTP_VERSION")}


class OwnerError(ValueError):
    pass


def selected_runtime(root: Path, profile: str) -> tuple[str, str, str]:
    if profile not in PROFILES:
        raise OwnerError("receipt toolchain profile is unsupported")
    source = (root / ".github/workflows/ci.yml").read_bytes()
    header = source.decode("utf-8").split("\njobs:", 1)[0]
    values = []
    for name in PROFILES[profile]:
        matches = re.findall(r"(?m)^  " + name + r': "([0-9]+(?:\.[0-9]+)*)"$', header)
        if len(matches) != 1:
            raise OwnerError("selected toolchain source is unavailable")
        values.append(matches[0])
    return values[0], values[1], hashlib.sha256(source).hexdigest()


def postgres_identity(value: str) -> str:
    if not re.fullmatch(r"[1-9][0-9]{5,7}", value):
        raise OwnerError("PostgreSQL numeric version observation is invalid")
    number = int(value)
    return f"{number // 10000}.{number % 10000}"


def _observe(command, *, root: Path, env=None) -> bytes:
    from package_input import bounded_run, PackageInputError
    try:
        result = bounded_run(command, cwd=root, env=env, stdin=subprocess.DEVNULL,
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False, timeout=30)
    except (OSError, ValueError, PackageInputError, subprocess.TimeoutExpired):
        raise OwnerError("selected runtime observation failed; diagnostics withheld") from None
    if result.returncode:
        raise OwnerError("selected runtime observation failed; diagnostics withheld")
    return result.stdout


@dataclass(frozen=True, init=False)
class ReceiptOwner:
    _serialized: str

    def __init__(self, document: dict):
        object.__setattr__(self, "_serialized", json.dumps(document, sort_keys=True, separators=(",", ":")))

    @property
    def document(self):
        # Callers cannot turn a receipt mutation into an authority mutation by
        # sharing a mutable dictionary with this independent snapshot.
        return json.loads(self._serialized)

    @property
    def runtime(self):
        return self.document["runtime"]

    @property
    def package_version(self):
        return self.document["package_version"]

    def validate(self, receipt: dict) -> None:
        candidate = receipt["candidate"]
        expected = self.document
        if (candidate.get("version") != expected["package_version"]
                or (candidate.get("source_revision"), candidate.get("archive_sha256"), candidate.get("tree_sha256"))
                    != tuple(expected["candidate_source_archive_tree"])
                or candidate.get("source_proof") != expected["candidate_owner_sha256"]
                or candidate.get("runner_revision") != expected["runner_revision"]
                or receipt.get("runtime") != expected["runtime"]):
            raise OwnerError("receipt version or runtime differs from independent owner authority")


def capture(root: Path, frozen: dict, profile: str, *, runner: str) -> ReceiptOwner:
    from package_input import package_version, package_tree_digest, sha256
    owner = frozen["candidate_owner"]
    package = root / owner["extracted_tree_path"]
    if (package_tree_digest(package) != owner["tree_sha256"]
            or sha256(root / owner["archive_path"]) != owner["archive_sha256"]):
        raise OwnerError("receipt package authority changed")
    version = package_version(package)
    elixir, otp, selection_digest = selected_runtime(root, profile)
    beam_output = _observe(("elixir", "-e", 'IO.puts(System.version()); IO.puts(System.otp_release())'), root=root)
    if beam_output.decode("ascii", errors="strict").splitlines() != [elixir, otp]:
        raise OwnerError("observed BEAM differs from selected toolchain profile")
    host = os.environ.get("CLEAN_ROOM_DB_HOST", "127.0.0.1")
    port = os.environ.get("CLEAN_ROOM_DB_PORT", "5432")
    if host not in {"127.0.0.1", "localhost", "::1"} or not port.isdecimal() or not 1 <= int(port) <= 65535:
        raise OwnerError("runtime authority server selection is invalid")
    environment = dict(os.environ, PGHOST=host, PGPORT=port,
                       PGUSER=os.environ.get("CLEAN_ROOM_DB_USER", "postgres"),
                       PGPASSWORD=os.environ.get("CLEAN_ROOM_DB_PASSWORD", "postgres"),
                       PGDATABASE=os.environ.get("CLEAN_ROOM_DB_NAME", "postgres"),
                       PGOPTIONS="-c default_transaction_read_only=on")
    for name in ("PGSERVICE", "PGSERVICEFILE", "PGHOSTADDR"):
        environment.pop(name, None)
    postgres_output = _observe(("psql", "--no-psqlrc", "--tuples-only", "--no-align", "--command", "SHOW server_version_num"),
                               root=root, env=environment)
    numeric = postgres_output.decode("ascii", errors="strict").strip()
    if postgres_output != numeric.encode("ascii") + b"\n":
        raise OwnerError("PostgreSQL numeric version framing is invalid")
    runtime = {"elixir": elixir, "otp": otp, "postgresql": postgres_identity(numeric)}
    return ReceiptOwner({"schema": "lockspire-verifier-receipt-owner-v1", "profile": profile,
        "runner_revision": runner, "selection_source_sha256": selection_digest,
        "candidate_source_archive_tree": [owner["source_revision"], owner["archive_sha256"], owner["tree_sha256"]],
        "candidate_owner_sha256": owner["owner_sha256"], "package_version": version,
        "runtime": runtime, "server_version_num": numeric,
        "observations": {"beam_sha256": hashlib.sha256(beam_output).hexdigest(),
                         "server_sha256": hashlib.sha256(postgres_output).hexdigest()}})


def validate_document(document: dict, *, root: Path, package_version: str,
                      runner: str, candidate: tuple, proof: str, profile: str | None = None) -> ReceiptOwner:
    fields = {"schema", "profile", "runner_revision", "selection_source_sha256", "candidate_source_archive_tree",
              "candidate_owner_sha256", "package_version", "runtime", "server_version_num", "observations"}
    if (not isinstance(document, dict) or set(document) != fields
            or document.get("schema") != "lockspire-verifier-receipt-owner-v1"
            or document.get("runner_revision") != runner or document.get("package_version") != package_version
            or document.get("candidate_source_archive_tree") != list(candidate)
            or document.get("candidate_owner_sha256") != proof
            or (profile is not None and document.get("profile") != profile)):
        raise OwnerError("receipt owner identity differs from authenticated package or execution")
    elixir, otp, digest = selected_runtime(root, document["profile"])
    expected = {"elixir": elixir, "otp": otp, "postgresql": postgres_identity(document["server_version_num"])}
    observations = document.get("observations")
    if (document.get("selection_source_sha256") != digest or document.get("runtime") != expected
            or not isinstance(observations, dict) or set(observations) != {"beam_sha256", "server_sha256"}
            or any(not isinstance(value, str) or not re.fullmatch(r"[0-9a-f]{64}", value) for value in observations.values())):
        raise OwnerError("receipt runtime authority differs from selected observed profile")
    if (observations["beam_sha256"] != hashlib.sha256((elixir + "\n" + otp + "\n").encode()).hexdigest()
            or observations["server_sha256"] != hashlib.sha256((document["server_version_num"] + "\n").encode()).hexdigest()):
        raise OwnerError("receipt runtime observation digests differ from canonical observations")
    return ReceiptOwner(document)


def selected_owner() -> ReceiptOwner:
    path = os.environ.get("LOCKSPIRE_RECEIPT_OWNER")
    digest = os.environ.get("LOCKSPIRE_EXPECTED_RECEIPT_OWNER_SHA256")
    if not path or not digest:
        raise OwnerError("independent receipt owner context is required")
    source = Path(path)
    if source.is_symlink() or not source.is_file():
        raise OwnerError("receipt owner context is unsafe")
    raw = source.read_bytes()
    if hashlib.sha256(raw).hexdigest() != digest:
        raise OwnerError("receipt owner context differs from its independent caller pin")
    document = json.loads(raw)
    # This context is captured and pinned before any group starts. Its package
    # and runtime identity are independently checked again at pair/upload gates.
    return validate_document(document, root=ROOT, package_version=document["package_version"],
        runner=document["runner_revision"], candidate=tuple(document["candidate_source_archive_tree"]),
        proof=document["candidate_owner_sha256"])


def observed_host_runtime(elixir: str, otp: str, server_version_num: str) -> tuple[str, str, str]:
    owner = selected_owner()
    observed = {"elixir": elixir, "otp": otp, "postgresql": postgres_identity(server_version_num)}
    if observed != owner.runtime:
        raise OwnerError("installed host runtime differs from captured execution authority")
    return observed["elixir"], observed["otp"], observed["postgresql"]
