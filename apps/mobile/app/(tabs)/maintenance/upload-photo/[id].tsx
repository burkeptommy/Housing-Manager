import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  Image,
  ActivityIndicator,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter, useLocalSearchParams, Stack } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';
import { useAuth } from '../../../../src/contexts/auth-context';
import { Card, Button, Input, LoadingSpinner, Badge } from '../../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../../src/lib/theme';
import { API_BASE_URL } from '../../../../src/lib/api';
import { getIdToken } from '../../../../src/lib/firebase';

interface PhotoItem {
  id: string;
  uri: string;
  caption?: string;
  type: 'before' | 'after' | 'issue';
}

interface MaintenanceTask {
  id: string;
  title: string;
  category: string;
  status: string;
}

export default function UploadPhotoScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { householdInfo } = useAuth();
  const [isLoading, setIsLoading] = useState(true);
  const [isUploading, setIsUploading] = useState(false);
  const [task, setTask] = useState<MaintenanceTask | null>(null);
  const [photos, setPhotos] = useState<PhotoItem[]>([]);
  const [notes, setNotes] = useState('');
  const [photoType, setPhotoType] = useState<'before' | 'after' | 'issue'>('issue');

  const fetchTask = useCallback(async () => {
    if (!id || !householdInfo?.id) {
      setIsLoading(false);
      return;
    }

    try {
      const token = await getIdToken(true);
      if (!token) {
        setIsLoading(false);
        return;
      }

      const response = await fetch(`${API_BASE_URL}/maintenance-tasks/${id}`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });

      if (response.ok) {
        const data = await response.json();
        setTask(data);
      }
    } catch (err) {
      console.error('Fetch task error:', err);
    } finally {
      setIsLoading(false);
    }
  }, [id, householdInfo?.id]);

  useEffect(() => {
    fetchTask();
  }, [fetchTask]);

  const pickImage = async () => {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images'],
      allowsMultipleSelection: true,
      quality: 0.8,
      selectionLimit: 5 - photos.length,
    });

    if (!result.canceled && result.assets) {
      const newPhotos: PhotoItem[] = result.assets.map((asset, index) => ({
        id: `photo-${Date.now()}-${index}`,
        uri: asset.uri,
        type: photoType,
      }));
      setPhotos([...photos, ...newPhotos].slice(0, 5));
    }
  };

  const takePhoto = async () => {
    const { status } = await ImagePicker.requestCameraPermissionsAsync();
    if (status !== 'granted') {
      Alert.alert('Permission needed', 'Camera permission is required');
      return;
    }

    const result = await ImagePicker.launchCameraAsync({
      quality: 0.8,
      allowsEditing: true,
    });

    if (!result.canceled && result.assets[0]) {
      const newPhoto: PhotoItem = {
        id: `photo-${Date.now()}`,
        uri: result.assets[0].uri,
        type: photoType,
      };
      setPhotos([...photos, newPhoto].slice(0, 5));
    }
  };

  const removePhoto = (photoId: string) => {
    setPhotos(photos.filter((p) => p.id !== photoId));
  };

  const updatePhotoCaption = (photoId: string, caption: string) => {
    setPhotos(photos.map((p) =>
      p.id === photoId ? { ...p, caption } : p
    ));
  };

  const handleSubmit = async () => {
    if (photos.length === 0) {
      Alert.alert('Required', 'Please add at least one photo');
      return;
    }

    setIsUploading(true);
    try {
      const token = await getIdToken(true);
      if (!token) {
        Alert.alert('Error', 'Authentication expired');
        return;
      }

      // Upload each photo
      for (const photo of photos) {
        const formData = new FormData();
        formData.append('file', {
          uri: photo.uri,
          name: `maintenance_${id}_${photo.type}_${Date.now()}.jpg`,
          type: 'image/jpeg',
        } as any);
        formData.append('taskId', id!);
        formData.append('photoType', photo.type);
        if (photo.caption) {
          formData.append('caption', photo.caption);
        }
        if (notes) {
          formData.append('notes', notes);
        }

        await fetch(`${API_BASE_URL}/maintenance-tasks/${id}/photos`, {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${token}`,
          },
          body: formData,
        });
      }

      Alert.alert('Success', 'Photos uploaded successfully', [
        { text: 'OK', onPress: () => router.back() },
      ]);
    } catch (error) {
      console.error('Upload error:', error);
      Alert.alert('Error', 'Failed to upload photos. Please try again.');
    } finally {
      setIsUploading(false);
    }
  };

  if (isLoading) {
    return <LoadingSpinner fullScreen message="Loading..." />;
  }

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <Stack.Screen options={{ title: 'Upload Photos' }} />
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        {/* Task Info Header */}
        {task && (
          <Card style={styles.taskCard}>
            <View style={styles.taskHeader}>
              <View style={styles.taskIcon}>
                <Ionicons name="construct-outline" size={24} color={colors.haven.purple[500]} />
              </View>
              <View style={styles.taskInfo}>
                <Text style={styles.taskTitle} numberOfLines={1}>{task.title}</Text>
                <Text style={styles.taskCategory}>{task.category}</Text>
              </View>
              <Badge
                label={task.status === 'PENDING' ? 'Pending' : task.status}
                variant={task.status === 'COMPLETED' ? 'success' : 'warning'}
              />
            </View>
          </Card>
        )}

        {/* Photo Type Selection */}
        <Card style={styles.card}>
          <Text style={styles.cardTitle}>Photo Type</Text>
          <View style={styles.typeRow}>
            {(['before', 'issue', 'after'] as const).map((type) => (
              <TouchableOpacity
                key={type}
                style={[
                  styles.typeButton,
                  photoType === type && styles.typeButtonSelected,
                ]}
                onPress={() => setPhotoType(type)}
              >
                <Ionicons
                  name={type === 'before' ? 'arrow-back-circle' : type === 'after' ? 'arrow-forward-circle' : 'alert-circle'}
                  size={20}
                  color={photoType === type ? colors.haven.purple[500] : colors.text.secondary}
                />
                <Text
                  style={[
                    styles.typeLabel,
                    photoType === type && styles.typeLabelSelected,
                  ]}
                >
                  {type.charAt(0).toUpperCase() + type.slice(1)}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </Card>

        {/* Photo Upload Area */}
        <Card style={styles.card}>
          <Text style={styles.cardTitle}>Photos ({photos.length}/5)</Text>

          {/* Upload Buttons */}
          <View style={styles.uploadButtons}>
            <TouchableOpacity
              style={styles.uploadButton}
              onPress={takePhoto}
              disabled={photos.length >= 5}
            >
              <Ionicons name="camera" size={24} color={colors.haven.purple[500]} />
              <Text style={styles.uploadButtonText}>Take Photo</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.uploadButton}
              onPress={pickImage}
              disabled={photos.length >= 5}
            >
              <Ionicons name="images" size={24} color={colors.haven.purple[500]} />
              <Text style={styles.uploadButtonText}>Choose from Library</Text>
            </TouchableOpacity>
          </View>

          {/* Photo Grid */}
          {photos.length > 0 && (
            <View style={styles.photoGrid}>
              {photos.map((photo) => (
                <View key={photo.id} style={styles.photoItem}>
                  <Image source={{ uri: photo.uri }} style={styles.photoImage} />
                  <TouchableOpacity
                    style={styles.removeButton}
                    onPress={() => removePhoto(photo.id)}
                  >
                    <Ionicons name="close-circle" size={24} color={colors.status.error} />
                  </TouchableOpacity>
                  <View style={styles.photoTypeTag}>
                    <Text style={styles.photoTypeText}>{photo.type}</Text>
                  </View>
                  <Input
                    value={photo.caption || ''}
                    onChangeText={(v) => updatePhotoCaption(photo.id, v)}
                    placeholder="Add caption..."
                    containerStyle={styles.captionInput}
                  />
                </View>
              ))}
            </View>
          )}

          {photos.length === 0 && (
            <View style={styles.emptyPhotos}>
              <Ionicons name="image-outline" size={48} color={colors.haven.purple[300]} />
              <Text style={styles.emptyText}>No photos added yet</Text>
              <Text style={styles.emptySubtext}>Take or choose photos to document this task</Text>
            </View>
          )}
        </Card>

        {/* Notes */}
        <Card style={styles.card}>
          <Text style={styles.cardTitle}>Additional Notes</Text>
          <Input
            value={notes}
            onChangeText={setNotes}
            placeholder="Add any additional notes about these photos..."
            multiline
            numberOfLines={3}
          />
        </Card>
      </ScrollView>

      {/* Footer */}
      <View style={styles.footer}>
        <Button
          title="Cancel"
          variant="outline"
          onPress={() => router.back()}
          style={styles.cancelButton}
        />
        <Button
          title={isUploading ? 'Uploading...' : 'Upload Photos'}
          onPress={handleSubmit}
          loading={isUploading}
          disabled={isUploading || photos.length === 0}
          style={styles.submitButton}
        />
      </View>
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
  taskCard: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  taskHeader: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  taskIcon: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.purple[50],
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
  card: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  cardTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginBottom: spacing[4],
  },
  typeRow: {
    flexDirection: 'row',
    gap: spacing[2],
  },
  typeButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.border.default,
    backgroundColor: colors.white,
    gap: spacing[2],
  },
  typeButtonSelected: {
    borderColor: colors.haven.purple[500],
    backgroundColor: colors.haven.purple[50],
  },
  typeLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  typeLabelSelected: {
    color: colors.haven.purple[600],
    fontWeight: typography.fontWeights.medium,
  },
  uploadButtons: {
    flexDirection: 'row',
    gap: spacing[3],
    marginBottom: spacing[4],
  },
  uploadButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[2],
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.haven.purple[200],
    borderStyle: 'dashed',
    backgroundColor: colors.haven.purple[50],
  },
  uploadButtonText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[600],
    fontWeight: typography.fontWeights.medium,
  },
  photoGrid: {
    gap: spacing[4],
  },
  photoItem: {
    position: 'relative',
  },
  photoImage: {
    width: '100%',
    height: 200,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.gray[100],
  },
  removeButton: {
    position: 'absolute',
    top: spacing[2],
    right: spacing[2],
    backgroundColor: colors.white,
    borderRadius: 12,
  },
  photoTypeTag: {
    position: 'absolute',
    top: spacing[2],
    left: spacing[2],
    backgroundColor: colors.haven.purple[900],
    paddingHorizontal: spacing[2],
    paddingVertical: 2,
    borderRadius: borderRadius.sm,
  },
  photoTypeText: {
    fontSize: typography.fontSizes.xs,
    color: colors.white,
    fontWeight: typography.fontWeights.medium,
    textTransform: 'capitalize',
  },
  captionInput: {
    marginTop: spacing[2],
  },
  emptyPhotos: {
    alignItems: 'center',
    paddingVertical: spacing[8],
  },
  emptyText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
    marginTop: spacing[3],
  },
  emptySubtext: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: spacing[1],
    textAlign: 'center',
  },
  footer: {
    flexDirection: 'row',
    padding: spacing[4],
    backgroundColor: colors.white,
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
    gap: spacing[3],
  },
  cancelButton: {
    flex: 1,
  },
  submitButton: {
    flex: 1,
  },
});
