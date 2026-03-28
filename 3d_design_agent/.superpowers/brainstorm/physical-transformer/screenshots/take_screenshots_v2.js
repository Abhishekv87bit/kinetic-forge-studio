const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1600, height: 900 } });

  await page.goto('http://localhost:52341/06-3d-explorer.html', { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);

  const outDir = 'd:/Claude local/3d_design_agent/.superpowers/brainstorm/physical-transformer/screenshots';

  // Click Play to start animation
  const playBtn = await page.locator('.mode-btn:has-text("Play")');
  await playBtn.click();
  await page.waitForTimeout(2000);

  // Take animated free orbit
  await page.screenshot({ path: `${outDir}/v2_animated_free.png` });
  console.log('Captured: v2_animated_free.png');

  // Front view
  await page.locator('.mode-btn:has-text("Front")').click();
  await page.waitForTimeout(2500);
  await page.screenshot({ path: `${outDir}/v2_front.png` });
  console.log('Captured: v2_front.png');

  // Back view
  await page.locator('.mode-btn:has-text("Back")').click();
  await page.waitForTimeout(2500);
  await page.screenshot({ path: `${outDir}/v2_back.png` });
  console.log('Captured: v2_back.png');

  // Right view
  await page.locator('.mode-btn:has-text("Right")').click();
  await page.waitForTimeout(2500);
  await page.screenshot({ path: `${outDir}/v2_right.png` });
  console.log('Captured: v2_right.png');

  // Explode view
  await page.locator('.mode-btn:has-text("Free")').click();
  await page.waitForTimeout(1500);
  await page.locator('.mode-btn:has-text("Explode")').click();
  await page.waitForTimeout(3000);
  await page.screenshot({ path: `${outDir}/v2_exploded.png` });
  console.log('Captured: v2_exploded.png');

  // Human POV
  await page.locator('.mode-btn:has-text("Collapse")').click();
  await page.waitForTimeout(1500);
  await page.locator('.mode-btn:has-text("Human")').click();
  await page.waitForTimeout(2500);
  await page.screenshot({ path: `${outDir}/v2_human.png` });
  console.log('Captured: v2_human.png');

  await browser.close();
  console.log('All v2 screenshots captured.');
})();
