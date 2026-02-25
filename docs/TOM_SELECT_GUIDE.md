# Tom Select - Multi-Select Combo Box

This document covers the setup, usage, and troubleshooting of **Tom Select** in the ST Insight Hub application. Tom Select replaces native `<select multiple>` elements with searchable, tag-based combo boxes.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Setup](#setup)
  - [1. Vendor the ESM Bundle](#1-vendor-the-esm-bundle)
  - [2. Register in Sprockets Manifest](#2-register-in-sprockets-manifest)
  - [3. Pin in Importmap](#3-pin-in-importmap)
  - [4. Add CSS to Layout](#4-add-css-to-layout)
  - [5. Stimulus Controller](#5-stimulus-controller)
- [Usage](#usage)
  - [Basic Multi-Select](#basic-multi-select)
  - [With Placeholder](#with-placeholder)
  - [Limiting Max Selections](#limiting-max-selections)
  - [Single Select](#single-select)
- [How It Works](#how-it-works)
- [Current Usage in the App](#current-usage-in-the-app)
- [Troubleshooting](#troubleshooting)
  - [Asset Not Precompiled Error](#asset-not-precompiled-error)
  - [Module Not Found / Import Error](#module-not-found--import-error)
  - [Tom Select Not Initializing in Modals](#tom-select-not-initializing-in-modals)
  - [Styles Not Applied / Looks Broken](#styles-not-applied--looks-broken)
  - [Selected Values Not Submitted](#selected-values-not-submitted)
  - [Dropdown Hidden Behind Modal](#dropdown-hidden-behind-modal)
- [Updating Tom Select](#updating-tom-select)
- [References](#references)

---

## Overview

**Tom Select** is a lightweight (~54KB), dependency-free, extensible `<select>` UI control. It provides:

- Searchable dropdown with type-ahead filtering
- Tag-style chips for selected items with remove buttons
- Keyboard navigation support
- Plugin architecture (remove_button, clear_button, etc.)
- No jQuery dependency

We use the **Bootstrap 5 theme** for visual consistency with the rest of the application.

---

## Architecture

```
config/importmap.rb                          → Pins "tom-select" to vendored JS
vendor/javascript/tom-select.js              → Self-contained ESM bundle (from esm.sh)
app/assets/config/manifest.js                → Registers vendor/javascript for Sprockets
app/javascript/controllers/tom_select_controller.js → Stimulus controller
app/views/layouts/dashboard/application.html.erb    → Tom Select Bootstrap 5 CSS (CDN)
```

**Why vendor instead of CDN for JS?**

Rails importmap requires ES modules (ESM). The standard Tom Select npm package ships separate files with relative imports that don't work with importmap's flat module resolution. We use a **pre-bundled ESM build** from `esm.sh` that inlines all dependencies into a single file.

The CSS, however, is loaded directly from jsDelivr CDN since stylesheets don't have module resolution issues.

---

## Setup

### 1. Vendor the ESM Bundle

Download the self-contained ESM bundle from esm.sh:

```bash
curl -sL "https://esm.sh/tom-select@2.4.3/es2022/tom-select.bundle.mjs" \
  -o vendor/javascript/tom-select.js
```

> **Why esm.sh?** It produces a single-file ESM bundle with all dependencies inlined. The standard npm package (`dist/esm/tom-select.complete.js`) uses relative imports (`./plugins/...`, `./contrib/...`) that fail with importmap since only the entry file gets vendored.

> **Why not jsDelivr `+esm`?** The `+esm` endpoint on jsDelivr also works as a CDN URL, but vendoring locally ensures offline development works and avoids CORS issues.

### 2. Register in Sprockets Manifest

In `app/assets/config/manifest.js`, add:

```javascript
//= link_tree ../../../vendor/javascript .js
```

This tells Sprockets to precompile files in `vendor/javascript/` so Rails can serve them via the asset pipeline.

### 3. Pin in Importmap

In `config/importmap.rb`, add:

```ruby
# Tom Select (multi-select combo box) - vendored ESM bundle from esm.sh
pin "tom-select", to: "tom-select.js"
```

The `to: "tom-select.js"` resolves to the vendored file via the asset pipeline.

### 4. Add CSS to Layout

In `app/views/layouts/dashboard/application.html.erb`, add inside `<head>`:

```erb
<!-- Tom Select CSS for multi-select combo boxes -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/tom-select@2.4.3/dist/css/tom-select.bootstrap5.min.css">
```

### 5. Stimulus Controller

The file `app/javascript/controllers/tom_select_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus";
import TomSelect from "tom-select";

export default class extends Controller {
  static values = {
    placeholder: { type: String, default: "Select..." },
    maxItems: { type: Number, default: 0 },
  };

  connect() {
    this.tomSelect = new TomSelect(this.element, {
      plugins: ["remove_button"],
      placeholder: this.placeholderValue,
      maxItems: this.maxItemsValue || null, // 0 or null = unlimited
      allowEmptyOption: true,
      closeAfterSelect: false,
      hidePlaceholder: true,
    });
  }

  disconnect() {
    if (this.tomSelect) {
      this.tomSelect.destroy();
    }
  }
}
```

The controller automatically registers via `stimulus-loading` since it follows the `*_controller.js` naming convention.

---

## Usage

### Basic Multi-Select

Add `data-controller="tom-select"` to any `<select>` element:

```erb
<%= f.select :user_ids,
    options_for_select(users.pluck(:name, :id), selected_ids),
    { include_blank: true },
    {
      multiple: true,
      data: { controller: "tom-select" }
    }
%>
```

### With Placeholder

```erb
<%= f.select :user_ids,
    options_for_select(users.pluck(:name, :id), selected_ids),
    { include_blank: true },
    {
      multiple: true,
      data: {
        controller: "tom-select",
        tom_select_placeholder_value: "Search and select users..."
      }
    }
%>
```

### Limiting Max Selections

Limit to a maximum number of selections:

```erb
data: {
  controller: "tom-select",
  tom_select_max_items_value: 3
}
```

### Single Select

Works with single selects too (non-multiple). Tom Select transforms it into a searchable dropdown:

```erb
<%= f.select :company_id,
    options_for_select(companies.pluck(:name, :id), selected_id),
    { include_blank: "Select a company..." },
    {
      data: {
        controller: "tom-select",
        tom_select_max_items_value: 1
      }
    }
%>
```

---

## How It Works

1. **Page loads** → Stimulus scans the DOM for `data-controller="tom-select"`
2. **`connect()`** → Tom Select initializes on the `<select>` element, hiding the native select and rendering a rich UI
3. **User interacts** → Tom Select manages the underlying `<select>` options (selecting/deselecting)
4. **Form submits** → The native `<select>` values are submitted normally — no special handling needed
5. **`disconnect()`** → When navigating away (Turbo) or closing a modal, Tom Select is destroyed to prevent memory leaks

This Turbo-safe lifecycle (init on `connect`, destroy on `disconnect`) ensures the widget works correctly with:

- Turbo Frame navigation
- Turbo Stream updates
- Bootstrap modal open/close cycles

---

## Current Usage in the App

### Dashboard Form (`app/views/dashboards/_form.html.erb`)

The "Assign Users (Client)" field in the dashboard create/edit modal uses Tom Select for multi-user selection. Only visible to Superadmin users.

```erb
<% if current_user.superadmin? %>
  <%= f.select :user_ids,
      options_for_select(
        @project.company.users.kept.joins(:role)
          .where.not(roles: { name: 'Superadmin' })
          .order(:name).pluck(:name, :id),
        @dashboard.user_ids
      ),
      { include_blank: true },
      {
        class: "form-select",
        multiple: true,
        data: {
          controller: "tom-select",
          tom_select_placeholder_value: "Search and select users..."
        }
      }
  %>
<% end %>
```

---

## Troubleshooting

### Asset Not Precompiled Error

**Error:**

```
ActionView::Template::Error: Asset `tom-select.js` was not declared to be precompiled in production.
Declare links to your assets in `app/assets/config/manifest.js`.
```

**Cause:** Sprockets doesn't know about `vendor/javascript/`. The importmap pin resolves the module name to a filename, but Sprockets must also know to serve it.

**Fix:** Add to `app/assets/config/manifest.js`:

```javascript
//= link_tree ../../../vendor/javascript .js
```

Then restart the server.

---

### Module Not Found / Import Error

**Error (browser console):**

```
Failed to resolve module specifier "tom-select"
```

**Possible causes:**

1. **Missing importmap pin** — Ensure `config/importmap.rb` has:

   ```ruby
   pin "tom-select", to: "tom-select.js"
   ```

2. **Vendored file is not ESM** — The file in `vendor/javascript/tom-select.js` must be a valid ES module with `export default`. Verify:

   ```bash
   # Should find an export statement
   grep "export" vendor/javascript/tom-select.js
   ```

   If not, re-download from esm.sh (see [Setup step 1](#1-vendor-the-esm-bundle)).

3. **Wrong CDN URL used in pin** — Do NOT use UMD builds like `tom-select.complete.min.js`. Importmap requires ESM.

---

### Tom Select Not Initializing in Modals

**Symptom:** The select looks like a normal `<select>` inside a Bootstrap modal.

**Possible causes:**

1. **Stimulus controller not connecting** — Check browser console for JS errors. The form content loaded via Turbo Frame should still trigger Stimulus `connect()`.

2. **Duplicate initialization** — If the modal content is cached and re-inserted, Tom Select might already be initialized. The `disconnect()` handler in the Stimulus controller prevents this by destroying the instance when the element is removed.

3. **Turbo Frame caching** — Clear the Turbo cache:
   ```javascript
   Turbo.cache.clear();
   ```

---

### Styles Not Applied / Looks Broken

**Symptom:** Tom Select initializes but looks unstyled or clashes with Bootstrap.

**Fix:** Ensure the Bootstrap 5 theme CSS is loaded in the layout `<head>`:

```html
<link
  rel="stylesheet"
  href="https://cdn.jsdelivr.net/npm/tom-select@2.4.3/dist/css/tom-select.bootstrap5.min.css" />
```

Make sure it's loaded **after** the Bootstrap CSS.

---

### Selected Values Not Submitted

**Symptom:** Form submits but selected users are not saved.

**Check:**

1. The controller must permit the array parameter:
   ```ruby
   params.require(:dashboard).permit(:name, :embed_url, ..., user_ids: [])
   ```
2. The `include_blank: true` option must be set in the `options_for_select` helper to allow empty submissions (deselecting all).

---

### Dropdown Hidden Behind Modal

**Symptom:** The Tom Select dropdown opens but is clipped or hidden behind the modal.

**Fix:** Add CSS to ensure the dropdown has a high z-index:

```css
.ts-dropdown {
  z-index: 1060; /* Higher than Bootstrap modal (1055) */
}
```

---

## Updating Tom Select

To update to a newer version:

1. Download the new bundle:

   ```bash
   curl -sL "https://esm.sh/tom-select@NEW_VERSION/es2022/tom-select.bundle.mjs" \
     -o vendor/javascript/tom-select.js
   ```

2. Update the CSS version in `app/views/layouts/dashboard/application.html.erb`:

   ```html
   <link
     rel="stylesheet"
     href="https://cdn.jsdelivr.net/npm/tom-select@NEW_VERSION/dist/css/tom-select.bootstrap5.min.css" />
   ```

3. Restart the server to clear the asset cache.

---

## References

- [Tom Select Documentation](https://tom-select.js.org/)
- [Tom Select GitHub](https://github.com/orchidjs/tom-select)
- [Tom Select Plugins](https://tom-select.js.org/plugins/)
- [Rails Importmap Documentation](https://github.com/rails/importmap-rails)
- [esm.sh - ESM CDN](https://esm.sh/)
