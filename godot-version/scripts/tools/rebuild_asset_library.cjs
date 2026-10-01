const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '../..');
const manifestPath = path.join(root, 'assets/asset_manifest.json');
const libraryPath = path.join(root, 'assets/animations/asset_library.tres');
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8').replace(/^\uFEFF/, ''));
const missing = [];

manifest.images = manifest.images.filter(item => {
  const present = fs.existsSync(path.join(root, 'assets', item.filename));
  if (!present) missing.push(item.filename);
  return present;
});

const external = manifest.images.map((item, index) =>
  `[ext_resource type="Texture2D" path="${item.path}" id="${index + 1}"]`
).join('\n');
const animations = manifest.images.map((item, index) => {
  const animationName = path.parse(item.filename).name.replaceAll('"', '\\"');
  return `{
"frames": [{"duration": 1.0, "texture": ExtResource("${index + 1}")}],
"loop": false,
"name": &"${animationName}",
"speed": 1.0
}`;
}).join(',\n');
const library = `[gd_resource type="SpriteFrames" load_steps=${manifest.images.length + 1} format=3]\n\n${external}\n\n[resource]\nanimations = [${animations}]\n`;

fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2) + '\n');
fs.writeFileSync(libraryPath, library);
console.log(JSON.stringify({images: manifest.images.length, removed_missing_references: missing}));
