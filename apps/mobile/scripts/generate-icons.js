const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

// Haven brand colors
const PURPLE = { r: 98, g: 0, b: 234, alpha: 1 }; // #6200EA
const WHITE = { r: 255, g: 255, b: 255, alpha: 1 }; // #ffffff

async function generateIcons() {
  const sourceDir = path.join(__dirname, '../../web/public/images');
  const outputDir = path.join(__dirname, '../assets');

  console.log('Source directory:', sourceDir);
  console.log('Output directory:', outputDir);

  // Ensure output directory exists
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  // Read SVG files
  const iconSvg = fs.readFileSync(path.join(sourceDir, 'icon.svg'), 'utf8');
  const iconWhiteSvg = fs.readFileSync(path.join(sourceDir, 'icon-white.svg'), 'utf8');
  const logoWhiteSvg = fs.readFileSync(path.join(sourceDir, 'logo-white.svg'), 'utf8');

  try {
    // Generate app icon (1024x1024) from icon.svg
    await sharp(Buffer.from(iconSvg))
      .resize(1024, 1024)
      .png()
      .toFile(path.join(outputDir, 'icon.png'));
    console.log('✓ Created icon.png (1024x1024)');

    // Generate adaptive icon foreground (1024x1024) - white icon on transparent
    // For Android adaptive icons, we need the foreground separate
    await sharp(Buffer.from(iconWhiteSvg))
      .resize(1024, 1024)
      .png()
      .toFile(path.join(outputDir, 'adaptive-icon.png'));
    console.log('✓ Created adaptive-icon.png (1024x1024)');

    // Generate notification icon (96x96) - white icon for notifications
    await sharp(Buffer.from(iconWhiteSvg))
      .resize(96, 96)
      .png()
      .toFile(path.join(outputDir, 'notification-icon.png'));
    console.log('✓ Created notification-icon.png (96x96)');

    // Generate favicon (48x48)
    await sharp(Buffer.from(iconSvg))
      .resize(48, 48)
      .png()
      .toFile(path.join(outputDir, 'favicon.png'));
    console.log('✓ Created favicon.png (48x48)');

    // Generate splash screen (1284x2778) - navy background with centered white logo
    const splashWidth = 1284;
    const splashHeight = 2778;
    const logoWidth = 600;
    const logoHeight = 150;

    // Create navy background
    const background = await sharp({
      create: {
        width: splashWidth,
        height: splashHeight,
        channels: 4,
        background: PURPLE
      }
    }).png().toBuffer();

    // Resize logo-white for splash
    const logo = await sharp(Buffer.from(logoWhiteSvg))
      .resize(logoWidth, logoHeight, {
        fit: 'contain',
        background: { r: 0, g: 0, b: 0, alpha: 0 }
      })
      .png()
      .toBuffer();

    // Composite logo on background (centered)
    await sharp(background)
      .composite([{
        input: logo,
        top: Math.round((splashHeight - logoHeight) / 2),
        left: Math.round((splashWidth - logoWidth) / 2)
      }])
      .toFile(path.join(outputDir, 'splash.png'));
    console.log('✓ Created splash.png (1284x2778)');

    console.log('\n✅ All icons generated successfully!');
    console.log('\nGenerated files:');
    const files = fs.readdirSync(outputDir).filter(f => f.endsWith('.png'));
    files.forEach(file => {
      const stats = fs.statSync(path.join(outputDir, file));
      console.log(`  - ${file} (${Math.round(stats.size / 1024)} KB)`);
    });

  } catch (error) {
    console.error('Error generating icons:', error);
    process.exit(1);
  }
}

generateIcons();
