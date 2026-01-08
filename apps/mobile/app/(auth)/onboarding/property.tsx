import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
} from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useOnboarding } from '../../../src/contexts/onboarding-context';
import { useAuth } from '../../../src/contexts/auth-context';
import { Button, Card, Badge, Input } from '../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../src/lib/theme';
import { getApiClient } from '../../../src/lib/api';

export default function OnboardingPropertyScreen() {
  const router = useRouter();
  const { user } = useAuth();
  const { propertyData, setPropertyData, setHouseholdId, attomError, setStep } = useOnboarding();
  const [isLoading, setIsLoading] = useState(false);
  const [isEditing, setIsEditing] = useState(false);

  // Local state for editing
  const [editedData, setEditedData] = useState(propertyData);

  const handleSave = async () => {
    if (!editedData || !user) {
      Alert.alert('Error', 'Missing property data or user');
      return;
    }

    setIsLoading(true);

    try {
      const api = getApiClient();

      // Create household
      const household = await api.createHousehold({
        name: `${editedData.city} Home`,
        description: `${editedData.addressLine1}, ${editedData.city}, ${editedData.state}`,
      });

      setHouseholdId(household.id);

      // Create home profile
      await api.upsertHomeProfile(household.id, {
        propertyType: editedData.propertyType as any,
        addressLine1: editedData.addressLine1,
        city: editedData.city,
        state: editedData.state,
        postalCode: editedData.postalCode,
        country: 'US',
        yearBuilt: editedData.yearBuilt,
        squareFeet: editedData.squareFeet,
        bedrooms: editedData.bedrooms,
        bathrooms: editedData.bathrooms,
        notes: JSON.stringify({
          lotSize: editedData.lotSize,
          hvacType: editedData.hvacType,
          heatingFuel: editedData.heatingFuel,
          hasPool: editedData.hasPool,
          hasFireplace: editedData.hasFireplace,
          roofType: editedData.roofType,
          utilities: {
            electric: editedData.electricProvider,
            gas: editedData.gasProvider,
            water: editedData.waterProvider,
            trash: editedData.trashProvider,
          },
        }),
      });

      // Update context and navigate
      setPropertyData(editedData);
      setStep('bank');
      router.push('/(auth)/onboarding/bank');
    } catch (err: any) {
      console.error('Save property error:', err);
      Alert.alert('Error', err.message || 'Failed to save property');
    } finally {
      setIsLoading(false);
    }
  };

  const formatValue = (value: any, suffix?: string) => {
    if (value === null || value === undefined) return 'Not detected';
    if (suffix) return `${value.toLocaleString()}${suffix}`;
    return value.toString();
  };

  if (!propertyData || !editedData) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.emptyState}>
          <Ionicons name="home-outline" size={48} color={colors.text.tertiary} />
          <Text style={styles.emptyTitle}>No property data found</Text>
          <Button
            title="Go Back"
            onPress={() => router.back()}
            variant="outline"
          />
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        {/* Progress */}
        <View style={styles.progress}>
          <View style={styles.progressBar}>
            <View style={[styles.progressFill, { width: '40%' }]} />
          </View>
          <Text style={styles.progressText}>Step 2 of 5</Text>
        </View>

        {/* Header */}
        <View style={styles.header}>
          <Text style={styles.title}>Confirm your property</Text>
          <Text style={styles.subtitle}>
            We found the following details about your home
          </Text>
        </View>

        {/* ATTOM Warning if applicable */}
        {attomError && (
          <View style={styles.warningBox}>
            <Ionicons name="alert-circle" size={20} color={colors.status.warning} />
            <Text style={styles.warningText}>{attomError}</Text>
          </View>
        )}

        {/* Property Card */}
        <Card style={styles.propertyCard}>
          <View style={styles.addressHeader}>
            <Ionicons name="home" size={24} color={colors.haven.navy[900]} />
            <View style={styles.addressText}>
              <Text style={styles.addressLine}>{editedData.addressLine1}</Text>
              <Text style={styles.cityState}>
                {editedData.city}, {editedData.state} {editedData.postalCode}
              </Text>
            </View>
            <Badge label="Verified" variant="success" />
          </View>
        </Card>

        {/* Property Details */}
        <Card style={styles.detailsCard}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Property Details</Text>
            <TouchableOpacity onPress={() => setIsEditing(!isEditing)}>
              <Text style={styles.editButton}>
                {isEditing ? 'Done' : 'Edit'}
              </Text>
            </TouchableOpacity>
          </View>

          {isEditing ? (
            <View style={styles.editForm}>
              <Input
                label="Year Built"
                value={editedData.yearBuilt?.toString() || ''}
                onChangeText={(v) =>
                  setEditedData({ ...editedData, yearBuilt: parseInt(v) || undefined })
                }
                keyboardType="number-pad"
              />
              <Input
                label="Square Feet"
                value={editedData.squareFeet?.toString() || ''}
                onChangeText={(v) =>
                  setEditedData({ ...editedData, squareFeet: parseInt(v) || undefined })
                }
                keyboardType="number-pad"
              />
              <View style={styles.row}>
                <Input
                  label="Bedrooms"
                  value={editedData.bedrooms?.toString() || ''}
                  onChangeText={(v) =>
                    setEditedData({ ...editedData, bedrooms: parseInt(v) || undefined })
                  }
                  keyboardType="number-pad"
                  containerStyle={{ flex: 1 }}
                />
                <Input
                  label="Bathrooms"
                  value={editedData.bathrooms?.toString() || ''}
                  onChangeText={(v) =>
                    setEditedData({ ...editedData, bathrooms: parseFloat(v) || undefined })
                  }
                  keyboardType="decimal-pad"
                  containerStyle={{ flex: 1 }}
                />
              </View>
            </View>
          ) : (
            <View style={styles.detailsGrid}>
              <DetailItem label="Type" value={editedData.propertyType?.replace('_', ' ')} />
              <DetailItem label="Year Built" value={formatValue(editedData.yearBuilt)} />
              <DetailItem
                label="Square Feet"
                value={formatValue(editedData.squareFeet, ' sqft')}
              />
              <DetailItem label="Bedrooms" value={formatValue(editedData.bedrooms)} />
              <DetailItem label="Bathrooms" value={formatValue(editedData.bathrooms)} />
              <DetailItem label="Lot Size" value={formatValue(editedData.lotSize, ' acres')} />
            </View>
          )}
        </Card>

        {/* Systems & Features */}
        <Card style={styles.detailsCard}>
          <Text style={styles.sectionTitle}>Systems & Features</Text>
          <View style={styles.detailsGrid}>
            <DetailItem label="HVAC" value={formatValue(editedData.hvacType)} />
            <DetailItem label="Heating" value={formatValue(editedData.heatingFuel)} />
            <DetailItem label="Pool" value={editedData.hasPool ? 'Yes' : 'No'} />
            <DetailItem label="Fireplace" value={editedData.hasFireplace ? 'Yes' : 'No'} />
            <DetailItem label="Roof" value={formatValue(editedData.roofType)} />
          </View>
        </Card>

        {/* Utilities */}
        {(editedData.electricProvider ||
          editedData.gasProvider ||
          editedData.waterProvider) && (
          <Card style={styles.detailsCard}>
            <Text style={styles.sectionTitle}>Local Utilities</Text>
            <View style={styles.detailsGrid}>
              {editedData.electricProvider && (
                <DetailItem
                  label="Electric"
                  value={editedData.electricProvider}
                  icon="flash-outline"
                />
              )}
              {editedData.gasProvider && (
                <DetailItem
                  label="Gas"
                  value={editedData.gasProvider}
                  icon="flame-outline"
                />
              )}
              {editedData.waterProvider && (
                <DetailItem
                  label="Water"
                  value={editedData.waterProvider}
                  icon="water-outline"
                />
              )}
            </View>
          </Card>
        )}

        {/* Continue Button */}
        <Button
          title={isLoading ? 'Saving...' : 'Looks Good!'}
          onPress={handleSave}
          loading={isLoading}
          fullWidth
          style={styles.continueButton}
        />

        <Button
          title="Go Back"
          onPress={() => router.back()}
          variant="ghost"
          fullWidth
        />
      </ScrollView>
    </SafeAreaView>
  );
}

// Detail item component
function DetailItem({
  label,
  value,
  icon,
}: {
  label: string;
  value: string;
  icon?: string;
}) {
  const isDetected = value !== 'Not detected';

  return (
    <View style={detailStyles.item}>
      {icon && (
        <Ionicons
          name={icon as any}
          size={16}
          color={colors.haven.champagne[500]}
          style={detailStyles.icon}
        />
      )}
      <Text style={detailStyles.label}>{label}</Text>
      <Text style={[detailStyles.value, !isDetected && detailStyles.notDetected]}>
        {value}
      </Text>
    </View>
  );
}

const detailStyles = StyleSheet.create({
  item: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  icon: {
    marginRight: spacing[2],
  },
  label: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  value: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  notDetected: {
    color: colors.text.tertiary,
    fontStyle: 'italic',
  },
});

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  scrollContent: {
    padding: spacing[5],
    paddingBottom: spacing[8],
  },
  emptyState: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing[8],
    gap: spacing[4],
  },
  emptyTitle: {
    fontSize: typography.fontSizes.lg,
    color: colors.text.secondary,
  },
  progress: {
    marginBottom: spacing[4],
  },
  progressBar: {
    height: 4,
    backgroundColor: colors.haven.navy[100],
    borderRadius: 2,
    marginBottom: spacing[2],
  },
  progressFill: {
    height: '100%',
    backgroundColor: colors.haven.champagne[500],
    borderRadius: 2,
  },
  progressText: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    textAlign: 'center',
  },
  header: {
    marginBottom: spacing[4],
  },
  title: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
    marginBottom: spacing[1],
  },
  subtitle: {
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
  },
  warningBox: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    backgroundColor: colors.status.warningLight,
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    marginBottom: spacing[4],
    gap: spacing[2],
  },
  warningText: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.status.warning,
  },
  propertyCard: {
    marginBottom: spacing[4],
    padding: spacing[4],
  },
  addressHeader: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  addressText: {
    flex: 1,
    marginLeft: spacing[3],
  },
  addressLine: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  cityState: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: 2,
  },
  detailsCard: {
    marginBottom: spacing[4],
    padding: spacing[4],
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
  editButton: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[500],
    fontWeight: typography.fontWeights.medium,
  },
  detailsGrid: {},
  editForm: {},
  row: {
    flexDirection: 'row',
    gap: spacing[3],
  },
  continueButton: {
    marginTop: spacing[2],
    marginBottom: spacing[3],
  },
});
