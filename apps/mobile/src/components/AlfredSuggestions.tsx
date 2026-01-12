import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, typography, spacing, borderRadius } from '../lib/theme';

// =============================================================================
// TYPES
// =============================================================================

interface Suggestion {
  id: string;
  text: string;
  icon: keyof typeof Ionicons.glyphMap;
}

interface AlfredSuggestionsProps {
  onSelect: (text: string) => void;
}

// =============================================================================
// SUGGESTIONS DATA
// =============================================================================

const SUGGESTIONS: Suggestion[] = [
  { id: '1', text: "What's on my maintenance checklist?", icon: 'list-outline' },
  { id: '2', text: 'Book a handyman visit', icon: 'construct-outline' },
  { id: '3', text: 'I have a bill to add', icon: 'receipt-outline' },
  { id: '4', text: 'Schedule HVAC maintenance', icon: 'thermometer-outline' },
  { id: '5', text: 'Find a plumber for a leak', icon: 'water-outline' },
  { id: '6', text: 'What home systems do I have?', icon: 'home-outline' },
];

// =============================================================================
// ALFRED SUGGESTIONS COMPONENT
// =============================================================================

export function AlfredSuggestions({ onSelect }: AlfredSuggestionsProps) {
  return (
    <View style={styles.container}>
      <Text style={styles.label}>Suggestions</Text>
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.scrollContent}
      >
        {SUGGESTIONS.map((suggestion) => (
          <TouchableOpacity
            key={suggestion.id}
            style={styles.suggestion}
            onPress={() => onSelect(suggestion.text)}
            activeOpacity={0.7}
          >
            <Ionicons
              name={suggestion.icon}
              size={16}
              color={colors.haven.champagne[600]}
              style={styles.icon}
            />
            <Text style={styles.text} numberOfLines={1}>
              {suggestion.text}
            </Text>
          </TouchableOpacity>
        ))}
      </ScrollView>
    </View>
  );
}

// =============================================================================
// STYLES
// =============================================================================

const styles = StyleSheet.create({
  container: {
    marginBottom: spacing[4],
  },
  label: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.tertiary,
    marginBottom: spacing[2],
    marginLeft: spacing[1],
  },
  scrollContent: {
    paddingHorizontal: spacing[1],
    gap: spacing[2],
  },
  suggestion: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[2],
    backgroundColor: colors.haven.champagne[50],
    borderRadius: borderRadius.full,
    borderWidth: 1,
    borderColor: colors.haven.champagne[200],
  },
  icon: {
    marginRight: spacing[2],
  },
  text: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[600],
    fontWeight: typography.fontWeights.medium,
    maxWidth: 180,
  },
});
