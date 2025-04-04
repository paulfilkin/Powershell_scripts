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
   ```

3. Run the script in PowerShell:

   ```powershell
   .\Check-AAC-Codecs.ps1
   ```

4. You will see output similar to:

   ```
   ✅ Found ffmpeg.exe at: c:\Tools\ffmpeg\bin\ffmpeg.exe
   
   🎧 AAC-related codecs found:
   
    DEA.L. aac                  AAC (Advanced Audio Coding) (decoders: aac aac_fixed) (encoders: aac aac_mf)
    D.A.L. aac_latm             AAC LATM (Advanced Audio Coding LATM syntax)
   
   ✅ AAC encoding is supported.
   ℹ️ libfdk_aac is not included in this build.
   ```

---

## 📦 Output Legend

- `D` = Decoder
- `E` = Encoder
- `A` = Audio
- `L` = Lossy
- `S` = Lossless
- `.` = Not supported

---

## 🧪 Tip: Test AAC Encoding Manually

You can test that AAC encoding works with FFmpeg like this within the same powershell window you have open after running ffmpeg_aac_check.ps1:

```powershell
& "$ffmpegPath" -f lavfi -i testsrc=duration=5:size=1280x720:rate=30 `
-f lavfi -i sine=frequency=1000:duration=5 `
-c:v libx264 -c:a aac -b:a 128k -shortest test_output.mp4
```

This generates a test MP4 file with a video test pattern and a 1kHz audio tone encoded using AAC.

Or you can run the standalone script testAACEncoding.ps1 which is also provided in this repository.

---

## 🤝 Contributions

Feel free to open an issue or PR if you want to improve the script or extend it to support other audio codecs.
