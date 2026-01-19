import Image from 'next/image';

interface AlfredLogoProps {
  variant?: 'light' | 'dark';
  size?: 'sm' | 'md' | 'lg' | 'xl';
  className?: string;
}

const sizes = { sm: 48, md: 80, lg: 120, xl: 160 };

export function AlfredLogo({ variant = 'light', size = 'md', className = '' }: AlfredLogoProps) {
  const src = variant === 'light' ? '/alfred-logo.svg' : '/alfred-logo-white.svg';
  return (
    <Image
      src={src}
      alt="Alfred"
      width={sizes[size]}
      height={sizes[size]}
      className={className}
    />
  );
}
