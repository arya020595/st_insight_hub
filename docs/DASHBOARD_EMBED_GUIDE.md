# Dashboard Embed Guide

> How the `embed_type` field works and when to use each option.

---

## Overview

Each Dashboard record has two key fields:

| Field        | Purpose                                              |
| ------------ | ---------------------------------------------------- |
| `embed_url`  | The URL of the BI report/dashboard (always required) |
| `embed_type` | Controls **how** that URL is presented to the client |

`embed_type` accepts two values: `iframe` and `embed_url`.

---

## `iframe` — Embed inside the page

The URL is loaded directly inside an HTML `<iframe>` within ST Insight Hub. The client sees the dashboard **without leaving the app**.

```erb
<iframe
  src="https://your-bi-tool.com/embed/dashboard/123"
  width="100%"
  height="100%"
  frameborder="0"
  allowfullscreen>
</iframe>
```

**Use this when:**

- The BI tool provides a dedicated **public embed / share link** designed for iframe use
- The tool's server does **not** send `X-Frame-Options: DENY` or `Content-Security-Policy: frame-ancestors 'none'` headers
- No additional login is required before the dashboard loads

**Examples of tools that support iframe embedding:**

- Metabase public dashboard links
- Tableau embed URLs (signed or public)
- Redash shared dashboard links
- Looker embedded dashboard URLs
- Google Looker Studio share links (with iframe enabled)

---

## `embed_url` — Open in a new tab

No iframe is rendered. Instead, a **button/link** is shown that opens the URL in a new browser tab. The client views the dashboard in the BI tool's own interface.

```erb
<a href="https://app.powerbi.com/..." target="_blank" rel="noopener noreferrer">
  Open Dashboard
</a>
```

**Use this when:**

- The BI tool **blocks iframe embedding** (Power BI, many corporate SSO-protected tools)
- The dashboard requires the user to **log in** to the BI tool first
- The tool enforces `X-Frame-Options: SAMEORIGIN` or `DENY`
- You want to send users to the full native BI tool experience

**Examples of tools that typically require this:**

- Power BI reports (unless using the Power BI Embedded API with a token)
- Salesforce dashboards
- Any dashboard behind corporate SSO / VPN

---

## Quick Decision Guide

```
Does the URL load inside an <iframe> without errors or a blank page?
    │
    ├─ YES → use embed_type: "iframe"
    │
    └─ NO (blocked, login wall, blank) → use embed_type: "embed_url"
```

To test quickly, paste the URL into this snippet in your browser console:

```html
<iframe src="YOUR_URL_HERE" width="800" height="600"></iframe>
```

If it shows the dashboard → `iframe`. If it shows a login page or is blocked → `embed_url`.

---

## How it renders in the app

File: `app/views/bi_dashboards/show.html.erb`

```erb
<% if @dashboard.embed_type == 'iframe' %>
  <%# Render the dashboard inline %>
  <% if safe_url(@dashboard.embed_url) %>
    <iframe
      src="<%= safe_url(@dashboard.embed_url) %>"
      width="100%" height="100%"
      frameborder="0" allowfullscreen>
    </iframe>
  <% end %>
<% else %>
  <%# embed_url: open in new tab %>
  <% if safe_url(@dashboard.embed_url) %>
    <%= link_to @dashboard.embed_url,
        safe_url(@dashboard.embed_url),
        target: "_blank",
        rel: "noopener noreferrer",
        class: "btn btn-primary" %>
  <% end %>
<% end %>
```

The `safe_url` helper validates the URL is HTTP/HTTPS before rendering it to prevent XSS.

---

## Database

```ruby
# db/schema.rb
t.string "embed_url",  null: false
t.string "embed_type", null: false   # "iframe" | "embed_url"
```

```ruby
# app/models/dashboard.rb
validates :embed_type, presence: true, inclusion: { in: %w[iframe embed_url] }
validates :embed_url,  presence: true, format: { with: URL_FORMAT, message: "must be a valid HTTP or HTTPS URL" }
```
