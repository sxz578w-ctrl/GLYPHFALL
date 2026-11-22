const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const { spawnSync } = require('node:child_process');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..');
const htmlPath = path.join(root, 'app/src/main/assets/index.html');
const html = fs.readFileSync(htmlPath, 'utf8');

assert.ok(html.startsWith('<!DOCTYPE html>'), 'game asset must be a complete HTML document');
assert.match(html, /<html lang="ar" dir="rtl">/, 'Arabic RTL document metadata must remain');
assert.match(html, /three@0\.160\.0/, 'Three.js must remain pinned to a tested version');
assert.match(html, /three\/addons\//, 'Three.js addon import map must remain configured');
assert.match(html, /camDist = PT\(\) \? 15\.5 : 24\.0/, 'landscape camera must keep the selected distance');
assert.match(html, /data-hero="vanguard"[\s\S]*data-hero="phantom"[\s\S]*data-hero="bastion"/, 'all three playable classes must be available');
assert.match(html, /id="btn-fire"[\s\S]*id="btn-sword"[\s\S]*id="btn-shield"[\s\S]*id="btn-dash"/, 'mobile melee control set must remain in HTML');
assert.match(html, /id="settings-screen"/, 'settings screen must remain available');
assert.match(html, /id="pause-screen"/, 'pause screen must remain available');
assert.ok(html.includes('</body>') && html.includes('</html>'), 'HTML closing tags must exist');

const moduleMatch = html.match(/<script\s+type="module">([\s\S]*?)<\/script>/i);
assert.ok(moduleMatch, 'main ES module must exist');
const tempModule = path.join(os.tmpdir(), `glyphfall-check-${process.pid}.mjs`);
try {
  fs.writeFileSync(tempModule, moduleMatch[1]);
  const check = spawnSync(process.execPath, ['--check', tempModule], { encoding: 'utf8' });
  assert.equal(check.status, 0, `main JavaScript module syntax error:\n${check.stderr || check.stdout}`);
} finally {
  fs.rmSync(tempModule, { force: true });
}

const manifest = fs.readFileSync(path.join(root, 'app/src/main/AndroidManifest.xml'), 'utf8');
assert.match(manifest, /android:screenOrientation="landscape"/, 'APK must lock orientation to landscape');
assert.match(manifest, /android\.permission\.INTERNET/, 'network permission required for the pinned Three.js CDN');
console.log(`GLYPHFALL asset verification passed (${html.length.toLocaleString()} HTML characters).`);
