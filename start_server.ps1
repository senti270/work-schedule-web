$port = 8080
$root = "build/web"

# HTTP 리스너 생성
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Prefixes.Add("http://127.0.0.1:$port/")
$listener.Start()

Write-Host "웹 서버가 시작되었습니다!"
Write-Host "접속 주소: http://localhost:$port"
Write-Host "종료하려면 Ctrl+C를 누르세요."

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        $url = $request.Url.LocalPath
        if ($url -eq "/") {
            $url = "/index.html"
        }
        
        $filePath = Join-Path $root $url.TrimStart("/")
        
        if (Test-Path $filePath -PathType Leaf) {
            $content = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentLength64 = $content.Length
            
            # MIME 타입 설정
            $extension = [System.IO.Path]::GetExtension($filePath)
            switch ($extension) {
                ".html" { $response.ContentType = "text/html" }
                ".js" { $response.ContentType = "application/javascript" }
                ".css" { $response.ContentType = "text/css" }
                ".json" { $response.ContentType = "application/json" }
                ".png" { $response.ContentType = "image/png" }
                ".jpg" { $response.ContentType = "image/jpeg" }
                default { $response.ContentType = "text/plain" }
            }
            
            $response.OutputStream.Write($content, 0, $content.Length)
        } else {
            # 파일이 없으면 index.html로 리다이렉트 (SPA 지원)
            $indexPath = Join-Path $root "index.html"
            if (Test-Path $indexPath) {
                $content = [System.IO.File]::ReadAllBytes($indexPath)
                $response.ContentLength64 = $content.Length
                $response.ContentType = "text/html"
                $response.OutputStream.Write($content, 0, $content.Length)
            } else {
                $response.StatusCode = 404
                $notFound = [System.Text.Encoding]::UTF8.GetBytes("404 - File Not Found")
                $response.OutputStream.Write($notFound, 0, $notFound.Length)
            }
        }
        
        $response.Close()
    }
} finally {
    $listener.Stop()
    Write-Host "웹 서버가 종료되었습니다."
}
