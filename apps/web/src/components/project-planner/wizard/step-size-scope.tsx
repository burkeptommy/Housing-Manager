'use client';

import { useState } from 'react';
import type { ProjectTemplate } from '@haven/core';

// Common complexity factors
const COMPLEXITY_OPTIONS = [
  { id: 'permits_required', label: 'Permits Required', description: 'Local permits will be needed' },
  { id: 'structural', label: 'Structural Work', description: 'Load-bearing walls or foundation' },
  { id: 'plumbing', label: 'Plumbing Changes', description: 'Moving or adding water lines' },
  { id: 'electrical', label: 'Electrical Updates', description: 'Panel upgrade or new circuits' },
  { id: 'multi_level', label: 'Multi-Level', description: 'Work on multiple floors/levels' },
  { id: 'custom_design', label: 'Custom Design', description: 'Unique or custom elements' },
  { id: 'high_end', label: 'High-End Materials', description: 'Premium fixtures and finishes' },
  { id: 'difficult_access', label: 'Difficult Access', description: 'Hard to reach areas' },
];

type StepSizeScopeProps = {
  template: ProjectTemplate | null;
  specs: {
    sqFt: number;
    complexity: string[];
  };
  title: string;
  description: string;
  onUpdateSpecs: (specs: { sqFt: number; complexity: string[] }) => void;
  onUpdateTitle: (title: string) => void;
  onUpdateDescription: (description: string) => void;
};

export default function StepSizeScope({
  template,
  specs,
  title,
  description,
  onUpdateSpecs,
  onUpdateTitle,
  onUpdateDescription,
}: StepSizeScopeProps) {
  const [showAllComplexity, setShowAllComplexity] = useState(false);

  const minSqFt = template?.minSqFt || 50;
  const maxSqFt = template?.maxSqFt || 5000;

  const handleSqFtChange = (value: number) => {
    onUpdateSpecs({ ...specs, sqFt: Math.max(minSqFt, Math.min(maxSqFt, value)) });
  };

  const toggleComplexity = (id: string) => {
    const newComplexity = specs.complexity.includes(id)
      ? specs.complexity.filter((c) => c !== id)
      : [...specs.complexity, id];
    onUpdateSpecs({ ...specs, complexity: newComplexity });
  };

  const displayedComplexityOptions = showAllComplexity
    ? COMPLEXITY_OPTIONS
    : COMPLEXITY_OPTIONS.slice(0, 4);

  return (
    <div className="space-y-8">
      {/* Project Title */}
      <div>
        <label htmlFor="title" className="label block mb-2">
          Project Name
        </label>
        <input
          id="title"
          type="text"
          value={title}
          onChange={(e) => onUpdateTitle(e.target.value)}
          className="input"
          placeholder="e.g., Master Bathroom Renovation"
        />
        <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
          Give your dream a name to remember it by
        </p>
      </div>

      {/* Square Footage */}
      <div>
        <label className="label block mb-2">
          Size (Square Feet)
        </label>
        <div className="flex items-center gap-4">
          <input
            type="range"
            min={minSqFt}
            max={maxSqFt}
            step={10}
            value={specs.sqFt}
            onChange={(e) => handleSqFtChange(Number(e.target.value))}
            className="flex-1 h-2 bg-slate-200 dark:bg-slate-700 rounded-lg appearance-none cursor-pointer accent-emerald-600"
          />
          <div className="flex items-center gap-2">
            <input
              type="number"
              value={specs.sqFt}
              onChange={(e) => handleSqFtChange(Number(e.target.value))}
              className="input w-24 text-center"
              min={minSqFt}
              max={maxSqFt}
            />
            <span className="text-slate-600 dark:text-slate-400">sq ft</span>
          </div>
        </div>
        {template && (
          <div className="flex justify-between text-xs text-slate-500 dark:text-slate-400 mt-2">
            <span>{minSqFt} sq ft</span>
            <span>Typical: {Math.round((minSqFt + maxSqFt) / 2)} sq ft</span>
            <span>{maxSqFt} sq ft</span>
          </div>
        )}
      </div>

      {/* Quick size presets */}
      <div className="flex flex-wrap gap-2">
        {[
          { label: 'Small', sqFt: Math.round(minSqFt + (maxSqFt - minSqFt) * 0.2) },
          { label: 'Medium', sqFt: Math.round((minSqFt + maxSqFt) / 2) },
          { label: 'Large', sqFt: Math.round(minSqFt + (maxSqFt - minSqFt) * 0.8) },
        ].map((preset) => (
          <button
            key={preset.label}
            onClick={() => handleSqFtChange(preset.sqFt)}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              specs.sqFt === preset.sqFt
                ? 'bg-emerald-600 text-white'
                : 'bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-700'
            }`}
          >
            {preset.label} (~{preset.sqFt} sq ft)
          </button>
        ))}
      </div>

      {/* Complexity Factors */}
      <div>
        <label className="label block mb-2">
          Complexity Factors
        </label>
        <p className="text-sm text-slate-600 dark:text-slate-400 mb-4">
          Select any factors that apply to your project. These help us give you a more accurate estimate.
        </p>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          {displayedComplexityOptions.map((option) => {
            const isSelected = specs.complexity.includes(option.id);
            return (
              <button
                key={option.id}
                onClick={() => toggleComplexity(option.id)}
                className={`p-3 rounded-xl border-2 text-left transition-all ${
                  isSelected
                    ? 'border-emerald-500 bg-emerald-50 dark:bg-emerald-900/20'
                    : 'border-slate-200 dark:border-slate-700 hover:border-emerald-300 dark:hover:border-emerald-700'
                }`}
              >
                <div className="flex items-start gap-3">
                  <div
                    className={`w-5 h-5 rounded-md flex items-center justify-center flex-shrink-0 mt-0.5 ${
                      isSelected
                        ? 'bg-emerald-600 text-white'
                        : 'bg-slate-200 dark:bg-slate-700'
                    }`}
                  >
                    {isSelected && (
                      <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                      </svg>
                    )}
                  </div>
                  <div>
                    <div className="font-medium text-slate-900 dark:text-white text-sm">
                      {option.label}
                    </div>
                    <div className="text-xs text-slate-500 dark:text-slate-400">
                      {option.description}
                    </div>
                  </div>
                </div>
              </button>
            );
          })}
        </div>
        {!showAllComplexity && COMPLEXITY_OPTIONS.length > 4 && (
          <button
            onClick={() => setShowAllComplexity(true)}
            className="mt-3 text-sm text-emerald-600 dark:text-emerald-400 hover:underline"
          >
            Show {COMPLEXITY_OPTIONS.length - 4} more options
          </button>
        )}
      </div>

      {/* Description */}
      <div>
        <label htmlFor="description" className="label block mb-2">
          Additional Details (optional)
        </label>
        <textarea
          id="description"
          value={description}
          onChange={(e) => onUpdateDescription(e.target.value)}
          className="input min-h-[100px]"
          placeholder="Tell us more about what you're envisioning..."
        />
      </div>
    </div>
  );
}
