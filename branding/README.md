# Haven Branding Assets

## Logo Design
The Haven logo features an elegant serif "H" with a champagne-colored A-frame roof, representing premium home management.

### Colors
- **Navy (Primary):** `#0a1929` - Background, H letterform
- **Champagne (Accent):** `#c4a574` - Roof element
- **White:** `#ffffff` - H letterform on dark backgrounds

### Typography
The "H" uses a classic serif style inspired by luxury fashion brands, with:
- Continuous letterform (single path, no gaps)
- Elegant serifs at top and bottom
- Balanced proportions filling the logo space

## File Locations

### Web App (`apps/web/public/`)
| File | Purpose |
|------|---------|
| `logo.svg` | Main square logo with navy background |
| `favicon.svg` | Browser tab icon (32x32 optimized) |
| `logo-wordmark.svg` | Logo + "HAVEN" text (navy on transparent) |
| `logo-wordmark-white.svg` | Logo + "HAVEN" text (white on transparent) |
| `icon-white.svg` | Icon only, white on transparent |
| `icon-navy.svg` | Icon only, navy on transparent |

### Mobile App (`apps/mobile/assets/`)
| File | Purpose |
|------|---------|
| `icon.svg` | App icon source (1024x1024) |
| `adaptive-icon.svg` | Android adaptive icon |
| `splash.svg` | Splash screen |
| `favicon.svg` | Favicon source |
| `notification-icon.svg` | Push notification icon (monochrome) |

## PNG Generation
Run the conversion script to generate PNG versions:
```bash
cd apps/mobile/assets
./convert-icons.sh
```

## Usage Guidelines
1. **Always use the champagne roof** - This is the distinctive brand element
2. **Minimum clear space** - Leave padding equal to the roof height around the logo
3. **On dark backgrounds** - Use white H with champagne roof
4. **On light backgrounds** - Use navy H with champagne roof
5. **Never alter proportions** - Keep the H and roof relationship intact
