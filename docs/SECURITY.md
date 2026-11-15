# Security model and limitations

## Trust boundaries

The Roblox server is the authority on collectible availability, distance, credits, item costs, quest completion, reward claims, and saved data. Client UI requests carry **action names and item IDs only**. This prevents the common beginner mistake of accepting a currency amount from the client.

Implemented safeguards:

- Remote actions restricted to an allowlist: `hello`, `buy`, `quest`, `daily`.
- Type and length checks for remote arguments.
- Per-player cooldown for economy actions.
- Server-owned prices and levels.
- Server-side player-to-object distance check on each in-world interaction.
- Atomic availability flip before awarding a crystal (no yield between check and update).
- Per-player DataStore records, protected reads/writes, and refusing saves after failed loads.
- Clamping input values loaded from persistence.

## Threats not solved

- No cross-server session locking. Two simultaneous sessions for one account can cause stale writes.
- No durable transaction journal for trading, developer products, or Robux purchases.
- No sophisticated economy exploit monitoring or fraud scoring.
- A player can automate legitimate proximity interactions at human-impossible frequency across time if they remain within range; add further behavioral controls for a high-value public economy.
- No automatic rollback or migration tooling for save-data schema changes.

The starter is for learning and prototyping. For monetized production games, get an experienced Roblox developer to review persistence, purchase receipt handling, and exploit resistance.

Sources:
- https://create.roblox.com/docs/scripting/security/security-tactics
- https://create.roblox.com/docs/cloud-services/data-stores
- https://create.roblox.com/docs/scripting/events/remote
