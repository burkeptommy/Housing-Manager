'use client';

import Image from 'next/image';
import { getAvatarUrl, getInitials } from '@/lib/images';

type AvatarSize = 'sm' | 'md' | 'lg' | 'xl' | '2xl';
type StatusType = 'online' | 'offline' | 'busy' | 'away';

interface AvatarProps {
  name: string;
  src?: string | null;
  size?: AvatarSize;
  status?: StatusType;
  className?: string;
}

const sizeClasses: Record<AvatarSize, string> = {
  sm: 'w-8 h-8 text-xs',
  md: 'w-10 h-10 text-sm',
  lg: 'w-12 h-12 text-base',
  xl: 'w-16 h-16 text-lg',
  '2xl': 'w-24 h-24 text-2xl',
};

const statusClasses: Record<StatusType, string> = {
  online: 'bg-emerald-500',
  offline: 'bg-warm-400',
  busy: 'bg-red-500',
  away: 'bg-amber-500',
};

export function Avatar({ name, src, size = 'md', status, className = '' }: AvatarProps) {
  const imageUrl = src || getAvatarUrl(name);
  const initials = getInitials(name);

  return (
    <div className={`relative inline-flex ${className}`}>
      {imageUrl ? (
        <Image
          src={imageUrl}
          alt={name}
          width={size === '2xl' ? 96 : size === 'xl' ? 64 : size === 'lg' ? 48 : size === 'md' ? 40 : 32}
          height={size === '2xl' ? 96 : size === 'xl' ? 64 : size === 'lg' ? 48 : size === 'md' ? 40 : 32}
          className={`rounded-full object-cover ring-2 ring-white shadow-sm ${sizeClasses[size]}`}
        />
      ) : (
        <div
          className={`rounded-full bg-gradient-to-br from-haven-400 to-haven-600 text-white font-semibold
                      flex items-center justify-center ring-2 ring-white shadow-sm ${sizeClasses[size]}`}
        >
          {initials}
        </div>
      )}
      {status && (
        <span
          className={`absolute bottom-0 right-0 w-3 h-3 rounded-full ring-2 ring-white ${statusClasses[status]}`}
        />
      )}
    </div>
  );
}

export function AvatarGroup({
  avatars,
  max = 4,
  size = 'md'
}: {
  avatars: Array<{ name: string; src?: string }>;
  max?: number;
  size?: AvatarSize;
}) {
  const visible = avatars.slice(0, max);
  const remaining = avatars.length - max;

  return (
    <div className="flex -space-x-2">
      {visible.map((avatar, i) => (
        <Avatar key={i} name={avatar.name} src={avatar.src} size={size} />
      ))}
      {remaining > 0 && (
        <div
          className={`rounded-full bg-warm-100 text-warm-600 font-medium
                      flex items-center justify-center ring-2 ring-white ${sizeClasses[size]}`}
        >
          +{remaining}
        </div>
      )}
    </div>
  );
}

// ============================================================================
// INITIALS AVATARS - Consistent colored circles with initials
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
  haven: 'bg-haven-100 text-haven-600',
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

// Deterministic color based on name
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

// For vendors - use a slightly different style with rounded corners
export function VendorAvatar({
  name,
  size = 'md',
  className = ''
}: Omit<InitialsAvatarProps, 'variant'>) {
  const initials = getInitialsFromName(name);

  return (
    <div
      className={`rounded-xl flex items-center justify-center font-semibold flex-shrink-0 bg-warm-100 text-warm-600 ${initialsSizeClasses[size]} ${className}`}
    >
      {initials}
    </div>
  );
}
