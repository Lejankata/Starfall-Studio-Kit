# Starfall Studio Kit

**An open-source Roblox crystal adventure with pets, unlockable worlds, quests, and upgrade systems.**

Version 2.0 adds two unlockable regions, three adoptable pet companions, a fourth upgrade path, live per-server rankings, improved procedurally generated scenery, and an expanded mobile-friendly menu. The game is built from Roblox primitives without paid assets.

> **Status:** The original v1 game mechanics were user-playtested in Roblox Studio. The new v2 features have **not** been independently playtested in Studio. Static repository checks are provided. Before publishing a public experience, follow [the Studio checklist](docs/TESTING.md) and fix any issues you encounter. The code is a learning/starter kit, not a production trading or payments framework.

## What is included

| Feature | Behavior |
|---|---|
| Playable world | Town square, six interactive kiosks, five crystal zones, 60 total collectibles |
| Core gameplay | Collect energy, fill your backpack, sell energy for credits |
| Four upgrades | Backpack capacity, harvest power, movement speed, and selling price |
| Three daily quests | Collect crystals, sell energy, and purchase upgrades; reward claims are server-validated |
| Daily reward | One 75-credit reward per UTC day, validated on the server |
| Pets | Three adoptable and equipable companions with server-validated energy bonuses |
| Worlds | Two additional regions unlocked using earned credits; access checked on the server |
| Rankings | Current server leaderboard for credits, crystals, and accessible worlds |
| Visuals | Decorated pathways, lanterns, trees, glow, and client-rendered companion followers |
| Player progress | Credits, energy, upgrades, pets, world unlocks, quests, and daily reward state saved through DataStoreService |
| Multiplayer | Server-owned shared crystals; separate player currencies and progress |
| UI | Credits/energy/pet HUD, seven tabs including pets, worlds and rankings; adjusts for mobile widths |
| Safety | Remote action allowlist, type/length/rate checks, proximity checks, authoritative pricing |
| Developer tooling | Rojo project, manual installation path, docs, contribution templates, Python static checks |

No external artwork, paid assets, or Roblox marketplace dependencies are required. All map structures are generated at runtime.

## Quick installation, no coding tools required

For an existing v1 experience, replace **both** old scripts with the new ones. Keep the published test experience and its DataStore name to preserve saved progress. See [the v2 upgrade guide](docs/V2_UPGRADE.md).

These are the **only two scripts** you need to install manually.

1. Open **Roblox Studio** and choose a fresh **Baseplate**. Leave its SpawnLocation in place.
2. Open **Explorer**. Under **ServerScriptService**, insert a **Script** and name it `StarfallServer`.
3. Replace the default script contents with all of [src/server/StarfallServer.server.luau](src/server/StarfallServer.server.luau).
4. Under **StarterPlayer > StarterPlayerScripts**, insert a **LocalScript** and name it `StarfallClient`.
5. Replace its contents with all of [src/client/StarfallClient.client.luau](src/client/StarfallClient.client.luau).
6. Press **Play**. You should see five crystal zones, a town square with kiosks, and the **STARFALL / MENU** button.
7. Gather a crystal by walking near it and pressing **E**. On mobile, use Roblox's interaction prompt. Return to **SELL ENERGY** to convert gathered energy into credits.
8. Open the menu to adopt pets, unlock worlds, upgrade tools, view rankings, and claim rewards.

Do **not** put either script in Workspace. The server script belongs in ServerScriptService. The client script belongs in StarterPlayerScripts.

### How to test saving

Roblox DataStore APIs require a **published experience**. Publish a **private test experience**, then use **File > Experience Settings > Security > Enable Studio Access to API Services**. Test that credits and upgrades persist after restarting. Do not enable Studio access on a live production game with real player data: Studio accesses the same stored data. Official guidance: https://create.roblox.com/docs/cloud-services/data-stores

If an unpublished experience cannot access DataStoreService, this project attempts to run in an **unsaved demo mode** instead. The HUD's Guide tab shows a saving-status message. This is intentional; unsaved sessions should never overwrite existing progress.

## Advanced installation with Rojo

This repository also contains `default.project.json` for [Rojo 7](https://rojo.space/docs/v7/). Open the project with your existing Rojo workflow (`rojo serve` and its Studio plugin). The source maps to the same two script locations. **Rojo is optional** and unnecessary for the manual installation above.

## The gameplay loop

1. Gather crystals from Starlight Meadow, Amber Canyon, and Moonlit Glade.
2. Fill your backpack with energy; the default capacity is 30.
3. Sell the energy at the green kiosk for **3 credits per energy initially (upgradeable)**.
4. Spend credits on backpack capacity, gathering power, speed, or a better selling rate. Adopt a pet and unlock Frostspire Peaks and Nebula Gardens.
5. Complete three daily quests, claim rewards, and check in each day.
6. Rejoin your **private test experience** and verify saved progress.

The game currently has no Robux purchases, trading, paid random rewards, or third-party analytics. Pets are bought directly with earned credits and have fixed bonuses, not randomized eggs.

## File structure

```text
Starfall-Studio-Kit/
├── src/
│   ├── server/StarfallServer.server.luau
│   └── client/StarfallClient.client.luau
├── docs/
│   ├── V2_UPGRADE.md
│   ├── ARCHITECTURE.md
│   ├── CUSTOMIZATION.md
│   ├── SECURITY.md
│   ├── TESTING.md
│   └── ROADMAP.md
├── tests/test_repo.py
├── tools/verify.py
├── .github/
│   ├── workflows/verify.yml
│   ├── ISSUE_TEMPLATE/
│   └── pull_request_template.md
├── default.project.json
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── SECURITY.md
├── CHANGELOG.md
└── LICENSE
```

## Quality and limitations

- All currency, quest completion, prices, and resource availability are decided server-side. Clients request actions, but they do not award themselves credits.
- DataStore reads and writes use protected calls. If loading fails, that session does **not** write data, protecting the existing record from accidental overwrite.
- `UpdateAsync` helps with writes but this kit **does not** implement cross-server session locking. The starter is **not suitable for live trading/economies** without upgrades.
- Crystals are **shared by all players on one server**, and each one respawns after nine seconds. Pets are drawn cosmetically on each player’s client, based on server-replicated attributes.
- Quest/daily resets use the **UTC date**, not players' local timezones.
- The Studio map is generated from parts and is not intended to represent final game art.
- Automated checks in this repository are **static**, not Roblox gameplay tests. Please follow the manual testing guide.

See [ARCHITECTURE](docs/ARCHITECTURE.md), [SECURITY](docs/SECURITY.md), [CUSTOMIZATION](docs/CUSTOMIZATION.md), and [TESTING](docs/TESTING.md).

## Contributing

Issue reports and genuine improvements are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) and our [Code of Conduct](CODE_OF_CONDUCT.md). In particular, real Roblox Studio playtest results, bug fixes, UI accessibility improvements, and data-safety improvements are valuable.

## License and provenance

MIT License. See [LICENSE](LICENSE). This codebase was developed with AI assistance and requires independent Roblox Studio testing. Do not claim popularity, downloads, stars, merged contributions, or production readiness that have not happened.

**Claude promotion:** Publishing this repository does not automatically meet Anthropic's open-source eligibility requirements. Approval depends on genuine open-source contributions and adoption, not repository size.
