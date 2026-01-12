# M12-7: PROFILE PICTURE UPLOADS FOR ALL ENTITIES

## CRITICAL INSTRUCTIONS

Users must be able to upload profile pictures for:
- Family members (adults, children)
- Pets
- Household staff
- The property itself

**DO NOT** claim this works. Test by actually trying to upload a photo in the simulator.

---

## PROBLEM STATEMENT

Currently there is no way to upload or change profile pictures for:
1. Family members - stuck with initials placeholders
2. Pets - no photo capability
3. Staff - no photo capability
4. Property - no main property photo

---

## REQUIRED DELIVERABLES

### 1. Install Required Packages

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Image picker
npx expo install expo-image-picker

# If not already installed
npx expo install expo-file-system
```

### 2. Add Photo URL Fields to Database

**File:** `apps/api/prisma/schema.prisma`

Ensure these models have photo fields:

```prisma
model FamilyMember {
  // ... existing fields
  profilePhotoUrl   String?
}

model Pet {
  // ... existing fields
  photoUrl          String?
}

model HouseholdStaff {
  // ... existing fields
  photoUrl          String?
}

model Household {
  // ... existing fields
  propertyPhotoUrl  String?
}
```

Run migration if fields don't exist:
```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/api
pnpm prisma migrate dev --name add-photo-urls
pnpm prisma generate
```

### 3. Create Image Upload Service

**File:** `apps/mobile/src/lib/image-upload.ts`

```typescript
import * as ImagePicker from 'expo-image-picker';
import * as FileSystem from 'expo-file-system';
import { API_BASE_URL } from './api';
import { getIdToken } from './firebase';
import { Alert, Platform } from 'react-native';

export type EntityType = 'family-member' | 'pet' | 'staff' | 'household';

/**
 * Request camera permissions
 */
export async function requestCameraPermission(): Promise<boolean> {
  const { status } = await ImagePicker.requestCameraPermissionsAsync();
  if (status !== 'granted') {
    Alert.alert(
      'Permission Required',
      'Camera access is needed to take photos.',
      [{ text: 'OK' }]
    );
    return false;
  }
  return true;
}

/**
 * Request media library permissions
 */
export async function requestMediaLibraryPermission(): Promise<boolean> {
  const { status } = await ImagePicker.requestMediaLibraryPermissionsAsync();
  if (status !== 'granted') {
    Alert.alert(
      'Permission Required',
      'Photo library access is needed to select photos.',
      [{ text: 'OK' }]
    );
    return false;
  }
  return true;
}

/**
 * Open image picker to select from library
 */
export async function pickImage(): Promise<string | null> {
  const hasPermission = await requestMediaLibraryPermission();
  if (!hasPermission) return null;

  const result = await ImagePicker.launchImageLibraryAsync({
    mediaTypes: ImagePicker.MediaTypeOptions.Images,
    allowsEditing: true,
    aspect: [1, 1],
    quality: 0.8,
  });

  if (result.canceled) return null;
  return result.assets[0].uri;
}

/**
 * Open camera to take a photo
 */
export async function takePhoto(): Promise<string | null> {
  const hasPermission = await requestCameraPermission();
  if (!hasPermission) return null;

  const result = await ImagePicker.launchCameraAsync({
    allowsEditing: true,
    aspect: [1, 1],
    quality: 0.8,
  });

  if (result.canceled) return null;
  return result.assets[0].uri;
}

/**
 * Show action sheet to pick or take photo
 */
export async function showImageOptions(
  onImageSelected: (uri: string) => void,
  currentPhotoUrl?: string
): Promise<void> {
  const options = ['Take Photo', 'Choose from Library', 'Cancel'];
  
  if (currentPhotoUrl) {
    options.unshift('Remove Photo');
  }

  Alert.alert(
    'Profile Photo',
    'Choose an option',
    options.map((option, index) => {
      if (option === 'Cancel') {
        return { text: option, style: 'cancel' };
      }
      if (option === 'Remove Photo') {
        return { 
          text: option, 
          style: 'destructive',
          onPress: () => onImageSelected(''),
        };
      }
      if (option === 'Take Photo') {
        return {
          text: option,
          onPress: async () => {
            const uri = await takePhoto();
            if (uri) onImageSelected(uri);
          },
        };
      }
      if (option === 'Choose from Library') {
        return {
          text: option,
          onPress: async () => {
            const uri = await pickImage();
            if (uri) onImageSelected(uri);
          },
        };
      }
      return { text: option };
    })
  );
}

/**
 * Upload image to server
 */
export async function uploadProfileImage(
  entityType: EntityType,
  entityId: string,
  imageUri: string
): Promise<string> {
  const token = await getIdToken(true);
  if (!token) throw new Error('Not authenticated');

  // Read the file as base64
  const base64 = await FileSystem.readAsStringAsync(imageUri, {
    encoding: FileSystem.EncodingType.Base64,
  });

  // Upload to server
  const response = await fetch(`${API_BASE_URL}/uploads/profile-image`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      entityType,
      entityId,
      image: base64,
      mimeType: 'image/jpeg',
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Upload failed: ${error}`);
  }

  const data = await response.json();
  return data.imageUrl;
}

/**
 * Remove profile image
 */
export async function removeProfileImage(
  entityType: EntityType,
  entityId: string
): Promise<void> {
  const token = await getIdToken(true);
  if (!token) throw new Error('Not authenticated');

  const response = await fetch(`${API_BASE_URL}/uploads/profile-image`, {
    method: 'DELETE',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ entityType, entityId }),
  });

  if (!response.ok) {
    throw new Error('Failed to remove image');
  }
}
```

### 4. Create Upload API Endpoint

**File:** `apps/api/src/uploads/uploads.controller.ts`

```typescript
import { Controller, Post, Delete, Body, UseGuards } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { FirebaseAuthGuard } from '../firebase';
import { Storage } from '@google-cloud/storage';
import { v4 as uuidv4 } from 'uuid';

@Controller('uploads')
@UseGuards(FirebaseAuthGuard)
export class UploadsController {
  private storage: Storage;
  private bucketName: string;

  constructor(private prisma: PrismaService) {
    // Initialize GCS if credentials exist
    if (process.env.GCS_BUCKET) {
      this.storage = new Storage();
      this.bucketName = process.env.GCS_BUCKET;
    }
  }

  @Post('profile-image')
  async uploadProfileImage(
    @Body() body: {
      entityType: 'family-member' | 'pet' | 'staff' | 'household';
      entityId: string;
      image: string; // base64
      mimeType: string;
    },
  ) {
    const { entityType, entityId, image, mimeType } = body;
    
    let imageUrl: string;

    if (this.storage && this.bucketName) {
      // Upload to Google Cloud Storage
      const filename = `profiles/${entityType}/${entityId}-${uuidv4()}.jpg`;
      const bucket = this.storage.bucket(this.bucketName);
      const blob = bucket.file(filename);
      
      const buffer = Buffer.from(image, 'base64');
      await blob.save(buffer, {
        contentType: mimeType || 'image/jpeg',
        public: true,
      });
      
      imageUrl = `https://storage.googleapis.com/${this.bucketName}/${filename}`;
    } else {
      // Fallback: Store as data URL (for development/testing)
      imageUrl = `data:${mimeType};base64,${image.substring(0, 100)}...`; // Truncated for demo
      // In real implementation, save to local file or use a different storage
      console.warn('No GCS bucket configured, using placeholder');
      imageUrl = `https://ui-avatars.com/api/?name=${entityId}&background=c4a574&color=fff`;
    }

    // Update the entity with the new image URL
    switch (entityType) {
      case 'family-member':
        await this.prisma.familyMember.update({
          where: { id: entityId },
          data: { profilePhotoUrl: imageUrl },
        });
        break;
      case 'pet':
        await this.prisma.pet.update({
          where: { id: entityId },
          data: { photoUrl: imageUrl },
        });
        break;
      case 'staff':
        await this.prisma.householdStaff.update({
          where: { id: entityId },
          data: { photoUrl: imageUrl },
        });
        break;
      case 'household':
        await this.prisma.household.update({
          where: { id: entityId },
          data: { propertyPhotoUrl: imageUrl },
        });
        break;
    }

    return { imageUrl };
  }

  @Delete('profile-image')
  async removeProfileImage(
    @Body() body: {
      entityType: 'family-member' | 'pet' | 'staff' | 'household';
      entityId: string;
    },
  ) {
    const { entityType, entityId } = body;

    // Remove URL from entity
    switch (entityType) {
      case 'family-member':
        await this.prisma.familyMember.update({
          where: { id: entityId },
          data: { profilePhotoUrl: null },
        });
        break;
      case 'pet':
        await this.prisma.pet.update({
          where: { id: entityId },
          data: { photoUrl: null },
        });
        break;
      case 'staff':
        await this.prisma.householdStaff.update({
          where: { id: entityId },
          data: { photoUrl: null },
        });
        break;
      case 'household':
        await this.prisma.household.update({
          where: { id: entityId },
          data: { propertyPhotoUrl: null },
        });
        break;
    }

    return { success: true };
  }
}
```

Create module:
```typescript
// apps/api/src/uploads/uploads.module.ts
import { Module } from '@nestjs/common';
import { UploadsController } from './uploads.controller';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [UploadsController],
})
export class UploadsModule {}
```

### 5. Create Reusable ProfilePhotoEditor Component

**File:** `apps/mobile/src/components/ProfilePhotoEditor.tsx`

```tsx
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

  const getInitials = () => {
    if (!name) return '?';
    const parts = name.split(' ');
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
      style={[styles.container, { width: size, height: size, borderRadius: size / 2 }]}
      onPress={handlePress}
      disabled={isUploading}
    >
      {photoUrl ? (
        <Image 
          source={{ uri: photoUrl }} 
          style={[styles.image, { width: size, height: size, borderRadius: size / 2 }]}
        />
      ) : (
        <View style={[styles.placeholder, { width: size, height: size, borderRadius: size / 2 }]}>
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
```

### 6. Integrate into Family Member Detail Screen

**File:** `apps/mobile/app/(tabs)/family/[id].tsx`

Add the ProfilePhotoEditor to the top:

```tsx
import { ProfilePhotoEditor } from '../../../src/components/ProfilePhotoEditor';

// In the component
<View style={styles.photoSection}>
  <ProfilePhotoEditor
    currentUrl={member.profilePhotoUrl}
    entityType="family-member"
    entityId={member.id}
    size={120}
    name={`${member.firstName} ${member.lastName}`}
    onPhotoUpdated={(url) => {
      setMember({ ...member, profilePhotoUrl: url });
    }}
  />
  <Text style={styles.photoHint}>Tap to change photo</Text>
</View>
```

Add styles:
```typescript
photoSection: {
  alignItems: 'center',
  marginBottom: 24,
},
photoHint: {
  fontSize: 12,
  color: '#94a3b8',
  marginTop: 8,
},
```

### 7. Add to Other Screens

Similarly add ProfilePhotoEditor to:
- Pet detail screen
- Staff detail screen  
- Property/Household settings screen

---

## VERIFICATION STEPS

1. **Navigate to Family Member**
   - Go to Family → Tap on a member
   - Verify profile photo area is visible with camera icon

2. **Take a Photo**
   - Tap the photo area
   - Select "Take Photo"
   - Grant camera permission
   - Take a photo
   - Verify loading indicator shows
   - Verify photo appears

3. **Choose from Library**
   - Tap the photo area
   - Select "Choose from Library"
   - Select a photo
   - Verify photo appears

4. **Remove Photo**
   - Tap the photo area
   - Select "Remove Photo"
   - Verify it reverts to initials

5. **Test on Pets/Staff**
   - Navigate to a pet detail
   - Verify photo upload works

---

## SUCCESS CRITERIA

- [ ] Camera icon badge visible on profile photos
- [ ] Tapping shows Take Photo / Choose from Library options
- [ ] Can take a photo with camera
- [ ] Can choose from photo library
- [ ] Photo uploads and displays
- [ ] Can remove photo
- [ ] Works for family members
- [ ] Works for pets (if pet screen exists)
