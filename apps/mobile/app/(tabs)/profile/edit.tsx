import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Alert,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter, Stack } from 'expo-router';
import { useAuth } from '../../../src/contexts/auth-context';
import { Card, Button, Input, ImageUpload } from '../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../src/lib/theme';
import { API_BASE_URL } from '../../../src/lib/api';
import { getIdToken } from '../../../src/lib/firebase';

export default function EditProfileScreen() {
  const router = useRouter();
  const { user, refreshMe } = useAuth();
  const [isSaving, setIsSaving] = useState(false);
  const [avatar, setAvatar] = useState<string | null>(user?.avatarUrl || null);

  const [formData, setFormData] = useState({
    firstName: user?.firstName || '',
    lastName: user?.lastName || '',
    email: user?.email || '',
    phone: user?.phone || '',
  });

  useEffect(() => {
    if (user) {
      setFormData({
        firstName: user.firstName || '',
        lastName: user.lastName || '',
        email: user.email || '',
        phone: user.phone || '',
      });
      setAvatar(user.avatarUrl || null);
    }
  }, [user]);

  const handleSave = async () => {
    if (!formData.firstName.trim()) {
      Alert.alert('Required', 'First name is required');
      return;
    }

    if (!formData.lastName.trim()) {
      Alert.alert('Required', 'Last name is required');
      return;
    }

    setIsSaving(true);
    try {
      const token = await getIdToken(true);
      if (!token) {
        Alert.alert('Error', 'Authentication expired. Please sign in again.');
        return;
      }

      const response = await fetch(`${API_BASE_URL}/users/profile`, {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          firstName: formData.firstName.trim(),
          lastName: formData.lastName.trim(),
          phone: formData.phone.trim() || null,
          avatarUrl: avatar,
        }),
      });

      if (!response.ok) {
        throw new Error('Failed to update profile');
      }

      await refreshMe();
      Alert.alert('Success', 'Profile updated successfully', [
        { text: 'OK', onPress: () => router.back() },
      ]);
    } catch (error) {
      console.error('Update profile error:', error);
      Alert.alert('Error', 'Failed to update profile. Please try again.');
    } finally {
      setIsSaving(false);
    }
  };

  const handleEmailChange = () => {
    Alert.alert(
      'Change Email',
      'To change your email address, please contact support. This helps protect your account security.',
      [{ text: 'OK' }]
    );
  };

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <Stack.Screen
        options={{
          title: 'Edit Profile',
          headerBackTitle: 'Profile',
        }}
      />
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.keyboardView}
      >
        <ScrollView
          contentContainerStyle={styles.scrollContent}
          showsVerticalScrollIndicator={false}
        >
          {/* Avatar */}
          <View style={styles.avatarSection}>
            <ImageUpload
              currentImage={avatar}
              onImageSelected={setAvatar}
              shape="circle"
              size="large"
              placeholder="Add Photo"
            />
            <Text style={styles.avatarHint}>Tap to change photo</Text>
          </View>

          {/* Personal Info */}
          <Card style={styles.card}>
            <Text style={styles.cardTitle}>Personal Information</Text>

            <Input
              label="First Name"
              value={formData.firstName}
              onChangeText={(v) => setFormData({ ...formData, firstName: v })}
              leftIcon="person-outline"
              placeholder="Enter first name"
              autoCapitalize="words"
            />

            <Input
              label="Last Name"
              value={formData.lastName}
              onChangeText={(v) => setFormData({ ...formData, lastName: v })}
              leftIcon="person-outline"
              placeholder="Enter last name"
              autoCapitalize="words"
            />

            <Input
              label="Email"
              value={formData.email}
              editable={false}
              leftIcon="mail-outline"
              rightIcon="lock-closed-outline"
              onPress={handleEmailChange}
              hint="Contact support to change email"
            />

            <Input
              label="Phone"
              value={formData.phone}
              onChangeText={(v) => setFormData({ ...formData, phone: v })}
              keyboardType="phone-pad"
              leftIcon="call-outline"
              placeholder="Enter phone number"
            />
          </Card>
        </ScrollView>

        {/* Footer Actions */}
        <View style={styles.footer}>
          <Button
            title="Cancel"
            variant="outline"
            onPress={() => router.back()}
            style={styles.cancelButton}
          />
          <Button
            title="Save Changes"
            onPress={handleSave}
            loading={isSaving}
            disabled={isSaving}
            style={styles.saveButton}
          />
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  keyboardView: {
    flex: 1,
  },
  scrollContent: {
    padding: spacing[4],
  },
  avatarSection: {
    alignItems: 'center',
    marginBottom: spacing[6],
  },
  avatarHint: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: spacing[2],
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
  saveButton: {
    flex: 1,
  },
});
