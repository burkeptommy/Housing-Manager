'use client';

import { useState, useRef, useEffect, useCallback, useMemo } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { getApiClient } from '@/lib/api';
import { useAuth } from '@/contexts/auth-context';
import {
  Plus,
  Hammer,
  Lightbulb,
  Calendar,
  DollarSign,
  Clock,
  CheckCircle2,
  Circle,
  Camera,
  Link as LinkIcon,
  Star,
  Shield,
  GripVertical,
  MoreVertical,
  ArrowRight,
  ArrowLeft,
  Sparkles,
  TrendingUp,
  CheckCircle,
  FileText,
  Receipt,
  Layers,
  Wrench,
  ImagePlus,
  Heart,
  Share2,
  Play,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

type ViewMode = 'active' | 'wishlist';
type ProjectTab = 'inspiration' | 'plan' | 'financials';
type TaskStatus = 'todo' | 'scheduled' | 'in_progress' | 'done';

interface InspirationImage {
  id: string;
  url: string;
  source?: string;
  sourceUrl?: string;
  caption?: string;
  aspectRatio: 'portrait' | 'landscape' | 'square';
}

interface ProjectTask {
  id: string;
  title: string;
  description?: string;
  status: TaskStatus;
  assignee?: string;
  dueDate?: string;
  estimatedCost?: number;
  recommendedVendor?: Vendor;
}

interface Vendor {
  id: string;
  name: string;
  trade: string;
  rating: number;
  reviewCount: number;
  verified: boolean;
  responseTime: string;
  friendsUsed?: string[];
}

interface Expense {
  id: string;
  description: string;
  category: 'materials' | 'labor' | 'permits' | 'other';
  estimatedAmount: number;
  actualAmount?: number;
  date?: string;
  vendor?: string;
  paid: boolean;
}

interface Project {
  id: string;
  title: string;
  description: string;
  category: string;
  coverImage: string;
  status: 'active' | 'wishlist' | 'completed';
  progress: number;
  estimatedBudget: number;
  actualSpend: number;
  dueDate?: string;
  startDate?: string;
  inspiration: InspirationImage[];
  tasks: ProjectTask[];
  expenses: Expense[];
  beforeImage?: string;
  afterImage?: string;
  suggestedItems?: string[];
}

// ============================================================================
// MOCK DATA (Fallback when API is unavailable)
// ============================================================================

const MOCK_VENDORS: Vendor[] = [
  {
    id: 'v1',
    name: 'Tile Masters Pro',
    trade: 'Tile Installation',
    rating: 4.9,
    reviewCount: 127,
    verified: true,
    responseTime: '2 hours',
    friendsUsed: ['Alice C.', 'Bob M.'],
  },
  {
    id: 'v2',
    name: 'Premier Plumbing',
    trade: 'Plumbing',
    rating: 4.8,
    reviewCount: 89,
    verified: true,
    responseTime: '1 hour',
    friendsUsed: ['Sarah K.'],
  },
  {
    id: 'v3',
    name: 'Elite Electricians',
    trade: 'Electrical',
    rating: 4.7,
    reviewCount: 156,
    verified: true,
    responseTime: '3 hours',
  },
];

const MOCK_PROJECTS: Project[] = [
  {
    id: 'p1',
    title: 'Kitchen Backsplash Upgrade',
    description: 'Modern subway tile backsplash with accent patterns',
    category: 'Kitchen',
    coverImage: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=800',
    status: 'active',
    progress: 65,
    estimatedBudget: 4500,
    actualSpend: 2800,
    dueDate: '2024-12-15',
    startDate: '2024-11-01',
    beforeImage: 'https://images.unsplash.com/photo-1556909172-8c2f041fca1e?w=400',
    afterImage: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400',
    inspiration: [
      { id: 'i1', url: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400', source: 'Pinterest', aspectRatio: 'portrait' },
      { id: 'i2', url: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=400', source: 'Houzz', aspectRatio: 'landscape' },
      { id: 'i3', url: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=400', aspectRatio: 'square' },
      { id: 'i4', url: 'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=400', source: 'Pinterest', aspectRatio: 'portrait' },
      { id: 'i5', url: 'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?w=400', aspectRatio: 'landscape' },
    ],
    tasks: [
      { id: 't1', title: 'Remove old backsplash', status: 'done', estimatedCost: 200 },
      { id: 't2', title: 'Prep wall surface', status: 'done', estimatedCost: 150 },
      { id: 't3', title: 'Install tile', status: 'in_progress', assignee: 'Tile Masters Pro', dueDate: '2024-12-01', estimatedCost: 2500, recommendedVendor: MOCK_VENDORS[0] },
      { id: 't4', title: 'Grout and seal', status: 'scheduled', dueDate: '2024-12-08', estimatedCost: 300, recommendedVendor: MOCK_VENDORS[0] },
      { id: 't5', title: 'Install outlet covers', status: 'todo', estimatedCost: 50 },
    ],
    expenses: [
      { id: 'e1', description: 'Subway tiles (200 sq ft)', category: 'materials', estimatedAmount: 1200, actualAmount: 1150, paid: true, vendor: 'Home Depot' },
      { id: 'e2', description: 'Grout and adhesive', category: 'materials', estimatedAmount: 200, actualAmount: 185, paid: true },
      { id: 'e3', description: 'Demo labor', category: 'labor', estimatedAmount: 400, actualAmount: 400, paid: true, vendor: 'Tile Masters Pro' },
      { id: 'e4', description: 'Installation labor', category: 'labor', estimatedAmount: 2000, actualAmount: 1065, paid: false, vendor: 'Tile Masters Pro' },
      { id: 'e5', description: 'Permit fee', category: 'permits', estimatedAmount: 150, actualAmount: 0, paid: false },
    ],
    suggestedItems: ['Under-cabinet lighting', 'Pot filler faucet', 'Appliance garage', 'Open shelving'],
  },
  {
    id: 'p2',
    title: 'Master Bath Renovation',
    description: 'Complete bathroom overhaul with walk-in shower',
    category: 'Bathroom',
    coverImage: 'https://images.unsplash.com/photo-1552321554-5fefe8c9ef14?w=800',
    status: 'active',
    progress: 25,
    estimatedBudget: 18000,
    actualSpend: 3500,
    dueDate: '2025-02-28',
    startDate: '2024-12-01',
    inspiration: [
      { id: 'i1', url: 'https://images.unsplash.com/photo-1552321554-5fefe8c9ef14?w=400', aspectRatio: 'portrait' },
      { id: 'i2', url: 'https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?w=400', aspectRatio: 'landscape' },
    ],
    tasks: [
      { id: 't1', title: 'Design finalization', status: 'done', estimatedCost: 500 },
      { id: 't2', title: 'Demolition', status: 'in_progress', estimatedCost: 1500 },
      { id: 't3', title: 'Plumbing rough-in', status: 'scheduled', estimatedCost: 3000, recommendedVendor: MOCK_VENDORS[1] },
      { id: 't4', title: 'Electrical work', status: 'todo', estimatedCost: 2000, recommendedVendor: MOCK_VENDORS[2] },
    ],
    expenses: [
      { id: 'e1', description: 'Vanity and fixtures', category: 'materials', estimatedAmount: 4500, actualAmount: 4200, paid: true },
      { id: 'e2', description: 'Demolition', category: 'labor', estimatedAmount: 1500, actualAmount: 0, paid: false },
    ],
    suggestedItems: ['Heated floors', 'Rain showerhead', 'Floating vanity'],
  },
  {
    id: 'p3',
    title: 'Deck Refinishing',
    description: 'Sand, stain, and seal the back deck',
    category: 'Outdoor',
    coverImage: 'https://images.unsplash.com/photo-1600585154526-990dced4db0d?w=800',
    status: 'active',
    progress: 90,
    estimatedBudget: 2500,
    actualSpend: 2650,
    dueDate: '2024-11-30',
    inspiration: [],
    tasks: [
      { id: 't1', title: 'Power wash deck', status: 'done', estimatedCost: 200 },
      { id: 't2', title: 'Sand surface', status: 'done', estimatedCost: 400 },
      { id: 't3', title: 'Apply stain', status: 'done', estimatedCost: 800 },
      { id: 't4', title: 'Final seal coat', status: 'in_progress', estimatedCost: 600 },
    ],
    expenses: [
      { id: 'e1', description: 'Deck stain (5 gal)', category: 'materials', estimatedAmount: 350, actualAmount: 380, paid: true },
      { id: 'e2', description: 'Sealant', category: 'materials', estimatedAmount: 200, actualAmount: 220, paid: true },
      { id: 'e3', description: 'Labor - staining', category: 'labor', estimatedAmount: 1500, actualAmount: 1600, paid: true },
    ],
    suggestedItems: [],
  },
  {
    id: 'p4',
    title: 'Outdoor Kitchen',
    description: 'Built-in grill, sink, and bar area',
    category: 'Outdoor',
    coverImage: 'https://images.unsplash.com/photo-1600566752355-35792bedcfea?w=800',
    status: 'wishlist',
    progress: 0,
    estimatedBudget: 25000,
    actualSpend: 0,
    inspiration: [
      { id: 'i1', url: 'https://images.unsplash.com/photo-1600566752355-35792bedcfea?w=400', aspectRatio: 'landscape' },
      { id: 'i2', url: 'https://images.unsplash.com/photo-1600210491892-03d54c0aaf87?w=400', aspectRatio: 'portrait' },
    ],
    tasks: [],
    expenses: [],
    suggestedItems: ['Pizza oven', 'Bar seating', 'Outdoor refrigerator'],
  },
  {
    id: 'p5',
    title: 'Home Office Upgrade',
    description: 'Built-in desk and shelving system',
    category: 'Interior',
    coverImage: 'https://images.unsplash.com/photo-1600494603989-9650cf6dad51?w=800',
    status: 'wishlist',
    progress: 0,
    estimatedBudget: 8000,
    actualSpend: 0,
    inspiration: [
      { id: 'i1', url: 'https://images.unsplash.com/photo-1600494603989-9650cf6dad51?w=400', aspectRatio: 'landscape' },
    ],
    tasks: [],
    expenses: [],
    suggestedItems: ['Cable management', 'Task lighting', 'Acoustic panels'],
  },
  {
    id: 'p6',
    title: 'Smart Home Integration',
    description: 'Whole-home automation with lighting, climate, and security',
    category: 'Technology',
    coverImage: 'https://images.unsplash.com/photo-1558002038-1055907df827?w=800',
    status: 'wishlist',
    progress: 0,
    estimatedBudget: 12000,
    actualSpend: 0,
    inspiration: [],
    tasks: [],
    expenses: [],
    suggestedItems: ['Smart thermostat', 'Automated blinds', 'Voice assistants'],
  },
];

// ============================================================================
// API-TO-UI MAPPING FUNCTIONS
// ============================================================================

// Default cover images by category for projects without images
const CATEGORY_IMAGES: Record<string, string> = {
  kitchen: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=800',
  bathroom: 'https://images.unsplash.com/photo-1552321554-5fefe8c9ef14?w=800',
  outdoor: 'https://images.unsplash.com/photo-1600585154526-990dced4db0d?w=800',
  interior: 'https://images.unsplash.com/photo-1600494603989-9650cf6dad51?w=800',
  technology: 'https://images.unsplash.com/photo-1558002038-1055907df827?w=800',
};

function mapApiTaskToUi(apiTask: Record<string, unknown>): ProjectTask {
  // Normalize status - ensure it matches our TaskStatus union
  const rawStatus = String(apiTask.status || 'todo').toLowerCase().replace('-', '_');
  const validStatuses: TaskStatus[] = ['todo', 'scheduled', 'in_progress', 'done'];
  const status: TaskStatus = validStatuses.includes(rawStatus as TaskStatus)
    ? (rawStatus as TaskStatus)
    : 'todo';

  return {
    id: String(apiTask.id || `task-${Date.now()}`),
    title: String(apiTask.title || apiTask.name || 'Untitled Task'),
    description: apiTask.description ? String(apiTask.description) : undefined,
    status,
    assignee: apiTask.assignee ? String(apiTask.assignee) : undefined,
    dueDate: apiTask.dueDate ? String(apiTask.dueDate) : undefined,
    estimatedCost: apiTask.estimatedCost ? Number(apiTask.estimatedCost) : undefined,
    recommendedVendor: apiTask.recommendedVendor
      ? mapApiVendorToUi(apiTask.recommendedVendor as Record<string, unknown>)
      : undefined,
  };
}

function mapApiVendorToUi(apiVendor: Record<string, unknown>): Vendor {
  return {
    id: String(apiVendor.id || `vendor-${Date.now()}`),
    name: String(apiVendor.name || apiVendor.displayName || 'Unknown Vendor'),
    trade: String(apiVendor.trade || apiVendor.category || 'General'),
    rating: Number(apiVendor.rating || apiVendor.averageRating || 0),
    reviewCount: Number(apiVendor.reviewCount || apiVendor.totalReviews || 0),
    verified: Boolean(apiVendor.verified || apiVendor.isVerified),
    responseTime: String(apiVendor.responseTime || 'N/A'),
    friendsUsed: Array.isArray(apiVendor.friendsUsed) ? apiVendor.friendsUsed.map(String) : undefined,
  };
}

function mapApiExpenseToUi(apiExpense: Record<string, unknown>): Expense {
  const category = String(apiExpense.category || 'other').toLowerCase();
  const validCategories = ['materials', 'labor', 'permits', 'other'];

  return {
    id: String(apiExpense.id || `expense-${Date.now()}`),
    description: String(apiExpense.description || apiExpense.name || 'Expense'),
    category: validCategories.includes(category) ? category as Expense['category'] : 'other',
    estimatedAmount: Number(apiExpense.estimatedAmount || apiExpense.estimate || 0),
    actualAmount: apiExpense.actualAmount !== undefined ? Number(apiExpense.actualAmount) : undefined,
    date: apiExpense.date ? String(apiExpense.date) : undefined,
    vendor: apiExpense.vendor ? String(apiExpense.vendor) : undefined,
    paid: Boolean(apiExpense.paid || apiExpense.isPaid),
  };
}

function mapApiProjectToUi(apiProject: Record<string, unknown>): Project {
  const category = String(apiProject.category || 'Interior');
  const categoryKey = category.toLowerCase();

  // Calculate actual spend from expenses if not provided
  let actualSpend = Number(apiProject.actualSpend || 0);
  const expenses = Array.isArray(apiProject.expenses)
    ? apiProject.expenses.map((e) => mapApiExpenseToUi(e as Record<string, unknown>))
    : [];

  if (actualSpend === 0 && expenses.length > 0) {
    actualSpend = expenses.reduce((sum, exp) => sum + (exp.actualAmount || exp.estimatedAmount), 0);
  }

  // Map tasks
  const tasks = Array.isArray(apiProject.tasks)
    ? apiProject.tasks.map((t) => mapApiTaskToUi(t as Record<string, unknown>))
    : [];

  // Calculate progress if not provided
  let progress = Number(apiProject.progress || 0);
  if (progress === 0 && tasks.length > 0) {
    const doneTasks = tasks.filter((t) => t.status === 'done').length;
    progress = Math.round((doneTasks / tasks.length) * 100);
  }

  // Normalize status
  const rawStatus = String(apiProject.status || 'active').toLowerCase();
  const status: Project['status'] = rawStatus === 'wishlist' ? 'wishlist'
    : rawStatus === 'completed' ? 'completed'
    : 'active';

  // Map inspiration images
  const inspiration: InspirationImage[] = Array.isArray(apiProject.inspiration)
    ? apiProject.inspiration.map((img, idx) => ({
        id: String((img as Record<string, unknown>).id || `img-${idx}`),
        url: String((img as Record<string, unknown>).url || ''),
        source: (img as Record<string, unknown>).source ? String((img as Record<string, unknown>).source) : undefined,
        sourceUrl: (img as Record<string, unknown>).sourceUrl ? String((img as Record<string, unknown>).sourceUrl) : undefined,
        caption: (img as Record<string, unknown>).caption ? String((img as Record<string, unknown>).caption) : undefined,
        aspectRatio: ((img as Record<string, unknown>).aspectRatio as InspirationImage['aspectRatio']) || 'landscape',
      }))
    : [];

  return {
    id: String(apiProject.id || `project-${Date.now()}`),
    title: String(apiProject.title || apiProject.name || 'Untitled Project'),
    description: String(apiProject.description || ''),
    category,
    coverImage: String(apiProject.coverImage || CATEGORY_IMAGES[categoryKey] || CATEGORY_IMAGES.interior),
    status,
    progress,
    estimatedBudget: Number(apiProject.estimatedBudget || apiProject.budget || 0),
    actualSpend,
    dueDate: apiProject.dueDate ? String(apiProject.dueDate) : undefined,
    startDate: apiProject.startDate ? String(apiProject.startDate) : undefined,
    inspiration,
    tasks,
    expenses,
    beforeImage: apiProject.beforeImage ? String(apiProject.beforeImage) : undefined,
    afterImage: apiProject.afterImage ? String(apiProject.afterImage) : undefined,
    suggestedItems: Array.isArray(apiProject.suggestedItems)
      ? apiProject.suggestedItems.map(String)
      : undefined,
  };
}

// Mapping functions are available for use within this file
// To use elsewhere, they would need to be moved to a separate module

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    maximumFractionDigits: 0,
  }).format(amount);
}

function formatDate(dateString: string): string {
  const date = new Date(dateString);
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

function getDaysUntil(dateString: string): number {
  const now = new Date();
  const target = new Date(dateString);
  const diffTime = target.getTime() - now.getTime();
  return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
}

function getBudgetStatus(estimated: number, actual: number): 'under' | 'on-track' | 'over' {
  const percentage = (actual / estimated) * 100;
  if (percentage > 100) return 'over';
  if (percentage > 85) return 'on-track';
  return 'under';
}

function getProgressColor(progress: number): string {
  if (progress >= 100) return 'stroke-emerald-500';
  if (progress >= 50) return 'stroke-emerald-500';
  return 'stroke-emerald-500';
}

function getBurnDownColor(percentage: number): string {
  if (percentage > 100) return 'bg-gradient-to-r from-red-400 to-red-600';
  if (percentage > 80) return 'bg-gradient-to-r from-amber-400 to-amber-600';
  return 'bg-gradient-to-r from-emerald-400 to-emerald-600';
}

// ============================================================================
// COMPONENTS
// ============================================================================

// Confetti Animation Component
function Confetti({ active }: { active: boolean }) {
  if (!active) return null;

  return (
    <div className="fixed inset-0 pointer-events-none z-50">
      {[...Array(50)].map((_, i) => (
        <div
          key={i}
          className="absolute animate-confetti"
          style={{
            left: `${Math.random() * 100}%`,
            top: '-10px',
            animationDelay: `${Math.random() * 2}s`,
            backgroundColor: ['#10b981', '#f59e0b', '#3b82f6', '#ec4899', '#8b5cf6'][Math.floor(Math.random() * 5)],
            width: '10px',
            height: '10px',
            borderRadius: Math.random() > 0.5 ? '50%' : '0',
          }}
        />
      ))}
      <style jsx>{`
        @keyframes confetti {
          0% { transform: translateY(0) rotate(0deg); opacity: 1; }
          100% { transform: translateY(100vh) rotate(720deg); opacity: 0; }
        }
        .animate-confetti {
          animation: confetti 3s ease-out forwards;
        }
      `}</style>
    </div>
  );
}

// View Mode Toggle
function ViewModeToggle({ mode, onChange }: { mode: ViewMode; onChange: (mode: ViewMode) => void }) {
  return (
    <div className="flex bg-slate-100 rounded-lg p-1">
      <button
        onClick={() => onChange('active')}
        className={`flex items-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-all ${
          mode === 'active'
            ? 'bg-white text-slate-900 shadow-sm'
            : 'text-slate-600 hover:text-slate-900'
        }`}
      >
        <Hammer className="w-4 h-4" />
        Active Builds
      </button>
      <button
        onClick={() => onChange('wishlist')}
        className={`flex items-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-all ${
          mode === 'wishlist'
            ? 'bg-white text-slate-900 shadow-sm'
            : 'text-slate-600 hover:text-slate-900'
        }`}
      >
        <Lightbulb className="w-4 h-4" />
        The Wishlist
      </button>
    </div>
  );
}

// Circular Progress Ring
function ProgressRing({ progress, size = 48, strokeWidth = 4 }: { progress: number; size?: number; strokeWidth?: number }) {
  const radius = (size - strokeWidth) / 2;
  const circumference = radius * 2 * Math.PI;
  const offset = circumference - (progress / 100) * circumference;

  return (
    <div className="relative" style={{ width: size, height: size }}>
      <svg className="transform -rotate-90" width={size} height={size}>
        <circle
          className="stroke-slate-200"
          strokeWidth={strokeWidth}
          fill="transparent"
          r={radius}
          cx={size / 2}
          cy={size / 2}
        />
        <circle
          className={`${getProgressColor(progress)} transition-all duration-500`}
          strokeWidth={strokeWidth}
          strokeLinecap="round"
          fill="transparent"
          r={radius}
          cx={size / 2}
          cy={size / 2}
          style={{ strokeDasharray: circumference, strokeDashoffset: offset }}
        />
      </svg>
      <div className="absolute inset-0 flex items-center justify-center">
        <span className="text-xs font-bold text-slate-900">{progress}%</span>
      </div>
    </div>
  );
}

// Before/After Slider
function BeforeAfterSlider({ beforeImage, afterImage }: { beforeImage: string; afterImage: string }) {
  const [sliderPosition, setSliderPosition] = useState(50);
  const containerRef = useRef<HTMLDivElement>(null);

  const handleMouseMove = (e: React.MouseEvent) => {
    if (!containerRef.current) return;
    const rect = containerRef.current.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const percentage = Math.max(0, Math.min(100, (x / rect.width) * 100));
    setSliderPosition(percentage);
  };

  return (
    <div
      ref={containerRef}
      className="relative w-full aspect-video rounded-xl overflow-hidden cursor-ew-resize select-none"
      onMouseMove={handleMouseMove}
    >
      {/* After Image (Background) */}
      <div className="absolute inset-0">
        <Image src={afterImage} alt="After" fill className="object-cover" />
      </div>

      {/* Before Image (Clipped) */}
      <div
        className="absolute inset-0 overflow-hidden"
        style={{ width: `${sliderPosition}%` }}
      >
        <Image src={beforeImage} alt="Before" fill className="object-cover" />
      </div>

      {/* Slider Handle */}
      <div
        className="absolute top-0 bottom-0 w-1 bg-white shadow-lg"
        style={{ left: `${sliderPosition}%`, transform: 'translateX(-50%)' }}
      >
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-10 h-10 bg-white rounded-full shadow-lg flex items-center justify-center">
          <div className="flex">
            <ArrowLeft className="w-3 h-3 text-slate-600" />
            <ArrowRight className="w-3 h-3 text-slate-600" />
          </div>
        </div>
      </div>

      {/* Labels */}
      <span className="absolute top-3 left-3 px-2 py-1 bg-black/60 text-white text-xs font-medium rounded">Before</span>
      <span className="absolute top-3 right-3 px-2 py-1 bg-black/60 text-white text-xs font-medium rounded">After</span>
    </div>
  );
}

// Project Card
function ProjectCard({
  project,
  onClick,
}: {
  project: Project;
  onClick: () => void;
}) {
  const daysUntil = project.dueDate ? getDaysUntil(project.dueDate) : null;
  const budgetStatus = getBudgetStatus(project.estimatedBudget, project.actualSpend);
  const isWishlist = project.status === 'wishlist';

  return (
    <div
      onClick={onClick}
      className="group bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden cursor-pointer hover:shadow-md hover:border-emerald-300 transition-all"
    >
      {/* Cover Image */}
      <div className="relative h-48 overflow-hidden">
        <Image
          src={project.coverImage}
          alt={project.title}
          fill
          className="object-cover group-hover:scale-105 transition-transform duration-300"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent" />

        {/* Overlays */}
        <div className="absolute top-3 left-3 right-3 flex items-start justify-between">
          <span className="px-2 py-1 bg-white/90 backdrop-blur-sm rounded-md text-xs font-medium text-slate-700">
            {project.category}
          </span>
          {!isWishlist && (
            <ProgressRing progress={project.progress} size={44} strokeWidth={3} />
          )}
        </div>

        {/* Bottom Overlays */}
        {!isWishlist && (
          <div className="absolute bottom-3 left-3 right-3 flex items-center gap-2">
            {daysUntil !== null && (
              <span className="px-2 py-1 bg-white/90 backdrop-blur-sm rounded-md text-xs font-medium text-slate-700 flex items-center gap-1">
                <Clock className="w-3 h-3" />
                {daysUntil > 0 ? `${daysUntil} days left` : daysUntil === 0 ? 'Due today' : `${Math.abs(daysUntil)} days overdue`}
              </span>
            )}
            <span className={`px-2 py-1 rounded-md text-xs font-medium flex items-center gap-1 ${
              budgetStatus === 'over'
                ? 'bg-red-100 text-red-700'
                : budgetStatus === 'on-track'
                ? 'bg-amber-100 text-amber-700'
                : 'bg-emerald-100 text-emerald-700'
            }`}>
              <DollarSign className="w-3 h-3" />
              {budgetStatus === 'over' ? 'Over Budget' : budgetStatus === 'on-track' ? 'On Track' : 'Under Budget'}
            </span>
          </div>
        )}
      </div>

      {/* Content */}
      <div className="p-4">
        <h3 className="font-semibold text-slate-900 group-hover:text-emerald-600 transition-colors">
          {project.title}
        </h3>
        <p className="text-sm text-slate-500 mt-1 line-clamp-2">{project.description}</p>

        {!isWishlist && (
          <div className="flex items-center justify-between mt-4 pt-4 border-t border-slate-100">
            <div>
              <p className="text-xs text-slate-500">Budget</p>
              <p className="font-semibold text-slate-900">{formatCurrency(project.estimatedBudget)}</p>
            </div>
            <div className="text-right">
              <p className="text-xs text-slate-500">Spent</p>
              <p className={`font-semibold ${
                budgetStatus === 'over' ? 'text-red-600' : 'text-emerald-600'
              }`}>
                {formatCurrency(project.actualSpend)}
              </p>
            </div>
          </div>
        )}

        {isWishlist && (
          <div className="mt-4 pt-4 border-t border-slate-100">
            <p className="text-xs text-slate-500">Estimated Budget</p>
            <p className="font-semibold text-slate-900">{formatCurrency(project.estimatedBudget)}</p>
          </div>
        )}
      </div>
    </div>
  );
}

// Masonry Grid for Inspiration Images
function MasonryGrid({ images, onAddImage }: { images: InspirationImage[]; onAddImage: () => void }) {
  return (
    <div className="columns-2 md:columns-3 lg:columns-4 gap-4 space-y-4">
      {images.map((image) => (
        <div
          key={image.id}
          className="break-inside-avoid relative rounded-xl overflow-hidden group cursor-pointer bg-slate-100"
        >
          <Image
            src={image.url}
            alt=""
            width={300}
            height={image.aspectRatio === 'portrait' ? 400 : image.aspectRatio === 'landscape' ? 200 : 300}
            className="w-full h-auto"
          />
          <div className="absolute inset-0 bg-black/0 group-hover:bg-black/40 transition-colors">
            <div className="absolute bottom-0 left-0 right-0 p-3 opacity-0 group-hover:opacity-100 transition-opacity">
              <div className="flex items-center gap-2">
                <button className="p-2 bg-white/90 rounded-lg hover:bg-white transition-colors">
                  <Heart className="w-4 h-4 text-slate-700" />
                </button>
                <button className="p-2 bg-white/90 rounded-lg hover:bg-white transition-colors">
                  <Share2 className="w-4 h-4 text-slate-700" />
                </button>
                {image.source && (
                  <span className="ml-auto text-xs text-white font-medium">{image.source}</span>
                )}
              </div>
            </div>
          </div>
        </div>
      ))}

      {/* Add Image Card */}
      <div
        onClick={onAddImage}
        className="break-inside-avoid flex flex-col items-center justify-center p-8 rounded-xl border-2 border-dashed border-slate-300 hover:border-emerald-500 hover:bg-emerald-50 cursor-pointer transition-colors aspect-square"
      >
        <ImagePlus className="w-8 h-8 text-slate-400" />
        <p className="text-sm text-slate-500 mt-2">Add Inspiration</p>
      </div>
    </div>
  );
}

// Smart Suggestion Chips
function SmartSuggestions({ items, onAdd }: { items: string[]; onAdd: (item: string) => void }) {
  if (items.length === 0) return null;

  return (
    <div className="bg-amber-50 rounded-xl p-4 mb-6">
      <div className="flex items-center gap-2 mb-3">
        <Sparkles className="w-5 h-5 text-amber-600" />
        <span className="font-medium text-amber-900">Community Suggestions</span>
      </div>
      <p className="text-sm text-amber-700 mb-3">Based on your project, others also added:</p>
      <div className="flex flex-wrap gap-2">
        {items.map((item) => (
          <button
            key={item}
            onClick={() => onAdd(item)}
            className="inline-flex items-center gap-1 px-3 py-1.5 bg-white rounded-full text-sm font-medium text-slate-700 border border-amber-200 hover:border-emerald-400 hover:bg-emerald-50 transition-colors"
          >
            <Plus className="w-3 h-3" />
            {item}
          </button>
        ))}
      </div>
    </div>
  );
}

// Kanban Task Card - Draggable
function TaskCard({
  task,
  projectId,
  onRequestQuote,
  onDragStart,
  isDragging,
}: {
  task: ProjectTask;
  projectId: string;
  onRequestQuote?: () => void;
  onDragStart?: (taskId: string) => void;
  isDragging?: boolean;
}) {
  const handleDragStart = (e: React.DragEvent) => {
    e.dataTransfer.setData('taskId', task.id);
    e.dataTransfer.setData('projectId', projectId);
    e.dataTransfer.effectAllowed = 'move';
    onDragStart?.(task.id);
  };

  return (
    <div
      draggable
      onDragStart={handleDragStart}
      className={`bg-white rounded-lg border border-slate-200 p-3 shadow-sm hover:shadow-md transition-all cursor-grab active:cursor-grabbing ${
        isDragging ? 'opacity-50 scale-95' : ''
      }`}
    >
      <div className="flex items-start gap-2">
        <GripVertical className="w-4 h-4 text-slate-300 mt-1" />
        <div className="flex-1 min-w-0">
          <p className="font-medium text-slate-900 text-sm">{task.title}</p>
          {task.dueDate && (
            <p className="text-xs text-slate-500 mt-1 flex items-center gap-1">
              <Calendar className="w-3 h-3" />
              {formatDate(task.dueDate)}
            </p>
          )}
          {task.estimatedCost && (
            <p className="text-xs text-emerald-600 mt-1">{formatCurrency(task.estimatedCost)}</p>
          )}

          {/* Recommended Vendor */}
          {task.recommendedVendor && (
            <div className="mt-3 p-2 bg-slate-50 rounded-lg">
              <p className="text-xs text-slate-500 mb-1.5">Recommended Pro</p>
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-full bg-emerald-100 flex items-center justify-center">
                  <Wrench className="w-4 h-4 text-emerald-600" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-slate-900 truncate">{task.recommendedVendor.name}</p>
                  <div className="flex items-center gap-1">
                    <Star className="w-3 h-3 text-amber-400 fill-amber-400" />
                    <span className="text-xs text-slate-600">{task.recommendedVendor.rating}</span>
                    {task.recommendedVendor.verified && (
                      <Shield className="w-3 h-3 text-amber-500" />
                    )}
                  </div>
                </div>
              </div>
              {task.recommendedVendor.friendsUsed && task.recommendedVendor.friendsUsed.length > 0 && (
                <p className="text-xs text-emerald-600 mt-1.5">
                  Used by {task.recommendedVendor.friendsUsed.join(', ')}
                </p>
              )}
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  onRequestQuote?.();
                }}
                className="mt-2 w-full px-3 py-1.5 bg-emerald-600 text-white text-xs font-medium rounded-lg hover:bg-emerald-700 transition-colors"
              >
                Request Quote
              </button>
            </div>
          )}
        </div>
        <button className="p-1 hover:bg-slate-100 rounded">
          <MoreVertical className="w-4 h-4 text-slate-400" />
        </button>
      </div>
    </div>
  );
}

// Kanban Column - Drop Zone
function KanbanColumn({
  title,
  tasks,
  status,
  projectId,
  icon: Icon,
  color,
  onDrop,
  onDragStart,
  draggedTaskId,
}: {
  title: string;
  tasks: ProjectTask[];
  status: TaskStatus;
  projectId: string;
  icon: typeof Circle;
  color: string;
  onDrop: (taskId: string, projectId: string, newStatus: TaskStatus) => void;
  onDragStart: (taskId: string) => void;
  draggedTaskId: string | null;
}) {
  const [isDragOver, setIsDragOver] = useState(false);

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
    setIsDragOver(true);
  };

  const handleDragLeave = () => {
    setIsDragOver(false);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(false);
    const taskId = e.dataTransfer.getData('taskId');
    const sourceProjectId = e.dataTransfer.getData('projectId');
    if (taskId && sourceProjectId === projectId) {
      onDrop(taskId, projectId, status);
    }
  };

  return (
    <div
      className={`flex-1 min-w-[280px] transition-all ${
        isDragOver ? 'scale-[1.02]' : ''
      }`}
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
    >
      <div className={`flex items-center gap-2 px-3 py-2 rounded-lg ${color} mb-3 ${
        isDragOver ? 'ring-2 ring-emerald-500 ring-offset-2' : ''
      }`}>
        <Icon className="w-4 h-4" />
        <span className="font-medium text-sm">{title}</span>
        <span className="ml-auto text-xs bg-white/50 px-2 py-0.5 rounded-full">{tasks.length}</span>
      </div>
      <div className={`space-y-2 min-h-[100px] rounded-lg p-1 transition-colors ${
        isDragOver ? 'bg-emerald-50 border-2 border-dashed border-emerald-300' : ''
      }`}>
        {tasks.map((task) => (
          <TaskCard
            key={task.id}
            task={task}
            projectId={projectId}
            onDragStart={onDragStart}
            isDragging={draggedTaskId === task.id}
          />
        ))}
        {tasks.length === 0 && (
          <div className="flex items-center justify-center h-20 text-slate-400 text-sm">
            {isDragOver ? 'Drop here' : 'No tasks'}
          </div>
        )}
      </div>
    </div>
  );
}

// Budget Burn Down Chart
function BurnDownChart({ estimated, actual }: { estimated: number; actual: number }) {
  const percentage = Math.round((actual / estimated) * 100);
  const remaining = estimated - actual;

  return (
    <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h3 className="font-semibold text-slate-900">Budget Overview</h3>
          <p className="text-sm text-slate-500">Estimated vs Actual Spend</p>
        </div>
        <div className="text-right">
          <p className="text-2xl font-bold text-slate-900">{formatCurrency(actual)}</p>
          <p className="text-sm text-slate-500">of {formatCurrency(estimated)}</p>
        </div>
      </div>

      {/* Progress Bar */}
      <div className="relative h-8 bg-slate-100 rounded-lg overflow-hidden mb-4">
        <div
          className={`absolute inset-y-0 left-0 ${getBurnDownColor(percentage)} transition-all duration-500`}
          style={{ width: `${Math.min(percentage, 100)}%` }}
        />
        <div className="absolute inset-0 flex items-center justify-center">
          <span className="text-sm font-bold text-white drop-shadow">{percentage}% Used</span>
        </div>
      </div>

      {/* Legend */}
      <div className="flex items-center justify-between text-sm">
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 rounded bg-emerald-500" />
            <span className="text-slate-600">0-80% Healthy</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 rounded bg-amber-500" />
            <span className="text-slate-600">81-99% Caution</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 rounded bg-red-500" />
            <span className="text-slate-600">100%+ Over</span>
          </div>
        </div>
        <div className={`font-semibold ${remaining >= 0 ? 'text-emerald-600' : 'text-red-600'}`}>
          {remaining >= 0 ? `${formatCurrency(remaining)} remaining` : `${formatCurrency(Math.abs(remaining))} over`}
        </div>
      </div>
    </div>
  );
}

// Expense Table
function ExpenseTable({ expenses }: { expenses: Expense[] }) {
  const groupedExpenses: Record<string, Expense[]> = {};
  expenses.forEach((expense) => {
    if (!groupedExpenses[expense.category]) {
      groupedExpenses[expense.category] = [];
    }
    groupedExpenses[expense.category]!.push(expense);
  });

  const defaultCategory = { label: 'Other', icon: Receipt };
  const categoryLabels: Record<string, { label: string; icon: typeof Receipt }> = {
    materials: { label: 'Materials', icon: Layers },
    labor: { label: 'Labor', icon: Wrench },
    permits: { label: 'Permits', icon: FileText },
    other: defaultCategory,
  };

  return (
    <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
      <div className="px-6 py-4 border-b border-slate-200">
        <h3 className="font-semibold text-slate-900">Expense Breakdown</h3>
      </div>

      {Object.entries(groupedExpenses).map(([category, items]) => {
        const categoryInfo = categoryLabels[category] ?? defaultCategory;
        const label = categoryInfo.label;
        const Icon = categoryInfo.icon;
        const categoryTotal = items.reduce((sum, e) => sum + (e.actualAmount || e.estimatedAmount), 0);

        return (
          <div key={category} className="border-b border-slate-100 last:border-0">
            <div className="px-6 py-3 bg-slate-50 flex items-center gap-2">
              <Icon className="w-4 h-4 text-slate-500" />
              <span className="font-medium text-slate-700">{label}</span>
              <span className="ml-auto font-semibold text-slate-900">{formatCurrency(categoryTotal)}</span>
            </div>
            <div className="divide-y divide-slate-100">
              {items.map((expense) => (
                <div key={expense.id} className="px-6 py-3 flex items-center">
                  <div className="flex-1">
                    <p className="text-sm text-slate-900">{expense.description}</p>
                    {expense.vendor && (
                      <p className="text-xs text-slate-500">{expense.vendor}</p>
                    )}
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-medium text-slate-900">
                      {formatCurrency(expense.actualAmount || expense.estimatedAmount)}
                    </p>
                    {expense.actualAmount && expense.actualAmount !== expense.estimatedAmount && (
                      <p className="text-xs text-slate-500 line-through">
                        {formatCurrency(expense.estimatedAmount)}
                      </p>
                    )}
                  </div>
                  <div className="ml-4">
                    {expense.paid ? (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-emerald-100 text-emerald-700 text-xs font-medium rounded-full">
                        <CheckCircle className="w-3 h-3" />
                        Paid
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-amber-100 text-amber-700 text-xs font-medium rounded-full">
                        <Clock className="w-3 h-3" />
                        Pending
                      </span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        );
      })}
    </div>
  );
}

// Project Detail View
function ProjectDetailView({
  project,
  onClose,
  onComplete,
  onTaskStatusChange,
}: {
  project: Project;
  onClose: () => void;
  onComplete: () => void;
  onTaskStatusChange: (projectId: string, taskId: string, newStatus: TaskStatus) => void;
}) {
  const [activeTab, setActiveTab] = useState<ProjectTab>('inspiration');
  const [showConfetti, setShowConfetti] = useState(false);
  const [draggedTaskId, setDraggedTaskId] = useState<string | null>(null);

  const handleComplete = () => {
    setShowConfetti(true);
    onComplete();
    setTimeout(() => setShowConfetti(false), 3000);
  };

  const handleDragStart = (taskId: string) => {
    setDraggedTaskId(taskId);
  };

  const handleDrop = (taskId: string, projectId: string, newStatus: TaskStatus) => {
    setDraggedTaskId(null);
    onTaskStatusChange(projectId, taskId, newStatus);
  };

  const handleDragEnd = () => {
    setDraggedTaskId(null);
  };

  const tasksByStatus = project.tasks.reduce((acc, task) => {
    if (!acc[task.status]) acc[task.status] = [];
    acc[task.status].push(task);
    return acc;
  }, {} as Record<TaskStatus, ProjectTask[]>);

  return (
    <div className="fixed inset-0 z-50 bg-slate-50 overflow-y-auto">
      <Confetti active={showConfetti} />

      {/* Header */}
      <div className="sticky top-0 z-10 bg-white border-b border-slate-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between py-4">
            <div className="flex items-center gap-4">
              <button
                onClick={onClose}
                className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
              >
                <ArrowLeft className="w-5 h-5 text-slate-600" />
              </button>
              <div>
                <h1 className="text-xl font-bold text-slate-900">{project.title}</h1>
                <p className="text-sm text-slate-500">{project.category}</p>
              </div>
            </div>
            <div className="flex items-center gap-3">
              <ProgressRing progress={project.progress} size={40} strokeWidth={3} />
              {project.progress === 100 ? (
                <span className="px-3 py-1.5 bg-emerald-100 text-emerald-700 text-sm font-medium rounded-lg">
                  Completed
                </span>
              ) : (
                <button
                  onClick={handleComplete}
                  className="px-4 py-2 bg-emerald-600 text-white text-sm font-medium rounded-lg hover:bg-emerald-700 transition-colors"
                >
                  Mark Complete
                </button>
              )}
            </div>
          </div>

          {/* Before/After Slider */}
          {project.beforeImage && project.afterImage && (
            <div className="pb-4">
              <BeforeAfterSlider beforeImage={project.beforeImage} afterImage={project.afterImage} />
            </div>
          )}

          {/* Tabs */}
          <div className="flex gap-1 border-b border-slate-200 -mb-px">
            {[
              { id: 'inspiration', label: 'Inspiration', icon: Lightbulb },
              { id: 'plan', label: 'The Plan', icon: Layers },
              { id: 'financials', label: 'Financials', icon: DollarSign },
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as ProjectTab)}
                className={`flex items-center gap-2 px-4 py-3 text-sm font-medium border-b-2 -mb-px transition-colors ${
                  activeTab === tab.id
                    ? 'border-emerald-600 text-emerald-600'
                    : 'border-transparent text-slate-600 hover:text-slate-900'
                }`}
              >
                <tab.icon className="w-4 h-4" />
                {tab.label}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Tab Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        {/* Inspiration Tab */}
        {activeTab === 'inspiration' && (
          <div>
            {/* Add from Pinterest */}
            <div className="flex items-center gap-4 mb-6">
              <div className="flex-1 relative">
                <LinkIcon className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
                <input
                  type="url"
                  placeholder="Paste a Pinterest or Houzz URL..."
                  className="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-300 rounded-lg text-sm focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                />
              </div>
              <button className="px-4 py-2.5 bg-emerald-600 text-white text-sm font-medium rounded-lg hover:bg-emerald-700 transition-colors flex items-center gap-2">
                <Plus className="w-4 h-4" />
                Add from URL
              </button>
            </div>

            {/* Smart Suggestions */}
            {project.suggestedItems && (
              <SmartSuggestions items={project.suggestedItems} onAdd={(item) => console.log('Add:', item)} />
            )}

            {/* Masonry Grid */}
            <MasonryGrid images={project.inspiration} onAddImage={() => console.log('Add image')} />
          </div>
        )}

        {/* Plan Tab */}
        {activeTab === 'plan' && (
          <div className="flex gap-4 overflow-x-auto pb-4" onDragEnd={handleDragEnd}>
            <KanbanColumn
              title="To Do"
              tasks={tasksByStatus.todo || []}
              status="todo"
              projectId={project.id}
              icon={Circle}
              color="bg-slate-100 text-slate-700"
              onDrop={handleDrop}
              onDragStart={handleDragStart}
              draggedTaskId={draggedTaskId}
            />
            <KanbanColumn
              title="Scheduled"
              tasks={tasksByStatus.scheduled || []}
              status="scheduled"
              projectId={project.id}
              icon={Calendar}
              color="bg-blue-100 text-blue-700"
              onDrop={handleDrop}
              onDragStart={handleDragStart}
              draggedTaskId={draggedTaskId}
            />
            <KanbanColumn
              title="In Progress"
              tasks={tasksByStatus.in_progress || []}
              status="in_progress"
              projectId={project.id}
              icon={Play}
              color="bg-amber-100 text-amber-700"
              onDrop={handleDrop}
              onDragStart={handleDragStart}
              draggedTaskId={draggedTaskId}
            />
            <KanbanColumn
              title="Done"
              tasks={tasksByStatus.done || []}
              status="done"
              projectId={project.id}
              icon={CheckCircle2}
              color="bg-emerald-100 text-emerald-700"
              onDrop={handleDrop}
              onDragStart={handleDragStart}
              draggedTaskId={draggedTaskId}
            />
          </div>
        )}

        {/* Financials Tab */}
        {activeTab === 'financials' && (
          <div className="space-y-6">
            <BurnDownChart estimated={project.estimatedBudget} actual={project.actualSpend} />
            <ExpenseTable expenses={project.expenses} />
          </div>
        )}
      </div>
    </div>
  );
}

// Mobile Quick Capture FAB - positioned above the global chat FAB
function QuickCaptureFAB({ mode }: { mode: ViewMode }) {
  return (
    <button className="lg:hidden fixed bottom-36 right-4 w-12 h-12 bg-emerald-600 text-white rounded-full shadow-lg flex items-center justify-center hover:bg-emerald-700 transition-colors z-40">
      {mode === 'wishlist' ? (
        <Camera className="w-5 h-5" />
      ) : (
        <Plus className="w-5 h-5" />
      )}
    </button>
  );
}

// ============================================================================
// MAIN PAGE
// ============================================================================

export default function ProjectsPage() {
  // Auth context for household
  const { currentHousehold } = useAuth();

  // State - initialize with mocks (hybrid pattern)
  const [viewMode, setViewMode] = useState<ViewMode>('active');
  const [selectedProject, setSelectedProject] = useState<Project | null>(null);
  const [projects, setProjects] = useState<Project[]>(MOCK_PROJECTS);
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const [_isLoading, setIsLoading] = useState(true);

  // Hybrid Data Fetching - load from API, fallback to mocks
  const loadProjects = useCallback(async () => {
    if (!currentHousehold?.id) {
      setIsLoading(false);
      return;
    }

    try {
      // Type for future API methods (not yet in ApiClient)
      type FutureApiClient = {
        getProjects?: (householdId: string) => Promise<unknown[]>;
        getProjectIdeas?: (householdId: string) => Promise<unknown[]>;
      };

      const api = getApiClient() as unknown as FutureApiClient;

      // Fetch projects in parallel with Promise.allSettled
      const [projectsResult] = await Promise.allSettled([
        api.getProjects?.(currentHousehold.id) ?? Promise.resolve([]),
      ]);

      // Process projects
      if (projectsResult.status === 'fulfilled') {
        const projectsData = projectsResult.value;
        if (Array.isArray(projectsData) && projectsData.length > 0) {
          setProjects(projectsData.map((p) => mapApiProjectToUi(p as Record<string, unknown>)));
        }
        // If empty, keep MOCK_PROJECTS (Demo Mode)
      } else {
        console.warn('Failed to fetch projects:', projectsResult.reason);
        // Keep mock data on failure
      }
    } catch (error) {
      console.error('Error loading projects:', error);
      // Keep mock data on failure - already initialized with mocks
    } finally {
      setIsLoading(false);
    }
  }, [currentHousehold?.id]);

  // Load data on mount and when household changes
  useEffect(() => {
    loadProjects();
  }, [loadProjects]);

  // Filter projects by view mode
  const activeProjects = useMemo(
    () => projects.filter((p) => p.status === 'active'),
    [projects]
  );
  const wishlistProjects = useMemo(
    () => projects.filter((p) => p.status === 'wishlist'),
    [projects]
  );
  const displayedProjects = viewMode === 'active' ? activeProjects : wishlistProjects;

  // Handle project completion with optimistic update
  const handleComplete = useCallback((projectId: string) => {
    // Optimistic update
    setProjects((prev) => prev.map((p) =>
      p.id === projectId ? { ...p, status: 'completed' as const, progress: 100 } : p
    ));

    // Sync to API (API endpoints not yet implemented)
    if (currentHousehold?.id) {
      type FutureApiClient = {
        updateProject?: (householdId: string, projectId: string, data: Record<string, unknown>) => Promise<unknown>;
      };
      const api = getApiClient() as unknown as FutureApiClient;
      api.updateProject?.(currentHousehold.id, projectId, {
        status: 'completed',
        progress: 100,
      })?.catch((err: unknown) => {
        console.error('Failed to complete project:', err);
        // Revert on failure
        setProjects((prev) => prev.map((p) =>
          p.id === projectId ? { ...p, status: 'active' as const, progress: p.progress } : p
        ));
      });
    }
  }, [currentHousehold?.id]);

  // Handle task status change with optimistic update (for Kanban drag-drop)
  const handleTaskStatusChange = useCallback((projectId: string, taskId: string, newStatus: TaskStatus) => {
    // Find the project and task
    const project = projects.find((p) => p.id === projectId);
    if (!project) return;

    const oldTask = project.tasks.find((t) => t.id === taskId);
    if (!oldTask || oldTask.status === newStatus) return;

    // Optimistic update
    setProjects((prev) => prev.map((p) => {
      if (p.id !== projectId) return p;
      const updatedTasks = p.tasks.map((t) =>
        t.id === taskId ? { ...t, status: newStatus } : t
      );
      // Recalculate progress based on done tasks
      const doneTasks = updatedTasks.filter((t) => t.status === 'done').length;
      const newProgress = updatedTasks.length > 0
        ? Math.round((doneTasks / updatedTasks.length) * 100)
        : 0;
      return { ...p, tasks: updatedTasks, progress: newProgress };
    }));

    // Also update selectedProject if it's the same one
    if (selectedProject?.id === projectId) {
      setSelectedProject((prev) => {
        if (!prev) return null;
        const updatedTasks = prev.tasks.map((t) =>
          t.id === taskId ? { ...t, status: newStatus } : t
        );
        const doneTasks = updatedTasks.filter((t) => t.status === 'done').length;
        const newProgress = updatedTasks.length > 0
          ? Math.round((doneTasks / updatedTasks.length) * 100)
          : 0;
        return { ...prev, tasks: updatedTasks, progress: newProgress };
      });
    }

    // Sync to API (API endpoints not yet implemented)
    if (currentHousehold?.id) {
      type FutureApiClient = {
        updateProjectTask?: (householdId: string, projectId: string, taskId: string, data: Record<string, unknown>) => Promise<unknown>;
      };
      const api = getApiClient() as unknown as FutureApiClient;
      api.updateProjectTask?.(currentHousehold.id, projectId, taskId, {
        status: newStatus,
      })?.catch((err: unknown) => {
        console.error('Failed to update task status:', err);
        // Revert on failure
        setProjects((prev) => prev.map((p) => {
          if (p.id !== projectId) return p;
          const revertedTasks = p.tasks.map((t) =>
            t.id === taskId ? { ...t, status: oldTask.status } : t
          );
          const doneTasks = revertedTasks.filter((t) => t.status === 'done').length;
          const revertedProgress = revertedTasks.length > 0
            ? Math.round((doneTasks / revertedTasks.length) * 100)
            : 0;
          return { ...p, tasks: revertedTasks, progress: revertedProgress };
        }));
      });
    }
  }, [projects, selectedProject, currentHousehold?.id]);

  // Summary stats
  const totalBudget = activeProjects.reduce((sum, p) => sum + p.estimatedBudget, 0);
  const totalSpent = activeProjects.reduce((sum, p) => sum + p.actualSpend, 0);
  const avgProgress = activeProjects.length > 0
    ? Math.round(activeProjects.reduce((sum, p) => sum + p.progress, 0) / activeProjects.length)
    : 0;

  return (
    <div className="pb-32 lg:pb-8">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
        <div>
          <h1 className="text-2xl lg:text-3xl font-bold text-slate-900">Project Planning</h1>
          <p className="text-slate-500 mt-1">Dream, plan, and build your home improvements</p>
        </div>
        <div className="flex items-center gap-3">
          <ViewModeToggle mode={viewMode} onChange={setViewMode} />
          <Link
            href="/app/projects/new"
            className="hidden sm:inline-flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white text-sm font-medium rounded-lg hover:bg-emerald-700 transition-colors shadow-sm"
          >
            <Plus className="w-4 h-4" />
            New Project
          </Link>
        </div>
      </div>

      {/* Stats Banner (Active Mode Only) */}
      {viewMode === 'active' && activeProjects.length > 0 && (
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
          <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4">
            <div className="flex items-center gap-2 text-slate-500 mb-1">
              <Hammer className="w-4 h-4" />
              <span className="text-sm">Active Projects</span>
            </div>
            <p className="text-2xl font-bold text-slate-900">{activeProjects.length}</p>
          </div>
          <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4">
            <div className="flex items-center gap-2 text-slate-500 mb-1">
              <TrendingUp className="w-4 h-4" />
              <span className="text-sm">Avg. Progress</span>
            </div>
            <p className="text-2xl font-bold text-emerald-600">{avgProgress}%</p>
          </div>
          <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4">
            <div className="flex items-center gap-2 text-slate-500 mb-1">
              <DollarSign className="w-4 h-4" />
              <span className="text-sm">Total Budget</span>
            </div>
            <p className="text-2xl font-bold text-slate-900">{formatCurrency(totalBudget)}</p>
          </div>
          <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4">
            <div className="flex items-center gap-2 text-slate-500 mb-1">
              <Receipt className="w-4 h-4" />
              <span className="text-sm">Total Spent</span>
            </div>
            <p className={`text-2xl font-bold ${totalSpent > totalBudget ? 'text-red-600' : 'text-emerald-600'}`}>
              {formatCurrency(totalSpent)}
            </p>
          </div>
        </div>
      )}

      {/* Wishlist Header */}
      {viewMode === 'wishlist' && (
        <div className="bg-gradient-to-r from-purple-50 to-pink-50 rounded-xl p-6 mb-8 border border-purple-100">
          <div className="flex items-start gap-4">
            <div className="p-3 bg-white rounded-xl shadow-sm">
              <Lightbulb className="w-6 h-6 text-purple-600" />
            </div>
            <div>
              <h2 className="text-lg font-semibold text-slate-900">Your Dream Board</h2>
              <p className="text-slate-600 mt-1">
                Capture ideas for future projects. No budgets, no deadlines - just inspiration.
                When you're ready to build, promote a wishlist item to Active Builds.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Project Grid */}
      {displayedProjects.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {displayedProjects.map((project) => (
            <ProjectCard
              key={project.id}
              project={project}
              onClick={() => setSelectedProject(project)}
            />
          ))}

          {/* Add New Card */}
          <Link
            href="/app/projects/new"
            className="flex flex-col items-center justify-center p-8 rounded-xl border-2 border-dashed border-slate-300 hover:border-emerald-500 hover:bg-emerald-50 cursor-pointer transition-colors min-h-[300px]"
          >
            <div className="p-4 bg-slate-100 rounded-full mb-4">
              <Plus className="w-8 h-8 text-slate-400" />
            </div>
            <p className="font-medium text-slate-600">Add New {viewMode === 'active' ? 'Project' : 'Idea'}</p>
            <p className="text-sm text-slate-400 mt-1">
              {viewMode === 'active' ? 'Start a new home improvement' : 'Capture your inspiration'}
            </p>
          </Link>
        </div>
      ) : (
        <div className="text-center py-16">
          <div className="inline-flex items-center justify-center w-16 h-16 bg-slate-100 rounded-full mb-4">
            {viewMode === 'active' ? (
              <Hammer className="w-8 h-8 text-slate-400" />
            ) : (
              <Lightbulb className="w-8 h-8 text-slate-400" />
            )}
          </div>
          <h3 className="text-lg font-semibold text-slate-900 mb-2">
            {viewMode === 'active' ? 'No active projects' : 'Your wishlist is empty'}
          </h3>
          <p className="text-slate-500 mb-6 max-w-md mx-auto">
            {viewMode === 'active'
              ? 'Start your first home improvement project and track it from inspiration to completion.'
              : 'Start capturing your dream home improvements. Snap photos, save ideas, plan for the future.'}
          </p>
          <Link
            href="/app/projects/new"
            className="inline-flex items-center gap-2 px-6 py-3 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors"
          >
            <Plus className="w-5 h-5" />
            {viewMode === 'active' ? 'Start a Project' : 'Add Your First Idea'}
          </Link>
        </div>
      )}

      {/* Mobile FAB */}
      <QuickCaptureFAB mode={viewMode} />

      {/* Project Detail Modal */}
      {selectedProject && (
        <ProjectDetailView
          project={selectedProject}
          onClose={() => setSelectedProject(null)}
          onComplete={() => {
            handleComplete(selectedProject.id);
            setSelectedProject({ ...selectedProject, progress: 100, status: 'completed' });
          }}
          onTaskStatusChange={handleTaskStatusChange}
        />
      )}
    </div>
  );
}
