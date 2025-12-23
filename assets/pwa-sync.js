const fs = require('fs');
const path = require('path');

const manifestPath = path.join(__dirname, '../priv/static/cache_manifest.json');
const templatePath = path.join(__dirname, 'sw.js.template');
const outputPath = path.join(__dirname, '../priv/static/sw.js');

if (!fs.existsSync(manifestPath)) {
  console.error('Manifest file not found. Run mix phx.digest first.');
  process.exit(1);
}

const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
const latest = manifest.latest || {};

let swContent = fs.readFileSync(templatePath, 'utf8');

const mapping = {
  '{{APP_JS}}': '/' + (latest['assets/js/app.js'] || 'assets/js/app.js'),
  '{{APP_CSS}}': '/' + (latest['assets/css/app.css'] || 'assets/css/app.css'),
  '{{LOGO_SVG}}': '/' + (latest['images/logo.svg'] || 'images/logo.svg'),
  '{{ICON_192}}': '/' + (latest['images/icon-192.png'] || 'images/icon-192.png'),
  '{{ICON_512}}': '/' + (latest['images/icon-512.png'] || 'images/icon-512.png'),
};

for (const [placeholder, assetPath] of Object.entries(mapping)) {
  swContent = swContent.replace(placeholder, assetPath);
}

// Also handle Phosphor icons if they are in the manifest
// For now we'll stick to the core app shell

fs.writeFileSync(outputPath, swContent);
console.log('Successfully updated priv/static/sw.js with fingerprinted assets.');
