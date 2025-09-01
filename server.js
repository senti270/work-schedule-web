const http = require('http');
const fs = require('fs');
const path = require('path');

const port = 5000;

const server = http.createServer((req, res) => {
  let filePath = path.join(__dirname, 'build/web', req.url === '/' ? 'index.html' : req.url);
  
  // 파일 확장자 확인
  const extname = path.extname(filePath);
  let contentType = 'text/html';
  
  switch (extname) {
    case '.js':
      contentType = 'text/javascript';
      break;
    case '.css':
      contentType = 'text/css';
      break;
    case '.json':
      contentType = 'application/json';
      break;
    case '.png':
      contentType = 'image/png';
      break;
    case '.jpg':
      contentType = 'image/jpg';
      break;
  }
  
  // 파일 읽기
  fs.readFile(filePath, (err, content) => {
    if (err) {
      if (err.code === 'ENOENT') {
        // 파일이 없으면 index.html로 리다이렉트 (SPA 지원)
        fs.readFile(path.join(__dirname, 'build/web/index.html'), (err, content) => {
          if (err) {
            res.writeHead(500);
            res.end('Error loading index.html');
          } else {
            res.writeHead(200, { 'Content-Type': 'text/html' });
            res.end(content, 'utf-8');
          }
        });
      } else {
        res.writeHead(500);
        res.end('Server Error: ' + err.code);
      }
    } else {
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(content, 'utf-8');
    }
  });
});

server.listen(port, '0.0.0.0', () => {
  console.log(`Server running at http://localhost:${port}/`);
  console.log(`Server also accessible at http://127.0.0.1:${port}/`);
});
