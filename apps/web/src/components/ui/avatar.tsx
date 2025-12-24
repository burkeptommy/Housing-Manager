'use client';

import React from 'react';
import { Sparkles, Wrench, Bot, Star, Dog, Cat } from 'lucide-react';

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

// Size presets with icon and badge sizes
const sizes = {
  xs: { container: 24, icon: 12, badge: 10, text: 10 },
  sm: { container: 32, icon: 16, badge: 12, text: 12 },
  md: { container: 40, icon: 20, badge: 14, text: 14 },
  lg: { container: 48, icon: 24, badge: 16, text: 16 },
  xl: { container: 64, icon: 32, badge: 20, text: 20 },
  '2xl': { container: 80, icon: 40, badge: 24, text: 24 },
};

type AvatarSize = keyof typeof sizes;

// ===========================================
// HOME MANAGER AVATAR (Sarah Chen)
// Champagne gradient + Sparkles icon + Star badge
// ===========================================
interface ManagerAvatarProps {
  size?: AvatarSize;
  className?: string;
  showBadge?: boolean;
}

export function ManagerAvatar({ size = 'md', className = '', showBadge = true }: ManagerAvatarProps) {
  const s = sizes[size];

  return (
    <div
      className={`relative flex-shrink-0 ${className}`}
      style={{ width: s.container, height: s.container }}
    >
      {/* Main circle - Champagne gradient */}
      <div
        className="w-full h-full rounded-full bg-gradient-to-br from-champagne-200 to-champagne-300 flex items-center justify-center"
      >
        <Sparkles
          style={{ width: s.icon, height: s.icon }}
          className="text-champagne-700"
        />
      </div>

      {/* Star badge */}
      {showBadge && (
        <div
          className="absolute -top-0.5 -right-0.5 bg-amber-400 rounded-full flex items-center justify-center ring-2 ring-white"
          style={{ width: s.badge, height: s.badge }}
        >
          <Star
            style={{ width: s.badge * 0.6, height: s.badge * 0.6 }}
            className="text-amber-700 fill-current"
          />
        </div>
      )}
    </div>
  );
}

// ===========================================
// HANDYMAN AVATAR (Marcus Johnson)
// Orange gradient + Wrench icon + Tool badge
// ===========================================
interface HandymanAvatarProps {
  size?: AvatarSize;
  className?: string;
  showBadge?: boolean;
}

export function HandymanAvatar({ size = 'md', className = '', showBadge = true }: HandymanAvatarProps) {
  const s = sizes[size];

  return (
    <div
      className={`relative flex-shrink-0 ${className}`}
      style={{ width: s.container, height: s.container }}
    >
      {/* Main circle - Orange gradient */}
      <div
        className="w-full h-full rounded-full bg-gradient-to-br from-orange-200 to-orange-300 flex items-center justify-center"
      >
        <Wrench
          style={{ width: s.icon, height: s.icon }}
          className="text-orange-700"
        />
      </div>

      {/* Tool badge */}
      {showBadge && (
        <div
          className="absolute -top-0.5 -right-0.5 bg-orange-500 rounded-full flex items-center justify-center ring-2 ring-white"
          style={{ width: s.badge, height: s.badge }}
        >
          <Wrench
            style={{ width: s.badge * 0.6, height: s.badge * 0.6 }}
            className="text-white"
          />
        </div>
      )}
    </div>
  );
}

// ===========================================
// CONCIERGE AVATAR (AI Assistant)
// Navy gradient + Bot icon + Pulse indicator
// ===========================================
interface ConciergeAvatarProps {
  size?: AvatarSize;
  className?: string;
  showPulse?: boolean;
}

export function ConciergeAvatar({ size = 'md', className = '', showPulse = true }: ConciergeAvatarProps) {
  const s = sizes[size];

  return (
    <div
      className={`relative flex-shrink-0 ${className}`}
      style={{ width: s.container, height: s.container }}
    >
      {/* Main circle - Navy gradient */}
      <div
        className="w-full h-full rounded-full bg-gradient-to-br from-haven-600 to-haven-700 flex items-center justify-center"
      >
        <Bot
          style={{ width: s.icon, height: s.icon }}
          className="text-white"
        />
      </div>

      {/* Online pulse indicator */}
      {showPulse && (
        <div
          className="absolute bottom-0 right-0 bg-emerald-500 rounded-full ring-2 ring-white animate-pulse"
          style={{ width: s.badge * 0.6, height: s.badge * 0.6 }}
        />
      )}
    </div>
  );
}

// ===========================================
// PERSON AVATAR (Family Members)
// Silhouettes for male/female/boy/girl
// ===========================================
interface PersonAvatarProps {
  name: string;
  type: 'male' | 'female' | 'boy' | 'girl';
  size?: AvatarSize;
  className?: string;
}

// Male Adult Silhouette
function MaleSilhouette({ color }: { color: string }) {
  return (
    <g fill={color}>
      <circle cx="20" cy="12" r="7" />
      <path d="M8 40 L12 28 C14 24 17 22 20 22 C23 22 26 24 28 28 L32 40 Z" />
    </g>
  );
}

// Female Adult Silhouette
function FemaleSilhouette({ color }: { color: string }) {
  return (
    <g fill={color}>
      <circle cx="20" cy="12" r="7" />
      <ellipse cx="20" cy="10" rx="8" ry="6" />
      <path d="M10 40 L13 28 C15 24 17 22 20 22 C23 22 25 24 27 28 L30 40 Z" />
    </g>
  );
}

// Boy Silhouette
function BoySilhouette({ color }: { color: string }) {
  return (
    <g fill={color}>
      <circle cx="20" cy="13" r="8" />
      <path d="M12 40 L14 30 C16 26 18 24 20 24 C22 24 24 26 26 30 L28 40 Z" />
    </g>
  );
}

// Girl Silhouette
function GirlSilhouette({ color }: { color: string }) {
  return (
    <g fill={color}>
      <circle cx="20" cy="13" r="8" />
      <circle cx="11" cy="11" r="3" />
      <circle cx="29" cy="11" r="3" />
      <path d="M12 40 L14 30 C16 26 18 24 20 24 C22 24 24 26 26 30 L28 40 Z" />
    </g>
  );
}

export function PersonAvatar({ name, type, size = 'md', className = '' }: PersonAvatarProps) {
  const s = sizes[size];
  const color = colors[getColorIndex(name)];

  return (
    <svg
      width={s.container}
      height={s.container}
      viewBox="0 0 40 40"
      className={`rounded-full flex-shrink-0 ${className}`}
      style={{ backgroundColor: color.bg }}
    >
      {type === 'male' && <MaleSilhouette color={color.fill} />}
      {type === 'female' && <FemaleSilhouette color={color.fill} />}
      {type === 'boy' && <BoySilhouette color={color.fill} />}
      {type === 'girl' && <GirlSilhouette color={color.fill} />}
    </svg>
  );
}

// ===========================================
// PET AVATAR
// ===========================================
interface PetAvatarProps {
  name: string;
  type: 'dog' | 'cat';
  size?: AvatarSize;
  className?: string;
}

export function PetAvatar({ name, type, size = 'md', className = '' }: PetAvatarProps) {
  const s = sizes[size];
  const color = colors[getColorIndex(name)];
  const Icon = type === 'dog' ? Dog : Cat;

  return (
    <div
      className={`rounded-full flex items-center justify-center flex-shrink-0 ${className}`}
      style={{
        width: s.container,
        height: s.container,
        backgroundColor: color.bg,
      }}
    >
      <Icon style={{ width: s.icon, height: s.icon, color: color.fill }} />
    </div>
  );
}

// ===========================================
// VENDOR AVATAR (Initials with color)
// ===========================================
interface VendorAvatarProps {
  name: string;
  size?: AvatarSize;
  className?: string;
}

export function VendorAvatar({ name, size = 'md', className = '' }: VendorAvatarProps) {
  const s = sizes[size];
  const color = colors[getColorIndex(name)];

  const initials = name
    .split(' ')
    .slice(0, 2)
    .map(word => word[0])
    .join('')
    .toUpperCase();

  return (
    <div
      className={`rounded-xl flex items-center justify-center font-semibold flex-shrink-0 ${className}`}
      style={{
        width: s.container,
        height: s.container,
        backgroundColor: color.bg,
        color: color.fill,
        fontSize: s.text,
      }}
    >
      {initials}
    </div>
  );
}

// ===========================================
// GENERIC AVATAR (Backward compatible)
// ===========================================
interface AvatarProps {
  name: string;
  type: 'male' | 'female' | 'boy' | 'girl' | 'pet-dog' | 'pet-cat';
  size?: AvatarSize;
  className?: string;
}

export function Avatar({ name, type, size = 'md', className = '' }: AvatarProps) {
  // Map pet types to PetAvatar
  if (type === 'pet-dog') {
    return <PetAvatar name={name} type="dog" size={size} className={className} />;
  }
  if (type === 'pet-cat') {
    return <PetAvatar name={name} type="cat" size={size} className={className} />;
  }

  // Use PersonAvatar for people types
  return <PersonAvatar name={name} type={type} size={size} className={className} />;
}

// ===========================================
// INITIALS AVATAR (Legacy support)
// ===========================================
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
