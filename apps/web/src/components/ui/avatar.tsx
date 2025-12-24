'use client';

import React from 'react';

// Color palette - 12 distinct colors
const colors = [
  { bg: '#E8ECF2', fill: '#1E2A3B' },  // Navy
  { bg: '#CCFBF1', fill: '#0F766E' },  // Teal
  { bg: '#EDE9FE', fill: '#6D28D9' },  // Violet
  { bg: '#FFE4E6', fill: '#BE123C' },  // Rose
  { bg: '#FEF3C7', fill: '#B45309' },  // Amber
  { bg: '#D1FAE5', fill: '#047857' },  // Emerald
  { bg: '#E0F2FE', fill: '#0369A1' },  // Sky
  { bg: '#FFEDD5', fill: '#C2410C' },  // Orange
  { bg: '#FCE7F3', fill: '#BE185D' },  // Pink
  { bg: '#E0E7FF', fill: '#4338CA' },  // Indigo
  { bg: '#ECFCCB', fill: '#4D7C0F' },  // Lime
  { bg: '#CFFAFE', fill: '#0E7490' },  // Cyan
];

// Get consistent color from name
function getColorIndex(name: string): number {
  let hash = 0;
  for (let i = 0; i < name.length; i++) {
    hash = name.charCodeAt(i) + ((hash << 5) - hash);
  }
  return Math.abs(hash) % colors.length;
}

// Size presets
const sizes = {
  xs: 24,
  sm: 32,
  md: 40,
  lg: 48,
  xl: 64,
  '2xl': 80,
};

type AvatarSize = keyof typeof sizes;

interface AvatarProps {
  name: string;
  type: 'male' | 'female' | 'boy' | 'girl' | 'manager' | 'handyman' | 'pet-dog' | 'pet-cat';
  size?: AvatarSize;
  colorIndex?: number; // Override color
  className?: string;
}

// Male Adult Silhouette
function MaleSilhouette({ color }: { color: string }) {
  return (
    <g fill={color}>
      {/* Head */}
      <circle cx="20" cy="12" r="7" />
      {/* Shoulders/Body - broader, more angular */}
      <path d="M8 40 L12 28 C14 24 17 22 20 22 C23 22 26 24 28 28 L32 40 Z" />
    </g>
  );
}

// Female Adult Silhouette
function FemaleSilhouette({ color }: { color: string }) {
  return (
    <g fill={color}>
      {/* Head */}
      <circle cx="20" cy="12" r="7" />
      {/* Hair hint - slightly longer */}
      <ellipse cx="20" cy="10" rx="8" ry="6" />
      {/* Shoulders/Body - narrower, softer */}
      <path d="M10 40 L13 28 C15 24 17 22 20 22 C23 22 25 24 27 28 L30 40 Z" />
    </g>
  );
}

// Boy Silhouette (smaller, childlike proportions)
function BoySilhouette({ color }: { color: string }) {
  return (
    <g fill={color}>
      {/* Bigger head relative to body (child proportions) */}
      <circle cx="20" cy="13" r="8" />
      {/* Smaller body */}
      <path d="M12 40 L14 30 C16 26 18 24 20 24 C22 24 24 26 26 30 L28 40 Z" />
    </g>
  );
}

// Girl Silhouette (smaller, childlike proportions with hair)
function GirlSilhouette({ color }: { color: string }) {
  return (
    <g fill={color}>
      {/* Bigger head relative to body */}
      <circle cx="20" cy="13" r="8" />
      {/* Pigtails/hair puffs */}
      <circle cx="11" cy="11" r="3" />
      <circle cx="29" cy="11" r="3" />
      {/* Smaller body */}
      <path d="M12 40 L14 30 C16 26 18 24 20 24 C22 24 24 26 26 30 L28 40 Z" />
    </g>
  );
}

// Manager silhouette with sparkle badge
function ManagerSilhouette() {
  return (
    <g>
      {/* Female silhouette base */}
      <g fill="#8C7D4E">
        <circle cx="20" cy="12" r="7" />
        <ellipse cx="20" cy="10" rx="8" ry="6" />
        <path d="M10 40 L13 28 C15 24 17 22 20 22 C23 22 25 24 27 28 L30 40 Z" />
      </g>
      {/* Star badge */}
      <g transform="translate(28, 2)">
        <circle cx="6" cy="6" r="6" fill="#FCD34D" />
        <path d="M6 2 L7 5 L10 5 L8 7 L9 10 L6 8 L3 10 L4 7 L2 5 L5 5 Z" fill="#B45309" />
      </g>
    </g>
  );
}

// Handyman silhouette with tool badge
function HandymanSilhouette() {
  return (
    <g>
      {/* Male silhouette base */}
      <g fill="#C2410C">
        <circle cx="20" cy="12" r="7" />
        <path d="M8 40 L12 28 C14 24 17 22 20 22 C23 22 26 24 28 28 L32 40 Z" />
      </g>
      {/* Wrench badge */}
      <g transform="translate(28, 2)">
        <circle cx="6" cy="6" r="6" fill="#FED7AA" />
        <path d="M4 4 L8 8 M8 4 L4 8" stroke="#C2410C" strokeWidth="2" strokeLinecap="round" />
      </g>
    </g>
  );
}

// Dog silhouette
function DogSilhouette({ color }: { color: string }) {
  return (
    <g fill={color}>
      {/* Body */}
      <ellipse cx="20" cy="24" rx="12" ry="8" />
      {/* Head */}
      <circle cx="20" cy="14" r="7" />
      {/* Ears */}
      <ellipse cx="13" cy="10" rx="3" ry="5" />
      <ellipse cx="27" cy="10" rx="3" ry="5" />
      {/* Snout */}
      <ellipse cx="20" cy="17" rx="3" ry="2" />
    </g>
  );
}

// Cat silhouette
function CatSilhouette({ color }: { color: string }) {
  return (
    <g fill={color}>
      {/* Body */}
      <ellipse cx="20" cy="26" rx="10" ry="7" />
      {/* Head */}
      <circle cx="20" cy="15" r="7" />
      {/* Pointed ears */}
      <polygon points="12,12 14,6 17,12" />
      <polygon points="28,12 26,6 23,12" />
      {/* Whiskers area */}
      <ellipse cx="20" cy="17" rx="2" ry="1.5" />
    </g>
  );
}

export function Avatar({ name, type, size = 'md', colorIndex, className = '' }: AvatarProps) {
  const pixelSize = sizes[size];
  const color = colors[colorIndex ?? getColorIndex(name)];

  // Manager and Handyman have fixed colors
  const bgColor = type === 'manager' ? '#F5F0E8' :
                  type === 'handyman' ? '#FFEDD5' :
                  color.bg;

  return (
    <svg
      width={pixelSize}
      height={pixelSize}
      viewBox="0 0 40 40"
      className={`rounded-full flex-shrink-0 ${className}`}
      style={{ backgroundColor: bgColor }}
    >
      {type === 'male' && <MaleSilhouette color={color.fill} />}
      {type === 'female' && <FemaleSilhouette color={color.fill} />}
      {type === 'boy' && <BoySilhouette color={color.fill} />}
      {type === 'girl' && <GirlSilhouette color={color.fill} />}
      {type === 'manager' && <ManagerSilhouette />}
      {type === 'handyman' && <HandymanSilhouette />}
      {type === 'pet-dog' && <DogSilhouette color={color.fill} />}
      {type === 'pet-cat' && <CatSilhouette color={color.fill} />}
    </svg>
  );
}

// Vendor Avatar - Uses initials with category icon
interface VendorAvatarProps {
  name: string;
  category?: string;
  size?: AvatarSize;
  colorIndex?: number;
  className?: string;
}

export function VendorAvatar({ name, size = 'md', colorIndex, className = '' }: VendorAvatarProps) {
  const pixelSize = sizes[size];
  const color = colors[colorIndex ?? getColorIndex(name)];

  // Get initials (first letter of first two words)
  const initials = name
    .split(' ')
    .slice(0, 2)
    .map(word => word[0])
    .join('')
    .toUpperCase();

  const fontSize = pixelSize * 0.35;

  return (
    <div
      className={`rounded-xl flex items-center justify-center font-semibold flex-shrink-0 ${className}`}
      style={{
        width: pixelSize,
        height: pixelSize,
        backgroundColor: color.bg,
        color: color.fill,
        fontSize: fontSize,
      }}
    >
      {initials}
    </div>
  );
}

// Convenience exports
export function ManagerAvatar({ size = 'md', className = '' }: { size?: AvatarSize; className?: string }) {
  return <Avatar name="Sarah Chen" type="manager" size={size} className={className} />;
}

export function HandymanAvatar({ size = 'md', className = '' }: { size?: AvatarSize; className?: string }) {
  return <Avatar name="Mike Rodriguez" type="handyman" size={size} className={className} />;
}

// ============================================================================
// BACKWARD COMPATIBILITY - InitialsAvatar
// ============================================================================

type InitialsSize = 'xs' | 'sm' | 'md' | 'lg' | 'xl';
type InitialsVariant = 'emerald' | 'blue' | 'purple' | 'amber' | 'rose' | 'haven' | 'warm';

interface InitialsAvatarProps {
  name: string;
  size?: InitialsSize;
  variant?: InitialsVariant;
  className?: string;
}

const initialsSizeClasses: Record<InitialsSize, string> = {
  xs: 'w-6 h-6 text-xs',
  sm: 'w-8 h-8 text-xs',
  md: 'w-10 h-10 text-sm',
  lg: 'w-12 h-12 text-base',
  xl: 'w-14 h-14 text-lg',
};

const initialsVariantClasses: Record<InitialsVariant, string> = {
  emerald: 'bg-emerald-100 text-emerald-600',
  blue: 'bg-blue-100 text-blue-600',
  purple: 'bg-purple-100 text-purple-600',
  amber: 'bg-amber-100 text-amber-600',
  rose: 'bg-rose-100 text-rose-600',
  haven: 'bg-haven-100 text-haven-700',
  warm: 'bg-warm-100 text-warm-600',
};

function getInitialsFromName(name: string): string {
  return name
    .split(' ')
    .map((n) => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2);
}

function getVariantFromName(name: string): InitialsVariant {
  const variants: InitialsVariant[] = ['emerald', 'blue', 'purple', 'amber', 'rose', 'haven'];
  let hash = 0;
  for (let i = 0; i < name.length; i++) {
    hash = name.charCodeAt(i) + ((hash << 5) - hash);
  }
  return variants[Math.abs(hash) % variants.length];
}

export function InitialsAvatar({
  name,
  size = 'md',
  variant,
  className = ''
}: InitialsAvatarProps) {
  const initials = getInitialsFromName(name);
  const colorVariant = variant || getVariantFromName(name);

  return (
    <div
      className={`rounded-full flex items-center justify-center font-semibold flex-shrink-0 ${initialsSizeClasses[size]} ${initialsVariantClasses[colorVariant]} ${className}`}
    >
      {initials}
    </div>
  );
}

export default Avatar;
