import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  RefreshControl,
  Linking,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter, Stack } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../../src/contexts/auth-context';
import { useSubscription } from '../../../src/contexts/subscription-context';
import { Card, Badge, LoadingSpinner } from '../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../src/lib/theme';
import { API_BASE_URL } from '../../../src/lib/api';
import { getIdToken } from '../../../src/lib/firebase';

// =============================================================================
// TYPES
// =============================================================================

interface Vendor {
  id: string;
  businessName: string;
  category: string;
  contactName?: string;
  phone?: string;
  email?: string;
  rating?: number;
  isPreferred?: boolean;
}

// =============================================================================
// VENDOR CATEGORIES
// =============================================================================

const VENDOR_CATEGORIES = [
  { id: 'all', label: 'All', icon: 'apps-outline' },
  { id: 'HVAC', label: 'HVAC', icon: 'thermometer-outline' },
  { id: 'PLUMBING', label: 'Plumbing', icon: 'water-outline' },
  { id: 'ELECTRICAL', label: 'Electrical', icon: 'flash-outline' },
  { id: 'LANDSCAPING', label: 'Landscape', icon: 'leaf-outline' },
  { id: 'CLEANING', label: 'Cleaning', icon: 'sparkles-outline' },
  { id: 'POOL_SPA', label: 'Pool', icon: 'water-outline' },
];

// =============================================================================
// VENDORS SCREEN
// =============================================================================

export default function VendorsScreen() {
  const router = useRouter();
  const { householdInfo } = useAuth();
  const { isEssentials } = useSubscription();
  const [vendors, setVendors] = useState<Vendor[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [error, setError] = useState<string | null>(null);

  const fetchVendors = useCallback(async () => {
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

      const response = await fetch(`${API_BASE_URL}/household-vendors`, {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      });

      if (response.ok) {
        const data = await response.json();
        setVendors(data);
        setError(null);
      } else {
        // Use placeholder data if API fails
        setVendors([]);
      }
    } catch (err) {
      console.error('Fetch vendors error:', err);
      setError('Failed to load vendors');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [householdInfo?.id]);

  useEffect(() => {
    fetchVendors();
  }, [fetchVendors]);

  const filteredVendors =
    selectedCategory === 'all'
      ? vendors
      : vendors.filter(v => v.category === selectedCategory);

  const handleCallVendor = (phone: string) => {
    Linking.openURL(`tel:${phone.replace(/[^0-9+]/g, '')}`);
  };

  const handleEmailVendor = (email: string) => {
    Linking.openURL(`mailto:${email}`);
  };

  const handleSchedule = (vendor: Vendor) => {
    // Navigate to request screen with vendor pre-selected
    router.push({
      pathname: '/(tabs)/manager/new-request',
      params: { vendorId: vendor.id, vendorName: vendor.businessName },
    } as any);
  };

  const getCategoryIcon = (category: string) => {
    const cat = VENDOR_CATEGORIES.find(c => c.id === category);
    return cat?.icon || 'business-outline';
  };

  const renderVendor = ({ item }: { item: Vendor }) => (
    <Card style={styles.vendorCard}>
      <View style={styles.vendorHeader}>
        <View style={styles.vendorIcon}>
          <Ionicons
            name={getCategoryIcon(item.category) as any}
            size={24}
            color={colors.haven.champagne[500]}
          />
        </View>
        <View style={styles.vendorInfo}>
          <Text style={styles.vendorName}>{item.businessName}</Text>
          <Text style={styles.vendorCategory}>{item.category.replace('_', ' ')}</Text>
          {item.contactName && (
            <Text style={styles.vendorContact}>{item.contactName}</Text>
          )}
        </View>
        {item.isPreferred && (
          <Badge label="Preferred" variant="success" size="sm" />
        )}
      </View>

      {/* Rating */}
      {item.rating && (
        <View style={styles.ratingContainer}>
          {[1, 2, 3, 4, 5].map(star => (
            <Ionicons
              key={star}
              name={star <= item.rating! ? 'star' : 'star-outline'}
              size={14}
              color={star <= item.rating! ? colors.haven.champagne[500] : colors.text.tertiary}
            />
          ))}
          <Text style={styles.ratingText}>{item.rating.toFixed(1)}</Text>
        </View>
      )}

      {/* Actions */}
      <View style={styles.vendorActions}>
        {item.phone && (
          <TouchableOpacity
            style={styles.vendorAction}
            onPress={() => handleCallVendor(item.phone!)}
          >
            <Ionicons name="call-outline" size={18} color={colors.haven.champagne[500]} />
            <Text style={styles.vendorActionText}>Call</Text>
          </TouchableOpacity>
        )}
        {item.email && (
          <TouchableOpacity
            style={styles.vendorAction}
            onPress={() => handleEmailVendor(item.email!)}
          >
            <Ionicons name="mail-outline" size={18} color={colors.haven.champagne[500]} />
            <Text style={styles.vendorActionText}>Email</Text>
          </TouchableOpacity>
        )}
        <TouchableOpacity
          style={[styles.vendorAction, styles.vendorActionPrimary]}
          onPress={() => handleSchedule(item)}
        >
          <Ionicons name="calendar-outline" size={18} color={colors.white} />
          <Text style={styles.vendorActionTextPrimary}>
            {isEssentials ? 'Ask Alfred' : 'Schedule'}
          </Text>
        </TouchableOpacity>
      </View>
    </Card>
  );

  if (isLoading) {
    return <LoadingSpinner fullScreen message="Loading vendors..." />;
  }

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <Stack.Screen options={{ title: 'Vendors' }} />

      {/* Category Filter */}
      <View style={styles.filterContainer}>
        <FlatList
          horizontal
          showsHorizontalScrollIndicator={false}
          data={VENDOR_CATEGORIES}
          keyExtractor={item => item.id}
          contentContainerStyle={styles.filterContent}
          renderItem={({ item }) => (
            <TouchableOpacity
              style={[
                styles.filterChip,
                selectedCategory === item.id && styles.filterChipSelected,
              ]}
              onPress={() => setSelectedCategory(item.id)}
            >
              <Ionicons
                name={item.icon as any}
                size={16}
                color={
                  selectedCategory === item.id ? colors.white : colors.text.secondary
                }
              />
              <Text
                style={[
                  styles.filterChipText,
                  selectedCategory === item.id && styles.filterChipTextSelected,
                ]}
              >
                {item.label}
              </Text>
            </TouchableOpacity>
          )}
        />
      </View>

      {/* Alfred Info Banner (Essentials tier) */}
      {isEssentials && (
        <View style={styles.alfredBanner}>
          <Ionicons name="sparkles" size={20} color={colors.haven.champagne[500]} />
          <Text style={styles.alfredBannerText}>
            Alfred can schedule any of these vendors for you. Just ask!
          </Text>
        </View>
      )}

      {/* Vendors List */}
      <FlatList
        data={filteredVendors}
        renderItem={renderVendor}
        keyExtractor={item => item.id}
        contentContainerStyle={styles.listContent}
        refreshControl={
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={() => {
              setIsRefreshing(true);
              fetchVendors();
            }}
          />
        }
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Ionicons name="business-outline" size={48} color={colors.haven.navy[300]} />
            <Text style={styles.emptyTitle}>No vendors yet</Text>
            <Text style={styles.emptyText}>
              {selectedCategory === 'all'
                ? 'Vendors will appear here once added'
                : `No ${selectedCategory.toLowerCase()} vendors found`}
            </Text>
          </View>
        }
      />
    </SafeAreaView>
  );
}

// =============================================================================
// STYLES
// =============================================================================

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  filterContainer: {
    backgroundColor: colors.white,
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  filterContent: {
    padding: spacing[3],
    gap: spacing[2],
  },
  filterChip: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[3],
    borderRadius: borderRadius.full,
    backgroundColor: colors.background.tertiary,
    gap: spacing[1],
  },
  filterChipSelected: {
    backgroundColor: colors.haven.navy[900],
  },
  filterChipText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    fontWeight: typography.fontWeights.medium,
  },
  filterChipTextSelected: {
    color: colors.white,
  },
  alfredBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.haven.champagne[50],
    padding: spacing[3],
    marginHorizontal: spacing[4],
    marginTop: spacing[4],
    borderRadius: borderRadius.lg,
    gap: spacing[2],
  },
  alfredBannerText: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[600],
  },
  listContent: {
    padding: spacing[4],
  },
  vendorCard: {
    padding: spacing[4],
    marginBottom: spacing[3],
  },
  vendorHeader: {
    flexDirection: 'row',
    alignItems: 'flex-start',
  },
  vendorIcon: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  vendorInfo: {
    flex: 1,
    marginLeft: spacing[3],
  },
  vendorName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  vendorCategory: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: spacing[0.5],
    textTransform: 'capitalize',
  },
  vendorContact: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: spacing[0.5],
  },
  ratingContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: spacing[3],
    gap: 2,
  },
  ratingText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginLeft: spacing[1],
  },
  vendorActions: {
    flexDirection: 'row',
    marginTop: spacing[4],
    gap: spacing[2],
  },
  vendorAction: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[3],
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.champagne[50],
    gap: spacing[1],
  },
  vendorActionPrimary: {
    flex: 1,
    justifyContent: 'center',
    backgroundColor: colors.haven.champagne[500],
  },
  vendorActionText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[600],
    fontWeight: typography.fontWeights.medium,
  },
  vendorActionTextPrimary: {
    color: colors.white,
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
