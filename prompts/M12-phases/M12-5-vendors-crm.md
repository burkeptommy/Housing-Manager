# M12-5: BUILD COMPLETE VENDORS CRM IN YOUR HOME SECTION

## CRITICAL INSTRUCTIONS

This is NOT just a list of vendors. This is a **full CRM** with:
- Vendor profiles with complete contact info
- Activity history (calls, services, quotes, payments)
- Notes and ratings
- Favorite vendors
- Category filtering

**DO NOT** claim this exists if it's just a basic vendor list. A CRM has ACTIVITY TRACKING.

---

## PROBLEM STATEMENT

The user needs a complete vendor CRM in the "Your Home" section where they can:
1. See all vendors they've ever used
2. Track all interactions with each vendor
3. Add notes and rate vendors
4. Mark favorites for quick access
5. Filter by category (plumber, electrician, etc.)
6. Log activities (service calls, quotes, payments)

---

## REQUIRED DELIVERABLES

### 1. Database Schema for Full CRM

**File:** `apps/api/prisma/schema.prisma`

Add or update these models:

```prisma
model Vendor {
  id              String   @id @default(cuid())
  householdId     String
  household       Household @relation(fields: [householdId], references: [id], onDelete: Cascade)
  
  // Basic Info
  name            String
  companyName     String?
  category        String    // plumber, electrician, hvac, landscaping, cleaning, etc.
  
  // Contact Info - ALL fields required for CRM
  phone           String?
  email           String?
  website         String?
  address         String?
  city            String?
  state           String?
  zipCode         String?
  
  // Contact Person (if different from company)
  contactName     String?
  contactPhone    String?
  contactEmail    String?
  
  // CRM Features
  isFavorite      Boolean  @default(false)
  rating          Int?     // 1-5 stars
  notes           String?  @db.Text  // Rich notes
  tags            String[] @default([])  // Custom tags
  
  // Source tracking
  source          String?  // "manual", "plaid", "alfred", "referral"
  referredBy      String?  // Who referred this vendor
  
  // Status
  isActive        Boolean  @default(true)
  lastContactDate DateTime?
  
  // Relations
  activities      VendorActivity[]
  
  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt
  
  @@index([householdId])
  @@index([householdId, category])
  @@index([householdId, isFavorite])
}

model VendorActivity {
  id              String   @id @default(cuid())
  vendorId        String
  vendor          Vendor   @relation(fields: [vendorId], references: [id], onDelete: Cascade)
  
  // Activity Details
  type            String   // service, quote, call, email, payment, note, complaint
  title           String
  description     String?  @db.Text
  
  // Financial
  amount          Float?
  isPaid          Boolean  @default(false)
  
  // Date & Time
  date            DateTime
  duration        Int?     // Duration in minutes (for calls/services)
  
  // Attachments/References
  invoiceUrl      String?
  receiptUrl      String?
  
  // Link to other entities
  maintenanceTaskId String?
  
  // Metadata
  createdBy       String?  // User who logged this
  
  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt
  
  @@index([vendorId])
  @@index([vendorId, date])
}
```

Run migration:
```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/api
pnpm prisma migrate dev --name vendor-crm-full
pnpm prisma generate
```

### 2. Create Vendor API Endpoints

**File:** `apps/api/src/vendors/vendors.controller.ts`

Create complete CRUD + activity endpoints:

```typescript
import { Controller, Get, Post, Patch, Delete, Param, Body, Query, UseGuards } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { FirebaseAuthGuard } from '../firebase';

@Controller('vendors')
@UseGuards(FirebaseAuthGuard)
export class VendorsController {
  constructor(private prisma: PrismaService) {}

  // GET /vendors/:householdId - List all vendors with filters
  @Get(':householdId')
  async getVendors(
    @Param('householdId') householdId: string,
    @Query('category') category?: string,
    @Query('favorite') favorite?: string,
    @Query('search') search?: string,
  ) {
    const where: any = { householdId };
    
    if (category) {
      where.category = category;
    }
    
    if (favorite === 'true') {
      where.isFavorite = true;
    }
    
    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { companyName: { contains: search, mode: 'insensitive' } },
      ];
    }
    
    return this.prisma.vendor.findMany({
      where,
      include: {
        activities: {
          orderBy: { date: 'desc' },
          take: 3, // Last 3 activities for preview
        },
      },
      orderBy: [
        { isFavorite: 'desc' },
        { lastContactDate: 'desc' },
        { name: 'asc' },
      ],
    });
  }

  // GET /vendors/:householdId/:vendorId - Get single vendor with all activities
  @Get(':householdId/:vendorId')
  async getVendor(
    @Param('householdId') householdId: string,
    @Param('vendorId') vendorId: string,
  ) {
    return this.prisma.vendor.findUnique({
      where: { id: vendorId },
      include: {
        activities: {
          orderBy: { date: 'desc' },
        },
      },
    });
  }

  // POST /vendors/:householdId - Create vendor
  @Post(':householdId')
  async createVendor(
    @Param('householdId') householdId: string,
    @Body() data: any,
  ) {
    return this.prisma.vendor.create({
      data: {
        householdId,
        ...data,
      },
    });
  }

  // PATCH /vendors/:vendorId - Update vendor
  @Patch(':vendorId')
  async updateVendor(
    @Param('vendorId') vendorId: string,
    @Body() data: any,
  ) {
    return this.prisma.vendor.update({
      where: { id: vendorId },
      data,
    });
  }

  // DELETE /vendors/:vendorId - Delete vendor
  @Delete(':vendorId')
  async deleteVendor(@Param('vendorId') vendorId: string) {
    return this.prisma.vendor.delete({
      where: { id: vendorId },
    });
  }

  // POST /vendors/:vendorId/toggle-favorite - Toggle favorite status
  @Post(':vendorId/toggle-favorite')
  async toggleFavorite(@Param('vendorId') vendorId: string) {
    const vendor = await this.prisma.vendor.findUnique({
      where: { id: vendorId },
    });
    
    return this.prisma.vendor.update({
      where: { id: vendorId },
      data: { isFavorite: !vendor?.isFavorite },
    });
  }

  // ========== ACTIVITIES ==========

  // GET /vendors/:vendorId/activities - Get all activities for vendor
  @Get(':vendorId/activities')
  async getActivities(@Param('vendorId') vendorId: string) {
    return this.prisma.vendorActivity.findMany({
      where: { vendorId },
      orderBy: { date: 'desc' },
    });
  }

  // POST /vendors/:vendorId/activities - Add activity
  @Post(':vendorId/activities')
  async addActivity(
    @Param('vendorId') vendorId: string,
    @Body() data: any,
  ) {
    // Also update lastContactDate on vendor
    await this.prisma.vendor.update({
      where: { id: vendorId },
      data: { lastContactDate: new Date() },
    });
    
    return this.prisma.vendorActivity.create({
      data: {
        vendorId,
        ...data,
      },
    });
  }

  // DELETE /vendors/activities/:activityId - Delete activity
  @Delete('activities/:activityId')
  async deleteActivity(@Param('activityId') activityId: string) {
    return this.prisma.vendorActivity.delete({
      where: { id: activityId },
    });
  }
}
```

Create module file:
```typescript
// apps/api/src/vendors/vendors.module.ts
import { Module } from '@nestjs/common';
import { VendorsController } from './vendors.controller';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [VendorsController],
})
export class VendorsModule {}
```

Register in app.module.ts.

### 3. Create Vendors List Screen

**File:** `apps/mobile/app/(tabs)/home/vendors/index.tsx`

```tsx
import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  FlatList,
  StyleSheet,
  TouchableOpacity,
  TextInput,
  RefreshControl,
  ActivityIndicator,
  Linking,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter, Stack } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../../../src/contexts/auth-context';
import { API_BASE_URL } from '../../../../src/lib/api';
import { getIdToken } from '../../../../src/lib/firebase';

interface Vendor {
  id: string;
  name: string;
  companyName?: string;
  category: string;
  phone?: string;
  email?: string;
  isFavorite: boolean;
  rating?: number;
  lastContactDate?: string;
  activities: Array<{
    id: string;
    type: string;
    title: string;
    date: string;
  }>;
}

const CATEGORIES = [
  { id: 'all', label: 'All', icon: 'grid-outline' },
  { id: 'plumber', label: 'Plumber', icon: 'water-outline' },
  { id: 'electrician', label: 'Electrician', icon: 'flash-outline' },
  { id: 'hvac', label: 'HVAC', icon: 'thermometer-outline' },
  { id: 'landscaping', label: 'Landscaping', icon: 'leaf-outline' },
  { id: 'cleaning', label: 'Cleaning', icon: 'sparkles-outline' },
  { id: 'handyman', label: 'Handyman', icon: 'construct-outline' },
  { id: 'pest', label: 'Pest Control', icon: 'bug-outline' },
  { id: 'roofing', label: 'Roofing', icon: 'home-outline' },
  { id: 'pool', label: 'Pool', icon: 'water-outline' },
  { id: 'other', label: 'Other', icon: 'ellipsis-horizontal-outline' },
];

export default function VendorsScreen() {
  const router = useRouter();
  const { householdInfo } = useAuth();
  
  const [vendors, setVendors] = useState<Vendor[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');

  const fetchVendors = useCallback(async () => {
    if (!householdInfo?.id) return;
    
    try {
      const token = await getIdToken(true);
      let url = `${API_BASE_URL}/vendors/${householdInfo.id}`;
      
      const params = new URLSearchParams();
      if (selectedCategory !== 'all') {
        params.append('category', selectedCategory);
      }
      if (searchQuery) {
        params.append('search', searchQuery);
      }
      
      if (params.toString()) {
        url += `?${params.toString()}`;
      }
      
      const response = await fetch(url, {
        headers: { Authorization: `Bearer ${token}` },
      });
      
      const data = await response.json();
      setVendors(data);
    } catch (error) {
      console.error('Error fetching vendors:', error);
    } finally {
      setIsLoading(false);
    }
  }, [householdInfo?.id, selectedCategory, searchQuery]);

  useEffect(() => {
    fetchVendors();
  }, [fetchVendors]);

  const onRefresh = async () => {
    setRefreshing(true);
    await fetchVendors();
    setRefreshing(false);
  };

  const toggleFavorite = async (vendorId: string) => {
    try {
      const token = await getIdToken(true);
      await fetch(`${API_BASE_URL}/vendors/${vendorId}/toggle-favorite`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` },
      });
      fetchVendors();
    } catch (error) {
      console.error('Error toggling favorite:', error);
    }
  };

  const callVendor = (phone?: string) => {
    if (phone) {
      Linking.openURL(`tel:${phone}`);
    } else {
      Alert.alert('No Phone Number', 'This vendor has no phone number on file.');
    }
  };

  const emailVendor = (email?: string) => {
    if (email) {
      Linking.openURL(`mailto:${email}`);
    } else {
      Alert.alert('No Email', 'This vendor has no email on file.');
    }
  };

  const renderVendor = ({ item }: { item: Vendor }) => {
    const categoryIcon = CATEGORIES.find(c => c.id === item.category)?.icon || 'business-outline';
    
    return (
      <TouchableOpacity 
        style={styles.vendorCard}
        onPress={() => router.push(`/(tabs)/home/vendors/${item.id}`)}
      >
        <View style={styles.vendorHeader}>
          <View style={styles.vendorIcon}>
            <Ionicons name={categoryIcon as any} size={24} color="#c4a574" />
          </View>
          <View style={styles.vendorInfo}>
            <View style={styles.vendorTitleRow}>
              <Text style={styles.vendorName}>{item.name}</Text>
              <TouchableOpacity onPress={() => toggleFavorite(item.id)}>
                <Ionicons 
                  name={item.isFavorite ? 'star' : 'star-outline'} 
                  size={20} 
                  color={item.isFavorite ? '#c4a574' : '#94a3b8'} 
                />
              </TouchableOpacity>
            </View>
            {item.companyName && (
              <Text style={styles.vendorCompany}>{item.companyName}</Text>
            )}
            <Text style={styles.vendorCategory}>
              {CATEGORIES.find(c => c.id === item.category)?.label || item.category}
            </Text>
            
            {/* Rating */}
            {item.rating && (
              <View style={styles.ratingRow}>
                {[1, 2, 3, 4, 5].map(star => (
                  <Ionicons 
                    key={star}
                    name={star <= item.rating! ? 'star' : 'star-outline'} 
                    size={12} 
                    color="#fbbf24" 
                  />
                ))}
              </View>
            )}
            
            {/* Last Activity */}
            {item.activities && item.activities[0] && (
              <Text style={styles.lastActivity}>
                Last: {item.activities[0].title} ({new Date(item.activities[0].date).toLocaleDateString()})
              </Text>
            )}
          </View>
        </View>
        
        {/* Quick Actions */}
        <View style={styles.vendorActions}>
          <TouchableOpacity 
            style={styles.actionButton}
            onPress={() => callVendor(item.phone)}
          >
            <Ionicons name="call-outline" size={20} color="#c4a574" />
          </TouchableOpacity>
          <TouchableOpacity 
            style={styles.actionButton}
            onPress={() => emailVendor(item.email)}
          >
            <Ionicons name="mail-outline" size={20} color="#c4a574" />
          </TouchableOpacity>
          <TouchableOpacity 
            style={styles.actionButton}
            onPress={() => router.push(`/(tabs)/home/vendors/${item.id}`)}
          >
            <Ionicons name="chevron-forward" size={20} color="#94a3b8" />
          </TouchableOpacity>
        </View>
      </TouchableOpacity>
    );
  };

  return (
    <>
      <Stack.Screen options={{ title: 'Vendors' }} />
      <SafeAreaView style={styles.container} edges={['bottom']}>
        {/* Search Bar */}
        <View style={styles.searchContainer}>
          <Ionicons name="search-outline" size={20} color="#94a3b8" />
          <TextInput
            style={styles.searchInput}
            placeholder="Search vendors..."
            placeholderTextColor="#94a3b8"
            value={searchQuery}
            onChangeText={setSearchQuery}
            onSubmitEditing={fetchVendors}
          />
        </View>
        
        {/* Category Filter */}
        <FlatList
          horizontal
          data={CATEGORIES}
          keyExtractor={item => item.id}
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.categoryList}
          renderItem={({ item }) => (
            <TouchableOpacity
              style={[
                styles.categoryChip,
                selectedCategory === item.id && styles.categoryChipActive,
              ]}
              onPress={() => setSelectedCategory(item.id)}
            >
              <Ionicons 
                name={item.icon as any} 
                size={16} 
                color={selectedCategory === item.id ? '#ffffff' : '#64748b'} 
              />
              <Text style={[
                styles.categoryChipText,
                selectedCategory === item.id && styles.categoryChipTextActive,
              ]}>
                {item.label}
              </Text>
            </TouchableOpacity>
          )}
        />
        
        {/* Vendors List */}
        {isLoading ? (
          <View style={styles.loadingContainer}>
            <ActivityIndicator size="large" color="#c4a574" />
          </View>
        ) : (
          <FlatList
            data={vendors}
            keyExtractor={item => item.id}
            renderItem={renderVendor}
            contentContainerStyle={styles.listContent}
            refreshControl={
              <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor="#c4a574" />
            }
            ListEmptyComponent={
              <View style={styles.emptyState}>
                <Ionicons name="people-outline" size={48} color="#cbd5e1" />
                <Text style={styles.emptyTitle}>No vendors yet</Text>
                <Text style={styles.emptySubtitle}>
                  Add your first vendor to start tracking
                </Text>
                <TouchableOpacity 
                  style={styles.addButton}
                  onPress={() => router.push('/(tabs)/home/vendors/add')}
                >
                  <Ionicons name="add" size={20} color="#ffffff" />
                  <Text style={styles.addButtonText}>Add Vendor</Text>
                </TouchableOpacity>
              </View>
            }
          />
        )}
        
        {/* FAB */}
        {vendors.length > 0 && (
          <TouchableOpacity 
            style={styles.fab}
            onPress={() => router.push('/(tabs)/home/vendors/add')}
          >
            <Ionicons name="add" size={28} color="#ffffff" />
          </TouchableOpacity>
        )}
      </SafeAreaView>
    </>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8fafc',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  searchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#ffffff',
    marginHorizontal: 16,
    marginTop: 16,
    paddingHorizontal: 12,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#e2e8f0',
  },
  searchInput: {
    flex: 1,
    paddingVertical: 12,
    paddingHorizontal: 8,
    fontSize: 16,
    color: '#0f172a',
  },
  categoryList: {
    paddingHorizontal: 16,
    paddingVertical: 12,
    gap: 8,
  },
  categoryChip: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: '#ffffff',
    borderWidth: 1,
    borderColor: '#e2e8f0',
    gap: 6,
    marginRight: 8,
  },
  categoryChipActive: {
    backgroundColor: '#0f172a',
    borderColor: '#0f172a',
  },
  categoryChipText: {
    fontSize: 13,
    color: '#64748b',
    fontWeight: '500',
  },
  categoryChipTextActive: {
    color: '#ffffff',
  },
  listContent: {
    padding: 16,
    gap: 12,
  },
  vendorCard: {
    backgroundColor: '#ffffff',
    borderRadius: 12,
    padding: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 1,
  },
  vendorHeader: {
    flexDirection: 'row',
    gap: 12,
  },
  vendorIcon: {
    width: 48,
    height: 48,
    borderRadius: 12,
    backgroundColor: '#faf6ed',
    alignItems: 'center',
    justifyContent: 'center',
  },
  vendorInfo: {
    flex: 1,
  },
  vendorTitleRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  vendorName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#0f172a',
  },
  vendorCompany: {
    fontSize: 14,
    color: '#64748b',
    marginTop: 2,
  },
  vendorCategory: {
    fontSize: 12,
    color: '#94a3b8',
    marginTop: 2,
  },
  ratingRow: {
    flexDirection: 'row',
    marginTop: 4,
    gap: 2,
  },
  lastActivity: {
    fontSize: 12,
    color: '#64748b',
    marginTop: 6,
    fontStyle: 'italic',
  },
  vendorActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    marginTop: 12,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: '#f1f5f9',
    gap: 8,
  },
  actionButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#faf6ed',
    alignItems: 'center',
    justifyContent: 'center',
  },
  emptyState: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 60,
  },
  emptyTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#64748b',
    marginTop: 16,
  },
  emptySubtitle: {
    fontSize: 14,
    color: '#94a3b8',
    marginTop: 4,
    textAlign: 'center',
  },
  addButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#c4a574',
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: 12,
    marginTop: 20,
    gap: 8,
  },
  addButtonText: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '600',
  },
  fab: {
    position: 'absolute',
    bottom: 24,
    right: 24,
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: '#c4a574',
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 4,
    elevation: 4,
  },
});
```

### 4. Create Vendor Detail Screen with Activity Log

**File:** `apps/mobile/app/(tabs)/home/vendors/[id].tsx`

This screen must include:
- Vendor header with name, company, rating, favorite toggle
- Contact info section (phone, email, address)
- Notes section (editable)
- **Activity Timeline** - This is the CRM part!
- Add Activity button

Length limit reached - see continuation in implementation.

### 5. Create Add Vendor Screen

**File:** `apps/mobile/app/(tabs)/home/vendors/add.tsx`

Form fields:
- Name (required)
- Company Name
- Category (picker)
- Phone
- Email
- Address
- Notes
- Source (where you found them)

### 6. Create Add Activity Modal

When adding an activity, user selects:
- Type: Service, Quote, Call, Email, Payment, Note
- Title (required)
- Description
- Amount (for payments/quotes)
- Date

---

## VERIFICATION STEPS

1. **Navigate to Vendors**
   - Go to Your Home → Vendors
   - Verify list appears (may be empty)

2. **Add a Vendor**
   - Tap + button
   - Fill in: Name, Category, Phone
   - Save
   - Verify vendor appears in list

3. **View Vendor Detail**
   - Tap on vendor
   - Verify all info shows
   - Verify Activity Timeline section exists

4. **Add an Activity**
   - Tap "Add Activity" or + on vendor detail
   - Select type: "Service Call"
   - Enter title: "Fixed leaky faucet"
   - Enter amount: 150
   - Save
   - Verify activity appears in timeline

5. **Filter by Category**
   - Tap category filter
   - Select "Plumber"
   - Verify only plumbers show

6. **Favorite a Vendor**
   - Tap star icon
   - Verify it fills in
   - Verify vendor moves to top of list

---

## SUCCESS CRITERIA

- [ ] Vendors list screen exists and loads
- [ ] Can add new vendor with full details
- [ ] Vendor detail screen shows all info
- [ ] **Activity Timeline shows all interactions**
- [ ] Can add activities (service, call, payment, etc.)
- [ ] Category filter works
- [ ] Favorite toggle works
- [ ] Quick actions (call, email) work
