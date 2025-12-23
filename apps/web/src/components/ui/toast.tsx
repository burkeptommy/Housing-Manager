'use client';

import { createContext, useContext, useState, useCallback, ReactNode } from 'react';
import { CheckCircle, XCircle, AlertCircle, Info, X } from 'lucide-react';

type ToastType = 'success' | 'error' | 'warning' | 'info';

interface Toast {
  id: string;
  type: ToastType;
  title: string;
  description?: string;
}

interface ToastContextType {
  toasts: Toast[];
  addToast: (toast: Omit<Toast, 'id'>) => void;
  removeToast: (id: string) => void;
}

const ToastContext = createContext<ToastContextType | null>(null);

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([]);

  const addToast = useCallback((toast: Omit<Toast, 'id'>) => {
    const id = Math.random().toString(36).slice(2);
    setToasts((prev) => [...prev, { ...toast, id }]);

    // Auto remove after 5 seconds
    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== id));
    }, 5000);
  }, []);

  const removeToast = useCallback((id: string) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  }, []);

  return (
    <ToastContext.Provider value={{ toasts, addToast, removeToast }}>
      {children}
      <ToastContainer />
    </ToastContext.Provider>
  );
}

export function useToast() {
  const context = useContext(ToastContext);
  if (!context) throw new Error('useToast must be used within ToastProvider');

  return {
    success: (title: string, description?: string) =>
      context.addToast({ type: 'success', title, description }),
    error: (title: string, description?: string) =>
      context.addToast({ type: 'error', title, description }),
    warning: (title: string, description?: string) =>
      context.addToast({ type: 'warning', title, description }),
    info: (title: string, description?: string) =>
      context.addToast({ type: 'info', title, description }),
  };
}

function ToastContainer() {
  const context = useContext(ToastContext);
  if (!context) return null;

  const { toasts, removeToast } = context;

  if (toasts.length === 0) return null;

  return (
    <div className="fixed bottom-4 right-4 z-50 flex flex-col gap-2">
      {toasts.map((toast) => (
        <ToastItem key={toast.id} toast={toast} onClose={() => removeToast(toast.id)} />
      ))}
    </div>
  );
}

const toastStyles: Record<ToastType, { icon: typeof CheckCircle; bg: string; iconColor: string }> = {
  success: { icon: CheckCircle, bg: 'bg-emerald-50 border-emerald-200', iconColor: 'text-emerald-500' },
  error: { icon: XCircle, bg: 'bg-red-50 border-red-200', iconColor: 'text-red-500' },
  warning: { icon: AlertCircle, bg: 'bg-amber-50 border-amber-200', iconColor: 'text-amber-500' },
  info: { icon: Info, bg: 'bg-blue-50 border-blue-200', iconColor: 'text-blue-500' },
};

function ToastItem({ toast, onClose }: { toast: Toast; onClose: () => void }) {
  const { icon: Icon, bg, iconColor } = toastStyles[toast.type];

  return (
    <div
      className={`flex items-start gap-3 px-4 py-3 rounded-xl border shadow-lg min-w-[300px] max-w-md
                  animate-in slide-in-from-right-full duration-300 ${bg}`}
    >
      <Icon className={`w-5 h-5 flex-shrink-0 mt-0.5 ${iconColor}`} />
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium text-warm-900">{toast.title}</p>
        {toast.description && (
          <p className="text-sm text-warm-600 mt-0.5">{toast.description}</p>
        )}
      </div>
      <button
        onClick={onClose}
        className="p-1 rounded-lg text-warm-400 hover:text-warm-600 hover:bg-white/50 transition-colors"
      >
        <X className="w-4 h-4" />
      </button>
    </div>
  );
}
