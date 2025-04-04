# 🎧 FFmpeg AAC Codec Checker

This PowerShell script checks whether a given `ffmpeg.exe` binary supports AAC audio encoding and reports on available AAC-related codecs, including the high-quality `libfdk_aac` encoder if present.

---

## 🧰 Features

- Verifies the presence of `ffmpeg.exe` at a specified path.
- Lists all AAC-related codecs detected in the FFmpeg build.
- Clearly identifies:
  - If AAC encoding is available.
  - Whether the `libfdk_aac` encoder is included.
  - Any AAC decoders or alternate encoders (e.g. `aac_mf` via Media Foundation).

---

## 📋 Prerequisites

- Windows 10/11 with PowerShell 5.1+ (or PowerShell Core)
- FFmpeg (static build, e.g. from [gyan.dev](https://www.gyan.dev/ffmpeg/builds/))

---

## 🛠️ Usage

1. Download or clone this repository.
2. Open the script file and modify the `$ffmpegPath` variable to match your local FFmpeg installation:

   ```powershell
   $ffmpegPath = "c:\Tools\ffmpeg\bin\ffmpeg.exe"
