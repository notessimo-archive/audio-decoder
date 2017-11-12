# audio-decoder

An easy wrapper to decode OGG / MP3 / WAV to Float32Array.

In HTML5 target it will utilize the AudioContext to decode (unless it's called from a Worker). OpenFL target will use the native decoder (if available) otherwise it default to an haxe implementation of the decoder.

WAV is always decoded from haxe.

MP3 is still a WIP, OGG / WAV should work.