const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1600, height: 900 } });

  await page.goto('http://localhost:52341/06-3d-explorer.html', { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);

  const outDir = 'd:/Claude local/3d_design_agent/.superpowers/brainstorm/physical-transformer/screenshots';

  // Start from free orbit (default)
  await page.screenshot({ path: `${outDir}/cam_free_start.png` });
  console.log('Captured: free start position');

  // Click Front — capture during transition AND at arrival
  await page.locator('.mode-btn:has-text("Front")').click();
  await page.waitForTimeout(800);
  await page.screenshot({ path: `${outDir}/cam_to_front_mid.png` });
  console.log('Captured: mid-transition to front');

  await page.waitForTimeout(1500);
  await page.screenshot({ path: `${outDir}/cam_to_front_late.png` });
  console.log('Captured: late transition to front');

  await page.waitForTimeout(2000);
  await page.screenshot({ path: `${outDir}/cam_front_arrived.png` });
  console.log('Captured: arrived at front');

  // Now from front → back (most extreme transition, goes through machine)
  await page.locator('.mode-btn:has-text("Back")').click();
  await page.waitForTimeout(800);
  await page.screenshot({ path: `${outDir}/cam_front_to_back_mid.png` });
  console.log('Captured: mid-transition front→back');

  await page.waitForTimeout(1500);
  await page.screenshot({ path: `${outDir}/cam_front_to_back_late.png` });
  console.log('Captured: late transition front→back');

  await page.waitForTimeout(2000);
  await page.screenshot({ path: `${outDir}/cam_back_arrived.png` });
  console.log('Captured: arrived at back');

  // Back → Right
  await page.locator('.mode-btn:has-text("Right")').click();
  await page.waitForTimeout(2500);
  await page.screenshot({ path: `${outDir}/cam_right_arrived.png` });
  console.log('Captured: arrived at right');

  await browser.close();
  console.log('All camera path screenshots captured.');
})();
