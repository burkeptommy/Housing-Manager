'use client';

import { ReactNode } from 'react';
import { Button } from './button';

interface EmptyStateProps {
  icon?: ReactNode;
  title: string;
  description?: string;
  action?: {
    label: string;
    onClick: () => void;
  };
  className?: string;
}

export function EmptyState({ icon, title, description, action, className = '' }: EmptyStateProps) {
  return (
    <div className={`flex flex-col items-center justify-center py-12 px-4 text-center ${className}`}>
      {icon && (
        <div className="w-16 h-16 rounded-2xl bg-neutral-100 flex items-center justify-center text-neutral-400 mb-4">
          {icon}
        </div>
      )}
      <h3 className="text-lg font-semibold text-neutral-900">{title}</h3>
      {description && (
        <p className="mt-2 text-sm text-neutral-500 max-w-sm">{description}</p>
      )}
      {action && (
        <Button onClick={action.onClick} className="mt-6">
          {action.label}
        </Button>
      )}
    </div>
  );
}

// Illustration-based empty state for premium feel
export function IllustratedEmptyState({
  illustration,
  title,
  description,
  action,
  secondaryAction,
}: {
  illustration: ReactNode;
  title: string;
  description: string;
  action?: { label: string; onClick: () => void };
  secondaryAction?: { label: string; onClick: () => void };
}) {
  return (
    <div className="flex flex-col items-center justify-center py-16 px-4 text-center">
      <div className="mb-6">{illustration}</div>
      <h3 className="text-xl font-semibold text-neutral-900">{title}</h3>
      <p className="mt-2 text-neutral-500 max-w-md">{description}</p>
      <div className="flex items-center gap-3 mt-8">
        {action && (
          <Button onClick={action.onClick}>{action.label}</Button>
        )}
        {secondaryAction && (
          <Button variant="secondary" onClick={secondaryAction.onClick}>
            {secondaryAction.label}
          </Button>
        )}
      </div>
    </div>
  );
}
