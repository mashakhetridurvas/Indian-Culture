# Simple Local HTTP Server for Indian Culture and Heritage Website
# Runs locally without needing Node.js or Python installed!

param(
    [int]$Port = 5500
)

$HostName = "localhost"
$Url = "http://${HostName}:${Port}/"
$Folder = $PSScriptRoot

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($Url)

try {
    $listener.Start()
} catch {
    Write-Warning "Port $Port is already in use or unavailable. Trying port 8080..."
    $Port = 8080
    $Url = "http://${HostName}:${Port}/"
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add($Url)
    $listener.Start()
}

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "  Indian Culture and Heritage Website - Local Server" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "Server running at: $Url" -ForegroundColor Yellow
Write-Host "Serving files from: $Folder" -ForegroundColor Gray
Write-Host "Press Ctrl + C in this window to stop the server." -ForegroundColor DarkGray
Write-Host "==========================================================" -ForegroundColor Green

# Open default browser automatically
Start-Process $Url

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $relativePath = $request.Url.LocalPath.TrimStart('/')
        if ([string]::IsNullOrWhiteSpace($relativePath)) {
            $relativePath = "index.html"
        }

        # Prevent directory traversal
        $filePath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($Folder, $relativePath))
        if (-not $filePath.StartsWith($Folder, [System.StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path $filePath -PathType Leaf)) {
            $response.StatusCode = 404
            $buffer = [System.Text.Encoding]::UTF8.GetBytes("<h1>404 - File Not Found</h1>")
            $response.ContentType = "text/html"
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
            continue
        }

        # Determine MIME type
        $extension = [System.IO.Path]::GetExtension($filePath).ToLower()
        $contentType = switch ($extension) {
            ".html" { "text/html; charset=utf-8" }
            ".htm"  { "text/html; charset=utf-8" }
            ".css"  { "text/css; charset=utf-8" }
            ".js"   { "application/javascript; charset=utf-8" }
            ".json" { "application/json; charset=utf-8" }
            ".png"  { "image/png" }
            ".jpg"  { "image/jpeg" }
            ".jpeg" { "image/jpeg" }
            ".svg"  { "image/svg+xml" }
            ".ico"  { "image/x-icon" }
            default { "application/octet-stream" }
        }

        $bytes = [System.IO.File]::ReadAllBytes($filePath)
        $response.ContentType = $contentType
        $response.ContentLength64 = $bytes.Length
        $response.OutputStream.Write($bytes, 0, $bytes.Length)
        $response.Close()
    } catch {
        # Handle exceptions gracefully when stopping
        break
    }
}
