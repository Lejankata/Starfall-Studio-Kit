# Upgrading from v1 to v2

## In Roblox Studio

1. Stop your currently running test and save a copy of your existing `.rbxl` or `.rbxlx` place file.
2. Open `ServerScriptService > StarfallServer`, select all code, paste the **entire** new `src/server/StarfallServer.server.luau`.
3. Open `StarterPlayer > StarterPlayerScripts > StarfallClient`, select all code, paste the **entire** new `src/client/StarfallClient.client.luau`.
4. Confirm that **only one** StarfallServer and **only one** StarfallClient are enabled. Do not keep the old copies running.
5. Press F5. You should see two new regions and PET SANCTUARY / WORLD PORTAL kiosks. Press the Menu button to see seven tabs.
6. Test pets, worlds, leaderboard, and old progress against a **private test experience**. Never run Studio against live production player data.

## Save compatibility

The DataStore name remains `StarfallStudioKit_v1` on purpose. Old saves should retain credits, energy, lifetime crystals, upgrades, quests, and daily reward state. New fields (`pets`, `unlocked`, `upgrades.market`) are safely defaulted on load. No reset is intended. If loading fails, the game does not overwrite an existing save with a blank profile.

## New mechanics

| Feature | Price / rule |
| --- | --- |
| Star Wisp | 150 credits, +2 energy per crystal |
| Comet Fox | 450 credits, +5 energy per crystal |
| Nebula Dragon | 1,500 credits, +10 energy per crystal |
| Frostspire Peaks | 500 credits, 16 base energy per crystal |
| Nebula Gardens | 1,800 credits, 25 base energy per crystal |
| Market Expert | 250 credits first level, +1 credit per energy sold per level |
| Leaderboard | Live ranking of players in the **same server**, not global |

Only one pet may be equipped. Pet purchases are deterministic, not random. Both the zone ownership and pet bonus are checked server-side.

## GitHub Codespaces update

Download `install_starfall_v2.sh` from the accompanying release. Open your existing GitHub Codespace for `Starfall-Studio-Kit`, drag the script into the root of its file Explorer, then run:

```bash
bash install_starfall_v2.sh
```

The installer checks that the working tree is clean and that the repository is on `main`, applies the bundled source patch, runs Python structural tests, commits, and pushes to GitHub. It does not edit Roblox Studio. If anything fails, keep the original files and read the terminal output. Do not run the installer twice.

For manual patching instead, upload `Starfall-v2.patch`, run `git apply --check Starfall-v2.patch`, then `git apply Starfall-v2.patch`. Run the checks before committing and pushing.

## Testing

See `docs/TESTING.md` for the quick combined checklist. Python tests are static checks only; Studio runtime and DataStore persistence require manual verification.
