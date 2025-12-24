# Haven - Copy House Image Instructions

## The Uploaded House Image

Copy the uploaded house image to the project:

```bash
# Copy the uploaded image to the public folder
cp /mnt/user-data/uploads/90bbbf2b90ec7c2b760912d8c4481756-cc_ft_960.jpg /Users/tomburke/Projects/Housing-Manager/apps/web/public/images/homes/38-bedford-rd.jpg
```

Or if the images/homes directory doesn't exist:

```bash
mkdir -p /Users/tomburke/Projects/Housing-Manager/apps/web/public/images/homes
cp /mnt/user-data/uploads/90bbbf2b90ec7c2b760912d8c4481756-cc_ft_960.jpg /Users/tomburke/Projects/Housing-Manager/apps/web/public/images/homes/38-bedford-rd.jpg
```

## Update All References

Replace ALL occurrences of house images across the application with:

```tsx
const HOUSE_IMAGE = '/images/homes/38-bedford-rd.jpg';
```

Files to update:
- `apps/web/src/app/app/home/page.tsx` - Your Home page
- `apps/web/src/app/app/properties/page.tsx` - If exists
- `apps/web/src/app/app/page.tsx` - Dashboard (if showing property)
- Any other component showing the Morrison home

## Image Details

The image shows:
- Classic shingle-style Connecticut home
- Cedar shake siding (weathered gray)
- Black shutters
- Bay window on right side
- Stone front steps with iron railings
- Red mums in planters
- Mature sycamore tree in foreground
- Well-maintained lawn with pachysandra groundcover
- GMLS IDX watermark (listing photo)

This is the authentic look for 38 Bedford Rd, Greenwich, CT.
