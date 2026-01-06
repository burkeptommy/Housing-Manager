'use client';

import Image from 'next/image';

interface HavenLogoProps {
  variant?: 'icon' | 'wordmark';
  color?: 'white' | 'navy';
  size?: 'sm' | 'md' | 'lg';
  className?: string;
}

const sizes = {
  sm: { icon: 24, wordmark: { width: 100, height: 24 } },
  md: { icon: 32, wordmark: { width: 120, height: 32 } },
  lg: { icon: 40, wordmark: { width: 140, height: 36 } },
};

export function HavenLogo({
  variant = 'icon',
  color = 'navy',
  size = 'md',
  className = ''
}: HavenLogoProps) {
  const sizeConfig = sizes[size];

  if (variant === 'wordmark') {
    const src = color === 'white' ? '/logo-wordmark-white.svg' : '/logo-wordmark.svg';
    return (
      <Image
        src={src}
        alt="Haven"
        width={sizeConfig.wordmark.width}
        height={sizeConfig.wordmark.height}
        className={className}
        priority
      />
    );
  }

  const src = color === 'white' ? '/icon-white.svg' : '/icon-navy.svg';
  return (
    <Image
      src={src}
      alt="Haven"
      width={sizeConfig.icon}
      height={sizeConfig.icon}
      className={className}
      priority
    />
  );
}

// Simple icon component for places that need just the icon in a container
export function HavenIcon({
  color = 'navy',
  size = 32,
  className = ''
}: {
  color?: 'white' | 'navy';
  size?: number;
  className?: string;
}) {
  const src = color === 'white' ? '/icon-white.svg' : '/icon-navy.svg';
  return (
    <Image
      src={src}
      alt="Haven"
      width={size}
      height={size}
      className={className}
      priority
    />
  );
}
