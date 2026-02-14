import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  TextInput,
  Alert,
  ActivityIndicator,
  Share,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import * as Clipboard from 'expo-clipboard';
import { AppHeader } from '../../../src/components';
import {
  colors,
  spacing,
  typography,
  borderRadius,
} from '../../../src/lib/theme';
import { getIdToken } from '../../../src/lib/firebase';
import { API_BASE_URL } from '../../../src/lib/api';

interface AuthorizedEmail {
  id: string;
  email: string;
  label: string | null;
  createdAt: string;
}

export default function AlfredEmailSettingsScreen() {
  const router = useRouter();
  const [alfredEmail, setAlfredEmail] = useState<string>('');
  const [authorizedEmails, setAuthorizedEmails] = useState<AuthorizedEmail[]>(
    [],
  );
  const [isLoading, setIsLoading] = useState(true);
  const [newEmail, setNewEmail] = useState('');
  const [newLabel, setNewLabel] = useState('');
  const [isAdding, setIsAdding] = useState(false);
  const [showAddForm, setShowAddForm] = useState(false);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      const token = await getIdToken();
      const headers = { Authorization: `Bearer ${token}` };

      const [emailRes, authRes] = await Promise.all([
        fetch(`${API_BASE_URL}/alfred/email-address`, { headers }),
        fetch(`${API_BASE_URL}/alfred/authorized-emails`, { headers }),
      ]);

      const emailData = await emailRes.json();
      const authData = await authRes.json();

      setAlfredEmail(emailData.email || '');
      setAuthorizedEmails(Array.isArray(authData) ? authData : []);
    } catch (err) {
      console.error('Failed to fetch Alfred email data:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const copyEmail = async () => {
    if (alfredEmail) {
      await Clipboard.setStringAsync(alfredEmail);
      Alert.alert(
        'Copied!',
        "Alfred's email address has been copied to your clipboard.",
      );
    }
  };

  const shareEmail = async () => {
    if (alfredEmail) {
      await Share.share({
        message: `CC Alfred on any email to have him help manage it: ${alfredEmail}`,
      });
    }
  };

  const addAuthorizedEmail = async () => {
    if (!newEmail.trim()) {
      Alert.alert('Error', 'Please enter an email address');
      return;
    }

    setIsAdding(true);
    try {
      const token = await getIdToken();
      const response = await fetch(`${API_BASE_URL}/alfred/authorized-emails`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          email: newEmail.trim(),
          label: newLabel.trim() || null,
        }),
      });

      if (!response.ok) throw new Error('Failed to add email');

      await fetchData();
      setNewEmail('');
      setNewLabel('');
      setShowAddForm(false);
      Alert.alert('Success', 'Email address authorized');
    } catch (err) {
      Alert.alert('Error', 'Failed to add authorized email');
    } finally {
      setIsAdding(false);
    }
  };

  const removeEmail = async (id: string, email: string) => {
    Alert.alert('Remove Email', `Remove ${email} from authorized senders?`, [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Remove',
        style: 'destructive',
        onPress: async () => {
          try {
            const token = await getIdToken();
            await fetch(`${API_BASE_URL}/alfred/authorized-emails/${id}`, {
              method: 'DELETE',
              headers: { Authorization: `Bearer ${token}` },
            });
            await fetchData();
          } catch (err) {
            Alert.alert('Error', 'Failed to remove email');
          }
        },
      },
    ]);
  };

  if (isLoading) {
    return (
      <View style={styles.fullContainer}>
        <AppHeader title="Personal Assistant" showBack onBackPress={() => router.push('/(tabs)')} />
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={colors.haven.purple[500]} />
        </View>
      </View>
    );
  }

  return (
    <View style={styles.fullContainer}>
      <AppHeader title="Personal Assistant" showBack onBackPress={() => router.push('/(tabs)')} />
      <ScrollView
        style={styles.scrollContainer}
        contentContainerStyle={styles.scrollContent}
      >
        {/* Intro */}
        <View style={styles.introCard}>
          <Ionicons name="mail" size={32} color={colors.haven.purple[500]} />
          <Text style={styles.introTitle}>CC Alfred on Any Email</Text>
          <Text style={styles.introText}>
            Forward or CC Alfred on emails about camps, bills, appointments,
            inspections, and more. He'll automatically add events to your
            calendar, track bills, and keep your home organized.
          </Text>
        </View>

        {/* Alfred's Email Address */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Alfred's Email Address</Text>
          <View style={styles.emailCard}>
            {alfredEmail ? (
              <>
                <Text style={styles.emailAddress}>{alfredEmail}</Text>
                <View style={styles.emailActions}>
                  <TouchableOpacity style={styles.emailAction} onPress={copyEmail}>
                    <Ionicons
                      name="copy-outline"
                      size={20}
                      color={colors.haven.purple[500]}
                    />
                    <Text style={styles.emailActionText}>Copy</Text>
                  </TouchableOpacity>
                  <TouchableOpacity
                    style={styles.emailAction}
                    onPress={shareEmail}
                  >
                    <Ionicons
                      name="share-outline"
                      size={20}
                      color={colors.haven.purple[500]}
                    />
                    <Text style={styles.emailActionText}>Share</Text>
                  </TouchableOpacity>
                </View>
              </>
            ) : (
              <View style={styles.configureContainer}>
                <Ionicons
                  name="home-outline"
                  size={32}
                  color={colors.haven.purple[400]}
                />
                <Text style={styles.configureText}>
                  Your Alfred email address is generated from your property address.
                </Text>
                <Text style={styles.configureNote}>
                  Complete your home profile to get your unique Alfred email.
                </Text>
                <TouchableOpacity
                  style={styles.setupButton}
                  onPress={() => router.push('/(tabs)/settings' as any)}
                >
                  <Text style={styles.setupButtonText}>Go to Settings</Text>
                </TouchableOpacity>
              </View>
            )}
          </View>
        </View>

        {/* How It Works */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>How It Works</Text>
          <View style={styles.stepsContainer}>
            <View style={styles.step}>
              <View style={styles.stepNumber}>
                <Text style={styles.stepNumberText}>1</Text>
              </View>
              <View style={styles.stepContent}>
                <Text style={styles.stepTitle}>CC or Forward</Text>
                <Text style={styles.stepText}>
                  Send to your unique Alfred address or forward emails directly
                </Text>
              </View>
            </View>
            <View style={styles.step}>
              <View style={styles.stepNumber}>
                <Text style={styles.stepNumberText}>2</Text>
              </View>
              <View style={styles.stepContent}>
                <Text style={styles.stepTitle}>Alfred Reads It</Text>
                <Text style={styles.stepText}>
                  Alfred extracts dates, amounts, contacts, and action items
                </Text>
              </View>
            </View>
            <View style={styles.step}>
              <View style={styles.stepNumber}>
                <Text style={styles.stepNumberText}>3</Text>
              </View>
              <View style={styles.stepContent}>
                <Text style={styles.stepTitle}>Auto-Organized</Text>
                <Text style={styles.stepText}>
                  Events go to calendar, bills are tracked, vendors are updated
                </Text>
              </View>
            </View>
          </View>
        </View>

        {/* Email History Link */}
        <TouchableOpacity
          style={styles.historyButton}
          onPress={() => router.push('/(tabs)/settings/alfred-cases' as any)}
        >
          <View style={styles.historyButtonContent}>
            <View style={styles.historyButtonIcon}>
              <Ionicons name="time-outline" size={24} color={colors.haven.purple[500]} />
            </View>
            <View style={styles.historyButtonText}>
              <Text style={styles.historyButtonTitle}>View Email History</Text>
              <Text style={styles.historyButtonSubtitle}>
                See all emails Alfred has processed
              </Text>
            </View>
          </View>
          <Ionicons name="chevron-forward" size={20} color={colors.text.tertiary} />
        </TouchableOpacity>

        {/* Authorized Senders */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Authorized Senders</Text>
            <TouchableOpacity onPress={() => setShowAddForm(!showAddForm)}>
              <Ionicons
                name={showAddForm ? 'close' : 'add-circle'}
                size={24}
                color={colors.haven.purple[500]}
              />
            </TouchableOpacity>
          </View>
          <Text style={styles.sectionSubtitle}>
            Only emails from these addresses will be processed
          </Text>

          {showAddForm && (
            <View style={styles.addForm}>
              <TextInput
                style={styles.input}
                placeholder="Email address"
                placeholderTextColor={colors.haven.purple[400]}
                value={newEmail}
                onChangeText={setNewEmail}
                keyboardType="email-address"
                autoCapitalize="none"
              />
              <TextInput
                style={styles.input}
                placeholder="Label (optional, e.g., 'Work Email')"
                placeholderTextColor={colors.haven.purple[400]}
                value={newLabel}
                onChangeText={setNewLabel}
              />
              <TouchableOpacity
                style={[styles.addButton, isAdding && styles.addButtonDisabled]}
                onPress={addAuthorizedEmail}
                disabled={isAdding}
              >
                {isAdding ? (
                  <ActivityIndicator size="small" color={colors.white} />
                ) : (
                  <Text style={styles.addButtonText}>Add Email</Text>
                )}
              </TouchableOpacity>
            </View>
          )}

          <View style={styles.emailList}>
            {authorizedEmails.map((item) => (
              <View key={item.id} style={styles.emailItem}>
                <View style={styles.emailItemInfo}>
                  <Text style={styles.emailItemAddress}>{item.email}</Text>
                  {item.label && (
                    <Text style={styles.emailItemLabel}>{item.label}</Text>
                  )}
                </View>
                <TouchableOpacity
                  onPress={() => removeEmail(item.id, item.email)}
                >
                  <Ionicons
                    name="trash-outline"
                    size={20}
                    color={colors.status.error}
                  />
                </TouchableOpacity>
              </View>
            ))}

            {authorizedEmails.length === 0 && (
              <Text style={styles.emptyText}>
                No additional emails authorized. Family member emails are
                automatically authorized.
              </Text>
            )}
          </View>
        </View>

        {/* Examples */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>What Alfred Can Handle</Text>
          <View style={styles.examplesContainer}>
            <View style={styles.example}>
              <Ionicons
                name="calendar"
                size={20}
                color={colors.haven.purple[500]}
              />
              <Text style={styles.exampleText}>
                Camp registrations & school events
              </Text>
            </View>
            <View style={styles.example}>
              <Ionicons
                name="receipt"
                size={20}
                color={colors.haven.purple[500]}
              />
              <Text style={styles.exampleText}>
                Bills, invoices & payment reminders
              </Text>
            </View>
            <View style={styles.example}>
              <Ionicons
                name="construct"
                size={20}
                color={colors.haven.purple[500]}
              />
              <Text style={styles.exampleText}>Home inspection reports</Text>
            </View>
            <View style={styles.example}>
              <Ionicons
                name="people"
                size={20}
                color={colors.haven.purple[500]}
              />
              <Text style={styles.exampleText}>Vendor correspondence</Text>
            </View>
            <View style={styles.example}>
              <Ionicons
                name="chatbubbles"
                size={20}
                color={colors.haven.purple[500]}
              />
              <Text style={styles.exampleText}>
                Dispute responses (with your approval)
              </Text>
            </View>
          </View>
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  fullContainer: {
    flex: 1,
    backgroundColor: colors.haven.purple[900],
  },
  scrollContainer: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  scrollContent: {
    padding: spacing[4],
    paddingBottom: spacing[8],
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.background.secondary,
  },
  introCard: {
    backgroundColor: colors.haven.purple[50],
    padding: spacing[6],
    marginBottom: spacing[4],
    borderRadius: borderRadius.xl,
    alignItems: 'center',
  },
  introTitle: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.haven.purple[900],
    marginTop: spacing[3],
    marginBottom: spacing[2],
  },
  introText: {
    fontSize: typography.fontSizes.base,
    color: colors.haven.purple[600],
    textAlign: 'center',
    lineHeight: 24,
  },
  section: {
    marginBottom: spacing[6],
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  sectionTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.purple[900],
    marginBottom: spacing[2],
  },
  sectionSubtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[500],
    marginBottom: spacing[3],
  },
  emailCard: {
    backgroundColor: colors.white,
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.border.default,
  },
  configureContainer: {
    alignItems: 'center',
    paddingVertical: spacing[4],
    gap: spacing[3],
  },
  configureText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[600],
    textAlign: 'center',
    lineHeight: 20,
  },
  configureNote: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.purple[400],
    textAlign: 'center',
    fontStyle: 'italic',
  },
  setupButton: {
    marginTop: spacing[3],
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[4],
    backgroundColor: colors.haven.purple[800],
    borderRadius: borderRadius.md,
  },
  setupButtonText: {
    color: colors.white,
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
  },
  emailAddress: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.purple[900],
    fontFamily: 'monospace',
    marginBottom: spacing[3],
  },
  emailActions: {
    flexDirection: 'row',
    gap: spacing[4],
  },
  emailAction: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
  },
  emailActionText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[600],
    fontWeight: typography.fontWeights.medium,
  },
  stepsContainer: {
    gap: spacing[4],
  },
  step: {
    flexDirection: 'row',
    gap: spacing[3],
  },
  stepNumber: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: colors.haven.purple[500],
    alignItems: 'center',
    justifyContent: 'center',
  },
  stepNumberText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.bold,
    color: colors.white,
  },
  stepContent: {
    flex: 1,
  },
  stepTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.purple[900],
  },
  stepText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[500],
    marginTop: 2,
  },
  addForm: {
    backgroundColor: colors.haven.purple[50],
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    marginBottom: spacing[4],
    gap: spacing[3],
  },
  input: {
    backgroundColor: colors.white,
    borderWidth: 1,
    borderColor: colors.haven.purple[200],
    borderRadius: borderRadius.lg,
    padding: spacing[3],
    fontSize: typography.fontSizes.base,
    color: colors.haven.purple[900],
  },
  addButton: {
    backgroundColor: colors.haven.purple[900],
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    alignItems: 'center',
  },
  addButtonDisabled: {
    opacity: 0.6,
  },
  addButtonText: {
    color: colors.white,
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
  },
  emailList: {
    gap: spacing[2],
  },
  emailItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.border.default,
  },
  emailItemInfo: {
    flex: 1,
  },
  emailItemAddress: {
    fontSize: typography.fontSizes.base,
    color: colors.haven.purple[900],
  },
  emailItemLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[500],
    marginTop: 2,
  },
  emptyText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[400],
    fontStyle: 'italic',
  },
  examplesContainer: {
    gap: spacing[3],
  },
  example: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
  },
  exampleText: {
    fontSize: typography.fontSizes.base,
    color: colors.haven.purple[700],
  },
  historyButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: colors.white,
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.border.default,
    marginBottom: spacing[6],
  },
  historyButtonContent: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
  },
  historyButtonIcon: {
    width: 44,
    height: 44,
    borderRadius: borderRadius.lg,
    backgroundColor: `${colors.haven.purple[500]}15`,
    alignItems: 'center',
    justifyContent: 'center',
  },
  historyButtonText: {
    flex: 1,
  },
  historyButtonTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.purple[900],
  },
  historyButtonSubtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[500],
    marginTop: 2,
  },
});
