import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import yazl from 'yazl';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, '..');
const version = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8')).version;
const outDir = path.join(root, 'dist');
const outPath = path.join(outDir, `peridot-idle-drain-ksu-next-v${version}.zip`);
const chunkSize = 1200;

const baseEntries = [
  'module.prop',
  'config.conf',
  'service.sh',
  'action.sh',
  'README.md',
  'LICENSE',
  'scripts/tune.sh',
  'webroot/index.html'
];
const payloadDir = path.join(root, 'payload', 'tune');
fs.rmSync(path.join(root, 'payload'), { recursive: true, force: true });
fs.mkdirSync(payloadDir, { recursive: true });
const fullTune = fs.readFileSync(path.join(root, 'full', 'tune.full.sh'));
const chunks = [];
for (let i = 0; i < fullTune.length; i += chunkSize) {
  const name = String(chunks.length).padStart(2, '0');
  const rel = `payload/tune/${name}`;
  fs.writeFileSync(path.join(root, rel), fullTune.subarray(i, i + chunkSize));
  chunks.push(rel);
}
const entries = [...baseEntries, ...chunks];

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
for (const entry of entries) {
  console.log(`${entry}: ${fs.statSync(path.join(root, entry)).size}`);
}
