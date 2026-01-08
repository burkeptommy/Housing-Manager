const sharp = require('sharp');
const { writeFileSync } = require('fs');
const { join } = require('path');

const svgPath = join(__dirname, '../public/favicon.svg');
const outputPath = join(__dirname, '../public');

const sizes = [16, 32, 48];

async function createFavicon() {
  const pngBuffers = [];

  for (const size of sizes) {
    const png = await sharp(svgPath)
      .resize(size, size)
      .png()
      .toBuffer();
    pngBuffers.push({ size, buffer: png });
    console.log(`Created ${size}x${size} PNG buffer`);
  }

  // Create ICO file
  const numImages = pngBuffers.length;
  const headerSize = 6;
  const entrySize = 16;
  const entriesSize = entrySize * numImages;

  let dataOffset = headerSize + entriesSize;
  const entries = [];
  const imageDataParts = [];

  for (const { size, buffer } of pngBuffers) {
    entries.push({
      width: size === 256 ? 0 : size,
      height: size === 256 ? 0 : size,
      colorCount: 0,
      reserved: 0,
      planes: 1,
      bitCount: 32,
      size: buffer.length,
      offset: dataOffset
    });
    imageDataParts.push(buffer);
    dataOffset += buffer.length;
  }

  const totalSize = headerSize + entriesSize + imageDataParts.reduce((a, b) => a + b.length, 0);
  const ico = Buffer.alloc(totalSize);

  ico.writeUInt16LE(0, 0);
  ico.writeUInt16LE(1, 2);
  ico.writeUInt16LE(numImages, 4);

  let offset = headerSize;
  for (const entry of entries) {
    ico.writeUInt8(entry.width, offset);
    ico.writeUInt8(entry.height, offset + 1);
    ico.writeUInt8(entry.colorCount, offset + 2);
    ico.writeUInt8(entry.reserved, offset + 3);
    ico.writeUInt16LE(entry.planes, offset + 4);
    ico.writeUInt16LE(entry.bitCount, offset + 6);
    ico.writeUInt32LE(entry.size, offset + 8);
    ico.writeUInt32LE(entry.offset, offset + 12);
    offset += entrySize;
  }

  for (const buffer of imageDataParts) {
    buffer.copy(ico, offset);
    offset += buffer.length;
  }

  writeFileSync(join(outputPath, 'favicon.ico'), ico);
  console.log('Created favicon.ico');
}

createFavicon().catch(console.error);
