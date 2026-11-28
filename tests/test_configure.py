"""임시 프로젝트에서 실제 Godot CLI로 configure의 파일 보존과 최초 생성을 검사한다."""
import configparser
import os
from pathlib import Path
import shutil
import subprocess
from tempfile import TemporaryDirectory
import unittest


ROOT = Path(__file__).resolve().parents[1]


class ConfigureTests(unittest.TestCase):
    def setUp(self):
        temp = TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        self.project = self.root / "project.godot"
        self.presets = self.root / "export_presets.cfg"
        self.project.write_text('config_version=5\n[application]\nconfig/name="Before sync"\n')
        for path in ("config/game.cfg", "tools/configure.gd"):
            (self.root / path).parent.mkdir()
            shutil.copyfile(ROOT / path, self.root / path)

    def configure(self):
        return subprocess.run(
            [os.environ.get("GODOT", "godot"), "--headless", "--path", str(self.root),
             "--script", "res://tools/configure.gd"],
            capture_output=True, text=True, timeout=30,
        )

    def test_malformed_presets_preserve_both_files(self):
        self.presets.write_text('[preset.0]\nname="Android"\nvalue=]\n')
        project_before = self.project.read_bytes()
        presets_before = self.presets.read_bytes()
        result = self.configure()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("export_presets.cfg", result.stderr)
        self.assertEqual(self.project.read_bytes(), project_before)
        self.assertEqual(self.presets.read_bytes(), presets_before)

    def test_missing_presets_are_created_and_sync_is_repeatable(self):
        result = self.configure()
        self.assertEqual(result.returncode, 0, result.stderr)
        presets = self.presets.read_bytes()
        for name in (b'Android', b'iOS', b'Android Google Play', b'Android ONE store'):
            self.assertIn(b'name="' + name + b'"', presets)
        project = self.project.read_bytes()
        self.assertNotIn(b'Before sync', project)
        result = self.configure()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.presets.read_bytes(), presets)
        self.assertEqual(self.project.read_bytes(), project)

    def test_reordered_presets_keep_options_and_new_stores_copy_android(self):
        self.presets.write_text(
            '[preset.0]\nname="iOS"\nplatform="iOS"\n'
            '[preset.0.options]\napplication/app_store_team_id="TEAM"\n'
            '[preset.1]\nname="Device Probe"\nplatform="Android"\ncustom_features="pgs_probe"\n'
            '[preset.1.options]\npackage/unique_name="com.example.probe"\n'
            '[preset.2]\nname="Android"\nplatform="Android"\n'
            '[preset.2.options]\narchitectures/x86_64=true\n'
            '[preset.3]\nname="Android Google Play"\nplatform="Android"\n'
            '[preset.3.options]\nscreen/immersive_mode=false\n'
        )
        result = self.configure()
        self.assertEqual(result.returncode, 0, result.stderr)
        config = configparser.ConfigParser(interpolation=None)
        config.read(self.presets)
        self.assertEqual(config['preset.0']['name'], '"iOS"')
        self.assertEqual(config['preset.0.options']['application/app_store_team_id'], '"TEAM"')
        self.assertEqual(config['preset.1']['name'], '"Device Probe"')
        self.assertEqual(dict(config['preset.1.options']), {'package/unique_name': '"com.example.probe"'})
        self.assertEqual(config['preset.2']['export_path'], '"build/android/mobile-template.apk"')
        self.assertEqual(config['preset.3.options']['screen/immersive_mode'], 'false')
        self.assertEqual(config['preset.4']['name'], '"Android ONE store"')
        self.assertEqual(config['preset.4']['platform'], '"Android"')
        self.assertEqual(config['preset.4.options']['architectures/x86_64'], 'true')
        self.assertNotIn('application/app_store_team_id', config['preset.4.options'])
        before = self.presets.read_bytes()
        self.assertEqual(self.configure().returncode, 0)
        self.assertEqual(self.presets.read_bytes(), before)

    def test_missing_base_keeps_custom_preset_in_first_position(self):
        self.presets.write_text('[preset.0]\nname="Linux QA"\nplatform="Linux"\n')
        result = self.configure()
        self.assertEqual(result.returncode, 0, result.stderr)
        config = configparser.ConfigParser(interpolation=None)
        config.read(self.presets)
        self.assertEqual(dict(config['preset.0']), {'name': '"Linux QA"', 'platform': '"Linux"'})
        self.assertEqual(config['preset.1']['name'], '"Android"')
        self.assertEqual(config['preset.2']['name'], '"iOS"')

    def test_reserved_name_on_another_platform_preserves_both_files(self):
        self.presets.write_text('[preset.0]\nname="Android"\nplatform="Linux"\n')
        original = self.presets.read_bytes()
        project = self.project.read_bytes()
        result = self.configure()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Conflicting export preset 'Android'", result.stderr)
        self.assertEqual(self.presets.read_bytes(), original)
        self.assertEqual(self.project.read_bytes(), project)


if __name__ == "__main__":
    unittest.main()
