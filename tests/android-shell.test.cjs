const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..');
const read = (p) => fs.readFileSync(path.join(root, p), 'utf8');

const manifest = read('app/src/main/AndroidManifest.xml');
const activity = read('app/src/main/java/com/glyphfall/game/MainActivity.java');
const gradle = read('app/build.gradle');
const workflow = read('.github/workflows/android-apk.yml');
const game = read('app/src/main/assets/index.html');

assert.match(manifest, /android:screenOrientation="landscape"/, 'Android activity must lock to landscape');
assert.match(manifest, /android\.permission\.INTERNET/, 'Internet permission is declared for pinned Three.js CDN');
assert.match(activity, /WebViewAssetLoader/, 'local game asset must be served through WebViewAssetLoader');
assert.match(activity, /https:\/\/appassets\.androidplatform\.net\/assets\/index\.html/, 'load local bundled game from secure appassets origin');
assert.match(activity, /setJavaScriptEnabled\(true\)/, '3D game JavaScript is enabled');
assert.match(activity, /setDomStorageEnabled\(true\)/, 'game save/settings localStorage is enabled');
assert.match(activity, /setAllowFileAccess\(false\)/, 'untrusted file:// access stays disabled');
assert.match(gradle, /com\.android\.application/);
assert.match(gradle, /minSdk\s*=?\s*24/);
assert.match(gradle, /androidx\.webkit:webkit:/, 'WebKit compatibility dependency is present');
assert.match(workflow, /:app:assembleDebug/, 'CI builds a debug APK');
assert.match(workflow, /upload-artifact/, 'CI publishes the APK as an artifact');
assert.match(game, /three@0\.160\.0/, 'Three.js runtime is pinned');
assert.match(game, /<html lang="ar" dir="rtl">/, 'Arabic RTL interface is retained');
assert.match(game, /camDist = PT\(\) \? 15\.5 : 24\.0/, 'landscape gameplay camera configuration is retained');
console.log('GLYPHFALL Android shell tests passed.');
