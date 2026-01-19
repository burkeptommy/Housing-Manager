import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  ActivityIndicator,
  Alert,
  TextInput,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { AppHeader, Card, Badge } from '../../../../src/components';
import {
  colors,
  spacing,
  typography,
  borderRadius,
} from '../../../../src/lib/theme';
import { getIdToken } from '../../../../src/lib/firebase';
import { API_BASE_URL } from '../../../../src/lib/api';

interface EmailCaseActivity {
  id: string;
  type: string;
  description: string;
  actor: string;
  actorName: string;
  details: Record<string, unknown> | null;
  createdAt: string;
}

interface EmailCaseDetail {
  id: string;
  caseNumber: string;
  fromEmail: string;
  subject: string;
  bodyText: string | null;
  status: string;
  priority: string;
  summary: string | null;
  detectedIntent: string | null;
  extractedData: Record<string, unknown> | null;
  pendingQuestion: string | null;
  questionOptions: string[] | null;
  receivedAt: string;
  activities: EmailCaseActivity[];
  attachments: { id: string; filename: string; contentType: string }[];
}

const statusConfig: Record<string, { label: string; variant: 'default' | 'success' | 'warning' | 'error' | 'info' }> = {
  RECEIVED: { label: 'Received', variant: 'info' },
  PROCESSING: { label: 'Processing', variant: 'info' },
  AWAITING_INPUT: { label: 'Needs Input', variant: 'warning' },
  IN_PROGRESS: { label: 'In Progress', variant: 'info' },
  COMPLETED: { label: 'Completed', variant: 'success' },
  ARCHIVED: { label: 'Archived', variant: 'default' },
};

const activityIconMap: Record<string, string> = {
  CASE_CREATED: 'mail',
  EMAIL_PARSED: 'analytics',
  CALENDAR_EVENT_CREATED: 'calendar',
  BILL_CREATED: 'card',
  VENDOR_CREATED: 'business',
  VENDOR_UPDATED: 'business',
  SYSTEM_ADDED: 'settings',
  TASK_CREATED: 'checkbox',
  DOCUMENT_SAVED: 'document',
  DISPUTE_DRAFT_CREATED: 'create',
  REMINDER_CREATED: 'alarm',
  WARRANTY_SAVED: 'shield-checkmark',
  SHIPPING_TRACKED: 'cube',
  NOTIFICATION_SENT: 'notifications',
  QUESTION_ASKED: 'help-circle',
  USER_RESPONDED: 'chatbubble',
  ALFRED_MESSAGE: 'chatbox-ellipses',
  STATUS_CHANGED: 'swap-horizontal',
  ACTION_FAILED: 'alert-circle',
};

export default function AlfredCaseDetailScreen() {
  const router = useRouter();
  const { id } = useLocalSearchParams<{ id: string }>();
  const [caseDetail, setCaseDetail] = useState<EmailCaseDetail | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [answer, setAnswer] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    if (id) {
      fetchCaseDetail();
    }
  }, [id]);

  const fetchCaseDetail = async () => {
    try {
      const token = await getIdToken();
      const response = await fetch(`${API_BASE_URL}/alfred/cases/${id}`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      const data = await response.json();
      setCaseDetail(data);
    } catch (err) {
      console.error('Failed to fetch case detail:', err);
      Alert.alert('Error', 'Failed to load case details');
    } finally {
      setIsLoading(false);
    }
  };

  const submitAnswer = async (selectedOption?: string) => {
    if (!answer.trim() && !selectedOption) {
      Alert.alert('Error', 'Please provide an answer');
      return;
    }

    setIsSubmitting(true);
    try {
      const token = await getIdToken();
      const response = await fetch(`${API_BASE_URL}/alfred/cases/${id}/answer`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          answer: selectedOption || answer,
          selectedOption,
        }),
      });

      if (response.ok) {
        setAnswer('');
        fetchCaseDetail(); // Refresh the case
        Alert.alert('Success', 'Your response has been sent to Alfred');
      } else {
        throw new Error('Failed to submit answer');
      }
    } catch (err) {
      console.error('Failed to submit answer:', err);
      Alert.alert('Error', 'Failed to send your response');
    } finally {
      setIsSubmitting(false);
    }
  };

  const archiveCase = async () => {
    Alert.alert(
      'Archive Case',
      'Are you sure you want to archive this case?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Archive',
          onPress: async () => {
            try {
              const token = await getIdToken();
              await fetch(`${API_BASE_URL}/alfred/cases/${id}/archive`, {
                method: 'POST',
                headers: { Authorization: `Bearer ${token}` },
              });
              router.back();
            } catch (err) {
              Alert.alert('Error', 'Failed to archive case');
            }
          },
        },
      ],
    );
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleString('en-US', {
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      hour12: true,
    });
  };

  const renderActivity = (activity: EmailCaseActivity) => {
    const icon = activityIconMap[activity.type] || 'ellipse';
    const isAlfred = activity.actor === 'alfred';
    const isError = activity.type === 'ACTION_FAILED';

    return (
      <View key={activity.id} style={styles.activityItem}>
        <View
          style={[
            styles.activityIcon,
            isError && { backgroundColor: `${colors.status.error}15` },
          ]}
        >
          <Ionicons
            name={`${icon}-outline` as any}
            size={18}
            color={isError ? colors.status.error : colors.haven.champagne[500]}
          />
        </View>
        <View style={styles.activityContent}>
          <Text style={[styles.activityText, isError && { color: colors.status.error }]}>
            {activity.description}
          </Text>
          <Text style={styles.activityMeta}>
            {isAlfred ? 'Alfred' : activity.actorName} - {formatDate(activity.createdAt)}
          </Text>
        </View>
      </View>
    );
  };

  if (isLoading || !caseDetail) {
    return (
      <View style={styles.fullContainer}>
        <AppHeader title="Case Details" showBack onBackPress={() => router.navigate('/(tabs)/settings/alfred-cases' as any)} />
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={colors.haven.champagne[500]} />
        </View>
      </View>
    );
  }

  const status = statusConfig[caseDetail.status] || statusConfig.RECEIVED;
  const needsInput = caseDetail.status === 'AWAITING_INPUT' && caseDetail.pendingQuestion;

  return (
    <KeyboardAvoidingView
      style={styles.fullContainer}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <AppHeader
        title={`Case #${caseDetail.caseNumber}`}
        showBack
        onBackPress={() => router.navigate('/(tabs)/settings/alfred-cases' as any)}
        rightAction={
          caseDetail.status !== 'ARCHIVED' ? (
            <TouchableOpacity onPress={archiveCase}>
              <Ionicons name="archive-outline" size={24} color={colors.white} />
            </TouchableOpacity>
          ) : undefined
        }
      />

      <ScrollView style={styles.scrollContainer} contentContainerStyle={styles.scrollContent}>
        {/* Header Card */}
        <Card style={styles.headerCard}>
          <View style={styles.headerRow}>
            <Text style={styles.subject}>{caseDetail.subject}</Text>
            <Badge label={status.label} variant={status.variant} />
          </View>
          <Text style={styles.fromEmail}>From: {caseDetail.fromEmail}</Text>
          <Text style={styles.receivedAt}>Received: {formatDate(caseDetail.receivedAt)}</Text>

          {caseDetail.summary && (
            <View style={styles.summaryBox}>
              <Ionicons name="sparkles" size={16} color={colors.haven.champagne[500]} />
              <Text style={styles.summaryText}>{caseDetail.summary}</Text>
            </View>
          )}

          {caseDetail.detectedIntent && (
            <View style={styles.intentBadge}>
              <Text style={styles.intentLabel}>Category:</Text>
              <Text style={styles.intentValue}>
                {caseDetail.detectedIntent.replace(/_/g, ' ')}
              </Text>
            </View>
          )}
        </Card>

        {/* Pending Question Card */}
        {needsInput && (
          <Card style={styles.questionCard}>
            <View style={styles.questionHeader}>
              <Ionicons name="help-circle" size={24} color={colors.haven.champagne[500]} />
              <Text style={styles.questionTitle}>Alfred needs your input</Text>
            </View>
            <Text style={styles.questionText}>{caseDetail.pendingQuestion}</Text>

            {caseDetail.questionOptions?.length ? (
              <View style={styles.optionsContainer}>
                {caseDetail.questionOptions.map((option, index) => (
                  <TouchableOpacity
                    key={index}
                    style={styles.optionButton}
                    onPress={() => submitAnswer(option)}
                    disabled={isSubmitting}
                  >
                    <Text style={styles.optionText}>{option}</Text>
                  </TouchableOpacity>
                ))}
              </View>
            ) : (
              <View style={styles.answerInputContainer}>
                <TextInput
                  style={styles.answerInput}
                  placeholder="Type your response..."
                  placeholderTextColor={colors.text.tertiary}
                  value={answer}
                  onChangeText={setAnswer}
                  multiline
                />
                <TouchableOpacity
                  style={[styles.sendButton, !answer.trim() && styles.sendButtonDisabled]}
                  onPress={() => submitAnswer()}
                  disabled={isSubmitting || !answer.trim()}
                >
                  {isSubmitting ? (
                    <ActivityIndicator size="small" color={colors.white} />
                  ) : (
                    <Ionicons name="send" size={20} color={colors.white} />
                  )}
                </TouchableOpacity>
              </View>
            )}
          </Card>
        )}

        {/* Attachments */}
        {caseDetail.attachments.length > 0 && (
          <Card style={styles.attachmentsCard}>
            <Text style={styles.sectionTitle}>Attachments</Text>
            {caseDetail.attachments.map((attachment) => (
              <View key={attachment.id} style={styles.attachmentItem}>
                <Ionicons name="document-outline" size={20} color={colors.text.secondary} />
                <Text style={styles.attachmentName}>{attachment.filename}</Text>
              </View>
            ))}
          </Card>
        )}

        {/* Activity Timeline */}
        <Card style={styles.timelineCard}>
          <Text style={styles.sectionTitle}>Activity Timeline</Text>
          <View style={styles.timeline}>
            {caseDetail.activities.map(renderActivity)}
          </View>
        </Card>

        {/* Original Email */}
        {caseDetail.bodyText && (
          <Card style={styles.emailCard}>
            <Text style={styles.sectionTitle}>Original Email</Text>
            <Text style={styles.emailBody}>{caseDetail.bodyText}</Text>
          </Card>
        )}
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  fullContainer: {
    flex: 1,
    backgroundColor: colors.haven.navy[900],
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.background.secondary,
  },
  scrollContainer: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  scrollContent: {
    padding: spacing[4],
    paddingBottom: spacing[8],
  },
  headerCard: {
    padding: spacing[4],
    marginBottom: spacing[3],
  },
  headerRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: spacing[2],
  },
  subject: {
    flex: 1,
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginRight: spacing[2],
  },
  fromEmail: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginBottom: spacing[1],
  },
  receivedAt: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  summaryBox: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    backgroundColor: `${colors.haven.champagne[500]}10`,
    padding: spacing[3],
    borderRadius: borderRadius.md,
    marginTop: spacing[3],
    gap: spacing[2],
  },
  summaryText: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.text.primary,
    lineHeight: 20,
  },
  intentBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: spacing[3],
    gap: spacing[2],
  },
  intentLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    textTransform: 'uppercase',
  },
  intentValue: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[500],
    fontWeight: typography.fontWeights.medium,
    textTransform: 'capitalize',
  },
  questionCard: {
    padding: spacing[4],
    marginBottom: spacing[3],
    borderWidth: 2,
    borderColor: colors.haven.champagne[500],
  },
  questionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    marginBottom: spacing[3],
  },
  questionTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.champagne[500],
  },
  questionText: {
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
    lineHeight: 24,
    marginBottom: spacing[4],
  },
  optionsContainer: {
    gap: spacing[2],
  },
  optionButton: {
    backgroundColor: colors.haven.champagne[50],
    paddingVertical: spacing[3],
    paddingHorizontal: spacing[4],
    borderRadius: borderRadius.md,
    borderWidth: 1,
    borderColor: colors.haven.champagne[200],
  },
  optionText: {
    fontSize: typography.fontSizes.base,
    color: colors.haven.champagne[600],
    textAlign: 'center',
    fontWeight: typography.fontWeights.medium,
  },
  answerInputContainer: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    gap: spacing[2],
  },
  answerInput: {
    flex: 1,
    backgroundColor: colors.gray[100],
    borderRadius: borderRadius.md,
    padding: spacing[3],
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
    maxHeight: 120,
  },
  sendButton: {
    width: 44,
    height: 44,
    borderRadius: borderRadius.md,
    backgroundColor: colors.haven.champagne[500],
    justifyContent: 'center',
    alignItems: 'center',
  },
  sendButtonDisabled: {
    backgroundColor: colors.gray[300],
  },
  attachmentsCard: {
    padding: spacing[4],
    marginBottom: spacing[3],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.tertiary,
    textTransform: 'uppercase',
    letterSpacing: 1,
    marginBottom: spacing[3],
  },
  attachmentItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    paddingVertical: spacing[2],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  attachmentName: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  timelineCard: {
    padding: spacing[4],
    marginBottom: spacing[3],
  },
  timeline: {
    gap: spacing[3],
  },
  activityItem: {
    flexDirection: 'row',
    gap: spacing[3],
  },
  activityIcon: {
    width: 36,
    height: 36,
    borderRadius: borderRadius.full,
    backgroundColor: `${colors.haven.champagne[500]}15`,
    justifyContent: 'center',
    alignItems: 'center',
  },
  activityContent: {
    flex: 1,
    paddingTop: spacing[1],
  },
  activityText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.primary,
    lineHeight: 20,
  },
  activityMeta: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: spacing[1],
  },
  emailCard: {
    padding: spacing[4],
    marginBottom: spacing[3],
  },
  emailBody: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    lineHeight: 22,
  },
});
