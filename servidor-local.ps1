param(
  [int]$Port = 8787,
  [switch]$NoBrowser
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootFull = ([System.IO.Path]::GetFullPath($Root)).TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar

function Get-ContentType {
  param([string]$Path)
  switch ([System.IO.Path]::GetExtension($Path).ToLowerInvariant()) {
    ".html" { "text/html; charset=utf-8"; break }
    ".css" { "text/css; charset=utf-8"; break }
    ".js" { "text/javascript; charset=utf-8"; break }
    ".json" { "application/json; charset=utf-8"; break }
    ".webmanifest" { "application/manifest+json; charset=utf-8"; break }
    ".svg" { "image/svg+xml"; break }
    ".png" { "image/png"; break }
    ".jpg" { "image/jpeg"; break }
    ".jpeg" { "image/jpeg"; break }
    ".webp" { "image/webp"; break }
    default { "application/octet-stream"; break }
  }
}

function Send-Response {
  param(
    [System.IO.Stream]$Stream,
    [int]$Status,
    [string]$StatusText,
    [byte[]]$Body,
    [string]$Type
  )
  $header = "HTTP/1.1 $Status $StatusText`r`nContent-Type: $Type`r`nContent-Length: $($Body.Length)`r`nCache-Control: no-cache`r`nConnection: close`r`n`r`n"
  $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($header)
  $Stream.Write($headerBytes, 0, $headerBytes.Length)
  $Stream.Write($Body, 0, $Body.Length)
}

$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Parse("127.0.0.1"), $Port)

try {
  $listener.Start()
  $url = "http://127.0.0.1:$Port/"
  Write-Host ""
  Write-Host "Turno Handling esta funcionando en:" -ForegroundColor Green
  Write-Host "  $url" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "No cierres esta ventana mientras uses la app en Windows."
  Write-Host "Para parar el servidor, pulsa Ctrl+C."
  if (-not $NoBrowser) {
    Start-Process $url
  }

  while ($true) {
    $client = $listener.AcceptTcpClient()
    try {
      $stream = $client.GetStream()
      $reader = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::ASCII, $false, 1024, $true)
      $requestLine = $reader.ReadLine()
      while (($line = $reader.ReadLine()) -ne $null -and $line -ne "") {}

      if (-not $requestLine) {
        continue
      }

      $parts = $requestLine.Split(" ")
      if ($parts.Length -lt 2) {
        $body = [System.Text.Encoding]::UTF8.GetBytes("Bad request")
        Send-Response $stream 400 "Bad Request" $body "text/plain; charset=utf-8"
        continue
      }

      $rawPath = $parts[1].Split("?")[0]
      if ($rawPath -eq "/") {
        $relative = "index.html"
      } else {
        $relative = [System.Uri]::UnescapeDataString($rawPath.TrimStart("/")).Replace("/", [System.IO.Path]::DirectorySeparatorChar)
      }

      $candidate = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($Root, $relative))
      if (-not $candidate.StartsWith($RootFull, [System.StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
        $body = [System.Text.Encoding]::UTF8.GetBytes("Not found")
        Send-Response $stream 404 "Not Found" $body "text/plain; charset=utf-8"
        continue
      }

      $bytes = [System.IO.File]::ReadAllBytes($candidate)
      Send-Response $stream 200 "OK" $bytes (Get-ContentType $candidate)
    } catch {
      try {
        $body = [System.Text.Encoding]::UTF8.GetBytes("Server error")
        Send-Response $stream 500 "Server Error" $body "text/plain; charset=utf-8"
      } catch {}
    } finally {
      $client.Close()
    }
  }
} finally {
  $listener.Stop()
}
