# Haven: Approval System

**Created:** December 28, 2024  
**Purpose:** Build the approval workflow for expenses and decisions  
**Priority:** High - Core to Haven's trust model

---

## CRITICAL RULES

1. **DO NOT DELETE existing code** - Only add and refactor
2. **All existing portals must continue working**
3. **Build on existing database models where possible**

---

## Overview

The Approval System lets Home Managers request approval from Homeowners before taking action on significant expenses or decisions.

### Flow

```
Sarah finds $2,800 HVAC repair needed
    ↓
Sarah creates Approval Request in /manager
    ↓
Bob sees pending approval in /app
    ↓
Bob approves, rejects, or asks questions
    ↓
Sarah sees decision, takes action
    ↓
Activity logged for both
```

### Approval Types

| Type | Example | Threshold |
|------|---------|-----------|
| EXPENSE | Vendor quote, repair cost | > $500 |
| VENDOR | New vendor selection | Always |
| SERVICE | New recurring service | Always |
| PROJECT | Home improvement project | Always |
| EMERGENCY | Urgent repair (expedited) | > $1000 |

---

## PHASE 1: Database Schema

### Task 1.1: Create Approval Model

Add to `apps/api/prisma/schema.prisma`:

```prisma
model ApprovalRequest {
  id              String            @id @default(uuid())
  householdId     String
  household       Household         @relation(fields: [householdId], references: [id])
  
  // Request details
  type            ApprovalType
  title           String
  description     String?
  amount          Float?
  
  // Linked entities (optional)
  vendorId        String?
  vendor          Vendor?           @relation(fields: [vendorId], references: [id])
  billId          String?
  serviceRequestId String?
  workOrderId     String?
  
  // Status tracking
  status          ApprovalStatus    @default(PENDING)
  priority        ApprovalPriority  @default(NORMAL)
  
  // Who's involved
  requestedById   String
  requestedBy     User              @relation("RequestedApprovals", fields: [requestedById], references: [id])
  decidedById     String?
  decidedBy       User?             @relation("DecidedApprovals", fields: [decidedById], references: [id])
  
  // Timing
  expiresAt       DateTime?
  decidedAt       DateTime?
  
  // Supporting info
  attachments     Json?             // URLs to documents, photos
  notes           String?           // Manager's notes
  homeownerNotes  String?           // Homeowner's response notes
  
  // Audit
  createdAt       DateTime          @default(now())
  updatedAt       DateTime          @updatedAt
  
  // Related
  comments        ApprovalComment[]
  
  @@index([householdId])
  @@index([status])
  @@index([requestedById])
}

model ApprovalComment {
  id                String          @id @default(uuid())
  approvalRequestId String
  approvalRequest   ApprovalRequest @relation(fields: [approvalRequestId], references: [id], onDelete: Cascade)
  
  authorId          String
  author            User            @relation(fields: [authorId], references: [id])
  
  content           String
  
  createdAt         DateTime        @default(now())
  
  @@index([approvalRequestId])
}

enum ApprovalType {
  EXPENSE
  VENDOR
  SERVICE
  PROJECT
  EMERGENCY
  OTHER
}

enum ApprovalStatus {
  PENDING
  APPROVED
  REJECTED
  EXPIRED
  CANCELLED
}

enum ApprovalPriority {
  LOW
  NORMAL
  HIGH
  URGENT
}
```

### Task 1.2: Update Household Model

Add relation to Household:

```prisma
model Household {
  // ... existing fields
  approvalRequests ApprovalRequest[]
}
```

### Task 1.3: Update User Model

Add relations to User:

```prisma
model User {
  // ... existing fields
  requestedApprovals ApprovalRequest[] @relation("RequestedApprovals")
  decidedApprovals   ApprovalRequest[] @relation("DecidedApprovals")
  approvalComments   ApprovalComment[]
}
```

### Task 1.4: Run Migration

```bash
cd apps/api
pnpm prisma migrate dev --name add-approval-system
pnpm prisma generate
```

---

## PHASE 2: Approval API Endpoints

### Task 2.1: Create Approval Service

Create `apps/api/src/approval/approval.service.ts`:

```typescript
import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ApprovalStatus, ApprovalType, ApprovalPriority } from '@prisma/client';

@Injectable()
export class ApprovalService {
  constructor(private prisma: PrismaService) {}

  // =========================================================================
  // CREATE APPROVAL REQUEST (Manager)
  // =========================================================================
  
  async createApprovalRequest(
    managerId: string,
    data: {
      householdId: string;
      type: ApprovalType;
      title: string;
      description?: string;
      amount?: number;
      vendorId?: string;
      priority?: ApprovalPriority;
      attachments?: string[];
      notes?: string;
      expiresInDays?: number;
    }
  ) {
    // Verify manager has access to this household
    const hasAccess = await this.prisma.householdSettings.findFirst({
      where: { householdId: data.householdId, homeManagerId: managerId },
    });

    if (!hasAccess) {
      throw new ForbiddenException('You do not manage this household');
    }

    // Calculate expiration if provided
    const expiresAt = data.expiresInDays
      ? new Date(Date.now() + data.expiresInDays * 24 * 60 * 60 * 1000)
      : null;

    // Create the approval request
    const approval = await this.prisma.approvalRequest.create({
      data: {
        householdId: data.householdId,
        type: data.type,
        title: data.title,
        description: data.description,
        amount: data.amount,
        vendorId: data.vendorId,
        priority: data.priority || 'NORMAL',
        attachments: data.attachments,
        notes: data.notes,
        expiresAt,
        requestedById: managerId,
        status: 'PENDING',
      },
      include: {
        vendor: true,
        requestedBy: {
          select: { id: true, name: true, email: true },
        },
      },
    });

    // Log activity
    await this.prisma.activityLog.create({
      data: {
        householdId: data.householdId,
        actorId: managerId,
        actorType: 'HOME_MANAGER',
        actorName: approval.requestedBy.name || 'Home Manager',
        action: 'APPROVAL_REQUESTED',
        category: 'BILLING',
        title: `Approval requested: ${data.title}`,
        description: data.amount ? `Amount: $${data.amount.toFixed(2)}` : undefined,
        amount: data.amount,
        visibleToHomeowner: true,
        metadata: { approvalId: approval.id },
      },
    });

    return approval;
  }

  // =========================================================================
  // GET APPROVALS (Various views)
  // =========================================================================

  async getPendingApprovalsForHomeowner(userId: string) {
    // Get user's household
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { householdId: true },
    });

    if (!user?.householdId) {
      return [];
    }

    return this.prisma.approvalRequest.findMany({
      where: {
        householdId: user.householdId,
        status: 'PENDING',
      },
      include: {
        vendor: true,
        requestedBy: {
          select: { id: true, name: true, firstName: true },
        },
        comments: {
          include: {
            author: { select: { id: true, name: true, firstName: true } },
          },
          orderBy: { createdAt: 'asc' },
        },
      },
      orderBy: [
        { priority: 'desc' },
        { createdAt: 'asc' },
      ],
    });
  }

  async getApprovalsForHousehold(householdId: string, status?: ApprovalStatus) {
    const where: any = { householdId };
    if (status) {
      where.status = status;
    }

    return this.prisma.approvalRequest.findMany({
      where,
      include: {
        vendor: true,
        requestedBy: {
          select: { id: true, name: true, firstName: true },
        },
        decidedBy: {
          select: { id: true, name: true, firstName: true },
        },
        comments: {
          include: {
            author: { select: { id: true, name: true } },
          },
          orderBy: { createdAt: 'asc' },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getApprovalRequestsForManager(managerId: string, status?: ApprovalStatus) {
    // Get all households this manager manages
    const settings = await this.prisma.householdSettings.findMany({
      where: { homeManagerId: managerId },
      select: { householdId: true },
    });

    const householdIds = settings.map(s => s.householdId);

    const where: any = { householdId: { in: householdIds } };
    if (status) {
      where.status = status;
    }

    return this.prisma.approvalRequest.findMany({
      where,
      include: {
        household: { select: { id: true, name: true } },
        vendor: true,
        decidedBy: {
          select: { id: true, name: true, firstName: true },
        },
        comments: {
          take: 3,
          orderBy: { createdAt: 'desc' },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getApprovalById(approvalId: string) {
    const approval = await this.prisma.approvalRequest.findUnique({
      where: { id: approvalId },
      include: {
        household: { select: { id: true, name: true } },
        vendor: true,
        requestedBy: {
          select: { id: true, name: true, firstName: true, email: true },
        },
        decidedBy: {
          select: { id: true, name: true, firstName: true },
        },
        comments: {
          include: {
            author: { select: { id: true, name: true, firstName: true } },
          },
          orderBy: { createdAt: 'asc' },
        },
      },
    });

    if (!approval) {
      throw new NotFoundException('Approval request not found');
    }

    return approval;
  }

  // =========================================================================
  // DECIDE ON APPROVAL (Homeowner)
  // =========================================================================

  async approveRequest(
    approvalId: string,
    userId: string,
    notes?: string
  ) {
    return this.updateApprovalStatus(approvalId, userId, 'APPROVED', notes);
  }

  async rejectRequest(
    approvalId: string,
    userId: string,
    notes?: string
  ) {
    return this.updateApprovalStatus(approvalId, userId, 'REJECTED', notes);
  }

  private async updateApprovalStatus(
    approvalId: string,
    userId: string,
    status: 'APPROVED' | 'REJECTED',
    notes?: string
  ) {
    // Get the approval
    const approval = await this.prisma.approvalRequest.findUnique({
      where: { id: approvalId },
      include: { household: true },
    });

    if (!approval) {
      throw new NotFoundException('Approval request not found');
    }

    // Verify user belongs to this household
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { householdId: true, name: true, role: true },
    });

    if (user?.householdId !== approval.householdId && user?.role !== 'ADMIN') {
      throw new ForbiddenException('You cannot decide on this approval');
    }

    if (approval.status !== 'PENDING') {
      throw new BadRequestException('This approval has already been decided');
    }

    // Update the approval
    const updated = await this.prisma.approvalRequest.update({
      where: { id: approvalId },
      data: {
        status,
        decidedById: userId,
        decidedAt: new Date(),
        homeownerNotes: notes,
      },
      include: {
        requestedBy: { select: { id: true, name: true } },
        decidedBy: { select: { id: true, name: true } },
      },
    });

    // Log activity
    await this.prisma.activityLog.create({
      data: {
        householdId: approval.householdId,
        actorId: userId,
        actorType: 'HOMEOWNER',
        actorName: user?.name || 'Homeowner',
        action: status === 'APPROVED' ? 'APPROVAL_APPROVED' : 'APPROVAL_REJECTED',
        category: 'BILLING',
        title: `${status === 'APPROVED' ? 'Approved' : 'Rejected'}: ${approval.title}`,
        description: notes,
        amount: approval.amount,
        visibleToHomeowner: true,
        metadata: { approvalId: approval.id },
      },
    });

    return updated;
  }

  // =========================================================================
  // COMMENTS
  // =========================================================================

  async addComment(
    approvalId: string,
    userId: string,
    content: string
  ) {
    // Verify approval exists and user has access
    const approval = await this.prisma.approvalRequest.findUnique({
      where: { id: approvalId },
    });

    if (!approval) {
      throw new NotFoundException('Approval request not found');
    }

    // Check user access (homeowner of household or manager)
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { householdId: true, role: true, name: true },
    });

    const isHomeowner = user?.householdId === approval.householdId;
    const isManager = await this.prisma.householdSettings.findFirst({
      where: { householdId: approval.householdId, homeManagerId: userId },
    });

    if (!isHomeowner && !isManager && user?.role !== 'ADMIN') {
      throw new ForbiddenException('You cannot comment on this approval');
    }

    const comment = await this.prisma.approvalComment.create({
      data: {
        approvalRequestId: approvalId,
        authorId: userId,
        content,
      },
      include: {
        author: { select: { id: true, name: true, firstName: true } },
      },
    });

    return comment;
  }

  // =========================================================================
  // CANCEL (Manager)
  // =========================================================================

  async cancelApproval(approvalId: string, managerId: string) {
    const approval = await this.prisma.approvalRequest.findUnique({
      where: { id: approvalId },
    });

    if (!approval) {
      throw new NotFoundException('Approval request not found');
    }

    if (approval.requestedById !== managerId) {
      throw new ForbiddenException('Only the requester can cancel');
    }

    if (approval.status !== 'PENDING') {
      throw new BadRequestException('Cannot cancel a decided approval');
    }

    return this.prisma.approvalRequest.update({
      where: { id: approvalId },
      data: { status: 'CANCELLED' },
    });
  }
}
```

### Task 2.2: Create Approval Controller

Create `apps/api/src/approval/approval.controller.ts`:

```typescript
import {
  Controller,
  Get,
  Post,
  Put,
  Param,
  Body,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { ApprovalService } from './approval.service';
import { ApprovalType, ApprovalPriority, ApprovalStatus } from '@prisma/client';

@Controller('approvals')
@UseGuards(FirebaseAuthGuard)
export class ApprovalController {
  constructor(private approvalService: ApprovalService) {}

  // =========================================================================
  // MANAGER ENDPOINTS
  // =========================================================================

  @Post()
  async createApproval(
    @Request() req: any,
    @Body() body: {
      householdId: string;
      type: ApprovalType;
      title: string;
      description?: string;
      amount?: number;
      vendorId?: string;
      priority?: ApprovalPriority;
      attachments?: string[];
      notes?: string;
      expiresInDays?: number;
    }
  ) {
    return this.approvalService.createApprovalRequest(
      req.user.userId || req.user.id,
      body
    );
  }

  @Get('manager')
  async getManagerApprovals(
    @Request() req: any,
    @Query('status') status?: ApprovalStatus
  ) {
    return this.approvalService.getApprovalRequestsForManager(
      req.user.userId || req.user.id,
      status
    );
  }

  @Put(':id/cancel')
  async cancelApproval(
    @Request() req: any,
    @Param('id') approvalId: string
  ) {
    return this.approvalService.cancelApproval(
      approvalId,
      req.user.userId || req.user.id
    );
  }

  // =========================================================================
  // HOMEOWNER ENDPOINTS
  // =========================================================================

  @Get('pending')
  async getPendingApprovals(@Request() req: any) {
    return this.approvalService.getPendingApprovalsForHomeowner(
      req.user.userId || req.user.id
    );
  }

  @Get('household/:householdId')
  async getHouseholdApprovals(
    @Param('householdId') householdId: string,
    @Query('status') status?: ApprovalStatus
  ) {
    return this.approvalService.getApprovalsForHousehold(householdId, status);
  }

  @Put(':id/approve')
  async approveRequest(
    @Request() req: any,
    @Param('id') approvalId: string,
    @Body() body: { notes?: string }
  ) {
    return this.approvalService.approveRequest(
      approvalId,
      req.user.userId || req.user.id,
      body.notes
    );
  }

  @Put(':id/reject')
  async rejectRequest(
    @Request() req: any,
    @Param('id') approvalId: string,
    @Body() body: { notes?: string }
  ) {
    return this.approvalService.rejectRequest(
      approvalId,
      req.user.userId || req.user.id,
      body.notes
    );
  }

  // =========================================================================
  // SHARED ENDPOINTS
  // =========================================================================

  @Get(':id')
  async getApproval(@Param('id') approvalId: string) {
    return this.approvalService.getApprovalById(approvalId);
  }

  @Post(':id/comments')
  async addComment(
    @Request() req: any,
    @Param('id') approvalId: string,
    @Body() body: { content: string }
  ) {
    return this.approvalService.addComment(
      approvalId,
      req.user.userId || req.user.id,
      body.content
    );
  }
}
```

### Task 2.3: Create Approval Module

Create `apps/api/src/approval/approval.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { ApprovalController } from './approval.controller';
import { ApprovalService } from './approval.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [ApprovalController],
  providers: [ApprovalService],
  exports: [ApprovalService],
})
export class ApprovalModule {}
```

### Task 2.4: Register Approval Module

Add to `apps/api/src/app.module.ts`:

```typescript
import { ApprovalModule } from './approval/approval.module';

@Module({
  imports: [
    // ... existing imports
    ApprovalModule,
  ],
})
export class AppModule {}
```

---

## PHASE 3: Homeowner Approvals UI

### Task 3.1: Create Approvals Page for Homeowner

Create `apps/web/src/app/app/approvals/page.tsx`:

```typescript
'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@/contexts/auth-context';
import { getIdToken } from '@/lib/firebase';
import {
  CheckCircle,
  XCircle,
  Clock,
  AlertTriangle,
  DollarSign,
  MessageCircle,
  ChevronRight,
  Loader2,
  Send,
} from 'lucide-react';

interface Approval {
  id: string;
  type: string;
  title: string;
  description: string;
  amount: number | null;
  status: string;
  priority: string;
  notes: string | null;
  createdAt: string;
  expiresAt: string | null;
  requestedBy: {
    id: string;
    name: string;
    firstName: string;
  };
  vendor: {
    id: string;
    displayName: string;
  } | null;
  comments: Array<{
    id: string;
    content: string;
    createdAt: string;
    author: { id: string; name: string; firstName: string };
  }>;
}

export default function ApprovalsPage() {
  const { user } = useAuth();
  const [approvals, setApprovals] = useState<Approval[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedApproval, setSelectedApproval] = useState<Approval | null>(null);
  const [comment, setComment] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [filter, setFilter] = useState<'pending' | 'all'>('pending');

  useEffect(() => {
    loadApprovals();
  }, [filter]);

  const loadApprovals = async () => {
    try {
      setLoading(true);
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';
      
      const endpoint = filter === 'pending' 
        ? '/approvals/pending'
        : `/approvals/household/${user?.householdId}`;
      
      const response = await fetch(`${apiUrl}${endpoint}`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (response.ok) {
        setApprovals(await response.json());
      }
    } catch (error) {
      console.error('Failed to load approvals:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDecision = async (approvalId: string, decision: 'approve' | 'reject') => {
    try {
      setSubmitting(true);
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';
      
      const response = await fetch(`${apiUrl}/approvals/${approvalId}/${decision}`, {
        method: 'PUT',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ notes: comment }),
      });

      if (response.ok) {
        setComment('');
        setSelectedApproval(null);
        loadApprovals();
      }
    } catch (error) {
      console.error('Failed to submit decision:', error);
    } finally {
      setSubmitting(false);
    }
  };

  const handleAddComment = async (approvalId: string) => {
    if (!comment.trim()) return;
    
    try {
      setSubmitting(true);
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';
      
      await fetch(`${apiUrl}/approvals/${approvalId}/comments`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ content: comment }),
      });

      setComment('');
      loadApprovals();
    } catch (error) {
      console.error('Failed to add comment:', error);
    } finally {
      setSubmitting(false);
    }
  };

  const priorityStyles = {
    URGENT: 'bg-red-100 text-red-700 border-red-200',
    HIGH: 'bg-orange-100 text-orange-700 border-orange-200',
    NORMAL: 'bg-blue-100 text-blue-700 border-blue-200',
    LOW: 'bg-gray-100 text-gray-700 border-gray-200',
  };

  const typeIcons = {
    EXPENSE: '💰',
    VENDOR: '👷',
    SERVICE: '🔧',
    PROJECT: '🏠',
    EMERGENCY: '🚨',
    OTHER: '📋',
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-8 h-8 animate-spin text-indigo-600" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Approvals</h1>
          <p className="text-gray-500">Review and approve requests from your Home Manager</p>
        </div>
        <div className="flex gap-2">
          <button
            onClick={() => setFilter('pending')}
            className={`px-4 py-2 rounded-lg text-sm font-medium ${
              filter === 'pending'
                ? 'bg-indigo-600 text-white'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            }`}
          >
            Pending ({approvals.filter(a => a.status === 'PENDING').length})
          </button>
          <button
            onClick={() => setFilter('all')}
            className={`px-4 py-2 rounded-lg text-sm font-medium ${
              filter === 'all'
                ? 'bg-indigo-600 text-white'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            }`}
          >
            All History
          </button>
        </div>
      </div>

      {/* Approvals List */}
      {approvals.length === 0 ? (
        <div className="text-center py-12 bg-white rounded-xl border border-gray-200">
          <CheckCircle className="w-12 h-12 text-green-500 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900">All caught up!</h3>
          <p className="text-gray-500">No pending approvals at this time.</p>
        </div>
      ) : (
        <div className="space-y-4">
          {approvals.map((approval) => (
            <div
              key={approval.id}
              className={`bg-white rounded-xl border ${
                approval.status === 'PENDING' ? 'border-amber-200' : 'border-gray-200'
              } overflow-hidden`}
            >
              {/* Header */}
              <div
                className="p-5 cursor-pointer hover:bg-gray-50"
                onClick={() => setSelectedApproval(
                  selectedApproval?.id === approval.id ? null : approval
                )}
              >
                <div className="flex items-start justify-between">
                  <div className="flex items-start gap-4">
                    <div className="text-2xl">
                      {typeIcons[approval.type as keyof typeof typeIcons] || '📋'}
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <h3 className="font-semibold text-gray-900">{approval.title}</h3>
                        <span className={`px-2 py-0.5 rounded text-xs font-medium ${
                          priorityStyles[approval.priority as keyof typeof priorityStyles]
                        }`}>
                          {approval.priority}
                        </span>
                      </div>
                      <p className="text-sm text-gray-500 mt-1">
                        From {approval.requestedBy.firstName || approval.requestedBy.name}
                        {approval.vendor && ` • ${approval.vendor.displayName}`}
                      </p>
                      {approval.description && (
                        <p className="text-sm text-gray-600 mt-2">{approval.description}</p>
                      )}
                    </div>
                  </div>
                  <div className="flex items-center gap-4">
                    {approval.amount && (
                      <div className="text-right">
                        <p className="text-2xl font-bold text-gray-900">
                          ${approval.amount.toLocaleString()}
                        </p>
                      </div>
                    )}
                    {approval.status === 'PENDING' ? (
                      <Clock className="w-5 h-5 text-amber-500" />
                    ) : approval.status === 'APPROVED' ? (
                      <CheckCircle className="w-5 h-5 text-green-500" />
                    ) : (
                      <XCircle className="w-5 h-5 text-red-500" />
                    )}
                    <ChevronRight className={`w-5 h-5 text-gray-400 transition-transform ${
                      selectedApproval?.id === approval.id ? 'rotate-90' : ''
                    }`} />
                  </div>
                </div>
              </div>

              {/* Expanded Details */}
              {selectedApproval?.id === approval.id && (
                <div className="border-t border-gray-100 p-5 bg-gray-50">
                  {/* Manager Notes */}
                  {approval.notes && (
                    <div className="mb-4 p-4 bg-white rounded-lg border border-gray-200">
                      <p className="text-sm font-medium text-gray-700 mb-1">Manager's Notes:</p>
                      <p className="text-gray-600">{approval.notes}</p>
                    </div>
                  )}

                  {/* Comments */}
                  {approval.comments.length > 0 && (
                    <div className="mb-4 space-y-2">
                      <p className="text-sm font-medium text-gray-700">Discussion:</p>
                      {approval.comments.map((c) => (
                        <div key={c.id} className="p-3 bg-white rounded-lg border border-gray-200">
                          <div className="flex items-center gap-2 mb-1">
                            <span className="text-sm font-medium">{c.author.firstName || c.author.name}</span>
                            <span className="text-xs text-gray-400">
                              {new Date(c.createdAt).toLocaleDateString()}
                            </span>
                          </div>
                          <p className="text-sm text-gray-600">{c.content}</p>
                        </div>
                      ))}
                    </div>
                  )}

                  {/* Actions for Pending */}
                  {approval.status === 'PENDING' && (
                    <div className="space-y-4">
                      {/* Comment Input */}
                      <div className="flex gap-2">
                        <input
                          type="text"
                          value={comment}
                          onChange={(e) => setComment(e.target.value)}
                          placeholder="Add a comment or question..."
                          className="flex-1 px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
                        />
                        <button
                          onClick={() => handleAddComment(approval.id)}
                          disabled={!comment.trim() || submitting}
                          className="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 disabled:opacity-50"
                        >
                          <Send className="w-4 h-4" />
                        </button>
                      </div>

                      {/* Decision Buttons */}
                      <div className="flex gap-3">
                        <button
                          onClick={() => handleDecision(approval.id, 'approve')}
                          disabled={submitting}
                          className="flex-1 flex items-center justify-center gap-2 px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 font-medium"
                        >
                          <CheckCircle className="w-5 h-5" />
                          Approve
                        </button>
                        <button
                          onClick={() => handleDecision(approval.id, 'reject')}
                          disabled={submitting}
                          className="flex-1 flex items-center justify-center gap-2 px-6 py-3 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50 font-medium"
                        >
                          <XCircle className="w-5 h-5" />
                          Reject
                        </button>
                      </div>
                    </div>
                  )}

                  {/* Show decision for resolved */}
                  {approval.status !== 'PENDING' && (
                    <div className={`p-4 rounded-lg ${
                      approval.status === 'APPROVED' ? 'bg-green-50' : 'bg-red-50'
                    }`}>
                      <p className={`font-medium ${
                        approval.status === 'APPROVED' ? 'text-green-700' : 'text-red-700'
                      }`}>
                        {approval.status === 'APPROVED' ? '✓ Approved' : '✗ Rejected'}
                      </p>
                    </div>
                  )}
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
```

### Task 3.2: Add Approvals to Homeowner Navigation

Update `apps/web/src/app/app/layout.tsx` to add Approvals link:

Find the navigation items array and add:

```typescript
{
  name: 'Approvals',
  href: '/app/approvals',
  icon: CheckSquare, // or ClipboardCheck
  badge: pendingApprovalsCount, // optional - show count
}
```

### Task 3.3: Add Pending Approvals to Dashboard

In `apps/web/src/app/app/page.tsx`, add a section showing pending approvals:

```typescript
// Add to dashboard
{pendingApprovals.length > 0 && (
  <div className="bg-amber-50 border border-amber-200 rounded-xl p-4 mb-6">
    <div className="flex items-center gap-2 mb-2">
      <AlertTriangle className="w-5 h-5 text-amber-600" />
      <h3 className="font-semibold text-amber-800">
        {pendingApprovals.length} Pending Approval{pendingApprovals.length > 1 ? 's' : ''}
      </h3>
    </div>
    <p className="text-amber-700 text-sm mb-3">
      Your Home Manager needs your approval on the following:
    </p>
    <Link href="/app/approvals">
      <button className="px-4 py-2 bg-amber-600 text-white rounded-lg hover:bg-amber-700 text-sm font-medium">
        Review Now
      </button>
    </Link>
  </div>
)}
```

---

## PHASE 4: Manager Approvals UI

### Task 4.1: Create Manager Approvals Page

Create `apps/web/src/app/manager/approvals/page.tsx`:

```typescript
'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { getIdToken } from '@/lib/firebase';
import {
  Plus,
  CheckCircle,
  XCircle,
  Clock,
  AlertTriangle,
  Loader2,
  Filter,
} from 'lucide-react';

interface Approval {
  id: string;
  type: string;
  title: string;
  description: string;
  amount: number | null;
  status: string;
  priority: string;
  createdAt: string;
  decidedAt: string | null;
  household: { id: string; name: string };
  decidedBy: { id: string; name: string; firstName: string } | null;
}

export default function ManagerApprovalsPage() {
  const router = useRouter();
  const [approvals, setApprovals] = useState<Approval[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<string>('');

  useEffect(() => {
    loadApprovals();
  }, [statusFilter]);

  const loadApprovals = async () => {
    try {
      setLoading(true);
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';
      
      const params = statusFilter ? `?status=${statusFilter}` : '';
      const response = await fetch(`${apiUrl}/approvals/manager${params}`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (response.ok) {
        setApprovals(await response.json());
      }
    } catch (error) {
      console.error('Failed to load approvals:', error);
    } finally {
      setLoading(false);
    }
  };

  const statusBadge = (status: string) => {
    switch (status) {
      case 'PENDING':
        return <span className="px-2 py-0.5 bg-amber-100 text-amber-700 rounded text-xs font-medium">Pending</span>;
      case 'APPROVED':
        return <span className="px-2 py-0.5 bg-green-100 text-green-700 rounded text-xs font-medium">Approved</span>;
      case 'REJECTED':
        return <span className="px-2 py-0.5 bg-red-100 text-red-700 rounded text-xs font-medium">Rejected</span>;
      default:
        return <span className="px-2 py-0.5 bg-gray-100 text-gray-700 rounded text-xs font-medium">{status}</span>;
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-8 h-8 animate-spin text-indigo-600" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Approval Requests</h1>
          <p className="text-gray-500">Track requests sent to homeowners</p>
        </div>
        <Link href="/manager/approvals/new">
          <button className="flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700">
            <Plus className="w-4 h-4" />
            New Request
          </button>
        </Link>
      </div>

      {/* Filters */}
      <div className="flex gap-2">
        {['', 'PENDING', 'APPROVED', 'REJECTED'].map((status) => (
          <button
            key={status}
            onClick={() => setStatusFilter(status)}
            className={`px-3 py-1.5 rounded-lg text-sm ${
              statusFilter === status
                ? 'bg-indigo-600 text-white'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            }`}
          >
            {status || 'All'}
          </button>
        ))}
      </div>

      {/* List */}
      {approvals.length === 0 ? (
        <div className="text-center py-12 bg-white rounded-xl border border-gray-200">
          <p className="text-gray-500">No approval requests found.</p>
        </div>
      ) : (
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="text-left px-4 py-3 text-sm font-medium text-gray-700">Request</th>
                <th className="text-left px-4 py-3 text-sm font-medium text-gray-700">Household</th>
                <th className="text-left px-4 py-3 text-sm font-medium text-gray-700">Amount</th>
                <th className="text-left px-4 py-3 text-sm font-medium text-gray-700">Status</th>
                <th className="text-left px-4 py-3 text-sm font-medium text-gray-700">Date</th>
              </tr>
            </thead>
            <tbody>
              {approvals.map((approval) => (
                <tr
                  key={approval.id}
                  onClick={() => router.push(`/manager/approvals/${approval.id}`)}
                  className="border-b border-gray-100 hover:bg-gray-50 cursor-pointer"
                >
                  <td className="px-4 py-3">
                    <p className="font-medium text-gray-900">{approval.title}</p>
                    <p className="text-sm text-gray-500">{approval.type}</p>
                  </td>
                  <td className="px-4 py-3 text-sm text-gray-600">
                    {approval.household.name}
                  </td>
                  <td className="px-4 py-3">
                    {approval.amount ? (
                      <span className="font-medium">${approval.amount.toLocaleString()}</span>
                    ) : (
                      <span className="text-gray-400">—</span>
                    )}
                  </td>
                  <td className="px-4 py-3">{statusBadge(approval.status)}</td>
                  <td className="px-4 py-3 text-sm text-gray-500">
                    {new Date(approval.createdAt).toLocaleDateString()}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
```

### Task 4.2: Create New Approval Form

Create `apps/web/src/app/manager/approvals/new/page.tsx`:

```typescript
'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { getIdToken } from '@/lib/firebase';
import { Loader2, ArrowLeft } from 'lucide-react';
import Link from 'next/link';

interface Household {
  id: string;
  name: string;
}

export default function NewApprovalPage() {
  const router = useRouter();
  const [households, setHouseholds] = useState<Household[]>([]);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  
  const [form, setForm] = useState({
    householdId: '',
    type: 'EXPENSE',
    title: '',
    description: '',
    amount: '',
    priority: 'NORMAL',
    notes: '',
  });

  useEffect(() => {
    loadHouseholds();
  }, []);

  const loadHouseholds = async () => {
    try {
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';
      
      const response = await fetch(`${apiUrl}/manager/households`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (response.ok) {
        const data = await response.json();
        setHouseholds(data);
        if (data.length === 1) {
          setForm(f => ({ ...f, householdId: data[0].id }));
        }
      }
    } catch (error) {
      console.error('Failed to load households:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      setSubmitting(true);
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';
      
      const response = await fetch(`${apiUrl}/approvals`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          ...form,
          amount: form.amount ? parseFloat(form.amount) : undefined,
        }),
      });

      if (response.ok) {
        router.push('/manager/approvals');
      } else {
        const error = await response.json();
        alert(error.message || 'Failed to create approval');
      }
    } catch (error) {
      console.error('Failed to submit:', error);
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-8 h-8 animate-spin text-indigo-600" />
      </div>
    );
  }

  return (
    <div className="max-w-2xl mx-auto">
      <Link href="/manager/approvals" className="flex items-center gap-2 text-gray-500 hover:text-gray-700 mb-6">
        <ArrowLeft className="w-4 h-4" />
        Back to Approvals
      </Link>

      <div className="bg-white rounded-xl border border-gray-200 p-6">
        <h1 className="text-xl font-bold text-gray-900 mb-6">Request Approval</h1>

        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Household */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Household
            </label>
            <select
              required
              value={form.householdId}
              onChange={(e) => setForm({ ...form, householdId: e.target.value })}
              className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="">Select household...</option>
              {households.map((h) => (
                <option key={h.id} value={h.id}>{h.name}</option>
              ))}
            </select>
          </div>

          {/* Type */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Type
            </label>
            <select
              value={form.type}
              onChange={(e) => setForm({ ...form, type: e.target.value })}
              className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="EXPENSE">Expense</option>
              <option value="VENDOR">New Vendor</option>
              <option value="SERVICE">Recurring Service</option>
              <option value="PROJECT">Home Project</option>
              <option value="EMERGENCY">Emergency</option>
              <option value="OTHER">Other</option>
            </select>
          </div>

          {/* Title */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Title
            </label>
            <input
              type="text"
              required
              value={form.title}
              onChange={(e) => setForm({ ...form, title: e.target.value })}
              placeholder="e.g., HVAC Repair Quote"
              className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
          </div>

          {/* Amount */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Amount (optional)
            </label>
            <div className="relative">
              <span className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500">$</span>
              <input
                type="number"
                step="0.01"
                value={form.amount}
                onChange={(e) => setForm({ ...form, amount: e.target.value })}
                placeholder="0.00"
                className="w-full pl-8 pr-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>
          </div>

          {/* Priority */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Priority
            </label>
            <select
              value={form.priority}
              onChange={(e) => setForm({ ...form, priority: e.target.value })}
              className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="LOW">Low</option>
              <option value="NORMAL">Normal</option>
              <option value="HIGH">High</option>
              <option value="URGENT">Urgent</option>
            </select>
          </div>

          {/* Description */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Description
            </label>
            <textarea
              value={form.description}
              onChange={(e) => setForm({ ...form, description: e.target.value })}
              rows={3}
              placeholder="What is this for? Why is it needed?"
              className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
          </div>

          {/* Notes */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Notes for Homeowner
            </label>
            <textarea
              value={form.notes}
              onChange={(e) => setForm({ ...form, notes: e.target.value })}
              rows={2}
              placeholder="Any additional context..."
              className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
          </div>

          {/* Submit */}
          <div className="flex gap-3">
            <button
              type="submit"
              disabled={submitting}
              className="flex-1 px-6 py-3 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 disabled:opacity-50 font-medium"
            >
              {submitting ? 'Submitting...' : 'Submit for Approval'}
            </button>
            <Link href="/manager/approvals">
              <button
                type="button"
                className="px-6 py-3 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200"
              >
                Cancel
              </button>
            </Link>
          </div>
        </form>
      </div>
    </div>
  );
}
```

### Task 4.3: Add to Manager Navigation

Update manager layout to include Approvals in navigation.

---

## PHASE 5: Add Test Data

### Task 5.1: Create Demo Approval

Add to seed or create via API after deployment:

```typescript
// Create a demo approval request from Sarah to Bob
await prisma.approvalRequest.create({
  data: {
    householdId: morrisonHousehold.id,
    type: 'EXPENSE',
    title: 'HVAC Annual Maintenance',
    description: 'Annual HVAC system inspection and tune-up. Includes filter replacement, refrigerant check, and cleaning.',
    amount: 289.00,
    priority: 'NORMAL',
    status: 'PENDING',
    requestedById: sarah.id,
    notes: 'This is recommended annually to maintain efficiency and prevent costly repairs. I got quotes from 3 companies - this is the best value.',
  },
});

await prisma.approvalRequest.create({
  data: {
    householdId: morrisonHousehold.id,
    type: 'EXPENSE',
    title: 'Emergency Roof Repair',
    description: 'Storm damage to roof shingles. Water intrusion risk if not addressed.',
    amount: 1850.00,
    priority: 'URGENT',
    status: 'PENDING',
    requestedById: sarah.id,
    notes: 'Roofer can come tomorrow if approved today. Delaying risks water damage to attic.',
  },
});
```

---

## PHASE 6: Update Tests

### Task 6.1: Add Approval Tests to Test Suite

Add to `scripts/test-haven.ts`:

```typescript
async function testApprovalFlow(): Promise<TestSuite> {
  const tests: TestResult[] = [];

  // Get manager token
  const managerToken = await getFirebaseToken(CREDENTIALS.manager.email, CREDENTIALS.manager.password);
  
  if (!managerToken) {
    tests.push({ name: 'Approval flow', passed: false, skipped: true, error: 'No manager token' });
    return { name: 'Approval System', tests };
  }

  // GET /approvals/manager
  let start = Date.now();
  let response = await apiRequest('GET', '/approvals/manager', managerToken);
  tests.push({
    name: 'GET /approvals/manager',
    passed: response.status === 200,
    error: response.status !== 200 ? `HTTP ${response.status}` : undefined,
    duration: Date.now() - start,
  });

  // Get homeowner token
  const homeownerToken = await getFirebaseToken(CREDENTIALS.homeowner.email, CREDENTIALS.homeowner.password);
  
  if (!homeownerToken) {
    tests.push({ name: 'Homeowner approval flow', passed: false, skipped: true, error: 'No homeowner token' });
    return { name: 'Approval System', tests };
  }

  // GET /approvals/pending
  start = Date.now();
  response = await apiRequest('GET', '/approvals/pending', homeownerToken);
  tests.push({
    name: 'GET /approvals/pending',
    passed: response.status === 200,
    error: response.status !== 200 ? `HTTP ${response.status}` : undefined,
    duration: Date.now() - start,
  });

  return { name: 'Approval System', tests };
}
```

---

## PHASE 7: Build, Deploy, Test

### Task 7.1: Build

```bash
cd /Users/tomburke/Projects/Housing-Manager
pnpm build
```

### Task 7.2: Run Migration in Production

```bash
cd apps/api
DATABASE_URL="production-url" pnpm prisma migrate deploy
```

### Task 7.3: Deploy

```bash
git add .
git commit -m "feat: approval system for expenses and decisions"
git push origin main

gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616
gcloud builds submit --config=cloudbuild-web.yaml --project=home-manager-480616
```

### Task 7.4: Run Tests

```bash
pnpm test:e2e
```

---

## Summary

After this prompt:

1. ✅ Database schema for ApprovalRequest and ApprovalComment
2. ✅ API endpoints for create/approve/reject/comment
3. ✅ Homeowner approvals page at /app/approvals
4. ✅ Manager approval request page at /manager/approvals
5. ✅ Activity logging for all approval actions
6. ✅ Demo data with pending approvals

### User Flow

**Sarah (Manager):**
- /manager/approvals → See all requests
- /manager/approvals/new → Create new request
- Track status of pending requests

**Bob (Homeowner):**
- /app/approvals → See pending approvals
- Review details, add comments
- Approve or reject with notes
- See in dashboard if pending

**Both see:**
- Activity feed updates
- Comments thread on each approval
