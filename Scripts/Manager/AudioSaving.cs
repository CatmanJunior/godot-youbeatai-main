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
        var path = SaveRealTimeRecordedSongAsFile();
        if (path != null)
        {
            if (Manager.instance.emailInput.Text != "") SendToEmail(path, Manager.instance.emailInput.Text);
            Manager.instance.ShowSavingLabel(path);
            Manager.instance.hassavedtofile = true;
        }
    }

    public static void SaveRealTimeRecordedBeatAsFileAndSendToEmail()
    {
        var path = SaveRealTimeRecordedBeatAsFile();
        if (path != null)
        {
            if (Manager.instance.emailInput.Text != "") SendToEmail(path, Manager.instance.emailInput.Text);
            Manager.instance.ShowSavingLabel(path);
            Manager.instance.hassavedtofile = true;
        }
    }

    public static string SaveRealTimeRecordedSongAsFile()
    {
        if (RealTimeAudioRecording.instance.recording_result == null) return null;

        var user = (string name) => Path.Combine(ProjectSettings.GlobalizePath("user://"), name);
        string sanitizedTime = Time.GetTimeStringFromSystem().Replace(":", "_");
        string final_name = user("export_" + BpmManager.instance.bpm.ToString() + "bpm_" + sanitizedTime);

        // (temporary solution) combine songvoiceover with submaster recording because voice isnt in submaster recording
        ConvertAudioStreamWavToWav(RealTimeAudioRecording.instance.recording_result, final_name + "_a_" + ".wav");
        ConvertAudioStreamWavToWav(SongVoiceOver.instance.voiceOver, final_name + "_b_" + ".wav");
        MixAudioFiles(final_name + "_a_" + ".wav", final_name + "_b_" + ".wav", final_name + ".wav");

        // delete temp wav files
        File.Delete(final_name + "_a_" + ".wav");
        File.Delete(final_name + "_b_" + ".wav");

        return final_name + ".wav";
    }

    public static string SaveRealTimeRecordedBeatAsFile()
    {
        if (RealTimeAudioRecording.instance.recording_result == null) return null;

        var user = (string name) => Path.Combine(ProjectSettings.GlobalizePath("user://"), name);
        string sanitizedTime = Time.GetTimeStringFromSystem().Replace(":", "_");
        string song_name = user("song_" + BpmManager.instance.bpm.ToString() + "bpm_" + sanitizedTime);
        string final_name = user("export_" + BpmManager.instance.bpm.ToString() + "bpm_" + sanitizedTime);

        // (temporary solution) combine songvoiceover with submaster recording because voice isnt in submaster recording
        ConvertAudioStreamWavToWav(RealTimeAudioRecording.instance.recording_result, song_name + "_a_" + ".wav");
        ConvertAudioStreamWavToWav(SongVoiceOver.instance.voiceOver, song_name + "_b_" + ".wav");
        MixAudioFiles(song_name + "_a_" + ".wav", song_name + "_b_" + ".wav", song_name + ".wav");

        // cut current layer out off song_name
        float timePerLayer = BpmManager.beatsAmount * BpmManager.instance.baseTimePerBeat;
        float startTime = Manager.instance.currentLayerIndex * timePerLayer;
        float endTime = startTime + timePerLayer;
        TrimWavFile(song_name + ".wav", final_name + ".wav", startTime, endTime);

        // delete temp wav files
        File.Delete(song_name + "_a_" + ".wav");
        File.Delete(song_name + "_b_" + ".wav");
        File.Delete(song_name + ".wav");

        return final_name + ".wav";
    }

    public static void RemoveLayerPartOfRecordings(int layer)
    {
        var user = (string name) => Path.Combine(ProjectSettings.GlobalizePath("user://"), name);
        string sanitizedTime = Time.GetTimeStringFromSystem().Replace(":", "_");

        // define wav file names and paths
        string realtime_old = user($"realtime_{sanitizedTime}_temp_old.wav");
        string song_old = user($"song_{sanitizedTime}_temp_old.wav");
        string realtime_new = user($"realtime_{sanitizedTime}_temp_new.wav");
        string song_new = user($"song_{sanitizedTime}_temp_new.wav");
        
        // audiostreams to wavs
        ConvertAudioStreamWavToWav(RealTimeAudioRecording.instance.recording_result, realtime_old);
        ConvertAudioStreamWavToWav(SongVoiceOver.instance.voiceOver, song_old);

        // calculate timing for part to cut out
        float timePerLayer = BpmManager.beatsAmount * BpmManager.instance.baseTimePerBeat;
        float startTime = layer * timePerLayer;
        float endTime = startTime + timePerLayer;
        
        // remove segments from wav files
        RemoveSegmentFromWavFile(realtime_old, realtime_new, startTime, endTime);
        RemoveSegmentFromWavFile(song_old, song_new, startTime, endTime);

        // wavs back to audiostreams
        RealTimeAudioRecording.instance.recording_result = AudioStreamWav.LoadFromFile(realtime_new);
        SongVoiceOver.instance.voiceOver = AudioStreamWav.LoadFromFile(song_new);

        // update voice audioplayer stream
        var wasplaying = SongVoiceOver.instance.audioPlayer.Playing;
        SongVoiceOver.instance.audioPlayer.Stream = SongVoiceOver.instance.voiceOver;
        if (wasplaying) SongVoiceOver.instance.audioPlayer.Play();

        // change recording length
        RealTimeAudioRecording.instance.recordingLength = (float)RealTimeAudioRecording.instance.recording_result.GetLength();
        SongVoiceOver.instance.recordingLength = (float)SongVoiceOver.instance.voiceOver.GetLength();

        // delete wavs
        File.Delete(realtime_old);
        File.Delete(song_old);
        File.Delete(realtime_new);
        File.Delete(song_new);
    }

    public static void InsertSilentLayerPartOfRecordings(int layer)
    {
        var user = (string name) => Path.Combine(ProjectSettings.GlobalizePath("user://"), name);
        string sanitizedTime = Time.GetTimeStringFromSystem().Replace(":", "_");

        // define wav file names and paths
        string realtime_old = user($"realtime_{sanitizedTime}_temp_old.wav");
        string song_old = user($"song_{sanitizedTime}_temp_old.wav");
        string realtime_new = user($"realtime_{sanitizedTime}_temp_new.wav");
        string song_new = user($"song_{sanitizedTime}_temp_new.wav");

        // convert AudioStreamWav -> WAV
        ConvertAudioStreamWavToWav(RealTimeAudioRecording.instance.recording_result, realtime_old);
        ConvertAudioStreamWavToWav(SongVoiceOver.instance.voiceOver, song_old);

        // calculate timing for insertion
        float timePerLayer = BpmManager.beatsAmount * BpmManager.instance.baseTimePerBeat;
        float insertTime = layer * timePerLayer;

        // insert silence into both files
        InsertSilenceIntoWavFile(realtime_old, realtime_new, insertTime, timePerLayer);
        InsertSilenceIntoWavFile(song_old, song_new, insertTime, timePerLayer);

        // wavs back to AudioStreamWav
        RealTimeAudioRecording.instance.recording_result = AudioStreamWav.LoadFromFile(realtime_new);
        SongVoiceOver.instance.voiceOver = AudioStreamWav.LoadFromFile(song_new);

        // update voice audioplayer stream
        var wasplaying = SongVoiceOver.instance.audioPlayer.Playing;
        SongVoiceOver.instance.audioPlayer.Stream = SongVoiceOver.instance.voiceOver;
        if (wasplaying) SongVoiceOver.instance.audioPlayer.Play();

        // update lengths
        RealTimeAudioRecording.instance.recordingLength = (float)RealTimeAudioRecording.instance.recording_result.GetLength();
        SongVoiceOver.instance.recordingLength = (float)SongVoiceOver.instance.voiceOver.GetLength();

        // delete temp wavs
        File.Delete(realtime_old);
        File.Delete(song_old);
        File.Delete(realtime_new);
        File.Delete(song_new);
    }

    public static void CombineWavFiles(string file1, string file2, string outputFile)
    {
        using var reader1 = new AudioFileReader(file1);
        using var reader2 = new AudioFileReader(file2);
        using var writer = new WaveFileWriter(outputFile, reader1.WaveFormat);
        
        float[] buffer = new float[1024];
        int read;

        // copy first file contents
        while ((read = reader1.Read(buffer, 0, buffer.Length)) > 0) writer.WriteSamples(buffer, 0, read);

        // copy second file contents
        while ((read = reader2.Read(buffer, 0, buffer.Length)) > 0) writer.WriteSamples(buffer, 0, read);
    }

    // removes a specific segment in the middle from a wav file. making the total wav length shorter
    public static void RemoveSegmentFromWavFile(string inputPath, string outputPath, double startTime, double endTime)
    {
        using var reader = new AudioFileReader(inputPath);
        using var writer = new WaveFileWriter(outputPath, reader.WaveFormat);

        int bytesPerSecond = reader.WaveFormat.AverageBytesPerSecond;
        long startPos = (long)(startTime * bytesPerSecond);
        long endPos = (long)(endTime * bytesPerSecond);

        startPos = Math.Min(startPos, reader.Length);
        endPos = Math.Min(endPos, reader.Length);

        // copy everything before the segment
        reader.Position = 0;
        CopyBytes(reader, writer, startPos);

        // skip the unwanted segment
        reader.Position = endPos;

        // copy everything after the segment
        reader.CopyTo(writer);
    }

    public static void InsertSilenceIntoWavFile(string inputPath, string outputPath, double insertTime, double silenceDuration)
    {
        using var reader = new AudioFileReader(inputPath);
        using var writer = new WaveFileWriter(outputPath, reader.WaveFormat);

        int bytesPerSecond = reader.WaveFormat.AverageBytesPerSecond;
        long insertPos = (long)(insertTime * bytesPerSecond);
        insertPos = Math.Min(insertPos, reader.Length);

        // copy everything before the insert position
        reader.Position = 0;
        CopyBytes(reader, writer, insertPos);

        // generate silence buffer (all zeros)
        int silenceBytes = (int)(silenceDuration * bytesPerSecond);
        byte[] silenceBuffer = new byte[silenceBytes];
        writer.Write(silenceBuffer, 0, silenceBuffer.Length);

        // copy everything after the insert position
        reader.CopyTo(writer);
    }

    private static void CopyBytes(Stream input, Stream output, long bytesToCopy)
    {
        byte[] buffer = new byte[8192];
        while (bytesToCopy > 0)
        {
            int toRead = (int)Math.Min(buffer.Length, bytesToCopy);
            int read = input.Read(buffer, 0, toRead);
            if (read == 0) break;
            output.Write(buffer, 0, read);
            bytesToCopy -= read;
        }
    }

    public static void TrimWavFile(string inputPath, string outputPath, double startTime, double endTime)
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

    public static void MixAudioFiles(string file1, string file2, string outputFile)
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

    public static void ConvertAudioStreamWavToWav(AudioStreamWav audioStreamWav, string filePath)
    {
        if (audioStreamWav.Stereo) audioStreamWav = ConvertStereoToMono(audioStreamWav);
        byte[] pcmData = audioStreamWav.Data;
        using (var waveFile = new WaveFileWriter(filePath, new WaveFormat(audioStreamWav.MixRate, 16, audioStreamWav.Stereo ? 2 : 1)))
        {
            waveFile.Write(pcmData, 0, pcmData.Length);
            waveFile.Close();
        }
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
}