"""Produce the bounded P2 ElevenLabs audio candidate batch.

The runtime has no ElevenLabs dependency. This offline tool uses only Python's
standard library, never logs the API key, performs no automatic retries, and
can only write under the D-drive P2 audio-source batch root.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import struct
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
import uuid
import wave
from datetime import UTC, datetime, timedelta
from email import policy
from email.parser import BytesParser
from pathlib import Path
from typing import Any


SCRIPT_PATH = Path(__file__).resolve()
REPO_ROOT = SCRIPT_PATH.parents[2]
BATCH_ROOT = REPO_ROOT / "audio-source" / "p2-life-loop-v1"
JOB_PATH = BATCH_ROOT / "P2_AUDIO_GENERATION_JOBS.json"
AUTHORIZATION_PATH = BATCH_ROOT / "P2_AUDIO_GENERATION_AUTHORIZATION.json"
GRANT_PATH = BATCH_ROOT / "P2_AUDIO_EXECUTION_GRANT.json"
GRANT_HISTORY_ROOT = BATCH_ROOT / "grants"
PLAN_PATH = BATCH_ROOT / "plans" / "h01_spring_day.music_v2.plan.json"
CANDIDATE_ROOT = BATCH_ROOT / "candidates"
REVIEW_ROOT = BATCH_ROOT / "review"
METADATA_ROOT = BATCH_ROOT / "metadata"
LEDGER_PATH = METADATA_ROOT / "API_CALL_LEDGER.json"
API_BASE = "https://api.elevenlabs.io/v1"
PCM_SAMPLE_RATE = 48_000
PCM_SAMPLE_WIDTH = 2
PCM_CHANNELS = 2


def _read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _assert_owned_path(path: Path) -> Path:
    resolved = path.resolve()
    root = BATCH_ROOT.resolve()
    if resolved.drive.upper() != "D:":
        raise RuntimeError(f"Audio production output must remain on D: {resolved}")
    if resolved != root and root not in resolved.parents:
        raise RuntimeError(f"Refusing output outside P2 audio batch: {resolved}")
    return resolved


def _atomic_write(path: Path, payload: bytes) -> None:
    target = _assert_owned_path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    handle, temporary_name = tempfile.mkstemp(
        prefix=f".{target.name}.",
        suffix=".part",
        dir=target.parent,
    )
    temporary = Path(temporary_name)
    try:
        with os.fdopen(handle, "wb") as stream:
            stream.write(payload)
            stream.flush()
            os.fsync(stream.fileno())
        temporary.replace(target)
    finally:
        temporary.unlink(missing_ok=True)


def _write_json(path: Path, value: Any) -> None:
    payload = json.dumps(value, ensure_ascii=False, indent=2).encode("utf-8")
    _atomic_write(path, payload + b"\n")


def _sha256_bytes(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()


def _sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _utc_now() -> str:
    return datetime.now(UTC).isoformat()


def _api_key() -> str:
    value = os.environ.get("ELEVENLABS_API_KEY", "").strip()
    if not value:
        raise RuntimeError("ELEVENLABS_API_KEY is not available")
    return value


def _request(
    method: str,
    endpoint: str,
    body: dict[str, Any] | None = None,
) -> tuple[bytes, dict[str, str], int]:
    payload = None
    headers = {
        "Accept": "application/json, audio/mpeg, application/octet-stream, multipart/mixed",
        "Connection": "close",
        "xi-api-key": _api_key(),
    }
    if body is not None:
        payload = json.dumps(body, ensure_ascii=False).encode("utf-8")
        headers["Content-Type"] = "application/json"
    request = urllib.request.Request(
        f"{API_BASE}{endpoint}",
        data=payload,
        headers=headers,
        method=method,
    )
    try:
        with urllib.request.urlopen(request, timeout=300) as response:
            response_headers = {
                name.lower(): value for name, value in response.headers.items()
            }
            return response.read(), response_headers, response.status
    except urllib.error.HTTPError as error:
        response_text = error.read().decode("utf-8", errors="replace")
        raise RuntimeError(
            f"ElevenLabs request failed: {method} {endpoint} "
            f"HTTP {error.code}: {response_text[:1000]}"
        ) from error


def _subscription() -> dict[str, Any]:
    payload, _headers, status = _request("GET", "/user/subscription")
    if status != 200:
        raise RuntimeError(f"Unexpected subscription status: {status}")
    source = json.loads(payload.decode("utf-8"))
    return {
        "capturedAt": _utc_now(),
        "tier": source.get("tier"),
        "status": source.get("status"),
        "creditUsed": source.get("character_count"),
        "creditLimit": source.get("character_limit"),
        "maximumOverage": source.get("max_credit_limit_extension"),
        "canExtend": source.get("can_extend_character_limit"),
        "nextResetUnix": source.get("next_character_count_reset_unix"),
    }


def _load_contracts() -> tuple[dict[str, Any], dict[str, Any]]:
    jobs = _read_json(JOB_PATH)
    authorization = _read_json(AUTHORIZATION_PATH)
    if jobs.get("batchId") != authorization.get("batchId"):
        raise RuntimeError("Audio job and authorization batch IDs do not match")
    if jobs.get("provider") != authorization.get("authorizedProvider"):
        raise RuntimeError("Audio provider is outside the recorded authorization")
    cue_count = len(jobs.get("soundEffects", []))
    variant_count = len(jobs.get("soundEffectVariants", []))
    limits = authorization["limits"]
    if cue_count != limits["soundEffectCueCount"]:
        raise RuntimeError("Sound-effect cue count is outside authorization")
    if variant_count != limits["soundEffectVariantsPerCue"]:
        raise RuntimeError("Sound-effect variant count is outside authorization")
    if cue_count * variant_count != limits["soundEffectCandidateCount"]:
        raise RuntimeError("Sound-effect total count is outside authorization")
    if limits.get("musicCandidateCount") != 1:
        raise RuntimeError("This batch requires exactly one music candidate")
    if limits.get("allowAdditionalRegeneration") is not False:
        raise RuntimeError("Additional regeneration must remain disabled")
    return jobs, authorization


def _contract_hashes() -> dict[str, str]:
    return {
        "jobsSha256": _sha256_file(JOB_PATH),
        "authorizationSha256": _sha256_file(AUTHORIZATION_PATH),
        "scriptSha256": _sha256_file(SCRIPT_PATH),
    }


def issue_grant() -> None:
    jobs, authorization = _load_contracts()
    ledger = _load_ledger()
    attempted_counts = {
        capability: sum(
            1
            for call in ledger.get("calls", [])
            if call.get("capability") == capability
            and any(
                state.get("state") == "ATTEMPTED"
                for state in call.get("states", [])
            )
        )
        for capability in (
            "music-composition-plan",
            "sound-effect",
            "music",
        )
    }
    authorized_counts = {
        "music-composition-plan": 1,
        "sound-effect": authorization["limits"]["soundEffectCandidateCount"],
        "music": authorization["limits"]["musicCandidateCount"],
    }
    remaining_counts = {
        capability: max(
            0,
            authorized_counts[capability] - attempted_counts[capability],
        )
        for capability in authorized_counts
    }
    grant = {
        "schemaVersion": 1,
        "batchId": jobs["batchId"],
        "issuedAt": _utc_now(),
        "expiresAt": (datetime.now(UTC) + timedelta(hours=24)).isoformat(),
        "contractHashes": _contract_hashes(),
        "operations": authorization["authorizedOperations"],
        "limits": authorization["limits"],
        "executionTokens": authorization["executionTokens"],
        "automaticRetries": 0,
        "shippingApproval": False,
        "remainingExecutionBudget": remaining_counts,
        "completedBatchHasNoRemainingExecutableJobs": all(
            count == 0 for count in remaining_counts.values()
        ),
    }
    snapshot_name = (
        grant["issuedAt"]
        .replace(":", "")
        .replace("-", "")
        .replace("+", "_")
        .replace(".", "_")
    )
    snapshot_path = (
        GRANT_HISTORY_ROOT
        / f"{snapshot_name}-{grant['contractHashes']['scriptSha256'][:12]}.json"
    )
    grant["versionedSnapshotPath"] = str(snapshot_path.resolve())
    _write_json(snapshot_path, grant)
    grant["versionedSnapshotSha256"] = _sha256_file(snapshot_path)
    _write_json(GRANT_PATH, grant)
    print(json.dumps(grant, ensure_ascii=False, indent=2))


def _require_execution(
    *,
    execute: bool,
    confirmation: str | None,
    operation: str,
) -> None:
    if not execute:
        raise RuntimeError("External API operation requires --execute")
    _jobs, authorization = _load_contracts()
    expected = authorization["executionTokens"][operation]
    if confirmation != expected:
        raise RuntimeError(f"Exact confirmation token required for {operation}")
    if not GRANT_PATH.is_file():
        raise RuntimeError("Issue the one-time execution grant first")
    grant = _read_json(GRANT_PATH)
    if grant.get("contractHashes") != _contract_hashes():
        raise RuntimeError("Execution grant no longer matches current contracts")
    expires_at = datetime.fromisoformat(grant["expiresAt"])
    if datetime.now(UTC) >= expires_at:
        raise RuntimeError("Execution grant has expired")
    if grant.get("automaticRetries") != 0:
        raise RuntimeError("Automatic retry policy must remain zero")


def _load_ledger() -> dict[str, Any]:
    if not LEDGER_PATH.is_file():
        return {
            "schemaVersion": 1,
            "batchId": "p2-life-loop-v1",
            "automaticRetries": 0,
            "calls": [],
        }
    return _read_json(LEDGER_PATH)


def _assert_operation_available(
    *,
    capability: str,
    audio_id: str,
    maximum_calls: int,
) -> None:
    ledger = _load_ledger()
    attempted_calls = [
        call
        for call in ledger.get("calls", [])
        if call.get("capability") == capability
        and any(
            state.get("state") == "ATTEMPTED"
            for state in call.get("states", [])
        )
    ]
    prior_audio_call = next(
        (
            call
            for call in attempted_calls
            if call.get("audioId") == audio_id
        ),
        None,
    )
    if prior_audio_call is not None:
        raise RuntimeError(
            "Refusing regeneration because the API ledger already records "
            f"an attempted provider call for {capability}/{audio_id}; "
            "restore and audit the original output instead"
        )
    if len(attempted_calls) >= maximum_calls:
        raise RuntimeError(
            f"Authorized {capability} call limit is exhausted: "
            f"{len(attempted_calls)}/{maximum_calls}"
        )


def _record_call(
    local_request_id: str,
    *,
    capability: str,
    audio_id: str,
    state: str,
    endpoint: str,
    request_sha256: str,
    provider_headers: dict[str, str] | None = None,
    error: str | None = None,
) -> None:
    ledger = _load_ledger()
    call = next(
        (
            item
            for item in ledger["calls"]
            if item["localRequestId"] == local_request_id
        ),
        None,
    )
    if call is None:
        call = {
            "localRequestId": local_request_id,
            "capability": capability,
            "audioId": audio_id,
            "endpoint": endpoint,
            "requestSha256": request_sha256,
            "states": [],
        }
        if GRANT_PATH.is_file():
            grant = _read_json(GRANT_PATH)
            call["executionGrant"] = {
                "issuedAt": grant.get("issuedAt"),
                "sha256": _sha256_file(GRANT_PATH),
                "versionedSnapshotPath": grant.get(
                    "versionedSnapshotPath"
                ),
                "versionedSnapshotSha256": grant.get(
                    "versionedSnapshotSha256"
                ),
            }
        ledger["calls"].append(call)
    call["states"].append({"state": state, "at": _utc_now()})
    if provider_headers:
        call["providerRequestId"] = (
            provider_headers.get("request-id")
            or provider_headers.get("x-request-id")
            or provider_headers.get("xi-request-id")
        )
        call["traceId"] = provider_headers.get("x-trace-id")
        call["characterCost"] = provider_headers.get("character-cost")
        call["songId"] = provider_headers.get("song-id")
    if error:
        call["error"] = error[:1000]
    _write_json(LEDGER_PATH, ledger)


def _execute_recorded_request(
    *,
    capability: str,
    audio_id: str,
    endpoint: str,
    request_body: dict[str, Any],
    maximum_calls: int,
) -> tuple[bytes, dict[str, str], int, str]:
    _assert_operation_available(
        capability=capability,
        audio_id=audio_id,
        maximum_calls=maximum_calls,
    )
    local_request_id = uuid.uuid4().hex
    request_sha = _sha256_bytes(
        json.dumps(
            request_body,
            ensure_ascii=False,
            sort_keys=True,
            separators=(",", ":"),
        ).encode("utf-8")
    )
    _record_call(
        local_request_id,
        capability=capability,
        audio_id=audio_id,
        state="RESERVED",
        endpoint=endpoint.split("?", 1)[0],
        request_sha256=request_sha,
    )
    _record_call(
        local_request_id,
        capability=capability,
        audio_id=audio_id,
        state="ATTEMPTED",
        endpoint=endpoint.split("?", 1)[0],
        request_sha256=request_sha,
    )
    try:
        payload, headers, status = _request("POST", endpoint, request_body)
    except Exception as error:
        _record_call(
            local_request_id,
            capability=capability,
            audio_id=audio_id,
            state="FAILED_UNKNOWN_PROVIDER_STATE",
            endpoint=endpoint.split("?", 1)[0],
            request_sha256=request_sha,
            error=str(error),
        )
        raise
    _record_call(
        local_request_id,
        capability=capability,
        audio_id=audio_id,
        state="COMPLETED",
        endpoint=endpoint.split("?", 1)[0],
        request_sha256=request_sha,
        provider_headers=headers,
    )
    return payload, headers, status, local_request_id


def _request_metadata(
    *,
    kind: str,
    audio_id: str,
    endpoint: str,
    model: str,
    local_request_id: str,
    request_body: dict[str, Any],
    response_headers: dict[str, str],
    output_path: Path,
) -> dict[str, Any]:
    prompt = str(request_body.get("text", ""))
    return {
        "schemaVersion": 1,
        "batchId": "p2-life-loop-v1",
        "createdAt": _utc_now(),
        "kind": kind,
        "audioId": audio_id,
        "provider": "ElevenLabs",
        "capability": kind,
        "endpoint": endpoint,
        "model": model,
        "localRequestId": local_request_id,
        "request": request_body,
        "promptSha256": _sha256_bytes(prompt.encode("utf-8")) if prompt else None,
        "response": {
            "requestId": (
                response_headers.get("request-id")
                or response_headers.get("x-request-id")
                or response_headers.get("xi-request-id")
            ),
            "traceId": response_headers.get("x-trace-id"),
            "characterCost": response_headers.get("character-cost"),
            "songId": response_headers.get("song-id"),
            "contentType": response_headers.get("content-type"),
        },
        "output": {
            "path": str(output_path.resolve()),
            "bytes": output_path.stat().st_size,
            "sha256": _sha256_file(output_path),
        },
        "candidateOnly": True,
        "godotRuntimeApproved": False,
        "commercialReleaseAuthorized": False,
        "shippingApproval": False,
    }


def _pcm_metrics(payload: bytes) -> dict[str, Any]:
    if not payload or len(payload) % PCM_SAMPLE_WIDTH != 0:
        raise RuntimeError("PCM payload must be non-empty signed 16-bit LE audio")
    sample_count = len(payload) // PCM_SAMPLE_WIDTH
    if sample_count % PCM_CHANNELS != 0:
        raise RuntimeError("PCM payload must contain complete stereo frames")
    frame_count = sample_count // PCM_CHANNELS
    samples = struct.unpack(f"<{sample_count}h", payload)
    peak = max(abs(sample) for sample in samples) / 32768.0
    mean = sum(samples) / sample_count
    rms = math.sqrt(sum(sample * sample for sample in samples) / sample_count)
    clipped = sum(1 for sample in samples if abs(sample) >= 32767)
    return {
        "sampleRate": PCM_SAMPLE_RATE,
        "channels": PCM_CHANNELS,
        "sampleFormat": "PCM_S16LE",
        "sampleCount": sample_count,
        "frameCount": frame_count,
        "durationSeconds": frame_count / PCM_SAMPLE_RATE,
        "peakLinear": round(peak, 8),
        "rmsLinear": round(rms / 32768.0, 8),
        "dcOffsetLinear": round(mean / 32768.0, 8),
        "clippedSampleCount": clipped,
    }


def _write_review_wav(pcm_path: Path, wav_path: Path) -> dict[str, Any]:
    payload = pcm_path.read_bytes()
    target = _assert_owned_path(wav_path)
    target.parent.mkdir(parents=True, exist_ok=True)
    handle, temporary_name = tempfile.mkstemp(
        prefix=f".{target.name}.",
        suffix=".part",
        dir=target.parent,
    )
    os.close(handle)
    temporary = Path(temporary_name)
    try:
        with wave.open(str(temporary), "wb") as stream:
            stream.setnchannels(PCM_CHANNELS)
            stream.setsampwidth(PCM_SAMPLE_WIDTH)
            stream.setframerate(PCM_SAMPLE_RATE)
            stream.writeframes(payload)
        temporary.replace(target)
    finally:
        temporary.unlink(missing_ok=True)
    return {
        "path": str(target),
        "bytes": target.stat().st_size,
        "sha256": _sha256_file(target),
        "sourcePcmSha256": _sha256_bytes(payload),
        "containerOnlyDerivation": True,
    }


def repair_sfx_derivatives() -> None:
    jobs, _authorization = _load_contracts()
    repaired: list[str] = []
    for job in jobs["soundEffects"]:
        for variant in jobs["soundEffectVariants"]:
            stem = f"{Path(job['fileName']).stem}_{variant['id']}"
            pcm_path = CANDIDATE_ROOT / "sfx" / f"{stem}.pcm"
            wav_path = REVIEW_ROOT / "wav" / f"{stem}.wav"
            metadata_path = METADATA_ROOT / "sfx" / f"{stem}.metadata.json"
            if not pcm_path.is_file() or not metadata_path.is_file():
                raise RuntimeError(f"Cannot repair incomplete SFX candidate: {stem}")
            payload = pcm_path.read_bytes()
            metadata = _read_json(metadata_path)
            metadata["technicalMetrics"] = _pcm_metrics(payload)
            metadata["reviewWav"] = _write_review_wav(pcm_path, wav_path)
            metadata["derivedArtifactsRebuiltAt"] = _utc_now()
            _write_json(metadata_path, metadata)
            repaired.append(stem)
    print(
        json.dumps(
            {
                "batchId": jobs["batchId"],
                "repairedCount": len(repaired),
                "rawPcmModified": False,
                "channels": PCM_CHANNELS,
                "sampleRate": PCM_SAMPLE_RATE,
            },
            ensure_ascii=False,
            indent=2,
        )
    )


def dry_run() -> None:
    jobs, authorization = _load_contracts()
    variants = len(jobs["soundEffectVariants"])
    seconds = sum(
        float(job["durationSeconds"]) * variants for job in jobs["soundEffects"]
    )
    report = {
        "batchId": jobs["batchId"],
        "result": "passed",
        "writesPerformed": False,
        "apiCallsPerformed": False,
        "soundEffectCues": len(jobs["soundEffects"]),
        "soundEffectCandidates": len(jobs["soundEffects"]) * variants,
        "soundEffectRequestedSeconds": round(seconds, 3),
        "estimatedSfxApiCreditsAtCurrentDocumentedRate": math.ceil(seconds * 11),
        "musicCandidates": authorization["limits"]["musicCandidateCount"],
        "musicLengthMs": jobs["music"]["lengthMs"],
        "estimatedMusicUsdAtCurrentDocumentedRate": round(
            jobs["music"]["lengthMs"] / 60_000 * 0.15,
            4,
        ),
        "estimatesAreNotActualUsage": True,
        "maximumObservedCreditDelta": authorization["limits"][
            "maximumObservedCreditDelta"
        ],
        "allowUsageBasedOverage": False,
        "automaticRetries": 0,
        "outputRoot": str(BATCH_ROOT.resolve()),
    }
    print(json.dumps(report, ensure_ascii=False, indent=2))


def create_plan(*, execute: bool, confirmation: str | None) -> None:
    _require_execution(execute=execute, confirmation=confirmation, operation="plan")
    jobs, _authorization = _load_contracts()
    if PLAN_PATH.exists():
        print(f"SKIP existing composition plan: {PLAN_PATH}")
        return
    _assert_operation_available(
        capability="music-composition-plan",
        audio_id=jobs["music"]["audioId"],
        maximum_calls=1,
    )
    before = _subscription()
    music = jobs["music"]
    request_body = {
        "prompt": music["prompt"],
        "music_length_ms": music["lengthMs"],
        "model_id": jobs["musicModel"],
    }
    payload, headers, status, local_request_id = _execute_recorded_request(
        capability="music-composition-plan",
        audio_id=music["audioId"],
        endpoint="/music/plan",
        request_body=request_body,
        maximum_calls=1,
    )
    if status != 200:
        raise RuntimeError(f"Unexpected composition-plan status: {status}")
    plan = json.loads(payload.decode("utf-8"))
    _write_json(PLAN_PATH, plan)
    metadata = {
        "schemaVersion": 1,
        "batchId": jobs["batchId"],
        "createdAt": _utc_now(),
        "kind": "music-composition-plan",
        "audioId": music["audioId"],
        "provider": jobs["provider"],
        "endpoint": "/v1/music/plan",
        "model": jobs["musicModel"],
        "localRequestId": local_request_id,
        "request": request_body,
        "response": {
            "requestId": headers.get("request-id"),
            "traceId": headers.get("x-trace-id"),
            "contentType": headers.get("content-type"),
        },
        "output": {
            "path": str(PLAN_PATH.resolve()),
            "bytes": PLAN_PATH.stat().st_size,
            "sha256": _sha256_file(PLAN_PATH),
        },
        "subscriptionBefore": before,
        "subscriptionAfter": _subscription(),
        "creditsExpected": 0,
        "candidateOnly": True,
        "shippingApproval": False,
    }
    _write_json(METADATA_ROOT / "h01_spring_day.plan.metadata.json", metadata)
    print(json.dumps(metadata, ensure_ascii=False, indent=2))


def generate_sfx(*, execute: bool, confirmation: str | None) -> None:
    _require_execution(
        execute=execute,
        confirmation=confirmation,
        operation="soundEffects",
    )
    jobs, authorization = _load_contracts()
    before: dict[str, Any] = {}
    generated: list[dict[str, Any]] = []
    for job in jobs["soundEffects"]:
        for variant in jobs["soundEffectVariants"]:
            stem = f"{Path(job['fileName']).stem}_{variant['id']}"
            audio_id = f"{job['audioId']}.{variant['id']}"
            output_path = CANDIDATE_ROOT / "sfx" / f"{stem}.pcm"
            review_path = REVIEW_ROOT / "wav" / f"{stem}.wav"
            metadata_path = METADATA_ROOT / "sfx" / f"{stem}.metadata.json"
            if (
                output_path.exists()
                or review_path.exists()
                or metadata_path.exists()
            ):
                if not (
                    output_path.exists()
                    and review_path.exists()
                    and metadata_path.exists()
                ):
                    raise RuntimeError(
                        f"Partial prior SFX output requires audit: {audio_id}"
                    )
                print(f"SKIP existing SFX candidate: {audio_id}")
                continue
            _assert_operation_available(
                capability="sound-effect",
                audio_id=audio_id,
                maximum_calls=authorization["limits"][
                    "soundEffectCandidateCount"
                ],
            )
            if not before:
                before = _subscription()
            prompt = f"{job['prompt']} {variant['modifier']}"
            request_body = {
                "text": prompt,
                "loop": job["loop"],
                "duration_seconds": job["durationSeconds"],
                "prompt_influence": job["promptInfluence"],
                "model_id": jobs["soundEffectModel"],
            }
            output_format = urllib.parse.quote(jobs["soundEffectOutputFormat"])
            endpoint = f"/sound-generation?output_format={output_format}"
            payload, headers, status, local_request_id = (
                _execute_recorded_request(
                    capability="sound-effect",
                    audio_id=audio_id,
                    endpoint=endpoint,
                    request_body=request_body,
                    maximum_calls=authorization["limits"][
                        "soundEffectCandidateCount"
                    ],
                )
            )
            content_type = headers.get("content-type", "")
            if status != 200 or "audio" not in content_type:
                raise RuntimeError(
                    f"Unexpected SFX response for {audio_id}: "
                    f"status={status}, content_type={content_type}"
                )
            metrics = _pcm_metrics(payload)
            _atomic_write(output_path, payload)
            review = _write_review_wav(output_path, review_path)
            metadata = _request_metadata(
                kind="sound-effect",
                audio_id=audio_id,
                endpoint="/v1/sound-generation",
                model=jobs["soundEffectModel"],
                local_request_id=local_request_id,
                request_body=request_body,
                response_headers=headers,
                output_path=output_path,
            )
            metadata["technicalMetrics"] = metrics
            metadata["reviewWav"] = review
            _write_json(metadata_path, metadata)
            generated.append(metadata)
            print(
                f"GENERATED {audio_id} {metrics['durationSeconds']:.3f}s "
                f"{metadata['output']['sha256']}"
            )
    if not generated:
        print("SKIP no ungenerated SFX candidates remain")
        return
    after = _subscription()
    delta = int(after["creditUsed"] or 0) - int(before["creditUsed"] or 0)
    if delta > authorization["limits"]["maximumObservedCreditDelta"]:
        raise RuntimeError(f"Observed credit delta exceeds authorization: {delta}")
    summary = {
        "schemaVersion": 1,
        "batchId": jobs["batchId"],
        "createdAt": _utc_now(),
        "phase": "sound-effects",
        "generatedCount": len(generated),
        "subscriptionBefore": before,
        "subscriptionAfter": after,
        "observedCreditDelta": delta,
        "allowUsageBasedOverage": False,
    }
    _write_json(METADATA_ROOT / "sfx-generation-summary.json", summary)
    print(json.dumps(summary, ensure_ascii=False, indent=2))


def _parse_detailed_music(
    content_type: str,
    payload: bytes,
) -> tuple[bytes, dict[str, Any]]:
    if "multipart/" not in content_type:
        raise RuntimeError(
            f"Detailed music response must be multipart: {content_type}"
        )
    envelope = (
        f"Content-Type: {content_type}\r\nMIME-Version: 1.0\r\n\r\n".encode(
            "ascii"
        )
        + payload
    )
    message = BytesParser(policy=policy.default).parsebytes(envelope)
    audio: bytes | None = None
    details: dict[str, Any] = {}
    for part in message.iter_parts():
        part_payload = part.get_payload(decode=True) or b""
        part_type = part.get_content_type()
        if part_type.startswith("audio/"):
            audio = part_payload
        elif part_type == "application/json":
            details = json.loads(part_payload.decode("utf-8"))
    if audio is None:
        raise RuntimeError("Detailed music response contains no audio part")
    return audio, details


def generate_music(*, execute: bool, confirmation: str | None) -> None:
    _require_execution(
        execute=execute,
        confirmation=confirmation,
        operation="music",
    )
    jobs, authorization = _load_contracts()
    if not PLAN_PATH.exists():
        raise RuntimeError("Create and audit the music composition plan first")
    output_path = CANDIDATE_ROOT / "music" / jobs["music"]["fileName"]
    metadata_path = METADATA_ROOT / "music" / "h01_spring_day.metadata.json"
    details_path = METADATA_ROOT / "music" / "h01_spring_day.provider.json"
    if output_path.exists() or metadata_path.exists() or details_path.exists():
        if not (
            output_path.exists()
            and metadata_path.exists()
            and details_path.exists()
        ):
            raise RuntimeError("Partial prior music output requires manual audit")
        print(f"SKIP existing music candidate: {jobs['music']['audioId']}")
        return
    _assert_operation_available(
        capability="music",
        audio_id=jobs["music"]["audioId"],
        maximum_calls=authorization["limits"]["musicCandidateCount"],
    )
    before = _subscription()
    plan = _read_json(PLAN_PATH)
    request_body = {
        "composition_plan": plan,
        "model_id": jobs["musicModel"],
        "store_for_inpainting": True,
    }
    output_format = urllib.parse.quote(jobs["musicOutputFormat"])
    endpoint = f"/music/detailed?output_format={output_format}"
    payload, headers, status, local_request_id = _execute_recorded_request(
        capability="music",
        audio_id=jobs["music"]["audioId"],
        endpoint=endpoint,
        request_body=request_body,
        maximum_calls=authorization["limits"]["musicCandidateCount"],
    )
    if status != 200:
        raise RuntimeError(f"Unexpected music response status: {status}")
    audio, details = _parse_detailed_music(
        headers.get("content-type", ""),
        payload,
    )
    if not (audio.startswith(b"ID3") or audio[:2] == b"\xff\xfb"):
        raise RuntimeError(f"Detailed music audio is not MP3: {audio[:12]!r}")
    _atomic_write(output_path, audio)
    _write_json(details_path, details)
    metadata = _request_metadata(
        kind="music",
        audio_id=jobs["music"]["audioId"],
        endpoint="/v1/music/detailed",
        model=jobs["musicModel"],
        local_request_id=local_request_id,
        request_body={"compositionPlanSha256": _sha256_file(PLAN_PATH)},
        response_headers=headers,
        output_path=output_path,
    )
    after = _subscription()
    delta = int(after["creditUsed"] or 0) - int(before["creditUsed"] or 0)
    if delta > authorization["limits"]["maximumObservedCreditDelta"]:
        raise RuntimeError(f"Observed credit delta exceeds authorization: {delta}")
    metadata["providerDetails"] = {
        "path": str(details_path.resolve()),
        "bytes": details_path.stat().st_size,
        "sha256": _sha256_file(details_path),
    }
    metadata["subscriptionBefore"] = before
    metadata["subscriptionAfter"] = after
    metadata["observedCreditDelta"] = delta
    _write_json(metadata_path, metadata)
    print(json.dumps(metadata, ensure_ascii=False, indent=2))


def verify() -> None:
    jobs, authorization = _load_contracts()
    checks: list[dict[str, Any]] = []
    for job in jobs["soundEffects"]:
        for variant in jobs["soundEffectVariants"]:
            stem = f"{Path(job['fileName']).stem}_{variant['id']}"
            audio_id = f"{job['audioId']}.{variant['id']}"
            pcm_path = CANDIDATE_ROOT / "sfx" / f"{stem}.pcm"
            wav_path = REVIEW_ROOT / "wav" / f"{stem}.wav"
            metadata_path = METADATA_ROOT / "sfx" / f"{stem}.metadata.json"
            exists = (
                pcm_path.is_file()
                and wav_path.is_file()
                and metadata_path.is_file()
            )
            metadata = _read_json(metadata_path) if metadata_path.is_file() else {}
            hash_matches = (
                exists
                and metadata.get("output", {}).get("sha256")
                == _sha256_file(pcm_path)
                and metadata.get("reviewWav", {}).get("sourcePcmSha256")
                == _sha256_file(pcm_path)
            )
            metrics_match = (
                exists
                and metadata.get("technicalMetrics", {}).get("sampleRate")
                == PCM_SAMPLE_RATE
                and metadata.get("technicalMetrics", {}).get("channels")
                == PCM_CHANNELS
                and metadata.get("technicalMetrics", {}).get("sampleFormat")
                == "PCM_S16LE"
                and pcm_path.stat().st_size
                % (PCM_SAMPLE_WIDTH * PCM_CHANNELS)
                == 0
            )
            checks.append(
                {
                    "audioId": audio_id,
                    "exists": exists,
                    "hashMatches": hash_matches,
                    "pcmContractMatches": metrics_match,
                    "passed": exists and hash_matches and metrics_match,
                }
            )
    music_path = CANDIDATE_ROOT / "music" / jobs["music"]["fileName"]
    music_metadata_path = (
        METADATA_ROOT / "music" / "h01_spring_day.metadata.json"
    )
    music_details_path = (
        METADATA_ROOT / "music" / "h01_spring_day.provider.json"
    )
    music_exists = (
        music_path.is_file()
        and music_metadata_path.is_file()
        and music_details_path.is_file()
    )
    music_metadata = (
        _read_json(music_metadata_path) if music_metadata_path.is_file() else {}
    )
    music_hash_matches = (
        music_exists
        and music_metadata.get("output", {}).get("sha256")
        == _sha256_file(music_path)
    )
    music_signature = music_exists and (
        music_path.read_bytes()[:3] == b"ID3"
        or music_path.read_bytes()[:2] == b"\xff\xfb"
    )
    checks.append(
        {
            "audioId": jobs["music"]["audioId"],
            "exists": music_exists,
            "hashMatches": music_hash_matches,
            "mp3Signature": music_signature,
            "passed": music_exists and music_hash_matches and music_signature,
        }
    )
    expected_count = (
        authorization["limits"]["soundEffectCandidateCount"]
        + authorization["limits"]["musicCandidateCount"]
    )
    ledger = _load_ledger()
    completed_calls = [
        call
        for call in ledger.get("calls", [])
        if call.get("states", [])
        and call["states"][-1].get("state") == "COMPLETED"
    ]
    failed_unknown_calls = [
        call
        for call in ledger.get("calls", [])
        if any(
            state.get("state") == "FAILED_UNKNOWN_PROVIDER_STATE"
            for state in call.get("states", [])
        )
    ]
    provider_identifiers = [
        call.get("providerRequestId")
        or call.get("traceId")
        or call.get("songId")
        for call in completed_calls
    ]
    expected_api_calls = (
        authorization["limits"]["soundEffectCandidateCount"]
        + authorization["limits"]["musicCandidateCount"]
        + 1
    )
    ledger_passed = (
        len(completed_calls) == expected_api_calls
        and not failed_unknown_calls
        and all(provider_identifiers)
        and len(set(provider_identifiers)) == len(provider_identifiers)
    )
    no_partial_files = not any(BATCH_ROOT.rglob("*.part"))
    passed = (
        len(checks) == expected_count
        and all(check["passed"] for check in checks)
        and ledger_passed
        and no_partial_files
    )
    report = {
        "schemaVersion": 1,
        "batchId": jobs["batchId"],
        "verifiedAt": _utc_now(),
        "result": "passed" if passed else "failed",
        "expectedCandidateCount": expected_count,
        "actualCandidateCount": len(checks),
        "noPartialFiles": no_partial_files,
        "apiLedger": {
            "expectedCompletedCalls": expected_api_calls,
            "actualCompletedCalls": len(completed_calls),
            "failedUnknownProviderStateCount": len(failed_unknown_calls),
            "providerIdentifiersPresentAndUnique": (
                all(provider_identifiers)
                and len(set(provider_identifiers))
                == len(provider_identifiers)
            ),
            "automaticRetries": ledger.get("automaticRetries"),
            "passed": ledger_passed,
        },
        "checks": checks,
        "subjectiveListeningApproval": False,
        "shippingApproval": False,
    }
    _write_json(BATCH_ROOT / "P2_AUDIO_CANDIDATE_VERIFICATION.json", report)
    print(json.dumps(report, ensure_ascii=False, indent=2))
    if not passed:
        raise RuntimeError("P2 audio candidate verification failed")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    operation = parser.add_mutually_exclusive_group(required=True)
    operation.add_argument("--dry-run", action="store_true")
    operation.add_argument("--issue-grant", action="store_true")
    operation.add_argument("--subscription", action="store_true")
    operation.add_argument("--repair-sfx-derivatives", action="store_true")
    operation.add_argument("--plan", action="store_true")
    operation.add_argument("--generate-sfx", action="store_true")
    operation.add_argument("--generate-music", action="store_true")
    operation.add_argument("--verify", action="store_true")
    parser.add_argument("--execute", action="store_true")
    parser.add_argument("--confirm")
    args = parser.parse_args()
    if args.dry_run:
        dry_run()
    elif args.issue_grant:
        issue_grant()
    elif args.subscription:
        print(json.dumps(_subscription(), ensure_ascii=False, indent=2))
    elif args.repair_sfx_derivatives:
        repair_sfx_derivatives()
    elif args.plan:
        create_plan(execute=args.execute, confirmation=args.confirm)
    elif args.generate_sfx:
        generate_sfx(execute=args.execute, confirmation=args.confirm)
    elif args.generate_music:
        generate_music(execute=args.execute, confirmation=args.confirm)
    else:
        verify()


if __name__ == "__main__":
    try:
        main()
    except Exception as error:  # noqa: BLE001 - fail closed with one message.
        print(f"ERROR: {error}", file=sys.stderr)
        raise SystemExit(1) from error
