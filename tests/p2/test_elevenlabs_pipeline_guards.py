from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT))

from tools.audio_production import elevenlabs_pipeline as pipeline


class ElevenLabsPipelineGuardTests(unittest.TestCase):
    def setUp(self) -> None:
        builds_root = Path(__file__).resolve().parents[2] / "builds"
        builds_root.mkdir(parents=True, exist_ok=True)
        self._temporary = tempfile.TemporaryDirectory(
            prefix="p2-audio-guard-",
            dir=builds_root,
        )
        self.ledger_path = Path(self._temporary.name) / "ledger.json"
        self._ledger_patch = patch.object(
            pipeline,
            "LEDGER_PATH",
            self.ledger_path,
        )
        self._ledger_patch.start()

    def tearDown(self) -> None:
        self._ledger_patch.stop()
        self._temporary.cleanup()

    def _write_calls(self, calls: list[dict[str, object]]) -> None:
        self.ledger_path.write_text(
            json.dumps(
                {
                    "schemaVersion": 1,
                    "batchId": "p2-life-loop-v1",
                    "automaticRetries": 0,
                    "calls": calls,
                }
            ),
            encoding="utf-8",
        )

    @staticmethod
    def _call(
        audio_id: str,
        states: list[str],
        capability: str = "sound-effect",
    ) -> dict[str, object]:
        return {
            "localRequestId": f"request-{audio_id}",
            "capability": capability,
            "audioId": audio_id,
            "states": [{"state": state} for state in states],
        }

    def test_completed_audio_id_cannot_be_regenerated(self) -> None:
        self._write_calls(
            [self._call("sfx.farm.till.a", ["RESERVED", "ATTEMPTED", "COMPLETED"])]
        )
        with self.assertRaisesRegex(RuntimeError, "Refusing regeneration"):
            pipeline._assert_operation_available(
                capability="sound-effect",
                audio_id="sfx.farm.till.a",
                maximum_calls=21,
            )

    def test_unknown_provider_state_cannot_be_retried(self) -> None:
        self._write_calls(
            [
                self._call(
                    "sfx.farm.till.a",
                    ["RESERVED", "ATTEMPTED", "FAILED_UNKNOWN_PROVIDER_STATE"],
                )
            ]
        )
        with self.assertRaisesRegex(RuntimeError, "Refusing regeneration"):
            pipeline._assert_operation_available(
                capability="sound-effect",
                audio_id="sfx.farm.till.a",
                maximum_calls=21,
            )

    def test_operation_limit_blocks_an_additional_audio_id(self) -> None:
        self._write_calls(
            [
                self._call("sfx.first", ["RESERVED", "ATTEMPTED", "COMPLETED"]),
                self._call("sfx.second", ["RESERVED", "ATTEMPTED", "COMPLETED"]),
            ]
        )
        with self.assertRaisesRegex(RuntimeError, "call limit is exhausted"):
            pipeline._assert_operation_available(
                capability="sound-effect",
                audio_id="sfx.third",
                maximum_calls=2,
            )

    def test_unused_operation_budget_allows_a_new_audio_id(self) -> None:
        self._write_calls(
            [self._call("sfx.first", ["RESERVED", "ATTEMPTED", "COMPLETED"])]
        )
        pipeline._assert_operation_available(
            capability="sound-effect",
            audio_id="sfx.second",
            maximum_calls=2,
        )


if __name__ == "__main__":
    unittest.main()
