from __future__ import annotations

import argparse
import hashlib
import json
from collections.abc import Collection
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Sequence, TextIO

ANALYSIS_SCHEMA_VERSION = 1
EVIDENCE_SCHEMA_VERSION = 1
MINIMUM_DIRECTIONAL_HUMAN_SAMPLES = 5
MAXIMUM_EVENTS_PER_SESSION = 2048
MAXIMUM_PROPERTIES_PER_EVENT = 24
MAXIMUM_JSON_LINE_CHARACTERS = 16384
MAXIMUM_SIGNED_64_BIT_INTEGER = 9_223_372_036_854_775_807

EVENT_SESSION_STARTED = "p2.pacing.session_started"
EVENT_OBJECTIVE_CHANGED = "p2.pacing.objective_changed"
EVENT_ACTION_COMMITTED = "p2.pacing.action_committed"
EVENT_SESSION_ENDED = "p2.pacing.session_ended"

RUN_KIND_HUMAN = "human_internal"
RUN_KIND_AUTOMATION = "automation"
STARTING_STATE_FRESH = "fresh"
STARTING_STATE_RESUMED = "resumed"

ACTION_RESOURCE_SEED = "home.h01.resource.north_meadow"
ACTION_RESOURCE_FORAGE = "home.h01.resource.north_meadow.forage"
ACTION_TILL = "farm.tilled"
ACTION_PLANT = "farm.planted"
ACTION_WATER = "farm.watered"
ACTION_REST = "day.rested"
ACTION_HARVEST = "farm.harvested"
ACTION_SELL = "economy.h01.sell_mistleaf"
ACTION_BUY_SEED = "economy.h01.buy_mistleaf_seed"

RESOURCE_ACTIONS = {
    ACTION_RESOURCE_SEED,
    ACTION_RESOURCE_FORAGE,
}
ORDERED_LOOP_ACTIONS = (
    ACTION_TILL,
    ACTION_PLANT,
    ACTION_WATER,
    ACTION_REST,
    ACTION_HARVEST,
    ACTION_SELL,
)
ALLOWED_ACTIONS = RESOURCE_ACTIONS | set(ORDERED_LOOP_ACTIONS) | {
    ACTION_BUY_SEED,
}
ALLOWED_EVENTS = {
    EVENT_SESSION_STARTED,
    EVENT_OBJECTIVE_CHANGED,
    EVENT_ACTION_COMMITTED,
    EVENT_SESSION_ENDED,
}
ALLOWED_RUN_KINDS = {
    RUN_KIND_HUMAN,
    RUN_KIND_AUTOMATION,
}
ALLOWED_SCENARIO_IDS = {
    "p2.h01.life_loop",
}
ALLOWED_INPUT_DEVICE_FAMILIES = {
    "mixed_or_unknown",
    "keyboard_mouse",
    "gamepad",
}
ALLOWED_STARTING_STATE_KINDS = {
    STARTING_STATE_FRESH,
    STARTING_STATE_RESUMED,
}
ALLOWED_MAP_IDS = {
    "home_h01_open_meadow",
}
ALLOWED_OBJECTIVES = {
    "p2.h01.guide.harvest",
    "p2.h01.guide.missing_watering_can",
    "p2.h01.guide.water",
    "p2.h01.guide.sell_for_space",
    "p2.h01.guide.sell",
    "p2.h01.guide.claim_daily",
    "p2.h01.guide.rest_growth",
    "p2.h01.guide.plant",
    "p2.h01.guide.missing_hoe",
    "p2.h01.guide.till",
    "p2.h01.guide.buy_seed",
    "p2.h01.guide.rest_resources",
    "p2.h01.guide.inventory_blocked",
    "p2.h01.guide.unavailable",
}
ALLOWED_OUTCOMES = {
    "complete_loop",
    "incomplete",
    "excluded_resumed",
}
REGISTERED_BUILD_REVISIONS = {
    "p2.pacing.instrumentation.v1",
}
REGISTERED_CONTENT_REVISIONS = {
    "p2.h01.balance.v1",
}

TOP_LEVEL_KEYS = {
    "evidenceSchemaVersion",
    "sessionId",
    "sequence",
    "recordedAtUnixMs",
    "eventName",
    "properties",
}
COMMON_PROPERTY_KEYS = {
    "evidenceSchemaVersion",
    "runKind",
    "scenarioId",
    "inputDeviceFamily",
    "startingStateKind",
    "buildRevision",
    "contentRevision",
    "elapsedMs",
    "mapId",
    "worldDay",
    "objectiveId",
    "farmTileCount",
    "cropCount",
    "seedCount",
    "forageCount",
    "scripCount",
}
SESSION_CONSTANT_KEYS = (
    "runKind",
    "scenarioId",
    "inputDeviceFamily",
    "startingStateKind",
    "buildRevision",
    "contentRevision",
    "mapId",
)
SNAPSHOT_KEYS = (
    "worldDay",
    "farmTileCount",
    "cropCount",
    "seedCount",
    "forageCount",
    "scripCount",
)
COUNT_KEYS = {
    "farmTileCount",
    "cropCount",
    "seedCount",
    "forageCount",
    "scripCount",
    "unknownActionCount",
}
SAFE_SESSION_ID_CHARACTERS = frozenset(
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    "abcdefghijklmnopqrstuvwxyz"
    "0123456789_-"
)


@dataclass(frozen=True)
class IntegrityIssue:
    source: str
    line: int
    code: str
    message: str

    def as_dict(self) -> dict[str, object]:
        return {
            "source": self.source,
            "line": self.line,
            "code": self.code,
            "message": self.message,
        }


class DuplicateJsonKeyError(ValueError):
    """Raised when one JSON object tries to redefine a key."""


@dataclass(frozen=True)
class ActionObservation:
    action_id: str
    elapsed_ms: int


@dataclass(frozen=True)
class ValidSession:
    source: str
    run_kind: str
    input_device_family: str
    starting_state_kind: str
    build_revision: str
    content_revision: str
    outcome: str
    duration_ms: int
    actions: tuple[ActionObservation, ...]
    canonical_fingerprint: str

    @property
    def is_structurally_complete_self_declared_human(self) -> bool:
        return (
            self.run_kind == RUN_KIND_HUMAN
            and self.starting_state_kind == STARTING_STATE_FRESH
            and self.outcome == "complete_loop"
        )

    def first_resource_action(self) -> str | None:
        for action in self.actions:
            if action.action_id in RESOURCE_ACTIONS:
                return action.action_id
        return None


def analyze_directory(directory: Path) -> dict[str, object]:
    evidence_directory = _canonical_d_drive_path(
        Path(directory),
        kind="evidence directory",
    )
    if not evidence_directory.is_dir():
        raise FileNotFoundError("evidence directory does not exist")

    try:
        source_files = sorted(
            evidence_directory.glob("p2-pacing-*.jsonl"),
            key=lambda path: path.name,
        )
    except OSError as error:
        raise OSError("evidence directory could not be enumerated") from error

    issues: list[IntegrityIssue] = []
    unique_sessions: list[ValidSession] = []
    fingerprint_sources: dict[str, str] = {}
    for source_index, source_file in enumerate(source_files, start=1):
        source = f"source-{source_index:04d}"
        if not _is_regular_d_drive_source(
            source_file,
            evidence_directory,
        ):
            issues.append(
                IntegrityIssue(
                    source=source,
                    line=0,
                    code="unsafe_source_path",
                    message=(
                        "evidence source must be a regular file inside "
                        "the registered D-drive directory"
                    ),
                )
            )
            continue
        session, file_issues = _parse_session(source_file, source)
        issues.extend(file_issues)
        if session is None or file_issues:
            continue
        first_source = fingerprint_sources.get(session.canonical_fingerprint)
        if first_source is not None:
            issues.append(
                IntegrityIssue(
                    source=source,
                    line=0,
                    code="duplicate_session_payload",
                    message=(
                        "session payload duplicates an earlier evidence source"
                    ),
                )
            )
            continue
        fingerprint_sources[session.canonical_fingerprint] = source
        unique_sessions.append(session)

    self_declared_human_fresh = [
        session
        for session in unique_sessions
        if session.run_kind == RUN_KIND_HUMAN
        and session.starting_state_kind == STARTING_STATE_FRESH
    ]
    structurally_complete_candidates = [
        session
        for session in self_declared_human_fresh
        if session.is_structurally_complete_self_declared_human
    ]
    report_usable = not issues
    revision_groups = _revision_groups(
        self_declared_human_fresh,
        report_usable=report_usable,
    )
    largest_compatible = max(
        (
            int(
                group[
                    "structurallyCompleteSelfDeclaredHumanSessionCount"
                ]
            )
            for group in revision_groups
        ),
        default=0,
    )
    candidate_groups = [
        group
        for group in revision_groups
        if bool(group["candidateSetReadyForHumanAttestation"])
    ]
    candidate_ready = report_usable and bool(candidate_groups)
    candidate_revisions = (
        [
            {
                "buildRevision": group["buildRevision"],
                "contentRevision": group["contentRevision"],
            }
            for group in candidate_groups
        ]
        if candidate_ready
        else []
    )
    gate_status = "insufficient_human_samples"
    if not report_usable:
        gate_status = "integrity_issues"
    elif candidate_ready:
        gate_status = "human_attestation_required"

    return {
        "analysisSchemaVersion": ANALYSIS_SCHEMA_VERSION,
        "evidenceSchemaVersion": EVIDENCE_SCHEMA_VERSION,
        "sourceFileCount": len(source_files),
        "structurallyValidUniqueSessionCount": len(unique_sessions),
        "selfDeclaredHumanFreshSessionCount": len(
            self_declared_human_fresh
        ),
        "structurallyCompleteSelfDeclaredHumanSessionCount": len(
            structurally_complete_candidates
        ),
        "automationSessionCount": sum(
            session.run_kind == RUN_KIND_AUTOMATION
            for session in unique_sessions
        ),
        "excludedResumedSelfDeclaredHumanSessionCount": sum(
            session.run_kind == RUN_KIND_HUMAN
            and session.starting_state_kind == STARTING_STATE_RESUMED
            and session.outcome == "excluded_resumed"
            for session in unique_sessions
        ),
        "integrityIssueCount": len(issues),
        "integrityIssues": [
            issue.as_dict()
            for issue in sorted(
                issues,
                key=lambda issue: (
                    issue.source,
                    issue.line,
                    issue.code,
                    issue.message,
                ),
            )
        ],
        "compatibleRevisionGroups": revision_groups,
        "reportUsable": report_usable,
        "candidateSetReadyForHumanAttestation": candidate_ready,
        # JSONL can only carry a self-declaration. A person must explicitly
        # attest who played and then review the direction outside this tool.
        "humanEvidenceCollected": False,
        "directionalReviewReady": False,
        "decisionGate": {
            "status": gate_status,
            "minimumCompatibleStructurallyCompleteSelfDeclaredHumanSamples": (
                MINIMUM_DIRECTIONAL_HUMAN_SAMPLES
            ),
            "largestCompatibleStructurallyCompleteCandidateSample": (
                largest_compatible
            ),
            "candidateRevisionsAwaitingHumanAttestation": (
                candidate_revisions
            ),
        },
        "designDecisionReviewed": False,
        "p2CompletionClaimAllowed": False,
    }


def _parse_session(
    path: Path,
    source: str,
) -> tuple[ValidSession | None, list[IntegrityIssue]]:
    records, issues = _read_bounded_jsonl(path, source)
    if not records:
        return None, issues

    expected_session_id = path.name.removeprefix("p2-pacing-").removesuffix(
        ".jsonl"
    )
    previous_recorded_at: int | None = None
    previous_elapsed_ms: int | None = None
    constants: dict[str, object] | None = None
    for line_number, record in enumerate(records, start=1):
        _validate_exact_keys(
            source,
            line_number,
            record,
            TOP_LEVEL_KEYS,
            "top_level",
            issues,
        )
        if not _is_int(record.get("evidenceSchemaVersion"), minimum=1):
            _issue(
                issues,
                source,
                line_number,
                "invalid_evidence_schema",
                "top-level evidence schema must be registered integer 1",
            )
        elif record["evidenceSchemaVersion"] != EVIDENCE_SCHEMA_VERSION:
            _issue(
                issues,
                source,
                line_number,
                "unsupported_evidence_schema",
                "only evidence schema version 1 is supported",
            )

        session_id = record.get("sessionId")
        if not _is_safe_session_id(session_id):
            _issue(
                issues,
                source,
                line_number,
                "unsafe_session_id",
                "session identifier is outside the registered safe syntax",
            )
        elif session_id != expected_session_id:
            _issue(
                issues,
                source,
                line_number,
                "session_filename_mismatch",
                "session identifier does not match its evidence source",
            )

        sequence = record.get("sequence")
        if (
            not _is_int(
                sequence,
                minimum=1,
                maximum=MAXIMUM_EVENTS_PER_SESSION,
            )
            or sequence != line_number
        ):
            _issue(
                issues,
                source,
                line_number,
                "sequence_mismatch",
                "sequence must be contiguous, one-based, and ordered",
            )

        recorded_at = record.get("recordedAtUnixMs")
        if not _is_int(recorded_at, minimum=1):
            _issue(
                issues,
                source,
                line_number,
                "invalid_recorded_time",
                "recorded wall-clock time must be a positive integer",
            )
        elif (
            previous_recorded_at is not None
            and recorded_at < previous_recorded_at
        ):
            _issue(
                issues,
                source,
                line_number,
                "recorded_time_regressed",
                "wall-clock audit time cannot regress",
            )
        else:
            previous_recorded_at = recorded_at

        event_name = record.get("eventName")
        if not isinstance(event_name, str) or event_name not in ALLOWED_EVENTS:
            _issue(
                issues,
                source,
                line_number,
                "unknown_event",
                "event is outside the registered P2 evidence vocabulary",
            )

        properties = record.get("properties")
        if not isinstance(properties, dict):
            _issue(
                issues,
                source,
                line_number,
                "properties_not_object",
                "properties must be a flat JSON object",
            )
            continue
        if len(properties) > MAXIMUM_PROPERTIES_PER_EVENT:
            _issue(
                issues,
                source,
                line_number,
                "property_limit_exceeded",
                "event exceeds the registered property limit",
            )
        expected_properties = set(COMMON_PROPERTY_KEYS)
        if event_name == EVENT_ACTION_COMMITTED:
            expected_properties.add("actionId")
        elif event_name == EVENT_SESSION_ENDED:
            expected_properties.update({"outcome", "unknownActionCount"})
        _validate_exact_keys(
            source,
            line_number,
            properties,
            expected_properties,
            "property",
            issues,
        )
        _validate_properties(
            source,
            line_number,
            properties,
            event_name,
            issues,
        )

        elapsed_ms = properties.get("elapsedMs")
        if _is_int(elapsed_ms, minimum=0):
            if (
                previous_elapsed_ms is not None
                and elapsed_ms < previous_elapsed_ms
            ):
                _issue(
                    issues,
                    source,
                    line_number,
                    "elapsed_time_regressed",
                    "monotonic elapsed time cannot regress",
                )
            previous_elapsed_ms = elapsed_ms

        current_constants = {
            key: properties.get(key) for key in SESSION_CONSTANT_KEYS
        }
        if constants is None:
            constants = current_constants
        elif current_constants != constants:
            _issue(
                issues,
                source,
                line_number,
                "session_constants_changed",
                "session identity or revision changed within one source",
            )

    _validate_event_topology(source, records, issues)
    if issues:
        return None, issues

    _validate_state_transitions(source, records, issues)
    _validate_declared_human_timing(source, records, issues)
    if issues:
        return None, issues

    started_properties = records[0]["properties"]
    ended_properties = records[-1]["properties"]
    started_elapsed_ms = started_properties["elapsedMs"]
    actions = tuple(
        ActionObservation(
            action_id=record["properties"]["actionId"],
            elapsed_ms=(
                record["properties"]["elapsedMs"] - started_elapsed_ms
            ),
        )
        for record in records
        if record["eventName"] == EVENT_ACTION_COMMITTED
    )
    expected_outcome = _expected_outcome(
        started_properties["startingStateKind"],
        (action.action_id for action in actions),
    )
    if ended_properties["outcome"] != expected_outcome:
        _issue(
            issues,
            source,
            len(records),
            "outcome_mismatch",
            "session outcome does not match the registered action sequence",
        )
        return None, issues
    if ended_properties["unknownActionCount"] != 0:
        _issue(
            issues,
            source,
            len(records),
            "unknown_action_observed",
            "session contains an action outside the registered vocabulary",
        )
        return None, issues

    return (
        ValidSession(
            source=source,
            run_kind=started_properties["runKind"],
            input_device_family=started_properties["inputDeviceFamily"],
            starting_state_kind=started_properties["startingStateKind"],
            build_revision=started_properties["buildRevision"],
            content_revision=started_properties["contentRevision"],
            outcome=ended_properties["outcome"],
            duration_ms=(
                ended_properties["elapsedMs"] - started_elapsed_ms
            ),
            actions=actions,
            canonical_fingerprint=_fingerprint_without_session_id(records),
        ),
        issues,
    )


def _read_bounded_jsonl(
    path: Path,
    source: str,
) -> tuple[list[dict[str, Any]], list[IntegrityIssue]]:
    records: list[dict[str, Any]] = []
    issues: list[IntegrityIssue] = []
    try:
        with path.open("r", encoding="utf-8", newline="") as handle:
            _read_jsonl_stream(handle, source, records, issues)
    except (OSError, UnicodeError):
        return [], [
            IntegrityIssue(
                source=source,
                line=0,
                code="unreadable_file",
                message="evidence source is not readable UTF-8",
            )
        ]
    if not records and not issues:
        issues.append(
            IntegrityIssue(
                source=source,
                line=0,
                code="empty_file",
                message="evidence source contains no records",
            )
        )
    return records, issues


def _read_jsonl_stream(
    handle: TextIO,
    source: str,
    records: list[dict[str, Any]],
    issues: list[IntegrityIssue],
) -> None:
    line_number = 0
    read_limit = MAXIMUM_JSON_LINE_CHARACTERS + 3
    while True:
        raw_line = handle.readline(read_limit)
        if raw_line == "":
            return
        line_number += 1
        if line_number > MAXIMUM_EVENTS_PER_SESSION:
            _issue(
                issues,
                source,
                0,
                "event_limit_exceeded",
                "evidence source exceeds the registered event limit",
            )
            return
        line = raw_line.rstrip("\r\n")
        if len(line) > MAXIMUM_JSON_LINE_CHARACTERS:
            _issue(
                issues,
                source,
                line_number,
                "line_limit_exceeded",
                "JSONL record exceeds the registered character limit",
            )
            return
        if not line.strip():
            _issue(
                issues,
                source,
                line_number,
                "blank_line",
                "JSONL records cannot contain blank lines",
            )
            continue
        try:
            raw_record = json.loads(
                line,
                object_pairs_hook=_reject_duplicate_json_keys,
            )
        except DuplicateJsonKeyError:
            _issue(
                issues,
                source,
                line_number,
                "duplicate_json_key",
                "JSON objects cannot redefine a key",
            )
            continue
        except (json.JSONDecodeError, ValueError, RecursionError):
            _issue(
                issues,
                source,
                line_number,
                "invalid_json",
                "record is not valid bounded JSON",
            )
            continue
        if not isinstance(raw_record, dict):
            _issue(
                issues,
                source,
                line_number,
                "record_not_object",
                "each evidence record must be a JSON object",
            )
            continue
        records.append(raw_record)


def _validate_event_topology(
    source: str,
    records: Sequence[dict[str, Any]],
    issues: list[IntegrityIssue],
) -> None:
    if not records:
        return
    event_names = [record.get("eventName") for record in records]
    if event_names[0] != EVENT_SESSION_STARTED:
        _issue(
            issues,
            source,
            1,
            "session_start_missing",
            "the first record must start the session",
        )
    if len(event_names) < 2 or event_names[1] != EVENT_OBJECTIVE_CHANGED:
        _issue(
            issues,
            source,
            min(2, len(event_names)),
            "initial_objective_missing",
            "the second record must capture the initial objective",
        )
    if event_names.count(EVENT_SESSION_STARTED) != 1:
        _issue(
            issues,
            source,
            0,
            "session_start_count",
            "a session must contain exactly one start event",
        )
    ended_count = event_names.count(EVENT_SESSION_ENDED)
    if ended_count == 0:
        _issue(
            issues,
            source,
            len(event_names),
            "unfinished_session",
            "a session without a final event is not a completed sample",
        )
    elif ended_count != 1 or event_names[-1] != EVENT_SESSION_ENDED:
        _issue(
            issues,
            source,
            len(event_names),
            "session_end_topology",
            "a session must contain exactly one final end event",
        )


def _validate_properties(
    source: str,
    line_number: int,
    properties: dict[str, Any],
    event_name: object,
    issues: list[IntegrityIssue],
) -> None:
    validators: dict[str, bool] = {
        "evidenceSchemaVersion": (
            _is_int(properties.get("evidenceSchemaVersion"), minimum=1)
            and properties.get("evidenceSchemaVersion")
            == EVIDENCE_SCHEMA_VERSION
        ),
        "runKind": _is_registered_string(
            properties.get("runKind"),
            ALLOWED_RUN_KINDS,
        ),
        "scenarioId": _is_registered_string(
            properties.get("scenarioId"),
            ALLOWED_SCENARIO_IDS,
        ),
        "inputDeviceFamily": _is_registered_string(
            properties.get("inputDeviceFamily"),
            ALLOWED_INPUT_DEVICE_FAMILIES,
        ),
        "startingStateKind": _is_registered_string(
            properties.get("startingStateKind"),
            ALLOWED_STARTING_STATE_KINDS,
        ),
        "buildRevision": _is_registered_string(
            properties.get("buildRevision"),
            REGISTERED_BUILD_REVISIONS,
        ),
        "contentRevision": _is_registered_string(
            properties.get("contentRevision"),
            REGISTERED_CONTENT_REVISIONS,
        ),
        "elapsedMs": _is_int(properties.get("elapsedMs"), minimum=0),
        "mapId": _is_registered_string(
            properties.get("mapId"),
            ALLOWED_MAP_IDS,
        ),
        "worldDay": _is_int(properties.get("worldDay"), minimum=1),
        "objectiveId": _is_registered_string(
            properties.get("objectiveId"),
            ALLOWED_OBJECTIVES,
        ),
    }
    for key in COUNT_KEYS & properties.keys():
        validators[key] = _is_int(properties.get(key), minimum=0)
    if event_name == EVENT_ACTION_COMMITTED:
        validators["actionId"] = _is_registered_string(
            properties.get("actionId"),
            ALLOWED_ACTIONS,
        )
    if event_name == EVENT_SESSION_ENDED:
        validators["outcome"] = _is_registered_string(
            properties.get("outcome"),
            ALLOWED_OUTCOMES,
        )
    for valid in validators.values():
        if not valid:
            _issue(
                issues,
                source,
                line_number,
                "invalid_property",
                "one property is outside its registered type or value domain",
            )
    for value in properties.values():
        if isinstance(value, (dict, list)):
            _issue(
                issues,
                source,
                line_number,
                "nested_property",
                "registered properties cannot contain nested data",
            )


def _validate_exact_keys(
    source: str,
    line_number: int,
    document: dict[str, Any],
    expected_keys: set[str],
    key_kind: str,
    issues: list[IntegrityIssue],
) -> None:
    for _missing_key in expected_keys - document.keys():
        _issue(
            issues,
            source,
            line_number,
            f"missing_{key_kind}",
            "record is missing a registered required key",
        )
    for _unexpected_key in document.keys() - expected_keys:
        _issue(
            issues,
            source,
            line_number,
            f"unexpected_{key_kind}",
            "record contains an unregistered key",
        )


def _validate_state_transitions(
    source: str,
    records: Sequence[dict[str, Any]],
    issues: list[IntegrityIssue],
) -> None:
    previous = _snapshot(records[0]["properties"])
    for line_number, record in enumerate(records[1:], start=2):
        current = _snapshot(record["properties"])
        if record["eventName"] == EVENT_ACTION_COMMITTED:
            action_id = record["properties"]["actionId"]
            if not _action_transition_is_plausible(
                action_id,
                previous,
                current,
            ):
                _issue(
                    issues,
                    source,
                    line_number,
                    "impossible_state_transition",
                    "action snapshot does not match its registered state change",
                )
        elif current != previous:
            _issue(
                issues,
                source,
                line_number,
                "unattributed_state_transition",
                "non-action event cannot change the tracked state snapshot",
            )
        previous = current


def _action_transition_is_plausible(
    action_id: str,
    before: dict[str, int],
    after: dict[str, int],
) -> bool:
    if action_id == ACTION_RESOURCE_SEED:
        return _only_changes(
            before,
            after,
            increases={"seedCount"},
        )
    if action_id == ACTION_RESOURCE_FORAGE:
        return _only_changes(
            before,
            after,
            increases={"forageCount"},
        )
    if action_id == ACTION_TILL:
        return _only_changes(
            before,
            after,
            increases={"farmTileCount"},
        )
    if action_id == ACTION_PLANT:
        return _only_changes(
            before,
            after,
            increases={"cropCount"},
            decreases={"seedCount"},
        )
    if action_id == ACTION_WATER:
        return before == after
    if action_id == ACTION_REST:
        return (
            after["worldDay"] == before["worldDay"] + 1
            and _keys_unchanged(
                before,
                after,
                set(SNAPSHOT_KEYS) - {"worldDay"},
            )
        )
    if action_id == ACTION_HARVEST:
        return _only_changes(
            before,
            after,
            increases={"forageCount"},
            decreases={"cropCount"},
        )
    if action_id == ACTION_SELL:
        return _only_changes(
            before,
            after,
            increases={"scripCount"},
            decreases={"forageCount"},
        )
    if action_id == ACTION_BUY_SEED:
        return _only_changes(
            before,
            after,
            increases={"seedCount"},
            decreases={"scripCount"},
        )
    return False


def _only_changes(
    before: dict[str, int],
    after: dict[str, int],
    *,
    increases: set[str] | None = None,
    decreases: set[str] | None = None,
) -> bool:
    increasing = increases or set()
    decreasing = decreases or set()
    if any(after[key] <= before[key] for key in increasing):
        return False
    if any(after[key] >= before[key] for key in decreasing):
        return False
    unchanged = set(SNAPSHOT_KEYS) - increasing - decreasing
    return _keys_unchanged(before, after, unchanged)


def _keys_unchanged(
    before: dict[str, int],
    after: dict[str, int],
    keys: set[str],
) -> bool:
    return all(before[key] == after[key] for key in keys)


def _snapshot(properties: dict[str, Any]) -> dict[str, int]:
    return {key: properties[key] for key in SNAPSHOT_KEYS}


def _validate_declared_human_timing(
    source: str,
    records: Sequence[dict[str, Any]],
    issues: list[IntegrityIssue],
) -> None:
    started = records[0]
    ended = records[-1]
    started_properties = started["properties"]
    if started_properties["runKind"] != RUN_KIND_HUMAN:
        return
    elapsed_delta = (
        ended["properties"]["elapsedMs"] - started_properties["elapsedMs"]
    )
    wall_clock_delta = (
        ended["recordedAtUnixMs"] - started["recordedAtUnixMs"]
    )
    if elapsed_delta <= 0 or wall_clock_delta <= 0:
        _issue(
            issues,
            source,
            len(records),
            "implausible_human_duration",
            "self-declared human session must have positive duration",
        )
        return
    tolerance_ms = max(5_000, elapsed_delta // 10)
    if abs(wall_clock_delta - elapsed_delta) > tolerance_ms:
        _issue(
            issues,
            source,
            len(records),
            "human_clock_mismatch",
            "self-declared human clocks are not plausibly aligned",
        )


def _expected_outcome(
    starting_state_kind: str,
    action_ids: Iterable[str],
) -> str:
    if starting_state_kind == STARTING_STATE_RESUMED:
        return "excluded_resumed"
    resource_choice_observed = False
    ordered_index = 0
    for action_id in action_ids:
        if action_id in RESOURCE_ACTIONS:
            if ordered_index == 0:
                resource_choice_observed = True
            continue
        if (
            resource_choice_observed
            and ordered_index < len(ORDERED_LOOP_ACTIONS)
            and action_id == ORDERED_LOOP_ACTIONS[ordered_index]
        ):
            ordered_index += 1
    return (
        "complete_loop"
        if resource_choice_observed
        and ordered_index == len(ORDERED_LOOP_ACTIONS)
        else "incomplete"
    )


def _revision_groups(
    self_declared_human_fresh: Sequence[ValidSession],
    *,
    report_usable: bool,
) -> list[dict[str, object]]:
    grouped: dict[tuple[str, str], list[ValidSession]] = defaultdict(list)
    for session in self_declared_human_fresh:
        grouped[(session.build_revision, session.content_revision)].append(
            session
        )

    reports: list[dict[str, object]] = []
    for (build_revision, content_revision), sessions in sorted(
        grouped.items()
    ):
        complete = [
            session
            for session in sessions
            if session.is_structurally_complete_self_declared_human
        ]
        resource_choices = Counter(
            resource_action
            for session in complete
            if (resource_action := session.first_resource_action()) is not None
        )
        reports.append(
            {
                "buildRevision": build_revision,
                "contentRevision": content_revision,
                "selfDeclaredHumanSessionCount": len(sessions),
                (
                    "structurallyCompleteSelfDeclaredHumanSessionCount"
                ): len(complete),
                "incompleteSelfDeclaredHumanSessionCount": (
                    len(sessions) - len(complete)
                ),
                "medianStructurallyCompleteLoopDurationMs": (
                    _integer_median(
                        session.duration_ms for session in complete
                    )
                    if complete
                    else None
                ),
                "resourceChoiceCounts": dict(sorted(resource_choices.items())),
                "medianFirstActionMs": _median_first_action_times(complete),
                "candidateSetReadyForHumanAttestation": (
                    report_usable
                    and len(complete)
                    >= MINIMUM_DIRECTIONAL_HUMAN_SAMPLES
                ),
            }
        )
    reports.sort(
        key=lambda group: (
            -int(
                group[
                    "structurallyCompleteSelfDeclaredHumanSessionCount"
                ]
            ),
            str(group["buildRevision"]),
            str(group["contentRevision"]),
        )
    )
    return reports


def _median_first_action_times(
    sessions: Sequence[ValidSession],
) -> dict[str, int]:
    elapsed_by_action: dict[str, list[int]] = defaultdict(list)
    for session in sessions:
        first_times: dict[str, int] = {}
        for action in session.actions:
            first_times.setdefault(action.action_id, action.elapsed_ms)
        for action_id, elapsed_ms in first_times.items():
            elapsed_by_action[action_id].append(elapsed_ms)
    return {
        action_id: _integer_median(elapsed_values)
        for action_id, elapsed_values in sorted(elapsed_by_action.items())
    }


def _fingerprint_without_session_id(
    records: Sequence[dict[str, Any]],
) -> str:
    first_recorded_at = records[0]["recordedAtUnixMs"]
    first_elapsed_ms = records[0]["properties"]["elapsedMs"]
    canonical_records = []
    for record in records:
        canonical_record = {
            key: value
            for key, value in record.items()
            if key not in {"sessionId", "properties"}
        }
        canonical_record["recordedAtUnixMs"] = (
            record["recordedAtUnixMs"] - first_recorded_at
        )
        canonical_record["properties"] = {
            **record["properties"],
            "elapsedMs": (
                record["properties"]["elapsedMs"] - first_elapsed_ms
            ),
        }
        canonical_records.append(canonical_record)
    payload = json.dumps(
        canonical_records,
        ensure_ascii=True,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def _integer_median(values: Iterable[int]) -> int:
    ordered = sorted(values)
    if not ordered:
        raise ValueError("median requires at least one registered integer")
    middle = len(ordered) // 2
    if len(ordered) % 2 == 1:
        return ordered[middle]
    return (ordered[middle - 1] + ordered[middle]) // 2


def _is_int(
    value: object,
    *,
    minimum: int,
    maximum: int = MAXIMUM_SIGNED_64_BIT_INTEGER,
) -> bool:
    return (
        isinstance(value, int)
        and not isinstance(value, bool)
        and minimum <= value <= maximum
    )


def _is_registered_string(
    value: object,
    allowed_values: Collection[str],
) -> bool:
    return isinstance(value, str) and value in allowed_values


def _is_safe_session_id(value: object) -> bool:
    return (
        isinstance(value, str)
        and 1 <= len(value) <= 96
        and all(character in SAFE_SESSION_ID_CHARACTERS for character in value)
    )


def _issue(
    issues: list[IntegrityIssue],
    source: str,
    line_number: int,
    code: str,
    message: str,
) -> None:
    issues.append(
        IntegrityIssue(
            source=source,
            line=line_number,
            code=code,
            message=message,
        )
    )


def _reject_duplicate_json_keys(
    pairs: list[tuple[str, object]],
) -> dict[str, object]:
    document: dict[str, object] = {}
    for key, value in pairs:
        if key in document:
            raise DuplicateJsonKeyError
        document[key] = value
    return document


def _canonical_d_drive_path(path: Path, *, kind: str) -> Path:
    if not path.is_absolute():
        raise ValueError(f"{kind} must be an absolute D-drive path")
    try:
        resolved = path.resolve(strict=False)
    except (OSError, RuntimeError) as error:
        raise ValueError(f"{kind} could not be resolved safely") from error
    if resolved.drive.casefold() != "d:":
        raise ValueError(f"{kind} must resolve to the D drive")
    return resolved


def _is_regular_d_drive_source(path: Path, directory: Path) -> bool:
    try:
        resolved = path.resolve(strict=True)
        return (
            not path.is_symlink()
            and resolved.is_file()
            and resolved.drive.casefold() == "d:"
            and resolved.parent == directory
        )
    except (OSError, RuntimeError):
        return False


def _build_argument_parser() -> argparse.ArgumentParser:
    repository_root = Path(__file__).resolve().parents[2]
    parser = argparse.ArgumentParser(
        description=(
            "Validate and summarize privacy-bounded P2 pacing JSONL. "
            "The result never substitutes for explicit human attestation."
        )
    )
    parser.add_argument(
        "--input",
        type=Path,
        default=repository_root
        / "builds"
        / "playtest-evidence"
        / "p2-pacing",
    )
    parser.add_argument("--output", type=Path)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = _build_argument_parser()
    arguments = parser.parse_args(argv)
    try:
        input_directory = _canonical_d_drive_path(
            arguments.input,
            kind="--input",
        )
        output_path = (
            _canonical_d_drive_path(arguments.output, kind="--output")
            if arguments.output is not None
            else None
        )
    except ValueError as error:
        parser.error(str(error))
    if output_path is not None and output_path.suffix.lower() != ".json":
        parser.error("--output must be a .json report")
    try:
        report = analyze_directory(input_directory)
    except (FileNotFoundError, OSError, ValueError) as error:
        parser.error(str(error))
    serialized = json.dumps(
        report,
        ensure_ascii=False,
        indent=2,
        sort_keys=True,
    )
    if output_path is not None:
        try:
            output_path.parent.mkdir(parents=True, exist_ok=True)
            output_path.write_text(serialized + "\n", encoding="utf-8")
        except OSError:
            parser.error("report output could not be written")
    print(serialized)
    return 0 if report["reportUsable"] else 2


if __name__ == "__main__":
    raise SystemExit(main())
