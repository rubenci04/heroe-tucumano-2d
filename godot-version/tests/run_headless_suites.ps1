param(
    [string]$Engine = 'C:\Users\rea_0\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe',
    [string]$Label = 'polish_final'
)
$project = Split-Path $PSScriptRoot -Parent
$suites = @(Get-ChildItem "$project/tests/*.gd" | Where-Object { $_.Name -notlike 'capture*' -and (Get-Content $_.FullName -First 1) -eq 'extends SceneTree' }) + @(Get-Item "$project/tools/prototype*checks.gd")
$results = foreach ($suite in $suites) {
    $log = Join-Path $project ('validation/' + $Label + '_' + $suite.BaseName + '.log')
    $resource = 'res://' + $suite.FullName.Substring($project.Length + 1).Replace('\','/')
    & $Engine --headless --path $project --fixed-fps 60 --quit-after 24000 --log-file $log --script $resource *> ($log + '.console.log')
    $exitCode = $LASTEXITCODE
    $errors = @(Select-String -Path $log -Pattern 'SCRIPT ERROR:|ERROR:')
    [PSCustomObject]@{suite=$suite.BaseName; exit=$exitCode; errors=$errors.Count; log=$log}
    Write-Host ($suite.BaseName + ': exit=' + $exitCode + ' errors=' + $errors.Count)
}
$results | ConvertTo-Json | Set-Content (Join-Path $project ('validation/' + $Label + '_results.json'))
if (@($results | Where-Object { $_.exit -ne 0 -or $_.errors -gt 0 }).Count -gt 0) { exit 1 }
