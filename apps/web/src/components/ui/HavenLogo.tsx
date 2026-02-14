'use client';

interface HavenLogoProps {
  variant?: 'icon' | 'wordmark';
  color?: 'white' | 'purple';
  size?: 'sm' | 'md' | 'lg';
  className?: string;
}

const sizeClasses = {
  sm: { icon: 'h-6 w-6', wordmark: 'h-6 w-auto' },
  md: { icon: 'h-8 w-8', wordmark: 'h-8 w-auto' },
  lg: { icon: 'h-10 w-10', wordmark: 'h-9 w-auto' },
};

export function HavenLogo({
  variant = 'icon',
  color = 'purple',
  size = 'md',
  className = ''
}: HavenLogoProps) {
  const sizeClass = sizeClasses[size];

  if (variant === 'wordmark') {
    const src = color === 'white' ? '/logo-wordmark-white.svg' : '/logo-wordmark.svg';
    return (
      <img
        src={src}
        alt="Haven"
        className={`${sizeClass.wordmark} ${className}`}
      />
    );
  }

  const src = color === 'white' ? '/icon-white.svg' : '/icon-purple.svg';
  return (
    <img
      src={src}
      alt="Haven"
      className={`${sizeClass.icon} ${className}`}
    />
  );
}

// Simple icon component for places that need just the icon in a container
export function HavenIcon({
  color = 'purple',
  size = 32,
  className = ''
}: {
  color?: 'white' | 'purple';
  size?: number;
  className?: string;
}) {
  const src = color === 'white' ? '/icon-white.svg' : '/icon-purple.svg';
  return (
    <img
      src={src}
      alt="Haven"
      style={{ width: size, height: size }}
      className={className}
    />
  );
}
