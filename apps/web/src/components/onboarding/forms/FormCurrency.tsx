'use client';

import { forwardRef, InputHTMLAttributes, useState, useEffect } from 'react';
import { cn } from '@/lib/utils';
import { DollarSign } from 'lucide-react';

interface FormCurrencyProps
  extends Omit<InputHTMLAttributes<HTMLInputElement>, 'onChange' | 'value'> {
  label: string;
  error?: string;
  hint?: string;
  value: number | undefined;
  onChange: (value: number | undefined) => void;
}

export const FormCurrency = forwardRef<HTMLInputElement, FormCurrencyProps>(
  ({ label, error, hint, value, onChange, className, ...props }, ref) => {
    const [displayValue, setDisplayValue] = useState(value !== undefined ? value.toString() : '');

    useEffect(() => {
      if (value !== undefined) {
        setDisplayValue(value.toString());
      }
    }, [value]);

    const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
      const raw = e.target.value.replace(/[^0-9.]/g, '');
      setDisplayValue(raw);

      const num = parseFloat(raw);
      onChange(isNaN(num) ? undefined : num);
    };

    const handleBlur = () => {
      if (value !== undefined) {
        setDisplayValue(value.toFixed(2));
      }
    };

    return (
      <div className="space-y-1">
        <label className="block text-sm font-medium text-gray-700">
          {label}
          {props.required && <span className="text-red-500 ml-1">*</span>}
        </label>
        <div className="relative">
          <div className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400">
            <DollarSign className="w-5 h-5" />
          </div>
          <input
            ref={ref}
            type="text"
            inputMode="decimal"
            value={displayValue}
            onChange={handleChange}
            onBlur={handleBlur}
            className={cn(
              'w-full pl-11 pr-4 py-3 rounded-xl border transition-all outline-none',
              'focus:ring-2 focus:ring-haven-champagne-200',
              error
                ? 'border-red-300 focus:border-red-500'
                : 'border-gray-300 focus:border-haven-champagne-500',
              className
            )}
            {...props}
          />
        </div>
        {hint && !error && <p className="text-sm text-gray-500">{hint}</p>}
        {error && <p className="text-sm text-red-600">{error}</p>}
      </div>
    );
  }
);

FormCurrency.displayName = 'FormCurrency';
