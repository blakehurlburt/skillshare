import json
import os
import re
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = json.loads((ROOT / "manifest.json").read_text())


class RepositoryTests(unittest.TestCase):
    def test_pre_commit_runs_tests(self):
        config = (ROOT / ".pre-commit-config.yaml").read_text()
        self.assertIn("python3 -m unittest discover -s tests -v", config)

    def test_manifest_is_consistent(self):
        self.assertEqual(MANIFEST["schema_version"], 1)
        grouped = set()
        for name, group in MANIFEST["groups"].items():
            self.assertTrue(group["description"], name)
            for skill in group["skills"]:
                self.assertIn(skill, MANIFEST["skills"], f"{name}: {skill}")
                self.assertNotIn(skill, grouped, f"skill appears in two groups: {skill}")
                grouped.add(skill)
        self.assertEqual(grouped, set(MANIFEST["skills"]))

    def test_bundled_payloads_exist_for_each_agent(self):
        for skill, metadata in MANIFEST["skills"].items():
            for agent in metadata["agents"]:
                path = ROOT / "payloads" / agent / "skills" / skill
                if metadata["source"] == "bundled":
                    self.assertTrue((path / "SKILL.md").is_file(), str(path))
                else:
                    self.assertFalse(path.exists(), f"external source was republished: {path}")

    def test_skill_files_have_frontmatter(self):
        for skill_file in (ROOT / "payloads").glob("**/SKILL.md"):
            text = skill_file.read_text(errors="replace")
            self.assertTrue(text.startswith("---\n"), str(skill_file))
            self.assertGreaterEqual(text.count("---"), 2, str(skill_file))

    def test_payload_has_no_nested_repositories_or_symlinks(self):
        for root_name in ("payloads", "runtime"):
            root = ROOT / root_name
            self.assertFalse(any(p.name == ".git" for p in root.rglob(".git")))
            self.assertFalse(any(p.is_symlink() for p in root.rglob("*")))

    def test_personal_machine_paths_are_removed(self):
        forbidden = ("/Users/blake", "blakewhurlburt@gmail.com")
        for root_name in ("payloads", "runtime", "profiles"):
            for path in (ROOT / root_name).rglob("*"):
                if not path.is_file():
                    continue
                try:
                    text = path.read_text()
                except UnicodeDecodeError:
                    continue
                for value in forbidden:
                    self.assertNotIn(value, text, str(path))

    def test_no_obvious_live_secrets(self):
        patterns = [
            re.compile(r"sk-(?!proj-your)(?!your-)[A-Za-z0-9_-]{24,}"),
            re.compile(r"AKIA[0-9A-Z]{16}"),
            re.compile(r"gh[op]_[A-Za-z0-9]{20,}"),
            re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
        ]
        for path in ROOT.rglob("*"):
            if not path.is_file() or ".git" in path.parts:
                continue
            try:
                text = path.read_text()
            except UnicodeDecodeError:
                continue
            for pattern in patterns:
                self.assertIsNone(pattern.search(text), str(path))

    def test_detached_runtime_has_no_updater_or_remote_telemetry(self):
        bin_dir = ROOT / "runtime" / "gstack" / "bin"
        for name in ("gstack-update-check", "gstack-telemetry-log", "gstack-telemetry-sync", "gstack-upgrade"):
            self.assertFalse((bin_dir / name).exists(), name)
        for path in (ROOT / "runtime").rglob("*"):
            if not path.is_file():
                continue
            try:
                text = path.read_text()
            except UnicodeDecodeError:
                continue
            self.assertNotIn("functions/v1/telemetry-ingest", text, str(path))
            self.assertNotRegex(text, r"git clone .*github\.com/garrytan/gstack", str(path))

    def test_external_sources_are_revision_pinned(self):
        installer = (ROOT / "install.sh").read_text()
        for name, dependency in MANIFEST["external_dependencies"].items():
            self.assertRegex(dependency["revision"], r"^[0-9a-f]{40}$", name)
            self.assertRegex(dependency["sha256"], r"^[0-9a-f]{64}$", name)
            self.assertIn(dependency["revision"], dependency["url"])
            self.assertIn(dependency["sha256"], installer)
        self.assertIn('BUN_VERSION="1.3.10"', installer)
        self.assertIn(
            'BUN_INSTALL_SHA="bab8acfb046aac8c72407bdcce903957665d655d7acaa3e11c7c4616beae68dd"',
            installer,
        )

    def test_runtime_dependency_surface_is_trimmed(self):
        package = json.loads((ROOT / "runtime" / "gstack" / "package.json").read_text())
        declared = set(package.get("dependencies", {})) | set(package.get("devDependencies", {}))
        unused = {
            "@anthropic-ai/claude-agent-sdk",
            "@huggingface/transformers",
            "puppeteer-core",
        }
        self.assertTrue(unused.isdisjoint(declared), sorted(unused & declared))

    def test_attribution_and_licenses_exist(self):
        notice = (ROOT / "THIRD_PARTY_NOTICES.md").read_text()
        self.assertIn("gstack", notice)
        self.assertIn("Claudeception", notice)
        self.assertIn("VibeSec", notice)
        self.assertIn("Copyright (c) 2026 Garry Tan", (ROOT / "third_party" / "GSTACK_LICENSE").read_text())
        self.assertIn("Copyright (c) 2026 Blake Hurlburt", (ROOT / "LICENSE").read_text())

    def test_shell_scripts_are_valid_and_executable(self):
        for script in (ROOT / "install.sh", ROOT / "runtime" / "gstack" / "build-shareable.sh"):
            subprocess.run(["bash", "-n", str(script)], check=True)
            self.assertTrue(os.access(script, os.X_OK), str(script))

    def test_installer_lists_and_dry_runs(self):
        listed = subprocess.run(
            ["bash", str(ROOT / "install.sh"), "--list"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout
        for group in MANIFEST["groups"]:
            self.assertIn(group, listed)
        dry_run = subprocess.run(
            [
                "bash",
                str(ROOT / "install.sh"),
                "--agent",
                "codex",
                "--groups",
                "core,planning",
                "--exclude",
                "claudeception",
                "--dry-run",
            ],
            check=True,
            capture_output=True,
            text=True,
        ).stdout
        self.assertIn("Dry run complete", dry_run)
        self.assertNotIn("claudeception", dry_run.split("Skills:", 1)[1].splitlines()[0])

    def test_installer_runs_cleanly_from_a_copy_paste_command(self):
        result = subprocess.run(
            ["bash", "-c", (ROOT / "install.sh").read_text(), "--", "--list"],
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
        )
        self.assertIn("Available groups", result.stdout)
        self.assertNotIn("unbound variable", result.stderr)

    def test_local_field_notes_install_for_both_agents(self):
        with tempfile.TemporaryDirectory() as home:
            env = os.environ.copy()
            env["HOME"] = home
            subprocess.run(
                [
                    "bash",
                    str(ROOT / "install.sh"),
                    "--agent",
                    "both",
                    "--groups",
                    "field-notes",
                    "--yes",
                ],
                check=True,
                capture_output=True,
                text=True,
                env=env,
            )
            for agent in ("claude", "codex"):
                skills_root = Path(home) / f".{agent}" / "skills"
                self.assertTrue((skills_root / "ntfy-unicode-headers" / "SKILL.md").is_file())
                self.assertTrue((skills_root / "share-agent-skills-safely" / "SKILL.md").is_file())
                self.assertTrue((skills_root / "_shared" / "preamble.md").is_file())
                self.assertFalse((skills_root / "claudeception").exists())

    def test_profile_merge_is_idempotent(self):
        with tempfile.TemporaryDirectory() as home:
            env = os.environ.copy()
            env["HOME"] = home
            command = [
                "bash",
                str(ROOT / "install.sh"),
                "--agent",
                "codex",
                "--profile",
                "--yes",
            ]
            subprocess.run(command, check=True, capture_output=True, text=True, env=env)
            subprocess.run(command, check=True, capture_output=True, text=True, env=env)
            profile = (Path(home) / ".codex" / "AGENTS.md").read_text()
            self.assertEqual(profile.count("<!-- skillshare:solo-dev:start -->"), 1)
            self.assertEqual(profile.count("<!-- skillshare:solo-dev:end -->"), 1)


if __name__ == "__main__":
    unittest.main()
