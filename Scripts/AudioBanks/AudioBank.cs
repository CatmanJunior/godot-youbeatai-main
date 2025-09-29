using Godot;

[GlobalClass]
public partial class AudioBank : Resource
{
	[Export]
	public AudioStream kick { get; set; }
	[Export]
	public AudioStream kick_alt { get; set; }
	
	
	[Export]
	public AudioStream snare { get; set; }
	[Export]
	public AudioStream snare_alt { get; set; }

	[Export]
	public AudioStream clap { get; set; }
	[Export]
	public AudioStream clap_alt { get; set; }


	[Export]
	public AudioStream closed { get; set; }
	[Export]
	public AudioStream closed_alt { get; set; }


	[Export]
	public Resource green_soundfont { get; set; }
	[Export]
	public int green_instrument_id { get; set; }
	

	[Export]
	public Resource purple_soundfont { get; set; }
	[Export]
	public int purple_instrument_id { get; set; }
	

	public AudioBank() { }
}
