FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Marketing + auth pages
COPY index.html /usr/share/nginx/html/
COPY security.html /usr/share/nginx/html/
COPY privacy.html /usr/share/nginx/html/
COPY terms.html /usr/share/nginx/html/
COPY styles.css /usr/share/nginx/html/
COPY og-image.png /usr/share/nginx/html/

# Vendor application flow (public — vendors apply to get verified)
COPY vendor-apply.html /usr/share/nginx/html/
COPY vendor-confirm.html /usr/share/nginx/html/

# Brand stylesheet — referenced by every Chez-branded page.
COPY chez.css /usr/share/nginx/html/
COPY chez.js /usr/share/nginx/html/

# Chez brand assets — every Chez-branded page references these in its <head>.
COPY favicon.svg /usr/share/nginx/html/
COPY favicon.ico /usr/share/nginx/html/
COPY favicon-16.png /usr/share/nginx/html/
COPY favicon-32.png /usr/share/nginx/html/
COPY favicon-192.png /usr/share/nginx/html/
COPY favicon-512.png /usr/share/nginx/html/
COPY apple-touch-icon.png /usr/share/nginx/html/
COPY manifest.webmanifest /usr/share/nginx/html/

# Admin portal (private, Tom-only via Supabase Auth + RLS). Vanilla HTML +
# vanilla ES modules. Requires the Swift→JSON snapshots in admin-data/
# to be present at build time — refresh with
# `node scripts/export_swift_admin_data.mjs` before docker build.
COPY admin.html /usr/share/nginx/html/
COPY admin.css /usr/share/nginx/html/
COPY admin.js /usr/share/nginx/html/
COPY admin-forms.js /usr/share/nginx/html/
COPY admin-preview.js /usr/share/nginx/html/
COPY admin-simulator.js /usr/share/nginx/html/
COPY admin-architecture.js /usr/share/nginx/html/
COPY admin-vendors.html /usr/share/nginx/html/
COPY admin-data /usr/share/nginx/html/admin-data
COPY chez-logo.png /usr/share/nginx/html/
COPY alfred-mark.svg /usr/share/nginx/html/

# Service desk (operator workspace, served at service.getchez.com).
# Shares admin.js / admin.css / admin-data / admin-* helpers above. The
# split lives entirely in service.html's `data-portal-mode="service"`
# attribute + the small cosmetic overrides in service.css.
COPY service.html /usr/share/nginx/html/
COPY service.css /usr/share/nginx/html/

# Password reset (Supabase deep link)
COPY reset-password.html /usr/share/nginx/html/

# Homeowners landing
COPY homeowners.html /usr/share/nginx/html/

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
