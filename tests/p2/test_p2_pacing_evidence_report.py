from __future__ import annotations

import contextlib
import io
import json
import re
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT))

from tools.playtest import analyze_p2_pacing as analyzer


class P2PacingEvidenceReportTests(unittest.TestCase):
    def setUp(self) -> None:
        builds_root = REPO_ROOT / "builds"
        builds_root.mkdir(parents=True, exist_ok=True)
        self._temporary = tempfile.TemporaryDirectory(
            prefix="p2-pacing-report-",
            dir=builds_root,
        )
        self.evidence_directory = Path(self._temporary.name)

    def tearDown(self) -> None:
        self._temporary.cleanup()

    def test_empty_directory_is_honest_insufficient_evidence(self) -> None:
        report = analyzer.analyze_directory(self.evidence_directory)

        self.assertTrue(report["reportUsable"])
        self.assertEqual(report["integrityIssueCount"], 0)
        self.assertEqual(report["structurallyValidUniqueSessionCount"], 0)
        self.assertFalse(report["humanEvidenceCollected"])
        self.assertFalse(report["candidateSetReadyForHumanAttestation"])
        self.assertFalse(report["directionalReviewReady"])
        self.assertEqual(
            report["decisionGate"]["status"],
            "insufficient_human_samples",
        )
        self.assertFalse(report["designDecisionReviewed"])
        self.assertFalse(report["p2CompletionClaimAllowed"])

    def test_five_plausible_self_declared_loops_only_open_attestation_gate(
        self,
    ) -> None:
        for index in range(5):
            resource_action = (
                analyzer.ACTION_RESOURCE_SEED
                if index < 3
                else analyzer.ACTION_RESOURCE_FORAGE
            )
            self._write_session(
                f"human-{index}",
                run_kind=analyzer.RUN_KIND_HUMAN,
                resource_action=resource_action,
                duration_ms=(index + 1) * 60_000,
                recorded_at_base=1_800_000_000_000 + index * 1_000_000,
            )

        report = analyzer.analyze_directory(self.evidence_directory)

        self.assertTrue(report["reportUsable"])
        self.assertEqual(report["integrityIssueCount"], 0)
        self.assertEqual(report["structurallyValidUniqueSessionCount"], 5)
        self.assertEqual(
            report[
                "structurallyCompleteSelfDeclaredHumanSessionCount"
            ],
            5,
        )
        self.assertTrue(report["candidateSetReadyForHumanAttestation"])
        self.assertFalse(report["humanEvidenceCollected"])
        self.assertFalse(report["directionalReviewReady"])
        self.assertEqual(
            report["decisionGate"]["status"],
            "human_attestation_required",
        )
        group = report["compatibleRevisionGroups"][0]
        self.assertEqual(
            group[
                "structurallyCompleteSelfDeclaredHumanSessionCount"
            ],
            5,
        )
        self.assertTrue(group["candidateSetReadyForHumanAttestation"])
        self.assertEqual(
            group["medianStructurallyCompleteLoopDurationMs"],
            180_000,
        )
        self.assertEqual(
            group["resourceChoiceCounts"],
            {
                analyzer.ACTION_RESOURCE_SEED: 3,
                analyzer.ACTION_RESOURCE_FORAGE: 2,
            },
        )
        self.assertFalse(report["designDecisionReviewed"])
        self.assertFalse(report["p2CompletionClaimAllowed"])

    def test_automation_and_resumed_sessions_are_separated(self) -> None:
        self._write_session(
            "automation",
            run_kind=analyzer.RUN_KIND_AUTOMATION,
            recorded_at_base=1_800_010_000_000,
        )
        self._write_session(
            "resumed",
            run_kind=analyzer.RUN_KIND_HUMAN,
            starting_state_kind=analyzer.STARTING_STATE_RESUMED,
            outcome="excluded_resumed",
            recorded_at_base=1_800_020_000_000,
        )

        report = analyzer.analyze_directory(self.evidence_directory)

        self.assertTrue(report["reportUsable"])
        self.assertEqual(report["automationSessionCount"], 1)
        self.assertEqual(
            report["excludedResumedSelfDeclaredHumanSessionCount"],
            1,
        )
        self.assertEqual(
            report["selfDeclaredHumanFreshSessionCount"],
            0,
        )
        self.assertFalse(report["candidateSetReadyForHumanAttestation"])
        self.assertFalse(report["humanEvidenceCollected"])

    def test_unknown_revision_and_fractional_timestamp_fail_closed(
        self,
    ) -> None:
        unknown = self._records(
            "unknown-v999",
            run_kind=analyzer.RUN_KIND_HUMAN,
            build_revision="p2.pacing.instrumentation.v999",
            content_revision="p2.h01.balance.v999",
        )
        self._write_records("unknown-v999", unknown)
        fractional = self._records(
            "fractional-time",
            run_kind=analyzer.RUN_KIND_HUMAN,
            recorded_at_base=1_800_030_000_000,
        )
        fractional[3]["recordedAtUnixMs"] = 1_800_030_000_000.5
        self._write_records("fractional-time", fractional)

        report = analyzer.analyze_directory(self.evidence_directory)

        self.assertFalse(report["reportUsable"])
        self.assertEqual(
            report["decisionGate"]["status"],
            "integrity_issues",
        )
        self.assertFalse(report["candidateSetReadyForHumanAttestation"])
        issue_codes = {issue["code"] for issue in report["integrityIssues"]}
        self.assertIn("invalid_property", issue_codes)
        self.assertIn("invalid_recorded_time", issue_codes)

    def test_integers_above_godot_int64_fail_closed(self) -> None:
        maximum = analyzer.MAXIMUM_SIGNED_64_BIT_INTEGER
        self.assertTrue(analyzer._is_int(maximum, minimum=0))
        self.assertFalse(analyzer._is_int(maximum + 1, minimum=0))
        even_median = analyzer._integer_median([1, 2])
        self.assertEqual(even_median, 1)
        self.assertIsInstance(even_median, int)

        oversized = 10**1000
        for index in range(2):
            session_id = f"oversized-{index}"
            records = self._records(
                session_id,
                run_kind=analyzer.RUN_KIND_HUMAN,
                recorded_at_base=1_800_032_000_000 + index * 1_000_000,
            )
            for record in records:
                record["recordedAtUnixMs"] = (
                    oversized + record["sequence"] + index
                )
                record["properties"]["elapsedMs"] += oversized
                record["properties"]["worldDay"] = oversized
                record["properties"]["seedCount"] = oversized
            self._write_records(session_id, records)

        report = analyzer.analyze_directory(self.evidence_directory)
        serialized = json.dumps(report, ensure_ascii=False, sort_keys=True)
        issue_codes = {issue["code"] for issue in report["integrityIssues"]}

        self.assertFalse(report["reportUsable"])
        self.assertFalse(report["candidateSetReadyForHumanAttestation"])
        self.assertFalse(report["directionalReviewReady"])
        self.assertIn("invalid_recorded_time", issue_codes)
        self.assertIn("invalid_property", issue_codes)
        self.assertNotIn(str(oversized)[:80], serialized)
        self.assertNotIn("traceback", serialized.lower())
        self.assertNotIn("D:\\", serialized)

    def test_privacy_and_invalid_json_reports_never_echo_input(
        self,
    ) -> None:
        private_session = "AliceProfile"
        private_records = self._records(
            private_session,
            run_kind=analyzer.RUN_KIND_HUMAN,
        )
        private_key = "D:/private/Alice/free text note"
        private_records[-1]["properties"][private_key] = "secret value"
        self._write_records(private_session, private_records)

        invalid_path = (
            self.evidence_directory / "p2-pacing-BobSecret.jsonl"
        )
        invalid_path.write_text(
            '{"number":' + ("9" * 5000) + "}\n",
            encoding="utf-8",
        )

        report = analyzer.analyze_directory(self.evidence_directory)
        serialized = json.dumps(report, ensure_ascii=False, sort_keys=True)

        self.assertFalse(report["reportUsable"])
        self.assertIn(
            "unexpected_property",
            {issue["code"] for issue in report["integrityIssues"]},
        )
        self.assertIn(
            "invalid_json",
            {issue["code"] for issue in report["integrityIssues"]},
        )
        for forbidden in (
            "Alice",
            "Bob",
            "private",
            "free text",
            "secret value",
            "D:/",
            "p2-pacing-",
        ):
            self.assertNotIn(forbidden, serialized)
        for issue in report["integrityIssues"]:
            self.assertRegex(issue["source"], r"^source-[0-9]{4}$")
            self.assertNotIn("file", issue)

    def test_nested_registered_values_fail_closed_without_traceback(
        self,
    ) -> None:
        for index, field_name in enumerate(
            ("runKind", "objectiveId", "actionId", "outcome")
        ):
            session_id = f"nested-{field_name.lower()}"
            records = self._records(
                session_id,
                run_kind=analyzer.RUN_KIND_HUMAN,
                recorded_at_base=(
                    1_800_035_000_000 + index * 1_000_000
                ),
            )
            private_value = {
                "D:/private/Alice": ["secret nested value"],
            }
            if field_name == "runKind":
                records[0]["properties"]["runKind"] = private_value
            elif field_name == "objectiveId":
                records[1]["properties"]["objectiveId"] = [
                    private_value
                ]
            elif field_name == "actionId":
                records[2]["properties"]["actionId"] = private_value
            else:
                records[-1]["properties"]["outcome"] = private_value
            self._write_records(session_id, records)

        report = analyzer.analyze_directory(self.evidence_directory)
        serialized = json.dumps(report, ensure_ascii=False, sort_keys=True)
        issue_codes = {issue["code"] for issue in report["integrityIssues"]}

        self.assertFalse(report["reportUsable"])
        self.assertFalse(report["candidateSetReadyForHumanAttestation"])
        self.assertFalse(report["directionalReviewReady"])
        self.assertIn("invalid_property", issue_codes)
        self.assertIn("nested_property", issue_codes)
        for forbidden in (
            "Alice",
            "private",
            "secret nested value",
            "D:/",
            "traceback",
        ):
            self.assertNotIn(forbidden.lower(), serialized.lower())

    def test_impossible_state_chain_and_cloned_payloads_are_rejected(
        self,
    ) -> None:
        impossible = self._records(
            "impossible",
            run_kind=analyzer.RUN_KIND_HUMAN,
            recorded_at_base=1_800_040_000_000,
        )
        for record in impossible:
            properties = record["properties"]
            properties["worldDay"] = 1
            properties["farmTileCount"] = 0
            properties["cropCount"] = 0
            properties["seedCount"] = 0
            properties["forageCount"] = 0
            properties["scripCount"] = 0
        self._write_records("impossible", impossible)

        clone_a = self._records(
            "clone-a",
            run_kind=analyzer.RUN_KIND_HUMAN,
            recorded_at_base=1_800_050_000_000,
        )
        clone_b = json.loads(json.dumps(clone_a))
        for record in clone_b:
            record["sessionId"] = "clone-b"
            record["recordedAtUnixMs"] += 50_000_000
            record["properties"]["elapsedMs"] += 1_000_000
        self._write_records("clone-a", clone_a)
        self._write_records("clone-b", clone_b)

        report = analyzer.analyze_directory(self.evidence_directory)
        issue_codes = {issue["code"] for issue in report["integrityIssues"]}

        self.assertFalse(report["reportUsable"])
        self.assertIn("impossible_state_transition", issue_codes)
        self.assertIn("duplicate_session_payload", issue_codes)
        self.assertEqual(report["structurallyValidUniqueSessionCount"], 1)
        self.assertFalse(report["candidateSetReadyForHumanAttestation"])

    def test_human_duration_and_any_integrity_issue_block_the_gate(
        self,
    ) -> None:
        for index in range(5):
            self._write_session(
                f"valid-{index}",
                run_kind=analyzer.RUN_KIND_HUMAN,
                duration_ms=120_000 + index * 10_000,
                recorded_at_base=(
                    1_800_060_000_000 + index * 1_000_000
                ),
            )
        zero_duration = self._records(
            "zero-duration",
            run_kind=analyzer.RUN_KIND_HUMAN,
            duration_ms=0,
            recorded_at_base=1_800_070_000_000,
        )
        self._write_records("zero-duration", zero_duration)

        report = analyzer.analyze_directory(self.evidence_directory)

        self.assertFalse(report["reportUsable"])
        self.assertIn(
            "implausible_human_duration",
            {issue["code"] for issue in report["integrityIssues"]},
        )
        self.assertFalse(report["candidateSetReadyForHumanAttestation"])
        self.assertFalse(
            report["compatibleRevisionGroups"][0][
                "candidateSetReadyForHumanAttestation"
            ]
        )
        self.assertFalse(report["directionalReviewReady"])

    def test_elapsed_offsets_cannot_corrupt_duration_or_action_metrics(
        self,
    ) -> None:
        records = self._records(
            "offset-elapsed",
            run_kind=analyzer.RUN_KIND_HUMAN,
            duration_ms=420_000,
            recorded_at_base=1_800_080_000_000,
        )
        for record in records:
            record["properties"]["elapsedMs"] += 1_000_000
        self._write_records("offset-elapsed", records)

        report = analyzer.analyze_directory(self.evidence_directory)
        group = report["compatibleRevisionGroups"][0]

        self.assertTrue(report["reportUsable"])
        self.assertEqual(
            group["medianStructurallyCompleteLoopDurationMs"],
            420_000,
        )
        self.assertEqual(
            group["medianFirstActionMs"][
                analyzer.ACTION_RESOURCE_SEED
            ],
            93_333,
        )

    def test_minimum_sample_policy_cannot_be_lowered(self) -> None:
        with self.assertRaises(TypeError):
            analyzer.analyze_directory(
                self.evidence_directory,
                minimum_human_samples=1,
            )

        stderr = io.StringIO()
        with contextlib.redirect_stderr(stderr):
            with self.assertRaises(SystemExit) as raised:
                analyzer.main(
                    [
                        "--input",
                        str(self.evidence_directory),
                        "--minimum-human-samples",
                        "1",
                    ]
                )
        self.assertEqual(raised.exception.code, 2)

    def test_streaming_and_source_boundaries_are_exact(self) -> None:
        exact_line_path = self.evidence_directory / "exact-line.txt"
        over_line_path = self.evidence_directory / "over-line.txt"
        json_prefix = '{"padding":"'
        json_suffix = '"}'
        exact_padding = (
            analyzer.MAXIMUM_JSON_LINE_CHARACTERS
            - len(json_prefix)
            - len(json_suffix)
        )
        exact_line = json_prefix + ("x" * exact_padding) + json_suffix
        over_line = exact_line[:-len(json_suffix)] + "x" + json_suffix
        self.assertEqual(
            len(exact_line),
            analyzer.MAXIMUM_JSON_LINE_CHARACTERS,
        )
        self.assertEqual(
            len(over_line),
            analyzer.MAXIMUM_JSON_LINE_CHARACTERS + 1,
        )
        exact_line_path.write_text(exact_line + "\n", encoding="utf-8")
        over_line_path.write_text(over_line + "\n", encoding="utf-8")

        exact_records, exact_issues = analyzer._read_bounded_jsonl(
            exact_line_path,
            "source-0001",
        )
        over_records, over_issues = analyzer._read_bounded_jsonl(
            over_line_path,
            "source-0002",
        )
        self.assertEqual(len(exact_records), 1)
        self.assertFalse(exact_issues)
        self.assertFalse(over_records)
        self.assertEqual(
            {issue.code for issue in over_issues},
            {"line_limit_exceeded"},
        )

        exact_events_path = self.evidence_directory / "exact-events.txt"
        over_events_path = self.evidence_directory / "over-events.txt"
        exact_events_path.write_text(
            "{}\n" * analyzer.MAXIMUM_EVENTS_PER_SESSION,
            encoding="utf-8",
        )
        over_events_path.write_text(
            "{}\n" * (analyzer.MAXIMUM_EVENTS_PER_SESSION + 1),
            encoding="utf-8",
        )
        exact_event_records, exact_event_issues = (
            analyzer._read_bounded_jsonl(
                exact_events_path,
                "source-0003",
            )
        )
        over_event_records, over_event_issues = (
            analyzer._read_bounded_jsonl(
                over_events_path,
                "source-0004",
            )
        )
        self.assertEqual(
            len(exact_event_records),
            analyzer.MAXIMUM_EVENTS_PER_SESSION,
        )
        self.assertFalse(exact_event_issues)
        self.assertEqual(
            len(over_event_records),
            analyzer.MAXIMUM_EVENTS_PER_SESSION,
        )
        self.assertEqual(
            {issue.code for issue in over_event_issues},
            {"event_limit_exceeded"},
        )

        invalid_utf8_path = self.evidence_directory / "invalid-utf8.txt"
        invalid_utf8_path.write_bytes(b"\xff\n")
        invalid_records, invalid_issues = analyzer._read_bounded_jsonl(
            invalid_utf8_path,
            "source-0005",
        )
        self.assertFalse(invalid_records)
        self.assertEqual(
            {issue.code for issue in invalid_issues},
            {"unreadable_file"},
        )

        regular_source = self.evidence_directory / "regular-source.txt"
        regular_source.write_text("{}\n", encoding="utf-8")
        self.assertTrue(
            analyzer._is_regular_d_drive_source(
                regular_source,
                self.evidence_directory.resolve(),
            )
        )
        builds_root = REPO_ROOT / "builds"
        with tempfile.TemporaryDirectory(
            prefix="p2-pacing-outside-",
            dir=builds_root,
        ) as outside_name:
            outside_source = Path(outside_name) / "outside-source.txt"
            outside_source.write_text("{}\n", encoding="utf-8")
            self.assertFalse(
                analyzer._is_regular_d_drive_source(
                    outside_source,
                    self.evidence_directory.resolve(),
                )
            )
        with mock.patch.object(Path, "is_symlink", return_value=True):
            self.assertFalse(
                analyzer._is_regular_d_drive_source(
                    regular_source,
                    self.evidence_directory.resolve(),
                )
            )

    def test_registered_contract_matches_both_gdscript_producers(self) -> None:
        session_source = (
            REPO_ROOT
            / "scripts"
            / "app"
            / "playtest"
            / "p2_pacing_evidence_session.gd"
        ).read_text(encoding="utf-8")
        adapter_source = (
            REPO_ROOT
            / "scripts"
            / "platform"
            / "adapters"
            / "local_jsonl_analytics_service.gd"
        ).read_text(encoding="utf-8")

        adapter_registries = {
            "_ALLOWED_EVENT_NAMES": analyzer.ALLOWED_EVENTS,
            "_COMMON_PROPERTY_KEYS": analyzer.COMMON_PROPERTY_KEYS,
            "_ALLOWED_RUN_KINDS": analyzer.ALLOWED_RUN_KINDS,
            "_ALLOWED_SCENARIO_IDS": analyzer.ALLOWED_SCENARIO_IDS,
            "_ALLOWED_INPUT_DEVICE_FAMILIES": (
                analyzer.ALLOWED_INPUT_DEVICE_FAMILIES
            ),
            "_ALLOWED_STARTING_STATE_KINDS": (
                analyzer.ALLOWED_STARTING_STATE_KINDS
            ),
            "_ALLOWED_BUILD_REVISIONS": (
                analyzer.REGISTERED_BUILD_REVISIONS
            ),
            "_ALLOWED_CONTENT_REVISIONS": (
                analyzer.REGISTERED_CONTENT_REVISIONS
            ),
            "_ALLOWED_MAP_IDS": analyzer.ALLOWED_MAP_IDS,
            "_ALLOWED_OBJECTIVE_IDS": analyzer.ALLOWED_OBJECTIVES,
            "_ALLOWED_ACTION_IDS": analyzer.ALLOWED_ACTIONS,
            "_ALLOWED_OUTCOMES": analyzer.ALLOWED_OUTCOMES,
        }
        for constant_name, expected_values in adapter_registries.items():
            self.assertEqual(
                expected_values,
                self._gdscript_array_values(
                    adapter_source,
                    constant_name,
                ),
                constant_name,
            )
        self.assertEqual(
            analyzer.MAXIMUM_EVENTS_PER_SESSION,
            self._gdscript_int_constant(
                adapter_source,
                "MAX_EVENTS_PER_SESSION",
            ),
        )
        self.assertEqual(
            analyzer.MAXIMUM_PROPERTIES_PER_EVENT,
            self._gdscript_int_constant(
                adapter_source,
                "MAX_PROPERTIES_PER_EVENT",
            ),
        )
        self.assertEqual(
            analyzer.MAXIMUM_JSON_LINE_CHARACTERS,
            self._gdscript_int_constant(
                adapter_source,
                "MAX_JSON_LINE_CHARACTERS",
            ),
        )

        session_constants = self._gdscript_string_constants(session_source)
        self.assertEqual(
            analyzer.EVIDENCE_SCHEMA_VERSION,
            self._gdscript_int_constant(
                session_source,
                "EVIDENCE_SCHEMA_VERSION",
            ),
        )
        self.assertEqual(
            analyzer.ALLOWED_EVENTS,
            {
                value
                for name, value in session_constants.items()
                if name.startswith("EVENT_")
            },
        )
        self.assertEqual(
            analyzer.ALLOWED_ACTIONS,
            {
                value
                for name, value in session_constants.items()
                if name.startswith("ACTION_")
            },
        )
        self.assertEqual(
            analyzer.ALLOWED_RUN_KINDS,
            {
                value
                for name, value in session_constants.items()
                if name.startswith("RUN_KIND_")
            },
        )
        self.assertEqual(
            analyzer.ALLOWED_STARTING_STATE_KINDS,
            {
                value
                for name, value in session_constants.items()
                if name.startswith("STARTING_STATE_")
            },
        )
        self.assertEqual(
            analyzer.REGISTERED_BUILD_REVISIONS,
            {session_constants["BUILD_REVISION"]},
        )
        self.assertEqual(
            analyzer.REGISTERED_CONTENT_REVISIONS,
            {session_constants["CONTENT_REVISION"]},
        )
        allowlisted_names = self._gdscript_array_identifiers(
            session_source,
            "_ALLOWLISTED_ACTIONS",
        )
        ordered_names = self._gdscript_array_identifiers(
            session_source,
            "_ORDERED_LOOP_ACTIONS",
        )
        self.assertEqual(
            analyzer.ALLOWED_ACTIONS,
            {session_constants[name] for name in allowlisted_names},
        )
        self.assertEqual(
            analyzer.ORDERED_LOOP_ACTIONS,
            tuple(session_constants[name] for name in ordered_names),
        )

    def test_api_and_cli_keep_all_paths_on_d_drive(self) -> None:
        with self.assertRaisesRegex(
            ValueError,
            r"must be an absolute D-drive path",
        ):
            analyzer.analyze_directory(Path("relative-evidence"))
        with self.assertRaisesRegex(ValueError, r"must resolve to the D drive"):
            analyzer.analyze_directory(Path("C:/private/Alice"))
        missing = Path("D:/p2-evidence-directory-that-does-not-exist")
        with self.assertRaises(FileNotFoundError) as raised:
            analyzer.analyze_directory(missing)
        self.assertEqual(
            str(raised.exception),
            "evidence directory does not exist",
        )

        stderr = io.StringIO()
        with contextlib.redirect_stderr(stderr):
            with self.assertRaises(SystemExit) as output_error:
                analyzer.main(
                    [
                        "--input",
                        str(self.evidence_directory),
                        "--output",
                        str(self.evidence_directory / "report.jsonl"),
                    ]
                )
        self.assertEqual(output_error.exception.code, 2)

    def _write_session(
        self,
        session_id: str,
        *,
        run_kind: str,
        resource_action: str = analyzer.ACTION_RESOURCE_SEED,
        duration_ms: int = 420_000,
        starting_state_kind: str = analyzer.STARTING_STATE_FRESH,
        build_revision: str = "p2.pacing.instrumentation.v1",
        content_revision: str = "p2.h01.balance.v1",
        outcome: str = "complete_loop",
        recorded_at_base: int = 1_800_000_000_000,
    ) -> None:
        self._write_records(
            session_id,
            self._records(
                session_id,
                run_kind=run_kind,
                resource_action=resource_action,
                duration_ms=duration_ms,
                starting_state_kind=starting_state_kind,
                build_revision=build_revision,
                content_revision=content_revision,
                outcome=outcome,
                recorded_at_base=recorded_at_base,
            ),
        )

    def _records(
        self,
        session_id: str,
        *,
        run_kind: str,
        resource_action: str = analyzer.ACTION_RESOURCE_SEED,
        duration_ms: int = 420_000,
        starting_state_kind: str = analyzer.STARTING_STATE_FRESH,
        build_revision: str = "p2.pacing.instrumentation.v1",
        content_revision: str = "p2.h01.balance.v1",
        outcome: str = "complete_loop",
        recorded_at_base: int = 1_800_000_000_000,
    ) -> list[dict[str, object]]:
        actions = self._complete_actions(resource_action)
        state = {
            "worldDay": 1,
            "farmTileCount": 0,
            "cropCount": 0,
            "seedCount": 0,
            "forageCount": 0,
            "scripCount": 0,
        }
        event_specs: list[tuple[str, str | None, dict[str, int]]] = [
            (
                analyzer.EVENT_SESSION_STARTED,
                None,
                dict(state),
            ),
            (
                analyzer.EVENT_OBJECTIVE_CHANGED,
                None,
                dict(state),
            ),
        ]
        for action_id in actions:
            self._apply_action(state, action_id)
            event_specs.append(
                (
                    analyzer.EVENT_ACTION_COMMITTED,
                    action_id,
                    dict(state),
                )
            )
        event_specs.append(
            (
                analyzer.EVENT_SESSION_ENDED,
                None,
                dict(state),
            )
        )

        records: list[dict[str, object]] = []
        denominator = len(event_specs) - 1
        for index, (event_name, action_id, snapshot) in enumerate(
            event_specs
        ):
            elapsed_ms = round(duration_ms * index / denominator)
            properties = self._common_properties(
                run_kind=run_kind,
                elapsed_ms=elapsed_ms,
                starting_state_kind=starting_state_kind,
                build_revision=build_revision,
                content_revision=content_revision,
                snapshot=snapshot,
            )
            if action_id is not None:
                properties["actionId"] = action_id
            if event_name == analyzer.EVENT_SESSION_ENDED:
                properties["outcome"] = outcome
                properties["unknownActionCount"] = 0
            records.append(
                {
                    "evidenceSchemaVersion": 1,
                    "sessionId": session_id,
                    "sequence": index + 1,
                    "recordedAtUnixMs": recorded_at_base + elapsed_ms,
                    "eventName": event_name,
                    "properties": properties,
                }
            )
        return records

    @staticmethod
    def _complete_actions(resource_action: str) -> list[str]:
        if resource_action == analyzer.ACTION_RESOURCE_FORAGE:
            return [
                analyzer.ACTION_RESOURCE_FORAGE,
                analyzer.ACTION_SELL,
                analyzer.ACTION_BUY_SEED,
                analyzer.ACTION_TILL,
                analyzer.ACTION_PLANT,
                analyzer.ACTION_WATER,
                analyzer.ACTION_REST,
                analyzer.ACTION_HARVEST,
                analyzer.ACTION_SELL,
            ]
        return [
            analyzer.ACTION_RESOURCE_SEED,
            analyzer.ACTION_TILL,
            analyzer.ACTION_PLANT,
            analyzer.ACTION_WATER,
            analyzer.ACTION_REST,
            analyzer.ACTION_HARVEST,
            analyzer.ACTION_SELL,
        ]

    @staticmethod
    def _apply_action(state: dict[str, int], action_id: str) -> None:
        if action_id == analyzer.ACTION_RESOURCE_SEED:
            state["seedCount"] += 3
        elif action_id == analyzer.ACTION_RESOURCE_FORAGE:
            state["forageCount"] += 3
        elif action_id == analyzer.ACTION_TILL:
            state["farmTileCount"] += 1
        elif action_id == analyzer.ACTION_PLANT:
            state["seedCount"] -= 1
            state["cropCount"] += 1
        elif action_id == analyzer.ACTION_WATER:
            return
        elif action_id == analyzer.ACTION_REST:
            state["worldDay"] += 1
        elif action_id == analyzer.ACTION_HARVEST:
            state["cropCount"] -= 1
            state["forageCount"] += 1
        elif action_id == analyzer.ACTION_SELL:
            state["forageCount"] -= 1
            state["scripCount"] += 10
        elif action_id == analyzer.ACTION_BUY_SEED:
            state["scripCount"] -= 5
            state["seedCount"] += 1
        else:
            raise AssertionError(f"unhandled test action: {action_id}")

    @staticmethod
    def _common_properties(
        *,
        run_kind: str,
        elapsed_ms: int,
        starting_state_kind: str,
        build_revision: str,
        content_revision: str,
        snapshot: dict[str, int],
    ) -> dict[str, object]:
        return {
            "evidenceSchemaVersion": 1,
            "runKind": run_kind,
            "scenarioId": "p2.h01.life_loop",
            "inputDeviceFamily": "keyboard_mouse",
            "startingStateKind": starting_state_kind,
            "buildRevision": build_revision,
            "contentRevision": content_revision,
            "elapsedMs": elapsed_ms,
            "mapId": "home_h01_open_meadow",
            "objectiveId": "p2.h01.guide.claim_daily",
            **snapshot,
        }

    def _write_records(
        self,
        session_id: str,
        records: list[dict[str, object]],
    ) -> None:
        path = self.evidence_directory / f"p2-pacing-{session_id}.jsonl"
        path.write_text(
            "".join(
                json.dumps(record, ensure_ascii=False) + "\n"
                for record in records
            ),
            encoding="utf-8",
        )

    @staticmethod
    def _gdscript_array_values(source: str, constant_name: str) -> set[str]:
        match = re.search(
            rf"const {re.escape(constant_name)}:[^=]+=\s*\[(.*?)\]",
            source,
            flags=re.DOTALL,
        )
        if match is None:
            raise AssertionError(f"missing GDScript registry: {constant_name}")
        return set(re.findall(r'"([^"]+)"', match.group(1)))

    @staticmethod
    def _gdscript_array_identifiers(
        source: str,
        constant_name: str,
    ) -> tuple[str, ...]:
        match = re.search(
            rf"const {re.escape(constant_name)}:[^=]+=\s*\[(.*?)\]",
            source,
            flags=re.DOTALL,
        )
        if match is None:
            raise AssertionError(f"missing GDScript array: {constant_name}")
        return tuple(
            re.findall(r"\b[A-Z][A-Z0-9_]+\b", match.group(1))
        )

    @staticmethod
    def _gdscript_string_constants(source: str) -> dict[str, str]:
        return dict(
            re.findall(
                (
                    r"const\s+([A-Z][A-Z0-9_]*):[^=]+="
                    r'\s*(?:\(\s*)?&"([^"]+)"'
                ),
                source,
                flags=re.DOTALL,
            )
        )

    @staticmethod
    def _gdscript_int_constant(source: str, constant_name: str) -> int:
        match = re.search(
            (
                rf"const {re.escape(constant_name)}:\s*int\s*="
                r"\s*([0-9_]+)"
            ),
            source,
        )
        if match is None:
            raise AssertionError(
                f"missing GDScript integer constant: {constant_name}"
            )
        return int(match.group(1).replace("_", ""))


if __name__ == "__main__":
    unittest.main()
