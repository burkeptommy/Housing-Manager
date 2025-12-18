'use client';

const URGENCY_OPTIONS = [
  {
    id: 'no_rush',
    name: 'No Rush',
    description: 'Just exploring, no specific timeline',
    icon: '🌿',
    color: 'bg-green-100 dark:bg-green-900/20 border-green-300 dark:border-green-700',
  },
  {
    id: 'sometime_this_year',
    name: 'Sometime This Year',
    description: 'Planning ahead, flexible on exact timing',
    icon: '📅',
    color: 'bg-emerald-100 dark:bg-emerald-900/20 border-emerald-300 dark:border-emerald-700',
  },
  {
    id: 'next_few_months',
    name: 'Next Few Months',
    description: 'Ready to start planning seriously',
    icon: '⏰',
    color: 'bg-yellow-100 dark:bg-yellow-900/20 border-yellow-300 dark:border-yellow-700',
  },
  {
    id: 'asap',
    name: 'ASAP',
    description: 'Need to get this done quickly',
    icon: '🚀',
    color: 'bg-red-100 dark:bg-red-900/20 border-red-300 dark:border-red-700',
  },
];

type StepTimelineProps = {
  urgency: string | null;
  targetStartDate: string | null;
  targetCompletionDate: string | null;
  onUpdateUrgency: (urgency: string | null) => void;
  onUpdateTargetStartDate: (date: string | null) => void;
  onUpdateTargetCompletionDate: (date: string | null) => void;
};

export default function StepTimeline({
  urgency,
  targetStartDate,
  targetCompletionDate,
  onUpdateUrgency,
  onUpdateTargetStartDate,
  onUpdateTargetCompletionDate,
}: StepTimelineProps) {
  // Get today's date in YYYY-MM-DD format
  const today = new Date().toISOString().split('T')[0];

  return (
    <div className="space-y-8">
      {/* Urgency Selection */}
      <div>
        <h3 className="text-lg font-medium text-slate-900 dark:text-white mb-2">
          How soon are you thinking?
        </h3>
        <p className="text-sm text-slate-600 dark:text-slate-400 mb-4">
          No pressure - it&apos;s totally fine to just be dreaming. We won&apos;t send any vendors your way until you&apos;re ready.
        </p>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {URGENCY_OPTIONS.map((option) => {
            const isSelected = urgency === option.id;
            return (
              <button
                key={option.id}
                onClick={() => onUpdateUrgency(option.id)}
                className={`p-4 rounded-xl border-2 text-left transition-all hover:scale-[1.01] ${
                  isSelected
                    ? `${option.color} border-2`
                    : 'border-slate-200 dark:border-slate-700 hover:border-emerald-300 dark:hover:border-emerald-700'
                }`}
              >
                <div className="flex items-start gap-3">
                  <div className="text-2xl">{option.icon}</div>
                  <div className="flex-1">
                    <div className="font-medium text-slate-900 dark:text-white">
                      {option.name}
                    </div>
                    <div className="text-sm text-slate-600 dark:text-slate-400 mt-1">
                      {option.description}
                    </div>
                  </div>
                  {isSelected && (
                    <svg
                      className="w-5 h-5 text-emerald-500 flex-shrink-0"
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

      {/* Target Dates (only show if not "no rush") */}
      {urgency && urgency !== 'no_rush' && (
        <div className="pt-6 border-t border-slate-200 dark:border-slate-700">
          <h3 className="text-lg font-medium text-slate-900 dark:text-white mb-2">
            Target dates (optional)
          </h3>
          <p className="text-sm text-slate-600 dark:text-slate-400 mb-4">
            These are just goals to help you plan. You can always adjust later.
          </p>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Start Date */}
            <div>
              <label htmlFor="startDate" className="label block mb-2">
                Target Start Date
              </label>
              <input
                id="startDate"
                type="date"
                value={targetStartDate || ''}
                onChange={(e) => onUpdateTargetStartDate(e.target.value || null)}
                min={today}
                className="input"
              />
              <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
                When would you ideally like work to begin?
              </p>
            </div>

            {/* Completion Date */}
            <div>
              <label htmlFor="completionDate" className="label block mb-2">
                Target Completion Date
              </label>
              <input
                id="completionDate"
                type="date"
                value={targetCompletionDate || ''}
                onChange={(e) => onUpdateTargetCompletionDate(e.target.value || null)}
                min={targetStartDate || today}
                className="input"
              />
              <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
                Any deadline you&apos;re working towards?
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Helpful tip */}
      <div className="p-4 rounded-xl bg-emerald-50 dark:bg-emerald-900/20 border border-emerald-200 dark:border-emerald-800">
        <div className="flex gap-3">
          <svg
            className="w-5 h-5 text-emerald-500 flex-shrink-0 mt-0.5"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
          <div>
            <div className="font-medium text-emerald-900 dark:text-emerald-100 text-sm">
              Your information stays private
            </div>
            <div className="text-sm text-emerald-700 dark:text-emerald-300 mt-1">
              We never share your project details with vendors until you explicitly ask for recommendations.
              Dream all you want - no spam, no sales calls.
            </div>
          </div>
        </div>
      </div>

      {/* Season considerations */}
      {urgency && urgency !== 'no_rush' && (
        <div className="p-4 rounded-xl bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800">
          <div className="flex gap-3">
            <span className="text-lg">💡</span>
            <div>
              <div className="font-medium text-amber-900 dark:text-amber-100 text-sm">
                Seasonal Tip
              </div>
              <div className="text-sm text-amber-700 dark:text-amber-300 mt-1">
                Many contractors book up quickly in spring and summer. If you&apos;re planning an outdoor project,
                consider reaching out in late winter for the best availability and pricing.
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
