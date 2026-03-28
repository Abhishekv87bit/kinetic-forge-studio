const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1600, height: 900 } });

  await page.goto('http://localhost:52341/06-3d-explorer.html', { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);

  const outDir = 'd:/Claude local/3d_design_agent/.superpowers/brainstorm/physical-transformer/screenshots';

  // Click Play to start animation
  await page.locator('.mode-btn:has-text("Play")').click();
  await page.waitForTimeout(500);

  // Go to back view to watch barrel cam + pendulum + drum
  await page.locator('.mode-btn:has-text("Back")').click();
  await page.waitForTimeout(2500);

  // Take screenshots at different time periods
  await page.screenshot({ path: `${outDir}/anim_back_t0.png` });
  console.log('Captured: anim_back_t0.png (t=0s)');

  await page.waitForTimeout(2000);
  await page.screenshot({ path: `${outDir}/anim_back_t2.png` });
  console.log('Captured: anim_back_t2.png (t=2s)');

  await page.waitForTimeout(2000);
  await page.screenshot({ path: `${outDir}/anim_back_t4.png` });
  console.log('Captured: anim_back_t4.png (t=4s)');

  await page.waitForTimeout(3000);
  await page.screenshot({ path: `${outDir}/anim_back_t7.png` });
  console.log('Captured: anim_back_t7.png (t=7s)');

  // Now check front view — spiral cams + error sliders animating
  await page.locator('.mode-btn:has-text("Front")').click();
  await page.waitForTimeout(2500);
  await page.screenshot({ path: `${outDir}/anim_front_t0.png` });
  console.log('Captured: anim_front_t0.png');

  await page.waitForTimeout(3000);
  await page.screenshot({ path: `${outDir}/anim_front_t3.png` });
  console.log('Captured: anim_front_t3.png');

  // Right view — pantograph breathing
  await page.locator('.mode-btn:has-text("Right")').click();
  await page.waitForTimeout(2500);
  await page.screenshot({ path: `${outDir}/anim_right_t0.png` });
  console.log('Captured: anim_right_t0.png');

  await page.waitForTimeout(3000);
  await page.screenshot({ path: `${outDir}/anim_right_t3.png` });
  console.log('Captured: anim_right_t3.png');

  // Top view — pin drum rotation
  await page.locator('.mode-btn:has-text("Top")').click();
  await page.waitForTimeout(2500);
  await page.screenshot({ path: `${outDir}/anim_top_t0.png` });
  console.log('Captured: anim_top_t0.png');

  await page.waitForTimeout(3000);
  await page.screenshot({ path: `${outDir}/anim_top_t3.png` });
  console.log('Captured: anim_top_t3.png');

  await browser.close();
  console.log('All animation screenshots captured.');
})();
