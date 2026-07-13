import json
import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class RepositoryTests(unittest.TestCase):
    def test_pre_commit_runs_tests(self):
        config = (ROOT / ".pre-commit-config.yaml").read_text()
        self.assertIn("python3 -m unittest discover -s tests -v", config)

    def test_manifest_is_valid_when_present(self):
        manifest = ROOT / "manifest.json"
        if manifest.exists():
            parsed = json.loads(manifest.read_text())
            self.assertEqual(parsed["schema_version"], 1)
            self.assertTrue(parsed["groups"])
            self.assertTrue(parsed["skills"])

    def test_installer_syntax_when_present(self):
        installer = ROOT / "install.sh"
        if installer.exists():
            subprocess.run(["bash", "-n", str(installer)], check=True)


if __name__ == "__main__":
    unittest.main()
