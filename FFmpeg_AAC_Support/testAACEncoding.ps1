# Define FFmpeg path (update if needed)
$ffmpegPath = "C:\Tools\ffmpeg\bin\ffmpeg.exe"

# Ensure ffmpeg.exe exists
if (-Not (Test-Path $ffmpegPath)) {
    Write-Host "❌ ffmpeg.exe not found at: $ffmpegPath" -ForegroundColor Red
    return
}

Write-Host "✅ ffmpeg.exe found at: $ffmpegPath" -ForegroundColor Green

# Build output path relative to script location
$outputPath = Join-Path $PSScriptRoot "test_output.mp4"
Write-Host "📁 Output will be saved to: $outputPath" -ForegroundColor Cyan

# Run FFmpeg test command
& "$ffmpegPath" -y `
-f lavfi -i testsrc=duration=5:size=1280x720:rate=30 `
-f lavfi -i sine=frequency=1000:duration=5 `
-c:v libx264 -c:a aac -b:a 128k -shortest "$outputPath"

# Check result
if (Test-Path $outputPath) {
    Write-Host "`n✅ test_output.mp4 was successfully created." -ForegroundColor Green
} else {
    Write-Host "`n❌ Failed to create test_output.mp4." -ForegroundColor Red
}
