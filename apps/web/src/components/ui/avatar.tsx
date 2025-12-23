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
