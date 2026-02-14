import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import Svg, { Circle } from 'react-native-svg';
import { typography, colors } from '../../lib/theme';

interface DonutSegment {
  value: number;
  color: string;
  label?: string;
}

interface DonutChartProps {
  segments: DonutSegment[];
  size: number;
  strokeWidth?: number;
  centerLabel?: string;
  centerValue?: string;
}

export function DonutChart({
  segments,
  size,
  strokeWidth = 12,
  centerLabel,
  centerValue,
}: DonutChartProps) {
  if (!segments || segments.length === 0) return null;

  const radius = (size - strokeWidth) / 2;
  const circumference = 2 * Math.PI * radius;
  const center = size / 2;
  const total = segments.reduce((s, seg) => s + seg.value, 0);

  if (total === 0) return null;

  let cumulativePercent = 0;

  return (
    <View style={{ width: size, height: size, alignItems: 'center', justifyContent: 'center' }}>
      <Svg width={size} height={size}>
        {/* Background circle */}
        <Circle
          cx={center}
          cy={center}
          r={radius}
          fill="none"
          stroke={colors.slate[100]}
          strokeWidth={strokeWidth}
        />
        {segments.map((seg, i) => {
          const percent = seg.value / total;
          const dashLength = circumference * percent;
          const dashOffset = circumference * (1 - cumulativePercent) + circumference * 0.25;
          cumulativePercent += percent;

          return (
            <Circle
              key={i}
              cx={center}
              cy={center}
              r={radius}
              fill="none"
              stroke={seg.color}
              strokeWidth={strokeWidth}
              strokeDasharray={`${dashLength} ${circumference - dashLength}`}
              strokeDashoffset={dashOffset}
              strokeLinecap="round"
            />
          );
        })}
      </Svg>
      {(centerLabel || centerValue) && (
        <View style={[StyleSheet.absoluteFill, styles.center]}>
          {centerValue && <Text style={styles.centerValue}>{centerValue}</Text>}
          {centerLabel && <Text style={styles.centerLabel}>{centerLabel}</Text>}
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  center: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  centerValue: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.slate[900],
  },
  centerLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
    marginTop: 2,
  },
});
