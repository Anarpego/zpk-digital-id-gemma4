import {
  closeSync,
  createReadStream,
  existsSync,
  openSync,
  readSync,
  statSync,
} from 'node:fs';
import { createServer } from 'node:http';
import { createHash } from 'node:crypto';
import { networkInterfaces } from 'node:os';
import { extname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import QRCode from 'qrcode';

const root = resolve(fileURLToPath(new URL('..', import.meta.url)));
const port = Number(process.env.PORT || 3333);
const apkPath = resolve(process.env.APK || `${root}/installer/dist/zpk-litert.apk`);
const modelPath = resolve(
  process.env.MODEL ||
    `${process.env.HOME}/.cache/huggingface/hub/models--litert-community--gemma-4-E2B-it-litert-lm/blobs/ab7838cdfc8f77e54d8ca45eadceb20452d9f01e4bfade03e5dce27911b27e42`,
);
const publicBaseUrl = (process.env.PUBLIC_URL || '').replace(/\/$/, '');
const lanBaseUrl = `http://${lanAddress()}:${port}`;
const baseUrl = publicBaseUrl || lanBaseUrl;
const appModelPath = '/data/user/0/gt.kan.kan_app/files/models/gemma-4-E2B-it.litertlm';
const litertInstallUrl = `${baseUrl}/zpk-litert.apk`;

const server = createServer(async (req, res) => {
  const url = new URL(req.url || '/', baseUrl);

  if (url.pathname === '/') {
    const qr = await QRCode.toDataURL(litertInstallUrl, { margin: 1, scale: 8 });
    sendHtml(res, page({ qr, url: litertInstallUrl }));
    return;
  }

  if (url.pathname === '/qr.svg') {
    const svg = await QRCode.toString(litertInstallUrl, {
      type: 'svg',
      margin: 1,
      scale: 8,
    });
    send(res, 200, 'image/svg+xml; charset=utf-8', svg);
    return;
  }

  if (url.pathname.endsWith('.apk')) {
    sendFile(res, apkPath, 'application/vnd.android.package-archive', {
      'content-disposition': 'attachment; filename="zpk-litert-release.apk"',
    });
    return;
  }

  if (url.pathname === '/zpk-litert.apk.sha256') {
    const body = existsSync(apkPath)
      ? `${sha256(apkPath)}  zpk-litert.apk\n`
      : 'missing apk\n';
    send(res, existsSync(apkPath) ? 200 : 404, 'text/plain; charset=utf-8', body);
    return;
  }

  if (url.pathname === '/models/gemma-4-E2B-it.litertlm') {
    sendFile(res, modelPath, 'application/octet-stream');
    return;
  }

  if (url.pathname === '/manifest.json') {
    const apk = apkMeta();
    sendJson(res, {
      app: 'ZPK Digital ID',
      apk: {
        url: litertInstallUrl,
        sha256: apk.sha256,
        bytes: apk.bytes,
        signed: 'release-sideload',
      },
      litertGemma: {
        modelUrl: `${baseUrl}/models/gemma-4-E2B-it.litertlm`,
        modelSha256: existsSync(modelPath) ? sha256(modelPath) : '',
        appModelPath,
      },
      installUrl: litertInstallUrl,
    });
    return;
  }

  send(res, 404, 'text/plain; charset=utf-8', 'not found');
});

server.listen(port, '0.0.0.0', () => {
  console.log(`ZPK wireless installer: ${baseUrl}`);
  console.log(`APK:   ${existsSync(apkPath) ? apkPath : `missing: ${apkPath}`}`);
  console.log(`Model: ${existsSync(modelPath) ? modelPath : `missing: ${modelPath}`}`);
  console.log(`QR:    ${baseUrl}/qr.svg`);
  console.log('');
  console.log('Cloudflare Tunnel option:');
  console.log(`  cloudflared tunnel --url http://127.0.0.1:${port}`);
  console.log(`  PUBLIC_URL=https://your-trycloudflare-url npm start`);
});

function sendFile(res, path, contentType, extraHeaders = {}) {
  if (!existsSync(path)) {
    send(res, 404, 'text/plain; charset=utf-8', `missing file: ${path}`);
    return;
  }
  const stat = statSync(path);
  res.writeHead(200, {
    'content-type': contentType || mime(path),
    'content-length': stat.size,
    'cache-control': 'no-store',
    'x-content-type-options': 'nosniff',
    'accept-ranges': 'bytes',
    ...extraHeaders,
  });
  createReadStream(path).pipe(res);
}

function sendHtml(res, body) {
  send(res, 200, 'text/html; charset=utf-8', body);
}

function sendJson(res, body) {
  send(res, 200, 'application/json; charset=utf-8', JSON.stringify(body, null, 2));
}

function send(res, status, contentType, body) {
  res.writeHead(status, {
    'content-type': contentType,
    'cache-control': 'no-store',
    'x-content-type-options': 'nosniff',
  });
  res.end(body);
}

function sha256(path) {
  const hash = createHash('sha256');
  const fd = openSync(path, 'r');
  const buffer = Buffer.allocUnsafe(8 * 1024 * 1024);
  try {
    while (true) {
      const bytes = readSync(fd, buffer, 0, buffer.length, null);
      if (bytes === 0) {
        break;
      }
      hash.update(buffer.subarray(0, bytes));
    }
  } finally {
    closeSync(fd);
  }
  return hash.digest('hex');
}

function apkMeta() {
  if (!existsSync(apkPath)) {
    return { sha256: '', bytes: 0 };
  }
  return { sha256: sha256(apkPath), bytes: statSync(apkPath).size };
}

function lanAddress() {
  for (const iface of Object.values(networkInterfaces())) {
    for (const addr of iface || []) {
      if (addr.family === 'IPv4' && !addr.internal) {
        return addr.address;
      }
    }
  }
  return '127.0.0.1';
}

function mime(path) {
  return extname(path) === '.svg' ? 'image/svg+xml' : 'application/octet-stream';
}

function page({ qr, url }) {
  const apk = apkMeta();
  const apkMib = apk.bytes ? (apk.bytes / 1024 / 1024).toFixed(1) : '0';
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>ZPK Wireless Installer</title>
  <style>
    body { margin: 0; font-family: system-ui, -apple-system, sans-serif; background: #f7f7f2; color: #17201d; }
    main { max-width: 780px; margin: 0 auto; padding: 28px; }
    h1 { font-size: 28px; margin: 0 0 8px; }
    .panel { border: 1px solid #cfd8d2; border-radius: 8px; padding: 18px; background: #fff; }
    .warn { border-color: #d8b65f; background: #fff9e8; }
    img { width: min(320px, 100%); height: auto; display: block; margin: 20px 0; }
    code { overflow-wrap: anywhere; }
    li { margin: 8px 0; }
    a { color: #006d5b; font-weight: 700; }
  </style>
</head>
<body>
  <main>
    <h1>ZPK Wireless Installer</h1>
    <p>Scan this QR from the Android phone to download the APK. Keep this Mac awake while the model downloads.</p>
    <section class="panel">
      <img src="${qr}" alt="Install QR code">
      <p><a href="${url}">Download ZPK Digital ID APK</a></p>
      <p><code>${url}</code></p>
      <p>Signed ARM64 release APK: <strong>${apkMib} MB</strong></p>
      <p>SHA-256: <code>${apk.sha256}</code></p>
      <p><a href="/zpk-litert.apk.sha256">Download SHA-256 file</a></p>
      <p>After install, Android may ask to allow installs from the browser. Keep this page open while the app downloads the Gemma 4 LiteRT-LM model from this same server.</p>
    </section>
    <section class="panel warn">
      <h2>If Android says package analysis failed</h2>
      <ul>
        <li>Delete the old APK from Downloads and download again. The correct ARM64 file is ${apkMib} MB.</li>
        <li>The phone must run Android 8/API 26 or newer.</li>
        <li>The phone must support ARM64 apps. Most modern Android phones do.</li>
        <li>Use Chrome or Files to open the downloaded APK and allow installs from that app.</li>
        <li>If an older ZPK build is installed, uninstall it first because the signing certificate changed.</li>
      </ul>
    </section>
  </main>
</body>
</html>`;
}
