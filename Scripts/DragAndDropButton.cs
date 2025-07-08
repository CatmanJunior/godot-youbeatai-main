using Godot;
using System;

public partial class DragAndDropButton : Sprite2D
{
	[Export] int ring = 0;

	bool inside => IsPixelOpaque(GetLocalMousePosition());

	float timePressing = 0;

	bool pressing = false;
	bool holdingOutside = false;
	bool startedholdingthisringinside = false;
	bool holdingforthis = false;

    public override void _Input(InputEvent inputEvent)
    {
		if (inputEvent is InputEventMouseButton mouseEvent && mouseEvent.ButtonIndex == MouseButton.Left)
		{
			// on press
			if (mouseEvent.IsPressed())
			{
				pressing = true;

				if (inside) holdingforthis = true;
				else holdingforthis = false;

				startedholdingthisringinside = inside;
			} 

			// on release
			if (mouseEvent.IsReleased())
			{
				pressing = false;

				if (inside) ActivateBeat();

				startedholdingthisringinside = false;
				Manager.instance.dragginganddropping = false;
			}
		}
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
		if (w_pressed != w_pressed_lastframe && ring == 0 && w_pressed && !Manager.instance.emailPromptOpen) ActivateBeat();

		a_pressed_lastframe = a_pressed;
		a_pressed = Input.IsKeyPressed(Key.S);
		if (a_pressed != a_pressed_lastframe && ring == 1 && a_pressed && !Manager.instance.emailPromptOpen) ActivateBeat();

		s_pressed_lastframe = s_pressed;
		s_pressed = Input.IsKeyPressed(Key.D);
		if (s_pressed != s_pressed_lastframe && ring == 2 && s_pressed && !Manager.instance.emailPromptOpen) ActivateBeat();

		d_pressed_lastframe = d_pressed;
		d_pressed = Input.IsKeyPressed(Key.F);
		if (d_pressed != d_pressed_lastframe && ring == 3 && d_pressed && !Manager.instance.emailPromptOpen) ActivateBeat();


		holdingOutside = pressing && !inside;
		var holdingthisring = holdingOutside && holdingforthis;
		if (holdingthisring) Manager.instance.holdingforring = ring;
		if (holdingthisring) Manager.instance.dragginganddropping = holdingOutside && startedholdingthisringinside;

		if (pressing) timePressing += (float)delta;
		else timePressing = 0;

		if (pressing && inside && timePressing > 0.5f && !Manager.instance.beatActives[ring, BpmManager.instance.currentBeat]) ActivateBeat();

		if (inside) SelfModulate = Manager.instance.colors[ring];
		else SelfModulate = Manager.instance.colors[ring] * 0.8f;
    }

	public void ActivateBeat()
	{
		GD.Print("add");
		Manager.instance.beatActives[ring, BpmManager.instance.currentBeat] = true;

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

		var position = Manager.instance.beatSprites[ring, BpmManager.instance.currentBeat].Position;
		Manager.instance.EmitBeatParticles(position, Manager.instance.colors[ring]);
	}
}
