import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  RefreshControl,
  Linking,
  TextInput,
  ActivityIndicator,
  Alert,
  Image,
} from 'react-native';
import { useRouter, useFocusEffect } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../../../src/contexts/auth-context';
import { useSubscription } from '../../../../src/contexts/subscription-context';
import { Card, Badge, LoadingSpinner, ScreenContainer } from '../../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../../src/lib/theme';
import { API_BASE_URL } from '../../../../src/lib/api';
import { getIdToken } from '../../../../src/lib/firebase';

// =============================================================================
// TYPES
// =============================================================================

interface Vendor {
  id: string;
  displayName: string;
  category: string;
  contactName?: string;
  phone?: string;
  email?: string;
  websiteUrl?: string;
  logoUrl?: string;
  rating?: number;
  isFavorite?: boolean;
  _logoError?: boolean; // Track logo load errors locally
}

interface DirectoryVendor {
  id: string;
  name: string;
  category: string;
  address: string;
  phone?: string;
  rating?: number;
  reviewCount?: number;
  distance?: string;
  isOpen?: boolean;
}

type TabType = 'my-vendors' | 'find-vendors';

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
  { id: 'ROOFING', label: 'Roofing', icon: 'home-outline' },
  { id: 'PEST_CONTROL', label: 'Pest Control', icon: 'bug-outline' },
  { id: 'HANDYMAN', label: 'Handyman', icon: 'hammer-outline' },
];

// =============================================================================
// VENDORS SCREEN
// =============================================================================

export default function VendorsScreen() {
  const router = useRouter();
  const { householdInfo } = useAuth();
  const { isEssentials } = useSubscription();

  // Tab state
  const [activeTab, setActiveTab] = useState<TabType>('my-vendors');

  // My Vendors state
  const [vendors, setVendors] = useState<Vendor[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState('all');

  // Find Vendors state
  const [searchQuery, setSearchQuery] = useState('');
  const [searchCategory, setSearchCategory] = useState('all');
  const [directoryVendors, setDirectoryVendors] = useState<DirectoryVendor[]>([]);
  const [isSearching, setIsSearching] = useState(false);
  const [hasSearched, setHasSearched] = useState(false);
  const [addingVendorId, setAddingVendorId] = useState<string | null>(null);

  // =============================================================================
  // MY VENDORS LOGIC
  // =============================================================================

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

      const response = await fetch(`${API_BASE_URL}/households/${householdInfo.id}/vendors`, {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      });

      if (response.ok) {
        const data = await response.json();
        setVendors(data);
      } else {
        setVendors([]);
      }
    } catch (err) {
      console.error('Fetch vendors error:', err);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [householdInfo?.id]);

  useEffect(() => {
    fetchVendors();
  }, [fetchVendors]);

  useFocusEffect(
    useCallback(() => {
      if (!isLoading) {
        fetchVendors();
      }
    }, [fetchVendors, isLoading])
  );

  // =============================================================================
  // FIND VENDORS LOGIC
  // =============================================================================

  const searchVendors = async () => {
    if (!searchQuery.trim() && searchCategory === 'all') {
      Alert.alert('Search Required', 'Please enter a search term or select a category');
      return;
    }

    setIsSearching(true);
    setHasSearched(true);

    try {
      const token = await getIdToken(true);
      if (!token) {
        setIsSearching(false);
        return;
      }

      // Build search params
      const params = new URLSearchParams();
      if (searchQuery.trim()) {
        params.append('query', searchQuery.trim());
      }
      if (searchCategory !== 'all') {
        params.append('category', searchCategory);
      }
      if (householdInfo?.id) {
        params.append('householdId', householdInfo.id);
      }

      const response = await fetch(`${API_BASE_URL}/vendors/search?${params.toString()}`, {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      });

      if (response.ok) {
        const data = await response.json();
        setDirectoryVendors(data);
      } else {
        // API failed - show empty results
        setDirectoryVendors([]);
      }
    } catch (err) {
      console.error('Search vendors error:', err);
      // API error - show empty results
      setDirectoryVendors([]);
    } finally {
      setIsSearching(false);
    }
  };

  const addVendorToHousehold = async (vendor: DirectoryVendor) => {
    if (!householdInfo?.id) return;

    setAddingVendorId(vendor.id);

    try {
      const token = await getIdToken(true);
      if (!token) {
        setAddingVendorId(null);
        return;
      }

      const response = await fetch(`${API_BASE_URL}/households/${householdInfo.id}/vendors`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          displayName: vendor.name,
          category: vendor.category,
          phone: vendor.phone,
          address: vendor.address,
          rating: vendor.rating,
          sourceId: vendor.id,
          source: 'directory',
        }),
      });

      if (response.ok) {
        Alert.alert('Success', `${vendor.name} has been added to your vendors`);
        // Remove from directory list
        setDirectoryVendors(prev => prev.filter(v => v.id !== vendor.id));
        // Refresh my vendors
        fetchVendors();
      } else {
        Alert.alert('Error', 'Failed to add vendor. Please try again.');
      }
    } catch (err) {
      console.error('Add vendor error:', err);
      Alert.alert('Error', 'Failed to add vendor. Please try again.');
    } finally {
      setAddingVendorId(null);
    }
  };

  // =============================================================================
  // HANDLERS
  // =============================================================================

  const handleVendorPress = (vendor: Vendor) => {
    router.push(`/(tabs)/manager/vendors/${vendor.id}`);
  };

  const handleAddVendor = () => {
    router.push('/(tabs)/manager/vendors/add');
  };

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
    // Navigate to vendor chat so messages show in the Messages tab
    router.push({
      pathname: '/(tabs)/manager/vendors/chat/[id]',
      params: { id: vendor.id },
    } as any);
  };

  const getCategoryIcon = (category: string) => {
    const cat = VENDOR_CATEGORIES.find(c => c.id === category);
    return cat?.icon || 'business-outline';
  };

  // =============================================================================
  // RENDER FUNCTIONS
  // =============================================================================

  const handleLogoError = (vendorId: string) => {
    // Mark this vendor's logo as failed so we show the icon instead
    setVendors(prev => prev.map(v =>
      v.id === vendorId ? { ...v, _logoError: true } : v
    ));
  };

  const renderVendor = ({ item }: { item: Vendor }) => (
    <TouchableOpacity onPress={() => handleVendorPress(item)} activeOpacity={0.7}>
      <Card style={styles.vendorCard}>
        <View style={styles.vendorHeader}>
          {item.logoUrl && !item._logoError ? (
            <Image
              source={{ uri: item.logoUrl }}
              style={styles.vendorLogo}
              resizeMode="contain"
              onError={() => handleLogoError(item.id)}
            />
          ) : (
            <View style={styles.vendorIcon}>
              <Ionicons
                name={getCategoryIcon(item.category) as any}
                size={24}
                color={colors.haven.champagne[500]}
              />
            </View>
          )}
          <View style={styles.vendorInfo}>
            <Text style={styles.vendorName}>{item.displayName}</Text>
            <Text style={styles.vendorCategory}>{item.category.replace(/_/g, ' ')}</Text>
            {item.contactName && (
              <Text style={styles.vendorContact}>{item.contactName}</Text>
            )}
          </View>
          {item.isFavorite && (
            <Badge label="Favorite" variant="success" size="sm" />
          )}
        </View>

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
    </TouchableOpacity>
  );

  const renderDirectoryVendor = ({ item }: { item: DirectoryVendor }) => (
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
          <Text style={styles.vendorName}>{item.name}</Text>
          <Text style={styles.vendorCategory}>{item.category.replace(/_/g, ' ')}</Text>
          <Text style={styles.vendorAddress}>{item.address}</Text>
        </View>
        {item.isOpen !== undefined && (
          <Badge
            label={item.isOpen ? 'Open' : 'Closed'}
            variant={item.isOpen ? 'success' : 'warning'}
            size="sm"
          />
        )}
      </View>

      <View style={styles.directoryMeta}>
        {item.rating && (
          <View style={styles.ratingContainer}>
            <Ionicons name="star" size={14} color={colors.haven.champagne[500]} />
            <Text style={styles.ratingText}>
              {item.rating.toFixed(1)} ({item.reviewCount || 0} reviews)
            </Text>
          </View>
        )}
        {item.distance && (
          <View style={styles.distanceContainer}>
            <Ionicons name="location-outline" size={14} color={colors.text.secondary} />
            <Text style={styles.distanceText}>{item.distance}</Text>
          </View>
        )}
      </View>

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
        <TouchableOpacity
          style={[styles.vendorAction, styles.vendorActionPrimary]}
          onPress={() => addVendorToHousehold(item)}
          disabled={addingVendorId === item.id}
        >
          {addingVendorId === item.id ? (
            <ActivityIndicator size="small" color={colors.white} />
          ) : (
            <>
              <Ionicons name="add-circle-outline" size={18} color={colors.white} />
              <Text style={styles.vendorActionTextPrimary}>Add to My Vendors</Text>
            </>
          )}
        </TouchableOpacity>
      </View>
    </Card>
  );

  const renderMyVendorsTab = () => (
    <>
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
                color={selectedCategory === item.id ? colors.white : colors.text.secondary}
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

      {/* Alfred Info Banner */}
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
                ? 'Add your service providers to track activity and schedule services'
                : `No ${selectedCategory.toLowerCase()} vendors found`}
            </Text>
            <TouchableOpacity style={styles.emptyAddButton} onPress={handleAddVendor}>
              <Ionicons name="add" size={20} color={colors.white} />
              <Text style={styles.emptyAddButtonText}>Add Vendor</Text>
            </TouchableOpacity>
          </View>
        }
      />

      {/* FAB */}
      {vendors.length > 0 && (
        <TouchableOpacity style={styles.fab} onPress={handleAddVendor}>
          <Ionicons name="add" size={28} color={colors.white} />
        </TouchableOpacity>
      )}
    </>
  );

  const renderFindVendorsTab = () => (
    <>
      {/* Search Section */}
      <View style={styles.searchSection}>
        <View style={styles.searchInputContainer}>
          <Ionicons name="search-outline" size={20} color={colors.text.tertiary} />
          <TextInput
            style={styles.searchInput}
            placeholder="What service do you need?"
            placeholderTextColor={colors.text.tertiary}
            value={searchQuery}
            onChangeText={setSearchQuery}
            onSubmitEditing={searchVendors}
            returnKeyType="search"
          />
          {searchQuery.length > 0 && (
            <TouchableOpacity onPress={() => setSearchQuery('')}>
              <Ionicons name="close-circle" size={20} color={colors.text.tertiary} />
            </TouchableOpacity>
          )}
        </View>

        {/* Category Filter */}
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
                searchCategory === item.id && styles.filterChipSelected,
              ]}
              onPress={() => setSearchCategory(item.id)}
            >
              <Ionicons
                name={item.icon as any}
                size={16}
                color={searchCategory === item.id ? colors.white : colors.text.secondary}
              />
              <Text
                style={[
                  styles.filterChipText,
                  searchCategory === item.id && styles.filterChipTextSelected,
                ]}
              >
                {item.label}
              </Text>
            </TouchableOpacity>
          )}
        />
      </View>

      {/* Alfred Find Vendors CTA */}
      <View style={styles.alfredFindContainer}>
        <View style={styles.alfredFindIcon}>
          <Ionicons name="sparkles" size={48} color={colors.haven.champagne[500]} />
        </View>
        <Text style={styles.alfredFindTitle}>Let Haven Find the Right Vendor</Text>
        <Text style={styles.alfredFindSubtitle}>
          Tell us what you need and we'll research and recommend vetted local professionals - no searching required.
        </Text>

        <TouchableOpacity
          style={styles.alfredFindButton}
          onPress={() => {
            const categoryLabel = searchCategory !== 'all'
              ? VENDOR_CATEGORIES.find(c => c.id === searchCategory)?.label?.toLowerCase() || searchCategory.toLowerCase()
              : 'service provider';
            const prefillText = searchQuery.trim()
              ? `Find me a ${categoryLabel}: ${searchQuery.trim()}`
              : `Find me a ${categoryLabel}`;
            router.push({
              pathname: '/(tabs)/manager/new-request',
              params: { prefill: prefillText },
            } as any);
          }}
        >
          <Ionicons name="sparkles" size={20} color={colors.white} />
          <Text style={styles.alfredFindButtonText}>
            {searchQuery ? `Find ${searchQuery}` : 'Request Vendor Recommendation'}
          </Text>
        </TouchableOpacity>

        <Text style={styles.alfredFindNote}>
          We typically respond within 24 hours with 2-3 vetted options
        </Text>
      </View>

      {/* Or Add Manually */}
      <View style={styles.orDivider}>
        <View style={styles.orLine} />
        <Text style={styles.orText}>or</Text>
        <View style={styles.orLine} />
      </View>

      {/* Manual Add Section */}
      <View style={styles.manualAddSection}>
        <Text style={styles.manualAddTitle}>Already have a vendor in mind?</Text>
        <TouchableOpacity
          style={styles.manualAddButton}
          onPress={handleAddVendor}
        >
          <Ionicons name="add-circle-outline" size={18} color={colors.haven.champagne[600]} />
          <Text style={styles.manualAddButtonText}>Add Vendor Manually</Text>
        </TouchableOpacity>
      </View>
    </>
  );

  if (isLoading) {
    return (
      <ScreenContainer title="Vendors" onBackPress={() => router.navigate('/more')}>
        <View style={styles.loadingContainer}>
          <LoadingSpinner message="Loading vendors..." />
        </View>
      </ScreenContainer>
    );
  }

  return (
    <ScreenContainer title="Vendors" onBackPress={() => router.navigate('/more')} scrollable={false}>

      <View style={styles.contentContainer}>
        {/* Tab Selector */}
      <View style={styles.tabContainer}>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'my-vendors' && styles.tabActive]}
          onPress={() => setActiveTab('my-vendors')}
        >
          <Ionicons
            name="briefcase-outline"
            size={18}
            color={activeTab === 'my-vendors' ? colors.haven.champagne[500] : colors.text.secondary}
          />
          <Text style={[styles.tabText, activeTab === 'my-vendors' && styles.tabTextActive]}>
            My Vendors
          </Text>
          {vendors.length > 0 && (
            <View style={styles.tabBadge}>
              <Text style={styles.tabBadgeText}>{vendors.length}</Text>
            </View>
          )}
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'find-vendors' && styles.tabActive]}
          onPress={() => setActiveTab('find-vendors')}
        >
          <Ionicons
            name="search-outline"
            size={18}
            color={activeTab === 'find-vendors' ? colors.haven.champagne[500] : colors.text.secondary}
          />
          <Text style={[styles.tabText, activeTab === 'find-vendors' && styles.tabTextActive]}>
            Find Vendors
          </Text>
        </TouchableOpacity>
      </View>

        {/* Tab Content */}
        {activeTab === 'my-vendors' ? renderMyVendorsTab() : renderFindVendorsTab()}
      </View>
    </ScreenContainer>
  );
}

// =============================================================================
// STYLES
// =============================================================================

const styles = StyleSheet.create({
  fullContainer: {
    flex: 1,
    backgroundColor: colors.haven.navy[900],
  },
  loadingContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.background.secondary,
  },
  contentContainer: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  tabContainer: {
    flexDirection: 'row',
    backgroundColor: colors.white,
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  tab: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: spacing[3],
    gap: spacing[2],
    borderBottomWidth: 2,
    borderBottomColor: 'transparent',
  },
  tabActive: {
    borderBottomColor: colors.haven.champagne[500],
  },
  tabText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
  },
  tabTextActive: {
    color: colors.haven.champagne[500],
  },
  tabBadge: {
    backgroundColor: colors.haven.champagne[100],
    paddingHorizontal: spacing[2],
    paddingVertical: 2,
    borderRadius: borderRadius.full,
  },
  tabBadgeText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.champagne[600],
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
  searchSection: {
    backgroundColor: colors.white,
    padding: spacing[4],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  searchInputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.background.tertiary,
    borderRadius: borderRadius.lg,
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[2],
    marginBottom: spacing[3],
    gap: spacing[2],
  },
  searchInput: {
    flex: 1,
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
    paddingVertical: spacing[1],
  },
  searchButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.haven.champagne[500],
    paddingVertical: spacing[3],
    borderRadius: borderRadius.lg,
    marginTop: spacing[3],
    gap: spacing[2],
  },
  searchButtonText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  searchingContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: spacing[10],
  },
  searchingText: {
    marginTop: spacing[4],
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
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
  vendorLogo: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.white,
    borderWidth: 1,
    borderColor: colors.border.light,
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
  vendorAddress: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: spacing[0.5],
  },
  directoryMeta: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: spacing[3],
    gap: spacing[4],
  },
  ratingContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 2,
  },
  ratingText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginLeft: spacing[1],
  },
  distanceContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
  },
  distanceText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
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
    backgroundColor: colors.haven.navy[800],
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
    paddingHorizontal: spacing[6],
  },
  emptyAddButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.haven.champagne[500],
    paddingVertical: spacing[3],
    paddingHorizontal: spacing[5],
    borderRadius: borderRadius.lg,
    marginTop: spacing[4],
    gap: spacing[2],
  },
  emptyAddButtonText: {
    color: colors.white,
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
  },
  fab: {
    position: 'absolute',
    bottom: spacing[6],
    right: spacing[4],
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: colors.haven.champagne[500],
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 4,
    elevation: 5,
  },
  // Alfred Find Vendors styles
  alfredFindContainer: {
    alignItems: 'center',
    padding: spacing[6],
    paddingTop: spacing[8],
  },
  alfredFindIcon: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[4],
  },
  alfredFindTitle: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
    textAlign: 'center',
    marginBottom: spacing[2],
  },
  alfredFindSubtitle: {
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
    textAlign: 'center',
    lineHeight: 22,
    paddingHorizontal: spacing[4],
    marginBottom: spacing[5],
  },
  alfredFindButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.haven.champagne[500],
    paddingVertical: spacing[4],
    paddingHorizontal: spacing[6],
    borderRadius: borderRadius.lg,
    gap: spacing[2],
    width: '100%',
  },
  alfredFindButtonText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  alfredFindNote: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
    marginTop: spacing[3],
    textAlign: 'center',
  },
  orDivider: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing[6],
    marginVertical: spacing[4],
  },
  orLine: {
    flex: 1,
    height: 1,
    backgroundColor: colors.border.light,
  },
  orText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
    paddingHorizontal: spacing[4],
  },
  manualAddSection: {
    alignItems: 'center',
    paddingHorizontal: spacing[6],
    paddingBottom: spacing[6],
  },
  manualAddTitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginBottom: spacing[3],
  },
  manualAddButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.haven.champagne[50],
    paddingVertical: spacing[3],
    paddingHorizontal: spacing[5],
    borderRadius: borderRadius.lg,
    gap: spacing[2],
  },
  manualAddButtonText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.champagne[600],
  },
});
