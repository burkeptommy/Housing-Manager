'use client';

import { useState } from 'react';
import {
  HardHat,
  Phone,
  MessageCircle,
  MapPin,
  Calendar,
  Clock,
  CheckCircle2,
  Circle,
  ChevronRight,
  ChevronDown,
  ClipboardList,
  User,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

type HandymanStatus = 'on_duty' | 'on_job' | 'break' | 'off_duty' | 'unavailable';
type TaskStatus = 'current' | 'upcoming' | 'completed';

interface ScheduleItem {
  id: string;
  time: string;
  household: string;
  task: string;
  workOrderId?: string;
  status: TaskStatus;
}

interface Handyman {
  id: string;
  name: string;
  role: string;
  serviceArea: string;
  status: HandymanStatus;
  phone: string;
  email: string;
  currentLocation?: string;
  currentTask?: {
    household: string;
    task: string;
    workOrderId: string;
    checkInTime: string;
    startedAgo: string;
  };
  todaySchedule: ScheduleItem[];
  stats: {
    tasksToday: number;
    tasksCompleted: number;
    avgRating: number;
  };
}

interface UnassignedTask {
  id: string;
  household: string;
  address: string;
  task: string;
  priority: 'urgent' | 'high' | 'medium' | 'low';
  dueDate: string;
  workOrderId: string;
}

// ============================================================================
// MOCK DATA
// ============================================================================

const mockHandymen: Handyman[] = [
  {
    id: 'h1',
    name: 'Mike Rodriguez',
    role: 'Primary Handyman',
    serviceArea: 'Austin Area',
    status: 'on_job',
    phone: '(512) 555-0101',
    email: 'mike@haven.app',
    currentLocation: 'Smith Residence',
    currentTask: {
      household: 'Smith Family',
      task: 'Kitchen faucet repair',
      workOrderId: 'WO-1893',
      checkInTime: '9:15 AM',
      startedAgo: '35m ago',
    },
    todaySchedule: [
      { id: 's1', time: '9:00 AM', household: 'Smith', task: 'Faucet repair', workOrderId: 'WO-1893', status: 'current' },
      { id: 's2', time: '11:00 AM', household: 'Johnson', task: 'Garage door', workOrderId: 'WO-1894', status: 'upcoming' },
      { id: 's3', time: '2:00 PM', household: 'Miller', task: 'Monthly round', status: 'upcoming' },
    ],
    stats: {
      tasksToday: 3,
      tasksCompleted: 0,
      avgRating: 4.9,
    },
  },
  {
    id: 'h2',
    name: 'Carlos Mendez',
    role: 'Handyman',
    serviceArea: 'Round Rock',
    status: 'on_duty',
    phone: '(512) 555-0102',
    email: 'carlos@haven.app',
    todaySchedule: [
      { id: 's4', time: '10:00 AM', household: 'Davis', task: 'Light fixture install', workOrderId: 'WO-1895', status: 'upcoming' },
      { id: 's5', time: '1:00 PM', household: 'Wilson', task: 'Door hinge repair', workOrderId: 'WO-1896', status: 'upcoming' },
    ],
    stats: {
      tasksToday: 2,
      tasksCompleted: 0,
      avgRating: 4.7,
    },
  },
  {
    id: 'h3',
    name: 'James Taylor',
    role: 'Handyman',
    serviceArea: 'Cedar Park',
    status: 'break',
    phone: '(512) 555-0103',
    email: 'james@haven.app',
    todaySchedule: [
      { id: 's6', time: '8:00 AM', household: 'Brown', task: 'HVAC filter change', status: 'completed' },
      { id: 's7', time: '11:30 AM', household: 'Garcia', task: 'Toilet running', workOrderId: 'WO-1897', status: 'upcoming' },
      { id: 's8', time: '3:00 PM', household: 'Martinez', task: 'Smoke detector install', status: 'upcoming' },
    ],
    stats: {
      tasksToday: 3,
      tasksCompleted: 1,
      avgRating: 4.8,
    },
  },
];

const mockUnassignedTasks: UnassignedTask[] = [
  {
    id: 'u1',
    household: 'Thompson Family',
    address: '789 Cedar Lane',
    task: 'Replace bathroom exhaust fan',
    priority: 'medium',
    dueDate: 'Dec 24',
    workOrderId: 'WO-1898',
  },
  {
    id: 'u2',
    household: 'Anderson Family',
    address: '321 Maple Drive',
    task: 'Fix squeaky floor in bedroom',
    priority: 'low',
    dueDate: 'Dec 26',
    workOrderId: 'WO-1899',
  },
  {
    id: 'u3',
    household: 'Clark Family',
    address: '555 Oak Street',
    task: 'Repair fence gate latch',
    priority: 'high',
    dueDate: 'Dec 23',
    workOrderId: 'WO-1900',
  },
];

// ============================================================================
// STATUS CONFIG
// ============================================================================

const statusConfig: Record<HandymanStatus, { label: string; color: string; bgColor: string; icon: string }> = {
  on_duty: { label: 'On Duty', color: 'text-emerald-600', bgColor: 'bg-emerald-100', icon: '🟢' },
  on_job: { label: 'On Job', color: 'text-blue-600', bgColor: 'bg-blue-100', icon: '🔵' },
  break: { label: 'Break', color: 'text-amber-600', bgColor: 'bg-amber-100', icon: '🟡' },
  off_duty: { label: 'Off Duty', color: 'text-slate-500', bgColor: 'bg-slate-100', icon: '⚪' },
  unavailable: { label: 'Unavailable', color: 'text-red-600', bgColor: 'bg-red-100', icon: '🔴' },
};

const priorityConfig: Record<UnassignedTask['priority'], { label: string; color: string; bgColor: string }> = {
  urgent: { label: 'Urgent', color: 'text-red-700', bgColor: 'bg-red-100' },
  high: { label: 'High', color: 'text-amber-700', bgColor: 'bg-amber-100' },
  medium: { label: 'Medium', color: 'text-blue-700', bgColor: 'bg-blue-100' },
  low: { label: 'Low', color: 'text-slate-600', bgColor: 'bg-slate-100' },
};

// ============================================================================
// MAIN COMPONENT
// ============================================================================

export default function HandymanHubPage() {
  const [handymen] = useState<Handyman[]>(mockHandymen);
  const [unassignedTasks] = useState<UnassignedTask[]>(mockUnassignedTasks);
  const [expandedHandyman, setExpandedHandyman] = useState<string | null>('h1');

  const toggleHandymanExpanded = (handymanId: string) => {
    setExpandedHandyman(prev => prev === handymanId ? null : handymanId);
  };

  const activeHandymen = handymen.filter(h => h.status !== 'off_duty' && h.status !== 'unavailable');
  const totalTasksToday = handymen.reduce((sum, h) => sum + h.stats.tasksToday, 0);
  const completedTasks = handymen.reduce((sum, h) => sum + h.stats.tasksCompleted, 0);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 bg-indigo-100 rounded-xl flex items-center justify-center">
              <HardHat className="w-6 h-6 text-indigo-600" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-slate-900">Handyman Team</h1>
              <p className="text-slate-500">Manage your handyman staff and assignments</p>
            </div>
          </div>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="bg-emerald-50 rounded-xl p-4 border border-emerald-100">
            <p className="text-2xl font-bold text-slate-900">{activeHandymen.length}</p>
            <p className="text-sm text-slate-600">Active Today</p>
          </div>
          <div className="bg-blue-50 rounded-xl p-4 border border-blue-100">
            <p className="text-2xl font-bold text-slate-900">{handymen.filter(h => h.status === 'on_job').length}</p>
            <p className="text-sm text-slate-600">Currently On Job</p>
          </div>
          <div className="bg-slate-50 rounded-xl p-4 border border-slate-100">
            <p className="text-2xl font-bold text-slate-900">{completedTasks}/{totalTasksToday}</p>
            <p className="text-sm text-slate-600">Tasks Completed</p>
          </div>
          <div className="bg-amber-50 rounded-xl p-4 border border-amber-100">
            <p className="text-2xl font-bold text-slate-900">{unassignedTasks.length}</p>
            <p className="text-sm text-slate-600">Unassigned Tasks</p>
          </div>
        </div>
      </div>

      {/* Active Handymen */}
      <div>
        <h2 className="text-lg font-semibold text-slate-900 mb-4">Active Handymen</h2>
        <div className="space-y-4">
          {activeHandymen.map(handyman => {
            const status = statusConfig[handyman.status];
            const isExpanded = expandedHandyman === handyman.id;

            return (
              <div key={handyman.id} className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
                {/* Handyman Header */}
                <button
                  onClick={() => toggleHandymanExpanded(handyman.id)}
                  className="w-full p-4 flex items-center justify-between hover:bg-slate-50 transition-colors"
                >
                  <div className="flex items-center gap-4">
                    <div className="w-12 h-12 bg-indigo-100 rounded-full flex items-center justify-center">
                      <User className="w-6 h-6 text-indigo-600" />
                    </div>
                    <div className="text-left">
                      <div className="flex items-center gap-2">
                        <h3 className="font-semibold text-slate-900">{handyman.name}</h3>
                        <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${status.bgColor} ${status.color}`}>
                          <span>{status.icon}</span>
                          {status.label}
                        </span>
                      </div>
                      <p className="text-sm text-slate-500">{handyman.role} - {handyman.serviceArea}</p>
                    </div>
                  </div>
                  {isExpanded ? (
                    <ChevronDown className="w-5 h-5 text-slate-400" />
                  ) : (
                    <ChevronRight className="w-5 h-5 text-slate-400" />
                  )}
                </button>

                {/* Expanded Content */}
                {isExpanded && (
                  <div className="border-t border-slate-100 p-4">
                    {/* Current Task */}
                    {handyman.currentTask && (
                      <div className="bg-blue-50 rounded-lg p-4 mb-4 border border-blue-100">
                        <div className="flex items-center gap-2 mb-2">
                          <MapPin className="w-4 h-4 text-blue-600" />
                          <span className="text-sm font-medium text-blue-800">Currently at: {handyman.currentLocation}</span>
                          <span className="text-sm text-blue-600">Checked in {handyman.currentTask.checkInTime}</span>
                        </div>
                        <div className="flex items-center gap-2">
                          <ClipboardList className="w-4 h-4 text-blue-600" />
                          <span className="text-sm text-blue-800">
                            Task: {handyman.currentTask.task} ({handyman.currentTask.workOrderId})
                          </span>
                          <span className="text-sm text-blue-600">Started {handyman.currentTask.startedAgo}</span>
                        </div>
                      </div>
                    )}

                    {/* Today's Schedule */}
                    <div className="mb-4">
                      <h4 className="text-sm font-medium text-slate-500 uppercase tracking-wide mb-3">Today&apos;s Schedule</h4>
                      <div className="space-y-2">
                        {handyman.todaySchedule.map(item => (
                          <div
                            key={item.id}
                            className={`flex items-center gap-3 py-2 ${
                              item.status === 'current' ? 'text-blue-900' :
                              item.status === 'completed' ? 'text-slate-400' : 'text-slate-700'
                            }`}
                          >
                            {item.status === 'completed' ? (
                              <CheckCircle2 className="w-5 h-5 text-emerald-500 flex-shrink-0" />
                            ) : item.status === 'current' ? (
                              <div className="w-5 h-5 flex-shrink-0 flex items-center justify-center">
                                <div className="w-3 h-3 bg-blue-500 rounded-full animate-pulse" />
                              </div>
                            ) : (
                              <Circle className="w-5 h-5 text-slate-300 flex-shrink-0" />
                            )}
                            <span className="w-20 text-sm font-medium flex-shrink-0">{item.time}</span>
                            <span className={`text-sm ${item.status === 'completed' ? 'line-through' : ''}`}>
                              {item.household} - {item.task}
                              {item.workOrderId && (
                                <span className="text-xs text-slate-400 ml-1">({item.workOrderId})</span>
                              )}
                            </span>
                            {item.status === 'current' && (
                              <span className="ml-auto text-xs font-medium text-blue-600 bg-blue-100 px-2 py-0.5 rounded">
                                Current
                              </span>
                            )}
                          </div>
                        ))}
                      </div>
                    </div>

                    {/* Actions */}
                    <div className="flex items-center gap-2 pt-2 border-t border-slate-100">
                      <a
                        href={`tel:${handyman.phone}`}
                        className="inline-flex items-center gap-1.5 px-3 py-2 text-sm font-medium text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors"
                      >
                        <Phone className="w-4 h-4" />
                        Call
                      </a>
                      <button className="inline-flex items-center gap-1.5 px-3 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg transition-colors">
                        <MessageCircle className="w-4 h-4" />
                        Message
                      </button>
                      <button className="inline-flex items-center gap-1.5 px-3 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg transition-colors">
                        <MapPin className="w-4 h-4" />
                        Track
                      </button>
                      <button className="inline-flex items-center gap-1.5 px-3 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg transition-colors">
                        <Calendar className="w-4 h-4" />
                        Full Schedule
                      </button>
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>

      {/* Unassigned Tasks */}
      <div>
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <h2 className="text-lg font-semibold text-slate-900">Unassigned Tasks</h2>
            <span className="px-2 py-0.5 bg-amber-100 text-amber-700 text-sm font-medium rounded-full">
              {unassignedTasks.length}
            </span>
          </div>
          <button className="inline-flex items-center gap-1 px-3 py-1.5 text-sm font-medium text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors">
            Assign All
            <ChevronRight className="w-4 h-4" />
          </button>
        </div>

        <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
          {unassignedTasks.map((task, index) => {
            const priority = priorityConfig[task.priority];
            return (
              <div
                key={task.id}
                className={`p-4 flex items-center justify-between ${
                  index < unassignedTasks.length - 1 ? 'border-b border-slate-100' : ''
                }`}
              >
                <div className="flex items-start gap-4">
                  <div className="w-10 h-10 bg-slate-100 rounded-lg flex items-center justify-center flex-shrink-0">
                    <ClipboardList className="w-5 h-5 text-slate-500" />
                  </div>
                  <div>
                    <div className="flex items-center gap-2 mb-1">
                      <h4 className="font-medium text-slate-900">{task.task}</h4>
                      <span className={`px-2 py-0.5 text-xs font-medium rounded-full ${priority.bgColor} ${priority.color}`}>
                        {priority.label}
                      </span>
                    </div>
                    <p className="text-sm text-slate-500">
                      {task.household} • {task.address}
                    </p>
                    <div className="flex items-center gap-3 mt-1 text-sm text-slate-400">
                      <span className="flex items-center gap-1">
                        <Clock className="w-3.5 h-3.5" />
                        Due: {task.dueDate}
                      </span>
                      <span>{task.workOrderId}</span>
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-2">
                  <select className="px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500">
                    <option value="">Assign to...</option>
                    {activeHandymen.map(h => (
                      <option key={h.id} value={h.id}>{h.name}</option>
                    ))}
                  </select>
                  <button className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-lg transition-colors">
                    <ChevronRight className="w-5 h-5" />
                  </button>
                </div>
              </div>
            );
          })}

          {unassignedTasks.length === 0 && (
            <div className="p-8 text-center">
              <CheckCircle2 className="w-12 h-12 text-emerald-500 mx-auto mb-3" />
              <h3 className="text-lg font-medium text-slate-900 mb-1">All tasks assigned!</h3>
              <p className="text-slate-500">No unassigned tasks at the moment</p>
            </div>
          )}
        </div>
      </div>

      {/* Off-Duty Handymen */}
      {handymen.filter(h => h.status === 'off_duty' || h.status === 'unavailable').length > 0 && (
        <div>
          <h2 className="text-lg font-semibold text-slate-900 mb-4">Off Duty / Unavailable</h2>
          <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4">
            <div className="flex flex-wrap gap-4">
              {handymen.filter(h => h.status === 'off_duty' || h.status === 'unavailable').map(handyman => {
                const status = statusConfig[handyman.status];
                return (
                  <div key={handyman.id} className="flex items-center gap-3 text-slate-500">
                    <div className="w-8 h-8 bg-slate-100 rounded-full flex items-center justify-center">
                      <User className="w-4 h-4 text-slate-400" />
                    </div>
                    <span className="font-medium">{handyman.name}</span>
                    <span className={`text-xs ${status.color}`}>{status.icon} {status.label}</span>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
