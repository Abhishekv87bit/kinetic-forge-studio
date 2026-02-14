# Compare two OpenSCAD files and show differences
param($old, $new)
Compare-Object (Get-Content $old) (Get-Content $new) | Format-Table -AutoSize
