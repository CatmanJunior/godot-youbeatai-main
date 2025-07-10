using Godot;

public partial class BeatSprite : Sprite2D
{
	public int ring;
	public int spriteIndex;

    public override void _Input(InputEvent inputEvent)
    {
		if (inputEvent is InputEventMouseButton mouseEvent)
		{
			if (mouseEvent.IsReleased() && mouseEvent.ButtonIndex == MouseButton.Left)
			{
				if (IsPixelOpaque(GetLocalMousePosition()))
				{
					Manager.instance.beatActives[ring, spriteIndex] = !Manager.instance.beatActives[ring, spriteIndex];

					if (Manager.instance.beatActives[ring, spriteIndex])
					{
						if (ring == 0) Manager.instance.firstAudioPlayer.Play();
						if (ring == 1) Manager.instance.secondAudioPlayer.Play();
						if (ring == 2) Manager.instance.thirdAudioPlayer.Play();
						if (ring == 3) Manager.instance.fourthAudioPlayer.Play();
					}

					var position = Manager.instance.beatSprites[ring, spriteIndex].Position;
					Manager.instance.EmitBeatParticles(position, Manager.instance.colors[ring]);
				}
			}
		}
    }
}