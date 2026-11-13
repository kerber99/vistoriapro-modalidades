param([int]$Port = 8765, [switch]$NoOpen)

# Servidor local simples (sem instalar nada) para abrir o site em http://localhost.
# Necessário para o vídeo do YouTube tocar dentro da página: abrindo o index.html direto
# do disco (file://), o YouTube bloqueia o player embutido com "Erro 153".

$root = (Split-Path -Parent $MyInvocation.MyCommand.Path).TrimEnd('\')
$prefix = "http://localhost:$Port/"
$mime = @{
  '.html' = 'text/html; charset=utf-8'; '.css' = 'text/css; charset=utf-8'; '.js' = 'text/javascript; charset=utf-8'
  '.json' = 'application/json'; '.png' = 'image/png'; '.jpg' = 'image/jpeg'; '.jpeg' = 'image/jpeg'
  '.webp' = 'image/webp'; '.svg' = 'image/svg+xml'; '.ico' = 'image/x-icon'; '.woff2' = 'font/woff2'
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)
try {
  $listener.Start()
} catch {
  Write-Host "A porta $Port ja esta em uso (o site provavelmente ja esta aberto). Abrindo o navegador..."
  if (-not $NoOpen) { Start-Process $prefix }
  exit
}

Write-Host ""
Write-Host "  Site no ar em $prefix"
Write-Host "  Deixe esta janela aberta enquanto usa o site. Feche-a para encerrar."
Write-Host ""
if (-not $NoOpen) { Start-Process $prefix }

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  try {
    $path = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath)
    if ($path -eq '/') { $path = '/index.html' }
    $file = [IO.Path]::GetFullPath((Join-Path $root $path.TrimStart('/')))
    if ($file.StartsWith($root + '\') -and (Test-Path -LiteralPath $file -PathType Leaf)) {
      $ext = [IO.Path]::GetExtension($file).ToLower()
      $type = $mime[$ext]
      if (-not $type) { $type = 'application/octet-stream' }
      $bytes = [IO.File]::ReadAllBytes($file)
      $ctx.Response.ContentType = $type
      $ctx.Response.ContentLength64 = $bytes.Length
      $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $ctx.Response.StatusCode = 404
    }
  } catch {
    $ctx.Response.StatusCode = 500
  } finally {
    $ctx.Response.Close()
  }
}
