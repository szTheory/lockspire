defmodule Lockspire.Web.Admin.CSS do
  @moduledoc false

  @css """
  /* Lockspire Admin UI - Design Tokens & BEM Architecture */
  :root {
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

    /* Typography */
    --ls-font-sans: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    --ls-font-mono: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
    
    /* Colors */
    --ls-color-brand-50: #eff6ff;
    --ls-color-brand-100: #dbeafe;
    --ls-color-brand-500: #3b82f6;
    --ls-color-brand-600: #2563eb;
    --ls-color-brand-700: #1d4ed8;
    
    --ls-color-gray-50: #f9fafb;
    --ls-color-gray-100: #f3f4f6;
    --ls-color-gray-200: #e5e7eb;
    --ls-color-gray-300: #d1d5db;
    --ls-color-gray-400: #9ca3af;
    --ls-color-gray-500: #6b7280;
    --ls-color-gray-600: #4b5563;
    --ls-color-gray-700: #374151;
    --ls-color-gray-800: #1f2937;
    --ls-color-gray-900: #111827;

    /* Status Colors */
    --ls-color-success-bg: #dcfce7;
    --ls-color-success-text: #166534;
    --ls-color-warning-bg: #fef9c3;
    --ls-color-warning-text: #854d0e;
    --ls-color-danger-bg: #fee2e2;
    --ls-color-danger-text: #991b1b;
    --ls-color-info-bg: #e0f2fe;
    --ls-color-info-text: #075985;

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
    --ls-transition-fast: 150ms cubic-bezier(0.4, 0, 0.2, 1);
    --ls-transition-bounce: 300ms cubic-bezier(0.175, 0.885, 0.32, 1.275);
  }

  /* Base Styles */
  .lockspire-admin-shell {
    font-family: var(--ls-font-sans);
    color: var(--ls-color-gray-900);
    -webkit-font-smoothing: antialiased;
    background-color: var(--ls-color-gray-50);
    min-height: 100vh;
    display: flex;
    flex-direction: column;
  }

  /* Header & Nav */
  .lockspire-admin-header {
    padding: var(--ls-space-6) var(--ls-space-8);
    background: white;
    border-bottom: 1px solid var(--ls-color-gray-200);
  }

  .lockspire-admin-eyebrow {
    text-transform: uppercase;
    font-size: 0.75rem;
    font-weight: 600;
    letter-spacing: 0.05em;
    color: var(--ls-color-gray-500);
    margin: 0 0 var(--ls-space-1) 0;
  }

  .lockspire-admin-header h1 {
    margin: 0;
    font-size: 1.875rem;
    font-weight: 700;
    letter-spacing: -0.025em;
    text-wrap: balance;
  }

  .lockspire-admin-nav {
    display: flex;
    gap: var(--ls-space-6);
    padding: 0 var(--ls-space-8);
    background: white;
    border-bottom: 1px solid var(--ls-color-gray-200);
    overflow-x: auto;
  }

  .lockspire-admin-nav-item {
    padding: var(--ls-space-4) 0;
    color: var(--ls-color-gray-500);
    text-decoration: none;
    font-weight: 500;
    font-size: 0.875rem;
    border-bottom: 2px solid transparent;
    transition: color var(--ls-transition-fast), border-color var(--ls-transition-fast);
    min-height: 40px;
    display: flex;
    align-items: center;
  }

  .lockspire-admin-nav-item:hover {
    color: var(--ls-color-gray-900);
  }

  .lockspire-admin-nav-item-current {
    color: var(--ls-color-brand-600);
    border-bottom-color: var(--ls-color-brand-600);
  }

  .lockspire-admin-nav-item-disabled {
    opacity: 0.5;
    pointer-events: none;
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
    background: white;
    border-radius: var(--ls-radius-lg);
    box-shadow: var(--ls-shadow-sm);
    padding: var(--ls-space-6);
    margin-bottom: var(--ls-space-6);
  }

  .lockspire-admin-card header {
    margin-bottom: var(--ls-space-6);
  }

  .lockspire-admin-card h2 {
    margin: 0 0 var(--ls-space-2) 0;
    font-size: 1.25rem;
    font-weight: 600;
  }

  .lockspire-admin-card p {
    margin: 0;
    color: var(--ls-color-gray-500);
    font-size: 0.875rem;
    text-wrap: pretty;
  }

  /* Badges (Atomic Component) */
  .lockspire-admin-badge {
    display: inline-flex;
    align-items: center;
    padding: 0.125rem 0.625rem;
    border-radius: 9999px;
    font-size: 0.75rem;
    font-weight: 600;
    line-height: 1.25rem;
    white-space: nowrap;
  }

  .lockspire-admin-badge-active {
    background-color: var(--ls-color-success-bg);
    color: var(--ls-color-success-text);
  }

  .lockspire-admin-badge-disabled {
    background-color: var(--ls-color-gray-100);
    color: var(--ls-color-gray-700);
  }

  .lockspire-admin-badge-warning {
    background-color: var(--ls-color-warning-bg);
    color: var(--ls-color-warning-text);
  }

  .lockspire-admin-badge-danger {
    background-color: var(--ls-color-danger-bg);
    color: var(--ls-color-danger-text);
  }

  .lockspire-admin-badge-info {
    background-color: var(--ls-color-info-bg);
    color: var(--ls-color-info-text);
  }

  /* Empty States */
  .lockspire-admin-empty {
    text-align: center;
    padding: var(--ls-space-12) var(--ls-space-6);
    background: var(--ls-color-gray-50);
    border: 1px dashed var(--ls-color-gray-300);
    border-radius: var(--ls-radius-md); /* Concentric to outer card */
  }

  .lockspire-admin-empty h2 {
    font-size: 1.125rem;
    color: var(--ls-color-gray-900);
    margin-bottom: var(--ls-space-2);
  }

  .lockspire-admin-empty p {
    color: var(--ls-color-gray-500);
    font-size: 0.875rem;
  }

  /* Tabular Numbers for Data */
  .lockspire-admin-tabular {
    font-variant-numeric: tabular-nums;
    font-family: var(--ls-font-mono);
    font-size: 0.875rem;
  }

  /* Buttons (Micro-interactions) */
  .lockspire-admin-btn-primary {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: var(--ls-space-2) var(--ls-space-4);
    background-color: var(--ls-color-brand-600);
    color: white;
    border: none;
    border-radius: var(--ls-radius-md);
    font-weight: 500;
    font-size: 0.875rem;
    cursor: pointer;
    min-height: 40px; /* Hit area */
    transition-property: background-color, transform, box-shadow;
    transition-duration: 150ms;
    transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
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
    padding: var(--ls-space-2) var(--ls-space-4);
    background-color: white;
    color: var(--ls-color-gray-700);
    border: 1px solid var(--ls-color-gray-300);
    border-radius: var(--ls-radius-md);
    font-weight: 500;
    font-size: 0.875rem;
    cursor: pointer;
    min-height: 40px;
    transition-property: background-color, border-color, transform, box-shadow;
    transition-duration: 150ms;
    transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
  }

  .lockspire-admin-btn-secondary:hover {
    background-color: var(--ls-color-gray-50);
    border-color: var(--ls-color-gray-400);
  }

  .lockspire-admin-btn-secondary:active {
    transform: scale(0.96);
  }

  /* Tables */
  .lockspire-admin-table {
    width: 100%;
    border-collapse: collapse;
    text-align: left;
    font-size: 0.875rem;
  }

  .lockspire-admin-table th {
    padding: var(--ls-space-3) var(--ls-space-4);
    border-bottom: 1px solid var(--ls-color-gray-200);
    color: var(--ls-color-gray-500);
    font-weight: 600;
  }

  .lockspire-admin-table td {
    padding: var(--ls-space-4);
    border-bottom: 1px solid var(--ls-color-gray-100);
    color: var(--ls-color-gray-900);
    vertical-align: top;
  }

  .lockspire-admin-table tr:last-child td {
    border-bottom: none;
  }

  /* Form Shell */
  .lockspire-admin-form-shell {
    max-width: 600px;
    display: flex;
    flex-direction: column;
    gap: var(--ls-space-5);
  }

  .lockspire-admin-field {
    display: flex;
    flex-direction: column;
    gap: var(--ls-space-2);
  }

  .lockspire-admin-field label {
    font-size: 0.875rem;
    font-weight: 600;
    color: var(--ls-color-gray-700);
  }

  .lockspire-admin-field input[type="text"],
  .lockspire-admin-field input[type="password"],
  .lockspire-admin-field select,
  .lockspire-admin-field textarea {
    padding: var(--ls-space-2) var(--ls-space-3);
    border: 1px solid var(--ls-color-gray-300);
    border-radius: var(--ls-radius-md);
    font-family: inherit;
    font-size: 0.875rem;
    color: var(--ls-color-gray-900);
    transition: border-color var(--ls-transition-fast), box-shadow var(--ls-transition-fast);
  }

  .lockspire-admin-field input:focus,
  .lockspire-admin-field select:focus,
  .lockspire-admin-field textarea:focus {
    outline: none;
    border-color: var(--ls-color-brand-500);
    box-shadow: 0 0 0 3px var(--ls-color-brand-100);
  }

  .lockspire-admin-help {
    font-size: 0.75rem;
    color: var(--ls-color-gray-500);
    margin: 0;
  }

  .lockspire-admin-errors {
    margin: 0;
    padding: var(--ls-space-3);
    background-color: var(--ls-color-danger-bg);
    color: var(--ls-color-danger-text);
    border-radius: var(--ls-radius-md);
    font-size: 0.875rem;
    list-style-type: none;
  }

  .lockspire-admin-errors li {
    margin-bottom: var(--ls-space-1);
  }

  .lockspire-admin-errors li:last-child {
    margin-bottom: 0;
  }

  /* Secret Reveal */
  .lockspire-admin-secret-reveal {
    background-color: var(--ls-color-gray-50);
    border: 1px solid var(--ls-color-gray-200);
    border-radius: var(--ls-radius-md);
    padding: var(--ls-space-4);
    margin-top: var(--ls-space-4);
  }

  .lockspire-admin-secret-reveal h3 {
    margin: 0 0 var(--ls-space-2) 0;
    font-size: 1rem;
    color: var(--ls-color-success-text);
  }

  .lockspire-admin-secret-reveal code {
    font-family: var(--ls-font-mono);
    background-color: var(--ls-color-gray-200);
    padding: 0.125rem 0.25rem;
    border-radius: var(--ls-radius-sm);
    font-size: 0.875rem;
    word-break: break-all;
  }

  /* Actions */
  .lockspire-admin-actions {
    display: flex;
    gap: var(--ls-space-3);
    align-items: center;
    margin-top: var(--ls-space-6);
  }

  /* Summary Grid */
  .lockspire-admin-summary-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
    gap: var(--ls-space-4);
    margin-bottom: var(--ls-space-6);
  }

  .lockspire-admin-summary-stat {
    background: var(--ls-color-gray-50);
    border: 1px solid var(--ls-color-gray-200);
    border-radius: var(--ls-radius-md);
    padding: var(--ls-space-4);
    display: flex;
    flex-direction: column;
    align-items: flex-start;
  }

  .lockspire-admin-summary-value {
    font-size: 1.5rem;
    font-weight: 700;
    color: var(--ls-color-gray-900);
    margin-bottom: var(--ls-space-1);
    font-variant-numeric: tabular-nums;
  }

  .lockspire-admin-summary-label {
    font-size: 0.75rem;
    font-weight: 500;
    color: var(--ls-color-gray-500);
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }

  /* Sub-nav */
  .lockspire-admin-secondary-nav {
    display: flex;
    gap: var(--ls-space-4);
    margin-bottom: var(--ls-space-6);
    border-bottom: 1px solid var(--ls-color-gray-200);
  }

  .lockspire-admin-secondary-nav a {
    padding: var(--ls-space-2) 0;
    color: var(--ls-color-gray-500);
    text-decoration: none;
    font-size: 0.875rem;
    font-weight: 500;
    border-bottom: 2px solid transparent;
    transition: color var(--ls-transition-fast), border-color var(--ls-transition-fast);
  }

  .lockspire-admin-secondary-nav a:hover {
    color: var(--ls-color-gray-900);
  }
  """

  def get, do: @css
end
