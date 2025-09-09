using Godot;

public partial class Manager : Node
{
    public enum ChaosPadMode
    {
        SampleMixing,
        SynthMixing
    }

    // chaos pad
    [Export] public Node2D[] corners = new Node2D[3]; // left, top, right
    [Export] public Node2D knob;
    [Export] public Sprite2D chaosPadTriangleSprite;
    [Export] public Label iconMain;
    [Export] public Label iconAlt;
    public Vector3 weights;
    public float outerTriangleSize = 40;
    public ChaosPadMode chaosPadMode = ChaosPadMode.SampleMixing;
    [Export] public Node2D micButtonLocation;

    #region SamplesMixing

    // sample mixing specifics
    private Vector2[] SamplesMixing_knobPositions = new Vector2[40];
    private Vector2[] SamplesMixing_knobPositionsClipboard = new Vector2[4];
    public int SamplesMixing_activeRing = 0;

    public void SamplesMixing_RememberKnobsForLayer()
    {
        // remember knob of active ring
        SamplesMixing_knobPositions[(currentLayerIndex * 4) + SamplesMixing_activeRing] = knob.GlobalPosition;
    }

    public void SamplesMixing_ReApplyKnobsForLayer()
    {
        // reapply knob of active ring
        knob.GlobalPosition = SamplesMixing_knobPositions[(currentLayerIndex * 4) + SamplesMixing_activeRing];
    }

    public void SamplesMixing_CopyKnobsForLayer(){}
    public void SamplesMixing_PasteKnobsLayer(){}
    public void SamplesMixing_ClearKnobsForLayer(){}

    public void SamplesMixing_ChangeRing(int newring)
    {
        // save knob position
        SamplesMixing_knobPositions[(currentLayerIndex * 4) + SamplesMixing_activeRing] = knob.GlobalPosition;

        // switch ring
        SamplesMixing_activeRing = newring;

        // remember knob position
        knob.GlobalPosition = SamplesMixing_knobPositions[(currentLayerIndex * 4) + SamplesMixing_activeRing];

        // set chaos pad color to active ring
        SamplesMixing_StartTriangleColorChange(0.2f);

        // update icons
        if (SamplesMixing_activeRing == 0)
        {
            iconMain.Text = "👞";
            iconAlt.Text = "👟";
        }
        if (SamplesMixing_activeRing == 1)
        {
            iconMain.Text = "👏";
            iconAlt.Text = "🥊";
        }
        if (SamplesMixing_activeRing == 2)
        {
            iconMain.Text = "📣";
            iconAlt.Text = "📢";
        }
        if (SamplesMixing_activeRing == 3)
        {
            iconMain.Text = "⌚";
            iconAlt.Text = "⏰";
        }

        // set mic button location
        Node2D[] micButtons = 
        [
            recordSampleButton0, 
            recordSampleButton1, 
            recordSampleButton2, 
            recordSampleButton3, 
            (Node2D)layerVoiceOver0.recordLayerButton.GetParent(), 
            (Node2D)layerVoiceOver1.recordLayerButton.GetParent()
        ];
        for (int i = 0; i < micButtons.Length; i++) micButtons[i].GlobalPosition = new Vector2(-500, 500);
        micButtons[SamplesMixing_activeRing].GlobalPosition = micButtonLocation.GlobalPosition;

        // set chaospad mode
        chaosPadMode = ChaosPadMode.SampleMixing;
    }

    async private void SamplesMixing_StartTriangleColorChange(float duration)
    {
        var old_color = chaosPadTriangleSprite.SelfModulate;
        var old_color_v3 = new Vector3(old_color.R, old_color.G, old_color.B);
        var new_color = colors[SamplesMixing_activeRing];
        var new_color_v3 = new Vector3(new_color.R, new_color.G, new_color.B);

        float elapsed = 0f;

        while (elapsed < duration)
        {
            float t = elapsed / duration;
            Vector3 lerped = old_color_v3.Lerp(new_color_v3, t);
            chaosPadTriangleSprite.SelfModulate = new Color(lerped.X, lerped.Y, lerped.Z, 1);

            // yield one frame
            await ToSignal(GetTree(), "process_frame");

            elapsed += (float)GetProcessDeltaTime();
        }

        // ensure final color is set
        chaosPadTriangleSprite.SelfModulate = new_color;
    }

    private void SamplesMixing_UpdateMixingVolumesForRing(int ring, float mastervolume)
    {
        float mainvolume = weights.X * mastervolume;
        float recvolume  = weights.Y * mastervolume;
        float altvolume  = weights.Z * mastervolume;

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

    #endregion

    #region SynthMixing

    private Vector2[] SynthMixing_knobPositions = new Vector2[2];
    public int SynthMixing_activeSynth = 0;

    public void SynthMixing_ChangeSynth(int synth)
    {
        // save knob position
        SynthMixing_knobPositions[SynthMixing_activeSynth] = knob.GlobalPosition;

        // switch synth
        SynthMixing_activeSynth = synth;

        // remember knob position
        knob.GlobalPosition = SynthMixing_knobPositions[SynthMixing_activeSynth];

        // set chaos pad color to active ring
        SynthMixing_StartTriangleColorChange(0.2f);

        // update icons
        if (SynthMixing_activeSynth == 0)
        {
            iconMain.Text = "🟢";
            iconAlt.Text = "🎹";
        }
        if (SynthMixing_activeSynth == 1)
        {
            iconMain.Text = "🟣";
            iconAlt.Text = "🎹";
        }

        // set mic button location
        Node2D[] micButtons = 
        [
            recordSampleButton0, 
            recordSampleButton1, 
            recordSampleButton2, 
            recordSampleButton3, 
            (Node2D)layerVoiceOver0.recordLayerButton.GetParent(), 
            (Node2D)layerVoiceOver1.recordLayerButton.GetParent()
        ];
        for (int i = 0; i < micButtons.Length; i++) micButtons[i].GlobalPosition = new Vector2(-500, 500);
        micButtons[4 + SynthMixing_activeSynth].GlobalPosition = micButtonLocation.GlobalPosition;

        // set chaospad mode
        chaosPadMode = ChaosPadMode.SynthMixing;
    }

    async private void SynthMixing_StartTriangleColorChange(float duration)
    {
        var old_color = chaosPadTriangleSprite.SelfModulate;
        var old_color_v3 = new Vector3(old_color.R, old_color.G, old_color.B);

        var new_color = new Color();
        if (SynthMixing_activeSynth == 0) new_color = Color.FromHtml("#25cc00");
        if (SynthMixing_activeSynth == 1) new_color = Color.FromHtml("#aa00ff");

        var new_color_v3 = new Vector3(new_color.R, new_color.G, new_color.B);

        float elapsed = 0f;

        while (elapsed < duration)
        {
            float t = elapsed / duration;
            Vector3 lerped = old_color_v3.Lerp(new_color_v3, t);
            chaosPadTriangleSprite.SelfModulate = new Color(lerped.X, lerped.Y, lerped.Z, 1);

            // yield one frame
            await ToSignal(GetTree(), "process_frame");

            elapsed += (float)GetProcessDeltaTime();
        }

        // ensure final color is set
        chaosPadTriangleSprite.SelfModulate = new_color;
    }

    private void SynthMixing_UpdateMixingVolumesForSynth(int synth, float mastervolume)
    {
        if (synth == 0)
        {
            layerVoiceOver0.audioPlayer.VolumeLinear = weights.Y * mastervolume * 1.5f;
            GetNode<Node>("/root/scene/Managers/LayerVoiceOver0/VoiceRecorder").Set("volume", weights.Z * mastervolume);
        }
        if (synth == 1)
        {
            layerVoiceOver1.audioPlayer.VolumeLinear = weights.Y * mastervolume * 1.5f;
            GetNode<Node>("/root/scene/Managers/LayerVoiceOver1/VoiceRecorder").Set("volume", weights.Z * mastervolume);
        }
    }

    #endregion

    private void OnReadyMixing()
    {
        for (int i = 0; i < SamplesMixing_knobPositions.Length; i++) SamplesMixing_knobPositions[i] = chaosPadTriangleSprite.GlobalPosition;
        for (int i = 0; i < SamplesMixing_knobPositionsClipboard.Length; i++) SamplesMixing_knobPositionsClipboard[i] = chaosPadTriangleSprite.GlobalPosition;
        for (int i = 0; i < SynthMixing_knobPositions.Length; i++) SynthMixing_knobPositions[i] = chaosPadTriangleSprite.GlobalPosition;

        if (chaosPadMode == ChaosPadMode.SampleMixing) SamplesMixing_ChangeRing(0);
        else if (chaosPadMode == ChaosPadMode.SynthMixing) SynthMixing_ChangeSynth(0);
    }

    private void OnUpdateMixing(float delta)
    {
        // inner triangle blending
        weights = GetBarycentricWeights
        (
            knob.GlobalPosition,
            corners[0].GlobalPosition,
            corners[1].GlobalPosition,
            corners[2].GlobalPosition
        );

        // outer triangle effects master volume
        float mastervolume = IsInsideTriangle(weights) ? 1f : MasterVolumeFromDistance(knob.GlobalPosition, corners[0].GlobalPosition, corners[1].GlobalPosition, corners[2].GlobalPosition);

        // clamp weights
        weights = new Vector3
        (
            Mathf.Clamp(weights.X, 0f, 1f),
            Mathf.Clamp(weights.Y, 0f, 1f),
            Mathf.Clamp(weights.Z, 0f, 1f)
        );

        // debug
        if (Input.IsKeyPressed(Key.P)) GD.Print($"weights: {weights.X:F2}, {weights.Y:F2}, {weights.Z:F2}");
        if (Input.IsKeyPressed(Key.O)) GD.Print(mastervolume);

        // update volumes of active ring
        bool anyrec = 
            SongVoiceOver.instance.recording || 
            layerVoiceOver0.recording || 
            layerVoiceOver0.shouldRecord || 
            layerVoiceOver1.recording || 
            layerVoiceOver1.shouldRecord;

        if (!anyrec)
        {
            if (chaosPadMode == ChaosPadMode.SampleMixing) SamplesMixing_UpdateMixingVolumesForRing(SamplesMixing_activeRing, mastervolume);
            if (chaosPadMode == ChaosPadMode.SynthMixing) SynthMixing_UpdateMixingVolumesForSynth(SynthMixing_activeSynth, mastervolume);
        }
    }

    private float MasterVolumeFromDistance(Vector2 knobPos, Vector2 a, Vector2 b, Vector2 c)
    {
        var ClosestPointOnTriangle = (Vector2 p, Vector2 a, Vector2 b, Vector2 c) =>
        {
            var ClosestPointOnSegment = (Vector2 p, Vector2 a, Vector2 b) =>
            {
                Vector2 ab = b - a;
                float t = (p - a).Dot(ab) / ab.LengthSquared();
                t = Mathf.Clamp(t, 0f, 1f);
                return a + ab * t;
            };

            Vector2 p0 = ClosestPointOnSegment(p, a, b);
            Vector2 p1 = ClosestPointOnSegment(p, b, c);
            Vector2 p2 = ClosestPointOnSegment(p, c, a);

            float d0 = p.DistanceSquaredTo(p0);
            float d1 = p.DistanceSquaredTo(p1);
            float d2 = p.DistanceSquaredTo(p2);

            float minDist = Mathf.Min(d0, Mathf.Min(d1, d2));
            if (minDist == d0) return p0;
            if (minDist == d1) return p1;
            return p2;
        };

        Vector2 closest = ClosestPointOnTriangle(knobPos, a, b, c);
        float distance = knobPos.DistanceTo(closest);
        float master = Mathf.Clamp(1f - (distance / outerTriangleSize), 0f, 1f);
        return master;
    }

    public Vector3 GetBarycentricWeights(Vector2 p, Vector2 a, Vector2 b, Vector2 c)
    {
        // compute vectors
        Vector2 v0 = b - a;
        Vector2 v1 = c - a;
        Vector2 v2 = p - a;

        // compute dot products
        float d00 = v0.Dot(v0);
        float d01 = v0.Dot(v1);
        float d11 = v1.Dot(v1);
        float d20 = v2.Dot(v0);
        float d21 = v2.Dot(v1);

        // ompute denominator
        float denom = d00 * d11 - d01 * d01;

        // compute barycentric coordinates
        float v = (d11 * d20 - d01 * d21) / denom;
        float w = (d00 * d21 - d01 * d20) / denom;
        float u = 1.0f - v - w;

        Vector3 nonclamped = new Vector3(u, v, w);

        return nonclamped;
    }

    public bool IsInsideTriangle(Vector3 weights)
    {
        return weights.X >= 0f && weights.Y >= 0f && weights.Z >= 0f;
    }
}