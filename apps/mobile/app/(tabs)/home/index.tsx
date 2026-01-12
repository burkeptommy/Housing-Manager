import React, { useEffect, useState, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
  Dimensions,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { formatDistanceToNow } from 'date-fns';
import { useAuth } from '../../../src/contexts/auth-context';
import { Card, Badge, AnimatedCard, SectionHeader, ScreenContainer, AlfredTabIcon } from '../../../src/components';
import { Skeleton } from '../../../src/components/ui/Skeleton';
import { colors, typography, spacing, borderRadius, shadows } from '../../../src/lib/theme';
import { API_BASE_URL } from '../../../src/lib/api';
import { getIdToken } from '../../../src/lib/firebase';
import { askAlfredForHelp } from '../../../src/lib/navigation';
import { AddZoneModal } from '../../../src/components/forms/AddZoneModal';
import { AddAssetModal } from '../../../src/components/forms/AddAssetModal';

// =============================================================================
// TYPES
// =============================================================================

type ZoneType =
  | 'KITCHEN' | 'LIVING_ROOM' | 'DINING_ROOM' | 'BEDROOM' | 'BATHROOM'
  | 'GARAGE' | 'BASEMENT' | 'ATTIC' | 'LAUNDRY' | 'OFFICE' | 'MUDROOM'
  | 'PANTRY' | 'OUTDOOR_FRONT' | 'OUTDOOR_BACK' | 'POOL_AREA' | 'MECHANICAL' | 'OTHER';

type AssetCategory =
  | 'APPLIANCE' | 'HVAC' | 'PLUMBING' | 'ELECTRICAL' | 'STRUCTURAL'
  | 'FURNITURE' | 'ELECTRONICS' | 'OUTDOOR' | 'VEHICLE' | 'SAFETY' | 'OTHER';

interface Zone {
  id: string;
  name: string;
  type: ZoneType;
  floor: string | null;
  assetCount: number;
  photos: string[];
  notes: string | null;
  procedures: string | null;
  assets: Asset[];
}

interface Asset {
  id: string;
  name: string;
  category: AssetCategory;
  brand: string | null;
  model: string | null;
  serialNumber: string | null;
  condition: string | null;
  lastServiceDate: string | null;
  nextServiceDate: string | null;
  serviceVendor: string | null;
  notes: string | null;
}

interface SystemStatus {
  id: string;
  name: string;
  category: string;
  status: 'good' | 'warning' | 'attention';
  warning?: string;
}

interface UtilityInfo {
  provider: string | null;
  confirmed?: boolean;
  source?: string | null;
  type?: string | null;
}

interface Utilities {
  electricity: UtilityInfo;
  gas: UtilityInfo;
  water: UtilityInfo;
  sewer: UtilityInfo;
  heatingFuel: UtilityInfo;
  internet: UtilityInfo;
  cable: UtilityInfo;
}

interface UpcomingTask {
  id: string;
  title: string;
  status: string;
  dueDate: string | null;
  category: string;
}

interface PropertyData {
  property: {
    id: string;
    name: string;
    address: {
      street: string;
      city: string;
      state: string;
      zip: string;
      full: string;
    } | null;
    details: {
      bedrooms: number | null;
      bathrooms: number | null;
      squareFeet: number | null;
      yearBuilt: number | null;
      lotSize: number | null;
      propertyType: string | null;
    };
  };
  systems: SystemStatus[];
  zones: Zone[];
  utilities?: Utilities;
  upcomingMaintenance?: UpcomingTask[];
  alfred?: {
    pendingQuestions: number;
    dataCompletion: number;
  };
}

interface ActivityFeedItem {
  id: string;
  category: 'BILLING' | 'SERVICE' | 'MAINTENANCE' | 'COMMUNICATION' | 'PROPERTY' | 'FAMILY' | 'SYSTEM';
  action: string;
  title: string;
  description: string | null;
  actorName: string;
  billId: string | null;
  vendorId: string | null;
  assetId: string | null;
  zoneId: string | null;
  taskId: string | null;
  amount: number | null;
  createdAt: string;
}

// =============================================================================
// HELPERS
// =============================================================================

const ZONE_ICONS: Record<ZoneType, keyof typeof Ionicons.glyphMap> = {
  KITCHEN: 'restaurant-outline',
  LIVING_ROOM: 'tv-outline',
  DINING_ROOM: 'cafe-outline',
  BEDROOM: 'bed-outline',
  BATHROOM: 'water-outline',
  GARAGE: 'car-outline',
  BASEMENT: 'layers-outline',
  ATTIC: 'home-outline',
  LAUNDRY: 'shirt-outline',
  OFFICE: 'desktop-outline',
  MUDROOM: 'footsteps-outline',
  PANTRY: 'fast-food-outline',
  OUTDOOR_FRONT: 'leaf-outline',
  OUTDOOR_BACK: 'flower-outline',
  POOL_AREA: 'water-outline',
  MECHANICAL: 'construct-outline',
  OTHER: 'cube-outline',
};

const ZONE_COLORS: Record<ZoneType, string> = {
  KITCHEN: colors.haven.champagne[500],
  LIVING_ROOM: colors.haven.navy[500],
  DINING_ROOM: colors.haven.champagne[600],
  BEDROOM: colors.indigo[500],
  BATHROOM: colors.blue[500],
  GARAGE: colors.gray[600],
  BASEMENT: colors.slate[600],
  ATTIC: colors.amber[500],
  LAUNDRY: colors.cyan[500],
  OFFICE: colors.emerald[500],
  MUDROOM: colors.orange[500],
  PANTRY: colors.rose[500],
  OUTDOOR_FRONT: colors.green[500],
  OUTDOOR_BACK: colors.lime[600],
  POOL_AREA: colors.sky[500],
  MECHANICAL: colors.red[500],
  OTHER: colors.gray[500],
};

function getZoneDisplayName(type: ZoneType): string {
  const names: Record<ZoneType, string> = {
    KITCHEN: 'Kitchen',
    LIVING_ROOM: 'Living Room',
    DINING_ROOM: 'Dining Room',
    BEDROOM: 'Bedroom',
    BATHROOM: 'Bathroom',
    GARAGE: 'Garage',
    BASEMENT: 'Basement',
    ATTIC: 'Attic',
    LAUNDRY: 'Laundry',
    OFFICE: 'Office',
    MUDROOM: 'Mudroom',
    PANTRY: 'Pantry',
    OUTDOOR_FRONT: 'Front Yard',
    OUTDOOR_BACK: 'Back Yard',
    POOL_AREA: 'Pool Area',
    MECHANICAL: 'Mechanical',
    OTHER: 'Other',
  };
  return names[type] || type;
}

function getStatusIcon(status: 'good' | 'warning' | 'attention'): keyof typeof Ionicons.glyphMap {
  switch (status) {
    case 'good': return 'checkmark-circle';
    case 'warning': return 'alert-circle';
    case 'attention': return 'close-circle';
  }
}

function getStatusColor(status: 'good' | 'warning' | 'attention'): string {
  switch (status) {
    case 'good': return colors.status.success;
    case 'warning': return colors.status.warning;
    case 'attention': return colors.status.error;
  }
}

// Activity Feed Config
function getActivityConfig(category: string): { emoji: string; bgColor: string } {
  const configs: Record<string, { emoji: string; bgColor: string }> = {
    PROPERTY: { emoji: '🏠', bgColor: '#E0E7FF' },     // indigo-100
    BILLING: { emoji: '💰', bgColor: '#D1FAE5' },     // green-100
    FAMILY: { emoji: '👨‍👩‍👧‍👦', bgColor: '#FCE7F3' },    // pink-100
    MAINTENANCE: { emoji: '🔧', bgColor: '#FEF3C7' }, // amber-100
    SERVICE: { emoji: '👷', bgColor: '#DBEAFE' },     // blue-100
    SYSTEM: { emoji: '🤖', bgColor: '#F3E8FF' },      // purple-100
    COMMUNICATION: { emoji: '💬', bgColor: '#E0F2FE' }, // sky-100
  };
  return configs[category] || { emoji: '📌', bgColor: '#F3F4F6' };
}

// =============================================================================
// COMPONENT
// =============================================================================

const { width: screenWidth } = Dimensions.get('window');
const ZONE_CARD_WIDTH = (screenWidth - spacing[4] * 2 - spacing[3]) / 2;

export default function YourHomeScreen() {
  const router = useRouter();
  const { householdInfo } = useAuth();
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [data, setData] = useState<PropertyData | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [activities, setActivities] = useState<ActivityFeedItem[]>([]);

  // Modal states
  const [showAddZoneModal, setShowAddZoneModal] = useState(false);
  const [showAddAssetModal, setShowAddAssetModal] = useState(false);

  const fetchProperty = useCallback(async () => {
    if (!householdInfo?.id) {
      setIsLoading(false);
      setError('No household found. Please complete onboarding.');
      return;
    }

    try {
      const token = await getIdToken(true);
      if (!token) {
        setError('Authentication expired. Please sign in again.');
        setIsLoading(false);
        return;
      }

      // Fetch dashboard data (includes utilities, maintenance, and Alfred context)
      const dashboardRes = await fetch(`${API_BASE_URL}/home/dashboard/${householdInfo.id}`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      // Also fetch property data for zones/assets
      const propertyRes = await fetch(`${API_BASE_URL}/property/household/${householdInfo.id}`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (!propertyRes.ok) {
        throw new Error(`Failed to fetch property: ${propertyRes.status}`);
      }

      const propertyData = await propertyRes.json();

      // Merge dashboard data if available
      if (dashboardRes.ok) {
        const dashboardData = await dashboardRes.json();
        propertyData.utilities = dashboardData.utilities;
        propertyData.upcomingMaintenance = dashboardData.upcomingMaintenance;
        propertyData.alfred = dashboardData.alfred;
      }

      setData(propertyData);
      setError(null);
    } catch (err) {
      console.error('Property fetch error:', err);
      setError('Failed to load property. Please try again.');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [householdInfo?.id]);

  // Fetch recent activity feed
  const fetchActivities = useCallback(async () => {
    if (!householdInfo?.id) return;

    try {
      const token = await getIdToken(true);
      if (!token) return;

      const response = await fetch(
        `${API_BASE_URL}/activity/household/${householdInfo.id}/recent`,
        { headers: { Authorization: `Bearer ${token}` } }
      );

      if (response.ok) {
        const data = await response.json();
        setActivities(data);
      }
    } catch (err) {
      console.error('Failed to fetch activities:', err);
    }
  }, [householdInfo?.id]);

  useEffect(() => {
    fetchProperty();
    fetchActivities();
  }, [fetchProperty, fetchActivities]);

  const onRefresh = () => {
    setIsRefreshing(true);
    fetchProperty();
    fetchActivities();
  };

  if (isLoading) {
    return (
      <ScreenContainer title="Property & Zones" onBackPress={() => router.navigate('/more')}>
        {/* Header Skeleton */}
        <View style={styles.header}>
          <Skeleton width={200} height={24} />
          <Skeleton width={screenWidth - 32} height={16} style={{ marginTop: 8 }} />
        </View>
        {/* Zones Grid Skeleton */}
        <View style={styles.zonesGrid}>
          {[1, 2, 3, 4].map((i) => (
            <Skeleton key={i} width={ZONE_CARD_WIDTH} height={120} borderRadius={16} />
          ))}
        </View>
      </ScreenContainer>
    );
  }

  if (error || !data) {
    return (
      <ScreenContainer title="Property & Zones" onBackPress={() => router.navigate('/more')}>
        <View style={styles.errorContainer}>
          <Ionicons name="alert-circle" size={48} color={colors.status.error} />
          <Text style={styles.errorTitle}>Unable to Load Property</Text>
          <Text style={styles.errorText}>{error}</Text>
          <TouchableOpacity style={styles.retryButton} onPress={fetchProperty}>
            <Text style={styles.retryText}>Try Again</Text>
          </TouchableOpacity>
        </View>
      </ScreenContainer>
    );
  }

  const totalAssets = data.zones.reduce((sum, zone) => sum + zone.assetCount, 0);

  return (
    <ScreenContainer
      title="Property & Zones"
      onBackPress={() => router.navigate('/more')}
      scrollable={false}
    >
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.scrollContent}
        refreshControl={<RefreshControl refreshing={isRefreshing} onRefresh={onRefresh} />}
        showsVerticalScrollIndicator={false}
      >
        {/* Property Header */}
        <View style={styles.header}>
          <Text style={styles.propertyName}>{data.property.name}</Text>
          {data.property.address && (
            <Text style={styles.propertyAddress}>{data.property.address.full}</Text>
          )}

          {/* Property Stats */}
          <View style={styles.propertyStats}>
            {data.property.details.bedrooms && (
              <View style={styles.statBadge}>
                <Ionicons name="bed-outline" size={14} color={colors.text.secondary} />
                <Text style={styles.statText}>{data.property.details.bedrooms} bed</Text>
              </View>
            )}
            {data.property.details.bathrooms && (
              <View style={styles.statBadge}>
                <Ionicons name="water-outline" size={14} color={colors.text.secondary} />
                <Text style={styles.statText}>{data.property.details.bathrooms} bath</Text>
              </View>
            )}
            {data.property.details.squareFeet && (
              <View style={styles.statBadge}>
                <Ionicons name="resize-outline" size={14} color={colors.text.secondary} />
                <Text style={styles.statText}>{data.property.details.squareFeet.toLocaleString()} sqft</Text>
              </View>
            )}
            {data.property.details.yearBuilt && (
              <View style={styles.statBadge}>
                <Ionicons name="calendar-outline" size={14} color={colors.text.secondary} />
                <Text style={styles.statText}>Built {data.property.details.yearBuilt}</Text>
              </View>
            )}
          </View>
        </View>

        {/* Utilities Section */}
        <View style={styles.section}>
          <SectionHeader
            title="Utilities"
            subtitle="Your service providers"
            actionText="+ Add"
            onActionPress={() => router.push('/(tabs)/manager/vendors/add' as any)}
          />
          {data.utilities && (
            data.utilities.electricity?.provider ||
            data.utilities.gas?.provider ||
            data.utilities.water?.provider ||
            data.utilities.internet?.provider
          ) ? (
            <View style={styles.utilitiesGrid}>
              {data.utilities.electricity?.provider && (
                <TouchableOpacity
                  style={styles.utilityCard}
                  onPress={() => router.push('/(tabs)/manager/vendors')}
                >
                  <Ionicons name="flash-outline" size={24} color={colors.amber[500]} />
                  <Text style={styles.utilityLabel}>Electric</Text>
                  <Text style={styles.utilityProvider}>{data.utilities.electricity.provider}</Text>
                </TouchableOpacity>
              )}
              {data.utilities.gas?.provider && (
                <TouchableOpacity
                  style={styles.utilityCard}
                  onPress={() => router.push('/(tabs)/manager/vendors')}
                >
                  <Ionicons name="flame-outline" size={24} color={colors.orange[500]} />
                  <Text style={styles.utilityLabel}>Gas</Text>
                  <Text style={styles.utilityProvider}>{data.utilities.gas.provider}</Text>
                </TouchableOpacity>
              )}
              {data.utilities.water?.provider && (
                <TouchableOpacity
                  style={styles.utilityCard}
                  onPress={() => router.push('/(tabs)/manager/vendors')}
                >
                  <Ionicons name="water-outline" size={24} color={colors.blue[500]} />
                  <Text style={styles.utilityLabel}>Water</Text>
                  <Text style={styles.utilityProvider}>{data.utilities.water.provider}</Text>
                </TouchableOpacity>
              )}
              {data.utilities.internet?.provider && (
                <TouchableOpacity
                  style={styles.utilityCard}
                  onPress={() => router.push('/(tabs)/manager/vendors')}
                >
                  <Ionicons name="wifi-outline" size={24} color={colors.indigo[500]} />
                  <Text style={styles.utilityLabel}>Internet</Text>
                  <Text style={styles.utilityProvider}>{data.utilities.internet.provider}</Text>
                </TouchableOpacity>
              )}
            </View>
          ) : (
            <TouchableOpacity
              style={styles.emptyUtilityCard}
              onPress={() => router.push('/(tabs)/manager/vendors/add' as any)}
            >
              <Ionicons name="flash-outline" size={32} color={colors.haven.champagne[500]} />
              <Text style={styles.emptyUtilityText}>Add your utility providers</Text>
              <Text style={styles.emptyUtilitySubtext}>Electric, gas, water, internet...</Text>
            </TouchableOpacity>
          )}
        </View>

        {/* Systems Status */}
        {data.systems.length > 0 && (
          <View style={styles.section}>
            <SectionHeader
              title="Home Systems"
              subtitle={`${data.systems.length} systems tracked`}
            />
            <ScrollView
              horizontal
              showsHorizontalScrollIndicator={false}
              style={styles.systemsScroll}
              contentContainerStyle={styles.systemsContent}
            >
              {data.systems.map((system) => (
                <TouchableOpacity key={system.id} style={styles.systemCard}>
                  <View style={[styles.systemIcon, { backgroundColor: getStatusColor(system.status) + '20' }]}>
                    <Ionicons
                      name={getStatusIcon(system.status)}
                      size={20}
                      color={getStatusColor(system.status)}
                    />
                  </View>
                  <Text style={styles.systemName}>{system.name}</Text>
                  <Text style={styles.systemStatus}>
                    {system.status === 'good' ? 'All good' : system.warning || 'Needs attention'}
                  </Text>
                </TouchableOpacity>
              ))}
            </ScrollView>
          </View>
        )}

        {/* Zones Grid */}
        <View style={styles.section}>
          <SectionHeader
            title="Property Zones"
            subtitle={`${data.zones.length} zones • ${totalAssets} items`}
            actionText="Add Zone"
            onActionPress={() => setShowAddZoneModal(true)}
          />

          {data.zones.length === 0 ? (
            <TouchableOpacity
              style={styles.emptyCard}
              onPress={() => setShowAddZoneModal(true)}
            >
              <Ionicons name="add-circle-outline" size={24} color={colors.text.tertiary} />
              <Text style={styles.emptyText}>Add your first zone</Text>
            </TouchableOpacity>
          ) : (
            <View style={styles.zonesGrid}>
              {data.zones.map((zone, index) => (
                <TouchableOpacity
                  key={zone.id}
                  style={styles.zoneCard}
                  onPress={() => router.push(`/(tabs)/home/zone/${zone.id}`)}
                >
                  <View style={[styles.zoneIconContainer, { backgroundColor: ZONE_COLORS[zone.type] + '20' }]}>
                    <Ionicons
                      name={ZONE_ICONS[zone.type]}
                      size={28}
                      color={ZONE_COLORS[zone.type]}
                    />
                  </View>
                  <Text style={styles.zoneName} numberOfLines={1}>{zone.name}</Text>
                  <Text style={styles.zoneType}>{getZoneDisplayName(zone.type)}</Text>
                  <View style={styles.zoneFooter}>
                    <View style={styles.assetCount}>
                      <Ionicons name="cube-outline" size={12} color={colors.text.tertiary} />
                      <Text style={styles.assetCountText}>
                        {zone.assetCount} {zone.assetCount === 1 ? 'item' : 'items'}
                      </Text>
                    </View>
                    {zone.floor && (
                      <Text style={styles.zoneFloor}>{zone.floor}</Text>
                    )}
                  </View>
                </TouchableOpacity>
              ))}
            </View>
          )}
        </View>

        {/* Quick Add Asset */}
        <View style={styles.section}>
          <SectionHeader
            title="All Appliances & Systems"
            subtitle="Manage your home inventory"
            actionText="Add Item"
            onActionPress={() => setShowAddAssetModal(true)}
          />

          {/* Recent Assets Preview */}
          {data.zones.flatMap(z => z.assets).slice(0, 5).length === 0 ? (
            <TouchableOpacity
              style={styles.emptyCard}
              onPress={() => setShowAddAssetModal(true)}
            >
              <Ionicons name="add-circle-outline" size={24} color={colors.text.tertiary} />
              <Text style={styles.emptyText}>Add appliances and systems</Text>
            </TouchableOpacity>
          ) : (
            <AnimatedCard style={styles.assetsCard}>
              {data.zones.flatMap(z => z.assets.map(a => ({ ...a, zoneName: z.name }))).slice(0, 5).map((asset, index) => (
                <TouchableOpacity
                  key={asset.id}
                  style={[
                    styles.assetRow,
                    index < 4 && styles.assetBorder,
                  ]}
                  onPress={() => router.push(`/(tabs)/home/asset/${asset.id}`)}
                >
                  <View style={styles.assetInfo}>
                    <Text style={styles.assetName}>{asset.name}</Text>
                    <Text style={styles.assetLocation}>{asset.zoneName}</Text>
                  </View>
                  {asset.brand && (
                    <Text style={styles.assetBrand}>{asset.brand}</Text>
                  )}
                  <Ionicons name="chevron-forward" size={16} color={colors.text.tertiary} />
                </TouchableOpacity>
              ))}
              {totalAssets > 5 && (
                <TouchableOpacity
                  style={styles.viewAllButton}
                  onPress={() => router.push('/(tabs)/home/assets' as any)}
                >
                  <Text style={styles.viewAllText}>View all {totalAssets} items</Text>
                  <Ionicons name="arrow-forward" size={16} color={colors.haven.champagne[500]} />
                </TouchableOpacity>
              )}
            </AnimatedCard>
          )}
        </View>

        {/* Recent Activity Section */}
        <View style={styles.section}>
          <SectionHeader
            title="Recent Activity"
            subtitle="What's happening"
            actionText="See All"
            onActionPress={() => router.push('/(tabs)/home/activity' as any)}
          />

          <View style={styles.activityList}>
            {activities.length === 0 ? (
              <View style={styles.activityEmpty}>
                <Text style={styles.activityEmptyText}>No recent activity</Text>
              </View>
            ) : (
              activities.slice(0, 5).map((activity, index) => {
                const config = getActivityConfig(activity.category);
                return (
                  <View
                    key={activity.id}
                    style={[
                      styles.activityItem,
                      index < Math.min(activities.length - 1, 4) && styles.activityItemBorder,
                    ]}
                  >
                    <View style={[styles.activityEmoji, { backgroundColor: config.bgColor }]}>
                      <Text style={styles.activityEmojiText}>{config.emoji}</Text>
                    </View>
                    <View style={styles.activityContent}>
                      <Text style={styles.activityTitle} numberOfLines={1}>{activity.title}</Text>
                      {activity.description && (
                        <Text style={styles.activityDescription} numberOfLines={1}>
                          {activity.description}
                        </Text>
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

        {/* Vendors Section */}
        <View style={styles.section}>
          <SectionHeader
            title="Your Vendors"
            subtitle="Manage service providers"
            actionText="View All"
            onActionPress={() => router.push('/(tabs)/manager/vendors')}
          />

          <TouchableOpacity
            style={styles.vendorsCard}
            onPress={() => router.push('/(tabs)/manager/vendors')}
          >
            <View style={styles.vendorsRow}>
              <View style={styles.vendorIconCircle}>
                <Ionicons name="people" size={24} color={colors.haven.champagne[500]} />
              </View>
              <View style={styles.vendorsContent}>
                <Text style={styles.vendorsTitle}>Vendor CRM</Text>
                <Text style={styles.vendorsSubtitle}>
                  Track service providers, log activities, and rate vendors
                </Text>
              </View>
              <Ionicons name="chevron-forward" size={20} color={colors.text.tertiary} />
            </View>
          </TouchableOpacity>
        </View>

        {/* Ask Alfred Card */}
        <TouchableOpacity
          style={styles.alfredCard}
          onPress={() => askAlfredForHelp('my property')}
        >
          <View style={styles.alfredIconContainer}>
            <AlfredTabIcon size={28} color={colors.haven.navy[900]} />
          </View>
          <View style={styles.alfredContent}>
            <Text style={styles.alfredTitle}>Ask Alfred</Text>
            <Text style={styles.alfredSubtitle}>
              {data.alfred?.pendingQuestions && data.alfred.pendingQuestions > 0
                ? `${data.alfred.pendingQuestions} question${data.alfred.pendingQuestions > 1 ? 's' : ''} to complete your home profile`
                : 'Your AI home manager is ready to help'}
            </Text>
          </View>
          <Ionicons name="chevron-forward" size={20} color={colors.haven.navy[400]} />
        </TouchableOpacity>
      </ScrollView>

      {/* Modals */}
      <AddZoneModal
        visible={showAddZoneModal}
        onClose={() => setShowAddZoneModal(false)}
        householdId={householdInfo?.id || ''}
        onSuccess={fetchProperty}
      />

      <AddAssetModal
        visible={showAddAssetModal}
        onClose={() => setShowAddAssetModal(false)}
        householdId={householdInfo?.id || ''}
        zones={data.zones.map(z => ({ id: z.id, name: z.name, type: z.type }))}
        onSuccess={fetchProperty}
      />
    </ScreenContainer>
  );
}

// =============================================================================
// STYLES
// =============================================================================

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.slate[50],
  },
  scrollView: {
    flex: 1,
    backgroundColor: colors.slate[50],
  },
  scrollContent: {
    paddingBottom: spacing[8],
  },
  errorContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing[6],
  },
  errorTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginTop: spacing[4],
  },
  errorText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    textAlign: 'center',
    marginTop: spacing[2],
  },
  retryButton: {
    marginTop: spacing[4],
    paddingHorizontal: spacing[6],
    paddingVertical: spacing[3],
    backgroundColor: colors.haven.champagne[500],
    borderRadius: borderRadius.lg,
  },
  retryText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },

  // Header
  header: {
    padding: spacing[4],
    paddingTop: spacing[2],
    backgroundColor: colors.white,
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  propertyName: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
  },
  propertyAddress: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: spacing[1],
  },
  propertyStats: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[2],
    marginTop: spacing[3],
  },
  statBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
    backgroundColor: colors.background.secondary,
    paddingHorizontal: spacing[2],
    paddingVertical: spacing[1],
    borderRadius: borderRadius.full,
  },
  statText: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
  },

  // Sections
  section: {
    marginTop: spacing[5],
    paddingHorizontal: spacing[4],
  },

  // Systems
  systemsScroll: {
    marginHorizontal: -spacing[4],
  },
  systemsContent: {
    paddingHorizontal: spacing[4],
    gap: spacing[3],
  },
  systemCard: {
    width: 120,
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[3],
    ...shadows.sm,
  },
  systemIcon: {
    width: 40,
    height: 40,
    borderRadius: borderRadius.lg,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[2],
  },
  systemName: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  systemStatus: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },

  // Zones Grid
  zonesGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[3],
  },
  zoneCard: {
    width: ZONE_CARD_WIDTH,
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[4],
    ...shadows.sm,
  },
  zoneIconContainer: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.lg,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[2],
  },
  zoneName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  zoneType: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  zoneFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: spacing[3],
    paddingTop: spacing[2],
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
  },
  assetCount: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
  },
  assetCountText: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  zoneFloor: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },

  // Empty State
  emptyCard: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing[5],
    gap: spacing[3],
    borderStyle: 'dashed',
    borderWidth: 1,
    borderColor: colors.border.light,
    borderRadius: borderRadius.xl,
    backgroundColor: colors.background.secondary,
  },
  emptyText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
  },

  // Assets
  assetsCard: {
    padding: spacing[3],
  },
  assetRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[3],
    gap: spacing[3],
  },
  assetBorder: {
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  assetInfo: {
    flex: 1,
  },
  assetName: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  assetLocation: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  assetBrand: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    marginRight: spacing[2],
  },
  viewAllButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[2],
    paddingTop: spacing[3],
    marginTop: spacing[2],
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
  },
  viewAllText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.champagne[500],
  },

  // Utilities
  utilitiesGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[3],
  },
  utilityCard: {
    width: (screenWidth - spacing[4] * 2 - spacing[3]) / 2,
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[4],
    alignItems: 'center',
    ...shadows.sm,
  },
  utilityLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: spacing[2],
  },
  utilityProvider: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
    marginTop: spacing[1],
    textAlign: 'center',
  },
  emptyUtilityCard: {
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing[6],
    borderStyle: 'dashed',
    borderWidth: 1,
    borderColor: colors.haven.champagne[300],
    borderRadius: borderRadius.xl,
    backgroundColor: colors.haven.champagne[50],
  },
  emptyUtilityText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
    marginTop: spacing[2],
  },
  emptyUtilitySubtext: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: spacing[1],
  },

  // Ask Alfred Card
  vendorsCard: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[4],
    borderWidth: 1,
    borderColor: colors.slate[200],
  },
  vendorsRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  vendorIconCircle: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  vendorsContent: {
    flex: 1,
    marginLeft: spacing[3],
  },
  vendorsTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  vendorsSubtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: 2,
  },
  alfredCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.haven.champagne[50],
    marginHorizontal: spacing[4],
    marginTop: spacing[5],
    marginBottom: spacing[4],
    padding: spacing[4],
    borderRadius: borderRadius.xl,
    borderWidth: 1,
    borderColor: colors.haven.champagne[200],
  },
  alfredIconContainer: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.champagne[100],
    alignItems: 'center',
    justifyContent: 'center',
  },
  alfredContent: {
    flex: 1,
    marginLeft: spacing[3],
  },
  alfredTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.navy[900],
  },
  alfredSubtitle: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    marginTop: spacing[1],
  },

  // Activity Feed
  activityList: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    overflow: 'hidden',
    ...shadows.sm,
  },
  activityItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    padding: spacing[3],
    gap: spacing[3],
  },
  activityItemBorder: {
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  activityEmoji: {
    width: 40,
    height: 40,
    borderRadius: borderRadius.md,
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
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  activityDescription: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    marginTop: 2,
  },
  activityTime: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: spacing[1],
  },
  activityEmpty: {
    padding: spacing[6],
    alignItems: 'center',
  },
  activityEmptyText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
  },
});
