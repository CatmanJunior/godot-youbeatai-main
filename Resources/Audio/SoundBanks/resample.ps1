Get-ChildItem -Recurse -Filter *.wav | ForEach-Object { ffmpeg -i $_.FullName -ar 48000 -y "$($_.FullName).temp.wav"; Move-Item -Force "$($_.FullName).temp.wav" $_.FullName }
