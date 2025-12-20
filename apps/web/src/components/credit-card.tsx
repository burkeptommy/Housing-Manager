'use client';

import { useState } from 'react';
import { Lock, Unlock, Wifi, CreditCard as CreditCardIcon } from 'lucide-react';

interface CreditCardProps {
  cardholderName: string;
  lastFour: string;
  expiry: string;
  isLocked: boolean;
  onToggleLock: (locked: boolean) => void;
}

export function CreditCard({
  cardholderName,
  lastFour,
  expiry,
  isLocked,
  onToggleLock,
}: CreditCardProps) {
  const [isHovered, setIsHovered] = useState(false);

  return (
    <div
      className={`relative w-full max-w-md aspect-[1.586/1] rounded-2xl overflow-hidden transition-all duration-500 ${
        isLocked ? 'grayscale' : ''
      } ${isHovered ? 'scale-[1.02] shadow-2xl' : 'shadow-xl'}`}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
    >
      {/* Card Background */}
      <div className="absolute inset-0 bg-gradient-to-br from-emerald-900 via-emerald-800 to-slate-900" />

      {/* Subtle Pattern Overlay */}
      <div className="absolute inset-0 opacity-10">
        <svg className="w-full h-full" viewBox="0 0 400 250">
          <defs>
            <pattern id="grid" width="20" height="20" patternUnits="userSpaceOnUse">
              <path d="M 20 0 L 0 0 0 20" fill="none" stroke="white" strokeWidth="0.5" />
            </pattern>
          </defs>
          <rect width="100%" height="100%" fill="url(#grid)" />
        </svg>
      </div>

      {/* Decorative Circles */}
      <div className="absolute -top-20 -right-20 w-64 h-64 rounded-full bg-emerald-600/20 blur-3xl" />
      <div className="absolute -bottom-32 -left-32 w-80 h-80 rounded-full bg-slate-600/20 blur-3xl" />

      {/* Card Content */}
      <div className="relative h-full p-6 flex flex-col justify-between">
        {/* Top Row */}
        <div className="flex items-start justify-between">
          {/* Logo & Brand */}
          <div className="flex items-center gap-2">
            <div className="w-10 h-10 rounded-lg bg-white/10 backdrop-blur-sm flex items-center justify-center">
              <CreditCardIcon className="w-5 h-5 text-white" />
            </div>
            <div>
              <div className="text-white font-bold text-lg tracking-tight">Haven</div>
              <div className="text-emerald-300/80 text-xs font-medium">Estate Card</div>
            </div>
          </div>

          {/* Lock Toggle */}
          <button
            onClick={() => onToggleLock(!isLocked)}
            className={`flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-medium transition-all ${
              isLocked
                ? 'bg-red-500/20 text-red-300 border border-red-500/30'
                : 'bg-white/10 text-white/80 border border-white/10 hover:bg-white/20'
            }`}
          >
            {isLocked ? (
              <>
                <Lock className="w-3 h-3" />
                Locked
              </>
            ) : (
              <>
                <Unlock className="w-3 h-3" />
                Active
              </>
            )}
          </button>
        </div>

        {/* EMV Chip & Contactless */}
        <div className="flex items-center gap-4">
          {/* Chip */}
          <div className="w-12 h-9 rounded-md bg-gradient-to-br from-amber-300 via-amber-400 to-amber-500 flex items-center justify-center">
            <div className="w-8 h-6 rounded-sm border-2 border-amber-600/30">
              <div className="w-full h-full grid grid-cols-3 gap-px p-0.5">
                {[...Array(6)].map((_, i) => (
                  <div key={i} className="bg-amber-600/20 rounded-sm" />
                ))}
              </div>
            </div>
          </div>

          {/* Contactless */}
          <Wifi className="w-6 h-6 text-white/60 rotate-90" />
        </div>

        {/* Card Number */}
        <div className="space-y-1">
          <div className="text-white/50 text-xs font-medium tracking-wider uppercase">Card Number</div>
          <div className="flex items-center gap-3 text-white text-xl font-mono tracking-widest">
            <span className="opacity-60">••••</span>
            <span className="opacity-60">••••</span>
            <span className="opacity-60">••••</span>
            <span>{lastFour}</span>
          </div>
        </div>

        {/* Bottom Row */}
        <div className="flex items-end justify-between">
          <div>
            <div className="text-white/50 text-xs font-medium tracking-wider uppercase mb-1">Cardholder</div>
            <div className="text-white font-semibold tracking-wide">{cardholderName}</div>
          </div>

          <div className="text-right">
            <div className="text-white/50 text-xs font-medium tracking-wider uppercase mb-1">Expires</div>
            <div className="text-white font-semibold font-mono">{expiry}</div>
          </div>

          {/* Card Network Logo */}
          <div className="flex items-center">
            <div className="w-8 h-8 rounded-full bg-red-500 opacity-80 -mr-3" />
            <div className="w-8 h-8 rounded-full bg-amber-500 opacity-80" />
          </div>
        </div>
      </div>

      {/* Locked Overlay */}
      {isLocked && (
        <div className="absolute inset-0 bg-slate-900/60 backdrop-blur-[2px] flex items-center justify-center">
          <div className="flex flex-col items-center gap-2 text-white">
            <div className="w-16 h-16 rounded-full bg-red-500/20 border-2 border-red-500/50 flex items-center justify-center">
              <Lock className="w-8 h-8 text-red-400" />
            </div>
            <span className="text-sm font-medium text-red-300">Card Frozen</span>
          </div>
        </div>
      )}
    </div>
  );
}
