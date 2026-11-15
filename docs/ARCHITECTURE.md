# Architecture

Starfall is deliberately installable with just **two Luau scripts**, one server script and one client script. The scripts are organized into labeled service functions rather than requiring 15 ModuleScripts for an introductory Roblox Studio setup.

## Flow

```mermaid
flowchart TD
    Client[LocalScript: UI and input] -->|Action: buy / quest / daily / hello| Server[Server Script: validation and game rules]
    Server -->|Snapshot / Toast / Open| Client
    Prompts[World ProximityPrompts] -->|Server-side Triggered + range checks| Server
    Server --> Sessions[Private per-player sessions]
    Sessions -->|Protected GetAsync + UpdateAsync| Store[(Roblox DataStore)]
    Server --> World[Generated map, crystals, kiosks]
```

### Single network channel

`ReplicatedStorage.StarfallNetwork` is created by the server. The client sends the following actions:

| Action | Value | Validation |
|---|---|---|
| `hello` | none | Session exists and finished loading; sends snapshot |
| `buy` | upgrade ID | Allowlisted IDs, server-owned prices and balance, capped levels, action cooldown |
| `quest` | quest ID | Allowlisted IDs, server-owned progress, one-time reward, action cooldown |
| `daily` | none | UTC date, one reward per day, action cooldown |

The **client cannot award itself credits**. Gathering and selling happen through Roblox `ProximityPrompt.Triggered` on the server, with a distance check. Exploiters may fire client-exposed events, so every critical decision must be server-owned.

### Session data

The server keeps a private session per player:

- `coins`, `energy`, `collected`, `sold`
- `upgrades.pack`, `upgrades.power`, `upgrades.boots`
- `daily.day`, `daily.claimed`
- `quests.day`, `quests.progress`, `quests.claimed`

Values are clamped on load to expected numeric ranges. UTC rollover resets daily quests. `sync` sends a **sanitized view** to the HUD; private session tables never live in ReplicatedStorage.

### Saving and shutdown

- Load with `GetAsync` wrapped in `pcall`.
- Save dirty sessions approximately every 75 seconds with `UpdateAsync` wrapped in `pcall`.
- Save on player removal and during `BindToClose`.
- **Important:** if a load fails, saving is turned off for that session. The server does not overwrite a potentially valid existing record with an empty profile.
- No cross-server session lock is implemented. Add a mature profile/session management library before shipping a high-value economy or trading game.

### Map

The map is generated on server start under `Workspace.StarfallWorld`:

- Central town square (spawn area)
- SELL ENERGY kiosk
- UPGRADE SHOP kiosk
- DAILY REWARD kiosk
- QUEST BOARD kiosk
- Three crystal zones, each with 12 crystals

No external assets required. Zone crystal spawns are fixed and server-shared.

### Performance

The world contains 36 interactable crystals. Each has an independent server callback and a nine-second respawn. Scaling to thousands of collectibles would require pooling and more centralized scheduling.
