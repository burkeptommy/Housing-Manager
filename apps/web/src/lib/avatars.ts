// DiceBear illustrated avatars for demo users
// Using consistent seeds for reproducible avatars across sessions

type AvatarStyle = 'lorelei' | 'adventurer' | 'big-ears' | 'avataaars' | 'bottts' | 'fun-emoji';

const DEFAULT_STYLE: AvatarStyle = 'lorelei';

// Pre-defined avatar seeds for demo users
export const demoAvatars = {
  // Morrison Family
  bob: 'bob-morrison-haven',
  alice: 'alice-morrison-haven',
  emma: 'emma-morrison-haven',
  jack: 'jack-morrison-haven',
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

  // Check known users
  const knownUsers: Record<string, string> = {
    'bob morrison': demoAvatars.bob,
    'bob': demoAvatars.bob,
    'alice morrison': demoAvatars.alice,
    'alice': demoAvatars.alice,
    'emma morrison': demoAvatars.emma,
    'emma': demoAvatars.emma,
    'jack morrison': demoAvatars.jack,
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
