# Manual testing in Roblox Studio

**The automated CI tests only check repository structure and basic source contracts. The following checks require a real Studio playtest. Do not mark boxes complete without testing.**

## Setup

- [ ] Fresh Baseplate, server script under ServerScriptService, client script under StarterPlayerScripts.
- [ ] Play starts and Output shows `[Starfall] World, shop, quests, daily rewards, and pickups initialized.`
- [ ] `Workspace.StarfallWorld` appears under Explorer while Play is running.
- [ ] Three zones and four kiosks render, with floating signs.
- [ ] No red runtime errors in Output.

## Gathering and economy

- [ ] Start with 0 credits and 0/30 energy on a new data profile.
- [ ] Press E on a crystal. Energy increases; the crystal disappears temporarily.
- [ ] Crystal returns after about nine seconds.
- [ ] Fill backpack. Attempting to collect at full capacity gives a message and no extra energy.
- [ ] Walk to the green SELL ENERGY kiosk and use its interaction prompt.
- [ ] Energy resets to 0 and credits increase by 3 times the sold energy.
- [ ] Try selling a second time with an empty backpack; no credits awarded.

## Upgrades and quests

- [ ] Open MENU > Shop; see prices and upgrade levels.
- [ ] Attempt to buy without enough credits; no purchase occurs.
- [ ] With enough credits, buy Backpack, verify increased energy capacity.
- [ ] Buy Crystal Power, verify more energy earned per pickup.
- [ ] Buy Swift Boots, verify increased walking speed, including after a character reset.
- [ ] Collect 12 crystals, sell 60 energy, and buy 2 upgrades to complete three daily quests.
- [ ] Claim each completed quest exactly once.
- [ ] Claim the daily reward once; second attempt must not award more credits.

## Saving

- [ ] Publish a **private test** experience.
- [ ] In Experience Settings > Security, enable Studio API Services **on the private test experience only**.
- [ ] Collect credits and buy an upgrade, then Stop and Play again.
- [ ] Credits, energy, and upgrade levels persist.
- [ ] Quest reward claim state persists when rejoining during the same UTC day.
- [ ] Force a DataStore **load** failure in a safe test environment and verify that gameplay continues without overwriting the stored record. Do not attempt destructive tests against a live game.

## Multiplayer and security

- [ ] Use Test > Start Test Session > Server & Clients with two players.
- [ ] Both players have independent credits, upgrades, and quests.
- [ ] One player collecting a crystal makes the crystal temporarily unavailable to both players.
- [ ] Attempt repeated or invalid `buy`/`quest` actions; no free credits or upgrades appear.
- [ ] Use an invalid string as upgrade ID; nothing is awarded and the server does not crash.
- [ ] Trigger a prompt from excessive distance in an isolated test; no rewards are awarded.

## Mobile and usability

- [ ] Use Test > Device Simulator to test a phone width.
- [ ] The MENU button, HUD, and modal remain usable without horizontal overflow.
- [ ] All four tabs display clearly on mobile.
- [ ] Claim and purchase buttons are reachable and readable.
- [ ] A ProximityPrompt is usable with touch input.
- [ ] Press M on desktop to open/close the menu.

## Record outcomes

Use the following for each failure:

```text
Date / Studio version:
Test scenario:
Expected:
Observed:
Output errors:
Screenshot or recording:
```

Open an issue on GitHub with reproducible evidence. Never claim to have run a test you haven't performed.
