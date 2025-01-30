Write-Host "Searching for generated files..." -ForegroundColor Yellow

# Find all .g.dart and .freezed.dart files recursively 
$gFiles = Get-ChildItem -Path . -Filter "*.g.dart" -Recurse
$freezedFiles = Get-ChildItem -Path . -Filter "*.freezed.dart" -Recurse
$files = $gFiles + $freezedFiles

if ($files.Count -eq 0) {
    Write-Host "No generated files found." -ForegroundColor Green
    exit
}

# List all files that will be deleted
Write-Host "`nFound the following generated files:" -ForegroundColor Cyan
foreach ($file in $files) {
    Write-Host $file.FullName -ForegroundColor Gray
}

# Prompt for confirmation
$confirmation = Read-Host "`nDo you want to delete these files? (y/n)"
if ($confirmation -eq 'y') {
    foreach ($file in $files) {
        Remove-Item $file.FullName
        Write-Host "Deleted: $($file.FullName)" -ForegroundColor Red
    }
    Write-Host "`nAll generated files have been deleted." -ForegroundColor Green
} else {
    Write-Host "`nOperation cancelled." -ForegroundColor Yellow
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')