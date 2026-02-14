import React, { useEffect, useRef, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Animated,
  ActivityIndicator,
  ScrollView,
} from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import * as Clipboard from 'expo-clipboard';
import { colors, spacing, typography, borderRadius } from '../../src/lib/theme';
import { useAuth } from '../../src/contexts/auth-context';
import { getIdToken } from '../../src/lib/firebase';
import { API_BASE_URL } from '../../src/lib/api';

export default function CompleteScreen() {
  const router = useRouter();
  const { refreshMe, refreshHouseholds } = useAuth();
  const [isNavigating, setIsNavigating] = useState(false);
  const [alfredEmail, setAlfredEmail] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);
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

    // Fetch Alfred email address
    fetchAlfredEmail();
  }, [fadeAnim, scaleAnim]);

  const fetchAlfredEmail = async () => {
    try {
      const token = await getIdToken();
      if (!token) return;
      const res = await fetch(`${API_BASE_URL}/alfred/email-address`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.ok) {
        const data = await res.json();
        if (data.email) setAlfredEmail(data.email);
      }
    } catch {
      // Not critical — email can be found in settings later
    }
  };

  const handleCopyEmail = async () => {
    if (!alfredEmail) return;
    await Clipboard.setStringAsync(alfredEmail);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

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
      <ScrollView contentContainerStyle={styles.scrollContent}>
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

          {/* Alfred Email Card */}
          {alfredEmail && (
            <View style={styles.emailCard}>
              <View style={styles.emailHeader}>
                <Ionicons name="mail" size={20} color={colors.haven.purple[500]} />
                <Text style={styles.emailTitle}>Your Alfred Email</Text>
              </View>
              <Text style={styles.emailDescription}>
                Forward bills, receipts & home docs to this address and Alfred will handle them.
              </Text>
              <TouchableOpacity style={styles.emailRow} onPress={handleCopyEmail}>
                <Text style={styles.emailAddress} numberOfLines={1}>{alfredEmail}</Text>
                <View style={styles.copyButton}>
                  <Ionicons
                    name={copied ? "checkmark" : "copy-outline"}
                    size={16}
                    color={copied ? '#10b981' : colors.haven.purple[600]}
                  />
                  <Text style={[styles.copyText, copied && styles.copyTextSuccess]}>
                    {copied ? 'Copied!' : 'Copy'}
                  </Text>
                </View>
              </TouchableOpacity>
            </View>
          )}

          {/* What's Next Card */}
          <View style={styles.card}>
            <Text style={styles.cardTitle}>What's next?</Text>

            <View style={styles.featureRow}>
              <View style={styles.featureIcon}>
                <Ionicons name="mail-open" size={20} color={colors.haven.purple[500]} />
              </View>
              <View style={styles.featureText}>
                <Text style={styles.featureTitle}>Your Alfred Email</Text>
                <Text style={styles.featureDescription}>
                  Forward bills, receipts & home docs to your personal email
                </Text>
              </View>
            </View>

            <View style={styles.featureRow}>
              <View style={styles.featureIcon}>
                <Ionicons name="chatbubble-ellipses" size={20} color={colors.haven.purple[500]} />
              </View>
              <View style={styles.featureText}>
                <Text style={styles.featureTitle}>Chat with Alfred</Text>
                <Text style={styles.featureDescription}>
                  Ask anything about your home, maintenance, or vendors
                </Text>
              </View>
            </View>

            <View style={styles.featureRow}>
              <View style={styles.featureIcon}>
                <Ionicons name="heart-circle" size={20} color={colors.haven.purple[500]} />
              </View>
              <View style={styles.featureText}>
                <Text style={styles.featureTitle}>Home Health Score</Text>
                <Text style={styles.featureDescription}>
                  See your home's condition and what needs attention
                </Text>
              </View>
            </View>

            <View style={styles.featureRow}>
              <View style={styles.featureIcon}>
                <Ionicons name="people" size={20} color={colors.haven.purple[500]} />
              </View>
              <View style={styles.featureText}>
                <Text style={styles.featureTitle}>Vendor CRM</Text>
                <Text style={styles.featureDescription}>
                  Track service providers and manage relationships
                </Text>
              </View>
            </View>

            <View style={[styles.featureRow, { marginBottom: 0 }]}>
              <View style={styles.featureIcon}>
                <Ionicons name="construct" size={20} color={colors.haven.purple[500]} />
              </View>
              <View style={styles.featureText}>
                <Text style={styles.featureTitle}>Maintenance Schedule</Text>
                <Text style={styles.featureDescription}>
                  Personalized reminders based on your home's systems
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
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.haven.purple[50],
  },
  scrollContent: {
    flexGrow: 1,
    justifyContent: 'center',
  },
  content: {
    padding: spacing[6],
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
    color: colors.haven.purple[900],
    textAlign: 'center',
    marginBottom: spacing[2],
  },
  subtitle: {
    fontSize: typography.fontSizes.base,
    color: colors.haven.purple[500],
    textAlign: 'center',
    marginBottom: spacing[6],
    lineHeight: 24,
  },
  emailCard: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[5],
    marginBottom: spacing[4],
    borderWidth: 1,
    borderColor: colors.haven.purple[200],
  },
  emailHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    marginBottom: spacing[2],
  },
  emailTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.purple[900],
  },
  emailDescription: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[500],
    lineHeight: 20,
    marginBottom: spacing[3],
  },
  emailRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.haven.purple[50],
    borderRadius: borderRadius.lg,
    padding: spacing[3],
    gap: spacing[3],
  },
  emailAddress: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.purple[900],
  },
  copyButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
    paddingHorizontal: spacing[2],
  },
  copyText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.purple[600],
  },
  copyTextSuccess: {
    color: '#10b981',
  },
  card: {
    backgroundColor: colors.white,
    borderRadius: borderRadius.xl,
    padding: spacing[5],
    marginBottom: spacing[6],
  },
  cardTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.purple[900],
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
    backgroundColor: colors.haven.purple[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  featureText: {
    flex: 1,
  },
  featureTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.purple[900],
    marginBottom: 2,
  },
  featureDescription: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[500],
    lineHeight: 20,
  },
  button: {
    backgroundColor: colors.haven.purple[900],
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
