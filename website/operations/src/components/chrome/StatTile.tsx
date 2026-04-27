import type { ReactNode } from "react";

interface StatTileProps {
  label: string;
  value: string | number;
  sub?: string;
  accent?: boolean;
  trailing?: ReactNode;
}

export function StatTile({ label, value, sub, accent = false, trailing }: StatTileProps) {
  return (
    <div className={`ops-stat ${accent ? "ops-stat--accent" : ""}`}>
      <div className="ops-stat__label">{label}</div>
      <div className="ops-stat__value">{value}</div>
      {sub && <div className="ops-stat__sub">{sub}</div>}
      {trailing}
    </div>
  );
}
