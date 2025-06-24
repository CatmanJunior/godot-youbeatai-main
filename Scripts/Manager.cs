using Godot;
using System;
using System.IO;

using NAudio.Wave;
using NAudio.Lame;
using System.Collections.Generic;
using NAudio.Wave.SampleProviders;
using System.Linq;
using System.Diagnostics;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Text;
using System.Globalization;

public partial class Manager : Node
{
    // singleton
    public static Manager instance = null;

    // events
    [Signal]
    public delegate void OnSwitchLayerEventHandler(int layer);
    [Signal]
    public delegate void OnShouldClapEventEventHandler();
    [Signal]
    public delegate void OnShouldStompEventEventHandler();

	// audio
    public AudioStreamPlayer2D firstAudioPlayer;
    public AudioStreamPlayer2D secondAudioPlayer;
    public AudioStreamPlayer2D thirdAudioPlayer;
    public AudioStreamPlayer2D fourthAudioPlayer;

    public AudioStreamPlayer2D firstAudioPlayerAlt;
    public AudioStreamPlayer2D secondAudioPlayerAlt;
    public AudioStreamPlayer2D thirdAudioPlayerAlt;
    public AudioStreamPlayer2D fourthAudioPlayerAlt;

    public AudioStreamPlayer2D firstAudioPlayerRec;
    public AudioStreamPlayer2D secondAudioPlayerRec;
    public AudioStreamPlayer2D thirdAudioPlayerRec;
    public AudioStreamPlayer2D fourthAudioPlayerRec;

    // sample mixers
    [Export] public Node2D sampleMixer0;
    [Export] public Node2D sampleMixer1;
    [Export] public Node2D sampleMixer2;
    [Export] public Node2D sampleMixer3;

    // other sfx
    AudioStreamPlayer2D extraAudioPlayer;
    [Export] AudioStream metronome_sfx;
    [Export] AudioStream metronomealt_sfx;
    [Export] AudioStream achievement_sfx;
    bool metronome_sfx_enabled = false;

    // saving
    [Export] public AudioStream[] mainAudioFiles;
    [Export] public AudioStream[] mainAudioFilesAlt;

    [Export] Button saveToWavButton;
    bool hassavedtofile = false;

    // particles
    [Export] public CpuParticles2D beat_particles;
    private Vector2 beat_particles_position;
    private float beat_particles_time;
    private float beat_particles_curtime;
    private Color beat_particles_color;
    private bool beat_particles_emitting = false;

    [Export] public CpuParticles2D pbar_particles;
    private float pbar_particles_time;
    private float pbar_particles_curtime;
    private bool pbar_particles_emitting = false;

    [Export] public CpuParticles2D achievement_particles;
    private float achievement_particles_time;
    private float achievement_particles_curtime;
    private bool achievement_particles_emitting = false;

    // switch layer buttons
    [Export] Button layerButton1;
    [Export] Button layerButton2;
    [Export] Button layerButton3;
    [Export] Button layerButton4;
    [Export] Button layerButton5;
    [Export] Button layerButton6;
    [Export] Button layerButton7;
    [Export] Button layerButton8;
    [Export] Button layerButton9;
    [Export] Button layerButton10;

    [Export] Label chosen_emoticons_label;


    public void EmitBeatParticles(Vector2 position, Color color)
    {
        beat_particles_curtime = 0;
        beat_particles_time = 0.05f;
        beat_particles_position = position;
        beat_particles_color = color.Lightened(0.25f);
        beat_particles_emitting = true;
    }

    public void EmitProgressBarParticles()
    {
        pbar_particles_curtime = 0;
        pbar_particles_time = 0.4f;
        pbar_particles_emitting = true;
    }

    public void EmitAchievementParticles()
    {
        achievement_particles_curtime = 0;
        achievement_particles_time = 0.5f;
        achievement_particles_emitting = true;
    }

    // colors
    [Export] public Color[] colors;

    // idk
    [Export] PointLight2D robotlight;

    // beats
    [Export] PackedScene spritePrefab;
    [Export] Texture2D texture;
    [Export] Texture2D outline;
    Sprite2D[,] beatOutlines;
    public Sprite2D[,] beatSprites;
    Sprite2D[,] templateSprites;
    

    // left buttons
    [Export] Button SaveLayoutButton;
    [Export] Button LoadLayoutButton;
    [Export] Button ClearLayoutButton;
    [Export] public Button PlayPauseButton;
    [Export] public Button ResetPlayerButton;
    [Export] Button BpmUpButton;
    [Export] Button BpmDownButton;

    // sample buttons
    [Export] public Sprite2D draganddropButton0;
    [Export] public Sprite2D draganddropButton1;
    [Export] public Sprite2D draganddropButton2;
    [Export] public Sprite2D draganddropButton3;
    [Export] public RecordSampleButton recordSampleButton0;
    [Export] public RecordSampleButton recordSampleButton1;
    [Export] public RecordSampleButton recordSampleButton2;
    [Export] public RecordSampleButton recordSampleButton3;

    BpmManager bpm_manager => BpmManager.instance;

    SoundBank chosenSoundBank = null;
    List<string> chosenEmoticons = null;

    // settings menu
    [Export] CheckButton metronome_toggle;
    [Export] ProgressBar micmeter;
    [Export] CheckButton add_beats;
    [Export] Slider volume_treshold;

    // other interface
    [Export] Button skiptutorialbutton;
    [Export] ProgressBar progressBar;
    float progressBarValue = 0;
    [Export] Sprite2D pointer;
    [Export] public Sprite2D metronome;
    [Export] public Sprite2D metronomebg;
    [Export] Label bpmLabel;
    [Export] Sprite2D draganddropthing;
    public bool dragginganddropping = false;
    public int holdingforring;
    [Export] Slider swingslider;
    [Export] Label swinglabel;
    [Export] Button settingsButton;
    [Export] Panel settingsPanel;
    [Export] Slider ClapBiasSlider;
    [Export] Panel achievementspanel;
    [Export] public CheckButton layerLoopToggle;
    [Export] Label SavingLabel;
    bool savingLabelActive = false;
    float savingLabelTimer = 0;

    // clapping and stomping
    bool stomped = false;
    bool clapped = false;
    int clappedAmount = 0;
    int stompedAmount = 0;

    // other
    public bool showTemplate = false;
    public bool selectedTemplate = false;
    bool haschangedbpm = false;
    bool hasclearedlayout = false;
    private bool spacedownlastframe = false;
    private bool enterdownlastframe = false;
    float timeafterplay = 0;
    bool savedToLaout = false;

    // on button functions
    bool[,] savedTemplate = new bool[4, BpmManager.beatsAmount];

    bool loadedtemplate = false;

    public void OnSaveLayoutButton()
    {
        //GD.Print("save");
        savedTemplate = (bool[,])beatActives.Clone();
        savedToLaout = true;
    }
    public void OnLoadLayoutButton()
    {
        //GD.Print("load");
        beatActives = (bool[,])savedTemplate.Clone();
        loadedtemplate = true;
    }

    public void OnClearLayoutButton()
    {
        beatActives = new bool[4, BpmManager.beatsAmount];
        hasclearedlayout = true;
    }
    public void OnRecordButton() => GD.Print("Record");

    public void OnPlayPauseButton()
    {
        bpm_manager.playing = !bpm_manager.playing;

        // pause layer voice over
        if (LayerVoiceOver.instance.voiceOvers[LayerVoiceOver.instance.currentLayer] != null)
        {
            if (LayerVoiceOver.instance.audioPlayer.Playing) LayerVoiceOver.instance.audioPlayer.StreamPaused = true;
            else LayerVoiceOver.instance.audioPlayer.StreamPaused = false;
        }

        // pause song voice over
        if (SongVoiceOver.instance.voiceOver != null)
        {
            if (SongVoiceOver.instance.audioPlayer.Playing) SongVoiceOver.instance.audioPlayer.StreamPaused = true;
            else SongVoiceOver.instance.audioPlayer.StreamPaused = false;
        }
    }

    public void OnBpmUpButton()
    {
        if (bpm_manager.bpm < 300) bpm_manager.bpm += 10;
        haschangedbpm = true;
    }
    public void OnBpmDownButton()
    {
        if (bpm_manager.bpm > 40) bpm_manager.bpm -= 10;
        haschangedbpm = true;
    }
    public void OnResetPlayerButton() => bpm_manager.currentBeat = BpmManager.beatsAmount - 1;

    public void ShowSavingLabel(string name)
    {
        savingLabelActive = true;
        savingLabelTimer = 0;
        SavingLabel.Text = "Opgeslagen naar:" + "\n" + name;
    }

    private void PlayExtraSFX(AudioStream audioStream)
    {
        extraAudioPlayer.Stop();
        extraAudioPlayer.Stream = audioStream;
        extraAudioPlayer.Play();
    }

    // on toggle functions
    /*
    private void OnToggled0(bool toggledOn)
    {
        firstAudioPlayer.Stop();
        audioFilesToUse[0] = toggledOn ? recordSampleButton0.recordedAudio : mainAudioFiles[0];
        firstAudioPlayer.Stream = audioFilesToUse[0];
    }
    private void OnToggled1(bool toggledOn)
    {
        secondAudioPlayer.Stop();
        audioFilesToUse[1] = toggledOn ? recordSampleButton1.recordedAudio : mainAudioFiles[1];
        secondAudioPlayer.Stream = audioFilesToUse[1];
    }
    private void OnToggled2(bool toggledOn)
    {
        thirdAudioPlayer.Stop();
        audioFilesToUse[2] = toggledOn ? recordSampleButton2.recordedAudio : mainAudioFiles[2];
        thirdAudioPlayer.Stream = audioFilesToUse[2];
    }
    private void OnToggled3(bool toggledOn)
    {
        fourthAudioPlayer.Stop();
        audioFilesToUse[3] = toggledOn ? recordSampleButton3.recordedAudio : mainAudioFiles[3];
        fourthAudioPlayer.Stream = audioFilesToUse[3];  
    }
    */

    [Export] Label InstructionLabel;
    int achievementLevel = 0;

    string[] instructions = null;
    Func<bool>[] conditions = null;
    Action[] outcomes = null;

    [Export] Sprite2D robot;

    // ---------------------------

    [Export] Button allLayersToMp3;

    [Export] Sprite2D layerOutline;

    public bool[,] beatActives = new bool[4, BpmManager.beatsAmount];

    public int currentLayerIndex = 0;

    public List<bool[,]> layers = new()
    {
        new bool[4, BpmManager.beatsAmount],
        new bool[4, BpmManager.beatsAmount],
        new bool[4, BpmManager.beatsAmount],
        new bool[4, BpmManager.beatsAmount],
        new bool[4, BpmManager.beatsAmount],
        new bool[4, BpmManager.beatsAmount],
        new bool[4, BpmManager.beatsAmount],
        new bool[4, BpmManager.beatsAmount],
        new bool[4, BpmManager.beatsAmount],
        new bool[4, BpmManager.beatsAmount]
    };

    public bool[,] GetCurrentLayer() => layers[currentLayerIndex];
    public bool[,] SetCurrentLayer(bool[,] value) => layers[currentLayerIndex] = value;

    public void NextLayer()
    {
        if (currentLayerIndex == 9) SwitchLayer(1);
        else SwitchLayer(currentLayerIndex + 2);
    }

    public void PreviousLayer()
    {
        if (currentLayerIndex == 0) SwitchLayer(10);
        else SwitchLayer(currentLayerIndex);
    }

    public void SwitchLayer(int layerToUse)
    {
        // save current layer
        SetCurrentLayer(beatActives);
        //GD.Print(LayerHasBeats(beatActives));

        // switch to next layer
        //GD.Print("switch to the " + layerToUse + "th layer");
        currentLayerIndex = layerToUse - 1;
        beatActives = GetCurrentLayer();

        // update outline
        layerOutline.Position = new Vector2(-574, 317) - new Vector2(0, 1) * (71f * currentLayerIndex);

        // update song voice position
        if (SongVoiceOver.instance.voiceOver != null) UpdateSongVoiceOverPlayBackPosition();

        EmitSignal(SignalName.OnSwitchLayer, layerToUse);
    }

    public void UpdateSongVoiceOverPlayBackPosition()
    {
        var timeperlayer = SongVoiceOver.instance.recordingLength / 10;

        var fixedcurrentbeat = bpm_manager.currentBeat;
        if (fixedcurrentbeat >= BpmManager.beatsAmount - 1) fixedcurrentbeat = 0;

        //GD.Print("current beat: " + fixedcurrentbeat);

        var timeperbeat = timeperlayer / BpmManager.beatsAmount;
        var beattimeoffset = timeperbeat * fixedcurrentbeat;

        var seekpos = currentLayerIndex * timeperlayer + beattimeoffset;

        //GD.Print("beat time offset: " + beattimeoffset);

        SongVoiceOver.instance.audioPlayer.Seek(seekpos);

        //GD.Print("layer: " + currentLayerIndex + " - " + "length: " + SongVoiceOver.instance.recordingLength + " - " + "seekpos: " + seekpos);
    }

    public bool LayerHasBeats(bool[,] layer)
    {
        for (int ring = 0; ring < 4; ring++)
        {
            for (int beat = 0; beat < BpmManager.beatsAmount; beat++)
            {
                bool active = layer[ring, beat];
                if (active) return true;
            }
        }
        return false;
    }

    public void AllLayersToMp3()
    {
        GD.Print("saving all layers to an mp3 file");
        SetCurrentLayer(beatActives);
        SaveSongAsFile(layers);
    }

    public void ConvertAudioStreamWavToWav(AudioStreamWav audioStreamWav, string filePath)
    {
        if (audioStreamWav.Stereo) audioStreamWav = ConvertStereoToMono(audioStreamWav);
        byte[] pcmData = audioStreamWav.Data;
        using (var waveFile = new WaveFileWriter(filePath, new WaveFormat(audioStreamWav.MixRate, 16, audioStreamWav.Stereo ? 2 : 1))) waveFile.Write(pcmData, 0, pcmData.Length);
        GD.Print($"WAV file successfully created at: {filePath}");
    }

    public AudioStreamWav ConvertStereoToMono(AudioStreamWav stereoStream)
    {
        AudioStreamWav monoStream = (AudioStreamWav)stereoStream.Duplicate();
        var audioData = stereoStream.Data;
        int bytesPerSample = stereoStream.Format == AudioStreamWav.FormatEnum.Format8Bits ? 1 : 2;
        byte[] monoData = new byte[audioData.Length / 2];

        for (int i = 0; i < audioData.Length; i += bytesPerSample * (stereoStream.Stereo ? 2 : 1))
        {
            // get left and right samples
            float leftSample = 0, rightSample = 0;
            if (stereoStream.Format == AudioStreamWav.FormatEnum.Format16Bits)
            {
                leftSample = BitConverter.ToInt16(audioData, i) / 32768f;
                rightSample = BitConverter.ToInt16(audioData, i + bytesPerSample) / 32768f;
            }
            else if (stereoStream.Format == AudioStreamWav.FormatEnum.Format8Bits)
            {
                leftSample = (audioData[i] - 128) / 128f;
                rightSample = (audioData[i + bytesPerSample] - 128) / 128f;
            }

            // write to averages mono sample
            float monoSample = (leftSample + rightSample) / 2.0f;
            if (stereoStream.Format == AudioStreamWav.FormatEnum.Format16Bits)
            {
                short monoShort = (short)(monoSample * 32768);
                byte[] monoBytes = BitConverter.GetBytes(monoShort);
                Array.Copy(monoBytes, 0, monoData, (i / 2), bytesPerSample);
            }
            else if (stereoStream.Format == AudioStreamWav.FormatEnum.Format8Bits)
            {
                byte monoByte = (byte)((monoSample * 128) + 128);
                monoData[i / 2] = monoByte;
            }
        }

        monoStream.Data = monoData;
        monoStream.Stereo = false;
        return monoStream;
    }

    public void MixAudioFiles(string file1, string file2, string outputFile)
    {
        using (var reader1 = new AudioFileReader(file1))
        {
            using (var reader2 = new AudioFileReader(file2))
            {
                // Use the format of the input files
                var outputFormat = reader1.WaveFormat;

                // Create a MixingSampleProvider for the two input files
                var mixer = new MixingSampleProvider([reader1.ToSampleProvider(), reader2.ToSampleProvider()]);

                // Write the mixed audio to the output file in chunks
                using (var writer = new WaveFileWriter(outputFile, outputFormat))
                {
                    const int bufferSize = 4096; // Process audio in chunks
                    float[] buffer = new float[bufferSize];

                    while (true)
                    {
                        // Read samples from the mixer
                        int samplesRead = mixer.Read(buffer, 0, bufferSize);

                        // Exit the loop if no more samples are available
                        if (samplesRead == 0) break;

                        // Write the samples to the output file
                        writer.WriteSamples(buffer, 0, samplesRead);
                    }

                    writer.Close();
                }
                reader2.Close();
            }
            reader1.Close();
        }
    }

    public void SaveBeatAsFile(bool[,] loop)
    {
        string sanitizedTime = Time.GetTimeStringFromSystem().Replace(":", "_");
        string filename = "beat_" + bpm_manager.bpm.ToString() + "bpm_" + sanitizedTime;

        int sampleRate = 48000;
        float secondsPerBeat = 60f / bpm_manager.bpm;
        int beatsPerLoop = BpmManager.beatsAmount;
        int totalBeats = beatsPerLoop;
        int totalSamples = (int)(totalBeats * secondsPerBeat * sampleRate);
        float[] audioData = new float[totalSamples];
        bool[,] currentLoop = loop;

        // for each ring
        for (int ring = 0; ring < currentLoop.GetLength(0); ring++)
        {
            // for each beat
            for (int beat = 0; beat < currentLoop.GetLength(1); beat++)
            {
                // if beat active
                if (currentLoop[ring, beat])
                {
                    // get audio sample of beat
                    AudioStreamWav audioStreamWav = (AudioStreamWav)mainAudioFiles[ring];
                    var audioBytes = audioStreamWav.GetData();

                    // Convert byte[] to float[] (each pcm sample is a 16 bit integer also known as a short)
                    float[] samples = new float[audioBytes.Length / 2];
                    for (int i = 0; i < samples.Length; i++) samples[i] = BitConverter.ToInt16(audioBytes, i * 2) / 32768f;

                    // write audiodata at position
                    for (int i = 0; i < samples.Length; i++)
                    {
                        int position = (int)((beat) * secondsPerBeat * sampleRate) + i;
                        if (position < totalSamples) audioData[position] += samples[i];
                    }
                }
            }
        }

        // normalize
        float max = 0;
        foreach (var sample in audioData) if (Math.Abs(sample) > max) max = Math.Abs(sample);
        if (max > 1.0f) for (int i = 0; i < audioData.Length; i++) audioData[i] /= max;

        // write file
        using (var writer = new WaveFileWriter(filename + ".wav", new WaveFormat(sampleRate, 1)))
        {
            foreach (var sample in audioData) writer.WriteSample(sample);
            writer.Close();
        }

        ChangePitch(filename + ".wav", 2f);

        // convert and finish
        //ConvertWavToMp3(filename);
        ShowSavingLabel(filename);
        hassavedtofile = true;
    }

    public void SaveSongAsFile(List<bool[,]> loops)
    {
        string sanitizedTime = Time.GetTimeStringFromSystem().Replace(":", "_");

        string final_name = "export_" + bpm_manager.bpm.ToString() + "bpm_" + sanitizedTime;

        string beats_name = "beats";
        string song_name = "song";
        string layers_name = "layers";
        string beats_with_song_name = "beats_with_song";

        int sampleRate = 48000;
        float secondsPerBeat = 60f / bpm_manager.bpm;
        int beatsPerLoop = BpmManager.beatsAmount;
        int totalBeats = beatsPerLoop * loops.Count;
        int totalSamples = (int)(totalBeats * secondsPerBeat * sampleRate);
        float[] audioData = new float[totalSamples];

        // process each loop
        for (int loopIndex = 0; loopIndex < loops.Count; loopIndex++)
        {
            bool[,] currentLoop = loops[loopIndex];

            // for each ring
            for (int ring = 0; ring < currentLoop.GetLength(0); ring++)
            {
                // for each beat
                for (int beat = 0; beat < currentLoop.GetLength(1); beat++)
                {
                    // if beat active
                    if (currentLoop[ring, beat])
                    {
                        // get audio sample of beat
                        AudioStreamWav audioStreamWav = (AudioStreamWav)mainAudioFiles[ring];
                        var audioBytes = audioStreamWav.GetData();

                        // Convert byte[] to float[] (each pcm sample is a 16 bit integer also known as a short)
                        float[] samples = new float[audioBytes.Length / 2];
                        for (int i = 0; i < samples.Length; i++) samples[i] = BitConverter.ToInt16(audioBytes, i * 2) / 32768f;

                        // write audiodata at position
                        for (int i = 0; i < samples.Length; i++)
                        {
                            int position = (int)((loopIndex * beatsPerLoop + beat) * secondsPerBeat * sampleRate) + i;
                            if (position < totalSamples) audioData[position] += samples[i];
                        }
                    }
                }
            }
        }

        // normalize
        float max = 0;
        foreach (var sample in audioData) if (Math.Abs(sample) > max) max = Math.Abs(sample);
        if (max > 1.0f) for (int i = 0; i < audioData.Length; i++) audioData[i] /= max;

        // write file
        using (var writer = new WaveFileWriter(beats_name + ".wav", new WaveFormat(sampleRate, 1)))
        {
            foreach (var sample in audioData) writer.WriteSample(sample);
            writer.Close();
        }

        ChangePitch(beats_name + ".wav", 2f);

        // export layers voiceovers as single wav
        AudioStream[] voiceovers = LayerVoiceOver.instance.voiceOvers;
        for (int i = 0; i < 10; i++)
        {
            string name = "layer" + i.ToString() + ".wav";
            AudioStreamWav audioStreamWav = (AudioStreamWav)voiceovers[i];
            if (audioStreamWav != null)
            {
                // voice wav
                ConvertAudioStreamWavToWav(audioStreamWav, name);
            }
            else
            {
                // empty wav
                float timepb = 60f / BpmManager.instance.bpm / 2;
                float time = timepb * BpmManager.beatsAmount;
                int rate = 48000;
                int channels = 1;
                int bits = 16;
                int total = (int)(time * rate * channels);
                byte[] silence = new byte[total * (bits / 8)];
                var waveFormat = new WaveFormat(sampleRate, bits, channels);
                using (var writer = new WaveFileWriter(name, waveFormat))
                {
                    writer.Write(silence, 0, silence.Length);
                    writer.Close();
                }
            }
        }
        List<string> layer_inputs =
        [
            "layer0.wav",
            "layer1.wav",
            "layer2.wav",
            "layer3.wav",
            "layer4.wav",
            "layer5.wav",
            "layer6.wav",
            "layer7.wav",
            "layer8.wav",
            "layer9.wav"
        ];
        using (var firstReader = new WaveFileReader(layer_inputs[0]))
        {
            var waveFormat = firstReader.WaveFormat;
            using (var writer = new WaveFileWriter(layers_name + ".wav", waveFormat))
            {
                firstReader.CopyTo(writer);
                for (int i = 1; i < layer_inputs.Count; i++) using (var reader = new WaveFileReader(layer_inputs[i])) reader.CopyTo(writer);
            }
        }
        for (int i = 0; i < layer_inputs.Count; i++) File.Delete(layer_inputs[i]);

        // song to wav
        ConvertAudioStreamWavToWav((AudioStreamWav)SongVoiceOver.instance.voiceOver, song_name + ".wav");

        // mix everything
        MixAudioFiles(beats_name + ".wav", song_name + ".wav", beats_with_song_name + ".wav");
        MixAudioFiles(beats_with_song_name + ".wav", layers_name + ".wav", final_name + ".wav");

        // delete temps
        File.Delete(beats_name + ".wav");
        File.Delete(layers_name + ".wav");
        File.Delete(song_name + ".wav");
        File.Delete(beats_with_song_name + ".wav");

        // convert and finish
        ConvertWavToMp3(final_name);
        ShowSavingLabel(final_name);
        hassavedtofile = true;
    }

    public void ChangePitch(string filePath, float pitchFactor)
    {
        List<float> outputBuffer = new List<float>();
        WaveFormat waveFormat;

        // read and process
        using (var reader = new AudioFileReader(filePath))
        {
            waveFormat = reader.WaveFormat;
            var sampleRate = waveFormat.SampleRate;
            var channels = waveFormat.Channels;

            var buffer = new float[sampleRate * channels];
            int bytesRead;

            while ((bytesRead = reader.Read(buffer, 0, buffer.Length)) > 0)
            {
                int newSampleCount = (int)(bytesRead / pitchFactor);
                var resampled = new float[newSampleCount];

                for (int i = 0; i < newSampleCount; i++)
                {
                    float sourceIndex = i * pitchFactor;
                    int index = (int)sourceIndex;
                    float frac = sourceIndex - index;

                    if (index + 1 < bytesRead) resampled[i] = buffer[index] * (1 - frac) + buffer[index + 1] * frac;
                    else resampled[i] = buffer[index];
                }

                outputBuffer.AddRange(resampled);
            }
        }

        // overwrite
        using (var writer = new WaveFileWriter(filePath, waveFormat)) writer.WriteSamples(outputBuffer.ToArray(), 0, outputBuffer.Count);
    }

    // --------------------------------

    private float startswing;

    public override void _Ready()
    {
        // init singleton
        instance ??= this;

        bpm_manager.OnBeatEvent += OnBeat;

        // deserialize chosen soundbank
        string chosen_soundbank_path = System.IO.Path.Combine(ProjectSettings.GlobalizePath("user://"), "chosen_soundbank.json");
        string chosen_soundbank_json = File.ReadAllText(chosen_soundbank_path);
        chosenSoundBank = JsonSerializer.Deserialize<SoundBank>(chosen_soundbank_json);

        // deserialize chosen emoticons
        string chosen_emoticons_path = System.IO.Path.Combine(ProjectSettings.GlobalizePath("user://"), "chosen_emoticons.json");
        string chosen_emoticons_json = File.ReadAllText(chosen_emoticons_path);
        chosenEmoticons = JsonSerializer.Deserialize<List<string>>(chosen_emoticons_json);
        foreach (var emoticon in chosenEmoticons) chosen_emoticons_label.Text += emoticon;

        // grab audio files -> res://Resources/Audio/SoundBanks/
        string soundbankname = chosenSoundBank.name;
        string baseDirPath = "res://Resources/Audio/SoundBanks/"; // should be a subfolder of "res://Resources/Audio/SoundBanks/" with the soundbankname in its name.
        DirAccess baseDir = DirAccess.Open(baseDirPath);
        baseDir.ListDirBegin();
        string folderName;
        while ((folderName = baseDir.GetNext()) != "")
        {
            if (baseDir.CurrentIsDir() && folderName.ToLower().Contains(soundbankname.ToLower()))
            {
                string folderThatHoldsAudioFiles = baseDirPath + folderName + "/";

                // load audio files
                string[] files = ResourceLoader.ListDirectory(folderThatHoldsAudioFiles);
                string fileName;
                for (int i = 0; i < files.Length; ++i)
                {
                    fileName = files[i];

                    if (fileName.EndsWith(".wav"))
                    {
                        string lower = fileName.ToLower();
                        string fullPath = folderThatHoldsAudioFiles + fileName;
                        if (lower.Contains("kick")) mainAudioFiles[0] = ResourceLoader.Load<AudioStream>(fullPath);
                        else if (lower.Contains("clap")) mainAudioFiles[1] = ResourceLoader.Load<AudioStream>(fullPath);
                        else if (lower.Contains("snare")) mainAudioFiles[2] = ResourceLoader.Load<AudioStream>(fullPath);
                        else if (lower.Contains("closed")) mainAudioFiles[3] = ResourceLoader.Load<AudioStream>(fullPath);
                    }
                }
                break;
            }
        }
        baseDir.ListDirEnd();

        // set swing
        float chosenswing = chosenSoundBank.swing / 100f * 0.4f;
        BpmManager.instance.swing = chosenswing;
        startswing = chosenswing;
        swingslider.Value = chosenswing;

        // set bpm
        int offset = 0;
        string path = "res://Resources/SoundBankMatrix/bpmoffset.json";
        string offsetjson = Godot.FileAccess.Open(path, Godot.FileAccess.ModeFlags.Read).GetAsText();
        Dictionary<string, string> offsetLookup = JsonSerializer.Deserialize<Dictionary<string, string>>(offsetjson);
        foreach (string theme in chosenSoundBank.themes)
        {
            offset += int.Parse(offsetLookup[theme]);
            GD.Print("add: " + offsetLookup[theme] + " / total: " + offset);
        }
        BpmManager.instance.bpm = chosenSoundBank.bpm + offset;

        // delete tmep json files
        File.Delete(chosen_emoticons_path);
        File.Delete(chosen_soundbank_path);

        // init audioplayers
        extraAudioPlayer = new AudioStreamPlayer2D();
        AddChild(extraAudioPlayer);

        // main
        firstAudioPlayer = new AudioStreamPlayer2D();
        secondAudioPlayer = new AudioStreamPlayer2D();
        thirdAudioPlayer = new AudioStreamPlayer2D();
        fourthAudioPlayer = new AudioStreamPlayer2D();
        AddChild(firstAudioPlayer);
        AddChild(secondAudioPlayer);
        AddChild(thirdAudioPlayer);
        AddChild(fourthAudioPlayer);

        // alt
        firstAudioPlayerAlt = new AudioStreamPlayer2D();
        secondAudioPlayerAlt = new AudioStreamPlayer2D();
        thirdAudioPlayerAlt = new AudioStreamPlayer2D();
        fourthAudioPlayerAlt = new AudioStreamPlayer2D();
        AddChild(firstAudioPlayerAlt);
        AddChild(secondAudioPlayerAlt);
        AddChild(thirdAudioPlayerAlt);
        AddChild(fourthAudioPlayerAlt);

        // rec
        firstAudioPlayerRec = new AudioStreamPlayer2D();
        secondAudioPlayerRec = new AudioStreamPlayer2D();
        thirdAudioPlayerRec = new AudioStreamPlayer2D();
        fourthAudioPlayerRec = new AudioStreamPlayer2D();
        AddChild(firstAudioPlayerRec);
        AddChild(secondAudioPlayerRec);
        AddChild(thirdAudioPlayerRec);
        AddChild(fourthAudioPlayerRec);

        firstAudioPlayer.Stream = mainAudioFiles[0];
        secondAudioPlayer.Stream = mainAudioFiles[1];
        thirdAudioPlayer.Stream = mainAudioFiles[2];
        fourthAudioPlayer.Stream = mainAudioFiles[3];

        firstAudioPlayerAlt.Stream = mainAudioFilesAlt[0];
        secondAudioPlayerAlt.Stream = mainAudioFilesAlt[1];
        thirdAudioPlayerAlt.Stream = mainAudioFilesAlt[2];
        fourthAudioPlayerAlt.Stream = mainAudioFilesAlt[3];

        // mixers setup -------------------------------------------------

        void UpdateVolumes(int ring, float mainvolume, float altvolume, float recvolume)
        {
            if (ring == 0)
            {
                firstAudioPlayer.VolumeDb = Mathf.LinearToDb(mainvolume);
                firstAudioPlayerAlt.VolumeDb = Mathf.LinearToDb(altvolume);
                firstAudioPlayerRec.VolumeDb = Mathf.LinearToDb(recvolume);
            }
            else if (ring == 1)
            {
                secondAudioPlayer.VolumeDb = Mathf.LinearToDb(mainvolume);
                secondAudioPlayerAlt.VolumeDb = Mathf.LinearToDb(altvolume);
                secondAudioPlayerRec.VolumeDb = Mathf.LinearToDb(recvolume);
            }
            else if (ring == 2)
            {
                thirdAudioPlayer.VolumeDb = Mathf.LinearToDb(mainvolume);
                thirdAudioPlayerAlt.VolumeDb = Mathf.LinearToDb(altvolume);
                thirdAudioPlayerRec.VolumeDb = Mathf.LinearToDb(recvolume);
            }
            else if (ring == 3)
            {
                fourthAudioPlayer.VolumeDb = Mathf.LinearToDb(mainvolume);
                fourthAudioPlayerAlt.VolumeDb = Mathf.LinearToDb(altvolume);
                fourthAudioPlayerRec.VolumeDb = Mathf.LinearToDb(recvolume);
            }
        }

        void RotatePivot(float rotation, Node2D pivot, int ring)
        {
            pivot.RotationDegrees += rotation;

            float fullrotation = Mathf.PosMod(pivot.RotationDegrees, 360f) / 360f;

            float GetCrossfadeVolume(float sectionCenter)
            {
                float distance = Mathf.Abs(fullrotation - sectionCenter);
                if (distance > 0.5f) distance = 1f - distance;
                float maxDistance = 1f / 3f;
                return distance <= maxDistance ? 1f - (distance / maxDistance) : 0f;
            }

            float mainvolume = GetCrossfadeVolume(0f);      // peak at 0°
            float altvolume = GetCrossfadeVolume(1f / 3f);  // peak at 120°
            float recvolume = GetCrossfadeVolume(2f / 3f);  // peak at 240°

            UpdateVolumes(ring, mainvolume, altvolume, recvolume);

            GD.Print($"rot: {fullrotation:F1}, main: {mainvolume:F1}, alt: {altvolume:F1}, rec: {recvolume:F1}");

            var icon0 = pivot.GetChild(0) as Label;
            var icon1 = pivot.GetChild(1) as Label;
            var icon2 = pivot.GetChild(2) as Label;

            icon0.Modulate = new Color(1, 1, 1, mainvolume);
            icon1.Modulate = new Color(1, 1, 1, altvolume);
            icon2.Modulate = new Color(1, 1, 1, recvolume);
        }

        void SetupMixer(Node2D mixer, int ring)
        {
            var increase = mixer.FindChild("IncreaseButton") as Button;
            var decrease = mixer.FindChild("DecreaseButton") as Button;
            var pivot = mixer.FindChild("Pivot") as Node2D;

            // increase.Pressed += () => RotatePivot(10, pivot, ring);
            // decrease.Pressed += () => RotatePivot(-10, pivot, ring);

            var timerInc = new Timer
            {
                WaitTime = 0.05,
                OneShot = false,
                Autostart = false
            };
            AddChild(timerInc);

            var timerDec = new Timer
            {
                WaitTime = 0.05,
                OneShot = false,
                Autostart = false
            };
            AddChild(timerDec);

            timerInc.Timeout += () => RotatePivot(5, pivot, ring);
            timerDec.Timeout += () => RotatePivot(-5, pivot, ring);

            increase.ButtonDown += () => timerInc.Start();
            increase.ButtonUp += () => timerInc.Stop();

            decrease.ButtonDown += () => timerDec.Start();
            decrease.ButtonUp += () => timerDec.Stop();
            
            RotatePivot(0, pivot, ring);
        }

        SetupMixer(sampleMixer0, 0);
        SetupMixer(sampleMixer1, 1);
        SetupMixer(sampleMixer2, 2);
        SetupMixer(sampleMixer3, 3);

        // mixers setup -------------------------------------------------

        layerButton1.Pressed += () => SwitchLayer(1);
        layerButton2.Pressed += () => SwitchLayer(2);
        layerButton3.Pressed += () => SwitchLayer(3);
        layerButton4.Pressed += () => SwitchLayer(4);
        layerButton5.Pressed += () => SwitchLayer(5);
        layerButton6.Pressed += () => SwitchLayer(6);
        layerButton7.Pressed += () => SwitchLayer(7);
        layerButton8.Pressed += () => SwitchLayer(8);
        layerButton9.Pressed += () => SwitchLayer(9);
        layerButton10.Pressed += () => SwitchLayer(10);

        allLayersToMp3.Pressed += AllLayersToMp3;

       

        SaveLayoutButton.Pressed += OnSaveLayoutButton;
        LoadLayoutButton.Pressed += OnLoadLayoutButton;

        ClearLayoutButton.Pressed += OnClearLayoutButton;
        PlayPauseButton.Pressed += OnPlayPauseButton;
        BpmUpButton.Pressed += OnBpmUpButton;
        BpmDownButton.Pressed += OnBpmDownButton;
        saveToWavButton.Pressed += () => SaveBeatAsFile(beatActives);
        ResetPlayerButton.Pressed += () => { OnResetPlayerButton(); bpm_manager.playing = true; };

        // skipping / ending the tutorial
        skiptutorialbutton.Pressed += () =>
        {
            // disable achievement management
            achievementLevel = -1;
            
            // first enable full ui
            SetEntireInterfaceVisibility(true);

            // disable achievements panel
            achievementspanel.Visible = false;

            // lift settigns panel
            settingsButton.Position = new(settingsButton.Position.X, -340);

            // shift robot position
            robot.Position = new(485, 225);

        };

        // settings panel
        settingsButton.Pressed += () => settingsPanel.Visible = !settingsPanel.Visible;

        // spawn sprites
        beatSprites = new Sprite2D[4, BpmManager.beatsAmount];
        for (int ring = 0; ring < 4; ring++)
        {
            for (int beat = 0; beat < BpmManager.beatsAmount; beat++)
            {
                var sprite = CreateSprite(beat, ring);
                AddChild(sprite);
                beatSprites[ring, beat] = sprite;
            }
        }

        // spawn outlines
        beatOutlines = new Sprite2D[4, BpmManager.beatsAmount];
        for (int ring = 0; ring < 4; ring++)
        {
            for (int beat = 0; beat < BpmManager.beatsAmount; beat++)
            {
                var outline = CreateOutline(beat, ring);
                AddChild(outline);
                beatOutlines[ring, beat] = outline;
            }
        }

        // spawn template sprites
        templateSprites = new Sprite2D[4, BpmManager.beatsAmount];
        for (int ring = 0; ring < 4; ring++)
        {
            for (int beat = 0; beat < BpmManager.beatsAmount; beat++)
            {
                var sprite = CreateTemplateSprite(beat, ring);
                AddChild(sprite);
                templateSprites[ring, beat] = sprite;
            }
        }

        // setup achievements
        instructions = new string[26]
        {
            // intro
			"Hoi ik ben Klappy!, we gaan een beat maken en ik ga je daarbij helpen. klap 👏 in je handen om verder te gaan",
			
			// rode ring
			"Dit is een 🔴 beat ring, plaats nu 4 beats op de witte streepjes",
			"Helemaal goed! zet 4 🔴 beats op een plek die jij wil",
			"Druk nu op '⏯ Start' om je beat te horen",
			"Als je stompt 👞 met je voet op de grond precies wanneer er een rode beat is krijg ik energie ⚡",

			// oranje ring
			"Dit is nog een 🟠 beat ring, plaats nu 4 beats in het midden van de rode beats",
			"Helemaal goed! zet 4 🟠 beats op een plek die jij wil!",
			"Druk nu op '⏯ Start' om je beat te horen",
			"Als je klapt 👏 met je handen wanneer er een oranje 🟠 beat klinkt krijgen ik energie ⚡",

			// gele ring
			"Dit is nog een 🟡 beat ring, plaats nu 2 harde beats waar je wilt op deze ring",

			// blauwe ring
			"Dit is nog een 🔵 beat ring, plaats nu 2 beats waar je wilt op deze ring",

			// alle ringen
			"Druk nog een keer op '⏯ Start', luister naar alle beats bij elkaar!",
			
			// progressiebar
			"Klap 👏 en stamp 👞 op het goede moment! Geef me 50% energie ⚡ om naar de volgende stap te gaan!",
			
			// custom sample
			"Je hebt het ritme te pakken! Nu gaan we onze eigen geluid maken, houd het microfoon 🎤 icoontje boven het rode 🔴 knopje ingedrukt een spreek iets in je microfoon",
			"Druk op de toggle boven de microfoon 🎤 icoontje om het opgenomen geluid te activeren",
			"Druk op '⏯ Start' om te horen hoe je eigen geluidje klinkt",

			// effects
			"We gaan de beat sneller maken. Druk op '🐇 Sneller' om de beat het sneller te maken",
			"Druk op de '🏛 Galm' of de '⛰ Echo'  knop. voor speciale echo's",
			"Tijd voor wat '🌀 Swing' in de beat. sleep het swing balkje naar het midden.",

            // layer voice over
            "door op de '🎤 Beat Opnemen' in het midden van de beats te drukken kan je jou stem over de beat opnemen. hij begint met opnemen als die beat ovenaan is.",
            "Bij '⚙️ Instellingen' kan je '🔁 Liedje Modus' aanzetten zodat de Beats achter elkaar afgespeeld worden",
            "Druk op '⏯ Start' om te horen hoe je eigen beats achter elkaar klinken",
            "Liedjes hebben een patroon: 'Intro🌱, Couplet📜, Refrein🤩 en Einde🏁'. Om je beats naar een andere laag te verplaatsen druk '💾 Kopieer Beat' en '♻️ Plak Beat'",

            // song voice over
            "Laten we nu het hele liedje opnemen door op de '🎙️ Liedje Opnemen' links bovenin het scherm te drukken. Dan begin hij met opnemen als hij bij de eerste beat op de eerst laag is",
            "Als je tevreden bent dan kan je ook echt je '🎼 Liedje naar mp3'",
            "Druk op de '🚫 Stop' knop om de tutorial te eindigen",
        };

        conditions = new Func<bool>[26]
        {
            // intro
            () => clapped, // t key is debug only

            // rode ring
            () => AmountOfActives(0) >= 4, // temp
            () => AmountOfActives(0) >= 8, // temp
            () => bpm_manager.playing == true, // temp
            () => stompedAmount > 4, // temp

            // oranje ring
            () => AmountOfActives(1) >= 4, // temp
            () => AmountOfActives(1) >= 8, // temp
            () => bpm_manager.playing == true, // temp
            () => clappedAmount > 4, // temp

            // gele ring
            () => AmountOfActives(2) >= 2, // temp

            // blauwe ring
            () => AmountOfActives(3) >= 2, // temp

            // alle ringen
            () => bpm_manager.playing == true, // temp

            // progressie bar
            () => progressBar.Value > 50,

            // custom sample
            () => recordSampleButton0.recordedAudio != null,
            () => true, // skip for now
            () => bpm_manager.playing == true, // temp

            // effects
            () => haschangedbpm,
            () => ReverbDelayManager.instance?.reverbSlider.Value != 0 || ReverbDelayManager.instance?.delaySlider.Value != 0,
            () => Mathf.Abs(bpm_manager.swing - startswing) > 0.01f,

            // layer voice over
            () => LayerVoiceOver.instance.finished,
            () => layerLoopToggle.ButtonPressed,
            () => bpm_manager.playing == true,
            () => savedToLaout == true && loadedtemplate == true,

            // song voice over
            () => SongVoiceOver.instance.finished,
            () => hassavedtofile == true,
            () => false
        };
        
        outcomes = new Action[]
        {
            () => SetRingVisibility(0, true),
            null,
            () => PlayPauseButton.Visible = true,
            () => progressBar.Visible = true,
            () => SetRingVisibility(1, true),
            null,
            null,
            null,
            () => SetRingVisibility(2, true), // zet geel
            () => SetRingVisibility(3, true), // zet blauw
            null, // druk play
            null, // geef energie
            () => { SetRecordingButtonsVisibility(true); SetDragAndDropButtonsVisibility(true); SetSampleMixersVisibility(true); },
            null,
            null,
            () => SetEffectButtonsVisibility(true),
            null,
            null,
            () => { LayerVoiceOver.instance.recordLayerButton.Visible = true; LayerVoiceOver.instance.textureProgressBar.Visible = true; },

            // layer voice over
            () => { settingsPanel.Visible = true; SetLayerSwitchButtonsVisibility(true); }, // before doing liedje modus
            null, // before pressing play
            () => SetMainButtonsVisibility(true), // before saving to layout
            () => { SongVoiceOver.instance.recordSongButton.Visible = true; SongVoiceOver.instance.progressbar.Visible = true; }, // before recording song

            // song voice over
            null, // before saving to file
            () => SetEntireInterfaceVisibility(true), // enable all
            null
        };
    }

    void _LateReady()
    {
        // disable entire interface
        SetEntireInterfaceVisibility(false);

        // start with showing tutorial
        achievementspanel.Visible = true;
        settingsButton.Visible = true;
        settingsPanel.Visible = false;
    }

    public void SetEntireInterfaceVisibility(bool visible)
    {
        // rings
        SetRingVisibility(0, visible);
        SetRingVisibility(1, visible);
        SetRingVisibility(2, visible);
        SetRingVisibility(3, visible);

        // sliders
        SetSampleMixersVisibility(visible);

        // progress bar
        progressBar.Visible = visible;

        // playpause button
        PlayPauseButton.Visible = visible;

        // main buttons
        SetMainButtonsVisibility(visible);

        // effect buttons
        SetEffectButtonsVisibility(visible);

        // recording buttons
        SetRecordingButtonsVisibility(visible);

        // draganddrop buttons
        SetDragAndDropButtonsVisibility(visible);

        // layer switch buttons
        SetLayerSwitchButtonsVisibility(visible);

        // settings menu
        settingsButton.Visible = visible;

        // achievements panel
        achievementspanel.Visible = visible;

        // recording
        SongVoiceOver.instance.recordSongButton.Visible = visible;
        SongVoiceOver.instance.progressbar.Visible = visible;
        LayerVoiceOver.instance.recordLayerButton.Visible = visible;
        LayerVoiceOver.instance.textureProgressBar.Visible = visible;
    }

    void SetRingVisibility(int ring, bool visible)
    {
        for (int beat = 0; beat < BpmManager.beatsAmount; beat++) beatSprites[ring, beat].Visible = visible;
        for (int beat = 0; beat < BpmManager.beatsAmount; beat++) beatOutlines[ring, beat].Visible = visible;
        for (int beat = 0; beat < BpmManager.beatsAmount; beat++) templateSprites[ring, beat].Visible = visible;
    }

    void SetMainButtonsVisibility(bool visible)
    {
        SaveLayoutButton.Visible = visible;
        LoadLayoutButton.Visible = visible;
        ClearLayoutButton.Visible = visible;
        ResetPlayerButton.Visible = visible;
        saveToWavButton.Visible = visible;
        allLayersToMp3.Visible = visible;
    }

    void SetEffectButtonsVisibility(bool visible)
    {
        BpmUpButton.Visible = visible;
        BpmDownButton.Visible = visible;
        bpmLabel.Visible = visible;
        swingslider.Visible = visible;
        swinglabel.Visible = visible;
        metronome.Visible = visible;
        metronomebg.Visible = visible;
        ReverbDelayManager.instance.reverbSlider.Visible = visible;
        ReverbDelayManager.instance.delaySlider.Visible = visible;
    }

    void SetRecordingButtonsVisibility(bool visible)
    {
        recordSampleButton0.Visible = visible;
        recordSampleButton1.Visible = visible;
        recordSampleButton2.Visible = visible;
        recordSampleButton3.Visible = visible;
    }

    void SetDragAndDropButtonsVisibility(bool visible)
    {
        draganddropButton0.Visible = visible;
        draganddropButton1.Visible = visible;
        draganddropButton2.Visible = visible;
        draganddropButton3.Visible = visible;
    }

    public void SetLayerSwitchButtonsVisibility(bool visible)
    {
        layerButton1.Visible = visible;
        layerButton2.Visible = visible;
        layerButton3.Visible = visible;
        layerButton4.Visible = visible;
        layerButton5.Visible = visible;
        layerButton6.Visible = visible;
        layerButton7.Visible = visible;
        layerButton8.Visible = visible;
        layerButton9.Visible = visible;
        layerButton10.Visible = visible;
        layerOutline.Visible = visible;
    }

    public void SetLayerSwitchButtonsEnabled(bool enabled)
    {
        layerButton1.Disabled = !enabled;
        layerButton2.Disabled = !enabled;
        layerButton3.Disabled = !enabled;
        layerButton4.Disabled = !enabled;
        layerButton5.Disabled = !enabled;
        layerButton6.Disabled = !enabled;
        layerButton7.Disabled = !enabled;
        layerButton8.Disabled = !enabled;
        layerButton9.Disabled = !enabled;
        layerButton10.Disabled = !enabled;
    }

    public void SetSampleMixersVisibility(bool visible)
    {
        sampleMixer0.Visible = visible;
        sampleMixer1.Visible = visible;
        sampleMixer2.Visible = visible;
        sampleMixer3.Visible = visible;
    }

    // ---------------------------------------------------------------

    // arrow keys
    bool up_pressed = false;
	bool up_pressed_lastframe = false;
    bool dn_pressed = false;
	bool dn_pressed_lastframe = false;
    bool lf_pressed = false;
	bool lf_pressed_lastframe = false;
    bool rt_pressed = false;
	bool rt_pressed_lastframe = false;

    bool f7_pressed = false;
	bool f7_pressed_lastframe = false;

    bool latereadydone = false;

    float time = 0;

    // metronome timer
    float slowBeatTimer = 0;

    bool first_tts_done = false;

    public override void _Process(double delta)
    {
        time += (float)delta;

        

        if (Input.IsKeyPressed(Key.F6) && bpm_manager.bpm != 900) bpm_manager.bpm = 900;

        if (!latereadydone)
        {
            _LateReady();
            latereadydone = true;
        }

        // saving label
        if (savingLabelActive && savingLabelTimer < 4)
        {
            savingLabelTimer += (float)delta;
        }
        else savingLabelActive = false;

        SavingLabel.Visible = savingLabelActive;

        // switch layer buttons
        layerButton1.Modulate = new Color(1, 1, 1, 1);
        layerButton2.Modulate = new Color(1, 1, 1, 1);
        layerButton3.Modulate = new Color(1, 1, 1, 1);
        layerButton4.Modulate = new Color(1, 1, 1, 1);
        layerButton5.Modulate = new Color(1, 1, 1, 1);
        layerButton6.Modulate = new Color(1, 1, 1, 1);
        layerButton7.Modulate = new Color(1, 1, 1, 1);
        layerButton8.Modulate = new Color(1, 1, 1, 1);
        layerButton9.Modulate = new Color(1, 1, 1, 1);
        layerButton10.Modulate = new Color(1, 1, 1, 1);
        if (!LayerHasBeats(layers[0])) layerButton1.Modulate = layerButton1.Modulate.Darkened(0.5f);
        if (!LayerHasBeats(layers[1])) layerButton2.Modulate = layerButton2.Modulate.Darkened(0.5f);
        if (!LayerHasBeats(layers[2])) layerButton3.Modulate = layerButton3.Modulate.Darkened(0.5f);
        if (!LayerHasBeats(layers[3])) layerButton4.Modulate = layerButton4.Modulate.Darkened(0.5f);
        if (!LayerHasBeats(layers[4])) layerButton5.Modulate = layerButton5.Modulate.Darkened(0.5f);
        if (!LayerHasBeats(layers[5])) layerButton6.Modulate = layerButton6.Modulate.Darkened(0.5f);
        if (!LayerHasBeats(layers[6])) layerButton7.Modulate = layerButton7.Modulate.Darkened(0.5f);
        if (!LayerHasBeats(layers[7])) layerButton8.Modulate = layerButton8.Modulate.Darkened(0.5f);
        if (!LayerHasBeats(layers[8])) layerButton9.Modulate = layerButton9.Modulate.Darkened(0.5f);
        if (!LayerHasBeats(layers[9])) layerButton10.Modulate = layerButton10.Modulate.Darkened(0.5f);


        // update robot light
        var lightvalue = progressBarValue / 100;
        if (lightvalue > 1) lightvalue = 1;
        float pulsed = ((((Mathf.Sin(time * 4) + 1) / 2) / 2) + 0.5f);
        robotlight.Energy = lightvalue * pulsed;

        // update micmeter
        micmeter.Value = MicrophoneCapture.instance.volume;

        // other
        metronome_sfx_enabled = metronome_toggle.ButtonPressed;

        string RemoveEmojis(string input)
        {
            var output = "";
            var stringInfo = new StringInfo(input);
            for (int i = 0; i < stringInfo.LengthInTextElements; i++)
            {
                string element = stringInfo.SubstringByTextElements(i, 1);
                if (!Regex.IsMatch(element, @"\p{Cs}|\p{So}|\p{Sk}|\p{Mn}|\u200D")) output += element;
            }
            return output;
        }

        void SpeakInstruction(int instruction)
        {
            var voices = DisplayServer.TtsGetVoicesForLanguage("nl");
            if (voices.Length == 0) voices = DisplayServer.TtsGetVoicesForLanguage("en");
            if (DisplayServer.TtsIsSpeaking()) DisplayServer.TtsStop();
            DisplayServer.TtsSpeak(RemoveEmojis(instructions[instruction]), voices[0], 100);
        }

        // first tts
        if (!first_tts_done)
        {
            SpeakInstruction(0);
            first_tts_done = true;
        }

        // deal with achievements
        if (achievementLevel != -1)
        {
            string instruction = instructions[achievementLevel];
            Func<bool> condition = conditions[achievementLevel];
            Action outcome = outcomes[achievementLevel];
            InstructionLabel.Text = instruction;

            f7_pressed_lastframe = f7_pressed;
		    f7_pressed = Input.IsKeyPressed(Key.F7);
		    bool skip = f7_pressed && f7_pressed != f7_pressed_lastframe;

            if (condition() || skip)
            {
                if (outcome != null) outcome();
                achievementLevel++;
                EmitAchievementParticles();
                PlayExtraSFX(achievement_sfx);
                SpeakInstruction(achievementLevel);
            }
        }

        // deal with beat particles
        if (beat_particles_emitting && beat_particles_curtime < beat_particles_time)
        {
            beat_particles.Color = beat_particles_color;
            beat_particles.Position = beat_particles_position;
            beat_particles.Emitting = true;
            beat_particles_curtime += (float)delta;
        }
        else
        {
            beat_particles.Emitting = false;
            beat_particles_emitting = false;
        }

        // deal with progress bar particles
        if (pbar_particles_emitting && pbar_particles_curtime < pbar_particles_time)
        {
            pbar_particles.Emitting = true;
            pbar_particles_curtime += (float)delta;
        }
        else
        {
            pbar_particles.Emitting = false;
            pbar_particles_emitting = false;
        }

        // deal with progress bar particles
        if (achievement_particles_emitting && achievement_particles_curtime < achievement_particles_time)
        {
            achievement_particles.Emitting = true;
            achievement_particles_curtime += (float)delta;
        }
        else
        {
            achievement_particles.Emitting = false;
            achievement_particles_emitting = false;
        }

        // deal with arrowkeys
        up_pressed_lastframe = up_pressed;
		up_pressed = Input.IsKeyPressed(Key.Up);
		if (up_pressed && up_pressed != up_pressed_lastframe) OnBpmUpButton();
        dn_pressed_lastframe = dn_pressed;
		dn_pressed = Input.IsKeyPressed(Key.Down);
		if (dn_pressed && dn_pressed != dn_pressed_lastframe) OnBpmDownButton();

        // update swing amount
        bpm_manager.swing = (float)swingslider.Value;

        // space as play/pause
        var spacedown = Input.IsKeyPressed(Key.Space);
        if (spacedown && spacedownlastframe == false) OnPlayPauseButton();
        spacedownlastframe = spacedown;

        // enter as reset player
        var enterdown = Input.IsKeyPressed(Key.Enter);
        if (enterdown && enterdownlastframe == false) { OnResetPlayerButton(); bpm_manager.playing = true; }
        enterdownlastframe = enterdown;

        // drag&drop
        if (dragginganddropping)
        {
            draganddropthing.Modulate = colors[holdingforring];
            draganddropthing.Position = GetViewport().GetMousePosition() - (DisplayServer.WindowGetSize() / 2);
        }
        else draganddropthing.Modulate = new Color(1, 1, 1, 0);

        // update pointer
        float intergerFactor = (float)((float)(bpm_manager.currentBeat + (BpmManager.instance.beatTimer / BpmManager.instance.timePerBeat)) / (float)BpmManager.beatsAmount);
        pointer.RotationDegrees = intergerFactor * 360f - 7f;

        // check clap and stomp
        var volume = MicrophoneCapture.instance.volume;
        var frequency = MicrophoneCapture.instance.frequency;

        var treshold = volume_treshold.Value;
        var shouldclap = volume > treshold && frequency > ClapBiasSlider.Value;
        if (shouldclap || Input.IsKeyPressed(Key.N))
        {
            if (!clapped)
            {
                OnClap();
                clapped = true;
            }
        }
        
        bool shouldstomp = volume > treshold && frequency < ClapBiasSlider.Value;
        if (shouldstomp || Input.IsKeyPressed(Key.M))
        {
            if (!stomped)
            {
                OnStomp();
                stomped = true;
            }
        }
        
        if (bpm_manager.playing)
        {
            timeafterplay += ((float)delta);
            
            slowBeatTimer += (float)delta / 4;
            if (slowBeatTimer > BpmManager.instance.timePerBeat) slowBeatTimer -= BpmManager.instance.timePerBeat;
            var beatprogress = slowBeatTimer / BpmManager.instance.timePerBeat;
            metronome.Position = new Vector2(metronome.Position.X, Mathf.Lerp(-0.4f, 0.4f, beatprogress));

            // update progressbar
            if (progressBarValue > 100) progressBarValue = 100;
            progressBar.Value = progressBarValue;
        }
        else
        {
            timeafterplay = 0;
        }

        // update sprites
        for (int beat = 0; beat < BpmManager.beatsAmount; beat++)
        {
            for (int ring = 0; ring < 4; ring++)
            {
                var sprite = beatSprites[ring, beat];
                var active = beatActives[ring, beat];

                var color = colors[ring];

                if (beat == bpm_manager.currentBeat)
                {
                    if (active) color = color.Lightened(0.75f);
                    else color = new(1, 1, 1, 0.5f);
                }
                else if (!active) color.A = 0.2f;

                sprite.Modulate = color;

                if (sprite.Scale.X > 1) sprite.Scale -= Vector2.One * (float)delta * 0.3f;
            }
        }

        // bloop
        float factor = 2;
        if (draganddropButton0.Scale.X > 2) draganddropButton0.Scale -= Vector2.One * (float)delta * factor;
        if (draganddropButton1.Scale.X > 2) draganddropButton1.Scale -= Vector2.One * (float)delta * factor;
        if (draganddropButton2.Scale.X > 2) draganddropButton2.Scale -= Vector2.One * (float)delta * factor;
        if (draganddropButton3.Scale.X > 2) draganddropButton3.Scale -= Vector2.One * (float)delta * factor;

        // update outlines
        for (int beat = 0; beat < BpmManager.beatsAmount; beat++)
        {
            for (int ring = 0; ring < 4; ring++)
            {
                var outline = beatOutlines[ring, beat];
                outline.Modulate = colors[ring];
            }
        }

        // update template sprites
        for (int beat = 0; beat < BpmManager.beatsAmount; beat++)
        {
            for (int ring = 0; ring < 4; ring++)
            {
                var sprite = templateSprites[ring, beat];
                var active = TemplateManager.instance.GetCurrentActives()[ring, beat];
                sprite.Modulate = new Color(0, 0, 0, 0);
                if (active && showTemplate) sprite.Modulate = new Color(0, 0, 0, 1);
            }
        }

        // update bpm label
        bpmLabel.Text = bpm_manager.bpm.ToString();
    }

    void SetMainVolume(float value)
    {
        firstAudioPlayer.VolumeDb = Mathf.LinearToDb(value);
        secondAudioPlayer.VolumeDb = Mathf.LinearToDb(value);
        thirdAudioPlayer.VolumeDb = Mathf.LinearToDb(value);
        fourthAudioPlayer.VolumeDb = Mathf.LinearToDb(value);
    }

    void SetAltVolume(float value)
    {
        float db = Mathf.LinearToDb(value);
        firstAudioPlayerAlt.VolumeDb = db;
        secondAudioPlayerAlt.VolumeDb = db;
        thirdAudioPlayerAlt.VolumeDb = db;
        fourthAudioPlayerAlt.VolumeDb = db;
    }

    void SetRecVolume(float value)
    {
        float db = Mathf.LinearToDb(value);
        firstAudioPlayerRec.VolumeDb = db;
        secondAudioPlayerRec.VolumeDb = db;
        thirdAudioPlayerRec.VolumeDb = db;
        fourthAudioPlayerRec.VolumeDb = db;
    }

    private void ConvertWavToMp3(string filename)
    {
        var reader = new AudioFileReader(filename + ".wav");
        var writer = new LameMP3FileWriter(filename + ".mp3", reader.WaveFormat, LAMEPreset.STANDARD);
        reader.CopyTo(writer);
        reader.Close();
        writer.Close();
        File.Delete(filename + ".wav");
    }

    public static AudioStreamWav ChangeSampleRate(AudioStreamWav audioStream, int newSampleRate)
    {
        // get original audio data
        var originalData = audioStream.Data;
        var originalSampleRate = audioStream.MixRate;
        var stereo = audioStream.Stereo;
        var originalFormat = audioStream.Format;

        // no resampling or conversion needed
        if (originalSampleRate == newSampleRate && !stereo) return audioStream; 

        // convert data to float for processing
        var sampleCount = originalData.Length / sizeof(float);
        var originalSamples = new float[sampleCount];
        Buffer.BlockCopy(originalData, 0, originalSamples, 0, originalData.Length);

        // if stereo convert to mono
        float[] monoSamples;
        if (stereo)
        {
            monoSamples = new float[sampleCount / 2];
            for (int i = 0; i < monoSamples.Length; i++) monoSamples[i] = (originalSamples[i * 2] + originalSamples[i * 2 + 1]) / 2.0f;
        }
        else monoSamples = originalSamples;

        // calc ratio
        float ratio = (float)newSampleRate / originalSampleRate;

        // create buffer
        int newSampleCount = (int)(monoSamples.Length * ratio);
        var resampledSamples = new float[newSampleCount];

        // linear interpolation to resample
        for (int i = 0; i < newSampleCount; i++)
        {
            float originalPosition = i / ratio;
            int originalIndex = (int)Math.Floor(originalPosition);
            float frac = originalPosition - originalIndex;

            if (originalIndex < monoSamples.Length - 1) resampledSamples[i] = monoSamples[originalIndex] * (1 - frac) + monoSamples[originalIndex + 1] * frac;
            else resampledSamples[i] = monoSamples[originalIndex];
        }

        // resampled data back to byte array
        var newData = new byte[resampledSamples.Length * sizeof(float)];
        Buffer.BlockCopy(resampledSamples, 0, newData, 0, newData.Length);

        // create new audiostreamwav with updated sample rate
        var newAudioStream = new AudioStreamWav
        {
            Data = newData,
            MixRate = newSampleRate,
            Format = originalFormat,
            Stereo = false
        };

        return newAudioStream;
    }

    public void OnClap()
    {
        if (timeafterplay < 0.2f) return;
        int ring = 1;
        bool active = beatActives[ring, bpm_manager.currentBeat];
        var sprite = beatSprites[ring, bpm_manager.currentBeat];
        if (active)
        {
            sprite.Scale += Vector2.One;
            progressBarValue += 1f / BpmManager.beatsAmount * 100f;
            EmitProgressBarParticles();
            EmitBeatParticles(beatSprites[ring, bpm_manager.currentBeat].Position, colors[ring]);
        }
        clappedAmount++;
        draganddropButton1.Scale += Vector2.One / 2;

        if (add_beats.ButtonPressed) ((DragAndDropButton)draganddropButton1).ActivateBeat();
    }

    public void OnStomp()
    {
        if (timeafterplay < 0.2f) return;
        int ring = 0;
        bool active = beatActives[ring, bpm_manager.currentBeat];
        var sprite = beatSprites[ring, bpm_manager.currentBeat];
        if (active)
        {
            sprite.Scale += Vector2.One;
            progressBarValue += 1f / BpmManager.beatsAmount * 100f;
            EmitProgressBarParticles();
            EmitBeatParticles(beatSprites[ring, bpm_manager.currentBeat].Position, colors[ring]);
        }
        stompedAmount++;
        draganddropButton0.Scale += Vector2.One / 2;

        if (add_beats.ButtonPressed) ((DragAndDropButton)draganddropButton0).ActivateBeat();

    }

    public void OnBeat()
    {
        if (metronome_sfx_enabled)
        {
           if (bpm_manager.currentBeat % 4 == 0) PlayExtraSFX(metronome_sfx);
           else PlayExtraSFX(metronomealt_sfx);
        }

        if (beatActives[0, bpm_manager.currentBeat]) firstAudioPlayer.Play();
        if (beatActives[1, bpm_manager.currentBeat]) secondAudioPlayer.Play();
        if (beatActives[2, bpm_manager.currentBeat]) thirdAudioPlayer.Play();
        if (beatActives[3, bpm_manager.currentBeat]) fourthAudioPlayer.Play();

        if (beatActives[0, bpm_manager.currentBeat]) firstAudioPlayerAlt.Play();
        if (beatActives[1, bpm_manager.currentBeat]) secondAudioPlayerAlt.Play();
        if (beatActives[2, bpm_manager.currentBeat]) thirdAudioPlayerAlt.Play();
        if (beatActives[3, bpm_manager.currentBeat]) fourthAudioPlayerAlt.Play();

        if (beatActives[0, bpm_manager.currentBeat] && firstAudioPlayerRec.Stream != null) firstAudioPlayerRec.Play();
        if (beatActives[1, bpm_manager.currentBeat] && secondAudioPlayerRec.Stream != null) secondAudioPlayerRec.Play();
        if (beatActives[2, bpm_manager.currentBeat] && thirdAudioPlayerRec.Stream != null) thirdAudioPlayerRec.Play();
        if (beatActives[3, bpm_manager.currentBeat] && fourthAudioPlayerRec.Stream != null) fourthAudioPlayerRec.Play();

        clapped = false;
        stomped = false;

        if (bpm_manager.currentBeat == 1) if (progressBarValue > 10) progressBarValue -= 5;

        // if layer looping
        if (layerLoopToggle.ButtonPressed || SongVoiceOver.instance.recording) if (bpm_manager.currentBeat == BpmManager.beatsAmount - 1) NextLayer();

        if (bpm_manager.currentBeat == 0)
        {
            LayerVoiceOver.instance.OnTop();
            UpdateSongVoiceOverPlayBackPosition();
        }
        if (currentLayerIndex == 0 && bpm_manager.currentBeat == 0) SongVoiceOver.instance.OnBeginning();

        int nextbeat = bpm_manager.currentBeat + 1;
        if (nextbeat == BpmManager.beatsAmount) nextbeat = 0;

        bool clap_active = beatActives[1, nextbeat];
        if (clap_active)
        {
            GD.Print("shouldclap");
            EmitSignal(SignalName.OnShouldClapEvent);
        }

        bool stomp_active = beatActives[0, nextbeat];
        if (stomp_active)
        {
            GD.Print("shouldstomp");
            EmitSignal(SignalName.OnShouldStompEvent);
        }
    }

    private Sprite2D CreateOutline(int beat, int ring)
    {
        var sprite = new Sprite2D();
        float angle = Mathf.Pi * 2 * beat / BpmManager.beatsAmount - Mathf.Pi / 2;
        float distance = (4 - ring) * 30 + 110;
        sprite.Position = new Vector2(Mathf.Cos(angle), Mathf.Sin(angle)) * distance;
        sprite.Texture = outline;
        return sprite;
    }

    private Sprite2D CreateSprite(int beat, int ring)
    {
        var sprite = (Sprite2D)spritePrefab.Instantiate();
        float angle = Mathf.Pi * 2 * beat / BpmManager.beatsAmount - Mathf.Pi / 2;
        float distance = (4 - ring) * 30 + 110;
        sprite.Position = new Vector2(Mathf.Cos(angle), Mathf.Sin(angle)) * distance;
        sprite.Texture = texture;

        BeatSprite beatSprite = sprite as BeatSprite;
        beatSprite.spriteIndex = beat;
        beatSprite.ring = ring;

        return sprite;
    }

    private Sprite2D CreateTemplateSprite(int beat, int ring)
    {
        var sprite = new Sprite2D();
        float angle = Mathf.Pi * 2 * beat / BpmManager.beatsAmount - Mathf.Pi / 2;
        float distance = (4 - ring) * 30 + 110;
        sprite.Position = new Vector2(Mathf.Cos(angle), Mathf.Sin(angle)) * distance;
        sprite.Texture = texture;
        sprite.Modulate = new Color(0, 0, 0, 1);
        sprite.Scale = Vector2.One * 0.2f;
        return sprite;
    }

    static int AmountOfActives(int ring)
    {
        int amount = 0;
        for (int beat = 0; beat < BpmManager.beatsAmount; beat++) if (instance.beatActives[ring, beat]) amount++;
        return amount;
    }
}