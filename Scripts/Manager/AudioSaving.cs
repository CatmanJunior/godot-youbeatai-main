using Godot;

using System;
using System.IO;
using System.Threading.Tasks;
using System.Collections.Generic;

using NAudio.Wave;
using NAudio.Wave.SampleProviders;

public static class AudioSaving
{
    public static void SaveRealTimeRecordedSongAsFileAndSendToEmail()
    {
        if (RealTimeAudioRecording.instance.recording_result == null) return;

        var user = (string name) => Path.Combine(ProjectSettings.GlobalizePath("user://"), name);
        string sanitizedTime = Time.GetTimeStringFromSystem().Replace(":", "_");
        string final_name = user("export_" + BpmManager.instance.bpm.ToString() + "bpm_" + sanitizedTime);

        // (temporary solution) combine songvoiceover with submaster recording because voice isnt in submaster recording
        ConvertAudioStreamWavToWav(RealTimeAudioRecording.instance.recording_result, final_name + "_a_" + ".wav");
        ConvertAudioStreamWavToWav(SongVoiceOver.instance.voiceOver, final_name + "_b_" + ".wav");
        MixAudioFiles(final_name + "_a_" + ".wav", final_name + "_b_" + ".wav", final_name + ".wav");
        File.Delete(final_name + "_a_" + ".wav");
        File.Delete(final_name + "_b_" + ".wav");

        if (Manager.instance.emailInput.Text != "") SendToEmail(final_name + ".wav", Manager.instance.emailInput.Text);

        Manager.instance.ShowSavingLabel(final_name);
        Manager.instance.hassavedtofile = true;
    }

    public static void SaveRealTimeRecordedBeatAsFileAndSendToEmail()
    {
        if (RealTimeAudioRecording.instance.recording_result == null) return;

        var user = (string name) => Path.Combine(ProjectSettings.GlobalizePath("user://"), name);
        string sanitizedTime = Time.GetTimeStringFromSystem().Replace(":", "_");
        string song_name = user("song_" + BpmManager.instance.bpm.ToString() + "bpm_" + sanitizedTime);
        string final_name = user("export_" + BpmManager.instance.bpm.ToString() + "bpm_" + sanitizedTime);

        // (temporary solution) combine songvoiceover with submaster recording because voice isnt in submaster recording
        ConvertAudioStreamWavToWav(RealTimeAudioRecording.instance.recording_result, song_name + "_a_" + ".wav");
        ConvertAudioStreamWavToWav(SongVoiceOver.instance.voiceOver, song_name + "_b_" + ".wav");
        MixAudioFiles(song_name + "_a_" + ".wav", song_name + "_b_" + ".wav", song_name + ".wav");

        // cut current layer out off song_name
        float timespan = 0;
        using (var reader = new AudioFileReader(song_name + ".wav")) timespan = (float)reader.TotalTime.TotalSeconds;
        float timePerLayer = BpmManager.beatsAmount * BpmManager.instance.baseTimePerBeat;
        float startTime = Manager.instance.currentLayerIndex * timePerLayer;
        float endTime = startTime + timePerLayer;
        TrimWavFile(song_name + ".wav", final_name + ".wav", startTime, endTime);

        // delete temp wav files
        File.Delete(song_name + "_a_" + ".wav");
        File.Delete(song_name + "_b_" + ".wav");
        File.Delete(song_name + ".wav");

        if (Manager.instance.emailInput.Text != "") SendToEmail(final_name + ".wav", Manager.instance.emailInput.Text);

        Manager.instance.ShowSavingLabel(final_name);
        Manager.instance.hassavedtofile = true;
    }

    static void TrimWavFile(string inputPath, string outputPath, double startTime, double endTime)
    {
        using (var reader = new AudioFileReader(inputPath))
        {
            int bytesPerSample = reader.WaveFormat.BitsPerSample / 8 * reader.WaveFormat.Channels;
            int startPos = (int)(startTime * reader.WaveFormat.SampleRate) * bytesPerSample;
            int endPos = (int)(endTime * reader.WaveFormat.SampleRate) * bytesPerSample;

            startPos = Math.Min(startPos, (int)reader.Length);
            endPos = Math.Min(endPos, (int)reader.Length);

            reader.Position = startPos;
            using (var writer = new WaveFileWriter(outputPath, reader.WaveFormat))
            {
                byte[] buffer = new byte[1024];
                while (reader.Position < endPos)
                {
                    int bytesRequired = (int)(endPos - reader.Position);
                    int bytesToRead = Math.Min(bytesRequired, buffer.Length);
                    int bytesRead = reader.Read(buffer, 0, bytesToRead);
                    if (bytesRead == 0) break;
                    writer.Write(buffer, 0, bytesRead);
                }
            }
        }
    }

    private static void MixAudioFiles(string file1, string file2, string outputFile)
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

    private async static void SendToEmail(string final_name, string to)
    {
        Action task = () => EmailSender.SendWav(ProjectSettings.GlobalizePath(final_name), to);
        await Task.Run(task);
    }

    private static void ConvertAudioStreamWavToWav(AudioStreamWav audioStreamWav, string filePath)
    {
        if (audioStreamWav.Stereo) audioStreamWav = ConvertStereoToMono(audioStreamWav);
        byte[] pcmData = audioStreamWav.Data;
        using (var waveFile = new WaveFileWriter(filePath, new WaveFormat(audioStreamWav.MixRate, 16, audioStreamWav.Stereo ? 2 : 1))) waveFile.Write(pcmData, 0, pcmData.Length);
        GD.Print($"WAV file successfully created at: {filePath}");
    }

    private static AudioStreamWav ConvertStereoToMono(AudioStreamWav stereoStream)
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

    /*
    private static void SaveSongAsFileAndSendToEmail(List<bool[,]> loops)
    {
        string sanitizedTime = Time.GetTimeStringFromSystem().Replace(":", "_");

        var user = (string name) => Path.Combine(ProjectSettings.GlobalizePath("user://"), name);

        string final_name = user("export_" + BpmManager.instance.bpm.ToString() + "bpm_" + sanitizedTime);
        string beats_name = user("beats");
        string song_name = user("song");
        string layers0_name = user("layers0");
        string layers1_name = user("layers1");
        string layers_combined_name = user("layers_combined");
        string beats_with_song_name = user("beats_with_song");

        int sampleRate = 48000;
        float secondsPerBeat = BpmManager.instance.baseTimePerBeat * 2;
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
                        AudioStreamWav audioStreamWav = (AudioStreamWav)Manager.instance.mainAudioFiles[ring];
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

        // export layersvoiceovers0 as single wav
        AudioStream[] voiceovers0 = Manager.instance.layerVoiceOver0.layersVoiceOvers;
        for (int i = 0; i < Manager.instance.layersAmount; i++)
        {
            string name = user("layer" + i.ToString() + "a.wav");
            AudioStreamWav audioStreamWav = (AudioStreamWav)voiceovers0[i];
            if (audioStreamWav != null)
            {
                // voice wav
                ConvertAudioStreamWavToWav(audioStreamWav, name);
            }
            else
            {
                // empty wav
                float timepb = BpmManager.instance.baseTimePerBeat * 2;
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
        List<string> layer0_inputs =
        [
            user("layer0a.wav"),
            user("layer1a.wav"),
            user("layer2a.wav"),
            user("layer3a.wav"),
            user("layer4a.wav"),
            user("layer5a.wav"),
            user("layer6a.wav"),
            user("layer7a.wav"),
            user("layer8a.wav"),
            user("layer9a.wav")
        ];
        using (var firstReader = new WaveFileReader(layer0_inputs[0]))
        {
            var waveFormat = firstReader.WaveFormat;
            using (var writer = new WaveFileWriter(layers0_name + ".wav", waveFormat))
            {
                firstReader.CopyTo(writer);
                for (int i = 1; i < layer0_inputs.Count; i++) using (var reader = new WaveFileReader(layer0_inputs[i])) reader.CopyTo(writer);
            }
        }
        for (int i = 0; i < layer0_inputs.Count; i++) File.Delete(layer0_inputs[i]);

        // export layersvoiceovers1 as single wav
        AudioStream[] voiceovers1 = Manager.instance.layerVoiceOver1.layersVoiceOvers;
        for (int i = 0; i < Manager.instance.layersAmount; i++)
        {
            string name = user("layer" + i.ToString() + "b.wav");
            AudioStreamWav audioStreamWav = (AudioStreamWav)voiceovers1[i];
            if (audioStreamWav != null)
            {
                // voice wav
                ConvertAudioStreamWavToWav(audioStreamWav, name);
            }
            else
            {
                // empty wav
                float timepb = BpmManager.instance.baseTimePerBeat;
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
        List<string> layer1_inputs =
        [
            user("layer0b.wav"),
            user("layer1b.wav"),
            user("layer2b.wav"),
            user("layer3b.wav"),
            user("layer4b.wav"),
            user("layer5b.wav"),
            user("layer6b.wav"),
            user("layer7b.wav"),
            user("layer8b.wav"),
            user("layer9b.wav")
        ];
        using (var firstReader = new WaveFileReader(layer1_inputs[0]))
        {
            var waveFormat = firstReader.WaveFormat;
            using (var writer = new WaveFileWriter(layers1_name + ".wav", waveFormat))
            {
                firstReader.CopyTo(writer);
                for (int i = 1; i < layer1_inputs.Count; i++) using (var reader = new WaveFileReader(layer1_inputs[i])) reader.CopyTo(writer);
            }
        }
        for (int i = 0; i < layer1_inputs.Count; i++) File.Delete(layer1_inputs[i]);

        // mixing
        var song = (AudioStreamWav)SongVoiceOver.instance.voiceOver;
        if (song != null)
        {
            ConvertAudioStreamWavToWav(song, song_name + ".wav");
            MixAudioFiles(beats_name + ".wav", song_name + ".wav", beats_with_song_name + ".wav");
        }
        else
        {
            File.Move(beats_name + ".wav", beats_with_song_name + ".wav");
        }
        MixAudioFiles(layers0_name + ".wav", layers1_name + ".wav", layers_combined_name + ".wav");
        MixAudioFiles(beats_with_song_name + ".wav", layers_combined_name + ".wav", final_name + ".wav");

        // delete temps
        File.Delete(beats_name + ".wav");
        File.Delete(layers0_name + ".wav");
        File.Delete(layers1_name + ".wav");
        File.Delete(layers_combined_name + ".wav");
        if (song != null) File.Delete(song_name + ".wav");
        File.Delete(beats_with_song_name + ".wav");

        Manager.instance.ShowSavingLabel(final_name);
        Manager.instance.hassavedtofile = true;

        if (Manager.instance.emailInput.Text != "") SendToEmail(final_name + ".wav", Manager.instance.emailInput.Text);
    }

    private static void ChangePitch(string filePath, float pitchFactor)
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

    private static AudioStreamWav ChangeSampleRate(AudioStreamWav audioStream, int newSampleRate)
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
    */

    /*
    public static void SaveBeatAsFile(bool[,] loop)
    {
        string sanitizedTime = Time.GetTimeStringFromSystem().Replace(":", "_");
        string filename = "beat_" + BpmManager.instance.bpm.ToString() + "bpm_" + sanitizedTime;

        int sampleRate = 48000;
        float secondsPerBeat = BpmManager.instance.baseTimePerBeat * 2;
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
                    AudioStreamWav audioStreamWav = (AudioStreamWav)Manager.instance.mainAudioFiles[ring];
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

        // finish
        Manager.instance.ShowSavingLabel(filename);
        Manager.instance.hassavedtofile = true;
    }
    */
}