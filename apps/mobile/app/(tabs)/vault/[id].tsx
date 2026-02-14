import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  RefreshControl,
  Share,
  Linking,
  Image,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useLocalSearchParams, useRouter, Stack } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import * as WebBrowser from 'expo-web-browser';
import { useAuth } from '../../../src/contexts/auth-context';
import { Card, Badge, Button, LoadingSpinner } from '../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../src/lib/theme';
import { API_BASE_URL } from '../../../src/lib/api';
import { getIdToken } from '../../../src/lib/firebase';

interface DocumentDetail {
  id: string;
  title: string;
  category: string;
  subcategory?: string | null;
  description?: string | null;
  fileUrl?: string;
  storageUrl?: string;
  downloadUrl?: string;
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
}

const CATEGORY_ICONS: Record<string, string> = {
  'PROPERTY': 'home-outline',
  'INSURANCE': 'shield-outline',
  'WARRANTY': 'document-text-outline',
  'MANUAL': 'book-outline',
  'TAX': 'calculator-outline',
  'CONTRACT': 'create-outline',
  'RECEIPT': 'receipt-outline',
  'PERMIT': 'ribbon-outline',
  'MAINTENANCE': 'construct-outline',
  'OTHER': 'document-outline',
  'default': 'document-outline',
};

export default function DocumentDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { householdInfo } = useAuth();
  const [document, setDocument] = useState<DocumentDetail | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [isProcessing, setIsProcessing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchDocument = useCallback(async () => {
    if (!id) return;

    try {
      const token = await getIdToken(true);
      if (!token) {
        setError('Authentication expired.');
        setIsLoading(false);
        return;
      }

      const response = await fetch(`${API_BASE_URL}/documents/${id}`, {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`Failed to fetch document: ${response.status}`);
      }

      const data: DocumentDetail = await response.json();
      // Normalize URL field - API returns storageUrl/downloadUrl, not fileUrl
      if (!data.fileUrl) {
        data.fileUrl = data.downloadUrl || data.storageUrl;
      }
      setDocument(data);
      setError(null);
    } catch (err) {
      console.error('Fetch document error:', err);
      setError('Failed to load document details.');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [id]);

  useEffect(() => {
    fetchDocument();
  }, [fetchDocument]);

  const handleView = async () => {
    if (!document?.fileUrl) return;
    try {
      await WebBrowser.openBrowserAsync(document.fileUrl);
    } catch (err) {
      Alert.alert('Error', 'Could not open document.');
    }
  };

  const handleShare = async () => {
    if (!document?.fileUrl) return;
    try {
      await Share.share({
        message: `${document.title}\n${document.fileUrl}`,
        url: document.fileUrl,
      });
    } catch (err) {
      Alert.alert('Error', 'Could not share document.');
    }
  };

  const handleDownload = async () => {
    if (!document?.fileUrl) return;
    try {
      await Linking.openURL(document.fileUrl);
    } catch (err) {
      Alert.alert('Error', 'Could not download document.');
    }
  };

  const handleDelete = async () => {
    Alert.alert(
      'Delete Document',
      'Are you sure you want to delete this document? This cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            setIsProcessing(true);
            try {
              const token = await getIdToken(true);
              if (!token) {
                Alert.alert('Error', 'Authentication expired.');
                return;
              }

              const response = await fetch(`${API_BASE_URL}/documents/${id}`, {
                method: 'DELETE',
                headers: {
                  Authorization: `Bearer ${token}`,
                },
              });

              if (!response.ok) throw new Error('Failed to delete');

              Alert.alert('Deleted', 'Document has been deleted.');
              router.back();
            } catch (err) {
              Alert.alert('Error', 'Failed to delete document.');
            } finally {
              setIsProcessing(false);
            }
          },
        },
      ]
    );
  };

  const formatFileSize = (bytes: number): string => {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      weekday: 'long',
      month: 'long',
      day: 'numeric',
      year: 'numeric',
    });
  };

  const isExpiringSoon = (expiresAt?: string | null) => {
    if (!expiresAt) return false;
    const daysUntilExpiry = Math.ceil(
      (new Date(expiresAt).getTime() - Date.now()) / (1000 * 60 * 60 * 24)
    );
    return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
  };

  const isExpired = (expiresAt?: string | null) => {
    if (!expiresAt) return false;
    return new Date(expiresAt) < new Date();
  };

  const getFileIcon = (mimeType: string) => {
    if (mimeType.includes('pdf')) return 'document-text';
    if (mimeType.includes('image')) return 'image';
    if (mimeType.includes('word') || mimeType.includes('doc')) return 'document';
    if (mimeType.includes('excel') || mimeType.includes('sheet')) return 'grid';
    return 'document-outline';
  };

  const isImageFile = (mimeType: string) => mimeType.includes('image');

  if (isLoading) {
    return <LoadingSpinner fullScreen message="Loading document..." />;
  }

  if (error || !document) {
    return (
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <Stack.Screen options={{ title: 'Document' }} />
        <View style={styles.errorContainer}>
          <Ionicons name="alert-circle" size={48} color={colors.status.error} />
          <Text style={styles.errorTitle}>Unable to Load Document</Text>
          <Text style={styles.errorText}>{error || 'Document not found'}</Text>
          <TouchableOpacity style={styles.retryButton} onPress={fetchDocument}>
            <Text style={styles.retryText}>Try Again</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  const uploaderName = document.uploadedBy
    ? `${document.uploadedBy.firstName || ''} ${document.uploadedBy.lastName || ''}`.trim() || 'Unknown'
    : 'Unknown';

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <Stack.Screen
        options={{
          title: 'Document',
          headerRight: () => (
            <TouchableOpacity onPress={() => Alert.alert('Edit', 'Edit metadata coming soon')}>
              <Ionicons name="create-outline" size={24} color={colors.haven.purple[500]} />
            </TouchableOpacity>
          ),
        }}
      />
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        refreshControl={
          <RefreshControl refreshing={isRefreshing} onRefresh={() => {
            setIsRefreshing(true);
            fetchDocument();
          }} />
        }
      >
        {/* Preview */}
        <Card style={styles.previewCard}>
          {isImageFile(document.mimeType) ? (
            <Image source={{ uri: document.fileUrl }} style={styles.imagePreview} resizeMode="contain" />
          ) : (
            <View style={styles.fileIconContainer}>
              <Ionicons name={getFileIcon(document.mimeType) as any} size={64} color={colors.haven.purple[500]} />
              <Text style={styles.fileType}>{document.mimeType.split('/')[1]?.toUpperCase() || 'FILE'}</Text>
            </View>
          )}
          <TouchableOpacity style={styles.viewButton} onPress={handleView}>
            <Ionicons name="eye-outline" size={20} color={colors.white} />
            <Text style={styles.viewButtonText}>View Document</Text>
          </TouchableOpacity>
        </Card>

        {/* Info */}
        <Card style={styles.section}>
          <Text style={styles.documentTitle}>{document.title}</Text>
          <View style={styles.badgeRow}>
            <Badge label={document.category} variant="default" />
            {document.expiresAt && (
              <Badge
                label={isExpired(document.expiresAt) ? 'Expired' : isExpiringSoon(document.expiresAt) ? 'Expiring Soon' : 'Valid'}
                variant={isExpired(document.expiresAt) ? 'error' : isExpiringSoon(document.expiresAt) ? 'warning' : 'success'}
              />
            )}
          </View>
          {document.description && (
            <Text style={styles.description}>{document.description}</Text>
          )}
        </Card>

        {/* Details */}
        <Card style={styles.section}>
          <Text style={styles.sectionTitle}>Details</Text>

          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>File Name</Text>
            <Text style={styles.detailValue}>{document.fileName}</Text>
          </View>

          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>File Size</Text>
            <Text style={styles.detailValue}>{formatFileSize(document.fileSize)}</Text>
          </View>

          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>Upload Date</Text>
            <Text style={styles.detailValue}>{formatDate(document.createdAt)}</Text>
          </View>

          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>Uploaded By</Text>
            <Text style={styles.detailValue}>{uploaderName}</Text>
          </View>

          {document.expiresAt && (
            <View style={styles.detailRow}>
              <Text style={styles.detailLabel}>Expiration Date</Text>
              <Text style={[styles.detailValue, isExpired(document.expiresAt) && { color: colors.status.error }]}>
                {formatDate(document.expiresAt)}
              </Text>
            </View>
          )}

          {document.tags && document.tags.length > 0 && (
            <View style={styles.tagsContainer}>
              <Text style={styles.detailLabel}>Tags</Text>
              <View style={styles.tags}>
                {document.tags.map((tag, index) => (
                  <View key={index} style={styles.tag}>
                    <Text style={styles.tagText}>{tag}</Text>
                  </View>
                ))}
              </View>
            </View>
          )}
        </Card>

        {/* Actions */}
        <View style={styles.actionButtons}>
          <TouchableOpacity style={styles.actionButton} onPress={handleShare}>
            <Ionicons name="share-outline" size={24} color={colors.haven.purple[700]} />
            <Text style={styles.actionButtonText}>Share</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.actionButton} onPress={handleDownload}>
            <Ionicons name="download-outline" size={24} color={colors.haven.purple[700]} />
            <Text style={styles.actionButtonText}>Download</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.actionButton} onPress={handleDelete}>
            <Ionicons name="trash-outline" size={24} color={colors.status.error} />
            <Text style={[styles.actionButtonText, { color: colors.status.error }]}>Delete</Text>
          </TouchableOpacity>
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
  previewCard: {
    alignItems: 'center',
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  imagePreview: {
    width: '100%',
    height: 200,
    borderRadius: borderRadius.lg,
    marginBottom: spacing[4],
  },
  fileIconContainer: {
    width: '100%',
    height: 160,
    backgroundColor: colors.haven.purple[50],
    borderRadius: borderRadius.lg,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[4],
  },
  fileType: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.purple[600],
    marginTop: spacing[2],
  },
  viewButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.haven.purple[900],
    paddingVertical: spacing[3],
    paddingHorizontal: spacing[5],
    borderRadius: borderRadius.lg,
    gap: spacing[2],
  },
  viewButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  section: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  documentTitle: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
    marginBottom: spacing[2],
  },
  badgeRow: {
    flexDirection: 'row',
    gap: spacing[2],
    marginBottom: spacing[3],
  },
  description: {
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
    lineHeight: 22,
  },
  sectionTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.secondary,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    marginBottom: spacing[3],
  },
  detailRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: spacing[3],
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
    textAlign: 'right',
    flex: 1,
    marginLeft: spacing[4],
  },
  tagsContainer: {
    paddingTop: spacing[3],
  },
  tags: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[2],
    marginTop: spacing[2],
  },
  tag: {
    backgroundColor: colors.haven.purple[100],
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[1],
    borderRadius: borderRadius.full,
  },
  tagText: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.purple[600],
  },
  actionButtons: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    backgroundColor: colors.white,
    borderRadius: borderRadius.lg,
    padding: spacing[4],
  },
  actionButton: {
    alignItems: 'center',
    gap: spacing[1],
  },
  actionButtonText: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.purple[700],
    fontWeight: typography.fontWeights.medium,
  },
});
