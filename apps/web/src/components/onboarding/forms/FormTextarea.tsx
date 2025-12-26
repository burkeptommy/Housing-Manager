'use client';

import { forwardRef, TextareaHTMLAttributes } from 'react';
import { cn } from '@/lib/utils';

interface FormTextareaProps extends TextareaHTMLAttributes<HTMLTextAreaElement> {
  label: string;
  error?: string;
  hint?: string;
}

export const FormTextarea = forwardRef<HTMLTextAreaElement, FormTextareaProps>(
  ({ label, error, hint, className, ...props }, ref) => {
    return (
      <div className="space-y-1">
        <label className="block text-sm font-medium text-gray-700">
          {label}
          {props.required && <span className="text-red-500 ml-1">*</span>}
        </label>
        <textarea
          ref={ref}
          className={cn(
            'w-full px-4 py-3 rounded-xl border transition-all outline-none resize-none',
            'focus:ring-2 focus:ring-haven-champagne-200',
            error
              ? 'border-red-300 focus:border-red-500'
              : 'border-gray-300 focus:border-haven-champagne-500',
            className
          )}
          {...props}
        />
        {hint && !error && <p className="text-sm text-gray-500">{hint}</p>}
        {error && <p className="text-sm text-red-600">{error}</p>}
      </div>
    );
  }
);

FormTextarea.displayName = 'FormTextarea';
