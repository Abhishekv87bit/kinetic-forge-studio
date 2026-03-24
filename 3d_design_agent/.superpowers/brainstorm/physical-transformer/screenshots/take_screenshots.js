const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1600, height: 900 } });

  await page.goto('http://localhost:52341/06-3d-explorer.html', { waitUntil: 'networkidle' });
  // Wait for Three.js to render
  await page.waitForTimeout(3000);

  const views = [
    'free',    // default orbit
    'front',   // Front — Weights triptych
    'back',    // Back — Motor
    'left',    // Left — I/O Prisms
    'right',   // Right — Compute
    'top',     // Top — Pin Drum
    'human',   // Human POV
  ];

  const outDir = 'd:/Claude local/3d_design_agent/.superpowers/brainstorm/physical-transformer/screenshots';

  for (const view of views) {
    // Click the view button
    const buttons = await page.$$('.mode-btn');
    for (const btn of buttons) {
      const text = await btn.textContent();
      if (view === 'free' && text.includes('Free Orbit')) { await btn.click(); break; }
      if (view === 'front' && text.includes('Front')) { await btn.click(); break; }
      if (view === 'back' && text.includes('Back')) { await btn.click(); break; }
      if (view === 'left' && text.includes('Left')) { await btn.click(); break; }
      if (view === 'right' && text.includes('Right')) { await btn.click(); break; }
      if (view === 'top' && text.includes('Top')) { await btn.click(); break; }
      if (view === 'human' && text.includes('Human')) { await btn.click(); break; }
    }

    // Wait for camera animation to complete
    await page.waitForTimeout(2500);

    await page.screenshot({ path: `${outDir}/view_${view}.png`, fullPage: false });
    console.log(`Captured: view_${view}.png`);
  }

  // Also capture exploded view
  const explodeBtn = await page.$('.mode-btn:has-text("Explode")');
  if (explodeBtn) {
    await explodeBtn.click();
    await page.waitForTimeout(2000);
    await page.screenshot({ path: `${outDir}/view_exploded.png`, fullPage: false });
    console.log('Captured: view_exploded.png');
  }

  await browser.close();
  console.log('All screenshots captured.');
})();
