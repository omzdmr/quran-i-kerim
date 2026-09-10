# Audio v2.1 status

Audio v2.1 stays isolated on `feature/audio-v21` until its final quality gate is green.

Current integration includes human-recorded Quran/translation catalog discovery, alternative human recordings per language when available, local-first audio caching, background media controls and metadata, sleep-timer primitives, and the Reader selection `Dinle` action wired to the verified human-audio playback pipeline.

The branch must pass analyzer, all tests, ARM64 release build, package-name verification, ABI verification, and APK signature verification before Reader v2 work starts.
