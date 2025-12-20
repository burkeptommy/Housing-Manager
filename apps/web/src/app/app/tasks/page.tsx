'use client';

import { useState, useMemo, useCallback } from 'react';
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
} from 'lucide-react';

// Types
type TaskStatus = 'pending' | 'sent' | 'viewed' | 'in_progress' | 'completed';
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
}

type Task = FamilyTask | ManagerTask;

interface ActivityItem {
  id: string;
  type: 'completed' | 'started' | 'viewed' | 'message';
  taskTitle: string;
  timestamp: Date;
  managerName: string;
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
};

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

// Mock manager tasks
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
    statusHistory: [
      { status: 'sent', timestamp: new Date(Date.now() - 172800000) },
      { status: 'viewed', timestamp: new Date(Date.now() - 172000000) },
      { status: 'in_progress', timestamp: new Date(Date.now() - 86400000) },
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
    status: 'in_progress',
    dueDate: new Date(Date.now() + 2592000000),
    recurrence: 'none',
    category: 'other',
    priority: 'medium',
    createdAt: new Date(Date.now() - 86400000),
    statusHistory: [
      { status: 'sent', timestamp: new Date(Date.now() - 86400000) },
      { status: 'viewed', timestamp: new Date(Date.now() - 82800000) },
      { status: 'in_progress', timestamp: new Date(Date.now() - 43200000) },
    ],
  },
  {
    id: 'mt-3',
    type: 'manager',
    title: 'Get quotes for driveway reseal',
    description: 'Driveway is cracking, need 3 quotes from reputable companies',
    status: 'viewed',
    recurrence: 'none',
    category: 'home',
    priority: 'low',
    createdAt: new Date(Date.now() - 3600000),
    statusHistory: [
      { status: 'sent', timestamp: new Date(Date.now() - 3600000) },
      { status: 'viewed', timestamp: new Date(Date.now() - 1800000) },
    ],
  },
  {
    id: 'mt-4',
    type: 'manager',
    title: 'Order flowers for Mom\'s birthday',
    description: 'Her favorite: pink peonies. Deliver to her house on Jan 15.',
    status: 'sent',
    dueDate: new Date(Date.now() + 2160000000),
    recurrence: 'yearly',
    category: 'gifts',
    priority: 'high',
    createdAt: new Date(Date.now() - 600000),
    statusHistory: [
      { status: 'sent', timestamp: new Date(Date.now() - 600000) },
    ],
  },
  {
    id: 'mt-5',
    type: 'manager',
    title: 'Book ski trip flights',
    description: 'Family of 4, Feb 15-22, to Denver. Prefer morning departures.',
    status: 'in_progress',
    dueDate: new Date(Date.now() + 1209600000),
    recurrence: 'none',
    category: 'travel',
    priority: 'high',
    createdAt: new Date(Date.now() - 259200000),
    statusHistory: [
      { status: 'sent', timestamp: new Date(Date.now() - 259200000) },
      { status: 'viewed', timestamp: new Date(Date.now() - 255600000) },
      { status: 'in_progress', timestamp: new Date(Date.now() - 172800000) },
    ],
  },
];

// Mock activity feed
const mockActivity: ActivityItem[] = [
  { id: 'a-1', type: 'completed', taskTitle: 'Book anniversary dinner', timestamp: new Date(Date.now() - 7200000), managerName: 'Sarah' },
  { id: 'a-2', type: 'started', taskTitle: 'Research summer camps', timestamp: new Date(Date.now() - 43200000), managerName: 'Sarah' },
  { id: 'a-3', type: 'viewed', taskTitle: 'Get quotes for driveway', timestamp: new Date(Date.now() - 1800000), managerName: 'Sarah' },
  { id: 'a-4', type: 'message', taskTitle: 'Ski trip flights', timestamp: new Date(Date.now() - 86400000), managerName: 'Sarah' },
  { id: 'a-5', type: 'completed', taskTitle: 'Renew gym membership', timestamp: new Date(Date.now() - 172800000), managerName: 'Sarah' },
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
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

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
      pending: managerTasks.filter(t => t.status === 'sent' || t.status === 'viewed'),
      inProgress: managerTasks.filter(t => t.status === 'in_progress'),
      completed: managerTasks.filter(t => t.status === 'completed'),
    };
  }, [managerTasks]);

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
    } else {
      const newTask: ManagerTask = {
        id: `mt-new-${Date.now()}`,
        type: 'manager',
        title: newTaskInput,
        status: 'sent',
        recurrence: 'none',
        priority: 'medium',
        createdAt: new Date(),
        statusHistory: [{ status: 'sent', timestamp: new Date() }],
      };
      setManagerTasks(prev => [newTask, ...prev]);
    }

    setNewTaskInput('');
    setNewTaskAssigneeId('');
    setShowAddModal(false);
  }, [newTaskInput, newTaskAssignee, newTaskAssigneeId]);

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
      statusHistory: [{ status: 'sent', timestamp: new Date() }],
    };
    setManagerTasks(prev => [managerTask, ...prev]);

    // Switch to manager tab
    setViewTab('manager');
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

  // Get status badge
  const getStatusBadge = (status: TaskStatus) => {
    switch (status) {
      case 'sent':
        return <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-slate-100 text-slate-700"><Send className="w-3 h-3" /> Sent</span>;
      case 'viewed':
        return <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-700"><Eye className="w-3 h-3" /> Viewed</span>;
      case 'in_progress':
        return <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-700"><Loader2 className="w-3 h-3 animate-spin" /> In Progress</span>;
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
    <div className="min-h-screen bg-slate-50">
      {/* Header */}
      <div className="bg-white border-b border-slate-200 sticky top-0 z-30">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-slate-900">Tasks</h1>
              <p className="text-sm text-slate-500 mt-0.5">Household & Manager Operations</p>
            </div>

            {/* Streak Badge */}
            <div className="flex items-center gap-2 px-3 py-1.5 bg-orange-50 border border-orange-200 rounded-full">
              <Flame className="w-5 h-5 text-orange-500" />
              <span className="text-sm font-semibold text-orange-700">{weeklyStreak} day streak</span>
            </div>
          </div>

          {/* Tabs */}
          <div className="mt-4 flex gap-1 bg-slate-100 rounded-lg p-1">
            <button
              onClick={() => setViewTab('household')}
              className={`flex-1 flex items-center justify-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-colors ${
                viewTab === 'household'
                  ? 'bg-white text-slate-900 shadow-sm'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <Users className="w-4 h-4" />
              Household
            </button>
            <button
              onClick={() => setViewTab('manager')}
              className={`flex-1 flex items-center justify-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-colors relative ${
                viewTab === 'manager'
                  ? 'bg-white text-slate-900 shadow-sm'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <Briefcase className="w-4 h-4" />
              Manager Queue
              {managerTasksByStatus.pending.length > 0 && (
                <span className="ml-1 px-1.5 py-0.5 text-xs bg-emerald-600 text-white rounded-full">
                  {managerTasksByStatus.pending.length}
                </span>
              )}
            </button>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        {/* Quick Add Bar */}
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4 mb-6">
          <div className="flex flex-col sm:flex-row gap-3">
            <div className="flex-1 relative">
              <input
                type="text"
                value={newTaskInput}
                onChange={(e) => setNewTaskInput(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleAddTask()}
                placeholder="What needs to get done?"
                className="w-full px-4 py-3 pr-24 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent text-slate-800 placeholder:text-slate-400"
              />
              {newTaskAssignee === 'manager' && (
                <div className="absolute right-3 top-1/2 -translate-y-1/2 flex gap-1">
                  <button className="p-1.5 hover:bg-slate-100 rounded-lg transition-colors text-slate-400 hover:text-slate-600">
                    <Camera className="w-5 h-5" />
                  </button>
                  <button className="p-1.5 hover:bg-slate-100 rounded-lg transition-colors text-slate-400 hover:text-slate-600">
                    <Mic className="w-5 h-5" />
                  </button>
                </div>
              )}
            </div>

            {/* Assignee Toggle */}
            <div className="flex gap-2">
              <div className="flex bg-slate-100 rounded-lg p-1">
                <button
                  onClick={() => setNewTaskAssignee('family')}
                  className={`flex items-center gap-2 px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                    newTaskAssignee === 'family'
                      ? 'bg-white text-slate-900 shadow-sm'
                      : 'text-slate-600'
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
                      : 'text-slate-600'
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

          {/* Family Assignee Selection */}
          {newTaskAssignee === 'family' && (
            <div className="mt-3">
              <span className="text-sm text-slate-500 block mb-2 sm:inline sm:mb-0 sm:mr-2">Assign to:</span>
              <div className="flex overflow-x-auto no-scrollbar gap-2 pb-2 pr-4 -mr-4">
                <button
                  onClick={() => setNewTaskAssigneeId('')}
                  className={`flex-shrink-0 px-3 py-1 rounded-full text-sm transition-colors ${
                    newTaskAssigneeId === ''
                      ? 'bg-slate-800 text-white'
                      : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
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
                        ? 'bg-slate-800 text-white'
                        : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
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
        </div>

        <div className="flex flex-col lg:flex-row gap-6">
          {/* Main Content */}
          <div className="flex-1 lg:w-[60%]">
            {viewTab === 'household' ? (
              <>
                {/* Gamification Header */}
                <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4 mb-4">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="p-2 bg-amber-100 rounded-lg">
                        <Trophy className="w-5 h-5 text-amber-600" />
                      </div>
                      <div>
                        <h3 className="font-semibold text-slate-900">Weekly Leaderboard</h3>
                        <p className="text-sm text-slate-500">This week&apos;s top contributors</p>
                      </div>
                    </div>
                  </div>

                  <div className="mt-4 grid grid-cols-2 sm:grid-cols-4 gap-3">
                    {leaderboard.map((member, index) => (
                      <div
                        key={member.id}
                        className={`flex items-center gap-2 p-3 rounded-lg ${
                          index === 0 ? 'bg-amber-50 border border-amber-200' : 'bg-slate-50'
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
                          <div className="font-medium text-slate-900 text-sm">{member.name}</div>
                          <div className="text-xs text-slate-500">{member.tasksCompleted} tasks</div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Today's Tasks */}
                <div className="mb-4">
                  <h2 className="font-semibold text-slate-900 mb-3 flex items-center gap-2">
                    <Clock className="w-5 h-5 text-slate-400" />
                    Today
                    <span className="text-sm font-normal text-slate-500">
                      ({groupedFamilyTasks.today.filter(t => !t.completed).length} remaining)
                    </span>
                  </h2>

                  {groupedFamilyTasks.today.length === 0 ? (
                    <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-8 text-center">
                      <PartyPopper className="w-12 h-12 text-emerald-500 mx-auto mb-3" />
                      <h3 className="text-lg font-medium text-slate-700">All caught up!</h3>
                      <p className="text-slate-500 mt-1">Relax, you deserve it.</p>
                    </div>
                  ) : (
                    <div className="space-y-2">
                      {groupedFamilyTasks.today.map(task => {
                        const assignee = task.assigneeId ? getMember(task.assigneeId) : null;
                        const CategoryIcon = (task.category && CATEGORY_ICONS[task.category]) || Sparkles;

                        return (
                          <div
                            key={task.id}
                            className={`bg-white rounded-xl shadow-sm border border-slate-200 p-4 transition-all ${
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
                                    : 'border-slate-300 hover:border-emerald-500'
                                }`}
                              >
                                {task.completed && <Check className="w-4 h-4" />}
                              </button>

                              {/* Category Icon */}
                              <div className="p-2 bg-slate-100 rounded-lg flex-shrink-0">
                                <CategoryIcon className="w-4 h-4 text-slate-600" />
                              </div>

                              {/* Task Content */}
                              <div className="flex-1 min-w-0">
                                <div className={`font-medium ${task.completed ? 'line-through text-slate-500' : 'text-slate-800'}`}>
                                  {task.title}
                                </div>
                                <div className="flex items-center gap-2 text-sm text-slate-500">
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

                              {/* Delegate Button */}
                              {!task.completed && (
                                <button
                                  onClick={() => delegateTask(task)}
                                  className="px-3 py-1.5 text-sm text-emerald-600 hover:bg-emerald-50 rounded-lg transition-colors flex items-center gap-1"
                                >
                                  <Share2 className="w-4 h-4" />
                                  <span className="hidden sm:inline">Delegate</span>
                                </button>
                              )}

                              {/* More */}
                              <button
                                onClick={() => setShowTaskDetail(task)}
                                className="p-2 hover:bg-slate-100 rounded-lg transition-colors text-slate-400"
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
                    <h2 className="font-semibold text-slate-900 mb-3 flex items-center gap-2">
                      <Calendar className="w-5 h-5 text-slate-400" />
                      Upcoming
                    </h2>

                    <div className="space-y-2">
                      {groupedFamilyTasks.upcoming.map(task => {
                        const assignee = task.assigneeId ? getMember(task.assigneeId) : null;
                        const CategoryIcon = (task.category && CATEGORY_ICONS[task.category]) || Sparkles;

                        return (
                          <div
                            key={task.id}
                            className="bg-white rounded-xl shadow-sm border border-slate-200 p-4"
                          >
                            <div className="flex items-center gap-3">
                              <button
                                onClick={() => toggleTaskComplete(task.id)}
                                className="w-7 h-7 rounded-full border-2 border-slate-300 hover:border-emerald-500 flex items-center justify-center flex-shrink-0 transition-colors"
                              />

                              <div className="p-2 bg-slate-100 rounded-lg flex-shrink-0">
                                <CategoryIcon className="w-4 h-4 text-slate-600" />
                              </div>

                              <div className="flex-1 min-w-0">
                                <div className="font-medium text-slate-800">{task.title}</div>
                                <div className="flex items-center gap-2 text-sm text-slate-500">
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
                                <span className="hidden sm:inline">Delegate</span>
                              </button>

                              <button
                                onClick={() => setShowTaskDetail(task)}
                                className="p-2 hover:bg-slate-100 rounded-lg transition-colors text-slate-400"
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
                  <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-12 text-center">
                    <Briefcase className="w-16 h-16 text-slate-300 mx-auto mb-4" />
                    <h3 className="text-lg font-medium text-slate-700 mb-2">Your Manager is standing by</h3>
                    <p className="text-slate-500 max-w-sm mx-auto">
                      Delegate something to free up your time. Just type above and select &quot;Manager&quot;.
                    </p>
                  </div>
                ) : (
                  <div className="space-y-6">
                    {/* Needs Review */}
                    {managerTasks.filter(t => t.needsReview).length > 0 && (
                      <div>
                        <h2 className="font-semibold text-slate-900 mb-3 flex items-center gap-2">
                          <AlertCircle className="w-5 h-5 text-amber-500" />
                          Needs Your Review
                        </h2>
                        <div className="space-y-2">
                          {managerTasks.filter(t => t.needsReview).map(task => (
                            <div
                              key={task.id}
                              className="bg-amber-50 rounded-xl border border-amber-200 p-4"
                            >
                              <div className="flex items-start justify-between">
                                <div className="flex-1">
                                  <div className="flex items-center gap-2 mb-1">
                                    {getStatusBadge(task.status)}
                                  </div>
                                  <h3 className="font-medium text-slate-900">{task.title}</h3>
                                  {task.managerNote && (
                                    <p className="text-sm text-slate-600 mt-2 p-3 bg-white rounded-lg border border-amber-100">
                                      &quot;{task.managerNote}&quot;
                                    </p>
                                  )}
                                </div>
                              </div>
                              <div className="mt-3 flex gap-2">
                                <button className="flex-1 px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors font-medium text-sm">
                                  Looks Good
                                </button>
                                <button className="flex-1 px-4 py-2 border border-slate-300 rounded-lg hover:bg-slate-50 transition-colors text-slate-700 text-sm">
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
                        <h2 className="font-semibold text-slate-900 mb-3 flex items-center gap-2">
                          <Loader2 className="w-5 h-5 text-amber-500 animate-spin" />
                          In Progress
                        </h2>
                        <div className="space-y-2">
                          {managerTasksByStatus.inProgress.filter(t => !t.needsReview).map(task => {
                            const CategoryIcon = (task.category && CATEGORY_ICONS[task.category]) || Sparkles;

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
                                    <div className="flex items-center gap-2 mb-1">
                                      {getStatusBadge(task.status)}
                                      {task.priority === 'high' && (
                                        <span className="px-2 py-0.5 bg-red-100 text-red-700 text-xs rounded-full font-medium">Priority</span>
                                      )}
                                    </div>
                                    <h3 className="font-medium text-slate-900">{task.title}</h3>
                                    {task.description && (
                                      <p className="text-sm text-slate-600 mt-1">{task.description}</p>
                                    )}
                                    {task.dueDate && (
                                      <p className="text-sm text-slate-500 mt-2 flex items-center gap-1">
                                        <Calendar className="w-4 h-4" />
                                        Due {task.dueDate.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
                                      </p>
                                    )}
                                  </div>
                                  <button
                                    onClick={() => setShowTaskDetail(task)}
                                    className="flex items-center gap-1 px-3 py-1.5 text-sm text-emerald-600 hover:bg-emerald-100 rounded-lg transition-colors"
                                  >
                                    <MessageCircle className="w-4 h-4" />
                                    Message
                                  </button>
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
                        <h2 className="font-semibold text-slate-900 mb-3 flex items-center gap-2">
                          <Send className="w-5 h-5 text-slate-400" />
                          Pending
                        </h2>
                        <div className="space-y-2">
                          {managerTasksByStatus.pending.map(task => {
                            const CategoryIcon = (task.category && CATEGORY_ICONS[task.category]) || Sparkles;

                            return (
                              <div
                                key={task.id}
                                className="bg-white rounded-xl border border-slate-200 p-4"
                              >
                                <div className="flex items-start gap-3">
                                  <div className="p-2 bg-slate-100 rounded-lg flex-shrink-0">
                                    <CategoryIcon className="w-5 h-5 text-slate-600" />
                                  </div>
                                  <div className="flex-1 min-w-0">
                                    <div className="flex items-center gap-2 mb-1">
                                      {getStatusBadge(task.status)}
                                      {task.recurrence !== 'none' && (
                                        <span className="flex items-center gap-1 text-xs text-slate-500">
                                          <Repeat className="w-3 h-3" />
                                          {task.recurrence}
                                        </span>
                                      )}
                                    </div>
                                    <h3 className="font-medium text-slate-900">{task.title}</h3>
                                    {task.description && (
                                      <p className="text-sm text-slate-600 mt-1">{task.description}</p>
                                    )}
                                  </div>
                                  <button
                                    onClick={() => setShowTaskDetail(task)}
                                    className="p-2 hover:bg-slate-100 rounded-lg transition-colors text-slate-400"
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
                    {managerTasksByStatus.completed.filter(t => !t.needsReview).length > 0 && (
                      <div>
                        <h2 className="font-semibold text-slate-900 mb-3 flex items-center gap-2">
                          <CheckCircle2 className="w-5 h-5 text-emerald-500" />
                          Recently Completed
                        </h2>
                        <div className="space-y-2">
                          {managerTasksByStatus.completed.filter(t => !t.needsReview).map(task => (
                            <div
                              key={task.id}
                              className="bg-white rounded-xl border border-slate-200 p-4 opacity-75"
                            >
                              <div className="flex items-center gap-3">
                                <div className="p-2 bg-emerald-100 rounded-lg flex-shrink-0">
                                  <CheckCircle2 className="w-5 h-5 text-emerald-600" />
                                </div>
                                <div className="flex-1 min-w-0">
                                  <h3 className="font-medium text-slate-700 line-through">{task.title}</h3>
                                  {task.managerNote && (
                                    <p className="text-sm text-slate-500 mt-1">{task.managerNote}</p>
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
            <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4 sticky top-32">
              <div className="flex items-center justify-between mb-4">
                <h2 className="font-semibold text-slate-900">Manager Activity</h2>
                <Bell className="w-5 h-5 text-slate-400" />
              </div>

              <div className="space-y-4">
                {activity.map(item => (
                  <div key={item.id} className="flex gap-3">
                    <div className={`w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 ${
                      item.type === 'completed' ? 'bg-emerald-100 text-emerald-600' :
                      item.type === 'started' ? 'bg-amber-100 text-amber-600' :
                      item.type === 'viewed' ? 'bg-blue-100 text-blue-600' :
                      'bg-purple-100 text-purple-600'
                    }`}>
                      {item.type === 'completed' && <CheckCircle2 className="w-4 h-4" />}
                      {item.type === 'started' && <Loader2 className="w-4 h-4" />}
                      {item.type === 'viewed' && <Eye className="w-4 h-4" />}
                      {item.type === 'message' && <MessageCircle className="w-4 h-4" />}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm text-slate-800">
                        <span className="font-medium">{item.managerName}</span>
                        {item.type === 'completed' && ' completed '}
                        {item.type === 'started' && ' started working on '}
                        {item.type === 'viewed' && ' viewed '}
                        {item.type === 'message' && ' sent a message about '}
                        <span className="font-medium">&quot;{item.taskTitle}&quot;</span>
                      </p>
                      <p className="text-xs text-slate-500 mt-0.5">{formatRelativeTime(item.timestamp)}</p>
                    </div>
                  </div>
                ))}
              </div>

              <button className="w-full mt-4 py-2 text-sm text-emerald-600 hover:bg-emerald-50 rounded-lg transition-colors font-medium">
                View All Activity
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Task Detail Modal */}
      {showTaskDetail && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl max-w-lg w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6 border-b border-slate-200">
              <div className="flex items-center justify-between">
                <h2 className="text-xl font-bold text-slate-900">Task Details</h2>
                <button
                  onClick={() => setShowTaskDetail(null)}
                  className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  <X className="w-5 h-5 text-slate-500" />
                </button>
              </div>
            </div>

            <div className="p-6 space-y-4">
              {/* Status */}
              <div className="flex items-center gap-2">
                {showTaskDetail.type === 'family' ? (
                  showTaskDetail.completed ? (
                    <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-sm font-medium bg-emerald-100 text-emerald-700">
                      <CheckCircle2 className="w-4 h-4" /> Completed
                    </span>
                  ) : (
                    <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-sm font-medium bg-slate-100 text-slate-700">
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
              <h3 className="text-lg font-semibold text-slate-900">{showTaskDetail.title}</h3>

              {/* Description (Manager tasks) */}
              {showTaskDetail.type === 'manager' && showTaskDetail.description && (
                <p className="text-slate-600">{showTaskDetail.description}</p>
              )}

              {/* Assignee (Family tasks) */}
              {showTaskDetail.type === 'family' && showTaskDetail.assigneeId && (
                <div className="flex items-center gap-2">
                  <span className="text-sm text-slate-500">Assigned to:</span>
                  {(() => {
                    const member = getMember(showTaskDetail.assigneeId);
                    if (!member) return null;
                    return (
                      <span className="flex items-center gap-1.5">
                        <span className={`w-6 h-6 rounded-full ${member.color} flex items-center justify-center text-xs text-white font-medium`}>
                          {member.initials}
                        </span>
                        <span className="font-medium text-slate-800">{member.name}</span>
                      </span>
                    );
                  })()}
                </div>
              )}

              {/* Due Date */}
              {showTaskDetail.dueDate && (
                <div className="flex items-center gap-2 text-slate-600">
                  <Calendar className="w-4 h-4" />
                  <span>
                    Due {showTaskDetail.dueDate.toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' })}
                  </span>
                </div>
              )}

              {/* Status Timeline (Manager tasks) */}
              {showTaskDetail.type === 'manager' && showTaskDetail.statusHistory.length > 0 && (
                <div className="border-t border-slate-200 pt-4 mt-4">
                  <h4 className="text-sm font-medium text-slate-700 mb-3">Status History</h4>
                  <div className="space-y-3">
                    {showTaskDetail.statusHistory.map((entry, index) => (
                      <div key={index} className="flex items-start gap-3">
                        <div className={`w-2 h-2 rounded-full mt-1.5 ${
                          entry.status === 'completed' ? 'bg-emerald-500' :
                          entry.status === 'in_progress' ? 'bg-amber-500' :
                          entry.status === 'viewed' ? 'bg-blue-500' :
                          'bg-slate-400'
                        }`} />
                        <div className="flex-1">
                          <div className="flex items-center justify-between">
                            <span className="text-sm font-medium text-slate-800 capitalize">{entry.status.replace('_', ' ')}</span>
                            <span className="text-xs text-slate-500">{formatRelativeTime(entry.timestamp)}</span>
                          </div>
                          {entry.note && (
                            <p className="text-sm text-slate-600 mt-1">{entry.note}</p>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>

            <div className="p-6 border-t border-slate-200 bg-slate-50 rounded-b-xl">
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
                    Delegate
                  </button>
                )}
                {showTaskDetail.type === 'manager' && (
                  <button className="px-4 py-2.5 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors font-medium flex items-center gap-2">
                    <MessageCircle className="w-4 h-4" />
                    Message Manager
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Mobile FAB - positioned above the global chat FAB */}
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
            <div className="p-4 border-b border-slate-200 sticky top-0 bg-white">
              <div className="flex items-center justify-between">
                <h2 className="text-lg font-bold text-slate-900">New Task</h2>
                <button
                  onClick={() => setShowAddModal(false)}
                  className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  <X className="w-5 h-5 text-slate-500" />
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
                className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-600 focus:border-transparent text-lg"
              />

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2">Assign to:</label>
                <div className="flex gap-2">
                  <button
                    onClick={() => setNewTaskAssignee('family')}
                    className={`flex-1 flex items-center justify-center gap-2 px-4 py-3 rounded-lg border-2 transition-colors ${
                      newTaskAssignee === 'family'
                        ? 'border-slate-800 bg-slate-50'
                        : 'border-slate-200'
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
                        : 'border-slate-200'
                    }`}
                  >
                    <Briefcase className="w-5 h-5" />
                    Manager
                  </button>
                </div>
              </div>

              {newTaskAssignee === 'family' && (
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">Family member:</label>
                  <div className="grid grid-cols-2 gap-2">
                    <button
                      onClick={() => setNewTaskAssigneeId('')}
                      className={`flex items-center gap-2 px-3 py-2 rounded-lg border transition-colors ${
                        newTaskAssigneeId === ''
                          ? 'border-slate-800 bg-slate-50'
                          : 'border-slate-200'
                      }`}
                    >
                      <Users className="w-5 h-5 text-slate-500" />
                      Anyone
                    </button>
                    {family.map(member => (
                      <button
                        key={member.id}
                        onClick={() => setNewTaskAssigneeId(member.id)}
                        className={`flex items-center gap-2 px-3 py-2 rounded-lg border transition-colors ${
                          newTaskAssigneeId === member.id
                            ? 'border-slate-800 bg-slate-50'
                            : 'border-slate-200'
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
                <div className="flex gap-2">
                  <button className="flex-1 flex items-center justify-center gap-2 px-4 py-3 border border-slate-300 rounded-lg hover:bg-slate-50 transition-colors text-slate-700">
                    <Camera className="w-5 h-5" />
                    Add Photo
                  </button>
                  <button className="flex-1 flex items-center justify-center gap-2 px-4 py-3 border border-slate-300 rounded-lg hover:bg-slate-50 transition-colors text-slate-700">
                    <Mic className="w-5 h-5" />
                    Voice Note
                  </button>
                </div>
              )}

              <button
                onClick={handleAddTask}
                disabled={!newTaskInput.trim()}
                className="w-full py-3 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors font-medium disabled:opacity-50"
              >
                {newTaskAssignee === 'manager' ? 'Send to Manager' : 'Add Task'}
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
      `}</style>
    </div>
  );
}
