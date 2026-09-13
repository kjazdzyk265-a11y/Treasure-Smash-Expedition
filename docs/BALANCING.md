# V1 Balancing Report

This report documents the intended V1 progression curve and the current static tuning. It is not a substitute for a timed Roblox Studio playtest.

## Target pacing

- first reward: within seconds
- first upgrade: 1-2 minutes
- Stone Mallet: 3-4 minutes
- first Egg: 4-6 minutes
- Zone 2: 8-12 minutes
- Zone 3: 20-25 minutes
- first Rebirth: 35-45 minutes

## Current economy anchors

### Tools

| Tool milestone | Price | Damage | Cumulative tool spend |
| --- | ---: | ---: | ---: |
| Stone Mallet | 120 | 8 | 120 |
| Iron Hammer | 420 | 13 | 540 |
| Steel Sledge | 1,200 | 21 | 1,740 |
| Crystal Maul | 8,200 | 55 | 13,140 |
| Celestial Crusher | 300,000 | 360 | 511,140 |
| Eternal Worldbreaker | 1,750,000,000 | 40,000 | 2,985,431,140 |

Tool damage and prices are exponential by design; later progression is additionally accelerated by pets, combo, upgrades and Rebirth multipliers.

### Zone gates

| Zone | Unlock cost |
| --- | ---: |
| Construction City | 600 |
| Crystal Caverns | 7,000 |
| Magma Forge | 85,000 |
| Sky Ruins | 900,000 |
| Void Kingdom | 8,500,000 |

### Eggs

| Egg | Price |
| --- | ---: |
| Green Egg | 120 |
| City Egg | 850 |
| Crystal Egg | 5,200 |
| Magma Egg | 32,000 |
| Sky Egg | 210,000 |
| Void Egg | 1,500,000 |

The first Green Egg intentionally competes with the Stone Mallet at the same 120-Coin price point, creating an early damage-vs-pet choice.

## Multipliers

- base crit chance: 8%
- crit multiplier: x2
- Perfect Smash: x1.5 damage
- combo reward tiers: x2 / x3 / x5 / x10 / x25
- Shiny pet: x2 pet power
- Rainbow pet: x5 pet power versus Normal
- Rebirth permanent multiplier: +22.5% per Rebirth
- Coin Gain upgrade: +8% per level before Rebirth multiplier
- Damage upgrade: +10% per level before Rebirth multiplier

Because combo currently multiplies object loot and Power on destruction, it is one of the strongest economy accelerators. During playtest, specifically watch whether x10/x25 chains trivialize zone costs or fill the Backpack too quickly.

## Backpack pressure

- starter capacity: 20
- BackpackSlots: +5 capacity per level
- loot is capped to remaining capacity
- selling applies CoinGain/Rebirth multipliers

This creates the intended expedition cadence: leave the Sell Pad, fill quickly, return, upgrade, then extend the trip through capacity and movement upgrades.

## Rebirth

Current requirement formula:

```text
750 * 1.85 ^ currentRebirths
```

A successful Rebirth additionally requires Zone 6. This means the first Rebirth is gated primarily by full-map completion, while subsequent Rebirths increase the Power requirement exponentially.

## Rare breakables

Configured rarity targets:

- Golden: ~3%
- Crystal: ~1%
- Void: ~0.2%
- Secret: ~0.05%

These need long-session validation because low probabilities cannot be meaningfully confirmed in a short smoke test.

## Global Meteor

Contribution rewards:

- 35%+ of validated damage: 5 Gems
- 15%+: 3 Gems
- any other active contributor: 1 Gem

This favors meaningful participation without making the event winner-take-all.

## Playtest decisions still required

The following cannot be responsibly finalized from static source alone:

1. exact minutes to each progression milestone;
2. whether combo causes runaway income;
3. whether Backpack capacity creates satisfying return-to-sell frequency;
4. whether boss HP feels substantial with 2-6 players;
5. whether first Rebirth lands inside the 35-45 minute target;
6. whether Egg prices compete fairly with tool/upgrade spending;
7. whether Meteor HP is suitable for expected server population.

Record a fresh-account timed playthrough and adjust only after observing the real loop. Prefer changing shared config values instead of introducing one-off multipliers in client code.
