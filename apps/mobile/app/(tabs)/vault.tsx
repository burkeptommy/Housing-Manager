import React, { useState, useEffect, useCallback } from 'react';
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
  ActivityIndicator,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import Animated, { FadeInUp, Layout } from 'react-native-reanimated';
import * as ImagePicker from 'expo-image-picker';
import * as DocumentPicker from 'expo-document-picker';
import { useAuth } from '../../src/contexts/auth-context';
import { Card, Badge, SkeletonList, NoDocumentsEmptyState, ErrorEmptyState } from '../../src/components';
import { colors, typography, spacing, borderRadius } from '../../src/lib/theme';
import { API_BASE_URL } from '../../src/lib/api';
import { getIdToken } from '../../src/lib/firebase';

// =============================================================================
// TYPES - Match backend Document response
// =============================================================================

interface DocumentFromAPI {
  id: string;
  title: string;
  category: string;
  subcategory?: string | null;
  description?: string | null;
  fileUrl: string;
  fileName: string;
  fileSize: number;
  mimeType: string;
  tags?: string[];
  expiresAt?: string | null;
  createdAt: string;
  updatedAt: string;
  uploadedBy?: {
    id: string;
    firstName?: string | null;
    lastName?: string | null;
  } | null;
  vendor?: {
    id: string;
    companyName: string;
  } | null;
}

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
  'PROPERTY': 'home-outline',
  'Property': 'home-outline',
  'INSURANCE': 'shield-outline',
  'Insurance': 'shield-outline',
  'WARRANTY': 'document-text-outline',
  'Warranty': 'document-text-outline',
  'MANUAL': 'book-outline',
  'Manual': 'book-outline',
  'TAX': 'calculator-outline',
  'Tax': 'calculator-outline',
  'CONTRACT': 'create-outline',
  'Contract': 'create-outline',
  'RECEIPT': 'receipt-outline',
  'Receipt': 'receipt-outline',
  'PERMIT': 'ribbon-outline',
  'Permit': 'ribbon-outline',
  'MAINTENANCE': 'construct-outline',
  'Maintenance': 'construct-outline',
  'OTHER': 'document-outline',
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
  'Maintenance',
];

// =============================================================================
// COMPONENT
// =============================================================================

export default function VaultScreen() {
  const router = useRouter();
  const { householdInfo } = useAuth();
  const [documents, setDocuments] = useState<Document[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [isUploading, setIsUploading] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState('All');
  const [error, setError] = useState<string | null>(null);

  const formatFileSize = (bytes: number): string => {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  const getFileType = (mimeType: string): string => {
    if (mimeType.includes('pdf')) return 'pdf';
    if (mimeType.includes('image')) return 'image';
    if (mimeType.includes('word') || mimeType.includes('doc')) return 'doc';
    if (mimeType.includes('excel') || mimeType.includes('sheet')) return 'xls';
    return 'file';
  };

  const convertDocument = (apiDoc: DocumentFromAPI): Document => ({
    id: apiDoc.id,
    name: apiDoc.title || apiDoc.fileName,
    category: apiDoc.category.charAt(0).toUpperCase() + apiDoc.category.slice(1).toLowerCase(),
    uploadedAt: apiDoc.createdAt,
    size: formatFileSize(apiDoc.fileSize),
    type: getFileType(apiDoc.mimeType),
    expiresAt: apiDoc.expiresAt || undefined,
  });

  const fetchDocuments = useCallback(async () => {
    if (!householdInfo?.id) {
      setError('No household found. Please complete onboarding.');
      setIsLoading(false);
      setIsRefreshing(false);
      return;
    }

    try {
      const token = await getIdToken(true);
      if (!token) {
        setError('Authentication expired. Please sign in again.');
        setIsLoading(false);
        setIsRefreshing(false);
        return;
      }

      const response = await fetch(
        `${API_BASE_URL}/documents/household/${householdInfo.id}`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        }
      );

      if (!response.ok) {
        throw new Error(`Failed to fetch documents: ${response.status}`);
      }

      const apiDocuments: DocumentFromAPI[] = await response.json();
      const convertedDocuments = apiDocuments.map(convertDocument);
      setDocuments(convertedDocuments);
      setError(null);
    } catch (err) {
      console.error('Fetch documents error:', err);
      setError('Failed to load documents. Please try again.');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [householdInfo?.id]);

  useEffect(() => {
    fetchDocuments();
  }, [fetchDocuments]);

  const uploadFile = async (fileUri: string, fileName: string, mimeType: string) => {
    if (!householdInfo?.id) {
      Alert.alert('Error', 'No household found');
      return;
    }

    setIsUploading(true);

    try {
      const token = await getIdToken(true);
      if (!token) {
        Alert.alert('Error', 'Authentication expired. Please sign in again.');
        return;
      }

      const formData = new FormData();
      formData.append('file', {
        uri: fileUri,
        name: fileName,
        type: mimeType,
      } as any);
      formData.append('category', 'OTHER');
      formData.append('title', fileName);

      const response = await fetch(
        `${API_BASE_URL}/documents/household/${householdInfo.id}/upload`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${token}`,
          },
          body: formData,
        }
      );

      if (!response.ok) {
        throw new Error('Upload failed');
      }

      Alert.alert('Success', 'Document uploaded successfully');
      fetchDocuments();
    } catch (err) {
      console.error('Upload error:', err);
      Alert.alert('Error', 'Failed to upload document. Please try again.');
    } finally {
      setIsUploading(false);
    }
  };

  const handleUpload = () => {
    router.push('/(tabs)/vault/upload' as any);
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

    if (!result.canceled && result.assets[0]) {
      const asset = result.assets[0];
      const fileName = `photo_${Date.now()}.jpg`;
      await uploadFile(asset.uri, fileName, 'image/jpeg');
    }
  };

  const pickImage = async () => {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images'],
      quality: 0.8,
      allowsEditing: true,
    });

    if (!result.canceled && result.assets[0]) {
      const asset = result.assets[0];
      const fileName = asset.fileName || `image_${Date.now()}.jpg`;
      await uploadFile(asset.uri, fileName, asset.mimeType || 'image/jpeg');
    }
  };

  const pickDocument = async () => {
    const result = await DocumentPicker.getDocumentAsync({
      type: ['application/pdf', 'image/*'],
      copyToCacheDirectory: true,
    });

    if (!result.canceled && result.assets[0]) {
      const asset = result.assets[0];
      await uploadFile(asset.uri, asset.name, asset.mimeType || 'application/octet-stream');
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
    selectedCategory === 'All' ? true : doc.category.toLowerCase() === selectedCategory.toLowerCase()
  );

  const handleDocumentPress = (documentId: string) => {
    router.push(`/(tabs)/vault/${documentId}` as any);
  };

  const renderDocument = ({ item, index }: { item: Document; index: number }) => (
    <Animated.View
      entering={FadeInUp.delay(index * 50).duration(400)}
      layout={Layout.springify()}
    >
    <TouchableOpacity activeOpacity={0.7} onPress={() => handleDocumentPress(item.id)}>
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
          {item.expiresAt && (isExpired(item.expiresAt) || isExpiringSoon(item.expiresAt)) && (
            <Badge
              label={isExpired(item.expiresAt) ? 'Expired' : 'Expiring Soon'}
              variant={isExpired(item.expiresAt) ? 'error' : 'warning'}
              size="sm"
            />
          )}
          <Ionicons name="chevron-forward" size={20} color={colors.text.tertiary} />
        </View>
      </Card>
    </TouchableOpacity>
    </Animated.View>
  );

  if (isLoading) {
    return (
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <View style={styles.categoriesContainer}>
          {CATEGORIES.slice(0, 5).map((cat, i) => (
            <View key={cat} style={[styles.categoryTab, i === 0 && styles.categoryTabActive]}>
              <Text style={[styles.categoryText, i === 0 && styles.categoryTextActive]}>{cat}</Text>
            </View>
          ))}
        </View>
        <SkeletonList count={5} showCards />
      </SafeAreaView>
    );
  }

  if (error && documents.length === 0) {
    return (
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <ErrorEmptyState onRetry={fetchDocuments} />
      </SafeAreaView>
    );
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
          <NoDocumentsEmptyState onAction={handleUpload} />
        }
      />

      {/* Upload FAB */}
      <TouchableOpacity
        style={[styles.fab, isUploading && styles.fabDisabled]}
        onPress={handleUpload}
        disabled={isUploading}
      >
        {isUploading ? (
          <ActivityIndicator size="small" color={colors.white} />
        ) : (
          <Ionicons name="add" size={28} color={colors.white} />
        )}
      </TouchableOpacity>
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
  fabDisabled: {
    opacity: 0.7,
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
