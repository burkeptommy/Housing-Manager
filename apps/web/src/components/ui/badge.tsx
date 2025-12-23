'use client';

import { ReactNode } from 'react';

type BadgeVariant = 'success' | 'warning' | 'error' | 'info' | 'neutral' | 'premium';

interface BadgeProps {
  children: ReactNode;
  variant?: BadgeVariant;
  size?: 'sm' | 'md';
  icon?: ReactNode;
  className?: string;
}

const variantClasses: Record<BadgeVariant, string> = {
  success: 'bg-emerald-50 text-emerald-700 ring-1 ring-inset ring-emerald-600/20',
  warning: 'bg-amber-50 text-amber-700 ring-1 ring-inset ring-amber-600/20',
  error: 'bg-red-50 text-red-700 ring-1 ring-inset ring-red-600/20',
  info: 'bg-blue-50 text-blue-700 ring-1 ring-inset ring-blue-600/20',
  neutral: 'bg-warm-100 text-warm-700 ring-1 ring-inset ring-warm-600/10',
  premium: 'bg-gradient-to-r from-gold-50 to-gold-100 text-gold-800 ring-1 ring-inset ring-gold-400/30',
};

const sizeClasses = {
  sm: 'px-2 py-0.5 text-xs',
  md: 'px-2.5 py-1 text-sm',
};

export function Badge({
  children,
  variant = 'neutral',
  size = 'sm',
  icon,
  className = '',
}: BadgeProps) {
  return (
    <span
      className={`inline-flex items-center gap-1 rounded-full font-medium
                  ${variantClasses[variant]} ${sizeClasses[size]} ${className}`}
    >
      {icon && <span className="flex-shrink-0">{icon}</span>}
      {children}
    </span>
  );
}

// Status badge with dot indicator
export function StatusBadge({
  status,
  label,
}: {
  status: 'active' | 'pending' | 'completed' | 'cancelled';
  label?: string;
}) {
  const config: Record<string, { variant: BadgeVariant; dot: string; text: string }> = {
    active: { variant: 'info', dot: 'bg-blue-500', text: 'Active' },
    pending: { variant: 'warning', dot: 'bg-amber-500', text: 'Pending' },
    completed: { variant: 'success', dot: 'bg-emerald-500', text: 'Completed' },
    cancelled: { variant: 'error', dot: 'bg-red-500', text: 'Cancelled' },
  };

  const { variant, dot, text } = config[status] || config.pending;

  return (
    <Badge
      variant={variant}
      icon={<span className={`w-1.5 h-1.5 rounded-full ${dot}`} />}
    >
      {label || text}
    </Badge>
  );
}
