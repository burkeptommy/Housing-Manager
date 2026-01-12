import React, { useState } from 'react';
import {
  View,
  Text,
  Image,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  showImageOptions,
  uploadProfileImage,
  removeProfileImage,
  EntityType,
} from '../lib/image-upload';

interface ProfilePhotoEditorProps {
  currentUrl?: string | null;
  entityType: EntityType;
  entityId: string;
  size?: number;
  name?: string; // For initials fallback
  onPhotoUpdated?: (newUrl: string | null) => void;
}

export function ProfilePhotoEditor({
  currentUrl,
  entityType,
  entityId,
  size = 100,
  name,
  onPhotoUpdated,
}: ProfilePhotoEditorProps) {
  const [isUploading, setIsUploading] = useState(false);
  const [photoUrl, setPhotoUrl] = useState(currentUrl);

  // Sync with prop changes
  React.useEffect(() => {
    setPhotoUrl(currentUrl);
  }, [currentUrl]);

  const getInitials = () => {
    if (!name) return '?';
    const parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
    }
    return parts[0][0]?.toUpperCase() || '?';
  };

  const handleImageSelected = async (uri: string) => {
    if (!uri) {
      // Remove photo
      setIsUploading(true);
      try {
        await removeProfileImage(entityType, entityId);
        setPhotoUrl(null);
        onPhotoUpdated?.(null);
      } catch (error) {
        console.error('Remove photo error:', error);
        Alert.alert('Error', 'Failed to remove photo');
      } finally {
        setIsUploading(false);
      }
      return;
    }

    // Upload new photo
    setIsUploading(true);
    try {
      const newUrl = await uploadProfileImage(entityType, entityId, uri);
      setPhotoUrl(newUrl);
      onPhotoUpdated?.(newUrl);
    } catch (error) {
      console.error('Upload error:', error);
      Alert.alert('Error', 'Failed to upload photo');
    } finally {
      setIsUploading(false);
    }
  };

  const handlePress = () => {
    showImageOptions(handleImageSelected, photoUrl || undefined);
  };

  return (
    <TouchableOpacity
      style={[
        styles.container,
        { width: size, height: size, borderRadius: size / 2 },
      ]}
      onPress={handlePress}
      disabled={isUploading}
    >
      {photoUrl ? (
        <Image
          source={{ uri: photoUrl }}
          style={[
            styles.image,
            { width: size, height: size, borderRadius: size / 2 },
          ]}
        />
      ) : (
        <View
          style={[
            styles.placeholder,
            { width: size, height: size, borderRadius: size / 2 },
          ]}
        >
          <Text style={[styles.initials, { fontSize: size / 2.5 }]}>
            {getInitials()}
          </Text>
        </View>
      )}

      {/* Upload overlay */}
      {isUploading && (
        <View style={[styles.uploadingOverlay, { borderRadius: size / 2 }]}>
          <ActivityIndicator color="#ffffff" />
        </View>
      )}

      {/* Edit badge */}
      <View style={styles.editBadge}>
        <Ionicons name="camera" size={14} color="#ffffff" />
      </View>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  container: {
    position: 'relative',
  },
  image: {
    backgroundColor: '#e2e8f0',
  },
  placeholder: {
    backgroundColor: '#c4a574',
    alignItems: 'center',
    justifyContent: 'center',
  },
  initials: {
    color: '#ffffff',
    fontWeight: '600',
  },
  uploadingOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  editBadge: {
    position: 'absolute',
    bottom: 0,
    right: 0,
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: '#0f172a',
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 2,
    borderColor: '#ffffff',
  },
});
