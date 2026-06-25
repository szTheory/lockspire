defmodule Lockspire.Web.Admin.CSS do
  @moduledoc false

  @css """
  /* Lockspire Admin UI - Design Tokens & BEM Architecture */
  :root {
    color-scheme: light;

    /* Spacing Scale (4px baseline) */
    --ls-space-1: 0.25rem;
    --ls-space-2: 0.5rem;
    --ls-space-3: 0.75rem;
    --ls-space-4: 1rem;
    --ls-space-5: 1.25rem;
    --ls-space-6: 1.5rem;
    --ls-space-8: 2rem;
    --ls-space-10: 2.5rem;
    --ls-space-12: 3rem;

    /* Typography — Familjen Grotesk (display) / Inter (UI) / JetBrains Mono (code).
       Named, not shipped: no font files, no external fetch (host/OS provides). */
    --ls-font-display: "Familjen Grotesk", "Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    --ls-font-sans: "Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    --ls-font-mono: "JetBrains Mono", ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;

    /* Colors — Signal Cyan brand. 500 = hero (dark/accent), 600 = Deep Cyan
       (AA-safe text/action on light), 700 = hover. */
    --ls-color-brand-50: #ecfeff;
    --ls-color-brand-100: #cffafe;
    --ls-color-brand-500: #22d3ee;
    --ls-color-brand-600: #0e7490;
    --ls-color-brand-700: #155e75;

    --ls-color-gray-50: #f8fafc;
    --ls-color-gray-100: #f1f5f9;
    --ls-color-gray-200: #e2e8f0;
    --ls-color-gray-300: #cbd5e1;
    --ls-color-gray-400: #94a3b8;
    --ls-color-gray-500: #64748b;
    --ls-color-gray-600: #475569;
    --ls-color-gray-700: #334155;
    --ls-color-gray-800: #1f2937;
    --ls-color-gray-900: #111827;
    --ls-color-gray-950: #0b1220;

    /* Status Colors */
    --ls-color-success-bg: #dcfce7;
    --ls-color-success-text: #166534;
    --ls-color-success-border: #bbf7d0;
    --ls-color-warning-bg: #fef9c3;
    --ls-color-warning-text: #854d0e;
    --ls-color-warning-border: #fde68a;
    --ls-color-danger-bg: #fee2e2;
    --ls-color-danger-text: #991b1b;
    --ls-color-danger-border: #fecaca;
    --ls-color-info-bg: #cffafe;
    --ls-color-info-text: #155e75;
    --ls-color-info-border: #a5f3fc;

    --ls-color-success-bg-dark: #0d2b22;
    --ls-color-success-text-dark: #5eead4;
    --ls-color-success-border-dark: #14b8a6;
    --ls-color-warning-bg-dark: #2c2410;
    --ls-color-warning-text-dark: #f4b942;
    --ls-color-warning-border-dark: #a16207;
    --ls-color-danger-bg-dark: #2e1517;
    --ls-color-danger-text-dark: #fca5a5;
    --ls-color-danger-border-dark: #e35d6a;
    --ls-color-info-bg-dark: #0c2330;
    --ls-color-info-text-dark: #67e8f9;
    --ls-color-info-border-dark: #22d3ee;

    /* Radii (Concentric) */
    --ls-radius-sm: 0.125rem;
    --ls-radius-md: 0.375rem;
    --ls-radius-lg: 0.5rem;
    --ls-radius-xl: 0.75rem;

    /* Shadows (Layered) */
    --ls-shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
    --ls-shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
    --ls-shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);

    /* Transitions */
    --ls-motion-duration-fast: 150ms;
    --ls-motion-duration-medium: 220ms;
    --ls-motion-ease-standard: cubic-bezier(0.4, 0, 0.2, 1);
    --ls-motion-property-feedback: background-color, border-color, color, box-shadow, transform;
    --ls-transition-fast: var(--ls-motion-duration-fast) var(--ls-motion-ease-standard);

    /* Semantic Token Aliases */
    --ls-surface-page: var(--ls-color-gray-50);
    --ls-surface-panel: #ffffff;
    --ls-surface-muted: var(--ls-color-gray-100);
    --ls-surface-inverse: var(--ls-color-gray-950);
    --ls-text-strong: var(--ls-color-gray-950);
    --ls-text-body: var(--ls-color-gray-700);
    --ls-text-muted: var(--ls-color-gray-500);
    --ls-text-accent: var(--ls-color-brand-600);
    --ls-border-subtle: var(--ls-color-gray-200);
    --ls-border-strong: var(--ls-color-gray-300);
    --ls-status-success-bg: var(--ls-color-success-bg);
    --ls-status-success-text: var(--ls-color-success-text);
    --ls-status-success-border: var(--ls-color-success-border);
    --ls-status-warning-bg: var(--ls-color-warning-bg);
    --ls-status-warning-text: var(--ls-color-warning-text);
    --ls-status-warning-border: var(--ls-color-warning-border);
    --ls-status-danger-bg: var(--ls-color-danger-bg);
    --ls-status-danger-text: var(--ls-color-danger-text);
    --ls-status-danger-border: var(--ls-color-danger-border);
    --ls-status-info-bg: var(--ls-color-info-bg);
    --ls-status-info-text: var(--ls-color-info-text);
    --ls-status-info-border: var(--ls-color-info-border);
    --ls-control-height: 40px;
    --ls-control-padding-x: var(--ls-space-4);
    --ls-control-padding-y: var(--ls-space-2);
    --ls-type-label-size: 0.75rem;
    --ls-type-body-size: 0.875rem;
    --ls-type-heading-size: 1rem;
    --ls-type-display-size: 1.5rem;
    --ls-type-weight-regular: 400;
    --ls-type-weight-semibold: 600;
    --ls-type-line-label: 1.2;
    --ls-type-line-body: 1.5;
    --ls-type-line-heading: 1.25;
    --ls-type-line-display: 1.2;
    --ls-focus-ring-color: var(--ls-color-brand-600);
    --ls-focus-ring-width: 2px;
    --ls-focus-ring-offset: 3px;
    --ls-focus-ring-shadow: 0 0 0 3px var(--ls-color-brand-100);
    --ls-z-nav: 10;
    --ls-z-overlay: 50;
    --ls-z-modal: 100;
  }

  /* Base Styles */
  .lockspire-admin-shell {
    font-family: var(--ls-font-sans);
    color: var(--ls-text-strong);
    -webkit-font-smoothing: antialiased;
    background-color: var(--ls-surface-page);
    min-height: 100vh;
    display: flex;
    flex-direction: column;
  }

  .lockspire-admin-shell,
  .lockspire-admin-shell * {
    box-sizing: border-box;
  }

  /* Header & Nav */
  .lockspire-admin-header {
    padding: var(--ls-space-6) var(--ls-space-8);
    background: var(--ls-surface-panel);
    border-bottom: 1px solid var(--ls-border-subtle);
  }

  .lockspire-admin-eyebrow {
    text-transform: uppercase;
    font-size: 0.75rem;
    font-weight: 600;
    letter-spacing: 0.05em;
    color: var(--ls-text-accent);
    margin: 0 0 var(--ls-space-1) 0;
  }

  .lockspire-admin-brand {
    display: inline-flex;
    color: var(--ls-text-strong);
    margin: 0 0 var(--ls-space-4) 0;
  }

  .lockspire-admin-brand svg {
    height: 22px;
    width: auto;
    display: block;
  }

  .lockspire-admin-header h1 {
    margin: 0;
    font-family: var(--ls-font-display);
    font-size: 1.875rem;
    font-weight: 700;
    letter-spacing: -0.02em;
    text-wrap: balance;
  }

  .lockspire-admin-nav {
    display: flex;
    gap: var(--ls-space-8);
    padding: var(--ls-space-3) var(--ls-space-8) 0;
    background: var(--ls-surface-panel);
    border-bottom: 1px solid var(--ls-border-subtle);
    overflow-x: auto;
    max-width: 100%;
    scrollbar-width: thin;
  }

  .lockspire-admin-nav-group {
    display: flex;
    flex-direction: column;
    gap: var(--ls-space-1);
    flex: 0 0 auto;
  }

  .lockspire-admin-nav-group-label {
    color: var(--ls-text-muted);
    font-size: 0.6875rem;
    font-weight: 700;
    letter-spacing: 0.05em;
    line-height: 1;
    text-transform: uppercase;
  }

  .lockspire-admin-nav-group-items {
    display: flex;
    gap: var(--ls-space-4);
  }

  .lockspire-admin-nav-item {
    padding: var(--ls-space-3) 0 var(--ls-space-4);
    color: var(--ls-text-muted);
    text-decoration: none;
    font-weight: 500;
    font-size: 0.875rem;
    border-bottom: 2px solid transparent;
    transition-property: color, border-color;
    transition-duration: var(--ls-motion-duration-fast);
    transition-timing-function: var(--ls-motion-ease-standard);
    min-height: var(--ls-control-height);
    display: flex;
    align-items: center;
  }

  .lockspire-admin-nav-item:hover {
    color: var(--ls-text-strong);
  }

  .lockspire-admin-nav-item:focus-visible,
  .lockspire-admin-secondary-nav a:focus-visible,
  .lockspire-admin-btn-primary:focus-visible,
  .lockspire-admin-btn-secondary:focus-visible,
  .lockspire-admin-btn-danger:focus-visible,
  .lockspire-admin-resource-list a:focus-visible {
    outline: var(--ls-focus-ring-width) solid var(--ls-focus-ring-color);
    outline-offset: var(--ls-focus-ring-offset);
  }

  .lockspire-admin-nav-item-current {
    color: var(--ls-text-accent);
    border-bottom-color: var(--ls-text-accent);
  }

  .lockspire-admin-nav-item-disabled {
    opacity: 0.5;
    pointer-events: none;
  }

  .lockspire-admin-header-row {
    align-items: flex-start;
    display: flex;
    gap: var(--ls-space-4);
    justify-content: space-between;
    max-width: 100%;
    min-width: 0;
  }

  .lockspire-admin-header-title {
    min-width: 0;
  }

  .lockspire-admin-theme-control {
    align-items: center;
    display: flex;
    flex: 0 0 auto;
    gap: var(--ls-space-2);
  }

  .lockspire-admin-theme-control label {
    color: var(--ls-text-muted);
    font-size: var(--ls-type-label-size);
    font-weight: var(--ls-type-weight-semibold);
    line-height: var(--ls-type-line-label);
  }

  .lockspire-admin-theme-control select {
    background: var(--ls-surface-panel);
    border: 1px solid var(--ls-border-strong);
    border-radius: var(--ls-radius-md);
    color: var(--ls-text-body);
    font: inherit;
    min-height: var(--ls-control-height);
    padding: var(--ls-space-2) var(--ls-space-3);
  }

  .lockspire-admin-theme-control select:focus-visible {
    outline: var(--ls-focus-ring-width) solid var(--ls-focus-ring-color);
    outline-offset: var(--ls-focus-ring-offset);
  }

  .lockspire-admin-body {
    padding: var(--ls-space-8);
    max-width: 1200px;
    width: 100%;
    margin: 0 auto;
    flex: 1;
  }

  /* Cards (Atomic Component) */
  .lockspire-admin-card {
    background: var(--ls-surface-panel);
    border-radius: var(--ls-radius-lg);
    box-shadow: var(--ls-shadow-sm);
    max-width: 100%;
    min-width: 0;
    padding: var(--ls-space-6);
    margin-bottom: var(--ls-space-6);
  }

  .lockspire-admin-hero {
    align-items: flex-start;
    background: var(--ls-surface-panel);
    border-radius: var(--ls-radius-lg);
    box-shadow: var(--ls-shadow-sm);
    display: flex;
    gap: var(--ls-space-6);
    justify-content: space-between;
    margin-bottom: var(--ls-space-6);
    padding: var(--ls-space-8);
  }

  .lockspire-admin-hero h2 {
    color: var(--ls-text-strong);
    font-family: var(--ls-font-display);
    font-size: 1.5rem;
    line-height: 1.2;
    margin: 0 0 var(--ls-space-2);
    text-wrap: balance;
  }

  .lockspire-admin-hero p:not(.lockspire-admin-eyebrow) {
    color: var(--ls-text-body);
    font-size: 0.9375rem;
    line-height: 1.6;
    margin: 0;
    max-width: 56rem;
    text-wrap: pretty;
  }

  .lockspire-admin-page-hero__main {
    min-width: 0;
  }

  .lockspire-admin-page-hero__summary {
    margin-top: var(--ls-space-4);
  }

  .lockspire-admin-page-hero__actions {
    align-items: center;
    display: flex;
    flex: 0 0 auto;
    flex-wrap: wrap;
    gap: var(--ls-space-3);
  }

  .lockspire-admin-card header {
    margin-bottom: var(--ls-space-6);
  }

  .lockspire-admin-card h2 {
    color: var(--ls-text-strong);
    font-family: var(--ls-font-display);
    margin: 0 0 var(--ls-space-2) 0;
    font-size: 1.25rem;
    font-weight: 600;
  }

  .lockspire-admin-card p {
    margin: 0;
    color: var(--ls-text-muted);
    font-size: 0.875rem;
    text-wrap: pretty;
  }

  .lockspire-admin-card code,
  .lockspire-admin-detail-section code,
  .lockspire-admin-form-shell code {
    max-width: 100%;
    min-width: 0;
    overflow-wrap: anywhere;
    word-break: break-word;
  }

  /* Badges (Atomic Component) */
  .lockspire-admin-badge {
    display: inline-flex;
    align-items: center;
    border: 1px solid currentColor;
    gap: var(--ls-space-2);
    padding: 0.125rem 0.625rem;
    border-radius: 9999px;
    font-size: 0.75rem;
    font-weight: 600;
    line-height: 1.25rem;
    white-space: nowrap;
  }

  .lockspire-admin-badge::before {
    background: currentColor;
    border-radius: 9999px;
    content: "";
    display: inline-block;
    height: 0.45rem;
    width: 0.45rem;
  }

  .lockspire-admin-badge-active {
    background-color: var(--ls-status-success-bg);
    color: var(--ls-status-success-text);
  }

  .lockspire-admin-badge-disabled {
    background-color: var(--ls-surface-muted);
    color: var(--ls-text-body);
  }

  .lockspire-admin-badge-warning {
    background-color: var(--ls-status-warning-bg);
    color: var(--ls-status-warning-text);
  }

  .lockspire-admin-badge-danger {
    background-color: var(--ls-status-danger-bg);
    color: var(--ls-status-danger-text);
  }

  .lockspire-admin-badge-info {
    background-color: var(--ls-status-info-bg);
    color: var(--ls-status-info-text);
  }

  .lockspire-admin-alert {
    border-radius: var(--ls-radius-md);
    border: 1px solid var(--ls-border-subtle);
    font-size: 0.875rem;
    line-height: 1.5;
    margin-bottom: var(--ls-space-5);
    padding: var(--ls-space-4);
  }

  .lockspire-admin-alert h3,
  .lockspire-admin-alert h4 {
    font-size: 1rem;
    margin: 0 0 var(--ls-space-2);
  }

  .lockspire-admin-alert-warning {
    background-color: var(--ls-status-warning-bg);
    border-color: var(--ls-status-warning-border);
    color: var(--ls-status-warning-text);
  }

  .lockspire-admin-alert-danger {
    background-color: var(--ls-status-danger-bg);
    border-color: var(--ls-status-danger-border);
    color: var(--ls-status-danger-text);
  }

  .lockspire-admin-alert-info {
    background-color: var(--ls-status-info-bg);
    border-color: var(--ls-status-info-border);
    color: var(--ls-status-info-text);
  }

  /* Empty States */
  .lockspire-admin-empty {
    text-align: center;
    padding: var(--ls-space-12) var(--ls-space-6);
    background: var(--ls-surface-muted);
    border: 1px dashed var(--ls-border-strong);
    border-radius: var(--ls-radius-md); /* Concentric to outer card */
  }

  .lockspire-admin-empty h2 {
    font-size: 1.125rem;
    color: var(--ls-text-strong);
    margin-bottom: var(--ls-space-2);
  }

  .lockspire-admin-empty p {
    color: var(--ls-text-muted);
    font-size: 0.875rem;
  }

  /* Tabular Numbers for Data */
  .lockspire-admin-tabular {
    font-variant-numeric: tabular-nums;
    font-family: var(--ls-font-mono);
    font-size: 0.875rem;
  }

  /* Buttons (Micro-interactions) */
  .lockspire-admin-btn {
    text-decoration: none;
    white-space: normal;
  }

  .lockspire-admin-btn-primary {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: var(--ls-control-padding-y) var(--ls-control-padding-x);
    background-color: var(--ls-color-brand-600);
    color: var(--ls-surface-panel);
    border: none;
    border-radius: var(--ls-radius-md);
    font-weight: 500;
    font-size: 0.875rem;
    cursor: pointer;
    min-height: var(--ls-control-height);
    transition-property: var(--ls-motion-property-feedback);
    transition-duration: var(--ls-motion-duration-fast);
    transition-timing-function: var(--ls-motion-ease-standard);
  }

  .lockspire-admin-btn-primary:hover {
    background-color: var(--ls-color-brand-700);
    box-shadow: var(--ls-shadow-sm);
  }

  .lockspire-admin-btn-primary:active {
    transform: scale(0.96);
  }

  .lockspire-admin-btn-secondary {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: var(--ls-control-padding-y) var(--ls-control-padding-x);
    background-color: var(--ls-surface-panel);
    color: var(--ls-text-body);
    border: 1px solid var(--ls-border-strong);
    border-radius: var(--ls-radius-md);
    font-weight: 500;
    font-size: 0.875rem;
    cursor: pointer;
    min-height: var(--ls-control-height);
    transition-property: var(--ls-motion-property-feedback);
    transition-duration: var(--ls-motion-duration-fast);
    transition-timing-function: var(--ls-motion-ease-standard);
  }

  .lockspire-admin-btn-secondary:hover {
    background-color: var(--ls-surface-muted);
    border-color: var(--ls-border-strong);
  }

  .lockspire-admin-btn-secondary:active {
    transform: scale(0.96);
  }

  .lockspire-admin-btn-danger {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: var(--ls-control-padding-y) var(--ls-control-padding-x);
    background-color: var(--ls-surface-panel);
    color: var(--ls-status-danger-text);
    border: 1px solid var(--ls-status-danger-border);
    border-radius: var(--ls-radius-md);
    font-weight: 500;
    font-size: 0.875rem;
    cursor: pointer;
    min-height: var(--ls-control-height);
    transition-property: var(--ls-motion-property-feedback);
    transition-duration: var(--ls-motion-duration-fast);
    transition-timing-function: var(--ls-motion-ease-standard);
  }

  .lockspire-admin-btn-danger:hover {
    background-color: var(--ls-status-danger-bg);
    border-color: var(--ls-status-danger-border);
  }

  .lockspire-admin-btn-danger:active {
    transform: scale(0.96);
  }

  .lockspire-admin-btn-primary:disabled,
  .lockspire-admin-btn-secondary:disabled,
  .lockspire-admin-btn-danger:disabled,
  .lockspire-admin-btn-primary[aria-disabled="true"],
  .lockspire-admin-btn-secondary[aria-disabled="true"],
  .lockspire-admin-btn-danger[aria-disabled="true"] {
    cursor: not-allowed;
    opacity: 0.55;
    transform: none;
  }

  /* Tables */
  .lockspire-admin-table-wrap {
    overflow-x: auto;
    width: 100%;
  }

  .lockspire-admin-table {
    width: 100%;
    border-collapse: collapse;
    text-align: left;
    font-size: 0.875rem;
  }

  .lockspire-admin-table th {
    padding: var(--ls-space-3) var(--ls-space-4);
    border-bottom: 1px solid var(--ls-border-subtle);
    color: var(--ls-text-muted);
    font-weight: 600;
  }

  .lockspire-admin-table td {
    padding: var(--ls-space-4);
    border-bottom: 1px solid var(--ls-border-subtle);
    color: var(--ls-text-strong);
    vertical-align: top;
  }

  .lockspire-admin-table tr:last-child td {
    border-bottom: none;
  }

  /* Form Shell */
  .lockspire-admin-form-shell {
    max-width: 600px;
    min-width: 0;
    display: flex;
    flex-direction: column;
    gap: var(--ls-space-5);
  }

  .lockspire-admin-form-stack,
  .lockspire-admin-fieldset {
    display: flex;
    flex-direction: column;
    gap: var(--ls-space-5);
  }

  .lockspire-admin-fieldset {
    gap: var(--ls-space-4);
  }

  .lockspire-admin-field {
    display: flex;
    flex-direction: column;
    gap: var(--ls-space-2);
  }

  .lockspire-admin-field label {
    font-size: 0.875rem;
    font-weight: 600;
    color: var(--ls-text-body);
  }

  .lockspire-admin-required-marker {
    color: var(--ls-status-danger-text);
    font-weight: 700;
  }

  .lockspire-admin-field input[type="text"],
  .lockspire-admin-field input[type="password"],
  .lockspire-admin-field input[type="number"],
  .lockspire-admin-field input[type="url"],
  .lockspire-admin-field input[type="email"],
  .lockspire-admin-field select,
  .lockspire-admin-field textarea {
    min-height: var(--ls-control-height);
    min-width: 0;
    max-width: 100%;
    padding: var(--ls-control-padding-y) var(--ls-control-padding-x);
    background: var(--ls-surface-panel);
    border: 1px solid var(--ls-border-strong);
    border-radius: var(--ls-radius-md);
    font-family: inherit;
    font-size: 0.875rem;
    color: var(--ls-text-strong);
    transition-property: border-color, box-shadow;
    transition-duration: var(--ls-motion-duration-fast);
    transition-timing-function: var(--ls-motion-ease-standard);
  }

  .lockspire-admin-field input:focus-visible,
  .lockspire-admin-field select:focus-visible,
  .lockspire-admin-field textarea:focus-visible {
    outline: none;
    border-color: var(--ls-focus-ring-color);
    box-shadow: var(--ls-focus-ring-shadow);
  }

  .lockspire-admin-field input:disabled,
  .lockspire-admin-field select:disabled,
  .lockspire-admin-field textarea:disabled,
  .lockspire-admin-field input[aria-disabled="true"],
  .lockspire-admin-field select[aria-disabled="true"],
  .lockspire-admin-field textarea[aria-disabled="true"] {
    background: var(--ls-surface-muted);
    color: var(--ls-text-muted);
    cursor: not-allowed;
    opacity: 1;
  }

  .lockspire-admin-field input[readonly],
  .lockspire-admin-field textarea[readonly] {
    background: var(--ls-surface-muted);
    border-style: dashed;
  }

  .lockspire-admin-field-error input,
  .lockspire-admin-field-error select,
  .lockspire-admin-field-error textarea,
  .lockspire-admin-field input[aria-invalid="true"],
  .lockspire-admin-field select[aria-invalid="true"],
  .lockspire-admin-field textarea[aria-invalid="true"] {
    border-color: var(--ls-status-danger-border);
    box-shadow: 0 0 0 1px var(--ls-status-danger-border);
  }

  .lockspire-admin-field-errors {
    color: var(--ls-status-danger-text);
    display: grid;
    font-size: var(--ls-type-label-size);
    gap: var(--ls-space-1);
    line-height: var(--ls-type-line-body);
    list-style: none;
    margin: 0;
    padding: 0;
  }

  .lockspire-admin-checkbox-field {
    align-items: flex-start;
    display: flex;
    gap: var(--ls-space-3);
  }

  .lockspire-admin-checkbox-field input {
    flex: 0 0 auto;
    height: 1rem;
    margin-top: 0.2rem;
    width: 1rem;
  }

  .lockspire-admin-checkbox-field label,
  .lockspire-admin-checkbox-field span {
    color: var(--ls-text-body);
    font-size: 0.875rem;
    font-weight: 500;
    line-height: 1.5;
  }

  .lockspire-admin-help {
    font-size: 0.75rem;
    color: var(--ls-text-muted);
    margin: 0;
  }

  .lockspire-admin-help-block {
    display: grid;
    gap: var(--ls-space-2);
    margin: var(--ls-space-4) 0;
  }

  .lockspire-admin-filter-bar {
    align-items: end;
    background: var(--ls-surface-panel);
    border: 1px solid var(--ls-border-subtle);
    border-radius: var(--ls-radius-lg);
    display: grid;
    gap: var(--ls-space-4);
    grid-template-columns: minmax(0, 1fr) auto;
    margin-bottom: var(--ls-space-6);
    padding: var(--ls-space-4);
  }

  .lockspire-admin-filter-bar__fields {
    align-items: end;
    display: flex;
    flex-wrap: wrap;
    gap: var(--ls-space-3);
    min-width: 0;
  }

  .lockspire-admin-filter-bar__help {
    color: var(--ls-text-muted);
    font-size: var(--ls-type-label-size);
    grid-column: 1 / -1;
    line-height: var(--ls-type-line-label);
  }

  .lockspire-admin-filter-bar__help p {
    margin: 0;
  }

  .lockspire-admin-filter-bar__actions {
    align-items: center;
    display: flex;
    flex-wrap: wrap;
    gap: var(--ls-space-3);
    justify-content: flex-end;
  }

  .lockspire-admin-errors {
    margin: 0;
    padding: var(--ls-space-3);
    background-color: var(--ls-status-danger-bg);
    border: 1px solid var(--ls-status-danger-border);
    color: var(--ls-status-danger-text);
    border-radius: var(--ls-radius-md);
    font-size: 0.875rem;
    list-style-type: none;
  }

  .lockspire-admin-error-summary {
    background: var(--ls-status-danger-bg);
    border: 1px solid var(--ls-status-danger-border);
    border-radius: var(--ls-radius-md);
    color: var(--ls-status-danger-text);
    display: grid;
    gap: var(--ls-space-2);
    margin: 0 0 var(--ls-space-5);
    padding: var(--ls-space-4);
  }

  .lockspire-admin-error-summary h2 {
    color: inherit;
    font-family: var(--ls-font-display);
    font-size: var(--ls-type-heading-size);
    line-height: var(--ls-type-line-heading);
    margin: 0;
  }

  .lockspire-admin-error-summary ul {
    display: grid;
    gap: var(--ls-space-1);
    margin: 0;
    padding-left: var(--ls-space-5);
  }

  .lockspire-admin-error-summary:focus-visible {
    outline: var(--ls-focus-ring-width) solid var(--ls-focus-ring-color);
    outline-offset: var(--ls-focus-ring-offset);
  }

  .lockspire-admin-errors li {
    margin-bottom: var(--ls-space-1);
  }

  .lockspire-admin-errors li:last-child {
    margin-bottom: 0;
  }

  /* Secret Reveal */
  .lockspire-admin-secret-reveal {
    background-color: var(--ls-surface-muted);
    border: 1px solid var(--ls-border-subtle);
    border-radius: var(--ls-radius-md);
    padding: var(--ls-space-4);
    margin-top: var(--ls-space-4);
  }

  .lockspire-admin-secret-reveal h3 {
    margin: 0 0 var(--ls-space-2) 0;
    font-size: 1rem;
    color: var(--ls-status-success-text);
  }

  .lockspire-admin-secret-reveal code {
    font-family: var(--ls-font-mono);
    background-color: var(--ls-surface-panel);
    border: 1px solid var(--ls-border-subtle);
    padding: 0.125rem 0.25rem;
    border-radius: var(--ls-radius-sm);
    font-size: 0.875rem;
    word-break: break-all;
  }

  .lockspire-admin-copy-once-secret {
    display: grid;
    gap: var(--ls-space-3);
    max-width: 100%;
    min-width: 0;
  }

  .lockspire-admin-copy-once-secret p {
    color: var(--ls-text-body);
    font-size: var(--ls-type-body-size);
    line-height: var(--ls-type-line-body);
    margin: 0;
  }

  .lockspire-admin-copy-once-secret__value {
    display: grid;
    gap: var(--ls-space-2);
    max-width: 100%;
    min-width: 0;
    overflow-wrap: anywhere;
    word-break: break-word;
  }

  .lockspire-admin-copy-once-secret__label {
    color: var(--ls-text-muted);
    font-size: var(--ls-type-label-size);
    font-weight: var(--ls-type-weight-semibold);
    line-height: var(--ls-type-line-label);
    text-transform: uppercase;
  }

  /* Actions */
  .lockspire-admin-action-bar,
  .lockspire-admin-actions {
    display: flex;
    gap: var(--ls-space-3);
    align-items: center;
    margin-top: var(--ls-space-6);
    flex-wrap: wrap;
    max-width: 100%;
    min-width: 0;
  }

  .lockspire-admin-action-bar-compact {
    margin-bottom: var(--ls-space-4);
    margin-top: var(--ls-space-4);
  }

  .lockspire-admin-action-group {
    align-items: center;
    display: flex;
    flex-wrap: wrap;
    gap: var(--ls-space-3);
    max-width: 100%;
    min-width: 0;
  }

  .lockspire-admin-action-group__primary,
  .lockspire-admin-action-group__secondary,
  .lockspire-admin-action-group__destructive {
    align-items: center;
    display: flex;
    flex-wrap: wrap;
    gap: var(--ls-space-3);
    max-width: 100%;
    min-width: 0;
  }

  .lockspire-admin-action-group__destructive {
    border-left: 1px solid var(--ls-status-danger-border);
    margin-left: var(--ls-space-1);
    padding-left: var(--ls-space-3);
  }

  /* Summary Grid */
  .lockspire-admin-summary-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
    gap: var(--ls-space-4);
    margin-bottom: var(--ls-space-6);
  }

  .lockspire-admin-summary-grid-wide {
    grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  }

  .lockspire-admin-metric-grid {
    align-items: stretch;
  }

  .lockspire-admin-summary-stat {
    background: var(--ls-surface-muted);
    border: 1px solid var(--ls-border-subtle);
    border-radius: var(--ls-radius-md);
    padding: var(--ls-space-4);
    display: flex;
    flex-direction: column;
    align-items: flex-start;
  }

  .lockspire-admin-summary-value {
    font-size: 1.5rem;
    font-weight: 700;
    color: var(--ls-text-strong);
    margin-bottom: var(--ls-space-1);
    font-variant-numeric: tabular-nums;
  }

  .lockspire-admin-summary-label {
    font-size: 0.75rem;
    font-weight: 500;
    color: var(--ls-text-muted);
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }

  .lockspire-admin-task-card {
    background: var(--ls-surface-panel);
    border: 1px solid var(--ls-border-subtle);
    border-radius: var(--ls-radius-lg);
    box-shadow: var(--ls-shadow-sm);
    display: grid;
    gap: var(--ls-space-4);
    padding: var(--ls-space-5);
  }

  .lockspire-admin-task-card__header {
    align-items: flex-start;
    display: flex;
    gap: var(--ls-space-3);
    justify-content: space-between;
  }

  .lockspire-admin-task-card__header h3 {
    color: var(--ls-text-strong);
    font-size: var(--ls-type-heading-size);
    font-weight: var(--ls-type-weight-semibold);
    line-height: var(--ls-type-line-heading);
    margin: 0;
  }

  .lockspire-admin-task-card__header p,
  .lockspire-admin-task-card__body {
    color: var(--ls-text-body);
    font-size: var(--ls-type-body-size);
    line-height: var(--ls-type-line-body);
    margin: 0;
  }

  .lockspire-admin-task-card__state {
    border: 1px solid var(--ls-status-info-border);
    border-radius: 9999px;
    color: var(--ls-status-info-text);
    font-size: var(--ls-type-label-size);
    font-weight: var(--ls-type-weight-semibold);
    line-height: var(--ls-type-line-label);
    padding: var(--ls-space-1) var(--ls-space-2);
    white-space: nowrap;
  }

  .lockspire-admin-task-card__actions {
    align-items: center;
    display: flex;
    flex-wrap: wrap;
    gap: var(--ls-space-3);
  }

  /* Sub-nav */
  .lockspire-admin-secondary-nav {
    display: flex;
    gap: var(--ls-space-4);
    margin-bottom: var(--ls-space-6);
    border-bottom: 1px solid var(--ls-border-subtle);
  }

  .lockspire-admin-secondary-nav a {
    padding: var(--ls-space-2) 0;
    color: var(--ls-text-muted);
    text-decoration: none;
    font-size: 0.875rem;
    font-weight: 500;
    border-bottom: 2px solid transparent;
    transition-property: color, border-color;
    transition-duration: var(--ls-motion-duration-fast);
    transition-timing-function: var(--ls-motion-ease-standard);
  }

  .lockspire-admin-secondary-nav a:hover {
    color: var(--ls-text-strong);
  }

  .lockspire-admin-dashboard-grid {
    display: grid;
    gap: var(--ls-space-6);
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  }

  .lockspire-admin-resource-list,
  .lockspire-admin-client-list,
  .lockspire-admin-key-list,
  .lockspire-admin-token-list,
  .lockspire-admin-consent-list,
  .lockspire-admin-list {
    display: flex;
    flex-direction: column;
    gap: var(--ls-space-3);
    list-style: none;
    margin: 0;
    padding: 0;
  }

  .lockspire-admin-key-list {
    margin-top: var(--ls-space-4);
  }

  .lockspire-admin-resource-list a,
  .lockspire-admin-resource-list__item,
  .lockspire-admin-client-list li,
  .lockspire-admin-key-list li,
  .lockspire-admin-token-list li,
  .lockspire-admin-consent-list li,
  .lockspire-admin-list li {
    align-items: center;
    background: var(--ls-surface-muted);
    border: 1px solid var(--ls-border-subtle);
    border-radius: var(--ls-radius-md);
    color: var(--ls-text-body);
    display: flex;
    gap: var(--ls-space-3);
    justify-content: space-between;
    min-height: 48px;
    padding: var(--ls-space-3) var(--ls-space-4);
    text-decoration: none;
  }

  .lockspire-admin-resource-list a:hover,
  .lockspire-admin-resource-list__item:hover {
    background: var(--ls-surface-panel);
    box-shadow: var(--ls-shadow-sm);
  }

  .lockspire-admin-resource-list strong,
  .lockspire-admin-resource-list__title {
    color: var(--ls-text-strong);
    font-weight: 600;
    font-variant-numeric: tabular-nums;
  }

  .lockspire-admin-resource-list__main {
    display: flex;
    flex-direction: column;
    gap: var(--ls-space-1);
    min-width: 0;
  }

  .lockspire-admin-resource-list__title {
    color: var(--ls-text-accent);
    overflow-wrap: anywhere;
    text-decoration: none;
  }

  .lockspire-admin-resource-list__title:hover {
    color: var(--ls-color-brand-700);
    text-decoration: underline;
    text-underline-offset: 0.18em;
  }

  .lockspire-admin-resource-list__subtitle {
    color: var(--ls-text-muted);
    font-family: var(--ls-font-mono);
    font-size: 0.875rem;
    overflow-wrap: anywhere;
  }

  .lockspire-admin-resource-list__meta,
  .lockspire-admin-resource-list__actions,
  .lockspire-admin-badge-group,
  .lockspire-admin-status-cluster {
    align-items: center;
    display: flex;
    flex-wrap: wrap;
    gap: var(--ls-space-2);
  }

  .lockspire-admin-long-value {
    display: inline-block;
    max-width: 100%;
    min-width: 0;
    overflow-wrap: anywhere;
    word-break: break-word;
  }

  .lockspire-admin-long-value-mono {
    font-family: var(--ls-font-mono);
    font-variant-numeric: tabular-nums;
  }

  .lockspire-admin-client-workspace {
    display: grid;
    gap: var(--ls-space-6);
    grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
    max-width: 100%;
    min-width: 0;
    margin-bottom: var(--ls-space-6);
  }

  .lockspire-admin-client-workspace > * {
    max-width: 100%;
    min-width: 0;
  }

  .lockspire-admin-detail-section {
    margin-bottom: var(--ls-space-6);
  }

  .lockspire-admin-detail-section:last-child {
    margin-bottom: 0;
  }

  .lockspire-admin-detail-section h3 {
    color: var(--ls-text-strong);
    font-size: 1rem;
    font-weight: 650;
    margin: 0 0 var(--ls-space-3);
  }

  .lockspire-admin-section-heading {
    color: var(--ls-text-strong);
    font-size: 1rem;
    font-weight: 650;
    margin: var(--ls-space-6) 0 var(--ls-space-3);
  }

  .lockspire-admin-section-spaced {
    margin-top: var(--ls-space-5);
  }

  .lockspire-admin-detail-section p + p {
    margin-top: var(--ls-space-2);
  }

  .lockspire-admin-detail-section-muted {
    background: var(--ls-surface-muted);
    border: 1px solid var(--ls-border-subtle);
    border-radius: var(--ls-radius-md);
    padding: var(--ls-space-4);
  }

  .lockspire-admin-description-list {
    display: grid;
    gap: var(--ls-space-3);
    margin: 0;
    max-width: 100%;
    min-width: 0;
  }

  .lockspire-admin-description-list div {
    border-bottom: 1px solid var(--ls-border-subtle);
    display: grid;
    gap: var(--ls-space-2);
    grid-template-columns: minmax(120px, 0.45fr) minmax(0, 1fr);
    max-width: 100%;
    min-width: 0;
    padding-bottom: var(--ls-space-3);
  }

  .lockspire-admin-description-list div:last-child {
    border-bottom: none;
    padding-bottom: 0;
  }

  .lockspire-admin-description-list dt {
    color: var(--ls-text-muted);
    font-size: 0.75rem;
    font-weight: 700;
    letter-spacing: 0.05em;
    text-transform: uppercase;
  }

  .lockspire-admin-description-list dd {
    color: var(--ls-text-strong);
    margin: 0;
    min-width: 0;
    overflow-wrap: anywhere;
    word-break: break-word;
  }

  .lockspire-admin-redacted-value {
    color: var(--ls-text-muted);
    font-style: italic;
  }

  .lockspire-admin-value-list {
    display: grid;
    gap: var(--ls-space-2);
    list-style-position: inside;
    margin: 0;
    min-width: 0;
    overflow-wrap: anywhere;
    padding: 0;
    word-break: break-word;
  }

  .lockspire-admin-kicker {
    color: var(--ls-text-muted);
    font-size: 0.75rem;
    font-weight: 700;
    letter-spacing: 0.05em;
    margin: 0 0 var(--ls-space-1);
    text-transform: uppercase;
  }

  .lockspire-admin-display-value {
    color: var(--ls-text-strong) !important;
    font-family: var(--ls-font-mono);
    font-size: 1.125rem !important;
    font-variant-numeric: tabular-nums;
    min-width: 0;
    overflow-wrap: anywhere;
    word-break: break-word;
  }

  .lockspire-admin-empty-notice {
    background: var(--ls-surface-muted);
    border: 1px dashed var(--ls-border-strong);
    border-radius: var(--ls-radius-md);
    color: var(--ls-text-muted);
    font-size: 0.875rem;
    margin: var(--ls-space-4) 0 0;
    padding: var(--ls-space-4);
  }

  .lockspire-admin-code-block {
    background-color: var(--ls-surface-muted);
    border: 1px solid var(--ls-border-subtle);
    border-radius: var(--ls-radius-md);
    color: var(--ls-text-strong);
    font-family: var(--ls-font-mono);
    font-size: 0.875rem;
    max-width: 100%;
    min-width: 0;
    overflow-wrap: anywhere;
    padding: var(--ls-space-4);
    word-break: break-word;
  }

  .lockspire-admin-confirmation-panel {
    background: var(--ls-surface-panel);
    border: 1px solid var(--ls-border-subtle);
    border-radius: var(--ls-radius-lg);
    box-shadow: var(--ls-shadow-sm);
    margin-top: var(--ls-space-5);
    padding: var(--ls-space-5);
  }

  .lockspire-admin-confirmation-panel header {
    margin: 0 0 var(--ls-space-3);
  }

  .lockspire-admin-confirmation-panel h3 {
    color: var(--ls-text-strong);
    font-size: 1rem;
    margin: 0;
  }

  .lockspire-admin-confirmation-panel__body {
    color: var(--ls-text-body);
    font-size: 0.875rem;
    line-height: 1.5;
  }

  .lockspire-admin-confirmation-panel__actions {
    align-items: center;
    display: flex;
    flex-wrap: wrap;
    gap: var(--ls-space-3);
    margin-top: var(--ls-space-4);
    max-width: 100%;
    min-width: 0;
  }

  .lockspire-admin-confirmation-panel-warning {
    border-color: var(--ls-status-warning-border);
  }

  .lockspire-admin-confirmation-panel-danger {
    border-color: var(--ls-status-danger-border);
  }

  @media (max-width: 720px) {
    .lockspire-admin-header,
    .lockspire-admin-body,
    .lockspire-admin-nav {
      padding-left: var(--ls-space-4);
      padding-right: var(--ls-space-4);
    }

    .lockspire-admin-header-row {
      flex-direction: column;
    }

    .lockspire-admin-theme-control {
      align-items: flex-start;
      flex-direction: column;
      width: 100%;
    }

    .lockspire-admin-theme-control select {
      width: 100%;
    }

    .lockspire-admin-nav {
      flex-wrap: wrap;
      gap: var(--ls-space-3) var(--ls-space-6);
      overflow-x: visible;
      padding-bottom: var(--ls-space-3);
    }

    .lockspire-admin-nav-group {
      max-width: 100%;
    }

    .lockspire-admin-nav-group-items {
      flex-wrap: wrap;
      gap: var(--ls-space-3);
    }

    .lockspire-admin-nav-item {
      padding-bottom: var(--ls-space-2);
    }

    .lockspire-admin-hero {
      flex-direction: column;
      padding: var(--ls-space-5);
    }

    .lockspire-admin-page-hero__actions {
      align-items: stretch;
      width: 100%;
    }

    .lockspire-admin-filter-bar {
      grid-template-columns: 1fr;
    }

    .lockspire-admin-client-workspace {
      grid-template-columns: minmax(0, 1fr);
    }

    .lockspire-admin-form-shell {
      width: 100%;
      max-width: 100%;
    }

    .lockspire-admin-filter-bar__fields,
    .lockspire-admin-filter-bar__actions,
    .lockspire-admin-action-group,
    .lockspire-admin-action-group__primary,
    .lockspire-admin-action-group__secondary,
    .lockspire-admin-action-group__destructive,
    .lockspire-admin-task-card__header,
    .lockspire-admin-task-card__actions {
      align-items: stretch;
      flex-direction: column;
    }

    .lockspire-admin-action-group__destructive {
      border-left: 0;
      border-top: 1px solid var(--ls-status-danger-border);
      margin-left: 0;
      margin-top: var(--ls-space-1);
      padding-left: 0;
      padding-top: var(--ls-space-3);
    }

    .lockspire-admin-description-list div {
      grid-template-columns: 1fr;
    }

    .lockspire-admin-resource-list a,
    .lockspire-admin-resource-list__item,
    .lockspire-admin-client-list li,
    .lockspire-admin-key-list li,
    .lockspire-admin-token-list li,
    .lockspire-admin-consent-list li,
    .lockspire-admin-list li {
      align-items: flex-start;
      flex-direction: column;
    }

    .lockspire-admin-action-bar,
    .lockspire-admin-actions,
    .lockspire-admin-confirmation-panel__actions {
      align-items: stretch;
      flex-direction: column;
    }

    .lockspire-admin-btn-primary,
    .lockspire-admin-btn-secondary,
    .lockspire-admin-btn-danger {
      max-width: 100%;
      min-width: 0;
      width: 100%;
    }
  }

  @media (prefers-reduced-motion: reduce) {
    .lockspire-admin-shell *,
    .lockspire-admin-shell *::before,
    .lockspire-admin-shell *::after {
      animation-duration: 0.01ms !important;
      animation-iteration-count: 1 !important;
      scroll-behavior: auto !important;
      transition-duration: 0.01ms !important;
    }

    .lockspire-admin-btn-primary:active,
    .lockspire-admin-btn-secondary:active,
    .lockspire-admin-btn-danger:active {
      transform: none;
    }
  }
  """

  # Dark mode mirrors the brandbook: primitives remain stable and only semantic
  # aliases remap. Components consume aliases so theme changes do not require
  # component-specific overrides.
  @dark_vars """
    color-scheme: dark;

    --ls-surface-page: var(--ls-color-gray-950);
    --ls-surface-panel: #131c2e;
    --ls-surface-muted: var(--ls-color-gray-800);
    --ls-surface-inverse: var(--ls-color-gray-50);
    --ls-text-strong: var(--ls-color-gray-50);
    --ls-text-body: #c9d4e3;
    --ls-text-muted: #8a99ad;
    --ls-text-accent: var(--ls-color-brand-500);
    --ls-border-subtle: #1e293b;
    --ls-border-strong: #334155;

    --ls-status-success-bg: var(--ls-color-success-bg-dark);
    --ls-status-success-text: var(--ls-color-success-text-dark);
    --ls-status-success-border: var(--ls-color-success-border-dark);
    --ls-status-warning-bg: var(--ls-color-warning-bg-dark);
    --ls-status-warning-text: var(--ls-color-warning-text-dark);
    --ls-status-warning-border: var(--ls-color-warning-border-dark);
    --ls-status-danger-bg: var(--ls-color-danger-bg-dark);
    --ls-status-danger-text: var(--ls-color-danger-text-dark);
    --ls-status-danger-border: var(--ls-color-danger-border-dark);
    --ls-status-info-bg: var(--ls-color-info-bg-dark);
    --ls-status-info-text: var(--ls-color-info-text-dark);
    --ls-status-info-border: var(--ls-color-info-border-dark);

    --ls-focus-ring-color: var(--ls-color-brand-500);
    --ls-focus-ring-shadow: 0 0 0 3px rgb(34 211 238 / 0.35);
    --ls-shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.4);
    --ls-shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.5), 0 2px 4px -2px rgb(0 0 0 / 0.5);
    --ls-shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.55), 0 4px 6px -4px rgb(0 0 0 / 0.55);
  """

  # Primary actions use the semantic accent in dark mode while primitives stay
  # stable. The label flips to Obsidian for contrast against Signal Cyan.
  @dark_btn "background-color: var(--ls-text-accent); color: var(--ls-surface-page);"

  @dark_css """
  :root[data-theme="light"] {
    color-scheme: light;
    --ls-text-accent: var(--ls-color-brand-600);
  }

  @media (prefers-color-scheme: dark) {
    :root:not([data-theme="light"]) {
    #{@dark_vars}
    }
    :root:not([data-theme="light"]) .lockspire-admin-btn-primary { #{@dark_btn} }
    :root:not([data-theme="light"]) .lockspire-admin-btn-primary:hover { background-color: var(--ls-color-brand-100); }
  }
  :root[data-theme="dark"] {
  #{@dark_vars}
  }
  :root[data-theme="dark"] .lockspire-admin-btn-primary { #{@dark_btn} }
  :root[data-theme="dark"] .lockspire-admin-btn-primary:hover { background-color: var(--ls-color-brand-100); }
  """

  def get, do: @css <> @dark_css
end
