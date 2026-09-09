const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '../..');
const hash = file => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const baseline = JSON.parse(fs.readFileSync(path.join(root, 'validation/original_hashes.json'), 'utf8').replace(/^\uFEFF/, ''));
const manifest = JSON.parse(fs.readFileSync(path.join(root, 'assets/asset_manifest.json'), 'utf8'));
const errors = [];
for (const item of baseline) {
  const target = path.resolve(root, '..', item.path);
  if (hash(target).toLowerCase() !== item.sha256.toLowerCase()) errors.push('Original changed: ' + item.path);
}
for (const item of manifest.images) {
  if (hash(path.join(root, 'assets', item.filename)) !== item.sha256) errors.push('Asset mismatch: ' + item.filename);
}
if (manifest.images.length !== 100) errors.push('Expected original inventory of 100 PNG');
for (const effect of Object.keys(JSON.parse(fs.readFileSync(path.join(root, 'audio/source/sfx_recipes.json'), 'utf8')))) {
  const wav = fs.readFileSync(path.join(root, 'audio', effect + '.wav'));
  if (wav.toString('ascii', 0, 4) !== 'RIFF' || wav.length < 46) errors.push('Invalid WAV: ' + effect);
}
const result = { passed: errors.length === 0, originals_checked: baseline.length, copied_images_checked: manifest.images.length, errors };
fs.writeFileSync(path.join(root, 'validation/integrity_results.json'), JSON.stringify(result, null, 2) + '\n');
console.log(JSON.stringify(result));
if (errors.length) process.exitCode = 1;
