$folder = "C:\monitored_folder"
    $edaUrl = "http://eda-controller.example.com:5000/endpoint"

    # Check if the directory exists, create if it does not
    if (-not (Test-Path -Path $folder -PathType Container)) {
        try {
            New-Item -Path $folder -ItemType Directory -Force | Out-Null
            Write-Host "Created monitored folder: $folder"
        } catch {
            Write-Error "Failed to create monitored folder: $_"
            exit 1
        }
    }

    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $folder
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $true

    # Define the action to take on file system events
    $action = {
        param($source, $eventArgs)

        $payload = @{
            path        = $eventArgs.FullPath
            change_type = $eventArgs.ChangeType
            time        = (Get-Date).ToString("o")
        } | ConvertTo-Json -Compress

        try {
            Invoke-RestMethod -Uri $using:edaUrl -Method Post -Body $payload -ContentType "application/json"
            Write-Host "Event sent: $payload"
        } catch {
            Write-Error "Failed to send event: $_"
        }
    }

    # Register handlers for different event types
    Register-ObjectEvent $watcher "Created" -Action $action
    Register-ObjectEvent $watcher "Changed" -Action $action
    Register-ObjectEvent $watcher "Deleted" -Action $action
    Register-ObjectEvent $watcher "Renamed" -Action $action

    # Keep the script running to continue monitoring
    Write-Host "Watching $folder for changes. This script will run in the background."
    while ($true) {
        Start-Sleep -Seconds 5
    }
