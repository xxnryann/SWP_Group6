/*
    Proxy chi cho phep trang thong tin ve di qua tunnel cong khai (dung boi public-qr.ps1).

    Internet -> cloudflared -> proxy nay (127.0.0.1:PORT) -> Tomcat
    Chi chap nhan GET/HEAD /ticket/view?code=TK...; moi duong dan khac (dang nhap, admin, API...) tra 404,
    nen tunnel khong lam lo phan con lai cua website. Khong chuyen tiep cookie theo ca hai chieu.

    Dung: node ticket-proxy.js <cong-proxy> <dia-chi-goc-ung-dung>
      vd: node ticket-proxy.js 9998 http://127.0.0.1:9999/CinemaTest
*/
const http = require('http');

const port = Number(process.argv[2] || 9998);
const target = new URL(process.argv[3] || 'http://127.0.0.1:9999/CinemaTest');
const basePath = target.pathname.replace(/\/$/, '');
const CODE = /^TK[0-9A-Z]{6,28}$/i;
const PASS_HEADERS = ['content-type', 'content-length', 'cache-control', 'x-robots-tag', 'date'];

function deny(res, status, text) {
    res.writeHead(status, { 'Content-Type': 'text/plain; charset=utf-8', 'Cache-Control': 'no-store' });
    res.end(text);
}

http.createServer((req, res) => {
    let url;
    try {
        url = new URL(req.url, 'http://proxy');
    } catch (e) {
        return deny(res, 400, 'Bad request');
    }
    if (req.method !== 'GET' && req.method !== 'HEAD') return deny(res, 405, 'Method not allowed');
    const code = url.searchParams.get('code') || '';
    if (url.pathname !== '/ticket/view' || !CODE.test(code)) return deny(res, 404, 'Not found');

    const upstream = http.request({
        hostname: target.hostname,
        port: target.port || 80,
        method: req.method,
        path: basePath + '/ticket/view?code=' + encodeURIComponent(code.toUpperCase()),
        headers: { 'User-Agent': req.headers['user-agent'] || 'ticket-proxy', 'Accept': 'text/html' },
        timeout: 15000
    }, up => {
        const headers = {};
        for (const h of PASS_HEADERS) if (up.headers[h]) headers[h] = up.headers[h];
        res.writeHead(up.statusCode, headers);
        up.pipe(res);
    });
    upstream.on('timeout', () => upstream.destroy(new Error('timeout')));
    upstream.on('error', () => { if (!res.headersSent) deny(res, 502, 'Website dang tat'); else res.end(); });
    upstream.end();
}).listen(port, '127.0.0.1', () => console.log(`ticket-proxy: 127.0.0.1:${port} -> ${target.href}`));
