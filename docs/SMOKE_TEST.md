# V1 Smoke Test Checklist

Run this checklist in Roblox Studio after building/syncing the project. Treat any Output error as a release blocker until understood.

## Boot and persistence

- [ ] Place starts without red errors in Output.
- [ ] Player receives Coins, Power, Gems and Rebirths leaderstats.
- [ ] Existing save loads when Studio API access is enabled.
- [ ] Autosave runs without DataStore exceptions.
- [ ] Leaving/rejoining preserves Coins, Power, Gems, Rebirths, ToolIndex, zones, upgrades, pets, equipped pets, index, quests, achievements and daily streak.

## Core smash loop

- [ ] Mouse click hits a breakable on PC.
- [ ] Touch input hits a breakable on mobile emulator/device.
- [ ] Out-of-range targets do no damage.
- [ ] Locked-zone targets do no damage.
- [ ] Cooldown spam does not bypass AttackSpeed.
- [ ] Damage numbers, HP feedback, wobble/FOV feedback and tool swing appear.
- [ ] Critical hits visibly differ.
- [ ] Perfect Smash cue can succeed inside the timing window and cannot be forced by a client flag.
- [ ] Combo increases and resets after inactivity.

## Backpack and economy

- [ ] Destroyed objects add loot to Backpack, not Coins directly.
- [ ] Backpack stops at capacity and shows FULL feedback.
- [ ] Sell Pad converts loot to Coins and clears Backpack.
- [ ] CoinGain/Rebirth multipliers affect sell payout.
- [ ] BackpackSlots increases capacity.

## Progression and zones

- [ ] All 20 tool purchases advance one step only and deduct server-side Coins.
- [ ] Tool visual changes after purchase and after respawn.
- [ ] All 9 upgrade buttons deduct the correct cost.
- [ ] MovementSpeed changes Humanoid WalkSpeed.
- [ ] Zone gates reject insufficient funds/locked progression.
- [ ] Checkpoints update CurrentZone.
- [ ] Boss defeat advances progression as intended.
- [ ] All 6 zones are reachable.

## Eggs and pets

- [ ] Every physical Egg Station prompt opens the correct zone Egg.
- [ ] Green/City/Crystal/Magma/Sky/Void Egg IDs match EggConfig.
- [ ] Hatch result is server-selected and price is deducted once.
- [ ] 36 pet entries can appear in Index.
- [ ] Equip/unequip and Equip Best work.
- [ ] Equip limit respects PetSlots.
- [ ] Lock prevents delete/fusion use.
- [ ] 5 Normal -> 1 Shiny and 5 Shiny -> 1 Rainbow.
- [ ] Shiny/Rainbow multipliers affect damage.
- [ ] Equipped pets render as 3D followers; unequipped pets disappear.
- [ ] Rainbow visual animation is cosmetic only.

## Breakables and bosses

- [ ] Normal breakables respawn.
- [ ] Golden, Crystal, Void and Secret variants are visually distinct.
- [ ] Variant reward/HP multipliers apply server-side.
- [ ] Each zone boss has a multi-part model and world HP bar.
- [ ] Boss bar changes at 50% and 25% HP.
- [ ] Boss death/respawn does not leave invisible collision parts.

## Retention systems

- [ ] Smash, Perfect, Hatch, Boss, Zone and Rebirth actions advance relevant quests/achievements.
- [ ] Quest rewards can be claimed once.
- [ ] Daily reward can be claimed once per UTC day.
- [ ] Daily streak advances/resets correctly across dates.
- [ ] Collection Index shows /36, not /0.

## Rebirth

- [ ] Rebirth rejects player before requirement + Zone 6.
- [ ] Successful Rebirth grants Gems.
- [ ] Coins, Power, ToolIndex, zones, Backpack and upgrades reset.
- [ ] Pets, equipped pets, Gems and Index remain.
- [ ] Permanent multiplier increases derived stats after reset/respawn.

## Global Meteor

- [ ] Meteor appears on schedule in a live server test.
- [ ] Multiple players can damage the same meteor.
- [ ] Contribution is based on validated server damage.
- [ ] 35%+ contribution grants 5 Gems.
- [ ] 15%+ contribution grants 3 Gems.
- [ ] Other active contributors grant 1 Gem.
- [ ] Non-participants receive no reward.

## Onboarding/UI

- [ ] New account sees first-smash instruction.
- [ ] Tutorial advances through upgrade, second tool, first Egg, rare object and Zone 2.
- [ ] Existing progressed account does not get stuck on impossible earlier steps.
- [ ] Shop, Pets, Quests, Rebirth and event UI do not overlap at common phone/tablet/desktop resolutions.

## Performance sanity

- [ ] No rapidly growing Instance count while idle for 10 minutes.
- [ ] Pet visual folders clean up when pets are unequipped/player leaves.
- [ ] Repeated breakable respawns do not duplicate tags, prompts or event connections.
- [ ] Server remains responsive with 2+ Studio test players smashing simultaneously.
