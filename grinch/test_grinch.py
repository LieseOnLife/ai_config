import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
GRINCH = "/Applications/Grinch.app/Contents/MacOS/Grinch"


class GrinchTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home, self.repo = self.root / "home", self.root / "repo"
        self.config = self.home / ".config/grinch"
        self.bin = self.home / ".local/bin"
        self.env = dict(os.environ, HOME=str(self.home), PATH=f"{self.bin}:{os.environ['PATH']}")
        shutil.copytree(ROOT / "scripts", self.repo / "scripts")
        shutil.copytree(ROOT / "grinch", self.repo / "grinch")
        for profile in ["Default", "Profile 3"]:
            (self.home / "Library/Application Support/Google/Chrome" / profile).mkdir(parents=True)

    def command(self, args, expected=0, answer=None):
        result = subprocess.run(args, env=self.env, input=answer, text=True,
                                capture_output=True, timeout=15)
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        return result.stdout

    def script(self, name, *args, expected=0, answer=None):
        return self.command(["bash", str(self.repo / "scripts" / name), *args], expected, answer)

    def install(self):
        self.script("install-grinch.sh", answer="y\n")

    def snapshot(self):
        return {str(p.relative_to(self.root)): (p.stat().st_mode, p.stat().st_mtime_ns,
                p.read_bytes() if p.is_file() else None) for p in self.root.rglob("*")}

    def test_dry_runs_write_nothing(self):
        before = self.snapshot()
        self.script("install-grinch.sh", "--dry-run")
        self.assertEqual(self.snapshot(), before)
        self.install()
        shutil.rmtree(self.repo / "grinch")
        before = self.snapshot()
        self.script("sync-grinch.sh", "--dry-run")
        self.script("sync-all.sh", "--dry-run")
        self.assertEqual(self.snapshot(), before)

    def test_install_and_config_only_sync(self):
        self.install()
        self.assertTrue((self.config / ".ai-config-managed").is_file())
        self.assertTrue(os.access(self.bin / "open-gov", os.X_OK))
        self.assertEqual((self.bin / "open-gov").read_bytes(), (ROOT / "grinch/open-gov").read_bytes())
        (self.config / "grinch.js").write_text("module.exports = { default: null };\n")
        (self.config / "private.json").write_text("not configuration")
        self.script("sync-grinch.sh")
        self.assertEqual((self.config / "grinch.js").read_bytes(),
                         (self.repo / "grinch/grinch.js").read_bytes())
        self.assertFalse((self.repo / "grinch/private.json").exists())
        self.assertFalse((self.repo / "grinch/.ai-config-managed").exists())

    def test_missing_config_and_invalid_arguments(self):
        self.script("sync-grinch.sh", expected=1)
        self.script("install-grinch.sh", "--invalid", expected=2)
        self.script("sync-grinch.sh", "--dry-run", "extra", expected=2)
        self.script("install-grinch.sh", answer="n\n", expected=1)
        self.assertFalse(self.config.exists())
        self.install()
        (self.config / "grinch.js").unlink()
        self.script("sync-grinch.sh", expected=1)

    def test_competing_configs_and_symlinks(self):
        conflict = self.home / ".grinch.js"
        conflict.touch()
        before = self.snapshot()
        self.script("install-grinch.sh", "--dry-run", expected=1)
        self.assertEqual(self.snapshot(), before)
        conflict.unlink()
        self.install()
        (self.home / ".config/grinch.js").symlink_to(self.root / "missing")
        self.script("sync-grinch.sh", expected=1)
        (self.home / ".config/grinch.js").unlink()
        (self.config / "grinch.js").unlink()
        (self.config / "grinch.js").symlink_to(ROOT / "grinch/grinch.js")
        self.script("sync-grinch.sh", expected=1)

    def test_missing_profile_and_nonregular_targets(self):
        profile = self.home / "Library/Application Support/Google/Chrome/Profile 3"
        profile.rmdir()
        self.script("install-grinch.sh", "--dry-run", expected=1)
        self.assertFalse(self.config.exists())
        profile.mkdir()
        self.config.mkdir(parents=True)
        (self.config / "grinch.js").mkdir()
        self.script("install-grinch.sh", "--dry-run", expected=1)
        (self.config / "grinch.js").rmdir()
        (self.config / ".ai-config-managed").symlink_to(self.root / "missing")
        self.script("install-grinch.sh", "--dry-run", expected=1)

    def test_gov_launcher(self):
        self.install()
        mock = self.bin / "open"
        mock.write_text('#!/bin/bash\nprintf "%s\\n" "$@"\n')
        mock.chmod(0o755)
        url = "https://identity.example/login?a=1&b=two%20words"
        output = self.command([str(self.bin / "open-gov"), url])
        self.assertEqual(output.splitlines(), ["-na", "Google Chrome", "--args",
                         "--profile-directory=Profile 3", url])
        for args in [[], ["--help"], ["file:///tmp/test"], ["https://"], ["https:///path"],
                     ["https://example.com/a b"], [url, url]]:
            self.command([str(self.bin / "open-gov"), *args], expected=2)
        (self.home / "Library/Application Support/Google/Chrome/Profile 3").rmdir()
        self.command([str(self.bin / "open-gov"), url], expected=1)

    def test_native_routes(self):
        self.install()
        self.command([GRINCH, "--validate"])
        gov = ["https://ddog-gov.com", "https://login.ddog-gov.com/a", "https://fed.dog",
               "https://vault.fed.dog/a", "https://FED.DOG/login", "http://fed.dog:8080/a",
               "https://console.amazonaws-us-gov.com",
               "https://us-gov-west-1.console.amazonaws-us-gov.com/ecs",
               "https://d-9067f50546.awsapps.com/start/#/?tab=accounts"]
        commercial = ["https://datadoghq.com", "https://prod.dog", "https://vault.prod.dog",
                      "https://staging.dog", "https://ddbuild.io", "https://ci.ddbuild.io",
                      "https://github.com/DataDog", "https://github.com/LieseOnLife",
                      "https://datadoghq.atlassian.net/wiki", "https://example.com",
                      "https://notfed.dog", "https://fed.dog.example.com",
                      "https://ddog-gov.com.example.com", "https://example.com/?next=fed.dog",
                      "https://awsapps.com", "https://console.aws.amazon.com",
                      "https://amazonaws-us-gov.com.example.com",
                      "https://d-9067f50546.awsapps.com.example.com"]
        for url in gov + commercial:
            with self.subTest(url=url):
                output = self.command([GRINCH, "--test", url])
                fields = dict(line.split(":", 1) for line in output.splitlines() if ":" in line)
                self.assertEqual(fields["Browser"].strip(), "com.google.Chrome")
                profile = "Profile 3" if url in gov else "Default"
                self.assertEqual(fields["Args"].strip(), f"--profile-directory={profile}")
                self.assertEqual(fields["Final"].strip(), url)


if __name__ == "__main__":
    unittest.main()
