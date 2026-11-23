const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');

const root = path.resolve(__dirname, '..');
const html = fs.readFileSync(path.join(root, 'app/src/main/assets/index.html'), 'utf8');
const menuArt = fs.readFileSync(path.join(root, 'app/src/main/assets/menu-world.svg'), 'utf8');
const icon = fs.readFileSync(path.join(root, 'app/src/main/res/drawable/ic_glyphfall.xml'), 'utf8');

assert.match(html, /function buildAAAArchitecture\(/, 'world must use detailed modular architecture');
assert.match(html, /function buildForestBiomes\(/, 'forest biomes must be generated as real 3D geometry');
assert.match(html, /renderer\.shadowMap\.enabled\s*=\s*true/, 'real-time shadows must be enabled');
assert.match(html, /THREE\.ACESFilmicToneMapping/, 'HDR scene must use filmic tone mapping');
assert.match(html, /THREE\.SRGBColorSpace/, 'renderer output must use sRGB');
assert.match(html, /qualityPresets\s*=\s*\{/, 'graphics quality must be driven by explicit presets');
assert.match(html, /ultra:\s*\{/, 'ultra quality preset must exist');
assert.match(html, /id="hero-detail-name"/, 'single character detail panel must update');
assert.match(html, /class="hero-showcase"/, 'class selector must provide one unified showcase');
assert.match(html, /class="hero-card[\s\S]*data-hero="vanguard"/, 'class roster contains Vanguard');
assert.match(html, /data-hero="phantom"/, 'class roster contains Phantom');
assert.match(html, /data-hero="bastion"/, 'class roster contains Bastion');
assert.match(html, /id="btn-sword"[\s\S]*data-skill="quick"/, 'quick melee action has semantic skill metadata');
assert.match(html, /data-skill="heavy"/, 'heavy melee action has semantic skill metadata');
assert.match(html, /data-skill="guard"/, 'defensive action has semantic skill metadata');
assert.match(html, /data-skill="evade"/, 'evade action has semantic skill metadata');
assert.match(html, /GLYPHFALL · AETHER EDITION/, 'new premium visual identity is present');
assert.match(html, /prefers-reduced-motion/, 'visual motion respects accessibility settings');

assert.match(menuArt, /<svg[\s\S]*viewBox="0 0 2048 1152"/, 'menu artwork is resolution-independent and widescreen');
assert.match(menuArt, /linearGradient/, 'menu artwork uses layered gradients');
assert.match(menuArt, /filter id="glow"/, 'menu artwork has a reusable glow treatment');
assert.match(icon, /#07111F/, 'Android app icon uses the new deep-space brand palette');
assert.match(icon, /#5DEBFF/, 'Android app icon uses the new cyan brand accent');

console.log('GLYPHFALL AAA visual-upgrade tests passed.');
