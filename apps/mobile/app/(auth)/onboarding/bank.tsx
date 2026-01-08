import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
} from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useOnboarding } from '../../../src/contexts/onboarding-context';
import { Button, Card } from '../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../src/lib/theme';

export default function OnboardingBankScreen() {
  const router = useRouter();
  const { setStep } = useOnboarding();

  const handleSkip = () => {
    setStep('plan');
    router.push('/(auth)/onboarding/plan');
  };

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        {/* Progress */}
        <View style={styles.progress}>
          <View style={styles.progressBar}>
            <View style={[styles.progressFill, { width: '60%' }]} />
          </View>
          <Text style={styles.progressText}>Step 3 of 5</Text>
        </View>

        {/* Header */}
        <View style={styles.header}>
          <View style={styles.iconContainer}>
            <Ionicons name="wallet" size={32} color={colors.haven.champagne[500]} />
          </View>
          <Text style={styles.title}>Connect your bank</Text>
          <Text style={styles.subtitle}>
            We'll automatically detect your recurring bills so you never miss a payment
          </Text>
        </View>

        {/* Coming Soon Card */}
        <Card style={styles.comingSoonCard}>
          <View style={styles.comingSoonHeader}>
            <View style={styles.comingSoonIcon}>
              <Ionicons name="time" size={32} color={colors.haven.champagne[500]} />
            </View>
            <Text style={styles.comingSoonTitle}>Coming Soon!</Text>
            <Text style={styles.comingSoonText}>
              Bank connection and automatic bill detection will be available in an upcoming update.
            </Text>
          </View>

          {/* Future Benefits */}
          <View style={styles.benefitsSection}>
            <Text style={styles.benefitsLabel}>What you'll get:</Text>

            <View style={styles.benefitRow}>
              <View style={styles.benefitIcon}>
                <Ionicons name="search" size={18} color={colors.haven.champagne[500]} />
              </View>
              <Text style={styles.benefitText}>Auto-detect recurring bills</Text>
            </View>

            <View style={styles.benefitRow}>
              <View style={styles.benefitIcon}>
                <Ionicons name="notifications" size={18} color={colors.haven.champagne[500]} />
              </View>
              <Text style={styles.benefitText}>Payment reminders</Text>
            </View>

            <View style={styles.benefitRow}>
              <View style={styles.benefitIcon}>
                <Ionicons name="shield-checkmark" size={18} color={colors.haven.champagne[500]} />
              </View>
              <Text style={styles.benefitText}>Bank-level security with Plaid</Text>
            </View>
          </View>
        </Card>

        {/* Continue Button */}
        <Button
          title="Continue"
          onPress={handleSkip}
          fullWidth
          icon={<Ionicons name="arrow-forward" size={20} color={colors.white} />}
        />

        {/* Note */}
        <View style={styles.noteContainer}>
          <Ionicons name="information-circle" size={16} color={colors.text.tertiary} />
          <Text style={styles.noteText}>
            You can add bank connection later in Settings
          </Text>
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
    padding: spacing[5],
    paddingBottom: spacing[8],
  },
  progress: {
    marginBottom: spacing[6],
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
    alignItems: 'center',
    marginBottom: spacing[6],
  },
  iconContainer: {
    width: 64,
    height: 64,
    borderRadius: borderRadius.xl,
    backgroundColor: colors.haven.champagne[100],
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[4],
  },
  title: {
    fontSize: typography.fontSizes['2xl'],
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
    marginBottom: spacing[2],
    textAlign: 'center',
  },
  subtitle: {
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
    textAlign: 'center',
    lineHeight: 24,
    paddingHorizontal: spacing[4],
  },
  comingSoonCard: {
    marginBottom: spacing[6],
    padding: spacing[5],
  },
  comingSoonHeader: {
    alignItems: 'center',
    marginBottom: spacing[4],
  },
  comingSoonIcon: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[3],
  },
  comingSoonTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginBottom: spacing[2],
  },
  comingSoonText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    textAlign: 'center',
    lineHeight: 22,
  },
  benefitsSection: {
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
    paddingTop: spacing[4],
  },
  benefitsLabel: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.tertiary,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    marginBottom: spacing[3],
  },
  benefitRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
  },
  benefitIcon: {
    width: 32,
    height: 32,
    borderRadius: borderRadius.md,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  benefitText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.primary,
  },
  noteContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[2],
    marginTop: spacing[4],
  },
  noteText: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
});
