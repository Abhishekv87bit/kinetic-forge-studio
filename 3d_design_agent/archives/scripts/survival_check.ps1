# Check for required components in OpenSCAD file
param($file)
$required = @("enclosure", "motor", "pinion", "master_gear", "four_bar", "wave")
$content = Get-Content $file -Raw
foreach ($comp in $required) {
    if ($content -match $comp) {
        Write-Host "[OK] $comp found" -ForegroundColor Green
    } else {
        Write-Host "[MISSING] $comp NOT FOUND" -ForegroundColor Red
    }
}
