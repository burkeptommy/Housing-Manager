# Haven Mobile: M07 - Core Features Part 2

**Created:** December 29, 2024  
**Priority:** P1 - Important features  
**Estimated Time:** 5-6 hours  
**Dependencies:** M01-M06 complete

---

## Overview

This prompt implements additional core screens:
1. Maintenance calendar with tasks
2. Document vault with camera upload
3. Family management (members, vehicles, staff)

---

## PHASE 1: Create Maintenance Screen

### Task 1.1: Create Maintenance Calendar Screen

Create `apps/mobile/app/(tabs)/maintenance.tsx`:

```typescript
import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  RefreshControl,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { Card, Badge, LoadingSpinner } from '../../src/components';
import { colors, typography, spacing, borderRadius } from '../../src/lib/theme';

interface MaintenanceTask {
  id: string;
  title: string;
  description: string;
  category: string;
  dueDate: string;
  frequency: string;
  status: 'upcoming' | 'due' | 'overdue' | 'completed';
  estimatedCost?: number;
  lastCompleted?: string;
  assignedTo?: string;
}

const CATEGORY_ICONS: Record<string, string> = {
  'HVAC': 'thermometer-outline',
  'Plumbing': 'water-outline',
  'Electrical': 'flash-outline',
  'Exterior': 'home-outline',
  'Pool': 'water',
  'Landscaping': 'leaf-outline',
  'Safety': 'shield-checkmark-outline',
  'Appliances': 'cube-outline',
  'Roofing': 'umbrella-outline',
  'default': 'construct-outline',
};

export default function MaintenanceScreen() {
  const [tasks, setTasks] = useState<MaintenanceTask[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [filter, setFilter] = useState<'all' | 'upcoming' | 'overdue'>('all');

  const fetchTasks = async () => {
    try {
      // TODO: Replace with actual API call
      setTasks([
        {
          id: '1',
          title: 'HVAC Filter Replacement',
          description: 'Replace air filters in all HVAC units',
          category: 'HVAC',
          dueDate: '2025-01-15',
          frequency: 'Every 3 months',
          status: 'upcoming',
          estimatedCost: 50,
          lastCompleted: '2024-10-15',
        },
        {
          id: '2',
          title: 'Pool Winterization',
          description: 'Prepare pool for winter season',
          category: 'Pool',
          dueDate: '2024-12-30',
          frequency: 'Annually',
          status: 'due',
          estimatedCost: 350,
          assignedTo: 'Sarah Chen',
        },
        {
          id: '3',
          title: 'Smoke Detector Testing',
          description: 'Test all smoke and CO detectors',
          category: 'Safety',
          dueDate: '2024-12-20',
          frequency: 'Every 6 months',
          status: 'overdue',
          estimatedCost: 0,
        },
        {
          id: '4',
          title: 'Gutter Cleaning',
          description: 'Clean gutters and downspouts',
          category: 'Exterior',
          dueDate: '2024-11-15',
          frequency: 'Twice yearly',
          status: 'completed',
          estimatedCost: 200,
          lastCompleted: '2024-11-10',
        },
      ]);
    } catch (error) {
      console.error('Fetch tasks error:', error);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  };

  useEffect(() => {
    fetchTasks();
  }, []);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'overdue': return colors.status.error;
      case 'due': return colors.status.warning;
      case 'completed': return colors.status.success;
      default: return colors.haven.champagne[500];
    }
  };

  const getStatusLabel = (status: string) => {
    switch (status) {
      case 'overdue': return 'Overdue';
      case 'due': return 'Due Soon';
      case 'completed': return 'Completed';
      default: return 'Upcoming';
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    });
  };

  const filteredTasks = tasks.filter(task => {
    if (filter === 'all') return true;
    if (filter === 'upcoming') return task.status === 'upcoming' || task.status === 'due';
    if (filter === 'overdue') return task.status === 'overdue';
    return true;
  });

  const overdueCount = tasks.filter(t => t.status === 'overdue').length;

  const renderTask = ({ item }: { item: MaintenanceTask }) => (
    <Card style={styles.taskCard}>
      <View style={styles.taskHeader}>
        <View style={[styles.taskIcon, { backgroundColor: `${getStatusColor(item.status)}20` }]}>
          <Ionicons
            name={(CATEGORY_ICONS[item.category] || CATEGORY_ICONS.default) as any}
            size={20}
            color={getStatusColor(item.status)}
          />
        </View>
        <View style={styles.taskInfo}>
          <Text style={styles.taskTitle}>{item.title}</Text>
          <Text style={styles.taskCategory}>{item.category}</Text>
        </View>
        <Badge
          label={getStatusLabel(item.status)}
          variant={
            item.status === 'overdue' ? 'error' :
            item.status === 'due' ? 'warning' :
            item.status === 'completed' ? 'success' : 'outline'
          }
          size="sm"
        />
      </View>

      <Text style={styles.taskDescription}>{item.description}</Text>

      <View style={styles.taskMeta}>
        <View style={styles.metaItem}>
          <Ionicons name="calendar-outline" size={14} color={colors.text.tertiary} />
          <Text style={styles.metaText}>
            {item.status === 'completed' ? 'Completed' : 'Due'}: {formatDate(item.dueDate)}
          </Text>
        </View>
        <View style={styles.metaItem}>
          <Ionicons name="repeat-outline" size={14} color={colors.text.tertiary} />
          <Text style={styles.metaText}>{item.frequency}</Text>
        </View>
        {item.estimatedCost !== undefined && item.estimatedCost > 0 && (
          <View style={styles.metaItem}>
            <Ionicons name="cash-outline" size={14} color={colors.text.tertiary} />
            <Text style={styles.metaText}>~${item.estimatedCost}</Text>
          </View>
        )}
      </View>

      {item.assignedTo && (
        <View style={styles.assignedContainer}>
          <Ionicons name="person-outline" size={14} color={colors.haven.champagne[600]} />
          <Text style={styles.assignedText}>{item.assignedTo} is handling this</Text>
        </View>
      )}
    </Card>
  );

  if (isLoading) {
    return <LoadingSpinner fullScreen message="Loading maintenance..." />;
  }

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      {/* Filter Tabs */}
      <View style={styles.filterContainer}>
        <TouchableOpacity
          style={[styles.filterTab, filter === 'all' && styles.filterTabActive]}
          onPress={() => setFilter('all')}
        >
          <Text style={[styles.filterText, filter === 'all' && styles.filterTextActive]}>
            All
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.filterTab, filter === 'upcoming' && styles.filterTabActive]}
          onPress={() => setFilter('upcoming')}
        >
          <Text style={[styles.filterText, filter === 'upcoming' && styles.filterTextActive]}>
            Upcoming
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.filterTab, filter === 'overdue' && styles.filterTabActive]}
          onPress={() => setFilter('overdue')}
        >
          <Text style={[styles.filterText, filter === 'overdue' && styles.filterTextActive]}>
            Overdue
          </Text>
          {overdueCount > 0 && (
            <View style={styles.filterBadge}>
              <Text style={styles.filterBadgeText}>{overdueCount}</Text>
            </View>
          )}
        </TouchableOpacity>
      </View>

      {/* Tasks List */}
      <FlatList
        data={filteredTasks}
        renderItem={renderTask}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.listContent}
        refreshControl={
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={() => {
              setIsRefreshing(true);
              fetchTasks();
            }}
          />
        }
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Ionicons name="checkmark-circle" size={48} color={colors.haven.navy[300]} />
            <Text style={styles.emptyTitle}>No tasks found</Text>
          </View>
        }
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  filterContainer: {
    flexDirection: 'row',
    padding: spacing[4],
    gap: spacing[2],
  },
  filterTab: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[4],
    borderRadius: borderRadius.full,
    backgroundColor: colors.white,
  },
  filterTabActive: {
    backgroundColor: colors.haven.navy[900],
  },
  filterText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
  },
  filterTextActive: {
    color: colors.white,
  },
  filterBadge: {
    marginLeft: spacing[2],
    backgroundColor: colors.status.error,
    paddingHorizontal: spacing[2],
    paddingVertical: 2,
    borderRadius: borderRadius.full,
  },
  filterBadgeText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  listContent: {
    padding: spacing[4],
    paddingTop: 0,
  },
  taskCard: {
    padding: spacing[4],
    marginBottom: spacing[3],
  },
  taskHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing[2],
  },
  taskIcon: {
    width: 40,
    height: 40,
    borderRadius: borderRadius.lg,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  taskInfo: {
    flex: 1,
  },
  taskTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  taskCategory: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: 2,
  },
  taskDescription: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginBottom: spacing[3],
    lineHeight: 20,
  },
  taskMeta: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[4],
  },
  metaItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
  },
  metaText: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  assignedContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: spacing[3],
    paddingTop: spacing[3],
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
    gap: spacing[2],
  },
  assignedText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[600],
  },
  emptyContainer: {
    alignItems: 'center',
    paddingVertical: spacing[10],
  },
  emptyTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginTop: spacing[4],
  },
});
```

---

## PHASE 2: Create Document Vault Screen

### Task 2.1: Create Documents Screen

Create `apps/mobile/app/(tabs)/vault.tsx`:

```typescript
import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  RefreshControl,
  Alert,
  ActionSheetIOS,
  Platform,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';
import * as DocumentPicker from 'expo-document-picker';
import { Card, Badge, LoadingSpinner, Button } from '../../src/components';
import { colors, typography, spacing, borderRadius } from '../../src/lib/theme';

interface Document {
  id: string;
  name: string;
  category: string;
  uploadedAt: string;
  size: string;
  type: string;
  expiresAt?: string;
  thumbnailUrl?: string;
}

const CATEGORY_ICONS: Record<string, string> = {
  'Property': 'home-outline',
  'Insurance': 'shield-outline',
  'Warranty': 'document-text-outline',
  'Manual': 'book-outline',
  'Tax': 'calculator-outline',
  'Contract': 'create-outline',
  'Receipt': 'receipt-outline',
  'Permit': 'ribbon-outline',
  'default': 'document-outline',
};

const CATEGORIES = [
  'All',
  'Property',
  'Insurance',
  'Warranty',
  'Manual',
  'Tax',
  'Contract',
  'Receipt',
  'Permit',
];

export default function VaultScreen() {
  const [documents, setDocuments] = useState<Document[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState('All');

  const fetchDocuments = async () => {
    try {
      // TODO: Replace with actual API call
      setDocuments([
        {
          id: '1',
          name: 'Property Deed',
          category: 'Property',
          uploadedAt: '2024-06-15',
          size: '2.4 MB',
          type: 'pdf',
        },
        {
          id: '2',
          name: 'Home Insurance Policy',
          category: 'Insurance',
          uploadedAt: '2024-01-10',
          size: '1.8 MB',
          type: 'pdf',
          expiresAt: '2025-01-10',
        },
        {
          id: '3',
          name: 'HVAC Warranty',
          category: 'Warranty',
          uploadedAt: '2023-08-20',
          size: '850 KB',
          type: 'pdf',
          expiresAt: '2028-08-20',
        },
        {
          id: '4',
          name: 'Roof Inspection Report',
          category: 'Property',
          uploadedAt: '2024-11-05',
          size: '3.2 MB',
          type: 'pdf',
        },
      ]);
    } catch (error) {
      console.error('Fetch documents error:', error);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  };

  useEffect(() => {
    fetchDocuments();
  }, []);

  const handleUpload = () => {
    if (Platform.OS === 'ios') {
      ActionSheetIOS.showActionSheetWithOptions(
        {
          options: ['Cancel', 'Take Photo', 'Choose from Library', 'Browse Files'],
          cancelButtonIndex: 0,
        },
        async (buttonIndex) => {
          if (buttonIndex === 1) {
            takePhoto();
          } else if (buttonIndex === 2) {
            pickImage();
          } else if (buttonIndex === 3) {
            pickDocument();
          }
        }
      );
    } else {
      // Android - show custom modal or use library
      Alert.alert('Upload Document', 'Choose upload method', [
        { text: 'Camera', onPress: takePhoto },
        { text: 'Photo Library', onPress: pickImage },
        { text: 'Files', onPress: pickDocument },
        { text: 'Cancel', style: 'cancel' },
      ]);
    }
  };

  const takePhoto = async () => {
    const { status } = await ImagePicker.requestCameraPermissionsAsync();
    if (status !== 'granted') {
      Alert.alert('Permission needed', 'Camera permission is required to take photos');
      return;
    }

    const result = await ImagePicker.launchCameraAsync({
      quality: 0.8,
      allowsEditing: true,
    });

    if (!result.canceled) {
      // TODO: Upload to API
      Alert.alert('Success', 'Photo captured! Upload functionality coming soon.');
    }
  };

  const pickImage = async () => {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      quality: 0.8,
      allowsEditing: true,
    });

    if (!result.canceled) {
      // TODO: Upload to API
      Alert.alert('Success', 'Image selected! Upload functionality coming soon.');
    }
  };

  const pickDocument = async () => {
    const result = await DocumentPicker.getDocumentAsync({
      type: ['application/pdf', 'image/*'],
      copyToCacheDirectory: true,
    });

    if (!result.canceled) {
      // TODO: Upload to API
      Alert.alert('Success', 'Document selected! Upload functionality coming soon.');
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    });
  };

  const isExpiringSoon = (expiresAt?: string) => {
    if (!expiresAt) return false;
    const daysUntilExpiry = Math.ceil(
      (new Date(expiresAt).getTime() - Date.now()) / (1000 * 60 * 60 * 24)
    );
    return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
  };

  const isExpired = (expiresAt?: string) => {
    if (!expiresAt) return false;
    return new Date(expiresAt) < new Date();
  };

  const filteredDocuments = documents.filter(doc =>
    selectedCategory === 'All' ? true : doc.category === selectedCategory
  );

  const renderDocument = ({ item }: { item: Document }) => (
    <TouchableOpacity activeOpacity={0.7}>
      <Card style={styles.documentCard}>
        <View style={styles.documentIcon}>
          <Ionicons
            name={(CATEGORY_ICONS[item.category] || CATEGORY_ICONS.default) as any}
            size={24}
            color={colors.haven.champagne[500]}
          />
        </View>
        <View style={styles.documentInfo}>
          <Text style={styles.documentName} numberOfLines={1}>{item.name}</Text>
          <View style={styles.documentMeta}>
            <Text style={styles.documentCategory}>{item.category}</Text>
            <Text style={styles.documentSize}>{item.size}</Text>
          </View>
          <Text style={styles.documentDate}>Uploaded {formatDate(item.uploadedAt)}</Text>
        </View>
        <View style={styles.documentActions}>
          {item.expiresAt && (
            <Badge
              label={
                isExpired(item.expiresAt) ? 'Expired' :
                isExpiringSoon(item.expiresAt) ? 'Expiring Soon' : ''
              }
              variant={isExpired(item.expiresAt) ? 'error' : 'warning'}
              size="sm"
            />
          )}
          <Ionicons name="chevron-forward" size={20} color={colors.text.tertiary} />
        </View>
      </Card>
    </TouchableOpacity>
  );

  if (isLoading) {
    return <LoadingSpinner fullScreen message="Loading documents..." />;
  }

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      {/* Category Tabs */}
      <FlatList
        horizontal
        data={CATEGORIES}
        keyExtractor={(item) => item}
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.categoriesContainer}
        renderItem={({ item }) => (
          <TouchableOpacity
            style={[
              styles.categoryTab,
              selectedCategory === item && styles.categoryTabActive,
            ]}
            onPress={() => setSelectedCategory(item)}
          >
            <Text
              style={[
                styles.categoryText,
                selectedCategory === item && styles.categoryTextActive,
              ]}
            >
              {item}
            </Text>
          </TouchableOpacity>
        )}
      />

      {/* Documents List */}
      <FlatList
        data={filteredDocuments}
        renderItem={renderDocument}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.listContent}
        refreshControl={
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={() => {
              setIsRefreshing(true);
              fetchDocuments();
            }}
          />
        }
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Ionicons name="folder-open-outline" size={48} color={colors.haven.navy[300]} />
            <Text style={styles.emptyTitle}>No documents</Text>
            <Text style={styles.emptyText}>
              Upload documents to keep them safe and organized
            </Text>
          </View>
        }
      />

      {/* Upload FAB */}
      <TouchableOpacity style={styles.fab} onPress={handleUpload}>
        <Ionicons name="add" size={28} color={colors.white} />
      </TouchableOpacity>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  categoriesContainer: {
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[3],
    gap: spacing[2],
  },
  categoryTab: {
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[4],
    borderRadius: borderRadius.full,
    backgroundColor: colors.white,
    marginRight: spacing[2],
  },
  categoryTabActive: {
    backgroundColor: colors.haven.navy[900],
  },
  categoryText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
  },
  categoryTextActive: {
    color: colors.white,
  },
  listContent: {
    padding: spacing[4],
    paddingTop: 0,
    paddingBottom: spacing[20],
  },
  documentCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[4],
    marginBottom: spacing[3],
  },
  documentIcon: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  documentInfo: {
    flex: 1,
  },
  documentName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  documentMeta: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    marginTop: 2,
  },
  documentCategory: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.champagne[600],
  },
  documentSize: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  documentDate: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  documentActions: {
    alignItems: 'flex-end',
    gap: spacing[2],
  },
  fab: {
    position: 'absolute',
    right: spacing[5],
    bottom: spacing[5],
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: colors.haven.champagne[500],
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 8,
  },
  emptyContainer: {
    alignItems: 'center',
    paddingVertical: spacing[10],
  },
  emptyTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginTop: spacing[4],
  },
  emptyText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: spacing[1],
    textAlign: 'center',
  },
});
```

---

## PHASE 3: Create Family Management Screen

### Task 3.1: Create Family Screen

Create `apps/mobile/app/(tabs)/family.tsx`:

```typescript
import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { Card, Badge, LoadingSpinner } from '../../src/components';
import { colors, typography, spacing, borderRadius } from '../../src/lib/theme';

interface FamilyMember {
  id: string;
  name: string;
  role: 'Head of Household' | 'Spouse' | 'Child' | 'Other';
  email?: string;
  phone?: string;
  avatar?: string;
  age?: number;
  school?: string;
  allergies?: string[];
  activities?: string[];
}

interface Vehicle {
  id: string;
  make: string;
  model: string;
  year: number;
  color: string;
  licensePlate: string;
  owner: string;
}

interface Staff {
  id: string;
  name: string;
  role: string;
  phone: string;
  schedule: string;
  agency?: string;
}

interface Pet {
  id: string;
  name: string;
  type: string;
  breed: string;
  age: number;
  vet?: string;
}

export default function FamilyScreen() {
  const [members, setMembers] = useState<FamilyMember[]>([]);
  const [vehicles, setVehicles] = useState<Vehicle[]>([]);
  const [staff, setStaff] = useState<Staff[]>([]);
  const [pets, setPets] = useState<Pet[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);

  const fetchData = async () => {
    try {
      // TODO: Replace with actual API calls
      setMembers([
        {
          id: '1',
          name: 'Bob Morrison',
          role: 'Head of Household',
          email: 'bob@example.com',
          phone: '(203) 555-0101',
        },
        {
          id: '2',
          name: 'Alice Morrison',
          role: 'Spouse',
          email: 'alice@example.com',
          phone: '(203) 555-0102',
        },
        {
          id: '3',
          name: 'Emma Morrison',
          role: 'Child',
          age: 12,
          school: 'Greenwich Country Day School',
          allergies: ['Peanuts', 'Tree nuts'],
          activities: ['Soccer', 'Piano'],
        },
        {
          id: '4',
          name: 'Jack Morrison',
          role: 'Child',
          age: 8,
          school: 'North Street School',
          activities: ['Little League', 'Piano', 'Art'],
        },
      ]);

      setVehicles([
        {
          id: '1',
          make: 'Tesla',
          model: 'Model Y',
          year: 2023,
          color: 'White',
          licensePlate: 'GRN 1234',
          owner: 'Bob Morrison',
        },
        {
          id: '2',
          make: 'Toyota',
          model: 'Highlander',
          year: 2022,
          color: 'Silver',
          licensePlate: 'ABC 5678',
          owner: 'Alice Morrison',
        },
      ]);

      setStaff([
        {
          id: '1',
          name: 'Maria Garcia',
          role: 'Nanny',
          phone: '(203) 555-0199',
          schedule: 'Mon-Thu 7am-6pm, Fri 7am-3pm',
          agency: 'Greenwich Elite Nannies',
        },
      ]);

      setPets([
        {
          id: '1',
          name: 'Max',
          type: 'Dog',
          breed: 'Golden Retriever',
          age: 4,
          vet: 'Dr. Williams, Westlake Animal Hospital',
        },
      ]);
    } catch (error) {
      console.error('Fetch family data error:', error);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  if (isLoading) {
    return <LoadingSpinner fullScreen message="Loading family..." />;
  }

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        refreshControl={
          <RefreshControl refreshing={isRefreshing} onRefresh={() => {
            setIsRefreshing(true);
            fetchData();
          }} />
        }
        showsVerticalScrollIndicator={false}
      >
        {/* Family Members */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Family Members</Text>
            <TouchableOpacity>
              <Ionicons name="add-circle" size={24} color={colors.haven.champagne[500]} />
            </TouchableOpacity>
          </View>
          {members.map((member) => (
            <Card key={member.id} style={styles.memberCard}>
              <View style={styles.memberAvatar}>
                <Text style={styles.memberInitials}>
                  {member.name.split(' ').map(n => n[0]).join('')}
                </Text>
              </View>
              <View style={styles.memberInfo}>
                <Text style={styles.memberName}>{member.name}</Text>
                <Text style={styles.memberRole}>{member.role}</Text>
                {member.age && (
                  <Text style={styles.memberDetail}>Age {member.age}</Text>
                )}
                {member.school && (
                  <Text style={styles.memberDetail}>{member.school}</Text>
                )}
                {member.allergies && member.allergies.length > 0 && (
                  <View style={styles.allergiesContainer}>
                    <Ionicons name="warning" size={12} color={colors.status.error} />
                    <Text style={styles.allergiesText}>
                      Allergies: {member.allergies.join(', ')}
                    </Text>
                  </View>
                )}
              </View>
              <Ionicons name="chevron-forward" size={20} color={colors.text.tertiary} />
            </Card>
          ))}
        </View>

        {/* Vehicles */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Vehicles</Text>
            <TouchableOpacity>
              <Ionicons name="add-circle" size={24} color={colors.haven.champagne[500]} />
            </TouchableOpacity>
          </View>
          {vehicles.map((vehicle) => (
            <Card key={vehicle.id} style={styles.vehicleCard}>
              <View style={styles.vehicleIcon}>
                <Ionicons name="car" size={24} color={colors.haven.navy[600]} />
              </View>
              <View style={styles.vehicleInfo}>
                <Text style={styles.vehicleName}>
                  {vehicle.year} {vehicle.make} {vehicle.model}
                </Text>
                <Text style={styles.vehicleDetail}>
                  {vehicle.color} • {vehicle.licensePlate}
                </Text>
                <Text style={styles.vehicleOwner}>{vehicle.owner}</Text>
              </View>
              <Ionicons name="chevron-forward" size={20} color={colors.text.tertiary} />
            </Card>
          ))}
        </View>

        {/* Staff */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Household Staff</Text>
            <TouchableOpacity>
              <Ionicons name="add-circle" size={24} color={colors.haven.champagne[500]} />
            </TouchableOpacity>
          </View>
          {staff.map((person) => (
            <Card key={person.id} style={styles.staffCard}>
              <View style={styles.staffAvatar}>
                <Ionicons name="person" size={24} color={colors.haven.champagne[500]} />
              </View>
              <View style={styles.staffInfo}>
                <Text style={styles.staffName}>{person.name}</Text>
                <Text style={styles.staffRole}>{person.role}</Text>
                <Text style={styles.staffDetail}>{person.schedule}</Text>
                {person.agency && (
                  <Text style={styles.staffAgency}>{person.agency}</Text>
                )}
              </View>
              <TouchableOpacity style={styles.callButton}>
                <Ionicons name="call" size={20} color={colors.haven.champagne[500]} />
              </TouchableOpacity>
            </Card>
          ))}
        </View>

        {/* Pets */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Pets</Text>
            <TouchableOpacity>
              <Ionicons name="add-circle" size={24} color={colors.haven.champagne[500]} />
            </TouchableOpacity>
          </View>
          {pets.map((pet) => (
            <Card key={pet.id} style={styles.petCard}>
              <View style={styles.petIcon}>
                <Ionicons name="paw" size={24} color={colors.haven.champagne[500]} />
              </View>
              <View style={styles.petInfo}>
                <Text style={styles.petName}>{pet.name}</Text>
                <Text style={styles.petDetail}>
                  {pet.breed} • {pet.age} years old
                </Text>
                {pet.vet && (
                  <Text style={styles.petVet}>{pet.vet}</Text>
                )}
              </View>
              <Ionicons name="chevron-forward" size={20} color={colors.text.tertiary} />
            </Card>
          ))}
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  scrollContent: {
    padding: spacing[4],
    paddingBottom: spacing[8],
  },
  section: {
    marginBottom: spacing[6],
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[3],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  memberCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[4],
    marginBottom: spacing[2],
  },
  memberAvatar: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: colors.haven.navy[100],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  memberInitials: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.navy[700],
  },
  memberInfo: {
    flex: 1,
  },
  memberName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  memberRole: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[600],
    marginTop: 2,
  },
  memberDetail: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  allergiesContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: spacing[1],
    gap: spacing[1],
  },
  allergiesText: {
    fontSize: typography.fontSizes.xs,
    color: colors.status.error,
  },
  vehicleCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[4],
    marginBottom: spacing[2],
  },
  vehicleIcon: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.navy[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  vehicleInfo: {
    flex: 1,
  },
  vehicleName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  vehicleDetail: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: 2,
  },
  vehicleOwner: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  staffCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[4],
    marginBottom: spacing[2],
  },
  staffAvatar: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  staffInfo: {
    flex: 1,
  },
  staffName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  staffRole: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[600],
    marginTop: 2,
  },
  staffDetail: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    marginTop: 2,
  },
  staffAgency: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  callButton: {
    padding: spacing[2],
  },
  petCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[4],
    marginBottom: spacing[2],
  },
  petIcon: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  petInfo: {
    flex: 1,
  },
  petName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  petDetail: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: 2,
  },
  petVet: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
});
```

---

## PHASE 4: Update Navigation

### Task 4.1: Add More Tab Screen

Create `apps/mobile/app/(tabs)/more.tsx`:

```typescript
import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
} from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { colors, typography, spacing, borderRadius } from '../../src/lib/theme';

interface MenuItem {
  id: string;
  title: string;
  subtitle?: string;
  icon: string;
  route: string;
  badge?: string;
}

const MENU_SECTIONS: { title: string; items: MenuItem[] }[] = [
  {
    title: 'Your Home',
    items: [
      { id: 'home', title: 'Property Details', icon: 'home-outline', route: '/(tabs)/home' },
      { id: 'family', title: 'Family & Household', icon: 'people-outline', route: '/(tabs)/family' },
      { id: 'maintenance', title: 'Maintenance', icon: 'construct-outline', route: '/(tabs)/maintenance' },
      { id: 'vault', title: 'Document Vault', icon: 'folder-outline', route: '/(tabs)/vault' },
    ],
  },
  {
    title: 'Financial',
    items: [
      { id: 'bills', title: 'Bills & Payments', icon: 'receipt-outline', route: '/(tabs)/money/bills' },
      { id: 'banks', title: 'Connected Banks', icon: 'card-outline', route: '/(tabs)/money/banks' },
    ],
  },
  {
    title: 'Account',
    items: [
      { id: 'profile', title: 'My Profile', icon: 'person-outline', route: '/(tabs)/profile' },
      { id: 'settings', title: 'Settings', icon: 'settings-outline', route: '/(tabs)/settings' },
    ],
  },
];

export default function MoreScreen() {
  const router = useRouter();

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <ScrollView contentContainerStyle={styles.scrollContent}>
        {MENU_SECTIONS.map((section) => (
          <View key={section.title} style={styles.section}>
            <Text style={styles.sectionTitle}>{section.title}</Text>
            <View style={styles.menuList}>
              {section.items.map((item, index) => (
                <TouchableOpacity
                  key={item.id}
                  style={[
                    styles.menuItem,
                    index === 0 && styles.menuItemFirst,
                    index === section.items.length - 1 && styles.menuItemLast,
                  ]}
                  onPress={() => router.push(item.route as any)}
                >
                  <View style={styles.menuIcon}>
                    <Ionicons
                      name={item.icon as any}
                      size={22}
                      color={colors.haven.champagne[500]}
                    />
                  </View>
                  <View style={styles.menuContent}>
                    <Text style={styles.menuTitle}>{item.title}</Text>
                    {item.subtitle && (
                      <Text style={styles.menuSubtitle}>{item.subtitle}</Text>
                    )}
                  </View>
                  {item.badge && (
                    <View style={styles.menuBadge}>
                      <Text style={styles.menuBadgeText}>{item.badge}</Text>
                    </View>
                  )}
                  <Ionicons
                    name="chevron-forward"
                    size={20}
                    color={colors.text.tertiary}
                  />
                </TouchableOpacity>
              ))}
            </View>
          </View>
        ))}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  scrollContent: {
    padding: spacing[4],
  },
  section: {
    marginBottom: spacing[6],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.tertiary,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    marginBottom: spacing[2],
    marginLeft: spacing[4],
  },
  menuList: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    overflow: 'hidden',
  },
  menuItem: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[4],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  menuItemFirst: {
    borderTopLeftRadius: borderRadius.xl,
    borderTopRightRadius: borderRadius.xl,
  },
  menuItemLast: {
    borderBottomWidth: 0,
    borderBottomLeftRadius: borderRadius.xl,
    borderBottomRightRadius: borderRadius.xl,
  },
  menuIcon: {
    width: 36,
    height: 36,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  menuContent: {
    flex: 1,
  },
  menuTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  menuSubtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: 2,
  },
  menuBadge: {
    backgroundColor: colors.status.error,
    paddingHorizontal: spacing[2],
    paddingVertical: 2,
    borderRadius: borderRadius.full,
    marginRight: spacing[2],
  },
  menuBadgeText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
});
```

---

## PHASE 5: Verification

### Task 5.1: Test Checklist

- [ ] Maintenance screen shows tasks with filters
- [ ] Document vault displays documents by category
- [ ] Camera and file picker work for uploads
- [ ] Family screen shows members, vehicles, staff, pets
- [ ] More menu navigates to correct screens
- [ ] All data displays correctly
- [ ] No TypeScript errors (`pnpm typecheck`)

### Task 5.2: Test Commands

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
pnpm typecheck
pnpm start --ios
```

---

## Summary

After completing this prompt:
1. ✅ Maintenance calendar with task filters
2. ✅ Document vault with camera upload
3. ✅ Family management (members, vehicles, staff, pets)
4. ✅ More menu for navigation
5. ✅ Full feature parity with web

**Next Prompt:** M08 - Settings & Profile
