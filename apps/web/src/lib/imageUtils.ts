/**
 * Demo Image Utility
 *
 * Provides consistent, high-quality Unsplash images for demo purposes.
 * Uses static photo IDs to ensure images don't change on refresh.
 */

type ImageCategory =
  | 'avatar-male'
  | 'avatar-female'
  | 'avatar-kid'
  | 'house-exterior'
  | 'kitchen'
  | 'living-room'
  | 'bathroom'
  | 'bedroom'
  | 'backyard'
  | 'construction'
  | 'blueprint'
  | 'map'
  | 'vendor-portrait'
  | 'team'
  | 'office'
  | 'vendor-logo'
  | 'plumbing-work'
  | 'electrical-work'
  | 'landscaping'
  | 'hvac-work'
  | 'painting-work'
  | 'handyman-work'
  | 'roofing-work'
  | 'cleaning-work';

// Curated Unsplash photo IDs for each category
// Multiple options per category for variety
const imageLibrary: Record<ImageCategory, string[]> = {
  'avatar-male': [
    'photo-1507003211169-0a1dd7228f2d', // Professional man, neutral background
    'photo-1472099645785-5658abf4ff4e', // Business casual man
    'photo-1500648767791-00dcc994a43e', // Friendly man smiling
    'photo-1560250097-0b93528c311a', // Man in suit
    'photo-1519085360753-af0119f7cbe7', // Professional headshot
  ],
  'avatar-female': [
    'photo-1494790108377-be9c29b29330', // Professional woman, warm smile
    'photo-1438761681033-6461ffad8d80', // Business woman
    'photo-1534528741775-53994a69daeb', // Confident woman
    'photo-1580489944761-15a19d654956', // Friendly professional
    'photo-1573496359142-b8d87734a5a2', // Woman in business attire
  ],
  'avatar-kid': [
    'photo-1503454537195-1dcabb73ffb9', // Happy child
    'photo-1518826778770-a729fb53327c', // Kid smiling
    'photo-1504439468489-c8920d796a29', // Child portrait
  ],
  'house-exterior': [
    'photo-1600596542815-ffad4c1539a9', // Modern luxury home
    'photo-1600585154340-be6161a56a0c', // Contemporary house
    'photo-1600607687939-ce8a6c25118c', // Modern architecture home
    'photo-1512917774080-9991f1c4c750', // Beautiful home exterior
    'photo-1605276374104-dee2a0ed3cd6', // Luxury residence
  ],
  'kitchen': [
    'photo-1556909114-f6e7ad7d3136', // Modern white kitchen
    'photo-1600585154526-990dced4db0d', // Luxury kitchen island
    'photo-1556909172-54557c7e4fb7', // Contemporary kitchen
    'photo-1600566753376-12c8ab7fb75b', // Bright modern kitchen
  ],
  'living-room': [
    'photo-1600210492486-724fe5c67fb0', // Modern living room
    'photo-1600607687644-c7171b42498f', // Cozy contemporary
    'photo-1618221195710-dd6b41faaea6', // Stylish interior
    'photo-1600566753190-17f0baa2a6c3', // Elegant living space
  ],
  'bathroom': [
    'photo-1600566752355-35792bedcfea', // Luxury bathroom
    'photo-1600607687920-4e2a09cf159d', // Modern bath design
    'photo-1552321554-5fefe8c9ef14', // Spa-like bathroom
    'photo-1600566752734-2a0cd66c42b7', // Contemporary bath
  ],
  'bedroom': [
    'photo-1600210491892-03d54c0aaf87', // Master bedroom
    'photo-1600585154084-4e5fe7c39198', // Luxury bedroom
    'photo-1616594039964-ae9021a400a0', // Modern bedroom design
  ],
  'backyard': [
    'photo-1600585154340-be6161a56a0c', // Backyard with pool
    'photo-1600566753086-00f18fb6b3ea', // Garden patio
    'photo-1558618666-fcd25c85cd64', // Outdoor living space
  ],
  'construction': [
    'photo-1504307651254-35680f356dfd', // Construction site
    'photo-1541888946425-d81bb19240f5', // Renovation work
    'photo-1621905252507-b35492cc74b4', // Home construction
    'photo-1503387762-592deb58ef4e', // Building project
  ],
  'blueprint': [
    'photo-1503387762-592deb58ef4e', // Architectural plans
    'photo-1545873333-2a2f67a0d3b3', // Blueprint drawings
    'photo-1574359411659-15573cc8cdd1', // Floor plans
  ],
  'map': [
    'photo-1524661135-423995f22d0b', // Aerial city view
    'photo-1506905925346-21bda4d32df4', // Aerial neighborhood
    'photo-1477959858617-67f85cf4f1df', // City from above
  ],
  'vendor-portrait': [
    'photo-1560250097-0b93528c311a', // Professional tradesperson
    'photo-1556157382-97edd2d9e772', // Contractor
    'photo-1507003211169-0a1dd7228f2d', // Service professional
    'photo-1519085360753-af0119f7cbe7', // Business owner
  ],
  'team': [
    'photo-1522071820081-009f0129c71c', // Team meeting
    'photo-1517245386807-bb43f82c33c4', // Business team
    'photo-1600880292203-757bb62b4baf', // Collaborative work
  ],
  'office': [
    'photo-1497366216548-37526070297c', // Modern office
    'photo-1497215728101-856f4ea42174', // Office interior
    'photo-1604328698692-f76ea9498e76', // Contemporary workspace
  ],
  // Vendor-specific categories
  'vendor-logo': [
    'photo-1560250097-0b93528c311a', // Professional in hard hat
    'photo-1507003211169-0a1dd7228f2d', // Tradesperson portrait
    'photo-1519085360753-af0119f7cbe7', // Service professional
    'photo-1472099645785-5658abf4ff4e', // Business owner
    'photo-1500648767791-00dcc994a43e', // Friendly contractor
    'photo-1556157382-97edd2d9e772', // Professional worker
  ],
  'plumbing-work': [
    'photo-1585704032915-c3400ca199e7', // Plumbing repair
    'photo-1607472586893-edb57bdc0e39', // Pipe work
    'photo-1504328345606-18bbc8c9d7d1', // Bathroom plumbing
    'photo-1558618666-fcd25c85cd64', // Modern bathroom
  ],
  'electrical-work': [
    'photo-1621905251189-08b45d6a269e', // Electrical panel
    'photo-1558618047-3c8c76ca7d13', // Wiring work
    'photo-1555963966-b7ae5404b6ed', // Electrical installation
  ],
  'landscaping': [
    'photo-1558904541-efa843a96f01', // Garden design
    'photo-1416879595882-3373a0480b5b', // Beautiful garden
    'photo-1585320806297-9794b3e4eeae', // Lawn care
    'photo-1558618666-fcd25c85cd64', // Outdoor space
  ],
  'hvac-work': [
    'photo-1585771724684-38269d6639fd', // HVAC unit
    'photo-1631545806609-6578aa86e36c', // Air conditioning
    'photo-1635048424329-a9bfb146d7aa', // Heating system
  ],
  'painting-work': [
    'photo-1562259949-e8e7689d7828', // Painting supplies
    'photo-1589939705384-5185137a7f0f', // House painting
    'photo-1558618666-fcd25c85cd64', // Wall painting
  ],
  'handyman-work': [
    'photo-1504307651254-35680f356dfd', // Tool work
    'photo-1581578731548-c64695cc6952', // Home repair
    'photo-1621905252507-b35492cc74b4', // Handyman tools
  ],
  'roofing-work': [
    'photo-1632759145351-1d592919f522', // Roofing
    'photo-1607400201889-565b1ee75f8e', // Roof repair
    'photo-1558618666-fcd25c85cd64', // House roof
  ],
  'cleaning-work': [
    'photo-1581578731548-c64695cc6952', // House cleaning
    'photo-1563453392212-326f5e854473', // Cleaning service
    'photo-1628177142898-93e36e4e3a50', // Professional cleaning
  ],
};

// Track which index to use for each category (for rotation)
const categoryIndex: Record<string, number> = {};

/**
 * Get a demo image URL from Unsplash
 *
 * @param category - The type of image to retrieve
 * @param width - Desired width (default: 800)
 * @param height - Desired height (default: 600)
 * @param seed - Optional seed for consistent image selection (e.g., user ID)
 * @returns Full Unsplash URL
 *
 * @example
 * getDemoImage('avatar-male', 200, 200) // Returns a male avatar
 * getDemoImage('kitchen', 1200, 800) // Returns a kitchen image
 * getDemoImage('avatar-female', 100, 100, 'user-123') // Consistent image for user-123
 */
export function getDemoImage(
  category: ImageCategory | string,
  width: number = 800,
  height: number = 600,
  seed?: string
): string {
  const images = imageLibrary[category as ImageCategory];

  if (!images || images.length === 0) {
    // Fallback to a generic placeholder
    return `https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=${width}&h=${height}&fit=crop&auto=format`;
  }

  let index: number;

  if (seed) {
    // Use seed to get consistent image for same identifier
    const hash = seed.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
    index = hash % images.length;
  } else {
    // Rotate through images for variety
    if (!(category in categoryIndex)) {
      categoryIndex[category] = 0;
    }
    index = categoryIndex[category] ?? 0;
    categoryIndex[category] = (index + 1) % images.length;
  }

  const photoId = images[index];
  return `https://images.unsplash.com/${photoId}?w=${width}&h=${height}&fit=crop&auto=format&q=80`;
}

/**
 * Get a specific demo image by index
 * Useful when you need a particular image from a category
 *
 * @param category - The type of image
 * @param index - Which image from the category (0-based)
 * @param width - Desired width
 * @param height - Desired height
 */
export function getDemoImageByIndex(
  category: ImageCategory | string,
  index: number,
  width: number = 800,
  height: number = 600
): string {
  const images = imageLibrary[category as ImageCategory];

  if (!images || images.length === 0) {
    return getDemoImage('house-exterior', width, height);
  }

  const safeIndex = Math.abs(index) % images.length;
  const photoId = images[safeIndex];
  return `https://images.unsplash.com/${photoId}?w=${width}&h=${height}&fit=crop&auto=format&q=80`;
}

/**
 * Get avatar image based on name (consistent per user)
 *
 * @param name - User's name for consistent selection
 * @param gender - 'male', 'female', or 'kid'
 * @param size - Square size for avatar
 */
export function getAvatarImage(
  name: string,
  gender: 'male' | 'female' | 'kid' = 'male',
  size: number = 200
): string {
  const category = `avatar-${gender}` as ImageCategory;
  return getDemoImage(category, size, size, name);
}

/**
 * Get a room image based on room type
 *
 * @param roomType - Type of room
 * @param seed - Optional seed for consistency
 */
export function getRoomImage(
  roomType: 'kitchen' | 'living-room' | 'bathroom' | 'bedroom' | 'backyard',
  seed?: string,
  width: number = 1200,
  height: number = 800
): string {
  return getDemoImage(roomType, width, height, seed);
}

/**
 * Get project-related images
 *
 * @param type - 'construction', 'blueprint', or 'before-after'
 * @param seed - Optional seed for consistency
 */
export function getProjectImage(
  type: 'construction' | 'blueprint' | 'house-exterior',
  seed?: string,
  width: number = 1200,
  height: number = 800
): string {
  return getDemoImage(type, width, height, seed);
}

/**
 * Get vendor work/cover image based on their trade
 *
 * @param trade - The vendor's trade type
 * @param seed - Optional seed for consistency
 */
export function getVendorWorkImage(
  trade: 'plumber' | 'electrician' | 'landscaper' | 'painter' | 'hvac' | 'handyman' | 'roofer' | 'cleaner' | string,
  seed?: string,
  width: number = 400,
  height: number = 200
): string {
  const tradeToCategory: Record<string, ImageCategory> = {
    'plumber': 'plumbing-work',
    'electrician': 'electrical-work',
    'landscaper': 'landscaping',
    'painter': 'painting-work',
    'hvac': 'hvac-work',
    'handyman': 'handyman-work',
    'roofer': 'roofing-work',
    'cleaner': 'cleaning-work',
  };

  const category = tradeToCategory[trade] || 'construction';
  return getDemoImage(category, width, height, seed);
}

// Export types for consumers
export type { ImageCategory };
