'use client';

import type { ProjectCategory, ProjectTemplate } from '@haven/core';

// Category display configuration
const CATEGORY_CONFIG: Record<ProjectCategory, { name: string; icon: string; description: string }> = {
  BATHROOM_REMODEL: {
    name: 'Bathroom Remodel',
    icon: '🚿',
    description: 'Upgrade your bathroom with new fixtures, tile, and finishes',
  },
  KITCHEN_REMODEL: {
    name: 'Kitchen Remodel',
    icon: '🍳',
    description: 'Transform your kitchen with new cabinets, counters, and appliances',
  },
  DECK_PATIO: {
    name: 'Deck & Patio',
    icon: '🏡',
    description: 'Create outdoor living space for entertaining and relaxing',
  },
  LANDSCAPING: {
    name: 'Landscaping',
    icon: '🌳',
    description: 'Design and install gardens, lawns, and outdoor features',
  },
  ROOF: {
    name: 'Roof',
    icon: '🏠',
    description: 'Repair or replace your roof for better protection',
  },
  WINDOWS_DOORS: {
    name: 'Windows & Doors',
    icon: '🪟',
    description: 'Upgrade windows and doors for efficiency and style',
  },
  FLOORING: {
    name: 'Flooring',
    icon: '🪵',
    description: 'Install new hardwood, tile, carpet, or luxury vinyl',
  },
  PAINTING: {
    name: 'Painting',
    icon: '🎨',
    description: 'Interior or exterior painting to refresh your space',
  },
  HVAC: {
    name: 'HVAC',
    icon: '❄️',
    description: 'Heating, cooling, and ventilation system upgrades',
  },
  ELECTRICAL: {
    name: 'Electrical',
    icon: '⚡',
    description: 'Electrical updates, panel upgrades, or new wiring',
  },
  PLUMBING: {
    name: 'Plumbing',
    icon: '🔧',
    description: 'Plumbing repairs, pipe replacement, or fixture updates',
  },
  ADDITION: {
    name: 'Addition',
    icon: '🏗️',
    description: 'Add square footage with a room or home addition',
  },
  BASEMENT: {
    name: 'Basement',
    icon: '🏚️',
    description: 'Finish or renovate your basement living space',
  },
  GARAGE: {
    name: 'Garage',
    icon: '🚗',
    description: 'Build a new garage or upgrade your existing one',
  },
  FENCE: {
    name: 'Fence',
    icon: '🏘️',
    description: 'Install privacy fencing, decorative fencing, or gates',
  },
  POOL: {
    name: 'Pool',
    icon: '🏊',
    description: 'Install an in-ground or above-ground pool',
  },
  SOLAR: {
    name: 'Solar',
    icon: '☀️',
    description: 'Solar panel installation for energy independence',
  },
  SMART_HOME: {
    name: 'Smart Home',
    icon: '🏠',
    description: 'Automation, security systems, and smart devices',
  },
  EXTERIOR_SIDING: {
    name: 'Exterior Siding',
    icon: '🧱',
    description: 'Replace or repair exterior siding and trim',
  },
  OTHER: {
    name: 'Other',
    icon: '🛠️',
    description: 'Custom project not listed above',
  },
};

// Popular categories shown first
const POPULAR_CATEGORIES: ProjectCategory[] = [
  'KITCHEN_REMODEL',
  'BATHROOM_REMODEL',
  'DECK_PATIO',
  'FLOORING',
  'PAINTING',
  'LANDSCAPING',
];

type StepCategoryProps = {
  templates: ProjectTemplate[];
  selectedCategory: ProjectCategory | null;
  selectedTemplateId: string | null;
  onSelectCategory: (category: ProjectCategory) => void;
  onSelectTemplate: (templateId: string) => void;
};

export default function StepCategory({
  templates,
  selectedCategory,
  selectedTemplateId,
  onSelectCategory,
  onSelectTemplate,
}: StepCategoryProps) {
  // Group templates by category
  const templatesByCategory = templates.reduce((acc, template) => {
    if (!acc[template.category]) {
      acc[template.category] = [];
    }
    acc[template.category].push(template);
    return acc;
  }, {} as Record<string, ProjectTemplate[]>);

  // Get all categories that have templates
  const categoriesWithTemplates = Object.keys(templatesByCategory) as ProjectCategory[];

  // Sort categories: popular first, then alphabetically
  const sortedCategories = [
    ...POPULAR_CATEGORIES.filter((c) => categoriesWithTemplates.includes(c)),
    ...categoriesWithTemplates
      .filter((c) => !POPULAR_CATEGORIES.includes(c))
      .sort((a, b) => (CATEGORY_CONFIG[a]?.name || a).localeCompare(CATEGORY_CONFIG[b]?.name || b)),
  ];

  const templatesForSelected = selectedCategory ? templatesByCategory[selectedCategory] || [] : [];

  return (
    <div className="space-y-6">
      {/* Category selection */}
      <div>
        <h3 className="text-lg font-medium text-slate-900 dark:text-white mb-4">
          Choose your project type
        </h3>
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
          {sortedCategories.map((category) => {
            const config = CATEGORY_CONFIG[category];
            const isSelected = selectedCategory === category;
            return (
              <button
                key={category}
                onClick={() => onSelectCategory(category)}
                className={`p-4 rounded-xl border-2 text-left transition-all hover:scale-[1.02] ${
                  isSelected
                    ? 'border-emerald-500 bg-emerald-50 dark:bg-emerald-900/20'
                    : 'border-slate-200 dark:border-slate-700 hover:border-emerald-300 dark:hover:border-emerald-700'
                }`}
              >
                <div className="text-2xl mb-2">{config?.icon || '🛠️'}</div>
                <div className="font-medium text-slate-900 dark:text-white text-sm">
                  {config?.name || category.replace(/_/g, ' ')}
                </div>
              </button>
            );
          })}
        </div>
      </div>

      {/* Template selection (if category is selected) */}
      {selectedCategory && templatesForSelected.length > 0 && (
        <div className="pt-6 border-t border-slate-200 dark:border-slate-700">
          <h3 className="text-lg font-medium text-slate-900 dark:text-white mb-4">
            Choose a project template
          </h3>
          <p className="text-sm text-slate-600 dark:text-slate-400 mb-4">
            Templates help us give you more accurate estimates based on typical project specs.
          </p>
          <div className="space-y-3">
            {templatesForSelected.map((template) => {
              const isSelected = selectedTemplateId === template.id;
              return (
                <button
                  key={template.id}
                  onClick={() => onSelectTemplate(template.id)}
                  className={`w-full p-4 rounded-xl border-2 text-left transition-all hover:scale-[1.01] ${
                    isSelected
                      ? 'border-emerald-500 bg-emerald-50 dark:bg-emerald-900/20'
                      : 'border-slate-200 dark:border-slate-700 hover:border-emerald-300 dark:hover:border-emerald-700'
                  }`}
                >
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="font-medium text-slate-900 dark:text-white">
                        {template.name}
                      </div>
                      {template.description && (
                        <p className="text-sm text-slate-600 dark:text-slate-400 mt-1">
                          {template.description}
                        </p>
                      )}
                      <div className="flex flex-wrap gap-3 mt-2 text-xs text-slate-500 dark:text-slate-400">
                        {template.minSqFt && template.maxSqFt && (
                          <span>
                            {template.minSqFt} - {template.maxSqFt} sq ft
                          </span>
                        )}
                        {template.estimatedDaysMin && template.estimatedDaysMax && (
                          <span>
                            {template.estimatedDaysMin} - {template.estimatedDaysMax} days
                          </span>
                        )}
                      </div>
                    </div>
                    {isSelected && (
                      <svg
                        className="w-5 h-5 text-emerald-500 flex-shrink-0 ml-3"
                        fill="currentColor"
                        viewBox="0 0 20 20"
                      >
                        <path
                          fillRule="evenodd"
                          d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                          clipRule="evenodd"
                        />
                      </svg>
                    )}
                  </div>
                </button>
              );
            })}
          </div>
        </div>
      )}

      {/* No template needed option */}
      {selectedCategory && (
        <div className="text-center">
          <button
            onClick={() => onSelectTemplate('')}
            className="text-sm text-slate-500 dark:text-slate-400 hover:text-emerald-600 dark:hover:text-emerald-400"
          >
            Skip template - I&apos;ll describe it myself
          </button>
        </div>
      )}
    </div>
  );
}
