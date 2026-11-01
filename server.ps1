$ErrorActionPreference = "Stop"

$port = 8080
$maxAttempts = 10
$listener = $null
$boundPort = $null

for ($i = 0; $i -lt $maxAttempts; $i++) {
    $currentPort = $port + $i
    try {
        $l = New-Object System.Net.HttpListener
        $l.Prefixes.Add("http://localhost:$currentPort/")
        $l.Start()
        $listener = $l
        $boundPort = $currentPort
        break
    } catch {
        if ($l) { $l.Close() }
    }
}

if (-not $listener) {
    Write-Host "Error: No se pudo iniciar el servidor web en los puertos 8080-8089." -ForegroundColor Red
    exit 1
}

$root = $PSScriptRoot
if (-not $root) { $root = Get-Location }
$url = "http://localhost:$boundPort/"

Clear-Host
Write-Host "==================================================================" -ForegroundColor DarkRed
Write-Host "     CHOCOLATE EMBAJADOR - LA TRADICION LLEVA TU APELLIDO        " -ForegroundColor Yellow
Write-Host "                  Cortes Hermanos & Co.                           " -ForegroundColor White
Write-Host "==================================================================" -ForegroundColor DarkRed
Write-Host ""
Write-Host "  [OK] Servidor web local iniciado con exito." -ForegroundColor Green
Write-Host "  -> Direccion: $url" -ForegroundColor Cyan
Write-Host "  -> Carpeta raiz: $root" -ForegroundColor Gray
Write-Host ""
Write-Host "  Abriendo en tu navegador predeterminado..." -ForegroundColor Yellow
Write-Host "  (Presiona Ctrl + C en esta ventana para detener el servidor)" -ForegroundColor DarkGray
Write-Host "------------------------------------------------------------------" -ForegroundColor DarkRed

# Open default browser
try {
    Start-Process $url
} catch {
    Write-Host "Aviso: Abre manualmente la direccion $url en tu navegador." -ForegroundColor DarkYellow
}

$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".htm"  = "text/html; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".gif"  = "image/gif"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
    ".woff2"= "font/woff2"
    ".woff" = "font/woff"
    ".ttf"  = "font/ttf"
}

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $localPath = $request.Url.LocalPath
        if ($localPath -eq "/" -or $localPath -eq "") {
            $localPath = "/index.html"
        }

        # sanitize path to prevent directory traversal
        $safePath = $localPath.TrimStart("/").Replace("/", [System.IO.Path]::DirectorySeparatorChar)
        $filePath = [System.IO.Path]::Combine($root, $safePath)

        if ([System.IO.File]::Exists($filePath)) {
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            $mime = "application/octet-stream"
            if ($mimeTypes.ContainsKey($ext)) {
                $mime = $mimeTypes[$ext]
            }

            try {
                $bytes = [System.IO.File]::ReadAllBytes($filePath)
                $response.ContentType = $mime
                $response.ContentLength64 = $bytes.Length
                $response.StatusCode = 200
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            } catch {
                $response.StatusCode = 500
            }
        } else {
            $response.StatusCode = 404
            $notFoundMsg = [System.Text.Encoding]::UTF8.GetBytes("404 - Archivo no encontrado")
            $response.ContentType = "text/plain; charset=utf-8"
            $response.ContentLength64 = $notFoundMsg.Length
            $response.OutputStream.Write($notFoundMsg, 0, $notFoundMsg.Length)
        }

        try {
            $response.OutputStream.Close()
        } catch {}
    }
} finally {
    if ($listener) {
        $listener.Stop()
        $listener.Close()
    }
}
