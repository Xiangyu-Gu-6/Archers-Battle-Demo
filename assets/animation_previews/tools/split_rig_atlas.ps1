param(
    [Parameter(Mandatory = $true)][string]$AtlasPath,
    [Parameter(Mandatory = $true)][string]$OutputDirectory
)

Add-Type -AssemblyName System.Drawing

$names = @(
    'head', 'hat', 'hat_feather', 'torso',
    'rear_upper_arm', 'rear_forearm_hand', 'front_upper_arm', 'front_forearm_hand',
    'rear_thigh', 'rear_lower_leg_boot', 'front_thigh', 'front_lower_leg_boot',
    'bow', 'quiver', 'nocked_arrow', 'belt_pouch'
)

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$source = [System.Drawing.Bitmap]::FromFile((Resolve-Path -LiteralPath $AtlasPath).Path)

try {
    for ($index = 0; $index -lt 16; $index++) {
        $column = $index % 4
        $row = [math]::Floor($index / 4)
        $x0 = [int][math]::Round($column * $source.Width / 4.0)
        $x1 = [int][math]::Round(($column + 1) * $source.Width / 4.0)
        $y0 = [int][math]::Round($row * $source.Height / 4.0)
        $y1 = [int][math]::Round(($row + 1) * $source.Height / 4.0)

        $cell = New-Object System.Drawing.Bitmap ($x1 - $x0), ($y1 - $y0), ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [System.Drawing.Graphics]::FromImage($cell)
        $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $graphics.DrawImage(
            $source,
            (New-Object System.Drawing.Rectangle 0, 0, $cell.Width, $cell.Height),
            (New-Object System.Drawing.Rectangle $x0, $y0, $cell.Width, $cell.Height),
            [System.Drawing.GraphicsUnit]::Pixel
        )
        $graphics.Dispose()

        $minX = $cell.Width
        $minY = $cell.Height
        $maxX = -1
        $maxY = -1
        for ($y = 0; $y -lt $cell.Height; $y++) {
            for ($x = 0; $x -lt $cell.Width; $x++) {
                if ($cell.GetPixel($x, $y).A -gt 4) {
                    if ($x -lt $minX) { $minX = $x }
                    if ($x -gt $maxX) { $maxX = $x }
                    if ($y -lt $minY) { $minY = $y }
                    if ($y -gt $maxY) { $maxY = $y }
                }
            }
        }

        if ($maxX -lt 0) {
            $cell.Dispose()
            throw "No visible pixels found in cell $index ($($names[$index]))."
        }

        $padding = 12
        $trimWidth = $maxX - $minX + 1
        $trimHeight = $maxY - $minY + 1
        $trimmed = New-Object System.Drawing.Bitmap ($trimWidth + 2 * $padding), ($trimHeight + 2 * $padding), ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $trimGraphics = [System.Drawing.Graphics]::FromImage($trimmed)
        $trimGraphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $trimGraphics.DrawImage(
            $cell,
            (New-Object System.Drawing.Rectangle $padding, $padding, $trimWidth, $trimHeight),
            (New-Object System.Drawing.Rectangle $minX, $minY, $trimWidth, $trimHeight),
            [System.Drawing.GraphicsUnit]::Pixel
        )
        $trimGraphics.Dispose()
        $cell.Dispose()

        $outputPath = Join-Path $OutputDirectory ("emerald_ranger_{0}_v02.png" -f $names[$index])
        $trimmed.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        Write-Output ("{0}`t{1}x{2}" -f $outputPath, $trimmed.Width, $trimmed.Height)
        $trimmed.Dispose()
    }
}
finally {
    $source.Dispose()
}
