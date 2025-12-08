'use client';

import { useState, useCallback } from 'react';
import type { ServiceRequestDetail, ServiceRequestStatus, ServiceRequestPriority } from '@haven/core';

interface KanbanColumn {
  id: ServiceRequestStatus;
  title: string;
  color: string;
}

const COLUMNS: KanbanColumn[] = [
  { id: 'SUBMITTED', title: 'New', color: 'blue' },
  { id: 'ASSIGNED', title: 'Assigned', color: 'purple' },
  { id: 'IN_PROGRESS', title: 'In Progress', color: 'yellow' },
  { id: 'COMPLETED', title: 'Completed', color: 'green' },
];

interface KanbanBoardProps {
  requests: ServiceRequestDetail[];
  onStatusChange: (requestId: string, newStatus: ServiceRequestStatus) => Promise<void>;
  onRequestClick: (request: ServiceRequestDetail) => void;
}

export function KanbanBoard({ requests, onStatusChange, onRequestClick }: KanbanBoardProps) {
  const [draggedRequest, setDraggedRequest] = useState<ServiceRequestDetail | null>(null);
  const [dragOverColumn, setDragOverColumn] = useState<ServiceRequestStatus | null>(null);

  const getRequestsByStatus = useCallback(
    (status: ServiceRequestStatus) => {
      return requests.filter((r) => r.status === status);
    },
    [requests]
  );

  const handleDragStart = (e: React.DragEvent, request: ServiceRequestDetail) => {
    setDraggedRequest(request);
    e.dataTransfer.effectAllowed = 'move';
    e.dataTransfer.setData('text/plain', request.id);
  };

  const handleDragEnd = () => {
    setDraggedRequest(null);
    setDragOverColumn(null);
  };

  const handleDragOver = (e: React.DragEvent, columnId: ServiceRequestStatus) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
    setDragOverColumn(columnId);
  };

  const handleDragLeave = () => {
    setDragOverColumn(null);
  };

  const handleDrop = async (e: React.DragEvent, columnId: ServiceRequestStatus) => {
    e.preventDefault();
    setDragOverColumn(null);

    if (draggedRequest && draggedRequest.status !== columnId) {
      await onStatusChange(draggedRequest.id, columnId);
    }

    setDraggedRequest(null);
  };

  return (
    <div className="flex gap-4 overflow-x-auto pb-4">
      {COLUMNS.map((column) => (
        <KanbanColumn
          key={column.id}
          column={column}
          requests={getRequestsByStatus(column.id)}
          isDragOver={dragOverColumn === column.id}
          onDragOver={(e) => handleDragOver(e, column.id)}
          onDragLeave={handleDragLeave}
          onDrop={(e) => handleDrop(e, column.id)}
          onDragStart={handleDragStart}
          onDragEnd={handleDragEnd}
          onRequestClick={onRequestClick}
          draggedRequest={draggedRequest}
        />
      ))}
    </div>
  );
}

interface KanbanColumnProps {
  column: KanbanColumn;
  requests: ServiceRequestDetail[];
  isDragOver: boolean;
  onDragOver: (e: React.DragEvent) => void;
  onDragLeave: () => void;
  onDrop: (e: React.DragEvent) => void;
  onDragStart: (e: React.DragEvent, request: ServiceRequestDetail) => void;
  onDragEnd: () => void;
  onRequestClick: (request: ServiceRequestDetail) => void;
  draggedRequest: ServiceRequestDetail | null;
}

function KanbanColumn({
  column,
  requests,
  isDragOver,
  onDragOver,
  onDragLeave,
  onDrop,
  onDragStart,
  onDragEnd,
  onRequestClick,
  draggedRequest,
}: KanbanColumnProps) {
  const colorClasses = {
    blue: 'bg-blue-500',
    purple: 'bg-purple-500',
    yellow: 'bg-yellow-500',
    green: 'bg-green-500',
  };

  return (
    <div
      className={`flex-shrink-0 w-80 rounded-lg transition-colors ${
        isDragOver
          ? 'bg-slate-200 dark:bg-slate-700'
          : 'bg-slate-100 dark:bg-slate-800'
      }`}
      onDragOver={onDragOver}
      onDragLeave={onDragLeave}
      onDrop={onDrop}
    >
      {/* Column Header */}
      <div className="flex items-center gap-2 p-3 border-b border-slate-200 dark:border-slate-700">
        <div className={`w-2 h-2 rounded-full ${colorClasses[column.color as keyof typeof colorClasses]}`} />
        <h3 className="font-medium text-slate-900 dark:text-white">{column.title}</h3>
        <span className="ml-auto text-sm text-slate-500 dark:text-slate-400 bg-slate-200 dark:bg-slate-700 px-2 py-0.5 rounded-full">
          {requests.length}
        </span>
      </div>

      {/* Column Content */}
      <div className="p-2 space-y-2 min-h-[200px] max-h-[calc(100vh-300px)] overflow-y-auto">
        {requests.map((request) => (
          <KanbanCard
            key={request.id}
            request={request}
            onDragStart={onDragStart}
            onDragEnd={onDragEnd}
            onClick={() => onRequestClick(request)}
            isDragging={draggedRequest?.id === request.id}
          />
        ))}
        {requests.length === 0 && (
          <div className="flex items-center justify-center h-20 text-sm text-slate-400 dark:text-slate-500">
            No requests
          </div>
        )}
      </div>
    </div>
  );
}

interface KanbanCardProps {
  request: ServiceRequestDetail;
  onDragStart: (e: React.DragEvent, request: ServiceRequestDetail) => void;
  onDragEnd: () => void;
  onClick: () => void;
  isDragging: boolean;
}

function KanbanCard({ request, onDragStart, onDragEnd, onClick, isDragging }: KanbanCardProps) {
  const priorityColors: Record<ServiceRequestPriority, string> = {
    LOW: 'bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-400',
    MEDIUM: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
    HIGH: 'bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400',
    URGENT: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400',
  };

  return (
    <div
      draggable
      onDragStart={(e) => onDragStart(e, request)}
      onDragEnd={onDragEnd}
      onClick={onClick}
      className={`bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-700 p-3 cursor-pointer hover:shadow-md transition-all ${
        isDragging ? 'opacity-50 scale-95' : ''
      }`}
    >
      {/* Header */}
      <div className="flex items-start justify-between gap-2 mb-2">
        <h4 className="font-medium text-slate-900 dark:text-white text-sm line-clamp-2">
          {request.title}
        </h4>
        <span className={`flex-shrink-0 text-xs font-medium px-2 py-0.5 rounded ${priorityColors[request.priority]}`}>
          {request.priority}
        </span>
      </div>

      {/* Description */}
      <p className="text-xs text-slate-500 dark:text-slate-400 line-clamp-2 mb-3">
        {request.description}
      </p>

      {/* Meta */}
      <div className="flex items-center justify-between text-xs">
        <div className="flex items-center gap-1 text-slate-500 dark:text-slate-400">
          <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
          </svg>
          <span className="truncate max-w-[100px]">{request.household?.name}</span>
        </div>
        {request.serviceCategory && (
          <span className="text-slate-400 dark:text-slate-500 truncate max-w-[80px]">
            {request.serviceCategory.name}
          </span>
        )}
      </div>

      {/* Vendor / Scheduled */}
      {(request.vendor || request.scheduledDate) && (
        <div className="mt-2 pt-2 border-t border-slate-100 dark:border-slate-800 flex items-center gap-2 text-xs">
          {request.vendor && (
            <div className="flex items-center gap-1 text-emerald-600 dark:text-emerald-400">
              <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
              </svg>
              <span className="truncate max-w-[80px]">{request.vendor.companyName}</span>
            </div>
          )}
          {request.scheduledDate && (
            <div className="flex items-center gap-1 text-slate-500 dark:text-slate-400 ml-auto">
              <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
              <span>{new Date(request.scheduledDate).toLocaleDateString()}</span>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
