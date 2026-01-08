import React, { useEffect, useRef } from 'react';
import { View, Text, StyleSheet, Animated } from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useOnboarding } from '../../../src/contexts/onboarding-context';
import { useAuth } from '../../../src/contexts/auth-context';
import { Button, Card } from '../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../src/lib/theme';

export default function OnboardingCompleteScreen() {
  const router = useRouter();
  const { propertyData, householdId, reset } = useOnboarding();
  const { completeOnboarding } = useAuth();

  // Animation
  const scaleAnim = useRef(new Animated.Value(0)).current;
  const fadeAnim = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    // Animate checkmark
    Animated.sequence([
      Animated.spring(scaleAnim, {
        toValue: 1,
        tension: 50,
        friction: 3,
        useNativeDriver: true,
      }),
      Animated.timing(fadeAnim, {
        toValue: 1,
        duration: 300,
        useNativeDriver: true,
      }),
    ]).start();
  }, []);

  const handleGoToDashboard = async () => {
    // Complete onboarding - navigation is handled by auth guard when householdInfo updates
    if (householdId) {
      await completeOnboarding(householdId);
    }
    reset();
    // Don't navigate here - let the auth guard handle it when householdInfo is set
    // This prevents race conditions with multiple navigation calls
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.content}>
        {/* Animated Checkmark */}
        <Animated.View
          style={[
            styles.successIcon,
            {
              transform: [{ scale: scaleAnim }],
            },
          ]}
        >
          <Ionicons name="checkmark" size={64} color={colors.white} />
        </Animated.View>

        {/* Success Message */}
        <Animated.View style={{ opacity: fadeAnim }}>
          <Text style={styles.title}>You're all set!</Text>
          <Text style={styles.subtitle}>
            Your home is ready to be managed. Welcome to Haven.
          </Text>

          {/* Summary Card */}
          {propertyData && (
            <Card style={styles.summaryCard}>
              <View style={styles.summaryHeader}>
                <Ionicons name="home" size={24} color={colors.haven.navy[900]} />
                <View style={styles.summaryText}>
                  <Text style={styles.summaryTitle}>
                    {propertyData.city} Home
                  </Text>
                  <Text style={styles.summaryAddress}>
                    {propertyData.addressLine1}
                  </Text>
                </View>
              </View>

              <View style={styles.summaryStats}>
                {propertyData.bedrooms && (
                  <View style={styles.stat}>
                    <Ionicons name="bed-outline" size={18} color={colors.haven.champagne[500]} />
                    <Text style={styles.statText}>{propertyData.bedrooms} bed</Text>
                  </View>
                )}
                {propertyData.bathrooms && (
                  <View style={styles.stat}>
                    <Ionicons name="water-outline" size={18} color={colors.haven.champagne[500]} />
                    <Text style={styles.statText}>{propertyData.bathrooms} bath</Text>
                  </View>
                )}
                {propertyData.squareFeet && (
                  <View style={styles.stat}>
                    <Ionicons name="resize-outline" size={18} color={colors.haven.champagne[500]} />
                    <Text style={styles.statText}>
                      {propertyData.squareFeet.toLocaleString()} sqft
                    </Text>
                  </View>
                )}
              </View>
            </Card>
          )}

          {/* What's Next */}
          <View style={styles.nextSteps}>
            <Text style={styles.nextTitle}>What's next?</Text>

            <View style={styles.nextItem}>
              <View style={styles.nextNumber}>
                <Text style={styles.nextNumberText}>1</Text>
              </View>
              <Text style={styles.nextText}>
                Explore your personalized maintenance schedule
              </Text>
            </View>

            <View style={styles.nextItem}>
              <View style={styles.nextNumber}>
                <Text style={styles.nextNumberText}>2</Text>
              </View>
              <Text style={styles.nextText}>
                Add your first bill to start tracking
              </Text>
            </View>

            <View style={styles.nextItem}>
              <View style={styles.nextNumber}>
                <Text style={styles.nextNumberText}>3</Text>
              </View>
              <Text style={styles.nextText}>
                Save documents like warranties and manuals
              </Text>
            </View>
          </View>

          {/* Go to Dashboard */}
          <Button
            title="Go to Dashboard"
            onPress={handleGoToDashboard}
            fullWidth
            style={styles.dashboardButton}
          />
        </Animated.View>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.primary,
  },
  content: {
    flex: 1,
    padding: spacing[5],
    alignItems: 'center',
    justifyContent: 'center',
  },
  successIcon: {
    width: 100,
    height: 100,
    borderRadius: 50,
    backgroundColor: colors.status.success,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[6],
  },
  title: {
    fontSize: typography.fontSizes['2xl'],
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
    textAlign: 'center',
    marginBottom: spacing[2],
  },
  subtitle: {
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
    textAlign: 'center',
    marginBottom: spacing[6],
    paddingHorizontal: spacing[4],
  },
  summaryCard: {
    width: '100%',
    padding: spacing[4],
    marginBottom: spacing[6],
  },
  summaryHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing[4],
  },
  summaryText: {
    marginLeft: spacing[3],
  },
  summaryTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  summaryAddress: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  summaryStats: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    paddingTop: spacing[3],
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
  },
  stat: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
  },
  statText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  nextSteps: {
    width: '100%',
    marginBottom: spacing[6],
  },
  nextTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginBottom: spacing[4],
  },
  nextItem: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing[3],
  },
  nextNumber: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: colors.haven.champagne[100],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  nextNumberText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.champagne[600],
  },
  nextText: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    lineHeight: 20,
  },
  dashboardButton: {
    width: '100%',
  },
});
