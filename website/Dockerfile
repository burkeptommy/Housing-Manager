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
COPY handyman-visit.html /usr/share/nginx/html/
COPY handyman-visit.css /usr/share/nginx/html/
COPY handyman-visit.js /usr/share/nginx/html/
COPY handyman-visit-sw.js /usr/share/nginx/html/
COPY handyman-visit.webmanifest /usr/share/nginx/html/
COPY styles.css /usr/share/nginx/html/
COPY og-image.png /usr/share/nginx/html/

# Brand stylesheet — referenced by both vanilla pages and the
# Operations Desk SPA (`<link rel="stylesheet" href="/chez.css" />` in
# operations/index.html). MUST be present for /operations/ to render.
COPY chez.css /usr/share/nginx/html/
COPY favicon.svg /usr/share/nginx/html/

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

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
