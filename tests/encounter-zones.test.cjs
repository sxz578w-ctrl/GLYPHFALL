const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const path = require('node:path');
const source = fs.readFileSync(path.resolve(__dirname, '../app/src/main/assets/index.html'), 'utf8');

function extractFunction(name) {
  const start = source.indexOf(`function ${name}(`);
  assert.notEqual(start, -1, `Missing ${name} implementation`);
  const brace = source.indexOf('{', start);
  let depth = 0;
  for (let i = brace; i < source.length; i++) {
    if (source[i] === '{') depth++;
    if (source[i] === '}' && --depth === 0) return source.slice(start, i + 1);
  }
  throw new Error(`Unclosed function: ${name}`);
}

const isWithinEncounterZone = extractFunction('isWithinEncounterZone');
const shouldEnemyEngagePlayer = extractFunction('shouldEnemyEngagePlayer');
const fireProjectile = extractFunction('fireProjectile');
const context = {};
vm.runInNewContext(`${isWithinEncounterZone}\n${shouldEnemyEngagePlayer}\nglobalThis.api = { isWithinEncounterZone, shouldEnemyEngagePlayer };`, context);
const api = context.api;

const site = { x: 100, z: -50, radius: 24 };
assert.equal(api.isWithinEncounterZone(100, -50, site), true, 'player at encounter center');
assert.equal(api.isWithinEncounterZone(124, -50, site), true, 'player on encounter boundary');
assert.equal(api.isWithinEncounterZone(125, -50, site), false, 'player outside encounter boundary');
assert.equal(api.shouldEnemyEngagePlayer({ x: 104, z: -50, site, aggroRange: 18 }, 121, -50), true, 'enemy engages nearby player inside its site');
assert.equal(api.shouldEnemyEngagePlayer({ x: 104, z: -50, site, aggroRange: 18 }, 123, -50), false, 'enemy does not engage outside its aggro radius');
assert.equal(api.shouldEnemyEngagePlayer({ x: 104, z: -50, site, aggroRange: 18 }, 125, -50), false, 'enemy never pursues player beyond its site');
assert.equal(api.shouldEnemyEngagePlayer({ x: 104, z: -50, aggroRange: 18 }, 105, -50), false, 'unbound enemy cannot chase outside a declared site');

assert.match(fireProjectile, /attackLight\(\)/, 'legacy fire action is redirected to melee');
assert.doesNotMatch(fireProjectile, /projectiles\.push|new THREE\.Mesh/, 'player action must not create a ranged projectile');
assert.match(source, /camDist = PT\(\) \? 15\.5 : 24\.0/, 'landscape camera is slightly closer');
assert.match(source, /const canEngage = !isSafe && shouldEnemyEngagePlayer/, 'safe haven suppresses hostile engagement');
assert.match(source, /if \(!forced \|\| !site \|\| enemies\.length >= 28 \|\| bossSpawned\) return false/, 'hostile spawns require a named encounter site');
assert.match(source, /data-hero="vanguard"[\s\S]*data-hero="phantom"[\s\S]*data-hero="bastion"/, 'menu exposes three character classes');
for (const hero of ['vanguard', 'phantom', 'bastion']) {
  assert.match(source, new RegExp(`${hero}:\\s*\\{[^}]*weapon:`), `${hero} has a dedicated melee weapon`);
  assert.match(source, new RegExp(`${hero}:\\s*\\{[^}]*ability:`), `${hero} has a dedicated skill`);
}
assert.match(source, /function castAnomalyBolt/, 'monster ranged pressure is represented as anomaly magic');
assert.doesNotMatch(source, /'ranged'/, 'no ranged-gun enemy class remains');
console.log('GLYPHFALL world/combat tests passed.');
