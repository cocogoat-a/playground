const { chromium } = require('playwright');

(async () => {
  const urls = [
    'https://www.etavrian.com',
    'https://www.etavrian.com/about-us',
    'https://www.etavrian.com/case-studies',
    'https://www.etavrian.com/seo',
    'https://www.etavrian.com/google-ads',
    'https://www.etavrian.com/contact-us',
    'https://www.linkedin.com/in/andrii-daniv/',
    'https://www.upwork.com/freelancers/~012bdb5a09009954f6',
    'https://www.upwork.com/ag/etavrian/'
  ];

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  for (const url of urls) {
    try {
      const resp = await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 45000 });
      await page.waitForTimeout(1200);
      const data = await page.evaluate(() => ({
        title: document.title || '',
        h1: (document.querySelector('h1')?.innerText || '').trim(),
        meta: document.querySelector('meta[name="description"]')?.getAttribute('content') || ''
      }));

      console.log('URL: ' + url);
      console.log('STATUS: ' + (resp ? resp.status() : 'n/a'));
      console.log('TITLE: ' + data.title);
      console.log('H1: ' + data.h1);
      console.log('META: ' + data.meta);
      console.log('---');
    } catch (e) {
      console.log('URL: ' + url);
      console.log('ERROR: ' + e.message);
      console.log('---');
    }
  }

  await browser.close();
})();
