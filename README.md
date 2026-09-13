# Treasure Smash Expedition

Roblox simulator/adventure built with Luau + Rojo.

## Current vertical slice

- Rojo project structure (`src/server`, `src/client`, `src/shared`)
- Generated Green Valley starter zone
- Server-authoritative smash requests with cooldown + distance validation
- Breakable HP, rewards and respawn
- Critical hits calculated on the server
- Coins + Power leaderstats
- Basic DataStore load/save/autosave
- PC and touch raycast input
- First HUD and floating damage feedback

## Run locally

1. Install Rojo.
2. Run `rojo serve` from the repository root.
3. In Roblox Studio, connect the Rojo plugin to the local server and sync the place.
4. Press Play to test the vertical slice.

This is an implementation checkpoint, not V1. Runtime verification in Roblox Studio is still required before claiming the slice fully works.
