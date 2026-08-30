const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const ROOT = path.join(__dirname);
const FRAMES = path.join(ROOT, 'frames');
const AUDIO = path.join(ROOT, 'audio');
const TEMP = path.join(ROOT, 'temp_segments');
const OUTPUT = path.join(ROOT, '..', 'Vehicle_Selector_Pro_Demo.mp4');

const manifest = JSON.parse(fs.readFileSync(path.join(ROOT, 'manifest.json'), 'utf8'));

fs.mkdirSync(TEMP, { recursive: true });

const segments = [];

for (const scene of manifest) {
  const img = path.join(FRAMES, `${scene.name}.png`);
  const wav = path.join(AUDIO, `${scene.name}.wav`);
  const seg = path.join(TEMP, `seg_${scene.name}.mp4`);

  if (!fs.existsSync(img) || !fs.existsSync(wav)) {
    console.log(`SKIP ${scene.name}`);
    continue;
  }

  // Get audio duration
  const dur = parseFloat(execSync(`ffprobe -v error -show_entries format=duration -of csv=p=0 "${wav}"`, { encoding: 'utf8' }).trim()) || 4;
  const totalDur = (dur + 0.8).toFixed(2);

  console.log(`BUILD ${scene.name} dur=${totalDur}s`);

  try {
    execSync(`ffmpeg -y -loop 1 -i "${img}" -i "${wav}" -c:v libx264 -tune stillimage -pix_fmt yuv420p -af "aresample=44100" -c:a aac -b:a 128k -strict -2 -t ${totalDur} -shortest "${seg}"`, { stdio: 'pipe' });

    if (fs.existsSync(seg) && fs.statSync(seg).size > 0) {
      segments.push(seg);
      console.log(`  OK ${scene.name}`);
    }
  } catch (e) {
    console.log(`  FAIL ${scene.name}: ${e.message.slice(0, 100)}`);
  }
}

if (segments.length === 0) {
  console.log('No segments. Aborting.');
  process.exit(1);
}

// Create concat list file
const listFile = path.join(TEMP, 'concat.txt');
const listContent = segments.map(s => `file '${s.replace(/\\/g, '/')}'`).join('\n');
fs.writeFileSync(listFile, listContent);

console.log(`\nCONCAT ${segments.length} segments → ${OUTPUT}`);

try {
  execSync(`ffmpeg -y -f concat -safe 0 -i "${listFile}" -c copy "${OUTPUT}"`, { stdio: 'pipe' });

  if (fs.existsSync(OUTPUT) && fs.statSync(OUTPUT).size > 0) {
    const sizeMB = (fs.statSync(OUTPUT).size / 1024 / 1024).toFixed(1);
    const dur = execSync(`ffprobe -v error -show_entries format=duration -of csv=p=0 "${OUTPUT}"`, { encoding: 'utf8' }).trim();
    console.log(`DONE ${OUTPUT} (${sizeMB} MB, ${parseFloat(dur).toFixed(1)}s)`);
  } else {
    console.log('FAIL: output empty');
  }
} catch (e) {
  console.log(`FAIL concat: ${e.message.slice(0, 200)}`);
}

// Cleanup
fs.rmSync(TEMP, { recursive: true, force: true });
