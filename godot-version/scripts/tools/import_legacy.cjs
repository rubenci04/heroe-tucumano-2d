/* Run with Node.js: node scripts/tools/import_legacy.cjs
 * Reads the parent HTML project; writes only inside this Godot project.
 * No npm packages or browser required.
 */
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const vm = require('node:vm');
const root = path.resolve(__dirname, '../..');
const legacy = path.resolve(root, '..');
const digest = data => crypto.createHash('sha256').update(data).digest('hex');
function write(relative, data) {
  const target = path.resolve(root, relative);
  if (!target.startsWith(root + path.sep)) throw Error('Output escapes godot-version');
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, data);
}
const source = fs.readFileSync(path.join(legacy, 'main.js'), 'utf8');
const imageNames = fs.readdirSync(path.join(legacy, 'assets')).filter(n => /\.png$/i.test(n)).sort();
const animationRegion = source.slice(source.indexOf("if (!this.anims.exists('correr'))"), source.indexOf('// JUGADOR Y GRUPOS FÍSICOS'));
const animations = [...animationRegion.matchAll(/this\.anims\.create\((\{[\s\S]*?\})\);/g)]
  .map(match => vm.runInNewContext('(' + match[1] + ')', Object.create(null), { timeout: 1000 }));
if (animations.length !== 22) throw Error('Legacy animation structure changed: review importer before continuing');
const declaredImages = new Set([...source.matchAll(/this\.load\.image\('[^']+', 'assets\/([^']+)'\)/g)].map(m => m[1]));
for (const name of imageNames) if (/^(juntar_(naranjas|cascote)\d|ciruja_cabezazo\d)\.png$/.test(name)) declaredImages.add(name);
const assetRecords = [];
for (const name of imageNames) {
  const bytes = fs.readFileSync(path.join(legacy, 'assets', name));
  write('assets/' + name, bytes);
  assetRecords.push({
    filename: name, path: 'res://assets/' + name,
    source: 'assets/' + name, bytes: bytes.length,
    width: bytes.readUInt32BE(16), height: bytes.readUInt32BE(20),
    sha256: digest(bytes), loaded_by_legacy: declaredImages.has(name),
    animations: animations.filter(a => a.frames.some(f => f.key + '.png' === name)).map(a => a.key)
  });
}
const groups = {
  player: animations.filter(a => !/^(hipster|agente|grandote|boss)_/.test(a.key)),
  hipster: animations.filter(a => a.key.startsWith('hipster_')),
  agente: animations.filter(a => a.key.startsWith('agente_')),
  grandote: animations.filter(a => a.key.startsWith('grandote_')),
  boss: animations.filter(a => a.key.startsWith('boss_'))
};
for (const [group, definitions] of Object.entries(groups)) {
  const textures = [...new Set(definitions.flatMap(a => a.frames.map(f => f.key)))];
  let text = '[gd_resource type="SpriteFrames" load_steps=' + (textures.length + 1) + ' format=3]\n\n';
  textures.forEach((key, index) => {
    if (!imageNames.includes(key + '.png')) throw Error('Missing animation texture ' + key);
    text += '[ext_resource type="Texture2D" path="res://assets/' + key + '.png" id="' + (index + 1) + '"]\n';
  });
  text += '\n[resource]\nanimations = [';
  text += definitions.map(a => '{\n"frames": [' + a.frames.map(f => '{"duration": 1.0, "texture": ExtResource("' + (textures.indexOf(f.key) + 1) + '")}').join(', ') +
    '],\n"loop": ' + (a.repeat === -1) + ',\n"name": &' + JSON.stringify(a.key) + ',\n"speed": ' + Number(a.frameRate).toFixed(1) + '\n}').join(',\n');
  write('assets/animations/' + group + '.tres', text + ']\n');
}
write('assets/asset_manifest.json', JSON.stringify({ source_main_sha256: digest(Buffer.from(source)), images: assetRecords, animations }, null, 2) + '\n');

// Preserve the actual legacy synthesis definitions and capture their automation events.
const audioSource = source.slice(source.indexOf('const AudioSFX ='), source.indexOf('const config ='));
write('audio/source/audio_sfx_original.js', audioSource);
const effects = ['salto','disparo_naranja','disparo_cascote','empanada','achilata','sanguche','golpe','danio','victoria','cabezazo','alerta'];
const recipes = {};
function parameter() {
  return {
    events: [],
    setValueAtTime(value, time) { this.events.push({ type: 'set', value, time }); },
    linearRampToValueAtTime(value, time) { this.events.push({ type: 'linear', value, time }); },
    exponentialRampToValueAtTime(value, time) { this.events.push({ type: 'exponential', value, time }); }
  };
}
function sampleAutomation(events, t) {
  let previous = events[0];
  for (let i = 1; i < events.length; i++) {
    const next = events[i];
    if (t < next.time) {
      if (next.type === 'set') return previous.value;
      const factor = (t - previous.time) / (next.time - previous.time);
      return next.type === 'linear'
        ? previous.value + factor * (next.value - previous.value)
        : previous.value * Math.pow(next.value / previous.value, factor);
    }
    previous = next;
  }
  return previous.value;
}
for (const effect of effects) {
  let oscillator, gain;
  const context = {
    currentTime: 0, destination: {},
    createOscillator() {
      oscillator = { type: 'sine', frequency: parameter(), connect() {}, start(t) { this.startTime = t; }, stop(t) { this.stopTime = t; } };
      return oscillator;
    },
    createGain() { gain = { gain: parameter(), connect() {} }; return gain; }
  };
  vm.runInNewContext(audioSource + '\nAudioSFX.ctx = context; AudioSFX.play(effect);', { context, effect }, { timeout: 1000 });
  if (!oscillator || !oscillator.stopTime) throw Error('No synthesized audio for ' + effect);
  const recipe = { waveform: oscillator.type, duration: oscillator.stopTime, frequency: oscillator.frequency.events, gain: gain.gain.events };
  recipes[effect] = recipe;
  const rate = 44100;
  const count = Math.ceil(rate * recipe.duration);
  const wav = Buffer.alloc(44 + count * 2);
  wav.write('RIFF'); wav.writeUInt32LE(wav.length - 8, 4); wav.write('WAVEfmt ', 8);
  wav.writeUInt32LE(16, 16); wav.writeUInt16LE(1, 20); wav.writeUInt16LE(1, 22);
  wav.writeUInt32LE(rate, 24); wav.writeUInt32LE(rate * 2, 28); wav.writeUInt16LE(2, 32); wav.writeUInt16LE(16, 34);
  wav.write('data', 36); wav.writeUInt32LE(count * 2, 40);
  let phase = 0;
  for (let i = 0; i < count; i++) {
    const t = i / rate;
    const frequency = sampleAutomation(recipe.frequency, t);
    let wave = 0;
    if (recipe.waveform === 'sine') wave = Math.sin(phase);
    else {
      const harmonics = Math.min(63, Math.floor(rate * 0.45 / frequency));
      for (let harmonic = 1; harmonic <= harmonics; harmonic++) {
        if (recipe.waveform === 'square' && harmonic % 2) wave += 4 / Math.PI * Math.sin(harmonic * phase) / harmonic;
        if (recipe.waveform === 'sawtooth') wave += 2 / Math.PI * (harmonic % 2 ? 1 : -1) * Math.sin(harmonic * phase) / harmonic;
        if (recipe.waveform === 'triangle' && harmonic % 2) wave += 8 / (Math.PI * Math.PI) * (harmonic % 4 === 1 ? 1 : -1) * Math.sin(harmonic * phase) / (harmonic * harmonic);
      }
    }
    const fade = Math.min(1, i / (rate * 0.001), (count - 1 - i) / (rate * 0.003));
    const value = Math.max(-1, Math.min(1, wave * sampleAutomation(recipe.gain, t) * fade));
    wav.writeInt16LE(Math.round(value * 32767), 44 + i * 2);
    phase = (phase + 2 * Math.PI * frequency / rate) % (2 * Math.PI);
  }
  write('audio/' + effect + '.wav', wav);
}
write('audio/source/sfx_recipes.json', JSON.stringify(recipes, null, 2) + '\n');
const duplicateGroups = Object.values(Object.groupBy(assetRecords, a => a.sha256)).filter(g => g.length > 1).map(g => g.map(a => a.filename));
write('validation/import_results.json', JSON.stringify({
  images: assetRecords.length, legacy_loaded: assetRecords.filter(a => a.loaded_by_legacy).length,
  legacy_unused: assetRecords.filter(a => !a.loaded_by_legacy).map(a => a.filename),
  animation_resources: Object.keys(groups).length, animations: animations.length,
  audio_effects: effects.length, duplicate_groups: duplicateGroups,
  note: 'WAV synthesized from captured legacy parameters; band-limited Fourier approximation, not bit-exact browser audio.'
}, null, 2) + '\n');
console.log(JSON.stringify({ images: assetRecords.length, animations: animations.length, audio: effects.length }));

require('./build_native_animations.cjs');
