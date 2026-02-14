// Reusable external resource link renderer
// Renders a list of clickable links that open in new browser tabs

import { getResourcesForContext } from '../resources.js';

const CATEGORY_ICONS = {
  tool: '\u{1F527}',      // wrench
  repo: '\u{1F4E6}',      // package
  tutorial: '\u{1F4D6}',  // book
  community: '\u{1F465}', // people
  book: '\u{1F4DA}',      // books
  plans: '\u{1F4CB}',     // clipboard
  artist: '\u{1F3A8}',    // palette
  video: '\u{1F3AC}'      // clapper
};

/**
 * Render external resource links as HTML string (for sidebar sections)
 * @param {string} context - The context key (e.g. 'discover', 'mechanize', 'skills-waves')
 * @param {object} options - { maxItems: 5, showCategory: true, compact: false }
 * @returns {string} HTML string for use in sidebar section html property
 */
export function renderResourceLinksHTML(context, options = {}) {
  const { maxItems = 5, showCategory = true, compact = false } = options;
  const resources = getResourcesForContext(context);

  if (resources.length === 0) return '';

  const items = resources.slice(0, maxItems);
  const linksHTML = items.map(r => {
    const icon = showCategory ? `<span class="ext-cat">${CATEGORY_ICONS[r.category] || ''}</span>` : '';
    const desc = compact ? '' : `<span class="ext-desc">${r.description}</span>`;
    return `
      <a href="${r.url}" target="_blank" rel="noopener noreferrer" class="ext-link" title="${r.description}">
        ${icon}
        <span class="ext-name">${r.name}</span>
        <span class="ext-arrow">\u2197</span>
        ${desc}
      </a>
    `;
  }).join('');

  return `<div class="ext-links">${linksHTML}</div>`;
}

/**
 * Create a sidebar section object for resources
 * @param {string} title - Section title (e.g. 'External Tools', 'Resources')
 * @param {string} context - The context key
 * @param {object} options - Rendering options
 * @returns {object|null} Sidebar section object or null if no resources
 */
export function createResourceSection(title, context, options = {}) {
  const html = renderResourceLinksHTML(context, options);
  if (!html) return null;
  return { title, html };
}

/**
 * Render resource links for multiple contexts (merged, deduplicated)
 * @param {string[]} contexts - Array of context keys
 * @param {object} options - Rendering options
 * @returns {string} HTML string
 */
export function renderMultiContextLinks(contexts, options = {}) {
  const { maxItems = 5, showCategory = true, compact = false } = options;
  const seen = new Set();
  const resources = [];

  for (const ctx of contexts) {
    for (const r of getResourcesForContext(ctx)) {
      if (!seen.has(r.id)) {
        seen.add(r.id);
        resources.push(r);
      }
    }
  }

  if (resources.length === 0) return '';

  const items = resources.slice(0, maxItems);
  const linksHTML = items.map(r => {
    const icon = showCategory ? `<span class="ext-cat">${CATEGORY_ICONS[r.category] || ''}</span>` : '';
    const desc = compact ? '' : `<span class="ext-desc">${r.description}</span>`;
    return `
      <a href="${r.url}" target="_blank" rel="noopener noreferrer" class="ext-link" title="${r.description}">
        ${icon}
        <span class="ext-name">${r.name}</span>
        <span class="ext-arrow">\u2197</span>
        ${desc}
      </a>
    `;
  }).join('');

  return `<div class="ext-links">${linksHTML}</div>`;
}
