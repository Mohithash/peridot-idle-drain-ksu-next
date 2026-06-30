import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import yazl from 'yazl';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, '..');
const version = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8')).version;
const outDir = path.join(root, 'dist');
const outPath = path.join(outDir, `peridot-idle-drain-ksu-next-v${version}.zip`);

const entries = [
  'module.prop',
  'config.conf',
  'service.sh',
  'action.sh',
  'README.md',
  'LICENSE',
  'scripts/tune.sh',
  'webroot/index.html'
];

fs.mkdirSync(outDir, { recursive: true });
if (fs.existsSync(outPath)) {
  fs.unlinkSync(outPath);
}

const zip = new yazl.ZipFile();
for (const entry of entries) {
  const filePath = path.join(root, entry);
  if (!fs.existsSync(filePath)) {
    throw new Error(`Missing release entry: ${entry}`);
  }
  const mode = ['service.sh', 'action.sh', 'scripts/tune.sh'].includes(entry) ? 0o100755 : 0o100644;
  zip.addFile(filePath, entry, { mode });
}

zip.end();

await new Promise((resolve, reject) => {
  zip.outputStream
    .pipe(fs.createWriteStream(outPath))
    .on('close', resolve)
    .on('error', reject);
});

console.log(outPath);
