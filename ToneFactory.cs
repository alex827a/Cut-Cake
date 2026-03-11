using Godot;

public static class ToneFactory
{
    public static AudioStreamWav CreateTone(float frequencyHz, float durationSeconds, float amplitude = 0.22f)
    {
        const int sampleRate = 44100;

        var sampleCount = Mathf.Max(1, Mathf.RoundToInt(sampleRate * durationSeconds));
        var data = new byte[sampleCount * 2];
        var fadeInSamples = Mathf.Max(1, Mathf.RoundToInt(sampleRate * 0.01f));
        var fadeOutSamples = Mathf.Max(1, Mathf.RoundToInt(sampleRate * 0.03f));

        for (var i = 0; i < sampleCount; i++)
        {
            var t = i / (float)sampleRate;
            var sampleValue = Mathf.Sin(Mathf.Tau * frequencyHz * t);

            var envelope = 1.0f;
            if (i < fadeInSamples)
            {
                envelope = i / (float)fadeInSamples;
            }

            var samplesFromEnd = sampleCount - i;
            if (samplesFromEnd < fadeOutSamples)
            {
                envelope = Mathf.Min(envelope, samplesFromEnd / (float)fadeOutSamples);
            }

            var pcmValue = (short)(sampleValue * envelope * amplitude * short.MaxValue);
            data[i * 2] = (byte)(pcmValue & 0xff);
            data[(i * 2) + 1] = (byte)((pcmValue >> 8) & 0xff);
        }

        return new AudioStreamWav
        {
            Format = AudioStreamWav.FormatEnum.Format16Bits,
            MixRate = sampleRate,
            Stereo = false,
            Data = data
        };
    }

    public static AudioStreamWav CreateCakeStackSound()
    {
        const int sampleRate = 44100;
        const float durationSeconds = 0.16f;

        var sampleCount = Mathf.Max(1, Mathf.RoundToInt(sampleRate * durationSeconds));
        var data = new byte[sampleCount * 2];
        var fadeInSamples = Mathf.Max(1, Mathf.RoundToInt(sampleRate * 0.004f));
        var fadeOutSamples = Mathf.Max(1, Mathf.RoundToInt(sampleRate * 0.085f));

        for (var i = 0; i < sampleCount; i++)
        {
            var t = i / (float)sampleRate;

            var thump = Mathf.Sin(Mathf.Tau * 180.0f * t) * Mathf.Exp(-t * 26.0f) * 0.32f;
            var body = Mathf.Sin(Mathf.Tau * 520.0f * t) * Mathf.Exp(-t * 13.0f) * 0.18f;
            var sparkle = Mathf.Sin(Mathf.Tau * 860.0f * t) * Mathf.Exp(-t * 19.0f) * 0.08f;
            var sampleValue = thump + body + sparkle;

            var envelope = 1.0f;
            if (i < fadeInSamples)
            {
                envelope = i / (float)fadeInSamples;
            }

            var samplesFromEnd = sampleCount - i;
            if (samplesFromEnd < fadeOutSamples)
            {
                envelope = Mathf.Min(envelope, samplesFromEnd / (float)fadeOutSamples);
            }

            var filtered = Mathf.Tanh(sampleValue * 1.35f) * envelope * 0.42f;
            var pcmValue = (short)(filtered * short.MaxValue);
            data[i * 2] = (byte)(pcmValue & 0xff);
            data[(i * 2) + 1] = (byte)((pcmValue >> 8) & 0xff);
        }

        return new AudioStreamWav
        {
            Format = AudioStreamWav.FormatEnum.Format16Bits,
            MixRate = sampleRate,
            Stereo = false,
            Data = data
        };
    }

    public static AudioStreamWav CreateGentleWinSound()
    {
        return CreateSoftChord(new[] { 392.0f, 493.88f, 587.33f }, 0.24f, 0.16f);
    }

    public static AudioStreamWav CreateGentleLoseSound()
    {
        return CreateSoftChord(new[] { 220.0f, 196.0f }, 0.28f, 0.12f);
    }

    public static AudioStreamWav CreateMenuClickSound()
    {
        const int sampleRate = 44100;
        const float durationSeconds = 0.1f;

        var sampleCount = Mathf.Max(1, Mathf.RoundToInt(sampleRate * durationSeconds));
        var data = new byte[sampleCount * 2];
        var fadeInSamples = Mathf.Max(1, Mathf.RoundToInt(sampleRate * 0.004f));
        var fadeOutSamples = Mathf.Max(1, Mathf.RoundToInt(sampleRate * 0.06f));

        for (var i = 0; i < sampleCount; i++)
        {
            var t = i / (float)sampleRate;
            var low = Mathf.Sin(Mathf.Tau * 280.0f * t) * Mathf.Exp(-t * 24.0f) * 0.18f;
            var mid = Mathf.Sin(Mathf.Tau * 420.0f * t) * Mathf.Exp(-t * 18.0f) * 0.11f;
            var sampleValue = low + mid;

            var envelope = 1.0f;
            if (i < fadeInSamples)
            {
                envelope = i / (float)fadeInSamples;
            }

            var samplesFromEnd = sampleCount - i;
            if (samplesFromEnd < fadeOutSamples)
            {
                envelope = Mathf.Min(envelope, samplesFromEnd / (float)fadeOutSamples);
            }

            var filtered = Mathf.Tanh(sampleValue * 1.1f) * envelope * 0.34f;
            var pcmValue = (short)(filtered * short.MaxValue);
            data[i * 2] = (byte)(pcmValue & 0xff);
            data[(i * 2) + 1] = (byte)((pcmValue >> 8) & 0xff);
        }

        return new AudioStreamWav
        {
            Format = AudioStreamWav.FormatEnum.Format16Bits,
            MixRate = sampleRate,
            Stereo = false,
            Data = data
        };
    }

    private static AudioStreamWav CreateSoftChord(float[] frequencies, float durationSeconds, float amplitude)
    {
        const int sampleRate = 44100;

        var sampleCount = Mathf.Max(1, Mathf.RoundToInt(sampleRate * durationSeconds));
        var data = new byte[sampleCount * 2];
        var fadeInSamples = Mathf.Max(1, Mathf.RoundToInt(sampleRate * 0.008f));
        var fadeOutSamples = Mathf.Max(1, Mathf.RoundToInt(sampleRate * 0.12f));

        for (var i = 0; i < sampleCount; i++)
        {
            var t = i / (float)sampleRate;
            var sampleValue = 0.0f;

            for (var toneIndex = 0; toneIndex < frequencies.Length; toneIndex++)
            {
                var detune = 1.0f + (toneIndex * 0.0035f);
                sampleValue += Mathf.Sin(Mathf.Tau * frequencies[toneIndex] * detune * t) * Mathf.Exp(-t * (5.5f + toneIndex));
            }

            sampleValue /= Mathf.Max(1, frequencies.Length);

            var envelope = 1.0f;
            if (i < fadeInSamples)
            {
                envelope = i / (float)fadeInSamples;
            }

            var samplesFromEnd = sampleCount - i;
            if (samplesFromEnd < fadeOutSamples)
            {
                envelope = Mathf.Min(envelope, samplesFromEnd / (float)fadeOutSamples);
            }

            var filtered = Mathf.Tanh(sampleValue * 0.9f) * envelope * amplitude;
            var pcmValue = (short)(filtered * short.MaxValue);
            data[i * 2] = (byte)(pcmValue & 0xff);
            data[(i * 2) + 1] = (byte)((pcmValue >> 8) & 0xff);
        }

        return new AudioStreamWav
        {
            Format = AudioStreamWav.FormatEnum.Format16Bits,
            MixRate = sampleRate,
            Stereo = false,
            Data = data
        };
    }
}
