// Onboarding walkthrough — 5-step modal for first-time users
// Shows once on first visit, stored in profile.onboardingComplete

import { getProfile, updateProfile } from '../state.js';

const STEPS = [
  {
    title: 'Welcome to KineticForge',
    icon: '&#9881;',
    content: `
      <p>KineticForge helps you design <strong>Margolin-style kinetic sculptures</strong> — mechanical artworks where waves, patterns, and mechanisms come alive through physical motion.</p>
      <p style="margin-top:8px;">This tool bridges the gap between <strong>mathematical wave design</strong> and <strong>physical fabrication</strong>.</p>
    `,
  },
  {
    title: 'Experiment First',
    icon: '&#127912;',
    content: `
      <p><strong>Experiment mode</strong> is your creative sandbox.</p>
      <ul style="margin-top:8px; padding-left:18px; line-height:1.8;">
        <li><strong>Wave Lab</strong> — Combine sine waves to create interference patterns</li>
        <li><strong>Patterns</strong> — Explore rose curves, Lissajous, spirographs</li>
        <li><strong>3D Waves</strong> — Design the actual wave surface your sculpture will produce</li>
        <li><strong>Mechanisms</strong> — Interactive linkage and cam tools</li>
      </ul>
      <p style="margin-top:8px;">When you find a wave you like, click <strong>"Use in Build Mode"</strong> to start engineering it.</p>
    `,
  },
  {
    title: 'Build When Ready',
    icon: '&#128736;',
    content: `
      <p><strong>Build mode</strong> is a 4-stage gated pipeline:</p>
      <div style="margin-top:10px; display:flex; align-items:center; gap:8px; flex-wrap:wrap;">
        <span style="background:var(--accent-dim); color:var(--accent); padding:4px 10px; border-radius:4px; font-weight:600;">1. Mechanize</span>
        <span style="color:var(--text-dim);">&#8594;</span>
        <span style="background:var(--accent-dim); color:var(--accent); padding:4px 10px; border-radius:4px; font-weight:600;">2. Simulate</span>
        <span style="color:var(--text-dim);">&#8594;</span>
        <span style="background:var(--accent-dim); color:var(--accent); padding:4px 10px; border-radius:4px; font-weight:600;">3. Build</span>
        <span style="color:var(--text-dim);">&#8594;</span>
        <span style="background:var(--accent-dim); color:var(--accent); padding:4px 10px; border-radius:4px; font-weight:600;">4. Iterate</span>
      </div>
      <p style="margin-top:10px;">Each stage must pass a <strong>gate check</strong> before the next unlocks. This ensures your sculpture will actually work when you build it.</p>
    `,
  },
  {
    title: 'Learn to Level Up',
    icon: '&#128218;',
    content: `
      <p><strong>Learn mode</strong> teaches the specific skills you need:</p>
      <ul style="margin-top:8px; padding-left:18px; line-height:1.8;">
        <li><strong>Exercises</strong> — Interactive, hands-on mechanism explorations</li>
        <li><strong>Skills</strong> — Track your mastery across four-bar, cams, gears, and more</li>
        <li><strong>Daily Tasks</strong> — Streak-based learning to build consistent practice</li>
        <li><strong>Curriculum</strong> — Structured path from beginner to professional</li>
      </ul>
      <p style="margin-top:8px;">Each exercise teaches one concept that directly applies to the Build pipeline.</p>
    `,
  },
  {
    title: 'Get Started',
    icon: '&#128640;',
    content: `
      <div style="display:grid; grid-template-columns:1fr 1fr; gap:12px; margin-top:8px;">
        <div style="background:var(--bg); padding:12px; border-radius:4px; border:1px solid var(--border);">
          <div style="font-weight:600; color:var(--accent); margin-bottom:4px;">Quick Start</div>
          <div style="font-size:11px; color:var(--text-dim); line-height:1.5;">
            1. Go to <strong>Experiment &gt; 3D Waves</strong><br>
            2. Add 2-3 wave sources<br>
            3. Click "Use in Build Mode"<br>
            4. Follow the pipeline
          </div>
        </div>
        <div style="background:var(--bg); padding:12px; border-radius:4px; border:1px solid var(--border);">
          <div style="font-weight:600; color:var(--accent); margin-bottom:4px;">Shortcuts</div>
          <div style="font-size:11px; color:var(--text-dim); line-height:1.5;">
            <strong>Ctrl+E</strong> — Experiment Mode<br>
            <strong>Ctrl+B</strong> — Build Mode<br>
            <strong>Ctrl+L</strong> — Learn Mode<br>
            <strong>Ctrl+1-4</strong> — Navigate stages
          </div>
        </div>
      </div>
      <p style="margin-top:12px; color:var(--text-dim); font-size:11px;">Look for the <strong style="color:var(--accent);">&#128161; guidance panels</strong> in the sidebar — they explain what each tool does and why it matters. You can dismiss them once you're comfortable.</p>
    `,
  },
];

/**
 * Show onboarding modal if the user hasn't completed it yet.
 * @returns {Promise<void>}
 */
export async function showOnboarding() {
  const profile = getProfile();
  if (profile?.onboardingComplete) return;

  return new Promise((resolve) => {
    let currentStep = 0;

    function render() {
      const step = STEPS[currentStep];
      const isLast = currentStep === STEPS.length - 1;
      const isFirst = currentStep === 0;

      // Remove existing overlay
      document.getElementById('onboarding-overlay')?.remove();

      const overlay = document.createElement('div');
      overlay.id = 'onboarding-overlay';
      overlay.className = 'modal-overlay';
      overlay.style.zIndex = '9995';

      overlay.innerHTML = `
        <div class="onboarding-modal" style="
          background: var(--bg-surface);
          border: 1px solid var(--accent-dim);
          border-radius: 8px;
          max-width: 520px;
          width: 90%;
          padding: 0;
          overflow: hidden;
          box-shadow: 0 20px 60px rgba(0,0,0,0.5);
        ">
          <!-- Progress bar -->
          <div style="height: 3px; background: var(--border);">
            <div style="height: 100%; width: ${((currentStep + 1) / STEPS.length) * 100}%; background: var(--accent); transition: width 0.3s;"></div>
          </div>

          <!-- Header -->
          <div style="padding: 20px 24px 0; display: flex; align-items: center; gap: 10px;">
            <span style="font-size: 24px;">${step.icon}</span>
            <div>
              <div style="font-size: 16px; font-weight: 700; color: var(--text);">${step.title}</div>
              <div style="font-size: 10px; color: var(--text-dim);">Step ${currentStep + 1} of ${STEPS.length}</div>
            </div>
          </div>

          <!-- Content -->
          <div style="padding: 16px 24px; font-size: 13px; color: var(--text); line-height: 1.6;">
            ${step.content}
          </div>

          <!-- Actions -->
          <div style="padding: 12px 24px 20px; display: flex; justify-content: space-between; align-items: center;">
            <div>
              ${!isFirst ? '<button id="onboard-prev" style="font-size: 12px; padding: 6px 16px;">Back</button>' : '<span></span>'}
            </div>
            <div style="display: flex; gap: 8px;">
              <button id="onboard-skip" style="font-size: 11px; padding: 4px 12px; opacity: 0.6;">Skip</button>
              <button id="onboard-next" class="primary" style="font-size: 12px; padding: 6px 20px;">${isLast ? 'Get Started' : 'Next'}</button>
            </div>
          </div>
        </div>
      `;

      document.body.appendChild(overlay);

      // Event handlers
      overlay.querySelector('#onboard-next').onclick = () => {
        if (isLast) {
          finish();
        } else {
          currentStep++;
          render();
        }
      };

      overlay.querySelector('#onboard-prev')?.addEventListener('click', () => {
        if (currentStep > 0) {
          currentStep--;
          render();
        }
      });

      overlay.querySelector('#onboard-skip').onclick = () => finish();
    }

    function finish() {
      document.getElementById('onboarding-overlay')?.remove();
      updateProfile({ onboardingComplete: true });
      resolve();
    }

    render();
  });
}

/**
 * Reset onboarding so it shows again (for testing or re-viewing).
 */
export async function resetOnboarding() {
  await updateProfile({ onboardingComplete: false });
}
