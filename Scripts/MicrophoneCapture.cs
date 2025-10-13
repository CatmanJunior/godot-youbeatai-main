using Godot;
using System;
using System.Numerics;

public partial class MicrophoneCapture : Node
{
    public static MicrophoneCapture instance = null;

    public override void _ExitTree()
    {
        if (instance == this) instance = null;
    }

	[Export] string busName = "Microphone";
	
    private AudioEffectCapture audioEffectCapture;
    private AudioStreamPlayer audioStreamPlayer;

    public float volume = 0;
    public float frequency = 0;
    
    [Signal]
    public delegate void OnMicrophoneInputEventHandler(float volume, float frequency);

    public override void _Ready()
    {
        instance ??= this;

        audioStreamPlayer = new AudioStreamPlayer();
        AddChild(audioStreamPlayer);
        audioStreamPlayer.Finished += () => audioStreamPlayer.Play();

        audioStreamPlayer.Stream = new AudioStreamMicrophone();

        audioStreamPlayer.Bus = busName;
        audioEffectCapture = (AudioEffectCapture)AudioServer.GetBusEffect(AudioServer.GetBusIndex(busName), 0);

        audioStreamPlayer.Play();
    }

    public override void _Process(double delta)
    {
		var frames = audioEffectCapture.GetFramesAvailable();
        if (frames > 0)
        {
            Godot.Vector2[] audioData = audioEffectCapture.GetBuffer(frames);
            volume = GetVolumeFromAudioData(audioData);
            frequency = GetPeakFrequency(PerformFFT(ConvertToMono(audioData)));

            // Call signal
            EmitSignal(SignalName.OnMicrophoneInput, volume, frequency);
		}
    }

    private float[] ConvertToMono(Godot.Vector2[] audioData)
    {
        // Convert stereo (Vector2) to mono by averaging the left and right channels (X and Y)
        float[] monoData = new float[audioData.Length];
        for (int i = 0; i < audioData.Length; i++)
        {
            monoData[i] = (audioData[i].X + audioData[i].Y) / 2f; // Average the stereo channels
        }
        return monoData;
    }

    private float GetVolumeFromAudioData(Godot.Vector2[] audioData)
    {
        float sum = 0f;
        foreach (Godot.Vector2 sample in audioData)
        {
            float averageSample = (Mathf.Abs(sample.X) + Mathf.Abs(sample.Y)) / 2;
            sum += averageSample;
        }
        return sum / audioData.Length;
    }

    private int GetNextPowerOf2(int n)
    {
        // Find the next power of 2 greater than or equal to n
        int powerOf2 = 1;
        while (powerOf2 < n)
        {
            powerOf2 <<= 1;  // Double the value (same as powerOf2 *= 2)
        }
        return powerOf2;
    }

    private float[] PerformFFT(float[] audioData)
    {
        // Check if the data length is a power of 2
        int N = audioData.Length;
        int nextPowerOf2 = GetNextPowerOf2(N);

        // If the length is not a power of 2, pad with zeros
        if (N != nextPowerOf2)
        {
            float[] paddedData = new float[nextPowerOf2];
            Array.Copy(audioData, paddedData, N);  // Copy original data into padded array
            audioData = paddedData;  // Update audioData to be padded
        }

        // Convert audioData to complex numbers
        Complex[] complexData = new Complex[audioData.Length];
        for (int i = 0; i < audioData.Length; i++)
        {
            complexData[i] = new Complex(audioData[i], 0);  // Imaginary part is 0
        }

        // Perform the FFT
        FFT(complexData);

        // Calculate magnitudes from complex numbers
        float[] magnitudes = new float[audioData.Length / 2];
        for (int i = 0; i < audioData.Length / 2; i++)
        {
            magnitudes[i] = (float)complexData[i].Magnitude;
        }

        return magnitudes;
    }

    private void FFT(Complex[] data)
    {
        int N = data.Length;
        if (N <= 1) return;

        // Split the data into even and odd parts
        Complex[] even = new Complex[N / 2];
        Complex[] odd = new Complex[N / 2];

        for (int i = 0; i < N / 2; i++)
        {
            even[i] = data[2 * i];
            odd[i] = data[2 * i + 1];
        }

        // Recursively apply FFT to the even and odd parts
        FFT(even);
        FFT(odd);

        // Combine the results
        for (int i = 0; i < N / 2; i++)
        {
            Complex t = Complex.Exp(new Complex(0, -2 * Math.PI * i / N)) * odd[i];
            data[i] = even[i] + t;
            data[i + N / 2] = even[i] - t;
        }
    }

    private float GetPeakFrequency(float[] frequencySpectrum)
    {
        // Find the index of the highest value in the frequency spectrum array
        int peakIndex = 0;
        float maxValue = 0f;
        for (int i = 0; i < frequencySpectrum.Length; i++)
        {
            if (frequencySpectrum[i] > maxValue)
            {
                maxValue = frequencySpectrum[i];
                peakIndex = i;
            }
        }
        
        // Assuming you know the sample rate, calculate the frequency based on the index
        float sampleRate = 44100f; // Set to the appropriate sample rate of your microphone input
        float frequency = peakIndex * (sampleRate / frequencySpectrum.Length);
        return frequency;
    }
}