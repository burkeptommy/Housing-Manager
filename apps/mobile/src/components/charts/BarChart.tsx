import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import Svg, { Rect } from 'react-native-svg';
import { typography, colors, spacing, borderRadius } from '../../lib/theme';

interface BarData {
  label: string;
  value: number;
  color?: string;
}

interface BarChartProps {
  data: BarData[];
  width: number;
  height: number;
  barColor?: string;
  showLabels?: boolean;
  showValues?: boolean;
  formatValue?: (v: number) => string;
}

export function BarChart({
  data,
  width,
  height,
  barColor = colors.haven.purple[500],
  showLabels = true,
  showValues = false,
  formatValue,
}: BarChartProps) {
  if (!data || data.length === 0) return null;

  const labelHeight = showLabels ? 20 : 0;
  const valueHeight = showValues ? 16 : 0;
  const chartH = height - labelHeight - valueHeight;
  const max = Math.max(...data.map((d) => d.value), 1);

  const barGap = 4;
  const barWidth = Math.max((width - barGap * (data.length - 1)) / data.length, 4);

  return (
    <View style={{ width, height }}>
      <View style={{ flexDirection: 'row', alignItems: 'flex-end', height: chartH, gap: barGap }}>
        {data.map((d, i) => {
          const barH = Math.max((d.value / max) * chartH, 2);
          return (
            <View key={i} style={{ width: barWidth, alignItems: 'center' }}>
              {showValues && (
                <Text style={styles.valueText}>
                  {formatValue ? formatValue(d.value) : `$${Math.round(d.value)}`}
                </Text>
              )}
              <Svg width={barWidth} height={chartH}>
                <Rect
                  x={0}
                  y={chartH - barH}
                  width={barWidth}
                  height={barH}
                  rx={Math.min(barWidth / 2, 4)}
                  fill={d.color || barColor}
                />
              </Svg>
            </View>
          );
        })}
      </View>
      {showLabels && (
        <View style={[styles.labelRow, { gap: barGap }]}>
          {data.map((d, i) => (
            <Text key={i} style={[styles.labelText, { width: barWidth }]} numberOfLines={1}>
              {d.label}
            </Text>
          ))}
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  labelRow: {
    flexDirection: 'row',
    marginTop: spacing[1],
  },
  labelText: {
    fontSize: 10,
    color: colors.slate[400],
    textAlign: 'center',
  },
  valueText: {
    fontSize: 9,
    color: colors.slate[500],
    marginBottom: 2,
  },
});
