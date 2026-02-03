import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  TextInput,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { useLocalSearchParams, router } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { ScreenContainer } from '../../../../src/components/ScreenContainer';
import { colors, spacing, typography, borderRadius } from '../../../../src/lib/theme';
import { getIdToken } from '../../../../src/lib/firebase';

const API_URL = process.env.EXPO_PUBLIC_API_URL;

interface SuggestedAction {
  label: string;
  type: string;
  data: unknown;
}

interface EmailCase {
  id: string;
  caseNumber: string;
  subject: string;
  fromEmail: string;
  fromName?: string;
  receivedAt: string;
  status: string;
  pendingQuestion: string;
  questionOptions: SuggestedAction[];
  summary?: string;
  actionsTaken?: Array<{ type: string; success: boolean }>;
  resolutionNotes?: string;
}

function getActionIcon(type: string): keyof typeof Ionicons.glyphMap {
  switch (type) {
    case 'CALENDAR':
      return 'calendar';
    case 'BILL':
      return 'receipt';
    case 'VENDOR':
      return 'people';
    case 'TASK':
      return 'checkbox';
    case 'DOCUMENT':
      return 'document';
    case 'REMINDER':
      return 'alarm';
    case 'WARRANTY':
      return 'shield-checkmark';
    case 'SHIPPING':
      return 'cube';
    case 'ALL':
      return 'checkmark-done';
    case 'CUSTOM':
      return 'chatbubble-ellipses';
    default:
      return 'ellipsis-horizontal';
  }
}

export default function CaseDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const [emailCase, setEmailCase] = useState<EmailCase | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isExecuting, setIsExecuting] = useState(false);
  const [selectedActions, setSelectedActions] = useState<string[]>([]);
  const [customRequest, setCustomRequest] = useState('');
  const [showCustomInput, setShowCustomInput] = useState(false);

  useEffect(() => {
    fetchCase();
  }, [id]);

  const fetchCase = async () => {
    try {
      const token = await getIdToken();
      if (!token) return;
      const response = await fetch(`${API_URL}/alfred/cases/${id}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (response.ok) {
        const data = await response.json();
        setEmailCase(data);
      }
    } catch (error) {
      console.error('Failed to fetch case:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const toggleAction = (actionType: string) => {
    if (actionType === 'CUSTOM') {
      setShowCustomInput(true);
      setSelectedActions(['CUSTOM']);
    } else {
      setShowCustomInput(false);
      setSelectedActions((prev) =>
        prev.includes(actionType)
          ? prev.filter((a) => a !== actionType)
          : [...prev.filter((a) => a !== 'CUSTOM'), actionType],
      );
    }
  };

  const executeActions = async () => {
    if (selectedActions.length === 0) {
      Alert.alert('Select an action', "Please choose what you'd like me to do.");
      return;
    }

    setIsExecuting(true);
    try {
      const token = await getIdToken();
      if (!token) return;
      const response = await fetch(`${API_URL}/alfred/cases/${id}/execute`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          actionTypes: selectedActions,
          customRequest: showCustomInput ? customRequest : undefined,
        }),
      });

      const result = await response.json();

      if (result.status === 'completed') {
        Alert.alert('Done!', result.message, [{ text: 'Great!', onPress: () => router.back() }]);
      } else {
        // Re-fetch case for new suggestions (e.g. after "Something else...")
        await fetchCase();
        setSelectedActions([]);
        setCustomRequest('');
        setShowCustomInput(false);
      }
    } catch (error) {
      Alert.alert('Error', 'Something went wrong. Please try again.');
    } finally {
      setIsExecuting(false);
    }
  };

  if (isLoading) {
    return (
      <ScreenContainer title="Case Details" showBack>
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={colors.haven.sage[500]} />
        </View>
      </ScreenContainer>
    );
  }

  if (!emailCase) {
    return (
      <ScreenContainer title="Case Details" showBack>
        <View style={styles.errorContainer}>
          <Text style={styles.errorText}>Case not found</Text>
        </View>
      </ScreenContainer>
    );
  }

  const isCompleted = emailCase.status === 'COMPLETED';

  return (
    <ScreenContainer title={emailCase.caseNumber} showBack>
      <ScrollView style={styles.container}>
        {/* Email Info Card */}
        <View style={styles.emailCard}>
          <View style={styles.emailHeader}>
            <Ionicons name="mail" size={20} color={colors.haven.sage[500]} />
            <Text style={styles.emailSubject} numberOfLines={2}>
              {emailCase.subject}
            </Text>
          </View>
          <Text style={styles.emailFrom}>
            From: {emailCase.fromName || emailCase.fromEmail}
          </Text>
          <Text style={styles.emailDate}>
            {new Date(emailCase.receivedAt).toLocaleDateString('en-US', {
              weekday: 'short',
              month: 'short',
              day: 'numeric',
              hour: 'numeric',
              minute: '2-digit',
            })}
          </Text>
        </View>

        {/* Alfred's Message */}
        <View style={styles.alfredSection}>
          <View style={styles.alfredHeader}>
            <View style={styles.alfredAvatar}>
              <Text style={styles.alfredAvatarText}>A</Text>
            </View>
            <Text style={styles.alfredName}>Alfred</Text>
          </View>

          <View style={styles.alfredBubble}>
            <Text style={styles.alfredMessage}>{emailCase.pendingQuestion}</Text>
          </View>
        </View>

        {/* Action Buttons */}
        {!isCompleted && emailCase.questionOptions && (
          <View style={styles.actionsSection}>
            <Text style={styles.actionsLabel}>
              {selectedActions.length > 0
                ? `Selected: ${selectedActions.length}`
                : 'Tap to select actions'}
            </Text>

            <View style={styles.actionsGrid}>
              {emailCase.questionOptions.map((action, index) => {
                const isSelected = selectedActions.includes(action.type);
                const isSomethingElse = action.type === 'CUSTOM';

                return (
                  <TouchableOpacity
                    key={index}
                    style={[
                      styles.actionButton,
                      isSelected && styles.actionButtonSelected,
                      isSomethingElse && styles.actionButtonCustom,
                    ]}
                    onPress={() => toggleAction(action.type)}
                  >
                    <Ionicons
                      name={getActionIcon(action.type)}
                      size={20}
                      color={isSelected ? colors.white : colors.haven.navy[700]}
                    />
                    <Text
                      style={[
                        styles.actionButtonText,
                        isSelected && styles.actionButtonTextSelected,
                      ]}
                    >
                      {action.label}
                    </Text>
                    {isSelected && !isSomethingElse && (
                      <Ionicons name="checkmark-circle" size={18} color={colors.white} />
                    )}
                  </TouchableOpacity>
                );
              })}
            </View>

            {/* Custom Request Input */}
            {showCustomInput && (
              <View style={styles.customInputContainer}>
                <Text style={styles.customInputLabel}>What would you like me to do?</Text>
                <TextInput
                  style={styles.customInput}
                  placeholder="e.g., Create a reminder for next week"
                  placeholderTextColor={colors.haven.navy[400]}
                  value={customRequest}
                  onChangeText={setCustomRequest}
                  multiline
                  numberOfLines={3}
                />
              </View>
            )}

            {/* Execute Button */}
            <TouchableOpacity
              style={[
                styles.executeButton,
                (selectedActions.length === 0 || isExecuting) && styles.executeButtonDisabled,
              ]}
              onPress={executeActions}
              disabled={selectedActions.length === 0 || isExecuting}
            >
              {isExecuting ? (
                <ActivityIndicator size="small" color={colors.white} />
              ) : (
                <>
                  <Ionicons name="sparkles" size={18} color={colors.white} />
                  <Text style={styles.executeButtonText}>
                    {showCustomInput ? 'Ask Alfred' : 'Do It'}
                  </Text>
                </>
              )}
            </TouchableOpacity>
          </View>
        )}

        {/* Completed State */}
        {isCompleted && emailCase.actionsTaken && (
          <View style={styles.completedSection}>
            <View style={styles.completedHeader}>
              <Ionicons name="checkmark-circle" size={24} color={colors.status.success} />
              <Text style={styles.completedTitle}>Completed</Text>
            </View>
            {emailCase.resolutionNotes && (
              <Text style={styles.completedNotes}>{emailCase.resolutionNotes}</Text>
            )}
            <View style={styles.actionsList}>
              {emailCase.actionsTaken.map((action, index) => (
                <View key={index} style={styles.completedAction}>
                  <Ionicons
                    name={action.success ? 'checkmark' : 'close'}
                    size={16}
                    color={action.success ? colors.status.success : colors.status.error}
                  />
                  <Text style={styles.completedActionText}>
                    {action.type.replace(/_/g, ' ').toLowerCase()}
                  </Text>
                </View>
              ))}
            </View>
          </View>
        )}
      </ScrollView>
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  errorText: {
    color: colors.haven.navy[500],
    fontSize: typography.fontSizes.base,
  },
  emailCard: {
    backgroundColor: colors.white,
    margin: spacing[4],
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.border.default,
  },
  emailHeader: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: spacing[2],
    marginBottom: spacing[2],
  },
  emailSubject: {
    flex: 1,
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold as '600',
    color: colors.haven.navy[900],
  },
  emailFrom: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[600],
    marginBottom: spacing[1],
  },
  emailDate: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[400],
  },
  alfredSection: {
    paddingHorizontal: spacing[4],
    marginBottom: spacing[4],
  },
  alfredHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    marginBottom: spacing[2],
  },
  alfredAvatar: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: colors.haven.sage[500],
    alignItems: 'center',
    justifyContent: 'center',
  },
  alfredAvatarText: {
    color: colors.white,
    fontWeight: typography.fontWeights.bold as '700',
    fontSize: typography.fontSizes.base,
  },
  alfredName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold as '600',
    color: colors.haven.navy[900],
  },
  alfredBubble: {
    backgroundColor: colors.haven.sage[50],
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    borderTopLeftRadius: 4,
  },
  alfredMessage: {
    fontSize: typography.fontSizes.base,
    color: colors.haven.navy[800],
    lineHeight: 24,
  },
  actionsSection: {
    padding: spacing[4],
  },
  actionsLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[500],
    marginBottom: spacing[3],
    textAlign: 'center',
  },
  actionsGrid: {
    gap: spacing[2],
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
    backgroundColor: colors.white,
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    borderWidth: 2,
    borderColor: colors.border.default,
  },
  actionButtonSelected: {
    backgroundColor: colors.haven.navy[900],
    borderColor: colors.haven.navy[900],
  },
  actionButtonCustom: {
    borderStyle: 'dashed' as const,
  },
  actionButtonText: {
    flex: 1,
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium as '500',
    color: colors.haven.navy[800],
  },
  actionButtonTextSelected: {
    color: colors.white,
  },
  customInputContainer: {
    marginTop: spacing[4],
  },
  customInputLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[600],
    marginBottom: spacing[2],
  },
  customInput: {
    backgroundColor: colors.white,
    borderWidth: 1,
    borderColor: colors.haven.navy[200],
    borderRadius: borderRadius.lg,
    padding: spacing[3],
    fontSize: typography.fontSizes.base,
    color: colors.haven.navy[900],
    minHeight: 80,
    textAlignVertical: 'top',
  },
  executeButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[2],
    backgroundColor: colors.haven.sage[500],
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    marginTop: spacing[4],
  },
  executeButtonDisabled: {
    opacity: 0.5,
  },
  executeButtonText: {
    color: colors.white,
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold as '600',
  },
  completedSection: {
    margin: spacing[4],
    padding: spacing[4],
    backgroundColor: colors.haven.sage[50],
    borderRadius: borderRadius.lg,
  },
  completedHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    marginBottom: spacing[3],
  },
  completedTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold as '600',
    color: colors.status.success,
  },
  completedNotes: {
    fontSize: typography.fontSizes.base,
    color: colors.haven.navy[700],
    marginBottom: spacing[3],
    lineHeight: 22,
  },
  actionsList: {
    gap: spacing[2],
  },
  completedAction: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
  },
  completedActionText: {
    fontSize: typography.fontSizes.base,
    color: colors.haven.navy[700],
    textTransform: 'capitalize',
  },
});
