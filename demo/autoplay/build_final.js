const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const ROOT = path.join(__dirname);
const FRAMES = path.join(ROOT, 'screen_recording', 'frames');
const AUDIO = path.join(ROOT, 'screen_recording', 'audio');
const OUTPUT = path.join(ROOT, 'screen_recording');

// Scene definitions - each scene uses a key frame repeated for duration
const SCENES = [
  { frame: '01_dashboard.png', duration: 10, audio: '01_intro.mp3' },
  { frame: '01_dashboard.png', duration: 15, audio: '02_dashboard.mp3' },
  { frame: '01_dashboard_scroll.png', duration: 10, audio: '03_dashboard_scroll.mp3' },
  { frame: '02_vehicles.png', duration: 15, audio: '04_vehicles.mp3' },
  { frame: '03_fitment_rules.png', duration: 15, audio: '05_fitments.mp3' },
  { frame: '05_settings.png', duration: 12, audio: '06_settings.mp3' },
  { frame: '06_bulk_imports.png', duration: 10, audio: '07_bulk.mp3' },
  { frame: '01_dashboard.png', duration: 8, audio: '08_closing.mp3' },
];

const FRAMES_DIR = path.join(ROOT, 'frames_live');
const TEMP_SEG = path.join(OUTPUT, 'temp_segments');
const TEMP_FINAL = path.join(OUTPUT, 'temp_final');

fs.mkdirSync(TEMP_SEG, { recursive: true });
fs.mkdirSync(TEMP_FINAL, { recursive: true });

console.log('Building video segments from screenshots...\n');

const segmentList = [];

for (let i = 0; i < SCENES.length; i++) {
  const scene = SCENES[i];
  const img = path.join(FRAMES_DIR, scene.frame);
  const wav = path.join(AUDIO, scene.audio.replace('.mp3', '.wav'));
  const mp3 = path.join(AUDIO, scene.audio);
  const seg = path.join(TEMP_SEG, `seg_${String(i + 1).padStart(2, '0')}.mp4`);

  // Check if we have wav, if not convert from mp3
  let audioFile = wav;
  if (!fs.existsSync(wav) && fs.existsSync(mp3)) {
    audioFile = path.join(TEMP_SEG, `audio_${i + 1}.wav`);
    try {
      execSync(`ffmpeg -y -i "${mp3}" "${audioFile}"`, { stdio: 'pipe' });
    } catch (e) {
      console.log(`  Warning: Could not convert audio for scene ${i + 1}`);
      audioFile = null;
    }
  } else if (!fs.existsSync(wav)) {
    audioFile = null;
  }

  // Get audio duration if available
  let audioDur = scene.duration;
  if (audioFile && fs.existsSync(audioFile)) {
    try {
      audioDur = parseFloat(execSync(`ffprobe -v error -show_entries format=duration -of csv=p=0 "${audioFile}"`, { encoding: 'utf8' }).trim());
    } catch (e) {}
  }

  const totalDur = audioDur + 0.5; // Add 0.5s padding

  console.log(`Scene ${i + 1}: ${scene.frame} (${totalDur.toFixed(1)}s)`);

  try {
    if (audioFile && fs.existsSync(audioFile)) {
      // Video with audio
      execSync(`ffmpeg -y -loop 1 -i "${img}" -i "${audioFile}" -vf "pad=ceil(iw/2)*2:ceil(ih/2)*2" -c:v libx264 -preset ultrafast -tune stillimage -pix_fmt yuv420p -af "aresample=44100" -c:a aac -b:a 192k -strict -2 -t ${totalDur.toFixed(2)} -shortest "${seg}"`, { stdio: 'pipe' });
    } else {
      // Video without audio (silent)
      execSync(`ffmpeg -y -loop 1 -i "${img}" -f lavfi -i anullsrc -vf "pad=ceil(iw/2)*2:ceil(ih/2)*2" -c:v libx264 -preset ultrafast -tune stillimage -pix_fmt yuv420p -af "aresample=44100" -c:a aac -b:a 192k -strict -2 -t ${totalDur.toFixed(2)} -shortest "${seg}"`, { stdio: 'pipe' });
    }

    if (fs.existsSync(seg) && fs.statSync(seg).size > 0) {
      segmentList.push(seg);
      console.log(`  OK`);
    }
  } catch (e) {
    console.log(`  FAIL: ${e.message.slice(0, 100)}`);
  }
}

if (segmentList.length === 0) {
  console.log('No segments built. Aborting.');
  process.exit(1);
}

// Create concat list
const listFile = path.join(TEMP_SEG, 'concat.txt');
fs.writeFileSync(listFile, segmentList.map(s => `file '${s.replace(/\\/g, '/')}'`).join('\n'));

// Concatenate all segments
const concatVideo = path.join(TEMP_FINAL, 'concat.mp4');
console.log(`\nConcatenating ${segmentList.length} segments...`);

try {
  execSync(`ffmpeg -y -f concat -safe 0 -i "${listFile}" -c copy "${concatVideo}"`, { stdio: 'pipe' });

  if (fs.existsSync(concatVideo)) {
    const dur = execSync(`ffprobe -v error -show_entries format=duration -of csv=p=0 "${concatVideo}"`, { encoding: 'utf8' }).trim();
    console.log(`Concatenated: ${parseFloat(dur).toFixed(1)}s`);
  }
} catch (e) {
  console.log(`Concat failed: ${e.message.slice(0, 200)}`);
}

// Generate full narration with edge-tts
const fullNarrationMp3 = path.join(AUDIO, 'full_narration.mp3');
const fullNarrationWav = path.join(AUDIO, 'full_narration.wav');

if (fs.existsSync(fullNarrationMp3) && !fs.existsSync(fullNarrationWav)) {
  console.log('Converting full narration to WAV...');
  try {
    execSync(`ffmpeg -y -i "${fullNarrationMp3}" "${fullNarrationWav}"`, { stdio: 'pipe' });
  } catch (e) {}
}

// Final output with full narration
const finalOutput = path.join(ROOT, '..', '..', 'Vehicle_Selector_Pro_Demo.mp4');
const finalOutputAlt = path.join(ROOT, '..', 'Vehicle_Selector_Pro_Demo.mp4');

if (fs.existsSync(fullNarrationWav) || fs.existsSync(fullNarrationMp3)) {
  const audioInput = fs.existsSync(fullNarrationWav) ? fullNarrationWav : fullNarrationMp3;
  console.log('Adding full narration audio...');

  for (const outPath of [finalOutput, finalOutputAlt]) {
    try {
      execSync(`ffmpeg -y -i "${concatVideo}" -i "${audioInput}" -c:v copy -c:a aac -b:a 192k -strict -2 -shortest "${outPath}"`, { stdio: 'pipe' });
      if (fs.existsSync(outPath) && fs.statSync(outPath).size > 0) {
        const sizeMB = (fs.statSync(outPath).size / 1024 / 1024).toFixed(1);
        const dur = execSync(`ffprobe -v error -show_entries format=duration -of csv=p=0 "${outPath}"`, { encoding: 'utf8' }).trim();
        console.log(`DONE: ${outPath} (${sizeMB} MB, ${parseFloat(dur).toFixed(1)}s)`);
      }
    } catch (e) {}
  }
} else {
  // No audio, just copy the concat
  console.log('No full narration found, using concat video only');
  for (const outPath of [finalOutput, finalOutputAlt]) {
    try {
      fs.copyFileSync(concatVideo, outPath);
      const sizeMB = (fs.statSync(outPath).size / 1024 / 1024).toFixed(1);
      const dur = execSync(`ffprobe -v error -show_entries format=duration -of csv=p=0 "${outPath}"`, { encoding: 'utf8' }).trim();
      console.log(`DONE: ${outPath} (${sizeMB} MB, ${parseFloat(dur).toFixed(1)}s)`);
    } catch (e) {}
  }
}

// Cleanup
try { fs.rmSync(TEMP_SEG, { recursive: true, force: true }); } catch(e) {}
try { fs.rmSync(TEMP_FINAL, { recursive: true, force: true }); } catch(e) {}

console.log('\nDone!');
