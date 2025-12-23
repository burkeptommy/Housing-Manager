// DiceBear illustrated avatars for demo users
// Using consistent seeds for reproducible avatars across sessions

type AvatarStyle = 'lorelei' | 'adventurer' | 'big-ears' | 'avataaars' | 'bottts' | 'fun-emoji';

const DEFAULT_STYLE: AvatarStyle = 'lorelei';

// Pre-defined avatar seeds for demo users
export const demoAvatars = {
  // Burke Family (38 Bedford Rd, Greenwich, CT)
  bob: 'bob-burke-haven',
  alice: 'alice-burke-haven',
  emma: 'emma-burke-haven',
  jack: 'jack-burke-haven',
  max: 'max-dog-haven',

  // Staff
  sarah: 'sarah-harrison-haven',
  mike: 'mike-rodriguez-haven',
  maria: 'maria-garcia-haven',
  carlos: 'carlos-reyes-haven',

  // Vendors
  aceRoofing: 'ace-roofing-haven',
  premierPlumbing: 'premier-plumbing-haven',
  eliteElectric: 'elite-electric-haven',
  greenThumb: 'green-thumb-haven',

  // Generic fallbacks
  default: 'haven-default-user',
} as const;

/**
 * Get a DiceBear avatar URL for a user
 * @param seed - Unique seed for consistent avatar generation
 * @param style - DiceBear style (defaults to 'lorelei' for friendly illustrated look)
 * @param size - Avatar size in pixels (default 200)
 */
export function getDiceBearAvatar(
  seed: string,
  style: AvatarStyle = DEFAULT_STYLE,
  size: number = 200
): string {
  const encodedSeed = encodeURIComponent(seed);
  return `https://api.dicebear.com/7.x/${style}/svg?seed=${encodedSeed}&size=${size}`;
}

/**
 * Get avatar URL for a known demo user
 * Returns consistent illustrated avatar for demo users
 */
export function getUserAvatar(name: string, fallbackToInitials: boolean = false): string | undefined {
  const lowerName = name.toLowerCase().trim();

  // Check known users (Burke family at 38 Bedford Rd, Greenwich, CT)
  const knownUsers: Record<string, string> = {
    'bob burke': demoAvatars.bob,
    'bob morrison': demoAvatars.bob, // legacy compatibility
    'bob': demoAvatars.bob,
    'alice burke': demoAvatars.alice,
    'alice morrison': demoAvatars.alice, // legacy compatibility
    'alice': demoAvatars.alice,
    'emma burke': demoAvatars.emma,
    'emma morrison': demoAvatars.emma, // legacy compatibility
    'emma': demoAvatars.emma,
    'jack burke': demoAvatars.jack,
    'jack morrison': demoAvatars.jack, // legacy compatibility
    'jack': demoAvatars.jack,
    'max': demoAvatars.max,
    'sarah harrison': demoAvatars.sarah,
    'sarah': demoAvatars.sarah,
    'mike rodriguez': demoAvatars.mike,
    'mike': demoAvatars.mike,
    'maria garcia': demoAvatars.maria,
    'maria': demoAvatars.maria,
    'carlos reyes': demoAvatars.carlos,
    'carlos': demoAvatars.carlos,
  };

  const seed = knownUsers[lowerName];
  if (seed) {
    return getDiceBearAvatar(seed);
  }

  // Generate avatar from name if not fallback to initials
  if (!fallbackToInitials) {
    return getDiceBearAvatar(lowerName);
  }

  return undefined;
}

/**
 * Get avatar for pets using fun-emoji style
 */
export function getPetAvatar(name: string, species?: 'dog' | 'cat' | 'other'): string {
  const style: AvatarStyle = species === 'cat' ? 'fun-emoji' : 'fun-emoji';
  return getDiceBearAvatar(`${name}-pet`, style);
}

/**
 * Get avatar for vendors/businesses using bottts style (robot-like professional icons)
 */
export function getVendorAvatar(vendorName: string): string {
  return getDiceBearAvatar(vendorName.toLowerCase().replace(/\s+/g, '-'), 'bottts');
}

/**
 * Get initials from a name
 */
export function getInitials(name: string): string {
  return name
    .split(' ')
    .map((n) => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2);
}
