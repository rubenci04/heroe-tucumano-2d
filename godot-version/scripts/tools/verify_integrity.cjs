const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');

const root = path.resolve(__dirname, '../..');
const baselinePath = path.join(root, 'validation/asset_baseline_v2.json');
const manifestPath = path.join(root, 'assets/asset_manifest.json');
const hash = file => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const slash = value => value.split(path.sep).join('/');

function listPngs(folder) {
  const result = [];
  for (const entry of fs.readdirSync(folder, { withFileTypes: true })) {
    const target = path.join(folder, entry.name);
    if (entry.isDirectory()) result.push(...listPngs(target));
    else if (entry.isFile() && entry.name.toLowerCase().endsWith('.png')) result.push(target);
  }
  return result;
}

if (process.argv.includes('--write-v2')) {
  const assets = listPngs(path.join(root, 'assets'))
    .map(file => ({ path: slash(path.relative(root, file)), sha256: hash(file) }))
    .sort((a, b) => a.path.localeCompare(b.path));
  const baseline = {
    version: 'Asset Baseline V2',
    approved: true,
    generated_on: '2026-09-21',
    scope: 'PNG assets present in the validated Godot project after the controlled asset rebuild',
    asset_count: assets.length,
    assets
  };
  fs.writeFileSync(baselinePath, JSON.stringify(baseline, null, 2) + '\n');
}

if (!fs.existsSync(baselinePath)) {
  console.error(JSON.stringify({ passed: false, baseline: 'Asset Baseline V2', errors: ['Missing validation/asset_baseline_v2.json'] }));
  process.exit(1);
}

const baseline = JSON.parse(fs.readFileSync(baselinePath, 'utf8').replace(/^\uFEFF/, ''));
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8').replace(/^\uFEFF/, ''));
const errors = [];
const expected = new Set(baseline.assets.map(item => item.path));

for (const item of baseline.assets) {
  const target = path.join(root, item.path);
  if (!fs.existsSync(target)) errors.push('Missing V2 asset: ' + item.path);
  else if (hash(target).toLowerCase() !== item.sha256.toLowerCase()) errors.push('Asset V2 mismatch: ' + item.path);
}
for (const file of listPngs(path.join(root, 'assets'))) {
  const relative = slash(path.relative(root, file));
  if (!expected.has(relative)) errors.push('PNG not registered in V2: ' + relative);
}
if (!manifest.images.length) errors.push('Asset gallery manifest is empty');
for (const item of manifest.images) {
  if (!fs.existsSync(path.join(root, 'assets', item.filename))) errors.push('Gallery asset missing: ' + item.filename);
}
for (const effect of Object.keys(JSON.parse(fs.readFileSync(path.join(root, 'audio/source/sfx_recipes.json'), 'utf8')))) {
  const wav = fs.readFileSync(path.join(root, 'audio', effect + '.wav'));
  if (wav.toString('ascii', 0, 4) !== 'RIFF' || wav.length < 46) errors.push('Invalid WAV: ' + effect);
}

const result = {
  passed: errors.length === 0,
  baseline: baseline.version,
  assets_checked: baseline.assets.length,
  gallery_images_checked: manifest.images.length,
  errors
};
fs.writeFileSync(path.join(root, 'validation/integrity_results.json'), JSON.stringify(result, null, 2) + '\n');
console.log(JSON.stringify(result));
if (errors.length) process.exitCode = 1;
