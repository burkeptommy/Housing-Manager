'use client';

import { forwardRef, ButtonHTMLAttributes, ReactNode } from 'react';
import { Loader2 } from 'lucide-react';

type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger' | 'outline';
type ButtonSize = 'sm' | 'md' | 'lg';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant;
  size?: ButtonSize;
  isLoading?: boolean;
  leftIcon?: ReactNode;
  rightIcon?: ReactNode;
}

const variantClasses: Record<ButtonVariant, string> = {
  primary: `bg-gradient-to-b from-haven-500 to-haven-600 text-white
            shadow-[0_1px_2px_rgba(0,0,0,0.1),0_2px_4px_rgba(0,0,0,0.1),inset_0_1px_0_rgba(255,255,255,0.15)]
            hover:from-haven-600 hover:to-haven-700 hover:shadow-[0_2px_4px_rgba(0,0,0,0.15),0_4px_8px_rgba(0,0,0,0.1)]`,
  secondary: `bg-white text-warm-700 border border-warm-200 shadow-sm
              hover:bg-warm-50 hover:border-warm-300 hover:text-warm-900`,
  ghost: `text-warm-600 hover:bg-warm-100 hover:text-warm-900`,
  danger: `bg-gradient-to-b from-red-500 to-red-600 text-white
           shadow-[0_1px_2px_rgba(0,0,0,0.1),inset_0_1px_0_rgba(255,255,255,0.15)]
           hover:from-red-600 hover:to-red-700`,
  outline: `bg-transparent text-haven-600 border border-haven-300
            hover:bg-haven-50 hover:border-haven-400`,
};

const sizeClasses: Record<ButtonSize, string> = {
  sm: 'px-3 py-1.5 text-sm rounded-lg gap-1.5',
  md: 'px-5 py-2.5 text-sm rounded-xl gap-2',
  lg: 'px-6 py-3 text-base rounded-xl gap-2.5',
};

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  (
    {
      variant = 'primary',
      size = 'md',
      isLoading = false,
      leftIcon,
      rightIcon,
      children,
      disabled,
      className = '',
      ...props
    },
    ref
  ) => {
    return (
      <button
        ref={ref}
        disabled={disabled || isLoading}
        className={`inline-flex items-center justify-center font-medium
                    transition-all duration-200 active:scale-[0.98]
                    disabled:opacity-50 disabled:cursor-not-allowed disabled:active:scale-100
                    ${variantClasses[variant]} ${sizeClasses[size]} ${className}`}
        {...props}
      >
        {isLoading ? (
          <Loader2 className="w-4 h-4 animate-spin" />
        ) : (
          leftIcon
        )}
        {children}
        {!isLoading && rightIcon}
      </button>
    );
  }
);

Button.displayName = 'Button';

// Icon-only button
export function IconButton({
  icon,
  variant = 'ghost',
  size = 'md',
  label,
  ...props
}: Omit<ButtonProps, 'children' | 'leftIcon' | 'rightIcon'> & {
  icon: ReactNode;
  label: string;
}) {
  const iconSizeClasses: Record<ButtonSize, string> = {
    sm: 'p-1.5 rounded-lg',
    md: 'p-2 rounded-xl',
    lg: 'p-3 rounded-xl',
  };

  return (
    <button
      aria-label={label}
      className={`inline-flex items-center justify-center
                  transition-all duration-200 active:scale-[0.95]
                  disabled:opacity-50 disabled:cursor-not-allowed
                  ${variantClasses[variant]} ${iconSizeClasses[size]}`}
      {...props}
    >
      {icon}
    </button>
  );
}
