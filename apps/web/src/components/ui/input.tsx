'use client';

import { forwardRef, InputHTMLAttributes, TextareaHTMLAttributes, ReactNode } from 'react';

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  hint?: string;
  leftIcon?: ReactNode;
  rightIcon?: ReactNode;
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, hint, leftIcon, rightIcon, className = '', ...props }, ref) => {
    return (
      <div className="w-full">
        {label && (
          <label className="block text-sm font-medium text-warm-700 mb-1.5">
            {label}
          </label>
        )}
        <div className="relative">
          {leftIcon && (
            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-warm-400">
              {leftIcon}
            </div>
          )}
          <input
            ref={ref}
            className={`w-full rounded-xl border bg-white px-4 py-2.5 text-warm-900 placeholder-warm-400
                       transition-all duration-200
                       focus:outline-none focus:ring-2 focus:ring-haven-500/20 focus:border-haven-500
                       disabled:bg-warm-50 disabled:text-warm-500 disabled:cursor-not-allowed
                       ${leftIcon ? 'pl-10' : ''}
                       ${rightIcon ? 'pr-10' : ''}
                       ${error ? 'border-red-300 focus:ring-red-500/20 focus:border-red-500' : 'border-warm-200'}
                       ${className}`}
            {...props}
          />
          {rightIcon && (
            <div className="absolute inset-y-0 right-0 pr-3 flex items-center text-warm-400">
              {rightIcon}
            </div>
          )}
        </div>
        {error && <p className="mt-1.5 text-sm text-red-600">{error}</p>}
        {hint && !error && <p className="mt-1.5 text-sm text-warm-500">{hint}</p>}
      </div>
    );
  }
);

Input.displayName = 'Input';

interface TextareaProps extends TextareaHTMLAttributes<HTMLTextAreaElement> {
  label?: string;
  error?: string;
  hint?: string;
}

export const Textarea = forwardRef<HTMLTextAreaElement, TextareaProps>(
  ({ label, error, hint, className = '', ...props }, ref) => {
    return (
      <div className="w-full">
        {label && (
          <label className="block text-sm font-medium text-warm-700 mb-1.5">
            {label}
          </label>
        )}
        <textarea
          ref={ref}
          className={`w-full rounded-xl border bg-white px-4 py-3 text-warm-900 placeholder-warm-400
                     transition-all duration-200 resize-none
                     focus:outline-none focus:ring-2 focus:ring-haven-500/20 focus:border-haven-500
                     disabled:bg-warm-50 disabled:text-warm-500 disabled:cursor-not-allowed
                     ${error ? 'border-red-300 focus:ring-red-500/20 focus:border-red-500' : 'border-warm-200'}
                     ${className}`}
          {...props}
        />
        {error && <p className="mt-1.5 text-sm text-red-600">{error}</p>}
        {hint && !error && <p className="mt-1.5 text-sm text-warm-500">{hint}</p>}
      </div>
    );
  }
);

Textarea.displayName = 'Textarea';

interface SelectProps extends InputHTMLAttributes<HTMLSelectElement> {
  label?: string;
  error?: string;
  hint?: string;
  options: Array<{ value: string; label: string }>;
}

export const Select = forwardRef<HTMLSelectElement, SelectProps>(
  ({ label, error, hint, options, className = '', ...props }, ref) => {
    return (
      <div className="w-full">
        {label && (
          <label className="block text-sm font-medium text-warm-700 mb-1.5">
            {label}
          </label>
        )}
        <select
          ref={ref}
          className={`w-full rounded-xl border bg-white px-4 py-2.5 text-warm-900
                     transition-all duration-200 appearance-none
                     bg-[url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='M6 8l4 4 4-4'/%3e%3c/svg%3e")]
                     bg-[length:1.5em_1.5em] bg-[right_0.5rem_center] bg-no-repeat
                     focus:outline-none focus:ring-2 focus:ring-haven-500/20 focus:border-haven-500
                     disabled:bg-warm-50 disabled:text-warm-500 disabled:cursor-not-allowed
                     ${error ? 'border-red-300 focus:ring-red-500/20 focus:border-red-500' : 'border-warm-200'}
                     ${className}`}
          {...props}
        >
          {options.map((option) => (
            <option key={option.value} value={option.value}>
              {option.label}
            </option>
          ))}
        </select>
        {error && <p className="mt-1.5 text-sm text-red-600">{error}</p>}
        {hint && !error && <p className="mt-1.5 text-sm text-warm-500">{hint}</p>}
      </div>
    );
  }
);

Select.displayName = 'Select';
