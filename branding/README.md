# Haven Branding Assets

## Logo Design
The Haven logo is a simple roof peak (A-frame chevron) representing home, shelter, and sanctuary.

### Design Principles
- **Simple**: Recognizable at any size, from 16px favicon to 1024px app icon
- **Two colors**: Navy background (#0a1929) + White icon (#ffffff)
- **Meaningful**: Says "home" without being literal - a modern, abstract take

### Colors
- **Navy (Primary):** `#0a1929` - Background
- **White:** `#ffffff` - Roof peak icon

### The Logo
```
      /\
     /  \
    /    \
```
A simple upward-pointing chevron representing a roof peak.

## File Locations

### Web App (`apps/web/public/`)
| File | Purpose |
|------|---------|
| `logo.svg` | Main square logo (navy bg, white icon) |
| `favicon.svg` | Browser tab icon (32x32 optimized) |
| `logo-wordmark.svg` | Logo + "HAVEN" text (navy on transparent) |
| `logo-wordmark-white.svg` | Logo + "HAVEN" text (white on transparent) |
| `icon-white.svg` | Icon only, white on transparent |
| `icon-navy.svg` | Icon only, navy on transparent |

### Mobile App (`apps/mobile/assets/`)
| File | Purpose |
|------|---------|
| `icon.svg` / `icon.png` | App icon (1024x1024) |
| `adaptive-icon.svg` / `adaptive-icon.png` | Android adaptive icon |
| `splash.svg` / `splash.png` | Launch/splash screen |
| `favicon.svg` / `favicon.png` | Favicon source |
| `notification-icon.svg` / `notification-icon.png` | Push notification icon |

### Master File (`branding/`)
| File | Purpose |
|------|---------|
| `haven-logo-master.svg` | Master source file |

## Usage Guidelines

1. **App Icon**: Use `logo.svg` - navy background with white roof peak
2. **On dark backgrounds**: Use `icon-white.svg` or `logo-wordmark-white.svg`
3. **On light backgrounds**: Use `icon-navy.svg` or `logo-wordmark.svg`
4. **Favicon**: Use `favicon.svg` - optimized for small sizes
5. **Never alter**: Keep the roof peak shape and proportions intact

## PNG Generation

Generate PNGs from SVGs for mobile:
```bash
cd apps/mobile/assets
convert -background none icon.svg -resize 1024x1024 icon.png
convert -background none adaptive-icon.svg -resize 1024x1024 adaptive-icon.png
convert -background none splash.svg splash.png
convert -background none notification-icon.svg -resize 96x96 notification-icon.png
```

## Important Notes

- **Do NOT use Next.js `<Image>` component** with wordmark SVGs (they contain `<text>` elements)
- Use regular `<img>` tags for all logo SVGs
- The logo should work at all sizes without modification
