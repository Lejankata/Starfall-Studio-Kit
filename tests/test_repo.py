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

    def test_expansion_source_contracts(self):
        server = (ROOT / "src/server/StarfallServer.server.luau").read_text()
        client = (ROOT / "src/client/StarfallClient.client.luau").read_text()
        for key in ("StarfallStudioKit_v1", 'id = "frost"', 'id = "nebula"',
                    'wisp = {', 'fox = {', 'dragon = {', 'market = {',
                    'action == "petBuy"', 'action == "petEquip"', 'action == "worldBuy"',
                    'data.pets.owned', 'data.unlocked', 'petBonus(data)', 'sellPrice(data)'):
            self.assertIn(key, server)
        for key in ('activeTab == "Pets"', 'activeTab == "Worlds"',
                    'activeTab == "Leaders"', 'GetAttribute("StarfallPet")',
                    '"petBuy"', '"petEquip"', '"worldBuy"'):
            self.assertIn(key, client)

    def test_v2_docs(self):
        self.assertTrue((ROOT / "docs/V2_UPGRADE.md").is_file())
        self.assertIn("Studio Test Plan", (ROOT / "docs/TESTING.md").read_text())

    def test_readme_links_to_actual_sources(self):
        readme = (ROOT / "README.md").read_text()
        for path in ("src/server/StarfallServer.server.luau", "src/client/StarfallClient.client.luau", "docs/TESTING.md"):
            self.assertIn(path, readme)
            self.assertTrue((ROOT / path).exists())


if __name__ == "__main__":
    unittest.main()
