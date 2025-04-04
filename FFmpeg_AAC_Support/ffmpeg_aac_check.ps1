# 🔧 Set your FFmpeg path here
$ffmpegPath = "c:\Tools\ffmpeg\bin\ffmpeg.exe"

# 🧪 Check if ffmpeg.exe exists
if (-Not (Test-Path $ffmpegPath)) {
    Write-Host "❌ ffmpeg.exe not found at: $ffmpegPath" -ForegroundColor Red
    return
}

Write-Host "✅ Found ffmpeg.exe at: $ffmpegPath" -ForegroundColor Green

# 📜 Run ffmpeg to list codecs
$aacCodecs = & $ffmpegPath -hide_banner -codecs | Where-Object { $_ -match "aac" }

if ($aacCodecs) {
    Write-Host "`n🎧 AAC-related codecs found:`n" -ForegroundColor Cyan
    $aacCodecs | ForEach-Object { Write-Host $_ }
    
    if ($aacCodecs -match "EA.*aac") {
        Write-Host "`n✅ AAC encoding is supported." -ForegroundColor Green
    } else {
        Write-Host "`n⚠️ AAC encoding not available in this build." -ForegroundColor Yellow
    }

    if ($aacCodecs -match "libfdk_aac") {
        Write-Host "✅ libfdk_aac is available (high quality AAC encoding)." -ForegroundColor Green
    } else {
        Write-Host "ℹ️ libfdk_aac is not included in this build." -ForegroundColor DarkYellow
    }
} else {
    Write-Host "❌ No AAC codecs found in this FFmpeg build." -ForegroundColor Red
}
