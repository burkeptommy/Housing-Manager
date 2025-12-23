'use client';

import { useState, useMemo, useCallback, useEffect } from 'react';
import {
  Plus,
  Check,
  Circle,
  Users,
  Briefcase,
  Send,
  MessageCircle,
  Flame,
  Trophy,
  Clock,
  Calendar,
  Repeat,
  Camera,
  Mic,
  X,
  Trash2,
  MoreHorizontal,
  CheckCircle2,
  Eye,
  Loader2,
  PartyPopper,
  Dog,
  Trash,
  ShoppingCart,
  Car,
  Phone,
  Utensils,
  Plane,
  Gift,
  Home,
  Sparkles,
  Share2,
  Bell,
  AlertCircle,
  LucideIcon,
  Search,
  FileText,
  RefreshCw,
  Lightbulb,
  ArrowRight,
  Zap,
  ChevronDown,
  BellRing,
  ClipboardList,
  HelpCircle,
} from 'lucide-react';

// Types
type TaskStatus = 'pending' | 'sent' | 'viewed' | 'researching' | 'in_progress' | 'waiting_approval' | 'completed';
type Recurrence = 'none' | 'daily' | 'weekly' | 'monthly' | 'yearly';
type ViewTab = 'household' | 'manager';

interface FamilyMember {
  id: string;
  name: string;
  initials: string;
  avatar?: string;
  color: string;
  tasksCompleted: number;
  currentStreak: number;
}

interface FamilyTask {
  id: string;
  type: 'family';
  title: string;
  assigneeId?: string;
  dueDate?: Date;
  dueTime?: string;
  completed: boolean;
  completedAt?: Date;
  completedBy?: string;
  recurrence: Recurrence;
  category?: string;
  priority: 'low' | 'medium' | 'high';
  createdAt: Date;
}

interface ManagerTask {
  id: string;
  type: 'manager';
  title: string;
  description?: string;
  status: TaskStatus;
  dueDate?: Date;
  attachments?: { type: 'photo' | 'voice'; url: string }[];
  recurrence: Recurrence;
  category?: string;
  priority: 'low' | 'medium' | 'high';
  createdAt: Date;
  statusHistory: { status: TaskStatus; timestamp: Date; note?: string }[];
  managerNote?: string;
  needsReview?: boolean;
  lastUpdate?: Date;
}

type Task = FamilyTask | ManagerTask;

interface ActivityItem {
  id: string;
  type: 'completed' | 'started' | 'viewed' | 'message' | 'researching';
  taskTitle: string;
  timestamp: Date;
  managerName: string;
}

interface TaskTemplate {
  id: string;
  title: string;
  icon: LucideIcon;
  placeholder: string;
  category: string;
}

// Task category icons
const CATEGORY_ICONS: Record<string, LucideIcon> = {
  pets: Dog,
  cleaning: Trash,
  shopping: ShoppingCart,
  errands: Car,
  calls: Phone,
  dining: Utensils,
  travel: Plane,
  gifts: Gift,
  home: Home,
  other: Sparkles,
  research: Search,
  quotes: FileText,
  scheduling: Calendar,
};

// Manager keywords for smart suggestions
const MANAGER_KEYWORDS = [
  'schedule', 'book', 'call', 'research', 'find', 'get quotes', 'quotes',
  'renew', 'cancel', 'set up', 'setup', 'coordinate', 'arrange', 'plan',
  'order', 'reserve', 'compare', 'look into', 'investigate', 'follow up',
];

const FAMILY_KEYWORDS = [
  'homework', 'clean room', 'take out trash', 'feed', 'walk dog', 'walk the dog',
  'empty dishwasher', 'make bed', 'practice', 'study', 'brush teeth',
  'put away', 'pick up', 'chores', 'water plants',
];

// Manager task templates
const MANAGER_TEMPLATES: TaskTemplate[] = [
  { id: 'research', title: 'Research [X] for me', icon: Search, placeholder: 'Research summer camps for Emma', category: 'research' },
  { id: 'quotes', title: 'Get quotes for [X]', icon: FileText, placeholder: 'Get quotes for driveway reseal', category: 'quotes' },
  { id: 'schedule', title: 'Schedule [X]', icon: Calendar, placeholder: 'Schedule HVAC maintenance', category: 'scheduling' },
  { id: 'book', title: 'Book [X]', icon: Plane, placeholder: 'Book anniversary dinner at La Maison', category: 'travel' },
  { id: 'renew', title: 'Renew [X]', icon: RefreshCw, placeholder: 'Renew car registration', category: 'errands' },
  { id: 'handle', title: 'Handle [X] - you decide', icon: Sparkles, placeholder: "Handle getting Mom's birthday gift", category: 'other' },
];

// Mock family members
const mockFamily: FamilyMember[] = [
  { id: 'bob', name: 'Bob', initials: 'B', color: 'bg-blue-500', tasksCompleted: 23, currentStreak: 5 },
  { id: 'alice', name: 'Alice', initials: 'A', color: 'bg-pink-500', tasksCompleted: 31, currentStreak: 7 },
  { id: 'emma', name: 'Emma', initials: 'E', color: 'bg-purple-500', tasksCompleted: 12, currentStreak: 3 },
  { id: 'jake', name: 'Jake', initials: 'J', color: 'bg-orange-500', tasksCompleted: 8, currentStreak: 2 },
];

// Mock family tasks
const mockFamilyTasks: FamilyTask[] = [
  { id: 'ft-1', type: 'family', title: 'Walk Max', assigneeId: 'emma', dueDate: new Date(), dueTime: '7:00 AM', completed: true, completedAt: new Date(), completedBy: 'emma', recurrence: 'daily', category: 'pets', priority: 'high', createdAt: new Date() },
  { id: 'ft-2', type: 'family', title: 'Take out recycling', assigneeId: 'jake', dueDate: new Date(), completed: false, recurrence: 'weekly', category: 'cleaning', priority: 'medium', createdAt: new Date() },
  { id: 'ft-3', type: 'family', title: 'Empty dishwasher', assigneeId: 'bob', dueDate: new Date(), completed: false, recurrence: 'daily', category: 'cleaning', priority: 'low', createdAt: new Date() },
  { id: 'ft-4', type: 'family', title: 'Water plants', assigneeId: 'alice', dueDate: new Date(), completed: true, completedAt: new Date(), completedBy: 'alice', recurrence: 'weekly', category: 'home', priority: 'low', createdAt: new Date() },
  { id: 'ft-5', type: 'family', title: 'Feed Max dinner', assigneeId: 'emma', dueDate: new Date(), dueTime: '6:00 PM', completed: false, recurrence: 'daily', category: 'pets', priority: 'high', createdAt: new Date() },
  { id: 'ft-6', type: 'family', title: 'Put away laundry', assigneeId: 'jake', dueDate: new Date(), completed: false, recurrence: 'none', category: 'cleaning', priority: 'medium', createdAt: new Date() },
  { id: 'ft-7', type: 'family', title: 'Practice piano', assigneeId: 'emma', dueDate: new Date(Date.now() + 86400000), completed: false, recurrence: 'daily', category: 'other', priority: 'medium', createdAt: new Date() },
  { id: 'ft-8', type: 'family', title: 'Mow the lawn', assigneeId: 'bob', dueDate: new Date(Date.now() + 172800000), completed: false, recurrence: 'weekly', category: 'home', priority: 'low', createdAt: new Date() },
];

// Mock manager tasks with enhanced statuses
const mockManagerTasks: ManagerTask[] = [
  {
    id: 'mt-1',
    type: 'manager',
    title: 'Book anniversary dinner at La Maison',
    description: 'Need a table for 2 on Dec 28th around 7pm. Prefer window seat.',
    status: 'completed',
    dueDate: new Date(Date.now() + 604800000),
    recurrence: 'yearly',
    category: 'dining',
    priority: 'high',
    createdAt: new Date(Date.now() - 172800000),
    lastUpdate: new Date(Date.now() - 7200000),
    statusHistory: [
      { status: 'sent', timestamp: new Date(Date.now() - 172800000) },
      { status: 'viewed', timestamp: new Date(Date.now() - 172000000) },
      { status: 'researching', timestamp: new Date(Date.now() - 129600000), note: 'Checking availability for Dec 28' },
      { status: 'in_progress', timestamp: new Date(Date.now() - 86400000), note: 'Called restaurant, window seats available' },
      { status: 'completed', timestamp: new Date(Date.now() - 7200000), note: 'Reservation confirmed for Dec 28 at 7:15pm. Window table secured!' },
    ],
    managerNote: 'Reservation confirmed for Dec 28 at 7:15pm. Window table secured!',
    needsReview: true,
  },
  {
    id: 'mt-2',
    type: 'manager',
    title: 'Research summer camps for Emma',
    description: 'Looking for STEM-focused camps, 2 weeks in July, budget $2000',
    status: 'researching',
    dueDate: new Date(Date.now() + 2592000000),
    recurrence: 'none',
    category: 'research',
    priority: 'medium',
    createdAt: new Date(Date.now() - 86400000),
    lastUpdate: new Date(Date.now() - 14400000),
    statusHistory: [
      { status: 'sent', timestamp: new Date(Date.now() - 86400000) },
      { status: 'viewed', timestamp: new Date(Date.now() - 82800000) },
      { status: 'researching', timestamp: new Date(Date.now() - 43200000), note: "Found 5 potential camps. Reviewing curriculum and reviews." },
    ],
    managerNote: "Found 5 potential camps. Reviewing curriculum and reviews. Will have recommendations by tomorrow.",
  },
  {
    id: 'mt-3',
    type: 'manager',
    title: 'Get quotes for driveway reseal',
    description: 'Driveway is cracking, need 3 quotes from reputable companies',
    status: 'in_progress',
    recurrence: 'none',
    category: 'quotes',
    priority: 'low',
    createdAt: new Date(Date.now() - 259200000),
    lastUpdate: new Date(Date.now() - 86400000),
    statusHistory: [
      { status: 'sent', timestamp: new Date(Date.now() - 259200000) },
      { status: 'viewed', timestamp: new Date(Date.now() - 255600000) },
      { status: 'researching', timestamp: new Date(Date.now() - 172800000), note: 'Identifying top-rated contractors in area' },
      { status: 'in_progress', timestamp: new Date(Date.now() - 86400000), note: 'Got 2 quotes so far, waiting on one more' },
    ],
    managerNote: 'Got 2 quotes so far ($1,200 and $1,450). Waiting on third quote from ABC Paving.',
  },
  {
    id: 'mt-4',
    type: 'manager',
    title: "Order flowers for Mom's birthday",
    description: 'Her favorite: pink peonies. Deliver to her house on Jan 15.',
    status: 'viewed',
    dueDate: new Date(Date.now() + 2160000000),
    recurrence: 'yearly',
    category: 'gifts',
    priority: 'high',
    createdAt: new Date(Date.now() - 600000),
    lastUpdate: new Date(Date.now() - 300000),
    statusHistory: [
      { status: 'sent', timestamp: new Date(Date.now() - 600000) },
      { status: 'viewed', timestamp: new Date(Date.now() - 300000) },
    ],
  },
  {
    id: 'mt-5',
    type: 'manager',
    title: 'Book ski trip flights',
    description: 'Family of 4, Feb 15-22, to Denver. Prefer morning departures.',
    status: 'waiting_approval',
    dueDate: new Date(Date.now() + 1209600000),
    recurrence: 'none',
    category: 'travel',
    priority: 'high',
    createdAt: new Date(Date.now() - 259200000),
    lastUpdate: new Date(Date.now() - 3600000),
    statusHistory: [
      { status: 'sent', timestamp: new Date(Date.now() - 259200000) },
      { status: 'viewed', timestamp: new Date(Date.now() - 255600000) },
      { status: 'researching', timestamp: new Date(Date.now() - 172800000), note: 'Comparing United, Southwest, and Frontier options' },
      { status: 'in_progress', timestamp: new Date(Date.now() - 86400000), note: 'Found best option: United, $1,850 total' },
      { status: 'waiting_approval', timestamp: new Date(Date.now() - 3600000), note: 'Ready to book United flights for $1,850. Depart 8:15am, return 10:30am. Want me to proceed?' },
    ],
    managerNote: 'Ready to book United flights for $1,850. Depart 8:15am, return 10:30am. Want me to proceed?',
    needsReview: true,
  },
];

// Mock activity feed
const mockActivity: ActivityItem[] = [
  { id: 'a-1', type: 'completed', taskTitle: 'Book anniversary dinner', timestamp: new Date(Date.now() - 7200000), managerName: 'Sarah' },
  { id: 'a-2', type: 'researching', taskTitle: 'Research summer camps', timestamp: new Date(Date.now() - 14400000), managerName: 'Sarah' },
  { id: 'a-3', type: 'started', taskTitle: 'Get driveway quotes', timestamp: new Date(Date.now() - 86400000), managerName: 'Sarah' },
  { id: 'a-4', type: 'message', taskTitle: 'Ski trip flights', timestamp: new Date(Date.now() - 3600000), managerName: 'Sarah' },
  { id: 'a-5', type: 'viewed', taskTitle: "Mom's birthday flowers", timestamp: new Date(Date.now() - 300000), managerName: 'Sarah' },
];

export default function TasksPage() {
  // State
  const [viewTab, setViewTab] = useState<ViewTab>('household');
  const [familyTasks, setFamilyTasks] = useState<FamilyTask[]>(mockFamilyTasks);
  const [managerTasks, setManagerTasks] = useState<ManagerTask[]>(mockManagerTasks);
  const [family] = useState<FamilyMember[]>(mockFamily);
  const [activity] = useState<ActivityItem[]>(mockActivity);

  // Quick add state
  const [newTaskInput, setNewTaskInput] = useState('');
  const [newTaskAssignee, setNewTaskAssignee] = useState<'family' | 'manager'>('family');
  const [newTaskAssigneeId, setNewTaskAssigneeId] = useState<string>('');
  const [showAddModal, setShowAddModal] = useState(false);
  const [showTaskDetail, setShowTaskDetail] = useState<Task | null>(null);
  const [showConfetti, setShowConfetti] = useState<string | null>(null);
  const [showDelegateConfirm, setShowDelegateConfirm] = useState<string | null>(null);
  const [showTemplates, setShowTemplates] = useState(false);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'info' } | null>(null);

  // Smart suggestion state
  const [suggestion, setSuggestion] = useState<'manager' | 'family' | null>(null);

  // Nudge days threshold
  const NUDGE_THRESHOLD_DAYS = 3;

  // Toast helper
  const showToast = (message: string, type: 'success' | 'info' = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  // Smart task suggestion based on input
  useEffect(() => {
    const input = newTaskInput.toLowerCase();
    if (!input || input.length < 3) {
      setSuggestion(null);
      return;
    }

    const isManagerTask = MANAGER_KEYWORDS.some(keyword => input.includes(keyword));
    const isFamilyTask = FAMILY_KEYWORDS.some(keyword => input.includes(keyword));

    if (isManagerTask && !isFamilyTask) {
      setSuggestion('manager');
    } else if (isFamilyTask && !isManagerTask) {
      setSuggestion('family');
    } else {
      setSuggestion(null);
    }
  }, [newTaskInput]);

  // Calculate weekly streak
  const weeklyStreak = useMemo(() => {
    return Math.max(...family.map(m => m.currentStreak));
  }, [family]);

  // Leaderboard
  const leaderboard = useMemo(() => {
    return [...family].sort((a, b) => b.tasksCompleted - a.tasksCompleted);
  }, [family]);

  // Group family tasks
  const groupedFamilyTasks = useMemo(() => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const todayTasks = familyTasks.filter(t => {
      if (!t.dueDate) return false;
      const taskDate = new Date(t.dueDate);
      taskDate.setHours(0, 0, 0, 0);
      return taskDate.getTime() === today.getTime();
    });

    const upcomingTasks = familyTasks.filter(t => {
      if (!t.dueDate) return true;
      const taskDate = new Date(t.dueDate);
      taskDate.setHours(0, 0, 0, 0);
      return taskDate.getTime() > today.getTime();
    });

    return { today: todayTasks, upcoming: upcomingTasks };
  }, [familyTasks]);

  // Manager tasks by status
  const managerTasksByStatus = useMemo(() => {
    return {
      needsApproval: managerTasks.filter(t => t.status === 'waiting_approval' || t.needsReview),
      inProgress: managerTasks.filter(t => ['researching', 'in_progress'].includes(t.status) && !t.needsReview),
      pending: managerTasks.filter(t => ['sent', 'viewed'].includes(t.status)),
      completed: managerTasks.filter(t => t.status === 'completed' && !t.needsReview),
    };
  }, [managerTasks]);

  // Check if task needs nudge
  const needsNudge = useCallback((task: ManagerTask) => {
    if (!task.lastUpdate) return false;
    const daysSinceUpdate = (Date.now() - task.lastUpdate.getTime()) / (1000 * 60 * 60 * 24);
    return daysSinceUpdate >= NUDGE_THRESHOLD_DAYS && !['completed', 'waiting_approval'].includes(task.status);
  }, []);

  // Get family member by ID
  const getMember = useCallback((id: string) => {
    return family.find(m => m.id === id);
  }, [family]);

  // Toggle task completion
  const toggleTaskComplete = useCallback((taskId: string) => {
    setFamilyTasks(prev => prev.map(task => {
      if (task.id !== taskId) return task;
      const newCompleted = !task.completed;
      if (newCompleted) {
        setShowConfetti(taskId);
        setTimeout(() => setShowConfetti(null), 1000);
      }
      return {
        ...task,
        completed: newCompleted,
        completedAt: newCompleted ? new Date() : undefined,
        completedBy: newCompleted ? task.assigneeId : undefined,
      };
    }));
  }, []);

  // Apply smart suggestion
  const applySuggestion = useCallback(() => {
    if (suggestion) {
      setNewTaskAssignee(suggestion);
      setSuggestion(null);
    }
  }, [suggestion]);

  // Add new task
  const handleAddTask = useCallback(() => {
    if (!newTaskInput.trim()) return;

    if (newTaskAssignee === 'family') {
      const newTask: FamilyTask = {
        id: `ft-new-${Date.now()}`,
        type: 'family',
        title: newTaskInput,
        assigneeId: newTaskAssigneeId || undefined,
        dueDate: new Date(),
        completed: false,
        recurrence: 'none',
        priority: 'medium',
        createdAt: new Date(),
      };
      setFamilyTasks(prev => [newTask, ...prev]);
      showToast('Task added!', 'success');
    } else {
      const newTask: ManagerTask = {
        id: `mt-new-${Date.now()}`,
        type: 'manager',
        title: newTaskInput,
        status: 'sent',
        recurrence: 'none',
        priority: 'medium',
        createdAt: new Date(),
        lastUpdate: new Date(),
        statusHistory: [{ status: 'sent', timestamp: new Date() }],
      };
      setManagerTasks(prev => [newTask, ...prev]);
      setShowDelegateConfirm(newTask.id);
      setTimeout(() => setShowDelegateConfirm(null), 3000);
    }

    setNewTaskInput('');
    setNewTaskAssigneeId('');
    setShowAddModal(false);
    setShowTemplates(false);
  }, [newTaskInput, newTaskAssignee, newTaskAssigneeId]);

  // Quick delegate with template
  const handleTemplateSelect = useCallback((template: TaskTemplate) => {
    setNewTaskInput(template.placeholder);
    setNewTaskAssignee('manager');
    setShowTemplates(false);
  }, []);

  // Delegate task to manager
  const delegateTask = useCallback((task: FamilyTask) => {
    // Remove from family tasks
    setFamilyTasks(prev => prev.filter(t => t.id !== task.id));

    // Add to manager tasks
    const managerTask: ManagerTask = {
      id: `mt-delegated-${Date.now()}`,
      type: 'manager',
      title: task.title,
      status: 'sent',
      recurrence: task.recurrence,
      category: task.category,
      priority: task.priority,
      createdAt: new Date(),
      lastUpdate: new Date(),
      statusHistory: [{ status: 'sent', timestamp: new Date() }],
    };
    setManagerTasks(prev => [managerTask, ...prev]);

    // Show confirmation
    setShowDelegateConfirm(managerTask.id);
    setTimeout(() => setShowDelegateConfirm(null), 3000);

    // Switch to manager tab
    setViewTab('manager');
  }, []);

  // Nudge manager
  const handleNudge = useCallback((taskId: string) => {
    setManagerTasks(prev => prev.map(t =>
      t.id === taskId ? { ...t, lastUpdate: new Date() } : t
    ));
    showToast('Reminder sent to Sarah!', 'success');
  }, []);

  // Approve/review task
  const handleApproveTask = useCallback((taskId: string) => {
    setManagerTasks(prev => prev.map(t => {
      if (t.id !== taskId) return t;
      return {
        ...t,
        status: 'completed' as TaskStatus,
        needsReview: false,
        statusHistory: [...t.statusHistory, { status: 'completed' as TaskStatus, timestamp: new Date(), note: 'Approved by homeowner' }],
      };
    }));
    showToast('Approved! Sarah will proceed.', 'success');
  }, []);

  // Request changes
  const handleRequestChanges = useCallback((taskId: string) => {
    setManagerTasks(prev => prev.map(t => {
      if (t.id !== taskId) return t;
      return {
        ...t,
        status: 'in_progress' as TaskStatus,
        needsReview: false,
        lastUpdate: new Date(),
        statusHistory: [...t.statusHistory, { status: 'in_progress' as TaskStatus, timestamp: new Date(), note: 'Homeowner requested changes' }],
      };
    }));
    showToast('Sarah has been notified of your feedback.', 'info');
  }, []);

  // Delete task
  const deleteTask = useCallback((task: Task) => {
    if (task.type === 'family') {
      setFamilyTasks(prev => prev.filter(t => t.id !== task.id));
    } else {
      setManagerTasks(prev => prev.filter(t => t.id !== task.id));
    }
    setShowTaskDetail(null);
  }, []);

  // Get status badge with enhanced statuses
  const getStatusBadge = (status: TaskStatus) => {
    switch (status) {
      case 'sent':
        return <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-warm-100 text-warm-700"><Send className="w-3 h-3" /> Sent</span>;
      case 'viewed':
        return <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-700"><Eye className="w-3 h-3" /> Viewed</span>;
      case 'researching':
        return <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-purple-100 text-purple-700"><Search className="w-3 h-3" /> Researching</span>;
      case 'in_progress':
        return <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-700"><Loader2 className="w-3 h-3 animate-spin" /> In Progress</span>;
      case 'waiting_approval':
        return <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-orange-100 text-orange-700"><AlertCircle className="w-3 h-3" /> Needs Approval</span>;
      case 'completed':
        return <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-emerald-100 text-emerald-700"><CheckCircle2 className="w-3 h-3" /> Completed</span>;
      default:
        return null;
    }
  };

  // Format relative time
  const formatRelativeTime = (date: Date) => {
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);
    const days = Math.floor(diff / 86400000);

    if (minutes < 1) return 'Just now';
    if (minutes < 60) return `${minutes}m ago`;
    if (hours < 24) return `${hours}h ago`;
    return `${days}d ago`;
  };

  return (
    <div className="min-h-screen bg-warm-50">
      {/* Toast */}
      {toast && (
        <div className="fixed top-4 right-4 z-50 animate-slide-down">
          <div className={`flex items-center gap-3 px-4 py-3 rounded-lg shadow-lg ${
            toast.type === 'success' ? 'bg-emerald-600 text-white' : 'bg-warm-800 text-white'
          }`}>
            {toast.type === 'success' ? <CheckCircle2 className="w-5 h-5" /> : <AlertCircle className="w-5 h-5" />}
            <span className="font-medium">{toast.message}</span>
          </div>
        </div>
      )}

      {/* Delegate Confirmation Toast */}
      {showDelegateConfirm && (
        <div className="fixed top-4 left-1/2 -tranwarm-x-1/2 z-50 animate-slide-down">
          <div className="flex items-center gap-3 px-5 py-3 bg-emerald-600 text-white rounded-xl shadow-lg">
            <div className="w-8 h-8 bg-white/20 rounded-full flex items-center justify-center">
              <Briefcase className="w-5 h-5" />
            </div>
            <div>
              <p className="font-semibold">Sarah will handle this</p>
              <p className="text-sm text-emerald-100">She&apos;ll update you as she makes progress</p>
            </div>
          </div>
        </div>
      )}

      {/* Header */}
      <div className="bg-white border-b border-warm-200 sticky top-0 z-30">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-warm-900">Tasks</h1>
              <p className="text-sm text-warm-500 mt-0.5">Household & Manager Operations</p>
            </div>

            <div className="flex items-center gap-3">
              {/* Add Errand Button */}
              <button
                onClick={() => {
                  setNewTaskAssignee('manager');
                  setShowAddModal(true);
                }}
                className="flex items-center gap-2 px-4 py-2 bg-haven-600 text-white font-medium rounded-xl hover:bg-haven-700 transition-colors"
              >
                <Plus className="w-5 h-5" />
                <span className="hidden sm:inline">Add Errand</span>
              </button>

              {/* Streak Badge */}
              <div className="flex items-center gap-2 px-3 py-1.5 bg-orange-50 border border-orange-200 rounded-full">
                <Flame className="w-5 h-5 text-orange-500" />
                <span className="text-sm font-semibold text-orange-700">{weeklyStreak} day streak</span>
              </div>
            </div>
          </div>

          {/* Tabs */}
          <div className="mt-4 flex gap-1 bg-warm-100 rounded-lg p-1">
            <button
              onClick={() => setViewTab('household')}
              className={`flex-1 flex items-center justify-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-colors ${
                viewTab === 'household'
                  ? 'bg-white text-warm-900 shadow-sm'
                  : 'text-warm-600 hover:text-warm-900'
              }`}
            >
              <Users className="w-4 h-4" />
              Household
            </button>
            <button
              onClick={() => setViewTab('manager')}
              className={`flex-1 flex items-center justify-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-colors relative ${
                viewTab === 'manager'
                  ? 'bg-white text-warm-900 shadow-sm'
                  : 'text-warm-600 hover:text-warm-900'
              }`}
            >
              <Briefcase className="w-4 h-4" />
              Manager Queue
              {managerTasksByStatus.needsApproval.length > 0 && (
                <span className="ml-1 px-1.5 py-0.5 text-xs bg-orange-500 text-white rounded-full">
                  {managerTasksByStatus.needsApproval.length}
                </span>
              )}
            </button>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        {/* Quick Add Bar */}
        <div className="bg-white rounded-xl shadow-sm border border-warm-200 p-4 mb-6">
          <div className="flex flex-col sm:flex-row gap-3">
            <div className="flex-1 relative">
              <input
                type="text"
                value={newTaskInput}
                onChange={(e) => setNewTaskInput(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleAddTask()}
                placeholder="What needs to get done?"
                className="w-full px-4 py-3 pr-24 border border-warm-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent text-warm-800 placeholder:text-warm-400"
              />
              {newTaskAssignee === 'manager' && (
                <div className="absolute right-3 top-1/2 -translate-y-1/2 flex gap-1">
                  <button className="p-1.5 hover:bg-warm-100 rounded-lg transition-colors text-warm-400 hover:text-warm-600">
                    <Camera className="w-5 h-5" />
                  </button>
                  <button className="p-1.5 hover:bg-warm-100 rounded-lg transition-colors text-warm-400 hover:text-warm-600">
                    <Mic className="w-5 h-5" />
                  </button>
                </div>
              )}
            </div>

            {/* Assignee Toggle */}
            <div className="flex gap-2">
              <div className="flex bg-warm-100 rounded-lg p-1">
                <button
                  onClick={() => setNewTaskAssignee('family')}
                  className={`flex items-center gap-2 px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                    newTaskAssignee === 'family'
                      ? 'bg-white text-warm-900 shadow-sm'
                      : 'text-warm-600'
                  }`}
                >
                  <Users className="w-4 h-4" />
                  Family
                </button>
                <button
                  onClick={() => setNewTaskAssignee('manager')}
                  className={`flex items-center gap-2 px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                    newTaskAssignee === 'manager'
                      ? 'bg-emerald-600 text-white'
                      : 'text-warm-600'
                  }`}
                >
                  <Briefcase className="w-4 h-4" />
                  Manager
                </button>
              </div>

              <button
                onClick={handleAddTask}
                disabled={!newTaskInput.trim()}
                className="px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors font-medium shadow-sm disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <Plus className="w-5 h-5" />
              </button>
            </div>
          </div>

          {/* Smart Suggestion */}
          {suggestion && (
            <div className="mt-3 flex items-center gap-2 p-3 bg-amber-50 border border-amber-200 rounded-lg">
              <Lightbulb className="w-5 h-5 text-amber-600 flex-shrink-0" />
              <p className="text-sm text-amber-800 flex-1">
                {suggestion === 'manager'
                  ? "This sounds like something your manager can handle"
                  : "This sounds like a family task"}
              </p>
              <button
                onClick={applySuggestion}
                className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                  suggestion === 'manager'
                    ? 'bg-emerald-600 text-white hover:bg-emerald-700'
                    : 'bg-warm-800 text-white hover:bg-warm-900'
                }`}
              >
                {suggestion === 'manager' ? 'Send to Manager' : 'Assign to Family'}
              </button>
            </div>
          )}

          {/* Family Assignee Selection */}
          {newTaskAssignee === 'family' && !suggestion && (
            <div className="mt-3">
              <span className="text-sm text-warm-500 block mb-2 sm:inline sm:mb-0 sm:mr-2">Assign to:</span>
              <div className="flex overflow-x-auto no-scrollbar gap-2 pb-2 pr-4 -mr-4">
                <button
                  onClick={() => setNewTaskAssigneeId('')}
                  className={`flex-shrink-0 px-3 py-1 rounded-full text-sm transition-colors ${
                    newTaskAssigneeId === ''
                      ? 'bg-warm-800 text-white'
                      : 'bg-warm-100 text-warm-600 hover:bg-warm-200'
                  }`}
                >
                  Anyone
                </button>
                {family.map(member => (
                  <button
                    key={member.id}
                    onClick={() => setNewTaskAssigneeId(member.id)}
                    className={`flex-shrink-0 flex items-center gap-1.5 px-3 py-1 rounded-full text-sm transition-colors ${
                      newTaskAssigneeId === member.id
                        ? 'bg-warm-800 text-white'
                        : 'bg-warm-100 text-warm-600 hover:bg-warm-200'
                    }`}
                  >
                    <span className={`w-5 h-5 rounded-full ${member.color} flex items-center justify-center text-xs text-white font-medium`}>
                      {member.initials}
                    </span>
                    {member.name}
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Manager Templates */}
          {newTaskAssignee === 'manager' && !suggestion && (
            <div className="mt-3">
              <button
                onClick={() => setShowTemplates(!showTemplates)}
                className="flex items-center gap-2 text-sm text-emerald-600 hover:text-emerald-700 font-medium"
              >
                <ClipboardList className="w-4 h-4" />
                Quick templates
                <ChevronDown className={`w-4 h-4 transition-transform ${showTemplates ? 'rotate-180' : ''}`} />
              </button>

              {showTemplates && (
                <div className="mt-3 grid grid-cols-2 sm:grid-cols-3 gap-2">
                  {MANAGER_TEMPLATES.map(template => {
                    const Icon = template.icon;
                    return (
                      <button
                        key={template.id}
                        onClick={() => handleTemplateSelect(template)}
                        className="flex items-center gap-2 p-3 bg-warm-50 hover:bg-emerald-50 border border-warm-200 hover:border-emerald-300 rounded-lg text-left transition-colors"
                      >
                        <Icon className="w-5 h-5 text-warm-500" />
                        <span className="text-sm text-warm-700">{template.title}</span>
                      </button>
                    );
                  })}
                </div>
              )}
            </div>
          )}
        </div>

        <div className="flex flex-col lg:flex-row gap-6">
          {/* Main Content */}
          <div className="flex-1 lg:w-[60%]">
            {viewTab === 'household' ? (
              <>
                {/* Gamification Header */}
                <div className="bg-white rounded-xl shadow-sm border border-warm-200 p-4 mb-4">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="p-2 bg-amber-100 rounded-lg">
                        <Trophy className="w-5 h-5 text-amber-600" />
                      </div>
                      <div>
                        <h3 className="font-semibold text-warm-900">Weekly Leaderboard</h3>
                        <p className="text-sm text-warm-500">This week&apos;s top contributors</p>
                      </div>
                    </div>
                  </div>

                  <div className="mt-4 grid grid-cols-2 sm:grid-cols-4 gap-3">
                    {leaderboard.map((member, index) => (
                      <div
                        key={member.id}
                        className={`flex items-center gap-2 p-3 rounded-lg ${
                          index === 0 ? 'bg-amber-50 border border-amber-200' : 'bg-warm-50'
                        }`}
                      >
                        <div className="relative">
                          <span className={`w-10 h-10 rounded-full ${member.color} flex items-center justify-center text-sm text-white font-medium`}>
                            {member.initials}
                          </span>
                          {index === 0 && (
                            <span className="absolute -top-1 -right-1 text-lg">👑</span>
                          )}
                        </div>
                        <div>
                          <div className="font-medium text-warm-900 text-sm">{member.name}</div>
                          <div className="text-xs text-warm-500">{member.tasksCompleted} tasks</div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Today's Tasks */}
                <div className="mb-4">
                  <h2 className="font-semibold text-warm-900 mb-3 flex items-center gap-2">
                    <Clock className="w-5 h-5 text-warm-400" />
                    Today
                    <span className="text-sm font-normal text-warm-500">
                      ({groupedFamilyTasks.today.filter(t => !t.completed).length} remaining)
                    </span>
                  </h2>

                  {groupedFamilyTasks.today.length === 0 ? (
                    <div className="bg-white rounded-xl shadow-sm border border-warm-200 p-8 text-center">
                      <PartyPopper className="w-12 h-12 text-emerald-500 mx-auto mb-3" />
                      <h3 className="text-lg font-medium text-warm-700">All caught up!</h3>
                      <p className="text-warm-500 mt-1">Relax, you deserve it.</p>
                    </div>
                  ) : (
                    <div className="space-y-2">
                      {groupedFamilyTasks.today.map(task => {
                        const assignee = task.assigneeId ? getMember(task.assigneeId) : null;
                        const CategoryIcon = (task.category && CATEGORY_ICONS[task.category]) || Sparkles;

                        return (
                          <div
                            key={task.id}
                            className={`bg-white rounded-xl shadow-sm border border-warm-200 p-4 transition-all ${
                              task.completed ? 'opacity-60' : ''
                            } ${showConfetti === task.id ? 'ring-2 ring-emerald-500 ring-offset-2' : ''}`}
                          >
                            <div className="flex items-center gap-3">
                              {/* Checkbox */}
                              <button
                                onClick={() => toggleTaskComplete(task.id)}
                                className={`w-7 h-7 rounded-full border-2 flex items-center justify-center flex-shrink-0 transition-all ${
                                  task.completed
                                    ? 'bg-emerald-600 border-emerald-600 text-white'
                                    : 'border-warm-300 hover:border-emerald-500'
                                }`}
                              >
                                {task.completed && <Check className="w-4 h-4" />}
                              </button>

                              {/* Category Icon */}
                              <div className="p-2 bg-warm-100 rounded-lg flex-shrink-0">
                                <CategoryIcon className="w-4 h-4 text-warm-600" />
                              </div>

                              {/* Task Content */}
                              <div className="flex-1 min-w-0">
                                <div className={`font-medium ${task.completed ? 'line-through text-warm-500' : 'text-warm-800'}`}>
                                  {task.title}
                                </div>
                                <div className="flex items-center gap-2 text-sm text-warm-500">
                                  {task.dueTime && <span>{task.dueTime}</span>}
                                  {task.recurrence !== 'none' && (
                                    <span className="flex items-center gap-1">
                                      <Repeat className="w-3 h-3" />
                                      {task.recurrence}
                                    </span>
                                  )}
                                </div>
                              </div>

                              {/* Assignee */}
                              {assignee && (
                                <span className={`w-8 h-8 rounded-full ${assignee.color} flex items-center justify-center text-xs text-white font-medium flex-shrink-0`}>
                                  {assignee.initials}
                                </span>
                              )}

                              {/* Hand Off Button */}
                              {!task.completed && (
                                <button
                                  onClick={() => delegateTask(task)}
                                  className="px-3 py-1.5 text-sm text-emerald-600 hover:bg-emerald-50 rounded-lg transition-colors flex items-center gap-1"
                                  title="Hand off to manager"
                                >
                                  <Share2 className="w-4 h-4" />
                                  <span className="hidden sm:inline">Hand Off</span>
                                </button>
                              )}

                              {/* More */}
                              <button
                                onClick={() => setShowTaskDetail(task)}
                                className="p-2 hover:bg-warm-100 rounded-lg transition-colors text-warm-400"
                              >
                                <MoreHorizontal className="w-5 h-5" />
                              </button>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  )}
                </div>

                {/* Upcoming Tasks */}
                {groupedFamilyTasks.upcoming.length > 0 && (
                  <div>
                    <h2 className="font-semibold text-warm-900 mb-3 flex items-center gap-2">
                      <Calendar className="w-5 h-5 text-warm-400" />
                      Upcoming
                    </h2>

                    <div className="space-y-2">
                      {groupedFamilyTasks.upcoming.map(task => {
                        const assignee = task.assigneeId ? getMember(task.assigneeId) : null;
                        const CategoryIcon = (task.category && CATEGORY_ICONS[task.category]) || Sparkles;

                        return (
                          <div
                            key={task.id}
                            className="bg-white rounded-xl shadow-sm border border-warm-200 p-4"
                          >
                            <div className="flex items-center gap-3">
                              <button
                                onClick={() => toggleTaskComplete(task.id)}
                                className="w-7 h-7 rounded-full border-2 border-warm-300 hover:border-emerald-500 flex items-center justify-center flex-shrink-0 transition-colors"
                              />

                              <div className="p-2 bg-warm-100 rounded-lg flex-shrink-0">
                                <CategoryIcon className="w-4 h-4 text-warm-600" />
                              </div>

                              <div className="flex-1 min-w-0">
                                <div className="font-medium text-warm-800">{task.title}</div>
                                <div className="flex items-center gap-2 text-sm text-warm-500">
                                  {task.dueDate && (
                                    <span>
                                      {task.dueDate.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' })}
                                    </span>
                                  )}
                                  {task.recurrence !== 'none' && (
                                    <span className="flex items-center gap-1">
                                      <Repeat className="w-3 h-3" />
                                      {task.recurrence}
                                    </span>
                                  )}
                                </div>
                              </div>

                              {assignee && (
                                <span className={`w-8 h-8 rounded-full ${assignee.color} flex items-center justify-center text-xs text-white font-medium flex-shrink-0`}>
                                  {assignee.initials}
                                </span>
                              )}

                              <button
                                onClick={() => delegateTask(task)}
                                className="px-3 py-1.5 text-sm text-emerald-600 hover:bg-emerald-50 rounded-lg transition-colors flex items-center gap-1"
                              >
                                <Share2 className="w-4 h-4" />
                                <span className="hidden sm:inline">Hand Off</span>
                              </button>

                              <button
                                onClick={() => setShowTaskDetail(task)}
                                className="p-2 hover:bg-warm-100 rounded-lg transition-colors text-warm-400"
                              >
                                <MoreHorizontal className="w-5 h-5" />
                              </button>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </div>
                )}
              </>
            ) : (
              /* Manager Queue View */
              <>
                {managerTasks.length === 0 ? (
                  <div className="bg-white rounded-xl shadow-sm border border-warm-200 p-12 text-center">
                    <Briefcase className="w-16 h-16 text-warm-300 mx-auto mb-4" />
                    <h3 className="text-lg font-medium text-warm-700 mb-2">Your Manager is standing by</h3>
                    <p className="text-warm-500 max-w-sm mx-auto mb-6">
                      Delegate something to free up your time. Just type above and select &quot;Manager&quot;.
                    </p>

                    {/* Quick Templates */}
                    <div className="max-w-md mx-auto">
                      <p className="text-sm text-warm-500 mb-3">Or try a template:</p>
                      <div className="grid grid-cols-2 gap-2">
                        {MANAGER_TEMPLATES.slice(0, 4).map(template => {
                          const Icon = template.icon;
                          return (
                            <button
                              key={template.id}
                              onClick={() => {
                                handleTemplateSelect(template);
                                setNewTaskAssignee('manager');
                              }}
                              className="flex items-center gap-2 p-3 bg-warm-50 hover:bg-emerald-50 border border-warm-200 hover:border-emerald-300 rounded-lg text-left transition-colors"
                            >
                              <Icon className="w-4 h-4 text-warm-500" />
                              <span className="text-sm text-warm-700 truncate">{template.title}</span>
                            </button>
                          );
                        })}
                      </div>
                    </div>
                  </div>
                ) : (
                  <div className="space-y-6">
                    {/* Needs Approval */}
                    {managerTasksByStatus.needsApproval.length > 0 && (
                      <div>
                        <h2 className="font-semibold text-warm-900 mb-3 flex items-center gap-2">
                          <AlertCircle className="w-5 h-5 text-orange-500" />
                          Needs Your Approval
                          <span className="ml-1 px-2 py-0.5 text-xs bg-orange-100 text-orange-700 rounded-full">
                            {managerTasksByStatus.needsApproval.length}
                          </span>
                        </h2>
                        <div className="space-y-3">
                          {managerTasksByStatus.needsApproval.map(task => (
                            <div
                              key={task.id}
                              className="bg-orange-50 rounded-xl border border-orange-200 p-4"
                            >
                              <div className="flex items-start justify-between mb-3">
                                <div className="flex-1">
                                  <div className="flex items-center gap-2 mb-1">
                                    {getStatusBadge(task.status)}
                                    {task.priority === 'high' && (
                                      <span className="px-2 py-0.5 bg-red-100 text-red-700 text-xs rounded-full font-medium">Priority</span>
                                    )}
                                  </div>
                                  <h3 className="font-medium text-warm-900">{task.title}</h3>
                                </div>
                                {task.lastUpdate && (
                                  <span className="text-xs text-warm-500">
                                    Updated {formatRelativeTime(task.lastUpdate)}
                                  </span>
                                )}
                              </div>

                              {task.managerNote && (
                                <div className="p-3 bg-white rounded-lg border border-orange-100 mb-3">
                                  <div className="flex items-start gap-2">
                                    <div className="w-6 h-6 bg-emerald-200 rounded-full flex items-center justify-center flex-shrink-0">
                                      <span className="text-xs font-semibold text-emerald-700">S</span>
                                    </div>
                                    <div>
                                      <p className="text-xs text-emerald-700 font-medium mb-1">Sarah says:</p>
                                      <p className="text-sm text-warm-700">{task.managerNote}</p>
                                    </div>
                                  </div>
                                </div>
                              )}

                              <div className="flex gap-2">
                                <button
                                  onClick={() => handleApproveTask(task.id)}
                                  className="flex-1 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors font-medium text-sm"
                                >
                                  Approve
                                </button>
                                <button
                                  onClick={() => handleRequestChanges(task.id)}
                                  className="flex-1 px-4 py-2 border border-warm-300 rounded-lg hover:bg-white transition-colors text-warm-700 text-sm"
                                >
                                  Request Changes
                                </button>
                              </div>
                            </div>
                          ))}
                        </div>
                      </div>
                    )}

                    {/* In Progress */}
                    {managerTasksByStatus.inProgress.length > 0 && (
                      <div>
                        <h2 className="font-semibold text-warm-900 mb-3 flex items-center gap-2">
                          <Loader2 className="w-5 h-5 text-amber-500 animate-spin" />
                          In Progress
                        </h2>
                        <div className="space-y-2">
                          {managerTasksByStatus.inProgress.map(task => {
                            const CategoryIcon = (task.category && CATEGORY_ICONS[task.category]) || Sparkles;
                            const showNudgeButton = needsNudge(task);

                            return (
                              <div
                                key={task.id}
                                className="bg-emerald-50/30 rounded-xl border border-emerald-100 p-4"
                              >
                                <div className="flex items-start gap-3">
                                  <div className="p-2 bg-emerald-100 rounded-lg flex-shrink-0">
                                    <CategoryIcon className="w-5 h-5 text-emerald-600" />
                                  </div>
                                  <div className="flex-1 min-w-0">
                                    <div className="flex items-center gap-2 mb-1 flex-wrap">
                                      {getStatusBadge(task.status)}
                                      {task.priority === 'high' && (
                                        <span className="px-2 py-0.5 bg-red-100 text-red-700 text-xs rounded-full font-medium">Priority</span>
                                      )}
                                      {task.lastUpdate && (
                                        <span className="text-xs text-warm-500">
                                          Updated {formatRelativeTime(task.lastUpdate)}
                                        </span>
                                      )}
                                    </div>
                                    <h3 className="font-medium text-warm-900">{task.title}</h3>
                                    {task.managerNote && (
                                      <p className="text-sm text-warm-600 mt-1 p-2 bg-white/70 rounded-lg">{task.managerNote}</p>
                                    )}
                                    {task.dueDate && (
                                      <p className="text-sm text-warm-500 mt-2 flex items-center gap-1">
                                        <Calendar className="w-4 h-4" />
                                        Due {task.dueDate.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
                                      </p>
                                    )}
                                  </div>
                                  <div className="flex flex-col gap-2">
                                    {showNudgeButton && (
                                      <button
                                        onClick={() => handleNudge(task.id)}
                                        className="flex items-center gap-1 px-3 py-1.5 text-sm text-amber-600 bg-amber-100 hover:bg-amber-200 rounded-lg transition-colors"
                                      >
                                        <BellRing className="w-4 h-4" />
                                        Nudge
                                      </button>
                                    )}
                                    <button
                                      onClick={() => setShowTaskDetail(task)}
                                      className="flex items-center gap-1 px-3 py-1.5 text-sm text-emerald-600 hover:bg-emerald-100 rounded-lg transition-colors"
                                    >
                                      <MessageCircle className="w-4 h-4" />
                                      Message
                                    </button>
                                  </div>
                                </div>
                              </div>
                            );
                          })}
                        </div>
                      </div>
                    )}

                    {/* Pending (Sent/Viewed) */}
                    {managerTasksByStatus.pending.length > 0 && (
                      <div>
                        <h2 className="font-semibold text-warm-900 mb-3 flex items-center gap-2">
                          <Send className="w-5 h-5 text-warm-400" />
                          Recently Sent
                        </h2>
                        <div className="space-y-2">
                          {managerTasksByStatus.pending.map(task => {
                            const CategoryIcon = (task.category && CATEGORY_ICONS[task.category]) || Sparkles;

                            return (
                              <div
                                key={task.id}
                                className="bg-white rounded-xl border border-warm-200 p-4"
                              >
                                <div className="flex items-start gap-3">
                                  <div className="p-2 bg-warm-100 rounded-lg flex-shrink-0">
                                    <CategoryIcon className="w-5 h-5 text-warm-600" />
                                  </div>
                                  <div className="flex-1 min-w-0">
                                    <div className="flex items-center gap-2 mb-1">
                                      {getStatusBadge(task.status)}
                                      {task.recurrence !== 'none' && (
                                        <span className="flex items-center gap-1 text-xs text-warm-500">
                                          <Repeat className="w-3 h-3" />
                                          {task.recurrence}
                                        </span>
                                      )}
                                    </div>
                                    <h3 className="font-medium text-warm-900">{task.title}</h3>
                                    {task.description && (
                                      <p className="text-sm text-warm-600 mt-1">{task.description}</p>
                                    )}
                                  </div>
                                  <button
                                    onClick={() => setShowTaskDetail(task)}
                                    className="p-2 hover:bg-warm-100 rounded-lg transition-colors text-warm-400"
                                  >
                                    <MoreHorizontal className="w-5 h-5" />
                                  </button>
                                </div>
                              </div>
                            );
                          })}
                        </div>
                      </div>
                    )}

                    {/* Completed */}
                    {managerTasksByStatus.completed.length > 0 && (
                      <div>
                        <h2 className="font-semibold text-warm-900 mb-3 flex items-center gap-2">
                          <CheckCircle2 className="w-5 h-5 text-emerald-500" />
                          Recently Completed
                        </h2>
                        <div className="space-y-2">
                          {managerTasksByStatus.completed.map(task => (
                            <div
                              key={task.id}
                              className="bg-white rounded-xl border border-warm-200 p-4 opacity-75"
                            >
                              <div className="flex items-center gap-3">
                                <div className="p-2 bg-emerald-100 rounded-lg flex-shrink-0">
                                  <CheckCircle2 className="w-5 h-5 text-emerald-600" />
                                </div>
                                <div className="flex-1 min-w-0">
                                  <h3 className="font-medium text-warm-700 line-through">{task.title}</h3>
                                  {task.managerNote && (
                                    <p className="text-sm text-warm-500 mt-1">{task.managerNote}</p>
                                  )}
                                </div>
                              </div>
                            </div>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>
                )}
              </>
            )}
          </div>

          {/* Right Sidebar - Activity Feed (Desktop Only) */}
          <div className="hidden lg:block lg:w-[40%]">
            <div className="bg-white rounded-xl shadow-sm border border-warm-200 p-4 sticky top-32">
              <div className="flex items-center justify-between mb-4">
                <h2 className="font-semibold text-warm-900">Manager Activity</h2>
                <Bell className="w-5 h-5 text-warm-400" />
              </div>

              <div className="space-y-4">
                {activity.map(item => (
                  <div key={item.id} className="flex gap-3">
                    <div className={`w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 ${
                      item.type === 'completed' ? 'bg-emerald-100 text-emerald-600' :
                      item.type === 'started' ? 'bg-amber-100 text-amber-600' :
                      item.type === 'viewed' ? 'bg-blue-100 text-blue-600' :
                      item.type === 'researching' ? 'bg-purple-100 text-purple-600' :
                      'bg-warm-100 text-warm-600'
                    }`}>
                      {item.type === 'completed' && <CheckCircle2 className="w-4 h-4" />}
                      {item.type === 'started' && <Loader2 className="w-4 h-4" />}
                      {item.type === 'viewed' && <Eye className="w-4 h-4" />}
                      {item.type === 'researching' && <Search className="w-4 h-4" />}
                      {item.type === 'message' && <MessageCircle className="w-4 h-4" />}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm text-warm-800">
                        <span className="font-medium">{item.managerName}</span>
                        {item.type === 'completed' && ' completed '}
                        {item.type === 'started' && ' started working on '}
                        {item.type === 'viewed' && ' viewed '}
                        {item.type === 'researching' && ' is researching '}
                        {item.type === 'message' && ' sent an update about '}
                        <span className="font-medium">&quot;{item.taskTitle}&quot;</span>
                      </p>
                      <p className="text-xs text-warm-500 mt-0.5">{formatRelativeTime(item.timestamp)}</p>
                    </div>
                  </div>
                ))}
              </div>

              <button className="w-full mt-4 py-2 text-sm text-emerald-600 hover:bg-emerald-50 rounded-lg transition-colors font-medium">
                View All Activity
              </button>

              {/* Quick Help */}
              <div className="mt-4 pt-4 border-t border-warm-200">
                <div className="flex items-start gap-3 p-3 bg-warm-50 rounded-lg">
                  <HelpCircle className="w-5 h-5 text-warm-400 flex-shrink-0 mt-0.5" />
                  <div>
                    <p className="text-sm font-medium text-warm-700">Need something done?</p>
                    <p className="text-xs text-warm-500 mt-0.5">
                      Just describe it and Sarah will handle the rest.
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Task Detail Modal */}
      {showTaskDetail && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl max-w-lg w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6 border-b border-warm-200">
              <div className="flex items-center justify-between">
                <h2 className="text-xl font-bold text-warm-900">Task Details</h2>
                <button
                  onClick={() => setShowTaskDetail(null)}
                  className="p-2 hover:bg-warm-100 rounded-lg transition-colors"
                >
                  <X className="w-5 h-5 text-warm-500" />
                </button>
              </div>
            </div>

            <div className="p-6 space-y-4">
              {/* Status */}
              <div className="flex items-center gap-2 flex-wrap">
                {showTaskDetail.type === 'family' ? (
                  showTaskDetail.completed ? (
                    <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-sm font-medium bg-emerald-100 text-emerald-700">
                      <CheckCircle2 className="w-4 h-4" /> Completed
                    </span>
                  ) : (
                    <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-sm font-medium bg-warm-100 text-warm-700">
                      <Circle className="w-4 h-4" /> Pending
                    </span>
                  )
                ) : (
                  getStatusBadge(showTaskDetail.status)
                )}
                {showTaskDetail.recurrence !== 'none' && (
                  <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-sm font-medium bg-purple-100 text-purple-700">
                    <Repeat className="w-4 h-4" /> {showTaskDetail.recurrence}
                  </span>
                )}
              </div>

              {/* Title */}
              <h3 className="text-lg font-semibold text-warm-900">{showTaskDetail.title}</h3>

              {/* Description (Manager tasks) */}
              {showTaskDetail.type === 'manager' && showTaskDetail.description && (
                <p className="text-warm-600">{showTaskDetail.description}</p>
              )}

              {/* Assignee (Family tasks) */}
              {showTaskDetail.type === 'family' && showTaskDetail.assigneeId && (
                <div className="flex items-center gap-2">
                  <span className="text-sm text-warm-500">Assigned to:</span>
                  {(() => {
                    const member = getMember(showTaskDetail.assigneeId);
                    if (!member) return null;
                    return (
                      <span className="flex items-center gap-1.5">
                        <span className={`w-6 h-6 rounded-full ${member.color} flex items-center justify-center text-xs text-white font-medium`}>
                          {member.initials}
                        </span>
                        <span className="font-medium text-warm-800">{member.name}</span>
                      </span>
                    );
                  })()}
                </div>
              )}

              {/* Due Date */}
              {showTaskDetail.dueDate && (
                <div className="flex items-center gap-2 text-warm-600">
                  <Calendar className="w-4 h-4" />
                  <span>
                    Due {showTaskDetail.dueDate.toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' })}
                  </span>
                </div>
              )}

              {/* Status Timeline (Manager tasks) */}
              {showTaskDetail.type === 'manager' && showTaskDetail.statusHistory.length > 0 && (
                <div className="border-t border-warm-200 pt-4 mt-4">
                  <h4 className="text-sm font-medium text-warm-700 mb-3">Status Timeline</h4>
                  <div className="space-y-3">
                    {showTaskDetail.statusHistory.map((entry, index) => (
                      <div key={index} className="flex items-start gap-3">
                        <div className={`w-2 h-2 rounded-full mt-1.5 ${
                          entry.status === 'completed' ? 'bg-emerald-500' :
                          entry.status === 'waiting_approval' ? 'bg-orange-500' :
                          entry.status === 'in_progress' ? 'bg-amber-500' :
                          entry.status === 'researching' ? 'bg-purple-500' :
                          entry.status === 'viewed' ? 'bg-blue-500' :
                          'bg-warm-400'
                        }`} />
                        <div className="flex-1">
                          <div className="flex items-center justify-between">
                            <span className="text-sm font-medium text-warm-800 capitalize">{entry.status.replace('_', ' ')}</span>
                            <span className="text-xs text-warm-500">{formatRelativeTime(entry.timestamp)}</span>
                          </div>
                          {entry.note && (
                            <p className="text-sm text-warm-600 mt-1">{entry.note}</p>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>

            <div className="p-6 border-t border-warm-200 bg-warm-50 rounded-b-xl">
              <div className="flex gap-3">
                <button
                  onClick={() => deleteTask(showTaskDetail)}
                  className="px-4 py-2.5 border border-red-300 text-red-600 rounded-lg hover:bg-red-50 transition-colors font-medium flex items-center gap-2"
                >
                  <Trash2 className="w-4 h-4" />
                  Delete
                </button>
                <div className="flex-1" />
                {showTaskDetail.type === 'family' && !showTaskDetail.completed && (
                  <button
                    onClick={() => {
                      delegateTask(showTaskDetail as FamilyTask);
                      setShowTaskDetail(null);
                    }}
                    className="px-4 py-2.5 border border-emerald-300 text-emerald-600 rounded-lg hover:bg-emerald-50 transition-colors font-medium flex items-center gap-2"
                  >
                    <Share2 className="w-4 h-4" />
                    Hand Off to Sarah
                  </button>
                )}
                {showTaskDetail.type === 'manager' && (
                  <button
                    onClick={() => showToast('Opening chat with Sarah...', 'info')}
                    className="px-4 py-2.5 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors font-medium flex items-center gap-2"
                  >
                    <MessageCircle className="w-4 h-4" />
                    Message Sarah
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Mobile FAB */}
      <button
        onClick={() => setShowAddModal(true)}
        className="fixed bottom-36 right-4 lg:hidden w-12 h-12 bg-emerald-600 text-white rounded-full shadow-lg hover:bg-emerald-700 transition-colors flex items-center justify-center z-40"
      >
        <Plus className="w-5 h-5" />
      </button>

      {/* Add Task Modal (Mobile) */}
      {showAddModal && (
        <div className="fixed inset-0 bg-black/50 flex items-end justify-center z-50 md:hidden">
          <div className="bg-white rounded-t-xl w-full max-h-[80vh] overflow-y-auto animate-slide-up">
            <div className="p-4 border-b border-warm-200 sticky top-0 bg-white">
              <div className="flex items-center justify-between">
                <h2 className="text-lg font-bold text-warm-900">New Task</h2>
                <button
                  onClick={() => setShowAddModal(false)}
                  className="p-2 hover:bg-warm-100 rounded-lg transition-colors"
                >
                  <X className="w-5 h-5 text-warm-500" />
                </button>
              </div>
            </div>

            <div className="p-4 space-y-4">
              <input
                type="text"
                value={newTaskInput}
                onChange={(e) => setNewTaskInput(e.target.value)}
                placeholder="What needs to get done?"
                autoFocus
                className="w-full px-4 py-3 border border-warm-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent text-lg"
              />

              {/* Smart Suggestion */}
              {suggestion && (
                <div className="flex items-center gap-2 p-3 bg-amber-50 border border-amber-200 rounded-lg">
                  <Lightbulb className="w-5 h-5 text-amber-600 flex-shrink-0" />
                  <p className="text-sm text-amber-800 flex-1">
                    {suggestion === 'manager'
                      ? "This sounds like something your manager can handle"
                      : "This sounds like a family task"}
                  </p>
                  <button
                    onClick={applySuggestion}
                    className={`px-3 py-1.5 rounded-lg text-sm font-medium ${
                      suggestion === 'manager'
                        ? 'bg-emerald-600 text-white'
                        : 'bg-warm-800 text-white'
                    }`}
                  >
                    Apply
                  </button>
                </div>
              )}

              <div>
                <label className="block text-sm font-medium text-warm-700 mb-2">Assign to:</label>
                <div className="flex gap-2">
                  <button
                    onClick={() => setNewTaskAssignee('family')}
                    className={`flex-1 flex items-center justify-center gap-2 px-4 py-3 rounded-lg border-2 transition-colors ${
                      newTaskAssignee === 'family'
                        ? 'border-warm-800 bg-warm-50'
                        : 'border-warm-200'
                    }`}
                  >
                    <Users className="w-5 h-5" />
                    Family
                  </button>
                  <button
                    onClick={() => setNewTaskAssignee('manager')}
                    className={`flex-1 flex items-center justify-center gap-2 px-4 py-3 rounded-lg border-2 transition-colors ${
                      newTaskAssignee === 'manager'
                        ? 'border-emerald-600 bg-emerald-50 text-emerald-700'
                        : 'border-warm-200'
                    }`}
                  >
                    <Briefcase className="w-5 h-5" />
                    Manager
                  </button>
                </div>
              </div>

              {newTaskAssignee === 'family' && (
                <div>
                  <label className="block text-sm font-medium text-warm-700 mb-2">Family member:</label>
                  <div className="grid grid-cols-2 gap-2">
                    <button
                      onClick={() => setNewTaskAssigneeId('')}
                      className={`flex items-center gap-2 px-3 py-2 rounded-lg border transition-colors ${
                        newTaskAssigneeId === ''
                          ? 'border-warm-800 bg-warm-50'
                          : 'border-warm-200'
                      }`}
                    >
                      <Users className="w-5 h-5 text-warm-500" />
                      Anyone
                    </button>
                    {family.map(member => (
                      <button
                        key={member.id}
                        onClick={() => setNewTaskAssigneeId(member.id)}
                        className={`flex items-center gap-2 px-3 py-2 rounded-lg border transition-colors ${
                          newTaskAssigneeId === member.id
                            ? 'border-warm-800 bg-warm-50'
                            : 'border-warm-200'
                        }`}
                      >
                        <span className={`w-6 h-6 rounded-full ${member.color} flex items-center justify-center text-xs text-white font-medium`}>
                          {member.initials}
                        </span>
                        {member.name}
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {newTaskAssignee === 'manager' && (
                <>
                  <div className="flex gap-2">
                    <button className="flex-1 flex items-center justify-center gap-2 px-4 py-3 border border-warm-300 rounded-lg hover:bg-warm-50 transition-colors text-warm-700">
                      <Camera className="w-5 h-5" />
                      Add Photo
                    </button>
                    <button className="flex-1 flex items-center justify-center gap-2 px-4 py-3 border border-warm-300 rounded-lg hover:bg-warm-50 transition-colors text-warm-700">
                      <Mic className="w-5 h-5" />
                      Voice Note
                    </button>
                  </div>

                  {/* Quick Templates */}
                  <div>
                    <p className="text-sm text-warm-500 mb-2">Quick templates:</p>
                    <div className="grid grid-cols-2 gap-2">
                      {MANAGER_TEMPLATES.slice(0, 4).map(template => {
                        const Icon = template.icon;
                        return (
                          <button
                            key={template.id}
                            onClick={() => handleTemplateSelect(template)}
                            className="flex items-center gap-2 p-2 bg-warm-50 hover:bg-emerald-50 border border-warm-200 rounded-lg text-left transition-colors"
                          >
                            <Icon className="w-4 h-4 text-warm-500" />
                            <span className="text-xs text-warm-700 truncate">{template.title}</span>
                          </button>
                        );
                      })}
                    </div>
                  </div>
                </>
              )}

              <button
                onClick={handleAddTask}
                disabled={!newTaskInput.trim()}
                className="w-full py-3 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors font-medium disabled:opacity-50"
              >
                {newTaskAssignee === 'manager' ? 'Send to Sarah' : 'Add Task'}
              </button>
            </div>
          </div>
        </div>
      )}

      <style jsx>{`
        @keyframes slide-up {
          from {
            transform: translateY(100%);
          }
          to {
            transform: translateY(0);
          }
        }
        .animate-slide-up {
          animation: slide-up 0.3s ease-out;
        }
        @keyframes slide-down {
          from {
            transform: translateY(-100%);
            opacity: 0;
          }
          to {
            transform: translateY(0);
            opacity: 1;
          }
        }
        .animate-slide-down {
          animation: slide-down 0.3s ease-out;
        }
      `}</style>
    </div>
  );
}
