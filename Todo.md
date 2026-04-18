# YouBeatAI Todo

## 🔴 HIGH PRIORITY (Blocking)

### Critical Bugs
- [ ] **Fix clap/stomp detection** — `Scripts/Audio/clap_stomp.gd` returns hardcoded 0.0, feature is non-functional
- [ ] **Remove hardcoded bus reference** — `Scripts/klappy_light_pad.gd:24` has TODO comment, uses hardcoded "SubMaster" bus

### Incomplete Core Features
- [ ] **Song recording** — Record full song mix, playback, export


---

## 🟡 MEDIUM PRIORITY (In Progress / Partial)

### Incomplete Implementations
- [ ] **Beat ring scale animation** — `Scripts/UI/beat_ring_ui.gd:146` mark TODO tween scale changes
- [ ] **Voice-to-synth pipeline** — `Experimental/VoiceToSynth/` multiple incomplete features
- [ ] **Synth filter support** — `addons/synth/synth.gd:226-237` only lowpass tested, others non-functional
- [ ] **Klappy tutorial outcome** — `Scripts/Achievements/tutorial.gd:166` stomp visibility disabled with cryptic comment
- [ ] **Track muting architecture** — Recording mute logic in `track_recorder.gd` should be in AudioPlayerManager
- [ ] **Audio export/email feature** — `Experimental/SongExport/exporter.gd` has commented-out email export

### Features to Complete
- [ ] **Beat suggestions / tip button** — Random beat pattern suggestions
- [ ] **Klappy animations** — Facial expressions, reactions, lighting
- [ ] **Klappy lightbulb interaction** — UI state machine for hint system
- [ ] **Alternative synth effects** — Beyond current lowpass filter
- [ ] **Improve FFT quality** — Better spectrum analysis for beat detection

### Polish & Debug Cleanup
- [ ] Remove debug print statements from: `audio_player_manager.gd`, `sequencer.gd`, `synth.gd`, `Fft.gd`, `beat_button.gd`
- [ ] Guard TTS helper for missing voice data (`Scripts/Global/tts_helper.gd:13`)
- [ ] Remove commented test code from `fft/Fft.gd:116-117`
- [ ] Clean up synth plugin empty lifecycle methods (`addons/synth/plugin.gd`)

---

## 🟢 LOW PRIORITY (Tech Debt & Cleanup)


### Remaining Experimental Cleanup
**Active & Keep:**
- ✅ `Experimental/Klappy/` — Used by Klappy robot system
- ✅ `Experimental/SongExport/exporter.gd`, `listenToLastExport.gd` — Integrated
- ✅ `Experimental/VoiceToSynth/notes.tres`, `Note.gd` — Used by synth tracks

**Delete (Completely Unused):**
- [ ] `Experimental/sequencer/` (entire folder) — MIDI prototype, 0 references
- [ ] `Experimental/VoiceToSynth/` — Delete all EXCEPT notes.tres & Note.gd
- [ ] `Experimental/SongExport/field.gd`, `loading_container.gd`, `scales.md`, `test.tscn`
- [ ] `Experimental/chords/chord.gd`, `progression.tres`

**Summary:** ~20 orphaned files remaining for deletion

### Documentation & Refactoring
- [ ] Build task in `.vscode/tasks.json` needs Godot executable path configuration
- [ ] Verify all EventBus signals are documented in `.github/copilot-instructions.md`
- [ ] Create architecture docs for: Audio recording pipeline, Klappy AI system, UI state machine

---

## ✅ COMPLETED / WORKING

- ✅ Core beat ring visualization
- ✅ Audio track playback (4x drum + 2x synth)
- ✅ Microphone recording (with clap/stomp trigger)
- ✅ Section switching
- ✅ BPM / swing control
- ✅ Chaos pad mixer
- ✅ Klappy robot (UI presence, basic reactions)
- ✅ EventBus architecture (no direct coupling)
- ✅ Workspace instructions (`copilot-instructions.md`)