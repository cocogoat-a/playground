import fs from 'fs';
import path from 'path';
import { spawnSync } from 'child_process';
import pkg from './node_modules/playwright-core/index.js';

const { chromium } = pkg;

const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const sourceBase = 'C:\\Users\\daniv\\AppData\\Local\\Google\\Chrome\\User Data';
const sourceProfile = path.join(sourceBase, 'Profile 6');
const sourceLocalState = path.join(sourceBase, 'Local State');
const workDir = path.resolve('C:\\.codex\\Playground\\tmp\\gsc-browser');
const browserDataDir = path.join(workDir, 'chrome-data');
const targetProfile = path.join(browserDataDir, 'Profile 6');
const targetLocalState = path.join(browserDataDir, 'Local State');

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function copyWithRobocopy(src, dst) {
  ensureDir(path.dirname(dst));
  if (fs.existsSync(dst)) {
    fs.rmSync(dst, { recursive: true, force: true });
  }
  const args = [
    src,
    dst,
    '/MIR',
    '/NFL',
    '/NDL',
    '/NJH',
    '/NJS',
    '/NC',
    '/NS',
    '/NP',
    '/R:1',
    '/W:1',
    '/XD',
    'Cache',
    'Code Cache',
    'GPUCache',
    'GrShaderCache',
    'ShaderCache',
    'DawnWebGPUCache',
    'Service Worker',
  ];
  const result = spawnSync('robocopy', args, { encoding: 'utf8' });
  const ok = result.status === 0 || result.status === 1 || result.status === 2 || result.status === 3 || result.status === 4 || result.status === 5 || result.status === 6 || result.status === 7;
  if (!ok) {
    throw new Error(`robocopy failed for ${src} -> ${dst}: ${result.stdout}\n${result.stderr}`);
  }
}

async function main() {
  ensureDir(browserDataDir);
  fs.copyFileSync(sourceLocalState, targetLocalState);
  copyWithRobocopy(sourceProfile, targetProfile);

  const browser = await chromium.launchPersistentContext(browserDataDir, {
    executablePath: chromePath,
    headless: true,
    args: [
      '--profile-directory=Profile 6',
      '--no-first-run',
      '--no-default-browser-check',
    ],
  });

  const page = browser.pages()[0] || await browser.newPage();
  const network = [];
  page.on('response', async (resp) => {
    const url = resp.url();
    if (/search-console|webmasters|googleusercontent|accounts\.google|gstatic|search\.google/i.test(url)) {
      network.push({
        url,
        status: resp.status(),
        type: resp.request().resourceType(),
      });
    }
  });

  const targetUrl = 'https://search.google.com/search-console/performance/search-analytics?resource_id=sc-domain%3Aetavrian.com';
  await page.goto(targetUrl, { waitUntil: 'domcontentloaded', timeout: 120000 });
  await page.waitForTimeout(15000);

  const title = await page.title();
  const url = page.url();
  const bodyText = await page.locator('body').innerText({ timeout: 30000 }).catch(() => '');
  const text = bodyText.replace(/\r/g, '');

  console.log(JSON.stringify({
    title,
    url,
    startsWithLogin: /sign in|choose an account|account chooser/i.test(text),
    containsPerformance: /performance|search results/i.test(text),
    network,
    bodySample: text.slice(0, 12000),
  }, null, 2));

  await browser.close();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
