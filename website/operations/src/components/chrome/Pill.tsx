import type { ReactNode } from "react";

export type PillTone =
  | "neutral"
  | "indigo"
  | "salmon"
  | "success"
  | "warning"
  | "critical"
  | "info";

interface PillProps {
  tone?: PillTone;
  withDot?: boolean;
  children: ReactNode;
}

export function Pill({ tone = "neutral", withDot = false, children }: PillProps) {
  return (
    <span className={`ops-pill ops-pill--${tone}`}>
      {withDot && <span className="ops-pill__dot" aria-hidden="true" />}
      {children}
    </span>
  );
}
