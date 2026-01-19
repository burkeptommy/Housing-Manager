import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  FlatList,
  RefreshControl,
} from 'react-native';
import { useRouter, useFocusEffect } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../../src/contexts/auth-context';
import { Card, LoadingSpinner, ScreenContainer, Badge } from '../../../src/components';
import { FreeWalkthroughBanner } from '../../../src/components/FreeWalkthroughBanner';
import { colors, typography, spacing, borderRadius } from '../../../src/lib/theme';
import { API_BASE_URL } from '../../../src/lib/api';
import { getIdToken } from '../../../src/lib/firebase';

// =============================================================================
// TYPES
// =============================================================================

interface HomeProfile {
  id: string;
  street: string;
  city: string;
  state: string;
  zipCode: string;
  squareFeet?: number;
  yearBuilt?: number;
  bedrooms?: number;
  bathrooms?: number;
  lotSize?: number;
  propertyType?: string;
}

interface HomeSystem {
  id: string;
  name: string;
  type: string;
  brand?: string;
  model?: string;
  modelNumber?: string;
  serialNumber?: string;
  installedDate?: string;
  warrantyExpires?: string;
  condition?: string;
  location?: string;
  maintenanceResearch?: {
    expectedLifespan?: string;
    annualBudget?: number;
    efficiencyTips?: string[];
  };
}

interface Document {
  id: string;
  name: string;
  type: string;
  uploadedAt: string;
  systemId?: string;
}

interface MaintenanceHistory {
  id: string;
  title: string;
  completedAt: string;
  cost?: number;
  systemName?: string;
  vendorName?: string;
}

interface Utility {
  type: string;
  provider?: string;
  accountNumber?: string;
}

type TabType = 'overview' | 'systems' | 'docs' | 'history';

// =============================================================================
// SYSTEM ICONS
// =============================================================================

const getSystemIcon = (type: string): string => {
  const iconMap: Record<string, string> = {
    FURNACE: 'flame-outline',
    AIR_CONDITIONER: 'snow-outline',
    HEAT_PUMP: 'thermometer-outline',
    BOILER: 'water-outline',
    THERMOSTAT: 'thermometer-outline',
    MINI_SPLIT: 'thermometer-outline',
    OIL_TANK: 'water-outline',
    PROPANE_TANK: 'flame-outline',
    WATER_HEATER: 'water-outline',
    WATER_SOFTENER: 'water-outline',
    WELL_PUMP: 'water-outline',
    SUMP_PUMP: 'water-outline',
    WATER_FILTRATION: 'water-outline',
    SEPTIC_SYSTEM: 'water-outline',
    ELECTRICAL_PANEL: 'flash-outline',
    GENERATOR: 'flash-outline',
    SOLAR_PANELS: 'sunny-outline',
    EV_CHARGER: 'car-outline',
    REFRIGERATOR: 'cube-outline',
    DISHWASHER: 'water-outline',
    OVEN_RANGE: 'flame-outline',
    GARBAGE_DISPOSAL: 'trash-outline',
    ROOF: 'home-outline',
    GUTTERS: 'water-outline',
    CHIMNEY: 'flame-outline',
    DECK: 'grid-outline',
    FENCE: 'grid-outline',
    DRIVEWAY: 'car-outline',
    WINDOWS: 'apps-outline',
    GARAGE_DOOR: 'car-outline',
    WASHER: 'water-outline',
    DRYER: 'flame-outline',
    POOL: 'water-outline',
    HOT_TUB: 'water-outline',
  };
  return iconMap[type] || 'construct-outline';
};

const getConditionVariant = (condition?: string): 'success' | 'warning' | 'error' | 'default' => {
  switch (condition?.toUpperCase()) {
    case 'EXCELLENT':
    case 'GOOD':
      return 'success';
    case 'FAIR':
      return 'warning';
    case 'POOR':
    case 'CRITICAL':
      return 'error';
    default:
      return 'default';
  }
};

// =============================================================================
// HOME MANUAL SCREEN
// =============================================================================

export default function HomeManualScreen() {
  const router = useRouter();
  const { householdInfo, userProfile } = useAuth();
  const [tab, setTab] = useState<TabType>('overview');
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [homeProfile, setHomeProfile] = useState<HomeProfile | null>(null);
  const [systems, setSystems] = useState<HomeSystem[]>([]);
  const [documents, setDocuments] = useState<Document[]>([]);
  const [history, setHistory] = useState<MaintenanceHistory[]>([]);
  const [utilities, setUtilities] = useState<Utility[]>([]);
  const [bills, setBills] = useState<any[]>([]);
  const [vendors, setVendors] = useState<any[]>([]);

  // =============================================================================
  // DATA FETCHING
  // =============================================================================

  const fetchData = useCallback(async () => {
    if (!householdInfo?.id) {
      setIsLoading(false);
      return;
    }

    try {
      const token = await getIdToken(true);
      if (!token) {
        setIsLoading(false);
        return;
      }

      const headers = {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      };

      // Fetch all data in parallel
      const [homeRes, systemsRes, billsRes, vendorsRes] = await Promise.all([
        fetch(`${API_BASE_URL}/home/${householdInfo.id}`, { headers }),
        fetch(`${API_BASE_URL}/home/${householdInfo.id}/systems`, { headers }),
        fetch(`${API_BASE_URL}/bills/household/${householdInfo.id}`, { headers }),
        fetch(`${API_BASE_URL}/households/${householdInfo.id}/vendors`, { headers }),
      ]);

      if (homeRes.ok) {
        const homeData = await homeRes.json();
        setHomeProfile(homeData.homeProfile);
        setUtilities(homeData.utilities || []);
        setDocuments(homeData.documents || []);
        setHistory(homeData.maintenanceHistory || []);
      }

      if (systemsRes.ok) {
        const systemsData = await systemsRes.json();
        setSystems(systemsData);
      }

      if (billsRes.ok) {
        const billsData = await billsRes.json();
        setBills(billsData);
      }

      if (vendorsRes.ok) {
        const vendorsData = await vendorsRes.json();
        setVendors(vendorsData);
      }
    } catch (err) {
      console.error('Error fetching home manual data:', err);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [householdInfo?.id]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  useFocusEffect(
    useCallback(() => {
      if (!isLoading) {
        fetchData();
      }
    }, [fetchData, isLoading])
  );

  const handleRefresh = () => {
    setIsRefreshing(true);
    fetchData();
  };

  // =============================================================================
  // TAB: OVERVIEW
  // =============================================================================

  const renderOverviewTab = () => (
    <ScrollView
      refreshControl={
        <RefreshControl refreshing={isRefreshing} onRefresh={handleRefresh} />
      }
    >
      {/* Property Header */}
      <View style={styles.propertyHeader}>
        <View style={styles.propertyIcon}>
          <Ionicons name="home" size={32} color={colors.haven.champagne[500]} />
        </View>
        <Text style={styles.propertyAddress}>
          {homeProfile?.street || 'Your Home'}
        </Text>
        <Text style={styles.propertyCityState}>
          {homeProfile ? `${homeProfile.city}, ${homeProfile.state} ${homeProfile.zipCode}` : ''}
        </Text>
      </View>

      {/* Free Walkthrough Banner */}
      {householdInfo?.id && (
        <FreeWalkthroughBanner
          householdId={householdInfo.id}
          systemCount={systems.length}
          vendorCount={vendors.length}
          billCount={bills.length}
          zipCode={homeProfile?.zipCode}
          createdAt={userProfile?.createdAt || new Date().toISOString()}
          compact
        />
      )}

      {/* Property Details */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Property Details</Text>
        <Card style={styles.detailsCard}>
          <DetailRow label="Year Built" value={homeProfile?.yearBuilt?.toString()} />
          <DetailRow label="Square Feet" value={homeProfile?.squareFeet?.toLocaleString()} />
          <DetailRow label="Lot Size" value={homeProfile?.lotSize ? `${homeProfile.lotSize} acres` : undefined} />
          <DetailRow label="Bedrooms" value={homeProfile?.bedrooms?.toString()} />
          <DetailRow label="Bathrooms" value={homeProfile?.bathrooms?.toString()} />
          <DetailRow label="Property Type" value={homeProfile?.propertyType} />
        </Card>
      </View>

      {/* Utilities Summary */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Utilities</Text>
        <Card style={styles.detailsCard}>
          <UtilityRow icon="flash-outline" label="Electric" value={utilities.find(u => u.type === 'ELECTRICITY')?.provider} />
          <UtilityRow icon="flame-outline" label="Gas" value={utilities.find(u => u.type === 'GAS')?.provider} />
          <UtilityRow icon="water-outline" label="Water" value={utilities.find(u => u.type === 'WATER')?.provider} />
          <UtilityRow icon="wifi-outline" label="Internet" value={utilities.find(u => u.type === 'INTERNET')?.provider} />
        </Card>
      </View>

      {/* Systems Summary */}
      <View style={styles.section}>
        <View style={styles.sectionHeaderRow}>
          <Text style={styles.sectionTitle}>Major Systems</Text>
          <TouchableOpacity onPress={() => setTab('systems')}>
            <Text style={styles.sectionAction}>View All</Text>
          </TouchableOpacity>
        </View>
        {systems.length > 0 ? (
          <ScrollView horizontal showsHorizontalScrollIndicator={false}>
            <View style={styles.systemsRow}>
              {systems.slice(0, 4).map(system => (
                <TouchableOpacity
                  key={system.id}
                  style={styles.systemCard}
                  onPress={() => router.push(`/(tabs)/home/system/${system.id}` as any)}
                >
                  <View style={styles.systemCardIcon}>
                    <Ionicons
                      name={getSystemIcon(system.type) as any}
                      size={24}
                      color={colors.haven.champagne[500]}
                    />
                  </View>
                  <Text style={styles.systemCardName} numberOfLines={1}>{system.name}</Text>
                  {system.brand && (
                    <Text style={styles.systemCardBrand} numberOfLines={1}>{system.brand}</Text>
                  )}
                </TouchableOpacity>
              ))}
            </View>
          </ScrollView>
        ) : (
          <EmptySystemsCard onAddPress={() => router.push('/(tabs)/home' as any)} />
        )}
      </View>

      {/* Important Dates */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Important Dates</Text>
        <Card style={styles.detailsCard}>
          <DateRow
            label="Roof Installed"
            value={systems.find(s => s.type === 'ROOF')?.installedDate}
          />
          <DateRow
            label="HVAC Installed"
            value={systems.find(s => ['FURNACE', 'AIR_CONDITIONER', 'HEAT_PUMP'].includes(s.type))?.installedDate}
          />
          <DateRow
            label="Water Heater"
            value={systems.find(s => s.type === 'WATER_HEATER')?.installedDate}
          />
        </Card>
      </View>
    </ScrollView>
  );

  // =============================================================================
  // TAB: SYSTEMS
  // =============================================================================

  const renderSystemsTab = () => (
    <FlatList
      data={systems}
      keyExtractor={item => item.id}
      refreshControl={
        <RefreshControl refreshing={isRefreshing} onRefresh={handleRefresh} />
      }
      contentContainerStyle={styles.listContent}
      ListHeaderComponent={
        <View style={styles.systemsHeader}>
          <Text style={styles.systemsCount}>{systems.length} systems tracked</Text>
          <TouchableOpacity onPress={() => router.push('/(tabs)/home' as any)}>
            <Text style={styles.addSystemText}>+ Add System</Text>
          </TouchableOpacity>
        </View>
      }
      ListEmptyComponent={
        <EmptySystemsWithWalkthroughCTA
          householdId={householdInfo?.id}
          zipCode={homeProfile?.zipCode}
          createdAt={userProfile?.createdAt}
          systemCount={systems.length}
          vendorCount={vendors.length}
          billCount={bills.length}
        />
      }
      renderItem={({ item }) => (
        <TouchableOpacity
          onPress={() => router.push(`/(tabs)/home/system/${item.id}` as any)}
        >
          <Card style={styles.systemListCard}>
            <View style={styles.systemListHeader}>
              <View style={styles.systemListIcon}>
                <Ionicons
                  name={getSystemIcon(item.type) as any}
                  size={24}
                  color={colors.haven.champagne[500]}
                />
              </View>
              <View style={styles.systemListInfo}>
                <Text style={styles.systemListName}>{item.name}</Text>
                <Text style={styles.systemListType}>
                  {item.type.replace(/_/g, ' ')}
                </Text>
                {item.brand && (
                  <Text style={styles.systemListBrand}>
                    {item.brand} {item.model || ''}
                  </Text>
                )}
              </View>
              {item.condition && (
                <Badge
                  label={item.condition}
                  variant={getConditionVariant(item.condition)}
                  size="sm"
                />
              )}
            </View>
            {item.installedDate && (
              <Text style={styles.systemListInstalled}>
                Installed: {new Date(item.installedDate).toLocaleDateString()}
              </Text>
            )}
          </Card>
        </TouchableOpacity>
      )}
    />
  );

  // =============================================================================
  // TAB: DOCUMENTS
  // =============================================================================

  const renderDocumentsTab = () => (
    <FlatList
      data={documents}
      keyExtractor={item => item.id}
      refreshControl={
        <RefreshControl refreshing={isRefreshing} onRefresh={handleRefresh} />
      }
      contentContainerStyle={styles.listContent}
      ListEmptyComponent={
        <View style={styles.emptyContainer}>
          <Ionicons name="document-outline" size={48} color={colors.haven.navy[300]} />
          <Text style={styles.emptyTitle}>No Documents Yet</Text>
          <Text style={styles.emptyText}>
            Upload manuals, warranties, and receipts to keep everything organized
          </Text>
          <TouchableOpacity
            style={styles.emptyButton}
            onPress={() => router.push('/(tabs)/settings/vault' as any)}
          >
            <Ionicons name="cloud-upload-outline" size={20} color={colors.white} />
            <Text style={styles.emptyButtonText}>Upload Document</Text>
          </TouchableOpacity>
        </View>
      }
      renderItem={({ item }) => (
        <Card style={styles.documentCard}>
          <View style={styles.documentIcon}>
            <Ionicons
              name={item.type === 'PDF' ? 'document-text-outline' : 'image-outline'}
              size={24}
              color={colors.haven.champagne[500]}
            />
          </View>
          <View style={styles.documentInfo}>
            <Text style={styles.documentName}>{item.name}</Text>
            <Text style={styles.documentDate}>
              Uploaded {new Date(item.uploadedAt).toLocaleDateString()}
            </Text>
          </View>
          <Ionicons name="chevron-forward" size={20} color={colors.text.tertiary} />
        </Card>
      )}
    />
  );

  // =============================================================================
  // TAB: HISTORY
  // =============================================================================

  const renderHistoryTab = () => (
    <FlatList
      data={history}
      keyExtractor={item => item.id}
      refreshControl={
        <RefreshControl refreshing={isRefreshing} onRefresh={handleRefresh} />
      }
      contentContainerStyle={styles.listContent}
      ListEmptyComponent={
        <View style={styles.emptyContainer}>
          <Ionicons name="time-outline" size={48} color={colors.haven.navy[300]} />
          <Text style={styles.emptyTitle}>No Maintenance History</Text>
          <Text style={styles.emptyText}>
            Completed maintenance tasks will appear here for your records
          </Text>
        </View>
      }
      renderItem={({ item }) => (
        <Card style={styles.historyCard}>
          <View style={styles.historyHeader}>
            <View style={styles.historyInfo}>
              <Text style={styles.historyTitle}>{item.title}</Text>
              <Text style={styles.historyMeta}>
                {item.systemName && `${item.systemName} • `}
                {new Date(item.completedAt).toLocaleDateString()}
              </Text>
              {item.vendorName && (
                <Text style={styles.historyVendor}>by {item.vendorName}</Text>
              )}
            </View>
            {item.cost && (
              <Text style={styles.historyCost}>
                ${item.cost.toLocaleString()}
              </Text>
            )}
          </View>
        </Card>
      )}
    />
  );

  // =============================================================================
  // RENDER
  // =============================================================================

  if (isLoading) {
    return (
      <ScreenContainer title="Home Manual" onBackPress={() => router.back()}>
        <View style={styles.loadingContainer}>
          <LoadingSpinner message="Loading..." />
        </View>
      </ScreenContainer>
    );
  }

  return (
    <ScreenContainer title="Home Manual" onBackPress={() => router.back()} scrollable={false}>
      {/* Tab Bar */}
      <View style={styles.tabBar}>
        <TabButton label="Overview" active={tab === 'overview'} onPress={() => setTab('overview')} />
        <TabButton label="Systems" active={tab === 'systems'} onPress={() => setTab('systems')} />
        <TabButton label="Docs" active={tab === 'docs'} onPress={() => setTab('docs')} />
        <TabButton label="History" active={tab === 'history'} onPress={() => setTab('history')} />
      </View>

      {/* Tab Content */}
      <View style={styles.tabContent}>
        {tab === 'overview' && renderOverviewTab()}
        {tab === 'systems' && renderSystemsTab()}
        {tab === 'docs' && renderDocumentsTab()}
        {tab === 'history' && renderHistoryTab()}
      </View>
    </ScreenContainer>
  );
}

// =============================================================================
// HELPER COMPONENTS
// =============================================================================

function TabButton({ label, active, onPress }: { label: string; active: boolean; onPress: () => void }) {
  return (
    <TouchableOpacity
      style={[styles.tabButton, active && styles.tabButtonActive]}
      onPress={onPress}
    >
      <Text style={[styles.tabButtonText, active && styles.tabButtonTextActive]}>
        {label}
      </Text>
    </TouchableOpacity>
  );
}

function DetailRow({ label, value }: { label: string; value?: string }) {
  return (
    <View style={styles.detailRow}>
      <Text style={styles.detailLabel}>{label}</Text>
      <Text style={styles.detailValue}>{value || '—'}</Text>
    </View>
  );
}

function UtilityRow({ icon, label, value }: { icon: string; label: string; value?: string }) {
  return (
    <View style={styles.utilityRow}>
      <Ionicons name={icon as any} size={20} color={colors.haven.champagne[500]} />
      <Text style={styles.utilityLabel}>{label}</Text>
      <Text style={styles.utilityValue}>{value || 'Not set'}</Text>
    </View>
  );
}

function DateRow({ label, value }: { label: string; value?: string }) {
  return (
    <View style={styles.detailRow}>
      <Text style={styles.detailLabel}>{label}</Text>
      <Text style={styles.detailValue}>
        {value ? new Date(value).toLocaleDateString() : '—'}
      </Text>
    </View>
  );
}

function EmptySystemsCard({ onAddPress }: { onAddPress: () => void }) {
  return (
    <Card style={styles.emptySystemsCard}>
      <Ionicons name="construct-outline" size={32} color={colors.haven.navy[300]} />
      <Text style={styles.emptySystemsText}>No systems added yet</Text>
      <TouchableOpacity style={styles.emptySystemsButton} onPress={onAddPress}>
        <Text style={styles.emptySystemsButtonText}>Add Your First System</Text>
      </TouchableOpacity>
    </Card>
  );
}

function EmptySystemsWithWalkthroughCTA({
  householdId,
  zipCode,
  createdAt,
  systemCount,
  vendorCount,
  billCount,
}: {
  householdId?: string;
  zipCode?: string;
  createdAt?: string;
  systemCount: number;
  vendorCount: number;
  billCount: number;
}) {
  return (
    <View style={styles.emptyContainer}>
      <Ionicons name="construct-outline" size={48} color={colors.haven.navy[300]} />
      <Text style={styles.emptyTitle}>No Systems Added Yet</Text>
      <Text style={styles.emptyText}>
        Track your home systems to get maintenance reminders and keep everything organized
      </Text>

      {householdId && (
        <FreeWalkthroughBanner
          householdId={householdId}
          systemCount={systemCount}
          vendorCount={vendorCount}
          billCount={billCount}
          zipCode={zipCode}
          createdAt={createdAt || new Date().toISOString()}
        />
      )}
    </View>
  );
}

// =============================================================================
// STYLES
// =============================================================================

const styles = StyleSheet.create({
  loadingContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  tabBar: {
    flexDirection: 'row',
    backgroundColor: colors.white,
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  tabButton: {
    flex: 1,
    paddingVertical: spacing[3],
    alignItems: 'center',
    borderBottomWidth: 2,
    borderBottomColor: 'transparent',
  },
  tabButtonActive: {
    borderBottomColor: colors.haven.champagne[500],
  },
  tabButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
  },
  tabButtonTextActive: {
    color: colors.haven.champagne[600],
  },
  tabContent: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  propertyHeader: {
    alignItems: 'center',
    padding: spacing[6],
    backgroundColor: colors.white,
  },
  propertyIcon: {
    width: 64,
    height: 64,
    borderRadius: 32,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[3],
  },
  propertyAddress: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
  },
  propertyCityState: {
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
    marginTop: spacing[1],
  },
  section: {
    padding: spacing[4],
  },
  sectionHeaderRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[3],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginBottom: spacing[3],
  },
  sectionAction: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[600],
    fontWeight: typography.fontWeights.medium,
  },
  detailsCard: {
    padding: spacing[4],
  },
  detailRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: spacing[2],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  detailLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  detailValue: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  utilityRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
    gap: spacing[3],
  },
  utilityLabel: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.text.primary,
  },
  utilityValue: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  systemsRow: {
    flexDirection: 'row',
    gap: spacing[3],
    paddingRight: spacing[4],
  },
  systemCard: {
    width: 120,
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing[3],
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  systemCardIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[2],
  },
  systemCardName: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
    textAlign: 'center',
  },
  systemCardBrand: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: spacing[1],
  },
  emptySystemsCard: {
    alignItems: 'center',
    padding: spacing[6],
  },
  emptySystemsText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: spacing[3],
    marginBottom: spacing[4],
  },
  emptySystemsButton: {
    backgroundColor: colors.haven.champagne[500],
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[4],
    borderRadius: borderRadius.md,
  },
  emptySystemsButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.white,
  },
  listContent: {
    padding: spacing[4],
  },
  systemsHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[3],
  },
  systemsCount: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  addSystemText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[600],
    fontWeight: typography.fontWeights.medium,
  },
  systemListCard: {
    padding: spacing[4],
    marginBottom: spacing[3],
  },
  systemListHeader: {
    flexDirection: 'row',
    alignItems: 'flex-start',
  },
  systemListIcon: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  systemListInfo: {
    flex: 1,
    marginLeft: spacing[3],
  },
  systemListName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  systemListType: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    textTransform: 'capitalize',
  },
  systemListBrand: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: spacing[0.5],
  },
  systemListInstalled: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: spacing[3],
  },
  documentCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[4],
    marginBottom: spacing[3],
  },
  documentIcon: {
    width: 40,
    height: 40,
    borderRadius: borderRadius.md,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  documentInfo: {
    flex: 1,
    marginLeft: spacing[3],
  },
  documentName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  documentDate: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
  },
  historyCard: {
    padding: spacing[4],
    marginBottom: spacing[3],
  },
  historyHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  historyInfo: {
    flex: 1,
  },
  historyTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  historyMeta: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: spacing[1],
  },
  historyVendor: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
    marginTop: spacing[0.5],
  },
  historyCost: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  emptyContainer: {
    alignItems: 'center',
    paddingVertical: spacing[10],
    paddingHorizontal: spacing[6],
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
    textAlign: 'center',
    marginTop: spacing[2],
    lineHeight: 20,
  },
  emptyButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.haven.champagne[500],
    paddingVertical: spacing[3],
    paddingHorizontal: spacing[5],
    borderRadius: borderRadius.lg,
    marginTop: spacing[4],
    gap: spacing[2],
  },
  emptyButtonText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
});
