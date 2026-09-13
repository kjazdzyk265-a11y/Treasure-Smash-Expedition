# Treasure Smash Expedition

Roblox simulator/adventure built with **Luau + Rojo**. The project is server-authoritative for progression/economy actions and uses generated world content so the repository can build a playable place without external Roblox asset IDs.

## V1 systems currently implemented

- 6 generated zones: Green Valley, Construction City, Crystal Caverns, Magma Forge, Sky Ruins, Void Kingdom
- 54+ breakable definitions, material classes, respawn, rare Golden/Crystal/Void/Secret variants
- 6 zone bosses with multi-part models, world HP bars and damage phases
- server-authoritative smash validation, critical hits, Perfect Smash and combo multipliers
- backpack -> Sell Pad -> Coins economy loop
- 20 tools with progression stats and procedural in-hand visual models/trails
- 36 pets, Eggs, inventory, Equip Best, Lock/Delete, Index, Shiny/Rainbow fusion
- client-side 3D pet follow formations driven only by server-approved EquippedPets state
- upgrade tree: Damage, Attack Speed, Range, Movement Speed, Luck, Crit, Coin Gain, Backpack, Pet Slots
- Rebirth + Gems + permanent multiplier
- quests, achievements, Collection Index, 7-day daily rewards
- shared Giant Meteor contribution event
- onboarding flow through first smash, upgrade, Stone Mallet, Egg, rare object and Zone 2
- PC/touch raycast input and large simulator-style UI
- DataStore load/save, 75-second autosave, PlayerRemoving and BindToClose saves

## Toolchain

The repository pins **Rojo 7.7.0** in `rokit.toml`.

With Rokit installed:

```bash
rokit install
rojo --version
```

Alternatively install Rojo 7.7.0 manually.

## Build a place file

From the repository root:

```bash
rojo build default.project.json -o TreasureSmashExpedition.rbxlx
```

Open `TreasureSmashExpedition.rbxlx` in Roblox Studio.

For live sync:

```bash
rojo serve default.project.json
```

Then connect the Rojo Studio plugin to the local server.

## Studio setup notes

For local DataStore testing, enable **Game Settings -> Security -> Enable Studio Access to API Services** only in an appropriate test experience. The game falls back to defaults when loading fails, but persistent-save behavior cannot be verified without API access.

No third-party Roblox models or guessed Asset IDs are required by the current V1 source. Tool, pet and boss visuals are assembled from Roblox primitives at runtime.

## Architecture

```text
src/shared   shared configs and catalogs
src/server   authoritative gameplay/economy/data services
src/client   HUD, input, VFX and local-only cosmetic models
```

Important authority boundary: the client does **not** decide damage, Coins, Gems, hatch results, equipped-pet power, zone unlocks, boss rewards, Rebirth success, Perfect Smash or Meteor contribution.

## Release verification

Before publishing, run the checklist in [`docs/SMOKE_TEST.md`](docs/SMOKE_TEST.md). Static implementation is present, but Roblox Studio runtime verification is still required before calling a build release-ready.

Balance targets and current tuning assumptions are documented in [`docs/BALANCING.md`](docs/BALANCING.md).
