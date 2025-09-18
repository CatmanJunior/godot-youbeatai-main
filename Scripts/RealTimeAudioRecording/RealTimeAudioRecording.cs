using Godot;

using System;
using System.IO;
using System.Threading.Tasks;
using System.Collections.Generic;

using NAudio.Wave;
using NAudio.Wave.SampleProviders;

public static class RealTimeAudioRecording
{
    public static AudioStreamWav recording_result = null;
    public static AudioEffectRecord audioEffectRecord;

    public static bool recording = false;
    public static float recordingTimer = 0;

    public static void Initialize()
    {
        var masterAudioBus = AudioServer.GetBusIndex("Master");
        audioEffectRecord = (AudioEffectRecord)AudioServer.GetBusEffect(masterAudioBus, 0);
    }

    public static void Update(float delta)
    {
        if (recording) recordingTimer += (float)delta;
        else recordingTimer = 0;

        if (recording) GD.Print("Recording Master: " + recordingTimer.ToString("0.0") + " seconds");

        if (Input.IsActionJustPressed("f1"))
        {
            if (!recording) StartRecordingMaster();
            else StopRecordingMaster();
        }
    }

    public static void StartRecordingMaster()
    {
        GD.Print("Starting Recording");
        recording = true;
        audioEffectRecord.SetRecordingActive(true);
    }

    public static void StopRecordingMaster()
    {
        GD.Print("Stopping Recording");
        recording = false;
        audioEffectRecord.SetRecordingActive(false);
        recording_result = audioEffectRecord.GetRecording();

        // output recording as wav file
        var time = Time.GetDatetimeStringFromSystem();
        ConvertAudioStreamWavToWav(recording_result, $"master_recording_{time}.wav");
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
}