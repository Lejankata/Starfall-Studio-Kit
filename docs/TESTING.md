# Starfall v2 Studio Test Plan

Run these tests together in a **private** published test experience. Use a second account or a 2-player local server for multiplayer.

## 5-minute smoke test

- [ ] Press F5; five zones and six kiosks appear, with no red Output errors.
- [ ] Gather a starter crystal; energy rises and lifetime Crystals leaderstat rises by one.
- [ ] Sell energy; initial sale pays 3 credits per energy.
- [ ] Buy Market Expert; selling rate becomes 4 credits per energy.
- [ ] Adopt Star Wisp for 150 credits; it appears beside your avatar.
- [ ] Gather a mint crystal with Star Wisp; energy increases by 5 (3 base +2 pet bonus), subject to bag capacity.
- [ ] Equip Comet Fox if purchased; its bonus replaces rather than stacking with the Wisp.
- [ ] Open Worlds; Frostspire Peaks requires 500 credits, Nebula Gardens 1,800.
- [ ] Attempt to gather in locked Frostspire Peaks; no energy is awarded.
- [ ] Unlock Frostspire, then gather there; base energy reward is 16, plus pet/power bonuses.
- [ ] Open Leaders; scores display only players in the current server.
- [ ] Rejoin the private test game; credits, upgrades, pet ownership/equipment, and world unlocks persist.
- [ ] On two clients, gather one shared crystal; it vanishes for both and reappears around 9 seconds later.
- [ ] On two clients, verify separate credits/energy and visible equipped pets.
- [ ] Resize the Studio emulator to a phone viewport; all seven tabs stay accessible.
- [ ] Claim daily reward twice; only the first claim succeeds on the same UTC day.

## Failure reporting

Record the failing step, Output messages, expected and observed numbers, Roblox Studio version, and a screenshot. Never include account secrets. Static checks do not establish gameplay correctness. The source has not received an independent v2 Studio playtest.
