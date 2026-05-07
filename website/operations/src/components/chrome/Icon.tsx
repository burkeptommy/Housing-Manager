import type { CSSProperties } from "react";

/**
 * Inline SVG icon library — no Lucide, no icon font. Stroke 1.8 round
 * caps + joins to mirror SF Symbol Regular weight on Apple devices.
 *
 * Each entry is a path string for a 24×24 viewbox. Add icons here as
 * needed — keep the same line geometry style.
 */
const PATHS: Record<string, string> = {
  // Navigation
  grid: "M3 3h7v7H3zM14 3h7v7h-7zM3 14h7v7H3zM14 14h7v7h-7z",
  dispatch: "M3 12h13M3 6h18M3 18h11M19 9l3 3-3 3M14 15l-3 3 3 3",
  calendar: "M3 7h18M5 4v3M19 4v3M4 11h16v9a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1z",
  route: "M6 4h12M6 12h8M6 20h12M6 4a2 2 0 1 0 0 4M14 12a2 2 0 1 0 0 4M18 16a2 2 0 1 0 0 4",
  crew: "M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM2 21v-1a6 6 0 0 1 6-6h2a6 6 0 0 1 6 6v1M16 11a3 3 0 1 0 0-6M22 21v-1a5 5 0 0 0-3-4.6",
  home: "M3 12 12 4l9 8M5 10v10h14V10",
  quote: "M4 4h16v16H4zM4 9h16M9 13h6M9 16h4",
  message: "M4 5h16v11H8l-4 4z",
  search: "M11 4a7 7 0 1 1 0 14 7 7 0 0 1 0-14zM21 21l-5-5",
  bell: "M15 17h5l-1.4-1.4a2 2 0 0 1-.6-1.4V11a6 6 0 1 0-12 0v3.2a2 2 0 0 1-.6 1.4L4 17h5M9 17a3 3 0 0 0 6 0",
  plus: "M12 5v14M5 12h14",
  chevron: "M9 6l6 6-6 6",
  chevronDown: "M6 9l6 6 6-6",
  filter: "M4 6h16M7 12h10M10 18h4",
  more: "M5 12a1 1 0 1 0 0-2 1 1 0 0 0 0 2zM12 12a1 1 0 1 0 0-2 1 1 0 0 0 0 2zM19 12a1 1 0 1 0 0-2 1 1 0 0 0 0 2z",
  drag: "M9 5h.01M9 12h.01M9 19h.01M15 5h.01M15 12h.01M15 19h.01",
  remove: "M6 6l12 12M18 6L6 18",
  sparkles: "M12 3v3M12 18v3M3 12h3M18 12h3M5.6 5.6l2.1 2.1M16.3 16.3l2.1 2.1M5.6 18.4l2.1-2.1M16.3 7.7l2.1-2.1",
  truck: "M3 7h11v9H3zM14 10h4l3 3v3h-7z M6.5 19a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3zM17.5 19a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3z",
  clock: "M12 8v4l3 2M12 4a8 8 0 1 1 0 16 8 8 0 0 1 0-16z",
  check: "M5 12l5 5L20 7",
  send: "M3 11l18-7-7 18-3-7z",
  user: "M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM4 21a8 8 0 0 1 16 0",
  phone: "M22 16.92V19a2 2 0 0 1-2.18 2 19.86 19.86 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6A19.86 19.86 0 0 1 2.12 4.18 2 2 0 0 1 4.11 2h2.08a2 2 0 0 1 2 1.72c.13.96.36 1.9.68 2.81a2 2 0 0 1-.45 2.11L7.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.91.32 1.85.55 2.81.68A2 2 0 0 1 22 16.92z",
  mail: "M3 6h18v12H3zM3 6l9 7 9-7",
  briefcase: "M3 7h18v12H3zM8 7V5a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2",
  shield: "M12 3l8 4v5c0 5-3.4 8.5-8 9-4.6-.5-8-4-8-9V7z",
  history: "M3 12a9 9 0 1 0 3-6.7M3 4v5h5M12 8v4l3 2",
  lightbulb: "M9 20h6M10 23h4M12 3a7 7 0 0 0-4 12.7c.6.6 1 1.4 1 2.3v1h6v-1c0-.9.4-1.7 1-2.3A7 7 0 0 0 12 3z",
  lock: "M6 11h12v9H6zM8 11V8a4 4 0 0 1 8 0v3",
  bolt: "M13 2L4 14h7l-1 8 9-12h-7z",
  wrench: "M14.7 6.3a4 4 0 0 0-5.4 5.4L3 18l3 3 6.3-6.3a4 4 0 0 0 5.4-5.4l-2.5 2.5-2.5-2.5z",
  edit: "M16 3l5 5-12 12H4v-5z M14 5l5 5",
  trash: "M4 7h16M9 7V5a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2M6 7v13a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2V7M10 11v7M14 11v7",
  // Wave P: Settings screen + sidebar entry. 24x24 cog with center hole.
  // Stroke matches every other glyph at 1.8 with round caps/joins.
  gear: "M12 9.5a2.5 2.5 0 1 1 0 5 2.5 2.5 0 0 1 0-5zM19.4 13.6a7.6 7.6 0 0 0 0-3.2l2-1.5-2-3.4-2.3.9a7.6 7.6 0 0 0-2.8-1.6l-.4-2.4h-3.8l-.4 2.4a7.6 7.6 0 0 0-2.8 1.6l-2.3-.9-2 3.4 2 1.5a7.6 7.6 0 0 0 0 3.2l-2 1.5 2 3.4 2.3-.9a7.6 7.6 0 0 0 2.8 1.6l.4 2.4h3.8l.4-2.4a7.6 7.6 0 0 0 2.8-1.6l2.3.9 2-3.4z",
  // Wave Q: Invoices nav entry. Receipt with line items.
  receipt: "M5 3v18l3-2 3 2 3-2 3 2 3-2V3zM8 8h8M8 12h8M8 16h5",
};

interface IconProps {
  name: keyof typeof PATHS | string;
  size?: number;
  stroke?: number;
  color?: string;
  className?: string;
  style?: CSSProperties;
}

export function Icon({
  name,
  size = 18,
  stroke = 1.8,
  color = "currentColor",
  className,
  style,
}: IconProps) {
  const d = PATHS[name as keyof typeof PATHS];
  if (!d) return null;
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke={color}
      strokeWidth={stroke}
      strokeLinecap="round"
      strokeLinejoin="round"
      className={`ops-icon ${className ?? ""}`}
      style={style}
      aria-hidden="true"
    >
      <path d={d} />
    </svg>
  );
}
