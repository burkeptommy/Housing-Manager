import React, { useEffect, useRef, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Animated,
  ActivityIndicator,
} from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { colors, spacing, typography, borderRadius } from '../../src/lib/theme';
import { useAuth } from '../../src/contexts/auth-context';

export default function CompleteScreen() {
  const router = useRouter();
  const { refreshMe, refreshHouseholds } = useAuth();
  const [isNavigating, setIsNavigating] = useState(false);
  const fadeAnim = useRef(new Animated.Value(0)).current;
  const scaleAnim = useRef(new Animated.Value(0.8)).current;

  useEffect(() => {
    Animated.parallel([
      Animated.timing(fadeAnim, {
        toValue: 1,
        duration: 600,
        useNativeDriver: true,
      }),
      Animated.spring(scaleAnim, {
        toValue: 1,
        friction: 8,
        tension: 40,
        useNativeDriver: true,
      }),
    ]).start();
  }, [fadeAnim, scaleAnim]);

  const handleGetStarted = async () => {
    setIsNavigating(true);
    try {
      // Ensure state is refreshed before navigating
      await refreshMe();
      await refreshHouseholds();
      // Small delay to let state settle
      await new Promise(resolve => setTimeout(resolve, 100));
      router.replace('/(tabs)');
    } catch (error) {
      console.error('Error refreshing state:', error);
      // Navigate anyway
      router.replace('/(tabs)');
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <Animated.View
        style={[
          styles.content,
          { opacity: fadeAnim, transform: [{ scale: scaleAnim }] }
        ]}
      >
        {/* Success Icon */}
        <View style={styles.iconContainer}>
          <View style={styles.iconCircle}>
            <Ionicons name="checkmark" size={48} color={colors.white} />
          </View>
        </View>

        {/* Header */}
        <Text style={styles.title}>You're all set!</Text>
        <Text style={styles.subtitle}>
          Welcome to Haven. Your home is now set up and ready to go.
        </Text>

        {/* What's Next Card */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>What's next?</Text>

          <View style={styles.featureRow}>
            <View style={styles.featureIcon}>
              <Ionicons name="chatbubble-ellipses" size={20} color={colors.haven.champagne[500]} />
            </View>
            <View style={styles.featureText}>
              <Text style={styles.featureTitle}>Meet Alfred</Text>
              <Text style={styles.featureDescription}>
                Your AI home manager will help complete your profile and answer questions
              </Text>
            </View>
          </View>

          <View style={styles.featureRow}>
            <View style={styles.featureIcon}>
              <Ionicons name="card" size={20} color={colors.haven.champagne[500]} />
            </View>
            <View style={styles.featureText}>
              <Text style={styles.featureTitle}>Connect Bills</Text>
              <Text style={styles.featureDescription}>
                Link your bank to auto-detect bills and set up consolidated payments
              </Text>
            </View>
          </View>

          <View style={styles.featureRow}>
            <View style={styles.featureIcon}>
              <Ionicons name="construct" size={20} color={colors.haven.champagne[500]} />
            </View>
            <View style={styles.featureText}>
              <Text style={styles.featureTitle}>Maintenance Reminders</Text>
              <Text style={styles.featureDescription}>
                We've created a maintenance schedule based on your home's systems
              </Text>
            </View>
          </View>
        </View>

        {/* Get Started Button */}
        <TouchableOpacity
          style={[styles.button, isNavigating && styles.buttonDisabled]}
          onPress={handleGetStarted}
          disabled={isNavigating}
        >
          {isNavigating ? (
            <ActivityIndicator color={colors.white} />
          ) : (
            <>
              <Text style={styles.buttonText}>Get Started</Text>
              <Ionicons name="arrow-forward" size={20} color={colors.white} />
            </>
          )}
        </TouchableOpacity>
      </Animated.View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.haven.navy[50],
  },
  content: {
    flex: 1,
    padding: spacing[6],
    justifyContent: 'center',
  },
  iconContainer: {
    alignItems: 'center',
    marginBottom: spacing[6],
  },
  iconCircle: {
    width: 96,
    height: 96,
    borderRadius: 48,
    backgroundColor: '#10b981',
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#10b981',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.3,
    shadowRadius: 16,
    elevation: 8,
  },
  title: {
    fontSize: 28,
    fontWeight: '700',
    color: colors.haven.navy[900],
    textAlign: 'center',
    marginBottom: spacing[2],
  },
  subtitle: {
    fontSize: typography.fontSizes.base,
    color: colors.haven.navy[500],
    textAlign: 'center',
    marginBottom: spacing[8],
    lineHeight: 24,
  },
  card: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[5],
    marginBottom: spacing[8],
  },
  cardTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.navy[900],
    marginBottom: spacing[4],
  },
  featureRow: {
    flexDirection: 'row',
    marginBottom: spacing[4],
    gap: spacing[3],
  },
  featureIcon: {
    width: 40,
    height: 40,
    borderRadius: 12,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  featureText: {
    flex: 1,
  },
  featureTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.navy[900],
    marginBottom: 2,
  },
  featureDescription: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[500],
    lineHeight: 20,
  },
  button: {
    backgroundColor: colors.haven.navy[900],
    borderRadius: borderRadius.lg,
    padding: spacing[4],
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[2],
  },
  buttonDisabled: {
    opacity: 0.6,
  },
  buttonText: {
    color: colors.white,
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
  },
});
