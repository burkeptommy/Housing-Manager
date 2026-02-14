'use client';

import { ReactNode } from 'react';

interface TableProps {
  children: ReactNode;
  className?: string;
}

export function Table({ children, className = '' }: TableProps) {
  return (
    <div className={`bg-white rounded-2xl border border-neutral-100 overflow-hidden ${className}`}>
      <table className="w-full">{children}</table>
    </div>
  );
}

export function TableHeader({ children }: { children: ReactNode }) {
  return (
    <thead className="bg-neutral-50 border-b border-neutral-100">
      {children}
    </thead>
  );
}

export function TableBody({ children }: { children: ReactNode }) {
  return <tbody className="divide-y divide-neutral-50">{children}</tbody>;
}

export function TableRow({
  children,
  onClick,
  className = '',
}: {
  children: ReactNode;
  onClick?: () => void;
  className?: string;
}) {
  return (
    <tr
      onClick={onClick}
      className={`${onClick ? 'cursor-pointer hover:bg-neutral-50 transition-colors' : ''} ${className}`}
    >
      {children}
    </tr>
  );
}

export function TableHead({ children, className = '' }: { children: ReactNode; className?: string }) {
  return (
    <th
      className={`px-6 py-3 text-left text-xs font-semibold text-neutral-600 uppercase tracking-wider ${className}`}
    >
      {children}
    </th>
  );
}

export function TableCell({
  children,
  className = '',
}: {
  children: ReactNode;
  className?: string;
}) {
  return (
    <td className={`px-6 py-4 text-sm text-neutral-700 ${className}`}>
      {children}
    </td>
  );
}

// Empty state for tables
export function TableEmpty({
  icon,
  title,
  description,
  action,
}: {
  icon?: ReactNode;
  title: string;
  description?: string;
  action?: ReactNode;
}) {
  return (
    <tr>
      <td colSpan={100}>
        <div className="flex flex-col items-center justify-center py-12 text-center">
          {icon && (
            <div className="w-12 h-12 rounded-xl bg-neutral-100 flex items-center justify-center text-neutral-400 mb-3">
              {icon}
            </div>
          )}
          <p className="text-neutral-900 font-medium">{title}</p>
          {description && <p className="text-sm text-neutral-500 mt-1">{description}</p>}
          {action && <div className="mt-4">{action}</div>}
        </div>
      </td>
    </tr>
  );
}

// Sortable table header
export function SortableHeader({
  children,
  sorted,
  direction,
  onSort,
}: {
  children: ReactNode;
  sorted: boolean;
  direction: 'asc' | 'desc';
  onSort: () => void;
}) {
  return (
    <th
      onClick={onSort}
      className="px-6 py-3 text-left text-xs font-semibold text-neutral-600 uppercase tracking-wider cursor-pointer
                 hover:text-neutral-900 transition-colors group"
    >
      <span className="flex items-center gap-1">
        {children}
        <span className={`transition-opacity ${sorted ? 'opacity-100' : 'opacity-0 group-hover:opacity-50'}`}>
          {direction === 'asc' ? '↑' : '↓'}
        </span>
      </span>
    </th>
  );
}
