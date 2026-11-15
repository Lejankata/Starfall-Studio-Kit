"""Non-runtime checks: never mistake these for Roblox Studio tests."""
import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from verify import validate  # noqa: E402


class RepositoryChecks(unittest.TestCase):
    def test_structure(self):
        self.assertEqual([], validate())

    def test_config_json_parses(self):
        project = json.loads((ROOT / "default.project.json").read_text())
        self.assertEqual("DataModel", project["tree"]["$className"])

    def test_no_paid_or_secret_config(self):
        server = (ROOT / "src/server/StarfallServer.server.luau").read_text()
        self.assertNotIn("MarketplaceService:PromptProductPurchase", server)
        self.assertNotIn("HttpService:RequestAsync", server)

    def test_readme_links_to_actual_sources(self):
        readme = (ROOT / "README.md").read_text()
        for path in ("src/server/StarfallServer.server.luau", "src/client/StarfallClient.client.luau", "docs/TESTING.md"):
            self.assertIn(path, readme)
            self.assertTrue((ROOT / path).exists())


if __name__ == "__main__":
    unittest.main()
