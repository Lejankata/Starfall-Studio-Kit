# Customizing Starfall

You only need to edit the **server script** for most gameplay changes.

## Change the saving namespace

In `src/server/StarfallServer.server.luau`, edit `CONFIG.DataStoreName`. Use a distinct value for separate test games or incompatible save-data versions. Do not change the name in a live game without planning a migration.

## Adjust gameplay

The `CONFIG` table controls:

| Key | Default | Meaning |
|---|---:|---|
| `SaveEverySeconds` | 75 | Autosave interval |
| `DailyReward` | 75 | Credits for a daily check-in |
| `CrystalsPerZone` | 12 | Crystals in each of the 3 zones |
| `RespawnSeconds` | 9 | Seconds before a crystal reappears |
| `GatherRadius` | 13 | Server's player-to-crystal distance limit |

Each zone also defines a color, center position, and base energy yield. Edit the `ZONES` table.

### Upgrades

`UPGRADES` holds the name, base cost, growth factor, and maximum level. Actual price calculation happens on the server. The client receives item prices from the server snapshot, so client displays stay aligned.

- `pack` adds 20 backpack capacity per level.
- `power` adds 1 energy gained per crystal per level.
- `boots` adds 2 WalkSpeed per level.

### Quest goals

`QUESTS` contains the goal, completion threshold and reward. Quest progress is updated on server events, not from client-submitted numbers.

## Change the appearance

- Server `COLORS`: environment, signs, and crystals.
- Client `C`: interface accent colors.
- Client `updateSize`: modal sizing on mobile and desktop.
- Client `makeRow`: card layout for upgrades, quests, and guide instructions.

All art is built from Roblox Parts. Replace parts with original models when you have tested a gameplay loop.

## Add a new upgrade safely

A new upgrade must be added to the authoritative server tables and save schema, plus its effect in gameplay code. Adding only a new UI button will not award anything. Never trust a client-sent price or currency amount.

## Avoid a common mistake

The server script **must not** live inside Workspace. The client script **must not** live inside ServerScriptService. Follow the README setup paths exactly.
