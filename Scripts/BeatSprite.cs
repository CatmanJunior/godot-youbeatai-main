using System;
using Godot;

public partial class BeatSprite : Sprite2D
{
    public int ring;
    public int spriteIndex;

    public Area2D area;
    public CollisionShape2D collider;

    public override void _Ready()
    {
        area = (Area2D)GetChild(0);
        collider = (CollisionShape2D)area.GetChild(0);

        var spriteSize = Texture.GetSize();
        ((CircleShape2D)collider.Shape).Radius = spriteSize.X * 0.5f;

        area.InputEvent += OnAreaInput;
    }

    private void OnAreaInput(Node viewport, InputEvent inputEvent, long shapeIdx)
    {
        if (!Visible || Manager.instance.settingsPanel.Visible)
            return;

        if (
            inputEvent is InputEventMouseButton mouseButtonEvent
            && mouseButtonEvent.ButtonIndex == MouseButton.Left
            && mouseButtonEvent.IsReleased()
        )
        {
            OnClick();
        }
    }

    void OnClick()
    {
        BeatStateChanger.ToggleBeat(ring, spriteIndex);

        if (Manager.instance.beatActives[ring, spriteIndex])
        {
            if (ring == 0)
                Manager.instance.firstAudioPlayer.Play();
            if (ring == 1)
                Manager.instance.secondAudioPlayer.Play();
            if (ring == 2)
                Manager.instance.thirdAudioPlayer.Play();
            if (ring == 3)
                Manager.instance.fourthAudioPlayer.Play();

            if (ring == 0)
                Manager.instance.firstAudioPlayerAlt.Play();
            if (ring == 1)
                Manager.instance.secondAudioPlayerAlt.Play();
            if (ring == 2)
                Manager.instance.thirdAudioPlayerAlt.Play();
            if (ring == 3)
                Manager.instance.fourthAudioPlayerAlt.Play();

            if (ring == 0)
                Manager.instance.firstAudioPlayerRec.Play();
            if (ring == 1)
                Manager.instance.secondAudioPlayerRec.Play();
            if (ring == 2)
                Manager.instance.thirdAudioPlayerRec.Play();
            if (ring == 3)
                Manager.instance.fourthAudioPlayerRec.Play();
        }

        var position = Manager.instance.beatSprites[ring, spriteIndex].Position;
        Manager.instance.EmitBeatParticles(position, Manager.instance.colors[ring]);

        Manager.instance.SamplesMixing_ChangeRing(ring);
    }
}
