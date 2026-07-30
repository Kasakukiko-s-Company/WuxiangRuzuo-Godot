param(
    [string]$ProjectRoot = ""
)

$ErrorActionPreference = "Stop"

$expectedSourceSha256 = (
    "457194D1FCBBE6A0E1506AA67FE88A2491B024034DA38ACAA37611D3D855B4EE"
)
$expectedOutputSha256 = (
    "63CE59F690CB4678BC9FF49A21395B165BA2ED71D40D1E01560853C7D17DDF9F"
)
$sourceRelative = (
    "art-source\visual-direction\ai-resource-families\batch-001\" +
    "a-cyan-mist-old-homestead-scene.png"
)
$targetRelative = (
    "assets\art\title\a_cyan_mist_homestead_title_dev.jpg"
)
$scriptProjectRoot = [System.IO.Path]::GetFullPath(
    [System.IO.Path]::Combine($PSScriptRoot, "..")
)
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = $scriptProjectRoot
}
$resolvedRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
if (-not $resolvedRoot.Equals(
    $scriptProjectRoot,
    [System.StringComparison]::OrdinalIgnoreCase
)) {
    throw "This tool only operates on the project that contains the script."
}
$sourcePath = [System.IO.Path]::GetFullPath(
    [System.IO.Path]::Combine($resolvedRoot, $sourceRelative)
)
$targetPath = [System.IO.Path]::GetFullPath(
    [System.IO.Path]::Combine($resolvedRoot, $targetRelative)
)
$rootPrefix = (
    $resolvedRoot.TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    ) + [System.IO.Path]::DirectorySeparatorChar
)

foreach ($path in @($resolvedRoot, $sourcePath, $targetPath)) {
    if (-not [System.IO.Path]::GetPathRoot($path).Equals(
        "D:\",
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "Visual reference production is restricted to the D drive."
    }
}
if (-not $sourcePath.StartsWith(
    $rootPrefix,
    [System.StringComparison]::OrdinalIgnoreCase
)) {
    throw "Source path escaped the project root."
}
if (-not $targetPath.StartsWith(
    $rootPrefix,
    [System.StringComparison]::OrdinalIgnoreCase
)) {
    throw "Target path escaped the project root."
}
if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
    throw "Visual-direction source is unavailable: $sourcePath"
}

function Assert-NoReparsePoint {
    param([string]$Path)

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $pathRoot = [System.IO.Path]::GetPathRoot($fullPath)
    $current = $pathRoot
    $relative = $fullPath.Substring($pathRoot.Length)
    foreach ($component in $relative.Split(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.StringSplitOptions]::RemoveEmptyEntries
    )) {
        $current = [System.IO.Path]::Combine($current, $component)
        if (-not (Test-Path -LiteralPath $current)) {
            break
        }
        $item = Get-Item -LiteralPath $current -Force
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Reparse points are not allowed in visual production paths: $current"
        }
    }
}

Assert-NoReparsePoint -Path $resolvedRoot
Assert-NoReparsePoint -Path $sourcePath
Assert-NoReparsePoint -Path (
    [System.IO.Path]::GetDirectoryName($targetPath)
)
$sourceHash = Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256
if (-not $sourceHash.Hash.Equals(
    $expectedSourceSha256,
    [System.StringComparison]::OrdinalIgnoreCase
)) {
    throw "Visual-direction source hash does not match the approved Batch 001 input."
}

Add-Type -AssemblyName System.Drawing
[System.IO.Directory]::CreateDirectory(
    [System.IO.Path]::GetDirectoryName($targetPath)
) | Out-Null
$candidatePath = (
    $targetPath + "." +
    [System.Guid]::NewGuid().ToString("N") +
    ".verified-candidate"
)

try {
    $sourceImage = [System.Drawing.Image]::FromFile($sourcePath)
    try {
        $bitmap = New-Object System.Drawing.Bitmap 640, 360
        try {
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            try {
                $graphics.CompositingQuality = (
                    [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                )
                $graphics.InterpolationMode = (
                    [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                )
                $graphics.SmoothingMode = (
                    [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                )
                $graphics.PixelOffsetMode = (
                    [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                )
                $graphics.DrawImage($sourceImage, 0, 0, 640, 360)
            }
            finally {
                $graphics.Dispose()
            }

            $jpegCodec = (
                [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
                    Where-Object { $_.MimeType -eq "image/jpeg" } |
                    Select-Object -First 1
            )
            $qualityEncoder = [System.Drawing.Imaging.Encoder]::Quality
            $encoderParameters = (
                New-Object System.Drawing.Imaging.EncoderParameters 1
            )
            try {
                $encoderParameters.Param[0] = (
                    New-Object System.Drawing.Imaging.EncoderParameter(
                        $qualityEncoder,
                        [long]90
                    )
                )
                $bitmap.Save($candidatePath, $jpegCodec, $encoderParameters)
            }
            finally {
                $encoderParameters.Dispose()
            }
        }
        finally {
            $bitmap.Dispose()
        }
    }
    finally {
        $sourceImage.Dispose()
    }

    $candidateHash = Get-FileHash -LiteralPath $candidatePath -Algorithm SHA256
    if (-not $candidateHash.Hash.Equals(
        $expectedOutputSha256,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "Generated title derivative does not match its approved hash."
    }
    Move-Item -LiteralPath $candidatePath -Destination $targetPath -Force
}
finally {
    if (Test-Path -LiteralPath $candidatePath) {
        Remove-Item -LiteralPath $candidatePath -Force
    }
}

$output = Get-Item -LiteralPath $targetPath
$hash = Get-FileHash -LiteralPath $targetPath -Algorithm SHA256
Write-Output (
    "DEV_VISUAL_REFERENCE_OK: {0} bytes, SHA-256 {1}" -f
    $output.Length,
    $hash.Hash
)
