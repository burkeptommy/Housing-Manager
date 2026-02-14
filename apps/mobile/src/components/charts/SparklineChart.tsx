import React from 'react';
import { View } from 'react-native';
import Svg, { Path, Defs, LinearGradient, Stop } from 'react-native-svg';

interface SparklineChartProps {
  data: number[];
  width: number;
  height: number;
  color?: string;
  fillOpacity?: number;
  strokeWidth?: number;
}

export function SparklineChart({
  data,
  width,
  height,
  color = '#7c3aed',
  fillOpacity = 0.15,
  strokeWidth = 2,
}: SparklineChartProps) {
  if (!data || data.length < 2) return null;

  const padding = strokeWidth;
  const chartW = width - padding * 2;
  const chartH = height - padding * 2;

  const max = Math.max(...data);
  const min = Math.min(...data);
  const range = max - min || 1;

  const points = data.map((val, i) => ({
    x: padding + (i / (data.length - 1)) * chartW,
    y: padding + chartH - ((val - min) / range) * chartH,
  }));

  // Build smooth path using cubic bezier
  let linePath = `M ${points[0].x},${points[0].y}`;
  for (let i = 1; i < points.length; i++) {
    const prev = points[i - 1];
    const curr = points[i];
    const cpx = (prev.x + curr.x) / 2;
    linePath += ` C ${cpx},${prev.y} ${cpx},${curr.y} ${curr.x},${curr.y}`;
  }

  // Fill area path
  const fillPath = `${linePath} L ${points[points.length - 1].x},${height} L ${points[0].x},${height} Z`;

  return (
    <View style={{ width, height }}>
      <Svg width={width} height={height}>
        <Defs>
          <LinearGradient id="sparkFill" x1="0" y1="0" x2="0" y2="1">
            <Stop offset="0" stopColor={color} stopOpacity={fillOpacity} />
            <Stop offset="1" stopColor={color} stopOpacity={0} />
          </LinearGradient>
        </Defs>
        <Path d={fillPath} fill="url(#sparkFill)" />
        <Path d={linePath} fill="none" stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" />
      </Svg>
    </View>
  );
}
