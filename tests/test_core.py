import importlib.util
import json
import os
import tempfile
import unittest
from importlib.machinery import SourceFileLoader
from pathlib import Path
from unittest import mock


SCRIPT = Path(__file__).parents[1] / "bin" / "villode-dock"


def load_module():
    loader = SourceFileLoader("villode_dock_test", str(SCRIPT))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class DockCoreTests(unittest.TestCase):
    def setUp(self):
        self.module = load_module()
        self.temporary = tempfile.TemporaryDirectory()
        root = Path(self.temporary.name)
        self.module.CONFIG_DIR = root / "config"
        self.module.PINS_FILE = self.module.CONFIG_DIR / "pins.json"
        self.module.PINS_LOCK_FILE = self.module.CONFIG_DIR / "pins.lock"
        self.module.CAELESTIA_CONFIG = root / "caelestia" / "shell.json"
        self.module.PID_LOCK_FILE = root / "cache" / "instance.lock"

    def tearDown(self):
        self.temporary.cleanup()

    def test_fullscreen_uses_the_dock_monitor_not_focused_monitor(self):
        responses = {
            "monitors": [
                {
                    "name": "first",
                    "focused": True,
                    "x": 0,
                    "y": 0,
                    "width": 1920,
                    "height": 1080,
                    "scale": 1,
                    "activeWorkspace": {"id": 1, "name": "1"},
                },
                {
                    "name": "second",
                    "focused": False,
                    "x": 1920,
                    "y": 0,
                    "width": 1920,
                    "height": 1080,
                    "scale": 1,
                    "activeWorkspace": {"id": 2, "name": "2"},
                },
            ],
            "workspaces": [
                {"id": 1, "name": "1", "hasfullscreen": False},
                {"id": 2, "name": "2", "hasfullscreen": True},
            ],
        }
        with mock.patch.object(
            self.module, "hypr_json", side_effect=lambda command: responses[command]
        ):
            fullscreen = self.module.hypr_monitor_fullscreen(
                (1920.0, 0.0, 1920.0, 1080.0), []
            )
        self.assertIs(fullscreen, True)

    def test_failed_fullscreen_query_is_unknown(self):
        with mock.patch.object(self.module, "hypr_json", return_value=None):
            self.assertIsNone(self.module.hypr_monitor_fullscreen(None, None))

    def test_file_manager_placeholders_are_replaced_once(self):
        with mock.patch.object(
            self.module,
            "caelestia_explorer_command",
            return_value=["custom-files", "--open", "%U"],
        ):
            self.assertEqual(
                self.module.file_manager_command("trash:///"),
                ["custom-files", "--open", "trash:///"],
            )

    def test_concurrent_pin_saves_are_atomic(self):
        children = []
        for index in range(24):
            pid = os.fork()
            if pid == 0:
                try:
                    self.module.save_pinned_keys(
                        ["builtin:files", f"desktop:test-{index}.desktop"]
                    )
                except Exception:
                    os._exit(1)
                os._exit(0)
            children.append(pid)
        for pid in children:
            _, status = os.waitpid(pid, 0)
            self.assertEqual(status, 0)

        payload = json.loads(self.module.PINS_FILE.read_text(encoding="utf-8"))
        self.assertEqual(payload["version"], 1)
        self.assertEqual(payload["items"][0], "builtin:files")
        self.assertEqual(list(self.module.CONFIG_DIR.glob(".pins.json.*.tmp")), [])

    def test_instance_lock_rejects_a_second_process(self):
        handle = self.module.acquire_instance_lock()
        self.assertIsNotNone(handle)
        pid = os.fork()
        if pid == 0:
            second = self.module.acquire_instance_lock()
            os._exit(0 if second is None else 1)
        _, status = os.waitpid(pid, 0)
        self.module.release_instance_lock(handle)
        self.assertEqual(status, 0)


if __name__ == "__main__":
    unittest.main()
