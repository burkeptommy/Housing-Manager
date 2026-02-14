import React, { useEffect, useState, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Alert,
} from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../../../src/contexts/auth-context';
import { AnimatedCard, Badge, ScreenContainer } from '../../../../src/components';
import { Skeleton } from '../../../../src/components/ui/Skeleton';
import { colors, typography, spacing, borderRadius, shadows } from '../../../../src/lib/theme';
import { API_BASE_URL } from '../../../../src/lib/api';
import { getIdToken } from '../../../../src/lib/firebase';
import { AddAssetModal } from '../../../../src/components/forms/AddAssetModal';

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

interface ZoneData {
  id: string;
  name: string;
  type: ZoneType;
  floor: string | null;
  photos: string[];
  notes: string | null;
  procedures: string | null;
  assets: Asset[];
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
  KITCHEN: colors.haven.purple[500],
  LIVING_ROOM: colors.haven.purple[500],
  DINING_ROOM: colors.haven.purple[600],
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

const CATEGORY_ICONS: Record<AssetCategory, keyof typeof Ionicons.glyphMap> = {
  APPLIANCE: 'cube-outline',
  HVAC: 'thermometer-outline',
  PLUMBING: 'water-outline',
  ELECTRICAL: 'flash-outline',
  STRUCTURAL: 'construct-outline',
  FURNITURE: 'bed-outline',
  ELECTRONICS: 'tv-outline',
  OUTDOOR: 'leaf-outline',
  VEHICLE: 'car-outline',
  SAFETY: 'shield-checkmark-outline',
  OTHER: 'ellipsis-horizontal',
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

function getCategoryLabel(category: AssetCategory): string {
  const labels: Record<AssetCategory, string> = {
    APPLIANCE: 'Appliance',
    HVAC: 'HVAC',
    PLUMBING: 'Plumbing',
    ELECTRICAL: 'Electrical',
    STRUCTURAL: 'Structural',
    FURNITURE: 'Furniture',
    ELECTRONICS: 'Electronics',
    OUTDOOR: 'Outdoor',
    VEHICLE: 'Vehicle',
    SAFETY: 'Safety',
    OTHER: 'Other',
  };
  return labels[category] || category;
}

function getConditionColor(condition: string | null): string {
  switch (condition) {
    case 'Excellent': return colors.status.success;
    case 'Good': return colors.haven.purple[500];
    case 'Fair': return colors.status.warning;
    case 'Needs Service': return colors.status.error;
    default: return colors.gray[400];
  }
}

// Suggested items by zone type
interface SuggestedItem {
  name: string;
  category: AssetCategory;
  icon: keyof typeof Ionicons.glyphMap;
}

const ZONE_SUGGESTIONS: Partial<Record<ZoneType, SuggestedItem[]>> = {
  KITCHEN: [
    { name: 'Refrigerator', category: 'APPLIANCE', icon: 'snow-outline' },
    { name: 'Dishwasher', category: 'APPLIANCE', icon: 'water-outline' },
    { name: 'Range/Oven', category: 'APPLIANCE', icon: 'flame-outline' },
    { name: 'Microwave', category: 'APPLIANCE', icon: 'radio-outline' },
    { name: 'Garbage Disposal', category: 'PLUMBING', icon: 'trash-outline' },
    { name: 'Range Hood', category: 'APPLIANCE', icon: 'cloud-outline' },
  ],
  LAUNDRY: [
    { name: 'Washer', category: 'APPLIANCE', icon: 'water-outline' },
    { name: 'Dryer', category: 'APPLIANCE', icon: 'sunny-outline' },
    { name: 'Water Heater', category: 'PLUMBING', icon: 'flame-outline' },
  ],
  GARAGE: [
    { name: 'Garage Door Opener', category: 'ELECTRICAL', icon: 'car-outline' },
    { name: 'EV Charger', category: 'ELECTRICAL', icon: 'flash-outline' },
    { name: 'Sump Pump', category: 'PLUMBING', icon: 'water-outline' },
  ],
  BASEMENT: [
    { name: 'Sump Pump', category: 'PLUMBING', icon: 'water-outline' },
    { name: 'Water Heater', category: 'PLUMBING', icon: 'flame-outline' },
    { name: 'Dehumidifier', category: 'APPLIANCE', icon: 'water-outline' },
    { name: 'Furnace', category: 'HVAC', icon: 'flame-outline' },
  ],
  MECHANICAL: [
    { name: 'Furnace', category: 'HVAC', icon: 'flame-outline' },
    { name: 'AC Condenser', category: 'HVAC', icon: 'snow-outline' },
    { name: 'Water Heater', category: 'PLUMBING', icon: 'flame-outline' },
    { name: 'Water Softener', category: 'PLUMBING', icon: 'water-outline' },
    { name: 'Electrical Panel', category: 'ELECTRICAL', icon: 'flash-outline' },
  ],
  LIVING_ROOM: [
    { name: 'Fireplace', category: 'HVAC', icon: 'flame-outline' },
    { name: 'Smart TV', category: 'ELECTRONICS', icon: 'tv-outline' },
    { name: 'Ceiling Fan', category: 'ELECTRICAL', icon: 'sync-outline' },
  ],
  BATHROOM: [
    { name: 'Toilet', category: 'PLUMBING', icon: 'water-outline' },
    { name: 'Shower/Tub', category: 'PLUMBING', icon: 'water-outline' },
    { name: 'Exhaust Fan', category: 'ELECTRICAL', icon: 'cloud-outline' },
  ],
  OUTDOOR_BACK: [
    { name: 'Grill', category: 'OUTDOOR', icon: 'flame-outline' },
    { name: 'Pool Equipment', category: 'OUTDOOR', icon: 'water-outline' },
    { name: 'Irrigation System', category: 'OUTDOOR', icon: 'leaf-outline' },
    { name: 'Deck/Patio', category: 'STRUCTURAL', icon: 'grid-outline' },
  ],
  POOL_AREA: [
    { name: 'Pool Pump', category: 'OUTDOOR', icon: 'water-outline' },
    { name: 'Pool Heater', category: 'OUTDOOR', icon: 'flame-outline' },
    { name: 'Pool Filter', category: 'OUTDOOR', icon: 'funnel-outline' },
    { name: 'Hot Tub', category: 'OUTDOOR', icon: 'thermometer-outline' },
  ],
};

// =============================================================================
// COMPONENT
// =============================================================================

export default function ZoneDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { householdInfo } = useAuth();
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [data, setData] = useState<ZoneData | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [showAddAssetModal, setShowAddAssetModal] = useState(false);
  const [prefillAsset, setPrefillAsset] = useState<{ name: string; category: AssetCategory } | null>(null);

  // Get suggested items that haven't been added yet
  const getSuggestedItems = useCallback(() => {
    if (!data) return [];
    const suggestions = ZONE_SUGGESTIONS[data.type] || [];
    const existingNames = data.assets.map(a => a.name.toLowerCase());
    return suggestions.filter(s => !existingNames.includes(s.name.toLowerCase()));
  }, [data]);

  const handleSuggestionPress = (suggestion: SuggestedItem) => {
    setPrefillAsset({ name: suggestion.name, category: suggestion.category });
    setShowAddAssetModal(true);
  };

  const fetchZone = useCallback(async () => {
    if (!id) {
      setIsLoading(false);
      setError('No zone ID provided');
      return;
    }

    try {
      const token = await getIdToken(true);
      if (!token) {
        setError('Authentication expired. Please sign in again.');
        setIsLoading(false);
        return;
      }

      const response = await fetch(`${API_BASE_URL}/property/zones/${id}`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (!response.ok) {
        throw new Error(`Failed to fetch zone: ${response.status}`);
      }

      const zoneData = await response.json();
      setData(zoneData);
      setError(null);
    } catch (err) {
      console.error('Zone fetch error:', err);
      setError('Failed to load zone. Please try again.');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [id]);

  useEffect(() => {
    fetchZone();
  }, [fetchZone]);

  const onRefresh = () => {
    setIsRefreshing(true);
    fetchZone();
  };

  const handleDeleteZone = async () => {
    Alert.alert(
      'Delete Zone',
      'Are you sure you want to delete this zone? All items in this zone will be unassigned.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            try {
              const token = await getIdToken(true);
              if (!token) return;

              const response = await fetch(`${API_BASE_URL}/property/zones/${id}`, {
                method: 'DELETE',
                headers: { Authorization: `Bearer ${token}` },
              });

              if (response.ok) {
                router.back();
              }
            } catch (err) {
              console.error('Delete zone error:', err);
            }
          },
        },
      ]
    );
  };

  if (isLoading) {
    return (
      <SafeAreaView style={styles.container} edges={['top']}>
        <View style={styles.loadingContainer}>
          <Skeleton width="100%" height={120} borderRadius={16} />
          <Skeleton width="100%" height={200} borderRadius={16} style={{ marginTop: 16 }} />
        </View>
      </SafeAreaView>
    );
  }

  if (error || !data) {
    return (
      <SafeAreaView style={styles.container} edges={['top']}>
        <View style={styles.errorContainer}>
          <Ionicons name="alert-circle" size={48} color={colors.status.error} />
          <Text style={styles.errorTitle}>Unable to Load Zone</Text>
          <Text style={styles.errorText}>{error}</Text>
          <TouchableOpacity style={styles.retryButton} onPress={fetchZone}>
            <Text style={styles.retryText}>Try Again</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  const zoneColor = ZONE_COLORS[data.type];

  return (
    <ScreenContainer
      title={data.name || 'Zone'}
      showBack
      onBackPress={() => router.back()}
      refreshing={isRefreshing}
      onRefresh={onRefresh}
      contentStyle={styles.scrollContent}
    >
        {/* Zone Header */}
        <View style={[styles.header, { backgroundColor: zoneColor + '20' }]}>
          <View style={[styles.zoneIcon, { backgroundColor: zoneColor + '30' }]}>
            <Ionicons name={ZONE_ICONS[data.type]} size={40} color={zoneColor} />
          </View>
          <Text style={styles.zoneName}>{data.name}</Text>
          <Text style={styles.zoneType}>{getZoneDisplayName(data.type)}</Text>
          {data.floor && (
            <Badge label={data.floor} variant="info" />
          )}
        </View>

        {/* Quick Stats */}
        <View style={styles.statsRow}>
          <View style={styles.stat}>
            <Text style={styles.statValue}>{data.assets.length}</Text>
            <Text style={styles.statLabel}>Items</Text>
          </View>
          <View style={styles.statDivider} />
          <View style={styles.stat}>
            <Text style={styles.statValue}>
              {data.assets.filter(a => a.condition === 'Excellent' || a.condition === 'Good').length}
            </Text>
            <Text style={styles.statLabel}>Good Condition</Text>
          </View>
          <View style={styles.statDivider} />
          <View style={styles.stat}>
            <Text style={styles.statValue}>
              {data.assets.filter(a => a.condition === 'Needs Service').length}
            </Text>
            <Text style={styles.statLabel}>Need Service</Text>
          </View>
        </View>

        {/* Notes Section */}
        {(data.notes || data.procedures) && (
          <AnimatedCard style={styles.notesCard}>
            {data.notes && (
              <View style={styles.notesSection}>
                <Text style={styles.notesLabel}>Notes</Text>
                <Text style={styles.notesText}>{data.notes}</Text>
              </View>
            )}
            {data.procedures && (
              <View style={[styles.notesSection, data.notes && styles.notesDivider]}>
                <Text style={styles.notesLabel}>Care Instructions</Text>
                <Text style={styles.notesText}>{data.procedures}</Text>
              </View>
            )}
          </AnimatedCard>
        )}

        {/* Assets in Zone */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Items in {data.name}</Text>
            <TouchableOpacity
              style={styles.addButton}
              onPress={() => setShowAddAssetModal(true)}
            >
              <Ionicons name="add" size={20} color={colors.haven.purple[500]} />
              <Text style={styles.addButtonText}>Add</Text>
            </TouchableOpacity>
          </View>

          {data.assets.length === 0 ? (
            <TouchableOpacity
              style={styles.emptyCard}
              onPress={() => setShowAddAssetModal(true)}
            >
              <Ionicons name="add-circle-outline" size={24} color={colors.text.tertiary} />
              <Text style={styles.emptyText}>Add your first item to {data.name}</Text>
            </TouchableOpacity>
          ) : (
            <AnimatedCard style={styles.assetsCard}>
              {data.assets.map((asset, index) => (
                <TouchableOpacity
                  key={asset.id}
                  style={[
                    styles.assetRow,
                    index < data.assets.length - 1 && styles.assetBorder,
                  ]}
                  onPress={() => router.push(`/(tabs)/home/asset/${asset.id}`)}
                >
                  <View style={styles.assetIconContainer}>
                    <Ionicons
                      name={CATEGORY_ICONS[asset.category]}
                      size={20}
                      color={colors.text.secondary}
                    />
                  </View>
                  <View style={styles.assetInfo}>
                    <Text style={styles.assetName}>{asset.name}</Text>
                    <View style={styles.assetMeta}>
                      <Text style={styles.assetCategory}>{getCategoryLabel(asset.category)}</Text>
                      {asset.brand && (
                        <>
                          <Text style={styles.assetDot}>•</Text>
                          <Text style={styles.assetBrand}>{asset.brand}</Text>
                        </>
                      )}
                    </View>
                  </View>
                  {asset.condition && (
                    <View style={[styles.conditionDot, { backgroundColor: getConditionColor(asset.condition) }]} />
                  )}
                  <Ionicons name="chevron-forward" size={16} color={colors.text.tertiary} />
                </TouchableOpacity>
              ))}
            </AnimatedCard>
          )}
        </View>

        {/* Suggested Items Section */}
        {getSuggestedItems().length > 0 && (
          <View style={styles.section}>
            <View style={styles.sectionHeader}>
              <Text style={styles.sectionTitle}>Commonly Tracked</Text>
            </View>
            <View style={styles.suggestionsContainer}>
              {getSuggestedItems().slice(0, 6).map((suggestion, index) => (
                <TouchableOpacity
                  key={`${suggestion.name}-${index}`}
                  style={styles.suggestionChip}
                  onPress={() => handleSuggestionPress(suggestion)}
                >
                  <Ionicons name={suggestion.icon} size={16} color={colors.haven.purple[500]} />
                  <Text style={styles.suggestionText}>{suggestion.name}</Text>
                  <Ionicons name="add" size={14} color={colors.haven.purple[500]} />
                </TouchableOpacity>
              ))}
            </View>
          </View>
        )}

        {/* Actions */}
        <View style={styles.actions}>
          <TouchableOpacity style={styles.deleteButton} onPress={handleDeleteZone}>
            <Ionicons name="trash-outline" size={18} color={colors.status.error} />
            <Text style={styles.deleteButtonText}>Delete Zone</Text>
          </TouchableOpacity>
        </View>

      {/* Add Asset Modal */}
      <AddAssetModal
        visible={showAddAssetModal}
        onClose={() => {
          setShowAddAssetModal(false);
          setPrefillAsset(null);
        }}
        householdId={householdInfo?.id || ''}
        zones={[{ id: data.id, name: data.name, type: data.type }]}
        defaultZoneId={data.id}
        defaultName={prefillAsset?.name}
        defaultCategory={prefillAsset?.category}
        onSuccess={fetchZone}
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
  scrollContent: {
    paddingBottom: spacing[8],
  },
  loadingContainer: {
    padding: spacing[4],
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
    backgroundColor: colors.haven.purple[500],
    borderRadius: borderRadius.lg,
  },
  retryText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },

  // Header
  header: {
    alignItems: 'center',
    paddingVertical: spacing[6],
    paddingHorizontal: spacing[4],
  },
  zoneIcon: {
    width: 80,
    height: 80,
    borderRadius: borderRadius['2xl'],
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[3],
  },
  zoneName: {
    fontSize: typography.fontSizes['2xl'],
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
    marginBottom: spacing[1],
  },
  zoneType: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginBottom: spacing[2],
  },

  // Stats
  statsRow: {
    flexDirection: 'row',
    backgroundColor: colors.white,
    marginHorizontal: spacing[4],
    marginTop: -spacing[4],
    padding: spacing[4],
    borderRadius: borderRadius.xl,
    ...shadows.sm,
  },
  stat: {
    flex: 1,
    alignItems: 'center',
  },
  statValue: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
  },
  statLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  statDivider: {
    width: 1,
    backgroundColor: colors.border.light,
    marginVertical: spacing[2],
  },

  // Notes
  notesCard: {
    marginHorizontal: spacing[4],
    marginTop: spacing[4],
    padding: spacing[4],
  },
  notesSection: {},
  notesDivider: {
    marginTop: spacing[3],
    paddingTop: spacing[3],
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
  },
  notesLabel: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginBottom: spacing[1],
  },
  notesText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    lineHeight: 20,
  },

  // Section
  section: {
    marginTop: spacing[5],
    paddingHorizontal: spacing[4],
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[3],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  addButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
  },
  addButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.purple[500],
  },

  // Empty
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
  assetIconContainer: {
    width: 40,
    height: 40,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.background.secondary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  assetInfo: {
    flex: 1,
  },
  assetName: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  assetMeta: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 2,
  },
  assetCategory: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  assetDot: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginHorizontal: spacing[1],
  },
  assetBrand: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  conditionDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginRight: spacing[2],
  },

  // Actions
  actions: {
    marginTop: spacing[8],
    paddingHorizontal: spacing[4],
    alignItems: 'center',
  },
  deleteButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    padding: spacing[3],
  },
  deleteButtonText: {
    fontSize: typography.fontSizes.sm,
    color: colors.status.error,
  },

  // Suggested Items
  suggestionsContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[2],
  },
  suggestionChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[3],
    backgroundColor: colors.haven.purple[50],
    borderRadius: borderRadius.full,
    borderWidth: 1,
    borderColor: colors.haven.purple[200],
  },
  suggestionText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.primary,
    fontWeight: typography.fontWeights.medium,
  },
});
