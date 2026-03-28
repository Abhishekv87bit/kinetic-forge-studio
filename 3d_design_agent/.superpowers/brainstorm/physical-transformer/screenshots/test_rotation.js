const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1600, height: 900 } });
  await page.goto('http://localhost:52341/06-3d-explorer.html', { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);
  const out = 'd:/Claude local/3d_design_agent/.superpowers/brainstorm/physical-transformer/screenshots';

  // Start animation
  await page.locator('.mode-btn:has-text("Play")').click();
  await page.waitForTimeout(500);

  // Go to back view to watch barrel cam
  await page.locator('.mode-btn:has-text("Back")').click();
  await page.waitForTimeout(3000); // wait for camera arc to complete

  for (let i = 0; i < 4; i++) {
    await page.screenshot({ path: `${out}/rot_back_${i}.png` });
    console.log(`rot_back_${i}.png`);
    await page.waitForTimeout(1500);
  }

  // Top view to watch drum
  await page.locator('.mode-btn:has-text("Top")').click();
  await page.waitForTimeout(3000);
  for (let i = 0; i < 3; i++) {
    await page.screenshot({ path: `${out}/rot_top_${i}.png` });
    console.log(`rot_top_${i}.png`);
    await page.waitForTimeout(1500);
  }

  await browser.close();
  console.log('Done.');
})();
