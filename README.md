# Snacktopia: Fuse-a-Brainrot

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/alchemist199/makefun-roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/alchemist199/makefun-roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

A 3D Roblox brainrot game for make.fun's roblox-brainrot-01 bounty. Catch absurd snack-creatures, carry them home, fuse them into rarer hybrids.

## How it plays

1. Catch: walk to the Wild Meadow and buy a roaming brainrot by holding E. Each has a price, a rarity, and a money rate, from the Common Soggy Cereal Knight at $2/s to the Legendary Grand Noodle at $60/s.
2. Carry: at most two at once, run them home.
3. Place: put them on your base by holding E on your pad. Each placed brainrot pays its rate every second, forever.
4. Fuse: carry any two to the Fusion Kitchen cauldron and fuse them into a Mythic hybrid that never roams the meadow: DJ Soggy Beats $50/s, Boba Pickle Baron $90/s, Couch Noodle Supreme $75/s. Fusing also frees base slots.
5. Run home: about every 100 seconds a Crumb Goblin wave sweeps in. Goblins steal carried brainrots on touch and raid bases whose owner is away. Standing on your own base scares them off.

Goal: fuse all three hybrids and become Snacktopia Master.

## Build

Rojo first. This machine is Linux; Roblox Studio is only used to publish and take screenshots.

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

`main.ts` hands the game in: it copies `game.rbxl`, `src/`, `screenshots/`, and `PLAY.json` to the output directory and writes `dossier.json` with the vendored library.

## Publish

Publish `game.rbxl` from Roblox Studio as a Public experience, put the make.fun play code in its description, fill in `PLAY.json` with its place id and universe id, upload an icon (512x512) and a thumbnail (one of the screenshots) on the Creator Dashboard, and wait until Roblox's review shows both on the experience page.

## Layout

- `src/server/Catalog.luau`: brainrots plus fusion recipes.
- `src/server/PlayerData.luau`: money, carried and placed brainrots, HUD attributes.
- `src/server/Spawner.luau`: wild brainrots.
- `src/server/Fusion.luau`: the Fusion Kitchen.
- `src/server/Waves.luau`: Crumb Goblin waves.
- `src/server/Main.server.luau`: bases, placing, income tick.
- `src/client/Hud.luau`: money, income, wave clock, goal, carrying.
- `src/client/Main.client.luau`: reads the server's player attributes and draws them.
- `default.project.json`: the Snacktopia island, four coloured bases, the Wild Meadow, the Fusion Kitchen, the Snack Fountain, the pond, and the giant snacks, all bright enough to read at thumbnail size.
- `vendor/makefun-roblox.ts`: the kit's vendored dossier builder, unchanged.
