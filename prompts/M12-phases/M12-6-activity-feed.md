# M12-6: ADD ACTIVITY FEED TO HOME SCREEN

## CRITICAL INSTRUCTIONS

The Activity Feed must be **visible on the home screen** with:
- Emoji categorization
- Color-coded backgrounds
- Relative timestamps ("2 hours ago")
- "See All" link

**DO NOT** claim this exists. Actually verify by looking at the home screen in simulator.

---

## PROBLEM STATEMENT

The home screen needs an Activity Feed that shows everything happening:
- 🏠 Property: New zone added, system added
- 💰 Billing: New bill added, payment made
- 👨‍👩‍👧‍👦 Family: Member added, activity added
- 🔧 Maintenance: Task created, completed
- 👷 Vendor: New vendor, service performed
- 🤖 Alfred: Conversations, actions taken

---

## REQUIRED DELIVERABLES

### 1. Database Schema for Activity Feed

**File:** `apps/api/prisma/schema.prisma`

Add this model:

```prisma
model ActivityFeedItem {
  id            String   @id @default(cuid())
  householdId   String
  household     Household @relation(fields: [householdId], references: [id], onDelete: Cascade)
  
  // Activity categorization
  type          String   // property, billing, family, maintenance, vendor, alfred
  action        String   // added, updated, completed, deleted, paid, etc.
  
  // Display
  title         String   // "New zone added"
  description   String?  // "Kitchen zone with 3 systems"
  emoji         String?  // 🏠 - Optional override
  
  // Entity reference for navigation
  entityType    String?  // zone, system, bill, member, task, vendor
  entityId      String?
  
  // Who performed the action
  userId        String?
  userName      String?  // "Tom" or "Alfred"
  
  createdAt     DateTime @default(now())
  
  @@index([householdId, createdAt])
}
```

Add relation to Household:
```prisma
model Household {
  // ... existing fields
  activityFeed    ActivityFeedItem[]
}
```

Run migration:
```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/api
pnpm prisma migrate dev --name add-activity-feed
pnpm prisma generate
```

### 2. Create Activity Feed Service

**File:** `apps/api/src/activity/activity-feed.service.ts`

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

interface LogActivityParams {
  householdId: string;
  type: 'property' | 'billing' | 'family' | 'maintenance' | 'vendor' | 'alfred';
  action: string;
  title: string;
  description?: string;
  entityType?: string;
  entityId?: string;
  userId?: string;
  userName?: string;
}

@Injectable()
export class ActivityFeedService {
  constructor(private prisma: PrismaService) {}

  async logActivity(params: LogActivityParams) {
    return this.prisma.activityFeedItem.create({
      data: params,
    });
  }

  async getRecentActivity(householdId: string, limit = 20) {
    return this.prisma.activityFeedItem.findMany({
      where: { householdId },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
  }

  // Helper methods for common activities
  async logZoneAdded(householdId: string, zoneName: string, zoneId: string, userName?: string) {
    return this.logActivity({
      householdId,
      type: 'property',
      action: 'added',
      title: `New zone added: ${zoneName}`,
      entityType: 'zone',
      entityId: zoneId,
      userName,
    });
  }

  async logSystemAdded(householdId: string, systemName: string, systemId: string, userName?: string) {
    return this.logActivity({
      householdId,
      type: 'property',
      action: 'added',
      title: `New system added: ${systemName}`,
      entityType: 'system',
      entityId: systemId,
      userName,
    });
  }

  async logBillAdded(householdId: string, billName: string, billId: string) {
    return this.logActivity({
      householdId,
      type: 'billing',
      action: 'added',
      title: `New bill added: ${billName}`,
      entityType: 'bill',
      entityId: billId,
    });
  }

  async logBillPaid(householdId: string, billName: string, amount: number) {
    return this.logActivity({
      householdId,
      type: 'billing',
      action: 'paid',
      title: `Bill paid: ${billName}`,
      description: `$${amount.toFixed(2)}`,
    });
  }

  async logFamilyMemberAdded(householdId: string, memberName: string, memberId: string) {
    return this.logActivity({
      householdId,
      type: 'family',
      action: 'added',
      title: `New family member: ${memberName}`,
      entityType: 'member',
      entityId: memberId,
    });
  }

  async logMaintenanceTaskCreated(householdId: string, taskName: string, taskId: string) {
    return this.logActivity({
      householdId,
      type: 'maintenance',
      action: 'added',
      title: `New task: ${taskName}`,
      entityType: 'task',
      entityId: taskId,
    });
  }

  async logMaintenanceCompleted(householdId: string, taskName: string, taskId: string) {
    return this.logActivity({
      householdId,
      type: 'maintenance',
      action: 'completed',
      title: `Task completed: ${taskName}`,
      entityType: 'task',
      entityId: taskId,
    });
  }

  async logVendorAdded(householdId: string, vendorName: string, vendorId: string) {
    return this.logActivity({
      householdId,
      type: 'vendor',
      action: 'added',
      title: `New vendor: ${vendorName}`,
      entityType: 'vendor',
      entityId: vendorId,
    });
  }

  async logAlfredAction(householdId: string, action: string, description?: string) {
    return this.logActivity({
      householdId,
      type: 'alfred',
      action: 'action',
      title: action,
      description,
      userName: 'Alfred',
    });
  }
}
```

Create module:
```typescript
// apps/api/src/activity/activity.module.ts
import { Module, Global } from '@nestjs/common';
import { ActivityFeedService } from './activity-feed.service';
import { PrismaModule } from '../prisma/prisma.module';

@Global() // Make it available everywhere
@Module({
  imports: [PrismaModule],
  providers: [ActivityFeedService],
  exports: [ActivityFeedService],
})
export class ActivityModule {}
```

Register in app.module.ts.

### 3. Create Activity Feed API Endpoint

**File:** `apps/api/src/activity/activity.controller.ts`

```typescript
import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { ActivityFeedService } from './activity-feed.service';
import { FirebaseAuthGuard } from '../firebase';

@Controller('activity')
@UseGuards(FirebaseAuthGuard)
export class ActivityController {
  constructor(private activityService: ActivityFeedService) {}

  @Get(':householdId')
  async getActivity(
    @Param('householdId') householdId: string,
    @Query('limit') limit?: string,
  ) {
    return this.activityService.getRecentActivity(
      householdId,
      limit ? parseInt(limit, 10) : 20,
    );
  }
}
```

### 4. Log Activities Throughout the App

Update existing services to log activities:

**Example - When creating a bill:**
```typescript
// In bills.service.ts or similar
async createBill(data: CreateBillDto) {
  const bill = await this.prisma.comprehensiveBill.create({ data });
  
  // Log activity
  await this.activityFeed.logBillAdded(
    data.householdId,
    data.name,
    bill.id,
  );
  
  return bill;
}
```

**Example - When adding a vendor:**
```typescript
// In vendors.controller.ts
@Post(':householdId')
async createVendor(@Param('householdId') householdId: string, @Body() data: any) {
  const vendor = await this.prisma.vendor.create({ data: { householdId, ...data } });
  
  // Log activity
  await this.activityFeed.logVendorAdded(householdId, vendor.name, vendor.id);
  
  return vendor;
}
```

### 5. Add Activity Feed to Home Screen

**File:** `apps/mobile/app/(tabs)/index.tsx` or `apps/mobile/app/(tabs)/home.tsx`

Add this section to the home screen ScrollView:

```tsx
import { formatDistanceToNow } from 'date-fns';

// State
const [activities, setActivities] = useState<Activity[]>([]);

// Fetch activities
const fetchActivities = async () => {
  try {
    const token = await getIdToken(true);
    const response = await fetch(
      `${API_BASE_URL}/activity/${householdInfo.id}?limit=10`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    const data = await response.json();
    setActivities(data);
  } catch (error) {
    console.error('Error fetching activities:', error);
  }
};

// Call in useEffect
useEffect(() => {
  fetchActivities();
}, [householdInfo?.id]);

// Activity config helper
const getActivityConfig = (type: string, action: string) => {
  const configs: Record<string, { emoji: string; bgColor: string }> = {
    property: { emoji: '🏠', bgColor: '#E0E7FF' },
    billing: { emoji: '💰', bgColor: '#D1FAE5' },
    family: { emoji: '👨‍👩‍👧‍👦', bgColor: '#FCE7F3' },
    maintenance: { emoji: '🔧', bgColor: '#FEF3C7' },
    vendor: { emoji: '👷', bgColor: '#DBEAFE' },
    alfred: { emoji: '🤖', bgColor: '#F3E8FF' },
  };
  return configs[type] || { emoji: '📌', bgColor: '#F3F4F6' };
};

// Render in ScrollView
{/* Activity Feed Section */}
<View style={styles.activitySection}>
  <View style={styles.sectionHeader}>
    <Text style={styles.sectionTitle}>Recent Activity</Text>
    <TouchableOpacity onPress={() => router.push('/activity')}>
      <Text style={styles.seeAllLink}>See All</Text>
    </TouchableOpacity>
  </View>
  
  <View style={styles.activityList}>
    {activities.length === 0 ? (
      <View style={styles.activityEmpty}>
        <Text style={styles.activityEmptyText}>No recent activity</Text>
      </View>
    ) : (
      activities.slice(0, 5).map((activity) => {
        const config = getActivityConfig(activity.type, activity.action);
        return (
          <View key={activity.id} style={styles.activityItem}>
            <View style={[styles.activityEmoji, { backgroundColor: config.bgColor }]}>
              <Text style={styles.activityEmojiText}>{config.emoji}</Text>
            </View>
            <View style={styles.activityContent}>
              <Text style={styles.activityTitle}>{activity.title}</Text>
              {activity.description && (
                <Text style={styles.activityDescription}>{activity.description}</Text>
              )}
              <Text style={styles.activityTime}>
                {formatDistanceToNow(new Date(activity.createdAt), { addSuffix: true })}
              </Text>
            </View>
          </View>
        );
      })
    )}
  </View>
</View>
```

Add styles:
```typescript
activitySection: {
  marginBottom: 24,
  paddingHorizontal: 16,
},
sectionHeader: {
  flexDirection: 'row',
  justifyContent: 'space-between',
  alignItems: 'center',
  marginBottom: 12,
},
sectionTitle: {
  fontSize: 18,
  fontWeight: '600',
  color: '#0f172a',
},
seeAllLink: {
  fontSize: 14,
  color: '#c4a574',
  fontWeight: '500',
},
activityList: {
  backgroundColor: '#ffffff',
  borderRadius: 12,
  overflow: 'hidden',
  shadowColor: '#000',
  shadowOffset: { width: 0, height: 1 },
  shadowOpacity: 0.05,
  shadowRadius: 2,
  elevation: 1,
},
activityItem: {
  flexDirection: 'row',
  alignItems: 'flex-start',
  padding: 12,
  borderBottomWidth: 1,
  borderBottomColor: '#f1f5f9',
  gap: 12,
},
activityEmoji: {
  width: 40,
  height: 40,
  borderRadius: 10,
  alignItems: 'center',
  justifyContent: 'center',
},
activityEmojiText: {
  fontSize: 20,
},
activityContent: {
  flex: 1,
},
activityTitle: {
  fontSize: 14,
  fontWeight: '500',
  color: '#0f172a',
},
activityDescription: {
  fontSize: 13,
  color: '#64748b',
  marginTop: 2,
},
activityTime: {
  fontSize: 12,
  color: '#94a3b8',
  marginTop: 4,
},
activityEmpty: {
  padding: 24,
  alignItems: 'center',
},
activityEmptyText: {
  fontSize: 14,
  color: '#94a3b8',
},
```

### 6. Install date-fns for Relative Time

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
npm install date-fns
```

---

## VERIFICATION STEPS

1. **Check Home Screen**
   - Open app
   - Scroll to find "Recent Activity" section
   - Verify it's visible with header and "See All" link

2. **Create Some Activity**
   - Add a new vendor (should create activity)
   - Add a new bill (should create activity)
   - Verify activities appear in feed

3. **Check Activity Display**
   - Verify emojis show correctly (🏠💰👷 etc.)
   - Verify colored backgrounds
   - Verify relative times ("2 hours ago")

4. **Tap See All**
   - Should navigate to full activity list

---

## SUCCESS CRITERIA

- [ ] Activity Feed section visible on home screen
- [ ] Shows emoji + colored background for each type
- [ ] Shows title and relative time
- [ ] Activities are logged when actions happen
- [ ] "See All" link works
- [ ] Empty state shows when no activities
