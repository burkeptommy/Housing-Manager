# Haven Logo Deployment - Claude Code Prompt

## Context
New Haven branding has been added to the project with the champagne-roof logo design. All SVG source files are in place. This prompt will complete the deployment.

## Task: Deploy New Haven Logo Across All Platforms

### 1. Generate PNG Assets for Mobile
```bash
cd apps/mobile/assets
chmod +x convert-icons.sh
./convert-icons.sh
```

If ImageMagick is not installed:
```bash
brew install imagemagick
```

### 2. Update Web App to Use New Logo

**Update `apps/web/src/app/layout.tsx`** - Add favicon and metadata:
```tsx
export const metadata: Metadata = {
  title: 'Haven - Home Management',
  description: 'Stop managing your home. Start living in it.',
  icons: {
    icon: '/favicon.svg',
    apple: '/logo.svg',
  },
}
```

**Update the sidebar/header** in `apps/web/src/app/app/layout.tsx` to use the new logo:
- Replace any existing logo with: `<img src="/logo-wordmark-white.svg" alt="Haven" className="h-8" />`
- For dark backgrounds, use `/logo-wordmark-white.svg`
- For light backgrounds, use `/logo-wordmark.svg`

### 3. Update Mobile App Configuration

**Update `apps/mobile/app.json`**:
```json
{
  "expo": {
    "name": "Haven",
    "slug": "haven",
    "icon": "./assets/icon.png",
    "splash": {
      "image": "./assets/splash.png",
      "resizeMode": "contain",
      "backgroundColor": "#0a1929"
    },
    "ios": {
      "supportsTablet": true,
      "bundleIdentifier": "com.haven.app"
    },
    "android": {
      "adaptiveIcon": {
        "foregroundImage": "./assets/adaptive-icon.png",
        "backgroundColor": "#0a1929"
      },
      "package": "com.haven.app"
    }
  }
}
```

### 4. Update Web Manifest

**Update `apps/web/public/manifest.json`**:
```json
{
  "name": "Haven",
  "short_name": "Haven",
  "description": "Stop managing your home. Start living in it.",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#0a1929",
  "theme_color": "#0a1929",
  "icons": [
    {
      "src": "/logo.svg",
      "sizes": "any",
      "type": "image/svg+xml"
    }
  ]
}
```

### 5. Verify and Build

```bash
# Build web app
cd apps/web
pnpm build

# Build mobile app (iOS)
cd ../mobile
npx expo prebuild --clean
npx eas build --platform ios --profile preview
```

### 6. Commit and Push

```bash
cd /Users/tomburke/Projects/Housing-Manager
git add .
git commit -m "feat(branding): Add new Haven logo with champagne roof

- Add elegant serif H logo with champagne accent roof
- Update web app favicon, logo, and wordmark variants
- Add mobile app icons (icon.png, adaptive-icon.png, splash.png)
- Add branding folder with master assets and README
- Update manifest.json with new branding colors"

git push origin main
```

### 7. Deploy to Production

```bash
# Deploy web to Google Cloud Run
cd apps/web
gcloud run deploy haven-web --source . --region us-central1

# Submit mobile to TestFlight (after EAS build completes)
# The EAS build from step 5 will automatically submit if configured
```

## Files Added/Modified

### New Files:
- `branding/haven-logo-master.svg` - Master logo source
- `branding/README.md` - Branding guidelines
- `apps/web/public/logo.svg` - Main logo
- `apps/web/public/favicon.svg` - Favicon
- `apps/web/public/logo-wordmark.svg` - Logo with text (navy)
- `apps/web/public/logo-wordmark-white.svg` - Logo with text (white)
- `apps/web/public/icon-white.svg` - Icon only (white)
- `apps/web/public/icon-navy.svg` - Icon only (navy)
- `apps/mobile/assets/icon.svg` - App icon source
- `apps/mobile/assets/adaptive-icon.svg` - Android adaptive icon
- `apps/mobile/assets/splash.svg` - Splash screen
- `apps/mobile/assets/favicon.svg` - Mobile favicon
- `apps/mobile/assets/notification-icon.svg` - Notification icon
- `apps/mobile/assets/convert-icons.sh` - PNG conversion script

### Modified Files:
- `apps/web/src/app/layout.tsx` - Favicon metadata
- `apps/web/src/app/app/layout.tsx` - Sidebar logo
- `apps/web/public/manifest.json` - PWA manifest
- `apps/mobile/app.json` - Expo config
