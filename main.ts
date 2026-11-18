// Snacktopia hand-in: copies the built place, the sources, the screenshots and
// the play link into the output directory, then writes the dossier the judge
// reads, using the vendored make.fun library. Node 22, standard library only.
//
// Run it outside the grader's container like this:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const repoRoot = fileURLToPath(new URL('.', import.meta.url));
const outputDir = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

// The grader refuses any output name that starts with a dot, so the tree
// copies below leave dotted files and folders out at every depth.
const keepVisible = (entryPath: string): boolean => !basename(entryPath).startsWith('.');

function fail(message: string): never {
  throw new Error(`Snacktopia hand-in failed: ${message}`);
}

const placeFile = join(repoRoot, 'game.rbxl');
if (!existsSync(placeFile)) {
  fail('game.rbxl is missing, build the place first with rojo build default.project.json --output game.rbxl');
}
if (statSync(placeFile).size === 0) {
  fail('game.rbxl is empty (0 bytes), rebuild the place with rojo build default.project.json --output game.rbxl');
}
const playFile = join(repoRoot, 'PLAY.json');
if (!existsSync(playFile)) {
  fail('PLAY.json is missing, fill it in with the published place id and universe id');
}

mkdirSync(outputDir, { recursive: true });
copyFileSync(placeFile, join(outputDir, 'game.rbxl'));
copyFileSync(playFile, join(outputDir, 'PLAY.json'));
cpSync(join(repoRoot, 'src'), join(outputDir, 'src'), { recursive: true, filter: keepVisible });
mkdirSync(join(outputDir, 'screenshots'), { recursive: true });
const shotsDir = join(repoRoot, 'screenshots');
if (!existsSync(shotsDir)) {
  fail('screenshots directory is missing, add 1 to 4 screenshots before handing the game in');
}
const shotCount = readdirSync(shotsDir).filter((name) => !name.startsWith('.')).length;
if (shotCount < 1 || shotCount > 4) {
  fail(`expected 1 to 4 screenshots, found ${shotCount}`);
}
cpSync(shotsDir, join(outputDir, 'screenshots'), { recursive: true, filter: keepVisible });

writeFileSync(
  join(outputDir, 'dossier.json'),
  buildDossier(outputDir, {
    text_max_bytes: 65536,
    screenshots: { max: 4, max_bytes: 262144 },
    max_instances: 500000,
    scripts_max_source_bytes: 8388608,
    scripts_max_path_chars: 1048576,
  }),
);
