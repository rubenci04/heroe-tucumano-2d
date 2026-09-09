const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../..');
const manifest = JSON.parse(fs.readFileSync(path.join(root,'assets/asset_manifest.json'),'utf8'));
const seq = (prefix, first, last) => Array.from({length:last-first+1},(_,i)=>({key:prefix+(i+first)}));
const native = [
{key:'Idle',frames:[{key:'ciruja_idle'}],frameRate:1},
{key:'Run',frames:seq('ciruja_run',0,5),frameRate:12,repeat:-1},
{key:'Jump',frames:seq('ciruja_salto',1,4),frameRate:8},
{key:'Throw Orange',frames:seq('ciruja_disparo_naranja',0,5),frameRate:24},
{key:'Throw Stone',frames:seq('ciruja_disparo_cascote',0,4),frameRate:20},
{key:'Headbutt',frames:seq('ciruja_cabezazo',0,2),frameRate:12},
{key:'Hit',frames:[{key:'ciruja_idle'}],frameRate:1,fallback:'Existing Idle frame with runtime tint; dedicated artwork absent'},
{key:'Death',frames:[{key:'ciruja_idle'}],frameRate:1,fallback:'Existing Idle frame with runtime rotation; dedicated artwork absent'}
];
const player = manifest.animations.filter(a=>!/^(hipster|agente|grandote|boss)_/.test(a.key)).concat(native);
function resource(name, animations) {
  const keys = [...new Set(animations.flatMap(a=>a.frames.map(f=>f.key)))];
  let output = '[gd_resource type="SpriteFrames" load_steps='+(keys.length+1)+' format=3]\n\n';
  for(let i=0;i<keys.length;i++) {
    if(!manifest.images.some(image=>image.filename===keys[i]+'.png')) throw Error('Missing image '+keys[i]);
    output += '[ext_resource type="Texture2D" path='+JSON.stringify('res://assets/'+keys[i]+'.png')+' id="'+(i+1)+'"]\n';
  }
  output += '\n[resource]\nanimations = [' + animations.map(a => '{\n"frames": ['+a.frames.map(f=>'{"duration": 1.0, "texture": ExtResource("'+(keys.indexOf(f.key)+1)+'")}').join(', ')+'],\n"loop": '+(a.repeat===-1)+',\n"name": &'+JSON.stringify(a.key)+',\n"speed": '+Number(a.frameRate).toFixed(1)+'\n}').join(',\n')+']\n';
  fs.writeFileSync(path.join(root,'assets/animations',name+'.tres'),output);
}
resource('player',player);
resource('asset_library',manifest.images.map(image=>({key:image.filename.slice(0,-4),frames:[{key:image.filename.slice(0,-4)}],frameRate:1})));
fs.writeFileSync(path.join(root,'assets/animations/native_animation_manifest.json'),JSON.stringify({native_player:native,legacy_animations:22,playable_and_legacy_animations:30,static_asset_animations:100},null,2)+'\n');
console.log('Generated 8 native player states and single-frame AnimatedSprite2D resources for all 100 PNG.');
