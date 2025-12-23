using Godot;

public partial class DragAndDropButton : Sprite2D
{
	[Export] int ring = 0;
	[Export] public Button button;

	[Signal] public delegate void OnPressedEventHandler();

	bool colorIsChanging = false;

    public override void _Ready()
    {
		button.ButtonUp += OnPress;
    }

	bool w_pressed = false;
	bool w_pressed_lastframe = false;
	bool a_pressed = false;
	bool a_pressed_lastframe = false;
	bool s_pressed = false;
	bool s_pressed_lastframe = false;
	bool d_pressed = false;
	bool d_pressed_lastframe = false;

    public override void _Process(double delta)
    {
		w_pressed_lastframe = w_pressed;
		w_pressed = Input.IsKeyPressed(Key.A);
		if (w_pressed != w_pressed_lastframe && ring == 0 && w_pressed && !Manager.instance.emailPromptOpen) OnPress();

		a_pressed_lastframe = a_pressed;
		a_pressed = Input.IsKeyPressed(Key.S);
		if (a_pressed != a_pressed_lastframe && ring == 1 && a_pressed && !Manager.instance.emailPromptOpen) OnPress();

		s_pressed_lastframe = s_pressed;
		s_pressed = Input.IsKeyPressed(Key.D);
		if (s_pressed != s_pressed_lastframe && ring == 2 && s_pressed && !Manager.instance.emailPromptOpen) OnPress();

		d_pressed_lastframe = d_pressed;
		d_pressed = Input.IsKeyPressed(Key.F);
		if (d_pressed != d_pressed_lastframe && ring == 3 && d_pressed && !Manager.instance.emailPromptOpen) OnPress();

		if (button.ButtonPressed) SelfModulate = Manager.instance.colors[ring];
		else SelfModulate = Manager.instance.colors[ring] * 0.8f;
    }

	public void OnPress()
	{
		if (Manager.instance.button_is_clap.ButtonPressed)
		{
			if (ring == 0) Manager.instance.OnStomp();
			else if (ring == 1) Manager.instance.OnClap();
			else ButtonBehaviour();
		}
		else ButtonBehaviour();

		Manager.instance.SamplesMixing_ChangeRing(ring);
		EmitSignal(SignalName.OnPressed);
	}

	public void ButtonBehaviour()
	{
		if (ring == 0) Manager.instance.firstAudioPlayer.Play();
		if (ring == 1) Manager.instance.secondAudioPlayer.Play();
		if (ring == 2) Manager.instance.thirdAudioPlayer.Play();
		if (ring == 3) Manager.instance.fourthAudioPlayer.Play();

		if (ring == 0) Manager.instance.firstAudioPlayerAlt.Play();
		if (ring == 1) Manager.instance.secondAudioPlayerAlt.Play();
		if (ring == 2) Manager.instance.thirdAudioPlayerAlt.Play();
		if (ring == 3) Manager.instance.fourthAudioPlayerAlt.Play();

		if (ring == 0) Manager.instance.firstAudioPlayerRec.Play();
		if (ring == 1) Manager.instance.secondAudioPlayerRec.Play();
		if (ring == 2) Manager.instance.thirdAudioPlayerRec.Play();
		if (ring == 3) Manager.instance.fourthAudioPlayerRec.Play();

		// if knop is klap
		if (Manager.instance.button_add_beats.ButtonPressed)
		{
			// Manager.instance.beatActives[ring, BpmManager.instance.currentBeat] = true;
			BeatStateChanger.SetBeat(ring, BpmManager.instance.currentBeat, true);
			var position = Manager.instance.beatSprites[ring, BpmManager.instance.currentBeat].Position;
			Manager.instance.EmitBeatParticles(position, Manager.instance.colors[ring]);
		}

		if (Manager.instance.SamplesMixing_activeRing != ring && !colorIsChanging) StartColorChange(ring, 0.3f);
	}

	async private void StartColorChange(int ring, float duration)
    {
		colorIsChanging = true;

        Color old_color = Manager.instance.colors[ring];
        var old_color_v3 = new Vector3(old_color.R, old_color.G, old_color.B);

        var new_color = old_color.Lightened(1f);
        var new_color_v3 = new Vector3(new_color.R, new_color.G, new_color.B);

        // brighten
        float elapsed = 0f;
        while (elapsed < duration)
        {
            float t = elapsed / duration;
            float ct = Manager.instance.SynthMixing_LineColorCurve?.Sample(t) ?? t;
            Vector3 lerped = old_color_v3.Lerp(new_color_v3, ct);
            Manager.instance.colorsOverride[ring] = new Color(lerped.X, lerped.Y, lerped.Z, 1);

            // yield one frame
            await ToSignal(GetTree(), "process_frame");
            elapsed += (float)GetProcessDeltaTime();
        }

        // ensure final color is set
        Manager.instance.colorsOverride[ring] = new_color;

        // darken
        elapsed = 0f;
        while (elapsed < duration)
        {
            float t = elapsed / duration;
            float ct = Manager.instance.SynthMixing_LineColorCurve?.Sample(t) ?? t;
            Vector3 lerped = new_color_v3.Lerp(old_color_v3, ct);
            Manager.instance.colorsOverride[ring] = new Color(lerped.X, lerped.Y, lerped.Z, 1);

            // yield one frame
            await ToSignal(GetTree(), "process_frame");
            elapsed += (float)GetProcessDeltaTime();
        }

        // ensure final color is set
        Manager.instance.colorsOverride[ring] = old_color;

		colorIsChanging = false;
    }
}