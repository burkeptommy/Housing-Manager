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
import { AnimatedCard, Badge, ScreenContainer } from '../../../../src/components';
import { Skeleton } from '../../../../src/components/ui/Skeleton';
import { colors, typography, spacing, borderRadius, shadows } from '../../../../src/lib/theme';
import { API_BASE_URL } from '../../../../src/lib/api';
import { getIdToken } from '../../../../src/lib/firebase';

// =============================================================================
// TYPES
// =============================================================================

type AssetCategory =
  | 'APPLIANCE' | 'HVAC' | 'PLUMBING' | 'ELECTRICAL' | 'STRUCTURAL'
  | 'FURNITURE' | 'ELECTRONICS' | 'OUTDOOR' | 'VEHICLE' | 'SAFETY' | 'OTHER';

interface AssetData {
  id: string;
  name: string;
  category: AssetCategory;
  zone: {
    id: string;
    name: string;
    type: string;
  } | null;
  brand: string | null;
  model: string | null;
  serialNumber: string | null;
  color: string | null;
  condition: string | null;
  conditionNotes: string | null;
  purchaseDate: string | null;
  purchasePrice: number | null;
  purchaseVendor: string | null;
  warrantyExpires: string | null;
  warrantyNotes: string | null;
  lastServiceDate: string | null;
  nextServiceDate: string | null;
  serviceInterval: string | null;
  serviceVendorId: string | null;
  serviceVendor: string | null;
  photos: string[];
  manualUrl: string | null;
  notes: string | null;
}

// =============================================================================
// HELPERS
// =============================================================================

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

const CATEGORY_COLORS: Record<AssetCategory, string> = {
  APPLIANCE: colors.haven.champagne[500],
  HVAC: colors.red[500],
  PLUMBING: colors.blue[500],
  ELECTRICAL: colors.amber[500],
  STRUCTURAL: colors.gray[600],
  FURNITURE: colors.indigo[500],
  ELECTRONICS: colors.haven.navy[500],
  OUTDOOR: colors.green[500],
  VEHICLE: colors.slate[600],
  SAFETY: colors.emerald[500],
  OTHER: colors.gray[500],
};

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
    case 'Good': return colors.haven.navy[500];
    case 'Fair': return colors.status.warning;
    case 'Needs Service': return colors.status.error;
    default: return colors.gray[400];
  }
}

function formatDate(dateString: string | null): string {
  if (!dateString) return '—';
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
}

function formatCurrency(amount: number | null): string {
  if (!amount) return '—';
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

// =============================================================================
// COMPONENT
// =============================================================================

export default function AssetDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [data, setData] = useState<AssetData | null>(null);
  const [error, setError] = useState<string | null>(null);

  const fetchAsset = useCallback(async () => {
    if (!id) {
      setIsLoading(false);
      setError('No asset ID provided');
      return;
    }

    try {
      const token = await getIdToken(true);
      if (!token) {
        setError('Authentication expired. Please sign in again.');
        setIsLoading(false);
        return;
      }

      const response = await fetch(`${API_BASE_URL}/property/assets/${id}`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (!response.ok) {
        throw new Error(`Failed to fetch asset: ${response.status}`);
      }

      const assetData = await response.json();
      setData(assetData);
      setError(null);
    } catch (err) {
      console.error('Asset fetch error:', err);
      setError('Failed to load item. Please try again.');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [id]);

  useEffect(() => {
    fetchAsset();
  }, [fetchAsset]);

  const onRefresh = () => {
    setIsRefreshing(true);
    fetchAsset();
  };

  const handleDeleteAsset = async () => {
    Alert.alert(
      'Delete Item',
      'Are you sure you want to delete this item?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            try {
              const token = await getIdToken(true);
              if (!token) return;

              const response = await fetch(`${API_BASE_URL}/property/assets/${id}`, {
                method: 'DELETE',
                headers: { Authorization: `Bearer ${token}` },
              });

              if (response.ok) {
                router.back();
              }
            } catch (err) {
              console.error('Delete asset error:', err);
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
          <Text style={styles.errorTitle}>Unable to Load Item</Text>
          <Text style={styles.errorText}>{error}</Text>
          <TouchableOpacity style={styles.retryButton} onPress={fetchAsset}>
            <Text style={styles.retryText}>Try Again</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  const categoryColor = CATEGORY_COLORS[data.category];
  const isWarrantyExpired = data.warrantyExpires && new Date(data.warrantyExpires) < new Date();
  const isServiceDue = data.nextServiceDate && new Date(data.nextServiceDate) < new Date();

  return (
    <ScreenContainer
      title={data.name || 'Item'}
      showBack
      onBackPress={() => router.back()}
      refreshing={isRefreshing}
      onRefresh={onRefresh}
      contentStyle={styles.scrollContent}
    >
        {/* Asset Header */}
        <View style={[styles.header, { backgroundColor: categoryColor + '15' }]}>
          <View style={[styles.assetIcon, { backgroundColor: categoryColor + '25' }]}>
            <Ionicons name={CATEGORY_ICONS[data.category]} size={40} color={categoryColor} />
          </View>
          <Text style={styles.assetName}>{data.name}</Text>
          <Badge label={getCategoryLabel(data.category)} variant="info" />
          {data.zone && (
            <TouchableOpacity
              style={styles.zoneBadge}
              onPress={() => router.push(`/(tabs)/home/zone/${data.zone!.id}`)}
            >
              <Ionicons name="location-outline" size={14} color={colors.text.secondary} />
              <Text style={styles.zoneBadgeText}>{data.zone.name}</Text>
            </TouchableOpacity>
          )}
        </View>

        {/* Condition & Status */}
        <View style={styles.statusRow}>
          {data.condition && (
            <View style={styles.statusItem}>
              <View style={[styles.conditionDot, { backgroundColor: getConditionColor(data.condition) }]} />
              <Text style={styles.statusLabel}>Condition:</Text>
              <Text style={styles.statusValue}>{data.condition}</Text>
            </View>
          )}
          {isServiceDue && (
            <View style={styles.alertBadge}>
              <Ionicons name="warning" size={14} color={colors.status.warning} />
              <Text style={styles.alertText}>Service Due</Text>
            </View>
          )}
          {isWarrantyExpired && (
            <View style={[styles.alertBadge, { backgroundColor: colors.status.error + '20' }]}>
              <Ionicons name="warning" size={14} color={colors.status.error} />
              <Text style={[styles.alertText, { color: colors.status.error }]}>Warranty Expired</Text>
            </View>
          )}
        </View>

        {/* Details Card */}
        <AnimatedCard style={styles.card}>
          <Text style={styles.cardTitle}>Details</Text>

          {data.brand && (
            <View style={styles.detailRow}>
              <Text style={styles.detailLabel}>Brand</Text>
              <Text style={styles.detailValue}>{data.brand}</Text>
            </View>
          )}
          {data.model && (
            <View style={styles.detailRow}>
              <Text style={styles.detailLabel}>Model</Text>
              <Text style={styles.detailValue}>{data.model}</Text>
            </View>
          )}
          {data.serialNumber && (
            <View style={styles.detailRow}>
              <Text style={styles.detailLabel}>Serial Number</Text>
              <Text style={styles.detailValue}>{data.serialNumber}</Text>
            </View>
          )}
          {data.color && (
            <View style={styles.detailRow}>
              <Text style={styles.detailLabel}>Color</Text>
              <Text style={styles.detailValue}>{data.color}</Text>
            </View>
          )}
        </AnimatedCard>

        {/* Purchase & Warranty Card */}
        {(data.purchaseDate || data.purchasePrice || data.warrantyExpires) && (
          <AnimatedCard style={styles.card}>
            <Text style={styles.cardTitle}>Purchase & Warranty</Text>

            {data.purchaseDate && (
              <View style={styles.detailRow}>
                <Text style={styles.detailLabel}>Purchase Date</Text>
                <Text style={styles.detailValue}>{formatDate(data.purchaseDate)}</Text>
              </View>
            )}
            {data.purchasePrice && (
              <View style={styles.detailRow}>
                <Text style={styles.detailLabel}>Purchase Price</Text>
                <Text style={styles.detailValue}>{formatCurrency(data.purchasePrice)}</Text>
              </View>
            )}
            {data.purchaseVendor && (
              <View style={styles.detailRow}>
                <Text style={styles.detailLabel}>Purchased From</Text>
                <Text style={styles.detailValue}>{data.purchaseVendor}</Text>
              </View>
            )}
            {data.warrantyExpires && (
              <View style={styles.detailRow}>
                <Text style={styles.detailLabel}>Warranty Expires</Text>
                <Text style={[
                  styles.detailValue,
                  isWarrantyExpired && { color: colors.status.error }
                ]}>
                  {formatDate(data.warrantyExpires)}
                  {isWarrantyExpired && ' (Expired)'}
                </Text>
              </View>
            )}
            {data.warrantyNotes && (
              <View style={styles.notesRow}>
                <Text style={styles.detailLabel}>Warranty Notes</Text>
                <Text style={styles.notesText}>{data.warrantyNotes}</Text>
              </View>
            )}
          </AnimatedCard>
        )}

        {/* Service Card */}
        {(data.lastServiceDate || data.nextServiceDate || data.serviceVendor) && (
          <AnimatedCard style={styles.card}>
            <Text style={styles.cardTitle}>Service</Text>

            {data.lastServiceDate && (
              <View style={styles.detailRow}>
                <Text style={styles.detailLabel}>Last Service</Text>
                <Text style={styles.detailValue}>{formatDate(data.lastServiceDate)}</Text>
              </View>
            )}
            {data.nextServiceDate && (
              <View style={styles.detailRow}>
                <Text style={styles.detailLabel}>Next Service</Text>
                <Text style={[
                  styles.detailValue,
                  isServiceDue && { color: colors.status.warning }
                ]}>
                  {formatDate(data.nextServiceDate)}
                  {isServiceDue && ' (Due)'}
                </Text>
              </View>
            )}
            {data.serviceInterval && (
              <View style={styles.detailRow}>
                <Text style={styles.detailLabel}>Service Interval</Text>
                <Text style={styles.detailValue}>{data.serviceInterval}</Text>
              </View>
            )}
            {data.serviceVendor && (
              <View style={styles.detailRow}>
                <Text style={styles.detailLabel}>Service Vendor</Text>
                <Text style={styles.detailValue}>{data.serviceVendor}</Text>
              </View>
            )}
          </AnimatedCard>
        )}

        {/* Notes */}
        {(data.notes || data.conditionNotes) && (
          <AnimatedCard style={styles.card}>
            <Text style={styles.cardTitle}>Notes</Text>
            {data.notes && (
              <Text style={styles.notesText}>{data.notes}</Text>
            )}
            {data.conditionNotes && (
              <View style={data.notes ? styles.notesDivider : undefined}>
                <Text style={styles.detailLabel}>Condition Notes</Text>
                <Text style={styles.notesText}>{data.conditionNotes}</Text>
              </View>
            )}
          </AnimatedCard>
        )}

        {/* Actions */}
        <View style={styles.actions}>
          <TouchableOpacity style={styles.deleteButton} onPress={handleDeleteAsset}>
            <Ionicons name="trash-outline" size={18} color={colors.status.error} />
            <Text style={styles.deleteButtonText}>Delete Item</Text>
          </TouchableOpacity>
        </View>
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
    alignItems: 'center',
    paddingVertical: spacing[6],
    paddingHorizontal: spacing[4],
  },
  assetIcon: {
    width: 80,
    height: 80,
    borderRadius: borderRadius['2xl'],
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[3],
  },
  assetName: {
    fontSize: typography.fontSizes['2xl'],
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
    marginBottom: spacing[2],
    textAlign: 'center',
  },
  zoneBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
    marginTop: spacing[2],
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[1],
    backgroundColor: colors.white,
    borderRadius: borderRadius.full,
    ...shadows.sm,
  },
  zoneBadgeText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },

  // Status Row
  statusRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[3],
    paddingHorizontal: spacing[4],
    marginTop: -spacing[3],
    marginBottom: spacing[4],
  },
  statusItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    backgroundColor: colors.white,
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[2],
    borderRadius: borderRadius.full,
    ...shadows.sm,
  },
  conditionDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  statusLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
  },
  statusValue: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  alertBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
    backgroundColor: colors.status.warning + '20',
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[2],
    borderRadius: borderRadius.full,
  },
  alertText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.status.warning,
  },

  // Cards
  card: {
    marginHorizontal: spacing[4],
    marginBottom: spacing[4],
    padding: spacing[4],
  },
  cardTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginBottom: spacing[3],
  },
  detailRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: spacing[2],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  detailLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
  },
  detailValue: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  notesRow: {
    paddingTop: spacing[3],
    marginTop: spacing[2],
  },
  notesText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    lineHeight: 20,
    marginTop: spacing[1],
  },
  notesDivider: {
    marginTop: spacing[3],
    paddingTop: spacing[3],
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
  },

  // Actions
  actions: {
    marginTop: spacing[4],
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
});
