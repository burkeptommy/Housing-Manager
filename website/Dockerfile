# ─── Stage 1: build the Operations Desk React + Vite SPA ────────────
FROM node:20-alpine AS ops-build
WORKDIR /app
COPY operations/package.json operations/package-lock.json* ./
RUN npm install --no-audit --no-fund
COPY operations/ ./
RUN npm run build

# ─── Stage 2: serve everything with nginx ───────────────────────────
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Marketing + auth pages (vanilla)
COPY index.html /usr/share/nginx/html/
COPY security.html /usr/share/nginx/html/
COPY privacy.html /usr/share/nginx/html/
COPY terms.html /usr/share/nginx/html/
COPY handyman.html /usr/share/nginx/html/
COPY handyman.css /usr/share/nginx/html/
COPY handyman.js /usr/share/nginx/html/
COPY handyman-quote.html /usr/share/nginx/html/
COPY handyman-quote.css /usr/share/nginx/html/
COPY handyman-quote.js /usr/share/nginx/html/
# Note: the legacy /handyman-visit PWA was retired 2026-05-08 — every
# field-tech surface is now the native HavenField iOS app, so the
# handyman-visit.{html,css,js,webmanifest} + sw.js COPYs are gone.
COPY styles.css /usr/share/nginx/html/
COPY og-image.png /usr/share/nginx/html/

# Brand stylesheet — referenced by both vanilla pages and the
# Operations Desk SPA (`<link rel="stylesheet" href="/chez.css" />` in
# operations/index.html). MUST be present for /operations/ to render.
COPY chez.css /usr/share/nginx/html/

# Chez brand assets — every Chez-branded page references these in its
# <head>. Missing any of them = 404s in the browser's network tab.
COPY favicon.svg /usr/share/nginx/html/
COPY favicon.ico /usr/share/nginx/html/
COPY favicon-16.png /usr/share/nginx/html/
COPY favicon-32.png /usr/share/nginx/html/
COPY favicon-192.png /usr/share/nginx/html/
COPY favicon-512.png /usr/share/nginx/html/
COPY apple-touch-icon.png /usr/share/nginx/html/
COPY manifest.webmanifest /usr/share/nginx/html/

# Operations Desk SPA — produced by stage 1.
COPY --from=ops-build /app/dist /usr/share/nginx/html/operations

# Admin Lab (private, Tom-only via Supabase Auth + RLS). Vanilla HTML +
# vanilla ES modules. Requires the Swift→JSON snapshots in admin-data/
# to be present at build time — refresh with
# `node scripts/export_swift_admin_data.mjs` before docker build.
COPY admin.html /usr/share/nginx/html/
COPY admin.css /usr/share/nginx/html/
COPY admin.js /usr/share/nginx/html/
COPY admin-forms.js /usr/share/nginx/html/
COPY admin-preview.js /usr/share/nginx/html/
COPY admin-simulator.js /usr/share/nginx/html/
COPY admin-data /usr/share/nginx/html/admin-data
COPY chez-logo.png /usr/share/nginx/html/
COPY alfred-mark.svg /usr/share/nginx/html/

# Service desk (operator workspace, served at service.getchez.com).
# Shares admin.js / admin.css / admin-data / admin-* helpers above. The
# split lives entirely in service.html's `data-portal-mode="service"`
# attribute + the small cosmetic overrides in service.css.
COPY service.html /usr/share/nginx/html/
COPY service.css /usr/share/nginx/html/

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
