'use client';

import { ReactNode, useEffect } from 'react';
import { X } from 'lucide-react';
import { IconButton } from './button';

interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title?: string;
  description?: string;
  children: ReactNode;
  size?: 'sm' | 'md' | 'lg' | 'xl';
  showClose?: boolean;
}

const sizeClasses = {
  sm: 'max-w-sm',
  md: 'max-w-md',
  lg: 'max-w-lg',
  xl: 'max-w-xl',
};

export function Modal({
  isOpen,
  onClose,
  title,
  description,
  children,
  size = 'md',
  showClose = true,
}: ModalProps) {
  // Handle escape key
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };

    if (isOpen) {
      document.addEventListener('keydown', handleEscape);
      document.body.style.overflow = 'hidden';
    }

    return () => {
      document.removeEventListener('keydown', handleEscape);
      document.body.style.overflow = '';
    };
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-neutral-900/50 backdrop-blur-sm animate-in fade-in duration-200"
        onClick={onClose}
      />

      {/* Modal */}
      <div
        className={`relative bg-white rounded-2xl shadow-2xl w-full ${sizeClasses[size]}
                    animate-in fade-in zoom-in-95 duration-200`}
      >
        {/* Header */}
        {(title || showClose) && (
          <div className="flex items-start justify-between p-6 pb-0">
            <div>
              {title && <h2 className="text-lg font-semibold text-neutral-900">{title}</h2>}
              {description && <p className="text-sm text-neutral-500 mt-1">{description}</p>}
            </div>
            {showClose && (
              <IconButton
                icon={<X className="w-5 h-5" />}
                label="Close"
                onClick={onClose}
                className="-mt-1 -mr-1"
              />
            )}
          </div>
        )}

        {/* Content */}
        <div className="p-6">{children}</div>
      </div>
    </div>
  );
}

// Confirmation dialog variant
export function ConfirmDialog({
  isOpen,
  onClose,
  onConfirm,
  title,
  description,
  confirmLabel = 'Confirm',
  cancelLabel = 'Cancel',
  variant = 'danger',
}: {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  title: string;
  description: string;
  confirmLabel?: string;
  cancelLabel?: string;
  variant?: 'danger' | 'primary';
}) {
  return (
    <Modal isOpen={isOpen} onClose={onClose} size="sm" showClose={false}>
      <div className="text-center">
        <h3 className="text-lg font-semibold text-neutral-900">{title}</h3>
        <p className="mt-2 text-sm text-neutral-500">{description}</p>
        <div className="flex gap-3 mt-6">
          <button
            onClick={onClose}
            className="flex-1 px-4 py-2.5 text-sm font-medium text-neutral-700 bg-neutral-100 rounded-xl
                       hover:bg-neutral-200 transition-colors"
          >
            {cancelLabel}
          </button>
          <button
            onClick={() => {
              onConfirm();
              onClose();
            }}
            className={`flex-1 px-4 py-2.5 text-sm font-medium text-white rounded-xl transition-colors
                       ${variant === 'danger'
                         ? 'bg-red-500 hover:bg-red-600'
                         : 'bg-haven-700 hover:bg-haven-800'}`}
          >
            {confirmLabel}
          </button>
        </div>
      </div>
    </Modal>
  );
}
