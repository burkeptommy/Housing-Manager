'use client';

import { forwardRef, InputHTMLAttributes } from 'react';
import { cn } from '@/lib/utils';
import { Check } from 'lucide-react';

interface FormCheckboxProps extends Omit<InputHTMLAttributes<HTMLInputElement>, 'type'> {
  label: string;
  description?: string;
}

export const FormCheckbox = forwardRef<HTMLInputElement, FormCheckboxProps>(
  ({ label, description, className, ...props }, ref) => {
    return (
      <label className="flex items-start gap-3 cursor-pointer group">
        <div className="relative mt-0.5">
          <input ref={ref} type="checkbox" className="sr-only peer" {...props} />
          <div
            className={cn(
              'w-5 h-5 rounded border-2 transition-all',
              'border-gray-300 group-hover:border-gray-400',
              'peer-checked:bg-haven-navy-900 peer-checked:border-haven-navy-900',
              'peer-focus:ring-2 peer-focus:ring-haven-champagne-200 peer-focus:ring-offset-2'
            )}
          />
          <Check className="absolute top-0.5 left-0.5 w-4 h-4 text-white opacity-0 peer-checked:opacity-100 transition-opacity" />
        </div>
        <div>
          <span className="text-sm font-medium text-gray-900">{label}</span>
          {description && <p className="text-sm text-gray-500">{description}</p>}
        </div>
      </label>
    );
  }
);

FormCheckbox.displayName = 'FormCheckbox';
