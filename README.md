## YouBeatAi
This is a game aimed at dutch children around 10 years old for making drum loops.

## Saving and loading
Songs can be saved and opened as `.ritme` files, including from the main menu.
In Settings, use the circular floppy-disk button to save and the circular
tray-and-arrow button to load. The main menu uses the same load button.
Hover over these buttons for the Dutch labels "Project bewaren" and "Project openen".
Loading replaces the song's effects, recordings, mix settings, theme emojis, and
section visuals rather than layering them over the previous song.
A full-screen "Liedje laden..." overlay blocks input while loading and remains
visible across the main-menu transition until the song and its UI are ready.

Run the loading regression checks with Godot 4.6:
```powershell
Start-Process -FilePath 'D:\Godot 4.6\godot.exe' -ArgumentList '--headless', '--path', '.', '.\tests\song_loading_test.tscn' -NoNewWindow -Wait
```
These checks do not replace manual audio, microphone, or browser file-picker testing.

## Showcase
![screen](https://github.com/user-attachments/assets/f37d486a-914c-4772-9687-fbb7b4aad2cd)
