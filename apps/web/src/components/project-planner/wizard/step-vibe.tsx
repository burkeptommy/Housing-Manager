'use client';

import type { ProjectTemplate } from '@haven/core';

// Style options with visual descriptions
const STYLE_OPTIONS = [
  {
    id: 'modern',
    name: 'Modern',
    description: 'Clean lines, minimalist, contemporary',
    colors: ['#1a1a1a', '#ffffff', '#666666'],
  },
  {
    id: 'traditional',
    name: 'Traditional',
    description: 'Classic, timeless, elegant details',
    colors: ['#8B4513', '#F5F5DC', '#D4AF37'],
  },
  {
    id: 'rustic',
    name: 'Rustic',
    description: 'Natural materials, warm, cozy',
    colors: ['#8B4513', '#228B22', '#D2691E'],
  },
  {
    id: 'industrial',
    name: 'Industrial',
    description: 'Raw, exposed elements, urban loft',
    colors: ['#2F4F4F', '#708090', '#CD7F32'],
  },
  {
    id: 'coastal',
    name: 'Coastal',
    description: 'Beach-inspired, light, airy',
    colors: ['#4682B4', '#F5F5DC', '#87CEEB'],
  },
  {
    id: 'farmhouse',
    name: 'Farmhouse',
    description: 'Country charm, comfortable, welcoming',
    colors: ['#FFFFFF', '#8B4513', '#F5F5DC'],
  },
  {
    id: 'mid_century',
    name: 'Mid-Century Modern',
    description: 'Retro 50s-60s, bold shapes, organic',
    colors: ['#FF6B35', '#004E89', '#F5E663'],
  },
  {
    id: 'contemporary',
    name: 'Contemporary',
    description: 'Current trends, eclectic, bold',
    colors: ['#2C3E50', '#E74C3C', '#ECF0F1'],
  },
  {
    id: 'minimalist',
    name: 'Minimalist',
    description: 'Less is more, functional, serene',
    colors: ['#FFFFFF', '#000000', '#808080'],
  },
  {
    id: 'not_sure',
    name: 'Not Sure Yet',
    description: "I'm open to suggestions",
    colors: ['#CBD5E1', '#94A3B8', '#64748B'],
  },
];

type StepVibeProps = {
  template: ProjectTemplate | null;
  style: string | null;
  vibeNotes: string;
  moodBoardImages: string[];
  onUpdateStyle: (style: string | null) => void;
  onUpdateVibeNotes: (vibeNotes: string) => void;
  onUpdateMoodBoardImages: (moodBoardImages: string[]) => void;
};

export default function StepVibe({
  template,
  style,
  vibeNotes,
  moodBoardImages,
  onUpdateStyle,
  onUpdateVibeNotes,
  onUpdateMoodBoardImages,
}: StepVibeProps) {
  const handleRemoveImage = (index: number) => {
    const newImages = [...moodBoardImages];
    newImages.splice(index, 1);
    onUpdateMoodBoardImages(newImages);
  };

  return (
    <div className="space-y-8">
      {/* Style Selection */}
      <div>
        <h3 className="text-lg font-medium text-slate-900 dark:text-white mb-2">
          What style speaks to you?
        </h3>
        <p className="text-sm text-slate-600 dark:text-slate-400 mb-4">
          This helps us match you with contractors who specialize in your preferred aesthetic.
        </p>
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3">
          {STYLE_OPTIONS.map((option) => {
            const isSelected = style === option.id;
            return (
              <button
                key={option.id}
                onClick={() => onUpdateStyle(option.id)}
                className={`p-4 rounded-xl border-2 text-left transition-all hover:scale-[1.02] ${
                  isSelected
                    ? 'border-emerald-500 bg-emerald-50 dark:bg-emerald-900/20'
                    : 'border-slate-200 dark:border-slate-700 hover:border-emerald-300 dark:hover:border-emerald-700'
                }`}
              >
                {/* Color palette preview */}
                <div className="flex gap-1 mb-3">
                  {option.colors.map((color, i) => (
                    <div
                      key={i}
                      className="w-6 h-6 rounded-md border border-slate-200 dark:border-slate-600"
                      style={{ backgroundColor: color }}
                    />
                  ))}
                </div>
                <div className="font-medium text-slate-900 dark:text-white text-sm">
                  {option.name}
                </div>
                <div className="text-xs text-slate-500 dark:text-slate-400 mt-1">
                  {option.description}
                </div>
              </button>
            );
          })}
        </div>
      </div>

      {/* Inspiration Images */}
      <div>
        <h3 className="text-lg font-medium text-slate-900 dark:text-white mb-2">
          Inspiration Board (optional)
        </h3>
        <p className="text-sm text-slate-600 dark:text-slate-400 mb-4">
          Add image URLs from Pinterest, Houzz, or anywhere you find inspiration.
        </p>

        {/* Display existing images */}
        {moodBoardImages.length > 0 && (
          <div className="grid grid-cols-3 md:grid-cols-4 gap-3 mb-4">
            {moodBoardImages.map((imageUrl, index) => (
              <div
                key={index}
                className="relative group aspect-square rounded-lg overflow-hidden bg-slate-100 dark:bg-slate-800"
              >
                <img
                  src={imageUrl}
                  alt={`Inspiration ${index + 1}`}
                  className="w-full h-full object-cover"
                  onError={(e) => {
                    // Replace with placeholder on error
                    (e.target as HTMLImageElement).src = 'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="100" height="100"%3E%3Crect fill="%23e2e8f0" width="100" height="100"/%3E%3Ctext fill="%2394a3b8" font-family="sans-serif" font-size="12" x="50%25" y="50%25" text-anchor="middle" dy=".3em"%3EImage%3C/text%3E%3C/svg%3E';
                  }}
                />
                <button
                  onClick={() => handleRemoveImage(index)}
                  className="absolute top-2 right-2 w-6 h-6 rounded-full bg-red-500 text-white opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center"
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
            ))}
          </div>
        )}

        {/* Add image URL input */}
        <div className="flex gap-2">
          <input
            type="url"
            placeholder="Paste an image URL..."
            className="input flex-1"
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                const input = e.target as HTMLInputElement;
                const url = input.value.trim();
                if (url && !moodBoardImages.includes(url)) {
                  onUpdateMoodBoardImages([...moodBoardImages, url]);
                  input.value = '';
                }
              }
            }}
          />
          <button
            type="button"
            onClick={(e) => {
              const input = (e.target as HTMLButtonElement).previousElementSibling as HTMLInputElement;
              const url = input.value.trim();
              if (url && !moodBoardImages.includes(url)) {
                onUpdateMoodBoardImages([...moodBoardImages, url]);
                input.value = '';
              }
            }}
            className="btn btn-secondary"
          >
            Add
          </button>
        </div>
        <p className="text-xs text-slate-500 dark:text-slate-400 mt-2">
          Press Enter or click Add to save the image URL
        </p>
      </div>

      {/* Vibe Notes */}
      <div>
        <h3 className="text-lg font-medium text-slate-900 dark:text-white mb-2">
          Describe the vibe
        </h3>
        <p className="text-sm text-slate-600 dark:text-slate-400 mb-4">
          What feeling do you want when you walk into this space?
        </p>
        <textarea
          value={vibeNotes}
          onChange={(e) => onUpdateVibeNotes(e.target.value)}
          className="input min-h-[120px]"
          placeholder="Examples: 'Bright and airy with natural light', 'Cozy retreat for relaxation', 'Sleek and functional workspace'..."
        />
      </div>

      {/* Template inspiration images */}
      {template?.inspirationImages && template.inspirationImages.length > 0 && (
        <div>
          <h3 className="text-lg font-medium text-slate-900 dark:text-white mb-2">
            Project Inspiration
          </h3>
          <p className="text-sm text-slate-600 dark:text-slate-400 mb-4">
            Here are some examples of similar projects
          </p>
          <div className="grid grid-cols-3 gap-3">
            {template.inspirationImages.slice(0, 6).map((imageUrl, index) => (
              <div
                key={index}
                className="aspect-video rounded-lg overflow-hidden bg-slate-100 dark:bg-slate-800"
              >
                <img
                  src={imageUrl}
                  alt={`Inspiration ${index + 1}`}
                  className="w-full h-full object-cover"
                />
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
