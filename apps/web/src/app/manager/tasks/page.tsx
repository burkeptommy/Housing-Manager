'use client';

import { useState } from 'react';
import {
  ClipboardList,
  Plus,
  ChevronDown,
  ChevronRight,
  Calendar,
  AlertTriangle,
  Clock,
  CheckCircle2,
  User,
  Home,
  Search,
  X,
  Send,
  Pause,
  Check,
  Link2,
  Bell,
  Upload,
  MoreVertical,
  ArrowUpDown,
  Building,
  CalendarDays,
  ListTodo,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

interface ProgressNote {
  id: string;
  content: string;
  completed: boolean;
  createdAt: string;
}

interface Task {
  id: string;
  title: string;
  description?: string;
  householdId: string;
  householdName: string;
  source: 'homeowner' | 'system' | 'manager';
  sourceDetails?: string;
  status: 'not_started' | 'in_progress' | 'waiting' | 'completed';
  priority: 'low' | 'medium' | 'high';
  dueDate: string;
  dueDateObj: Date;
  category: string;
  createdAt: string;
  completedAt?: string;
  progressNotes: ProgressNote[];
  linkedTo?: {
    type: 'request' | 'work_order' | 'bill';
    id: string;
    title: string;
  };
  notifyOnComplete: boolean;
}

type ViewType = 'my_tasks' | 'by_household' | 'by_due_date' | 'completed';

// ============================================================================
// MOCK DATA
// ============================================================================

const mockTasks: Task[] = [
  {
    id: 't1',
    title: 'Research summer camps for Emma',
    description: 'Looking for STEM camps, budget $2k/week, Austin area',
    householdId: 'hh1',
    householdName: 'Smith Family',
    source: 'homeowner',
    sourceDetails: 'Alice requested via message on Dec 19',
    status: 'in_progress',
    priority: 'medium',
    dueDate: 'Dec 28',
    dueDateObj: new Date('2024-12-28'),
    category: 'Concierge',
    createdAt: 'Dec 19',
    progressNotes: [
      { id: 'n1', content: 'Found Camp Invention ($1,800/week) - STEM focus', completed: true, createdAt: 'Dec 21' },
      { id: 'n2', content: 'Found iD Tech Camp ($2,100/week) - coding focus', completed: true, createdAt: 'Dec 22' },
      { id: 'n3', content: 'Need to check availability for July', completed: false, createdAt: 'Dec 22' },
    ],
    notifyOnComplete: true,
  },
  {
    id: 't2',
    title: 'Schedule HVAC maintenance',
    description: 'Annual inspection due for HVAC system',
    householdId: 'hh1',
    householdName: 'Smith Family',
    source: 'system',
    sourceDetails: 'Auto-generated from maintenance schedule',
    status: 'not_started',
    priority: 'medium',
    dueDate: 'Dec 26',
    dueDateObj: new Date('2024-12-26'),
    category: 'Maintenance',
    createdAt: 'Dec 20',
    progressNotes: [],
    notifyOnComplete: false,
  },
  {
    id: 't3',
    title: 'Get driveway sealing quotes',
    description: 'Driveway needs resealing. Get 3 quotes for comparison.',
    householdId: 'hh1',
    householdName: 'Smith Family',
    source: 'homeowner',
    sourceDetails: 'Bob requested during site visit',
    status: 'in_progress',
    priority: 'low',
    dueDate: 'Dec 30',
    dueDateObj: new Date('2024-12-30'),
    category: 'Home Improvement',
    createdAt: 'Dec 15',
    progressNotes: [
      { id: 'n4', content: 'Got quote from ABC Paving - $1,200', completed: true, createdAt: 'Dec 18' },
      { id: 'n5', content: 'Got quote from Premier Sealing - $1,450', completed: true, createdAt: 'Dec 20' },
      { id: 'n6', content: 'Waiting for third quote from DriveWay Pros', completed: false, createdAt: 'Dec 21' },
    ],
    notifyOnComplete: true,
  },
  {
    id: 't4',
    title: 'Renew homeowners insurance',
    description: 'Policy expires Jan 15. Review and renew.',
    householdId: 'hh2',
    householdName: 'Johnson Family',
    source: 'system',
    sourceDetails: 'Auto-generated from bill tracking',
    status: 'not_started',
    priority: 'high',
    dueDate: 'Dec 20',
    dueDateObj: new Date('2024-12-20'),
    category: 'Insurance',
    createdAt: 'Dec 10',
    progressNotes: [],
    linkedTo: { type: 'bill', id: 'b1', title: 'State Farm Insurance - $412/mo' },
    notifyOnComplete: true,
  },
  {
    id: 't5',
    title: 'Follow up on roof repair',
    description: 'Check if Ace Roofing completed the work satisfactorily',
    householdId: 'hh2',
    householdName: 'Johnson Family',
    source: 'manager',
    sourceDetails: 'Created by me after work order completed',
    status: 'waiting',
    priority: 'medium',
    dueDate: 'Dec 18',
    dueDateObj: new Date('2024-12-18'),
    category: 'Follow-up',
    createdAt: 'Dec 16',
    progressNotes: [
      { id: 'n7', content: 'Left message with homeowner', completed: true, createdAt: 'Dec 17' },
      { id: 'n8', content: 'Waiting for callback', completed: false, createdAt: 'Dec 17' },
    ],
    linkedTo: { type: 'work_order', id: 'wo1', title: 'Roof Leak Repair - Ace Roofing' },
    notifyOnComplete: false,
  },
  {
    id: 't6',
    title: 'Set up pest control service',
    description: 'New client needs quarterly pest control arranged',
    householdId: 'hh3',
    householdName: 'Garcia Residence',
    source: 'homeowner',
    sourceDetails: 'Requested during onboarding',
    status: 'not_started',
    priority: 'medium',
    dueDate: 'Dec 24',
    dueDateObj: new Date('2024-12-24'),
    category: 'Vendor Setup',
    createdAt: 'Dec 20',
    progressNotes: [],
    notifyOnComplete: true,
  },
  {
    id: 't7',
    title: 'Coordinate holiday lighting takedown',
    description: 'Schedule professional lighting removal for Jan 2',
    householdId: 'hh4',
    householdName: 'Williams Estate',
    source: 'homeowner',
    sourceDetails: 'Email from Mrs. Williams',
    status: 'in_progress',
    priority: 'low',
    dueDate: 'Dec 27',
    dueDateObj: new Date('2024-12-27'),
    category: 'Seasonal',
    createdAt: 'Dec 18',
    progressNotes: [
      { id: 'n9', content: 'Contacted Bright Holidays - available Jan 2', completed: true, createdAt: 'Dec 19' },
      { id: 'n10', content: 'Need to confirm time slot with homeowner', completed: false, createdAt: 'Dec 20' },
    ],
    notifyOnComplete: true,
  },
  {
    id: 't8',
    title: 'Review pool service contract',
    description: 'Contract up for renewal, compare with competitors',
    householdId: 'hh1',
    householdName: 'Smith Family',
    source: 'manager',
    status: 'completed',
    priority: 'medium',
    dueDate: 'Dec 15',
    dueDateObj: new Date('2024-12-15'),
    category: 'Vendor Management',
    createdAt: 'Dec 1',
    completedAt: 'Dec 14',
    progressNotes: [
      { id: 'n11', content: 'Current rate: $175/mo with Pool Pros', completed: true, createdAt: 'Dec 10' },
      { id: 'n12', content: 'Got competing quote: $160/mo from Blue Wave', completed: true, createdAt: 'Dec 12' },
      { id: 'n13', content: 'Negotiated Pool Pros down to $165/mo - renewed', completed: true, createdAt: 'Dec 14' },
    ],
    notifyOnComplete: false,
  },
  {
    id: 't9',
    title: 'Update emergency contact list',
    description: 'Annual review of emergency contacts for all households',
    householdId: 'hh2',
    householdName: 'Johnson Family',
    source: 'system',
    status: 'completed',
    priority: 'low',
    dueDate: 'Dec 10',
    dueDateObj: new Date('2024-12-10'),
    category: 'Admin',
    createdAt: 'Dec 1',
    completedAt: 'Dec 8',
    progressNotes: [],
    notifyOnComplete: false,
  },
];

const households = [
  { id: 'hh1', name: 'Smith Family' },
  { id: 'hh2', name: 'Johnson Family' },
  { id: 'hh3', name: 'Garcia Residence' },
  { id: 'hh4', name: 'Williams Estate' },
  { id: 'hh5', name: 'Chen Family' },
  { id: 'hh6', name: 'Patel Residence' },
];

const categories = [
  'General',
  'Concierge',
  'Maintenance',
  'Home Improvement',
  'Insurance',
  'Vendor Setup',
  'Vendor Management',
  'Seasonal',
  'Follow-up',
  'Admin',
];

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

const today = new Date();
today.setHours(0, 0, 0, 0);

const isOverdue = (task: Task) => {
  if (task.status === 'completed') return false;
  return task.dueDateObj < today;
};

const isDueToday = (task: Task) => {
  if (task.status === 'completed') return false;
  return task.dueDateObj.getTime() === today.getTime();
};

const isUpcoming = (task: Task) => {
  if (task.status === 'completed') return false;
  return task.dueDateObj > today;
};

// ============================================================================
// STATUS & PRIORITY COLORS
// ============================================================================

const statusColors: Record<string, string> = {
  not_started: 'text-slate-600 bg-slate-100',
  in_progress: 'text-blue-600 bg-blue-100',
  waiting: 'text-amber-600 bg-amber-100',
  completed: 'text-emerald-600 bg-emerald-100',
};

const statusLabels: Record<string, string> = {
  not_started: 'Not Started',
  in_progress: 'In Progress',
  waiting: 'Waiting',
  completed: 'Completed',
};

const priorityColors: Record<string, string> = {
  low: 'text-slate-500',
  medium: 'text-amber-600',
  high: 'text-red-600',
};

const sourceLabels: Record<string, string> = {
  homeowner: 'Homeowner Request',
  system: 'System Generated',
  manager: 'Self-Created',
};

const sourceIcons: Record<string, React.ReactNode> = {
  homeowner: <User className="w-3.5 h-3.5" />,
  system: <Clock className="w-3.5 h-3.5" />,
  manager: <ClipboardList className="w-3.5 h-3.5" />,
};

// ============================================================================
// MAIN COMPONENT
// ============================================================================

export default function TaskManagementPage() {
  const [view, setView] = useState<ViewType>('my_tasks');
  const [expandedTasks, setExpandedTasks] = useState<string[]>([]);
  const [completedTaskIds, setCompletedTaskIds] = useState<string[]>(
    mockTasks.filter(t => t.status === 'completed').map(t => t.id)
  );

  // Filters
  const [householdFilter, setHouseholdFilter] = useState<string>('all');
  const [sourceFilter, setSourceFilter] = useState<string>('all');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [sortBy, setSortBy] = useState<string>('due_date');
  const [searchQuery, setSearchQuery] = useState('');

  // Modals
  const [showNewTaskModal, setShowNewTaskModal] = useState(false);
  const [showCompleteModal, setShowCompleteModal] = useState(false);
  const [completingTask, setCompletingTask] = useState<Task | null>(null);
  const [newProgressNote, setNewProgressNote] = useState<Record<string, string>>({});

  // New task form
  const [newTask, setNewTask] = useState({
    householdId: '',
    title: '',
    description: '',
    dueDate: '',
    source: 'manager',
    priority: 'medium',
    category: 'General',
    linkedTo: '',
    notifyOnComplete: false,
  });

  // Calculate stats
  const activeTasks = mockTasks.filter(t => !completedTaskIds.includes(t.id));
  const stats = {
    today: activeTasks.filter(t => isDueToday(t)).length,
    thisWeek: activeTasks.filter(t => {
      const weekFromNow = new Date(today);
      weekFromNow.setDate(weekFromNow.getDate() + 7);
      return t.dueDateObj <= weekFromNow;
    }).length,
    overdue: activeTasks.filter(t => isOverdue(t)).length,
    total: activeTasks.length,
  };

  const toggleExpanded = (taskId: string) => {
    setExpandedTasks(prev =>
      prev.includes(taskId) ? prev.filter(id => id !== taskId) : [...prev, taskId]
    );
  };

  const handleQuickComplete = (task: Task) => {
    if (task.source === 'homeowner' && task.notifyOnComplete) {
      setCompletingTask(task);
      setShowCompleteModal(true);
    } else {
      setCompletedTaskIds(prev => [...prev, task.id]);
    }
  };

  const handleCompleteWithMessage = () => {
    if (completingTask) {
      setCompletedTaskIds(prev => [...prev, completingTask.id]);
      setShowCompleteModal(false);
      setCompletingTask(null);
    }
  };

  const addProgressNote = (taskId: string) => {
    const note = newProgressNote[taskId];
    if (note?.trim()) {
      // In real app, would update the task
      console.log('Adding note to task', taskId, note);
      setNewProgressNote(prev => ({ ...prev, [taskId]: '' }));
    }
  };

  // Filter and sort tasks
  let filteredTasks = mockTasks.filter(task => {
    if (view === 'completed') {
      return completedTaskIds.includes(task.id);
    }
    if (completedTaskIds.includes(task.id)) return false;

    if (householdFilter !== 'all' && task.householdId !== householdFilter) return false;
    if (sourceFilter !== 'all' && task.source !== sourceFilter) return false;
    if (statusFilter !== 'all' && task.status !== statusFilter) return false;
    if (searchQuery && !task.title.toLowerCase().includes(searchQuery.toLowerCase())) return false;

    return true;
  });

  // Sort tasks
  filteredTasks = [...filteredTasks].sort((a, b) => {
    if (sortBy === 'due_date') {
      return a.dueDateObj.getTime() - b.dueDateObj.getTime();
    }
    if (sortBy === 'priority') {
      const priorityOrder = { high: 0, medium: 1, low: 2 };
      return priorityOrder[a.priority] - priorityOrder[b.priority];
    }
    if (sortBy === 'household') {
      return a.householdName.localeCompare(b.householdName);
    }
    return 0;
  });

  // Group tasks for different views
  const overdueTasks = filteredTasks.filter(isOverdue);
  const todayTasks = filteredTasks.filter(isDueToday);
  const upcomingTasks = filteredTasks.filter(isUpcoming);

  const tasksByHousehold = households.reduce((acc, household) => {
    acc[household.id] = filteredTasks.filter(t => t.householdId === household.id);
    return acc;
  }, {} as Record<string, Task[]>);

  const views = [
    { id: 'my_tasks' as ViewType, label: 'My Tasks', icon: ListTodo },
    { id: 'by_household' as ViewType, label: 'By Household', icon: Building },
    { id: 'by_due_date' as ViewType, label: 'By Due Date', icon: CalendarDays },
    { id: 'completed' as ViewType, label: 'Completed', icon: CheckCircle2 },
  ];

  // Task Card Component
  const TaskCard = ({ task }: { task: Task }) => {
    const isExpanded = expandedTasks.includes(task.id);
    const isCompleted = completedTaskIds.includes(task.id);
    const taskIsOverdue = isOverdue(task);

    return (
      <div
        className={`bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden transition-all ${
          taskIsOverdue ? 'border-l-4 border-l-red-500' : ''
        } ${isCompleted ? 'opacity-60' : ''}`}
      >
        <div
          className="p-4 cursor-pointer"
          onClick={() => toggleExpanded(task.id)}
        >
          <div className="flex items-start gap-3">
            {/* Checkbox */}
            <button
              onClick={(e) => {
                e.stopPropagation();
                if (!isCompleted) handleQuickComplete(task);
              }}
              className={`mt-0.5 w-5 h-5 rounded border-2 flex items-center justify-center transition-colors ${
                isCompleted
                  ? 'bg-emerald-500 border-emerald-500 text-white'
                  : 'border-slate-300 hover:border-indigo-500'
              }`}
            >
              {isCompleted && <Check className="w-3 h-3" />}
            </button>

            {/* Main Content */}
            <div className="flex-1 min-w-0">
              <div className="flex items-start justify-between gap-2">
                <h3 className={`font-medium ${isCompleted ? 'line-through text-slate-400' : 'text-slate-900'}`}>
                  {task.title}
                </h3>
                <div className="flex items-center gap-2">
                  <span className={`px-2 py-0.5 rounded text-xs font-medium ${statusColors[task.status]}`}>
                    {statusLabels[task.status]}
                  </span>
                  <button onClick={(e) => e.stopPropagation()} className="text-slate-400 hover:text-slate-600">
                    <MoreVertical className="w-4 h-4" />
                  </button>
                </div>
              </div>
              <div className="flex items-center gap-2 mt-1 text-sm text-slate-500">
                <span className="font-medium text-slate-700">{task.householdName}</span>
                <span>•</span>
                <span className="flex items-center gap-1">
                  {sourceIcons[task.source]}
                  {sourceLabels[task.source]}
                </span>
                <span>•</span>
                <span className={`flex items-center gap-1 ${taskIsOverdue ? 'text-red-600 font-medium' : ''}`}>
                  <Calendar className="w-3.5 h-3.5" />
                  Due: {task.dueDate}
                </span>
                {task.priority === 'high' && (
                  <>
                    <span>•</span>
                    <span className="text-red-600 font-medium">High Priority</span>
                  </>
                )}
              </div>
            </div>

            {/* Expand Icon */}
            <div className="text-slate-400">
              {isExpanded ? <ChevronDown className="w-5 h-5" /> : <ChevronRight className="w-5 h-5" />}
            </div>
          </div>
        </div>

        {/* Expanded Content */}
        {isExpanded && (
          <div className="px-4 pb-4 space-y-4 border-t border-slate-100 pt-4">
            {/* Source Details */}
            {task.sourceDetails && (
              <div className="bg-slate-50 rounded-lg p-3">
                <p className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-1">
                  {task.source === 'homeowner' ? 'Request from Homeowner' : 'Source'}
                </p>
                <p className="text-sm text-slate-700">{task.description || task.sourceDetails}</p>
              </div>
            )}

            {/* Linked Item */}
            {task.linkedTo && (
              <div className="flex items-center gap-2 text-sm">
                <Link2 className="w-4 h-4 text-slate-400" />
                <span className="text-slate-500">Linked to:</span>
                <button className="text-indigo-600 hover:text-indigo-700 font-medium">
                  {task.linkedTo.title}
                </button>
              </div>
            )}

            {/* Progress Notes */}
            {(task.progressNotes.length > 0 || !isCompleted) && (
              <div>
                <p className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-2">My Progress</p>
                <div className="bg-slate-50 rounded-lg p-3 space-y-2">
                  {task.progressNotes.map(note => (
                    <div key={note.id} className="flex items-start gap-2">
                      {note.completed ? (
                        <CheckCircle2 className="w-4 h-4 text-emerald-500 mt-0.5" />
                      ) : (
                        <div className="w-4 h-4 rounded-full border-2 border-slate-300 mt-0.5" />
                      )}
                      <span className={`text-sm flex-1 ${note.completed ? 'text-slate-600' : 'text-slate-900'}`}>
                        {note.content}
                      </span>
                      <span className="text-xs text-slate-400">{note.createdAt}</span>
                    </div>
                  ))}
                  {!isCompleted && (
                    <div className="flex items-center gap-2 mt-2 pt-2 border-t border-slate-200">
                      <input
                        type="text"
                        value={newProgressNote[task.id] || ''}
                        onChange={(e) => setNewProgressNote(prev => ({ ...prev, [task.id]: e.target.value }))}
                        placeholder="Add progress note..."
                        className="flex-1 text-sm px-2 py-1 border border-slate-200 rounded focus:outline-none focus:ring-1 focus:ring-indigo-500"
                        onClick={(e) => e.stopPropagation()}
                      />
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          addProgressNote(task.id);
                        }}
                        className="text-indigo-600 hover:text-indigo-700 text-sm font-medium"
                      >
                        Add
                      </button>
                    </div>
                  )}
                </div>
              </div>
            )}

            {/* Actions */}
            {!isCompleted && (
              <div className="flex items-center gap-2 pt-2 border-t border-slate-100">
                {task.source === 'homeowner' && (
                  <button className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors">
                    <Send className="w-4 h-4" />
                    Send Options to Homeowner
                  </button>
                )}
                <button className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg transition-colors">
                  <Pause className="w-4 h-4" />
                  Put on Hold
                </button>
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    handleQuickComplete(task);
                  }}
                  className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-emerald-600 hover:bg-emerald-50 rounded-lg transition-colors"
                >
                  <Check className="w-4 h-4" />
                  Mark Complete
                </button>
              </div>
            )}
          </div>
        )}
      </div>
    );
  };

  // Task Section Component
  const TaskSection = ({ title, tasks, icon, bgColor, textColor }: {
    title: string;
    tasks: Task[];
    icon: React.ReactNode;
    bgColor: string;
    textColor: string;
  }) => {
    if (tasks.length === 0) return null;

    return (
      <div className="space-y-3">
        <div className={`${bgColor} rounded-lg px-4 py-2 flex items-center gap-2`}>
          {icon}
          <span className={`font-medium ${textColor}`}>{title} ({tasks.length})</span>
        </div>
        <div className="space-y-3">
          {tasks.map(task => (
            <TaskCard key={task.id} task={task} />
          ))}
        </div>
      </div>
    );
  };

  return (
    <div className="min-h-screen bg-slate-50">
      {/* Header */}
      <div className="bg-white border-b border-slate-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between mb-6">
            <div className="flex items-center gap-3">
              <ClipboardList className="w-8 h-8 text-indigo-600" />
              <h1 className="text-2xl font-bold text-slate-900">Task Management</h1>
            </div>
            <button
              onClick={() => setShowNewTaskModal(true)}
              className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700 transition-colors"
            >
              <Plus className="w-4 h-4" />
              New Task
            </button>
          </div>

          {/* View Tabs */}
          <div className="flex items-center gap-1 mb-6">
            {views.map(v => {
              const Icon = v.icon;
              return (
                <button
                  key={v.id}
                  onClick={() => setView(v.id)}
                  className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                    view === v.id
                      ? 'bg-indigo-600 text-white'
                      : 'text-slate-600 hover:bg-slate-100'
                  }`}
                >
                  <Icon className="w-4 h-4" />
                  {v.label}
                </button>
              );
            })}
          </div>

          {/* Stats */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
            <div className="bg-amber-50 rounded-lg p-4 border border-amber-100">
              <p className="text-xs font-medium text-amber-600 uppercase tracking-wide">Today</p>
              <p className="text-2xl font-bold text-amber-700">{stats.today}</p>
            </div>
            <div className="bg-blue-50 rounded-lg p-4 border border-blue-100">
              <p className="text-xs font-medium text-blue-600 uppercase tracking-wide">This Week</p>
              <p className="text-2xl font-bold text-blue-700">{stats.thisWeek}</p>
            </div>
            <div className="bg-red-50 rounded-lg p-4 border border-red-100">
              <p className="text-xs font-medium text-red-600 uppercase tracking-wide flex items-center gap-1">
                Overdue
                {stats.overdue > 0 && <span className="w-2 h-2 rounded-full bg-red-500 animate-pulse" />}
              </p>
              <p className="text-2xl font-bold text-red-700">{stats.overdue}</p>
            </div>
            <div className="bg-slate-100 rounded-lg p-4 border border-slate-200">
              <p className="text-xs font-medium text-slate-600 uppercase tracking-wide">Total Active</p>
              <p className="text-2xl font-bold text-slate-700">{stats.total}</p>
            </div>
          </div>

          {/* Filters */}
          <div className="flex flex-wrap items-center gap-3">
            <div className="relative flex-1 max-w-xs">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-slate-400" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search tasks..."
                className="w-full pl-9 pr-4 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>
            <select
              value={householdFilter}
              onChange={(e) => setHouseholdFilter(e.target.value)}
              className="px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="all">All Households</option>
              {households.map(h => (
                <option key={h.id} value={h.id}>{h.name}</option>
              ))}
            </select>
            <select
              value={sourceFilter}
              onChange={(e) => setSourceFilter(e.target.value)}
              className="px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="all">All Sources</option>
              <option value="homeowner">Homeowner Request</option>
              <option value="system">System Generated</option>
              <option value="manager">Self-Created</option>
            </select>
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="all">All Statuses</option>
              <option value="not_started">Not Started</option>
              <option value="in_progress">In Progress</option>
              <option value="waiting">Waiting</option>
            </select>
            <div className="flex items-center gap-1 text-sm text-slate-500">
              <ArrowUpDown className="w-4 h-4" />
              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value)}
                className="px-2 py-2 border-0 bg-transparent focus:outline-none focus:ring-0 text-slate-600"
              >
                <option value="due_date">Sort: Due Date</option>
                <option value="priority">Sort: Priority</option>
                <option value="household">Sort: Household</option>
              </select>
            </div>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* My Tasks View */}
        {view === 'my_tasks' && (
          <div className="space-y-6">
            <TaskSection
              title="OVERDUE"
              tasks={overdueTasks}
              icon={<AlertTriangle className="w-4 h-4 text-red-600" />}
              bgColor="bg-red-50"
              textColor="text-red-700"
            />
            <TaskSection
              title="DUE TODAY"
              tasks={todayTasks}
              icon={<Calendar className="w-4 h-4 text-amber-600" />}
              bgColor="bg-amber-50"
              textColor="text-amber-700"
            />
            <TaskSection
              title="UPCOMING"
              tasks={upcomingTasks}
              icon={<CalendarDays className="w-4 h-4 text-slate-500" />}
              bgColor="bg-slate-100"
              textColor="text-slate-700"
            />
            {filteredTasks.length === 0 && (
              <div className="text-center py-12">
                <CheckCircle2 className="w-12 h-12 text-emerald-400 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-slate-900">All caught up!</h3>
                <p className="text-slate-500">No tasks match your current filters.</p>
              </div>
            )}
          </div>
        )}

        {/* By Household View */}
        {view === 'by_household' && (
          <div className="space-y-6">
            {households.map(household => {
              const householdTasks = tasksByHousehold[household.id] || [];
              if (householdTasks.length === 0) return null;

              return (
                <div key={household.id} className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
                  <div className="flex items-center justify-between p-4 bg-slate-50 border-b border-slate-200">
                    <div className="flex items-center gap-2">
                      <Home className="w-5 h-5 text-indigo-600" />
                      <h3 className="font-semibold text-slate-900">{household.name}</h3>
                      <span className="px-2 py-0.5 rounded-full bg-slate-200 text-slate-600 text-xs font-medium">
                        {householdTasks.length} tasks
                      </span>
                    </div>
                    <button className="text-indigo-600 hover:text-indigo-700 text-sm font-medium">
                      View Household
                    </button>
                  </div>
                  <div className="p-4 space-y-3">
                    {householdTasks.map(task => (
                      <TaskCard key={task.id} task={task} />
                    ))}
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {/* By Due Date View */}
        {view === 'by_due_date' && (
          <div className="space-y-6">
            <TaskSection
              title="OVERDUE"
              tasks={overdueTasks}
              icon={<AlertTriangle className="w-4 h-4 text-red-600" />}
              bgColor="bg-red-50"
              textColor="text-red-700"
            />
            <TaskSection
              title="DUE TODAY"
              tasks={todayTasks}
              icon={<Calendar className="w-4 h-4 text-amber-600" />}
              bgColor="bg-amber-50"
              textColor="text-amber-700"
            />
            <TaskSection
              title="UPCOMING"
              tasks={upcomingTasks}
              icon={<CalendarDays className="w-4 h-4 text-slate-500" />}
              bgColor="bg-slate-100"
              textColor="text-slate-700"
            />
          </div>
        )}

        {/* Completed View */}
        {view === 'completed' && (
          <div className="space-y-3">
            {filteredTasks.length > 0 ? (
              filteredTasks.map(task => (
                <TaskCard key={task.id} task={task} />
              ))
            ) : (
              <div className="text-center py-12">
                <ClipboardList className="w-12 h-12 text-slate-300 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-slate-900">No completed tasks</h3>
                <p className="text-slate-500">Tasks you complete will appear here.</p>
              </div>
            )}
          </div>
        )}
      </div>

      {/* New Task Modal */}
      {showNewTaskModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl max-w-lg w-full max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between p-4 border-b border-slate-200">
              <h2 className="text-lg font-semibold text-slate-900 flex items-center gap-2">
                <Plus className="w-5 h-5 text-indigo-600" />
                New Task
              </h2>
              <button
                onClick={() => setShowNewTaskModal(false)}
                className="text-slate-400 hover:text-slate-600"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="p-4 space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">
                    Household <span className="text-red-500">*</span>
                  </label>
                  <select
                    value={newTask.householdId}
                    onChange={(e) => setNewTask(prev => ({ ...prev, householdId: e.target.value }))}
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  >
                    <option value="">Select...</option>
                    {households.map(h => (
                      <option key={h.id} value={h.id}>{h.name}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">
                    Due Date <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="date"
                    value={newTask.dueDate}
                    onChange={(e) => setNewTask(prev => ({ ...prev, dueDate: e.target.value }))}
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">
                  Task Title <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  value={newTask.title}
                  onChange={(e) => setNewTask(prev => ({ ...prev, title: e.target.value }))}
                  placeholder="e.g., Schedule HVAC maintenance"
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">
                  Description
                </label>
                <textarea
                  value={newTask.description}
                  onChange={(e) => setNewTask(prev => ({ ...prev, description: e.target.value }))}
                  placeholder="Additional details..."
                  rows={3}
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Source</label>
                  <select
                    value={newTask.source}
                    onChange={(e) => setNewTask(prev => ({ ...prev, source: e.target.value }))}
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  >
                    <option value="manager">Self-Created</option>
                    <option value="homeowner">Homeowner Request</option>
                    <option value="system">System Generated</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Priority</label>
                  <div className="flex items-center gap-4 pt-2">
                    {['low', 'medium', 'high'].map(p => (
                      <label key={p} className="flex items-center gap-1.5">
                        <input
                          type="radio"
                          name="priority"
                          value={p}
                          checked={newTask.priority === p}
                          onChange={(e) => setNewTask(prev => ({ ...prev, priority: e.target.value }))}
                          className="text-indigo-600 focus:ring-indigo-500"
                        />
                        <span className={`text-sm capitalize ${priorityColors[p]}`}>{p}</span>
                      </label>
                    ))}
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Category</label>
                  <select
                    value={newTask.category}
                    onChange={(e) => setNewTask(prev => ({ ...prev, category: e.target.value }))}
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  >
                    {categories.map(c => (
                      <option key={c} value={c}>{c}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Link to</label>
                  <select
                    value={newTask.linkedTo}
                    onChange={(e) => setNewTask(prev => ({ ...prev, linkedTo: e.target.value }))}
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  >
                    <option value="">None</option>
                    <option value="request">Request / Work Order / Bill</option>
                  </select>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="notifyOnComplete"
                  checked={newTask.notifyOnComplete}
                  onChange={(e) => setNewTask(prev => ({ ...prev, notifyOnComplete: e.target.checked }))}
                  className="w-4 h-4 text-indigo-600 rounded border-slate-300 focus:ring-indigo-500"
                />
                <label htmlFor="notifyOnComplete" className="text-sm text-slate-700">
                  Notify homeowner when complete
                </label>
              </div>
            </div>
            <div className="flex items-center justify-end gap-3 p-4 border-t border-slate-200 bg-slate-50">
              <button
                onClick={() => setShowNewTaskModal(false)}
                className="px-4 py-2 text-sm font-medium text-slate-600 hover:text-slate-800"
              >
                Cancel
              </button>
              <button
                onClick={() => {
                  // In real app, would create the task
                  console.log('Creating task:', newTask);
                  setShowNewTaskModal(false);
                  setNewTask({
                    householdId: '',
                    title: '',
                    description: '',
                    dueDate: '',
                    source: 'manager',
                    priority: 'medium',
                    category: 'General',
                    linkedTo: '',
                    notifyOnComplete: false,
                  });
                }}
                disabled={!newTask.householdId || !newTask.title || !newTask.dueDate}
                className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Create Task
                <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Complete Task Modal */}
      {showCompleteModal && completingTask && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl max-w-lg w-full">
            <div className="flex items-center justify-between p-4 border-b border-slate-200">
              <h2 className="text-lg font-semibold text-slate-900 flex items-center gap-2">
                <CheckCircle2 className="w-5 h-5 text-emerald-600" />
                Complete Task
              </h2>
              <button
                onClick={() => {
                  setShowCompleteModal(false);
                  setCompletingTask(null);
                }}
                className="text-slate-400 hover:text-slate-600"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="p-4 space-y-4">
              <div className="bg-slate-50 rounded-lg p-3">
                <p className="font-medium text-slate-900">{completingTask.title}</p>
                <p className="text-sm text-slate-500">{completingTask.householdName}</p>
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">
                  Completion Summary <span className="text-red-500">*</span>
                </label>
                <textarea
                  placeholder="Describe what was accomplished..."
                  rows={3}
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">
                  Attachments
                </label>
                <div className="border-2 border-dashed border-slate-200 rounded-lg p-4 text-center">
                  <Upload className="w-6 h-6 text-slate-400 mx-auto mb-2" />
                  <p className="text-sm text-slate-500">Drop files here or click to upload</p>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="followUp"
                  className="w-4 h-4 text-indigo-600 rounded border-slate-300 focus:ring-indigo-500"
                />
                <label htmlFor="followUp" className="text-sm text-slate-700">
                  Create follow-up task
                </label>
              </div>

              <div className="bg-indigo-50 rounded-lg p-3 border border-indigo-100">
                <div className="flex items-center gap-2 mb-2">
                  <Bell className="w-4 h-4 text-indigo-600" />
                  <p className="text-sm font-medium text-indigo-700">Message Preview</p>
                </div>
                <p className="text-sm text-indigo-900">
                  A message will be sent to {completingTask.householdName} notifying them that this task has been completed.
                </p>
              </div>
            </div>
            <div className="flex items-center justify-end gap-3 p-4 border-t border-slate-200 bg-slate-50">
              <button
                onClick={() => {
                  setShowCompleteModal(false);
                  setCompletingTask(null);
                }}
                className="px-4 py-2 text-sm font-medium text-slate-600 hover:text-slate-800"
              >
                Cancel
              </button>
              <button
                onClick={handleCompleteWithMessage}
                className="inline-flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white text-sm font-medium rounded-lg hover:bg-emerald-700 transition-colors"
              >
                <Send className="w-4 h-4" />
                Complete & Send
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
