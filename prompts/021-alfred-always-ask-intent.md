# Haven: Alfred Email - Always Ask Intent Enhancement

**Created:** February 3, 2026
**Priority:** HIGH - Core UX for beta launch 2/15
**Prerequisite:** Run 011b first to fix Firebase auth

---

## OVERVIEW

Enhance Alfred's email processing to ALWAYS ask users what they want done with forwarded emails. Even when Alfred is 99% confident about intent, he should confirm first with a conversational tone and quick action buttons.

**Principle:** Every forwarded email is HIGH INTENT. Users don't CC Alfred for no reason. But Alfred should never assume - always ask, always confirm.

---

## CURRENT vs. NEW BEHAVIOR

### Current (Wrong)
```
User forwards camp registration email
→ Alfred auto-creates calendar event
→ Alfred auto-logs fee
→ User notified: "Done! Added Emma's camp to calendar."
```

### New (Correct)
```
User forwards camp registration email
→ Alfred creates Case
→ Alfred analyzes email
→ Alfred asks user IN CHAT with friendly message + action buttons:

"Hey! 📧 Got your email about Camp Wonderland.

I can see it's a summer camp running June 15-19 with a $450 registration fee.

What would you like me to do?

[Add to Calendar]  [Track Fee as Bill]  [Save Camp Contact]  [All of the Above]  [Something Else...]"
```

---

## IMPLEMENTATION

### Phase 1: Modify Email Parser Response

**File:** `apps/api/src/alfred-email/email-parser.service.ts`

Update the Claude prompt to ALWAYS return suggestions, never auto-actions:

```typescript
const systemPrompt = `You are Alfred, Haven's friendly AI home assistant. Your job is to analyze emails that homeowners forward to you and suggest helpful actions.

CRITICAL BEHAVIOR:
- NEVER auto-execute actions
- ALWAYS suggest what you could do
- ALWAYS be conversational and warm
- ALWAYS offer "Something else..." as an option
- Extract all relevant data for potential actions

The household has the following context:
- Family members: ${JSON.stringify(input.householdContext.members)}
- Children: ${JSON.stringify(input.householdContext.children)}
- Known vendors: ${JSON.stringify(input.householdContext.vendors)}
- Home systems: ${JSON.stringify(input.householdContext.systems)}

Your response must include:
1. A friendly greeting acknowledging the email
2. A brief summary of what you see in the email
3. 2-5 suggested actions as button labels
4. Always include "Something else..." as the last option
5. Extracted data for each suggested action (so we can execute if user approves)

TONE GUIDELINES:
- Warm and conversational, like a helpful friend
- Use occasional emojis sparingly (📧 📅 💵 📋)
- Be efficient but not robotic
- Show that you understand the context

Example response format:
{
  "greeting": "Hey! 📧 Got your email about [subject summary].",
  "summary": "I can see [key observations from email].",
  "suggestedActions": [
    {
      "label": "Add to Calendar",
      "type": "CALENDAR",
      "data": { "title": "...", "startDate": "...", ... }
    },
    {
      "label": "Track as Bill",
      "type": "BILL", 
      "data": { "vendor": "...", "amount": ..., "dueDate": "..." }
    },
    {
      "label": "Something else...",
      "type": "CUSTOM",
      "data": null
    }
  ],
  "confidence": 0.85,
  "emailType": "CAMP_REGISTRATION"
}`;
```

### Phase 2: Update Email Case Flow

**File:** `apps/api/src/alfred-email/alfred-email.service.ts`

Modify `processInboundEmail` to ALWAYS create an awaiting-input case:

```typescript
async processInboundEmail(emailData: InboundEmailData) {
  // ... existing validation code ...

  // 6. Parse email with Claude
  const parseResult = await this.emailParser.parseEmail({
    subject: emailData.subject,
    body: emailData.text || emailData.html || '',
    attachments: emailData.attachments,
    householdContext: await this.getHouseholdContext(household.id),
  });

  // 7. ALWAYS set to AWAITING_INPUT - never auto-execute
  const caseNumber = await generateCaseNumber(this.prisma);
  
  const emailCase = await this.prisma.emailCase.create({
    data: {
      householdId: household.id,
      caseNumber,
      messageId: emailData.messageId || `msg_${Date.now()}`,
      fromEmail: senderEmail,
      fromName: this.extractName(emailData.from),
      subject: emailData.subject,
      bodyText: emailData.text,
      bodyHtml: emailData.html,
      receivedAt: new Date(),
      status: 'AWAITING_INPUT', // ALWAYS await user input
      summary: parseResult.summary,
      detectedIntent: parseResult.emailType,
      extractedData: parseResult,
      confidence: parseResult.confidence,
      pendingQuestion: this.buildAlfredMessage(parseResult),
      questionOptions: parseResult.suggestedActions,
    },
  });

  // 8. Log activity
  await this.prisma.emailCaseActivity.create({
    data: {
      caseId: emailCase.id,
      type: 'CASE_CREATED',
      description: `Email received and analyzed`,
      actor: 'alfred',
      actorName: 'Alfred',
    },
  });

  // 9. Create Alfred chat message for user
  await this.createAlfredChatMessage(household.id, emailCase);

  return emailCase;
}

private buildAlfredMessage(parseResult: any): string {
  return `${parseResult.greeting}\n\n${parseResult.summary}\n\nWhat would you like me to do?`;
}
```

### Phase 3: Action Execution Endpoint

**File:** `apps/api/src/alfred-email/alfred-email.controller.ts`

Add endpoint for executing user-selected actions:

```typescript
/**
 * Execute selected action(s) from email case
 */
@Post('cases/:caseId/execute')
@UseGuards(JwtAuthGuard)
async executeAction(
  @CurrentUser() user: User,
  @Param('caseId') caseId: string,
  @Body() body: { 
    actionTypes: string[];  // ['CALENDAR', 'BILL'] or ['CUSTOM']
    customRequest?: string; // If user selected "Something else..."
  },
) {
  return this.alfredEmailService.executeSelectedActions(user, caseId, body);
}
```

**File:** `apps/api/src/alfred-email/alfred-email.service.ts`

```typescript
async executeSelectedActions(
  user: User,
  caseId: string,
  body: { actionTypes: string[]; customRequest?: string },
) {
  const household = await this.getHousehold(user);
  const emailCase = await this.prisma.emailCase.findFirst({
    where: { id: caseId, householdId: household.id },
  });

  if (!emailCase) throw new BadRequestException('Case not found');

  const extractedData = emailCase.extractedData as any;
  const actions: any[] = [];

  // Handle "Something else..." custom request
  if (body.actionTypes.includes('CUSTOM') && body.customRequest) {
    // Re-process with Claude using user's custom instruction
    const customResult = await this.emailParser.parseWithCustomIntent(
      emailCase,
      body.customRequest,
    );
    
    // Ask again with new suggestions based on custom request
    await this.prisma.emailCase.update({
      where: { id: caseId },
      data: {
        pendingQuestion: customResult.greeting + '\n\n' + customResult.summary,
        questionOptions: customResult.suggestedActions,
      },
    });

    await this.prisma.emailCaseActivity.create({
      data: {
        caseId,
        type: 'ALFRED_MESSAGE',
        description: `User requested: "${body.customRequest}"`,
        actor: 'user',
        actorName: user.firstName || 'User',
      },
    });

    return { status: 'awaiting_input', message: customResult };
  }

  // Execute selected actions
  for (const actionType of body.actionTypes) {
    const actionData = extractedData.suggestedActions?.find(
      (a: any) => a.type === actionType
    );

    if (!actionData) continue;

    try {
      switch (actionType) {
        case 'CALENDAR':
          const event = await this.executeCalendarAction(household.id, actionData.data);
          actions.push({ type: 'CALENDAR', success: true, id: event.id });
          break;
        
        case 'BILL':
          const bill = await this.executeBillAction(household.id, actionData.data);
          actions.push({ type: 'BILL', success: true, id: bill.id });
          break;

        case 'VENDOR':
          const vendor = await this.executeVendorAction(household.id, actionData.data);
          actions.push({ type: 'VENDOR', success: true, id: vendor.id });
          break;

        case 'TASK':
          const task = await this.executeTaskAction(household.id, actionData.data);
          actions.push({ type: 'TASK', success: true, id: task.id });
          break;

        case 'DOCUMENT':
          const doc = await this.executeDocumentAction(household.id, actionData.data);
          actions.push({ type: 'DOCUMENT', success: true, id: doc.id });
          break;
      }

      // Log each action
      await this.prisma.emailCaseActivity.create({
        data: {
          caseId,
          type: `${actionType}_CREATED` as any,
          description: `Created ${actionType.toLowerCase()} from email`,
          actor: 'alfred',
          actorName: 'Alfred',
        },
      });
    } catch (error) {
      actions.push({ type: actionType, success: false, error: error.message });
    }
  }

  // Update case status
  await this.prisma.emailCase.update({
    where: { id: caseId },
    data: {
      status: 'COMPLETED',
      actionsTaken: actions,
      resolvedAt: new Date(),
    },
  });

  // Send confirmation message
  const confirmationMessage = this.buildConfirmationMessage(actions);
  
  await this.prisma.emailCaseActivity.create({
    data: {
      caseId,
      type: 'CASE_RESOLVED',
      description: confirmationMessage,
      actor: 'alfred',
      actorName: 'Alfred',
    },
  });

  return { status: 'completed', actions, message: confirmationMessage };
}

private buildConfirmationMessage(actions: any[]): string {
  const successful = actions.filter(a => a.success);
  if (successful.length === 0) return "Hmm, I ran into some issues. Let me try again?";
  
  const items = successful.map(a => {
    switch (a.type) {
      case 'CALENDAR': return '📅 Added to calendar';
      case 'BILL': return '💵 Tracking the bill';
      case 'VENDOR': return '📋 Saved contact info';
      case 'TASK': return '✅ Created task';
      case 'DOCUMENT': return '📄 Saved document';
      default: return `✓ ${a.type}`;
    }
  });

  return `Done! ✨\n\n${items.join('\n')}\n\nAnything else you need?`;
}
```

### Phase 4: Mobile Cases Screen with Action Buttons

**File:** `apps/mobile/app/(tabs)/alfred/cases/[id].tsx`

```tsx
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
import { ScreenContainer } from '../../../../src/components';
import { colors, spacing, typography, borderRadius } from '../../../../src/lib/theme';
import { useAuth } from '../../../../src/hooks/useAuth';
import { getIdToken } from '../../../../src/lib/firebase';

const API_URL = process.env.EXPO_PUBLIC_API_URL;

interface SuggestedAction {
  label: string;
  type: string;
  data: any;
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
  actionsTaken?: any[];
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
      const response = await fetch(`${API_URL}/alfred/cases/${id}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      const data = await response.json();
      setEmailCase(data);
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
      setSelectedActions(prev => 
        prev.includes(actionType)
          ? prev.filter(a => a !== actionType)
          : [...prev.filter(a => a !== 'CUSTOM'), actionType]
      );
    }
  };

  const executeActions = async () => {
    if (selectedActions.length === 0) {
      Alert.alert('Select an action', 'Please choose what you\'d like me to do.');
      return;
    }

    setIsExecuting(true);
    try {
      const token = await getIdToken();
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
        Alert.alert('Done! ✨', result.message, [
          { text: 'Great!', onPress: () => router.back() }
        ]);
      } else {
        // Re-fetch case for new suggestions
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
                    <Text style={[
                      styles.actionButtonText,
                      isSelected && styles.actionButtonTextSelected,
                    ]}>
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
                <Text style={styles.customInputLabel}>
                  What would you like me to do?
                </Text>
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
            <View style={styles.actionsList}>
              {emailCase.actionsTaken.map((action: any, index: number) => (
                <View key={index} style={styles.completedAction}>
                  <Ionicons
                    name={action.success ? 'checkmark' : 'close'}
                    size={16}
                    color={action.success ? colors.status.success : colors.status.error}
                  />
                  <Text style={styles.completedActionText}>
                    {action.type.replace('_', ' ').toLowerCase()}
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

function getActionIcon(type: string): string {
  switch (type) {
    case 'CALENDAR': return 'calendar';
    case 'BILL': return 'receipt';
    case 'VENDOR': return 'people';
    case 'TASK': return 'checkbox';
    case 'DOCUMENT': return 'document';
    case 'CUSTOM': return 'chatbubble-ellipses';
    default: return 'ellipsis-horizontal';
  }
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
    fontWeight: typography.fontWeights.semibold,
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
    fontWeight: typography.fontWeights.bold,
    fontSize: typography.fontSizes.base,
  },
  alfredName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.navy[900],
  },
  alfredBubble: {
    backgroundColor: colors.haven.softGreen,
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
    borderStyle: 'dashed',
  },
  actionButtonText: {
    flex: 1,
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
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
    fontWeight: typography.fontWeights.semibold,
  },
  completedSection: {
    margin: spacing[4],
    padding: spacing[4],
    backgroundColor: colors.haven.softGreen,
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
    fontWeight: typography.fontWeights.semibold,
    color: colors.status.success,
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
```

---

## Phase 5: Cases List Screen

**File:** `apps/mobile/app/(tabs)/alfred/cases/index.tsx`

```tsx
import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  RefreshControl,
  ActivityIndicator,
} from 'react-native';
import { router } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { ScreenContainer } from '../../../../src/components';
import { colors, spacing, typography, borderRadius } from '../../../../src/lib/theme';
import { getIdToken } from '../../../../src/lib/firebase';

const API_URL = process.env.EXPO_PUBLIC_API_URL;

interface EmailCase {
  id: string;
  caseNumber: string;
  subject: string;
  fromEmail: string;
  receivedAt: string;
  status: string;
  summary?: string;
}

export default function CasesListScreen() {
  const [cases, setCases] = useState<EmailCase[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [filter, setFilter] = useState<'all' | 'active' | 'completed'>('all');

  const fetchCases = useCallback(async () => {
    try {
      const token = await getIdToken();
      const response = await fetch(`${API_URL}/alfred/cases`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      const data = await response.json();
      setCases(data);
    } catch (error) {
      console.error('Failed to fetch cases:', error);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, []);

  useEffect(() => {
    fetchCases();
  }, [fetchCases]);

  const onRefresh = () => {
    setIsRefreshing(true);
    fetchCases();
  };

  const filteredCases = cases.filter(c => {
    if (filter === 'all') return true;
    if (filter === 'active') return c.status === 'AWAITING_INPUT' || c.status === 'PROCESSING';
    if (filter === 'completed') return c.status === 'COMPLETED';
    return true;
  });

  const activeCount = cases.filter(c => 
    c.status === 'AWAITING_INPUT' || c.status === 'PROCESSING'
  ).length;

  const renderCase = ({ item }: { item: EmailCase }) => {
    const isActive = item.status === 'AWAITING_INPUT' || item.status === 'PROCESSING';
    
    return (
      <TouchableOpacity
        style={styles.caseCard}
        onPress={() => router.push(`/(tabs)/alfred/cases/${item.id}`)}
      >
        <View style={styles.caseHeader}>
          <View style={[
            styles.statusDot,
            isActive ? styles.statusActive : styles.statusCompleted,
          ]} />
          <Text style={styles.caseNumber}>{item.caseNumber}</Text>
          <Text style={styles.caseDate}>
            {new Date(item.receivedAt).toLocaleDateString('en-US', {
              month: 'short',
              day: 'numeric',
            })}
          </Text>
        </View>
        <Text style={styles.caseSubject} numberOfLines={2}>
          {item.subject}
        </Text>
        {isActive && (
          <View style={styles.actionNeeded}>
            <Ionicons name="chatbubble" size={14} color={colors.haven.sage[600]} />
            <Text style={styles.actionNeededText}>Alfred needs your input</Text>
          </View>
        )}
      </TouchableOpacity>
    );
  };

  if (isLoading) {
    return (
      <ScreenContainer title="Email Cases" showBack>
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={colors.haven.sage[500]} />
        </View>
      </ScreenContainer>
    );
  }

  return (
    <ScreenContainer title="Email Cases" showBack>
      {/* Filter Tabs */}
      <View style={styles.filterContainer}>
        <TouchableOpacity
          style={[styles.filterTab, filter === 'all' && styles.filterTabActive]}
          onPress={() => setFilter('all')}
        >
          <Text style={[styles.filterText, filter === 'all' && styles.filterTextActive]}>
            All ({cases.length})
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.filterTab, filter === 'active' && styles.filterTabActive]}
          onPress={() => setFilter('active')}
        >
          <Text style={[styles.filterText, filter === 'active' && styles.filterTextActive]}>
            Needs Action ({activeCount})
          </Text>
          {activeCount > 0 && (
            <View style={styles.filterBadge}>
              <Text style={styles.filterBadgeText}>{activeCount}</Text>
            </View>
          )}
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.filterTab, filter === 'completed' && styles.filterTabActive]}
          onPress={() => setFilter('completed')}
        >
          <Text style={[styles.filterText, filter === 'completed' && styles.filterTextActive]}>
            Done
          </Text>
        </TouchableOpacity>
      </View>

      {/* Cases List */}
      <FlatList
        data={filteredCases}
        keyExtractor={(item) => item.id}
        renderItem={renderCase}
        contentContainerStyle={styles.listContent}
        refreshControl={
          <RefreshControl refreshing={isRefreshing} onRefresh={onRefresh} />
        }
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Ionicons name="mail-open-outline" size={48} color={colors.haven.navy[300]} />
            <Text style={styles.emptyTitle}>No emails yet</Text>
            <Text style={styles.emptyText}>
              Forward or CC Alfred on any email and it'll show up here.
            </Text>
          </View>
        }
      />
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  filterContainer: {
    flexDirection: 'row',
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[2],
    gap: spacing[2],
    backgroundColor: colors.white,
    borderBottomWidth: 1,
    borderBottomColor: colors.border.default,
  },
  filterTab: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[3],
    borderRadius: borderRadius.full,
    gap: spacing[1],
  },
  filterTabActive: {
    backgroundColor: colors.haven.navy[100],
  },
  filterText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[500],
  },
  filterTextActive: {
    color: colors.haven.navy[900],
    fontWeight: typography.fontWeights.medium,
  },
  filterBadge: {
    backgroundColor: colors.haven.sage[500],
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 10,
  },
  filterBadgeText: {
    color: colors.white,
    fontSize: 10,
    fontWeight: typography.fontWeights.bold,
  },
  listContent: {
    padding: spacing[4],
    gap: spacing[3],
  },
  caseCard: {
    backgroundColor: colors.white,
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.border.default,
  },
  caseHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing[2],
  },
  statusDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginRight: spacing[2],
  },
  statusActive: {
    backgroundColor: colors.haven.sage[500],
  },
  statusCompleted: {
    backgroundColor: colors.haven.navy[300],
  },
  caseNumber: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[500],
    fontFamily: 'monospace',
  },
  caseDate: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[400],
  },
  caseSubject: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.navy[900],
    marginBottom: spacing[2],
  },
  actionNeeded: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
  },
  actionNeededText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.sage[600],
    fontWeight: typography.fontWeights.medium,
  },
  emptyContainer: {
    alignItems: 'center',
    paddingVertical: spacing[12],
  },
  emptyTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.navy[700],
    marginTop: spacing[4],
    marginBottom: spacing[2],
  },
  emptyText: {
    fontSize: typography.fontSizes.base,
    color: colors.haven.navy[500],
    textAlign: 'center',
    paddingHorizontal: spacing[8],
  },
});
```

---

## VERIFICATION CHECKLIST

### API Changes
- [ ] EmailParser returns suggestions, not auto-actions
- [ ] Every email case starts as AWAITING_INPUT
- [ ] /cases/:id/execute endpoint handles action execution
- [ ] Custom "Something else" triggers re-analysis
- [ ] Confirmation messages are conversational

### Mobile App
- [ ] Cases list shows active vs completed
- [ ] Case detail shows Alfred's message
- [ ] Action buttons are tappable and multi-selectable
- [ ] "Something else..." opens text input
- [ ] Execute button sends selected actions
- [ ] Confirmation shows what was done

### User Experience
- [ ] Alfred never auto-executes without confirmation
- [ ] Messages feel conversational, not robotic
- [ ] Users can always say "Something else..."
- [ ] Quick actions match email content
- [ ] Success messages are friendly

---

## TEST SCENARIOS

### 1. Camp Registration
**Email:** "Your child is registered for Camp Wonderland, June 15-19. Fee: $450."
**Alfred says:** "Hey! 📧 Got your email about Camp Wonderland. I can see it's a summer camp running June 15-19 with a $450 registration fee. What would you like me to do?"
**Options:** [Add to Calendar] [Track Fee] [Both] [Something else...]

### 2. Utility Bill
**Email:** "Your Eversource bill is ready. Amount: $187.43. Due: Feb 15."
**Alfred says:** "Hey! 💵 Got your Eversource bill. It's $187.43 due on February 15th. What would you like me to do?"
**Options:** [Track this Bill] [Something else...]

### 3. Vendor Quote  
**Email:** "Here's your quote for gutter cleaning: $275. Valid through March 1."
**Alfred says:** "Hey! 📋 Got a quote from ABC Gutters for $275. Want me to save this?"
**Options:** [Save Quote] [Add to Vendors] [Create Reminder] [Something else...]

### 4. Unknown Email
**Email:** Random newsletter forward
**Alfred says:** "Hey! 📧 Got your forwarded email about [subject]. I see it's from [sender]. What would you like me to do with this?"
**Options:** [Save for Reference] [Create Task] [Something else...]

---

## DEPLOYMENT

```bash
# 1. Run migration (if schema changes needed)
cd apps/api
pnpm prisma migrate dev --name alfred_always_ask

# 2. Deploy API
gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616

# 3. Build mobile
cd apps/mobile
eas build --platform ios --profile production --auto-submit
```
