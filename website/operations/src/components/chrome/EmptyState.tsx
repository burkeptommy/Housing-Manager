import type { ReactNode } from "react";
import { Icon } from "./Icon";

interface EmptyStateProps {
  icon?: string;
  title: string;
  body: string;
  cta?: { label: string; onClick: () => void };
  trailing?: ReactNode;
}

export function EmptyState({ icon = "sparkles", title, body, cta, trailing }: EmptyStateProps) {
  return (
    <div className="ops-empty">
      <div className="ops-empty__icon">
        <Icon name={icon} size={22} stroke={1.9} />
      </div>
      <div className="ops-empty__title">{title}</div>
      <p className="ops-empty__body">{body}</p>
      {cta && (
        <button className="ops-button ops-button--salmon" onClick={cta.onClick}>
          {cta.label}
        </button>
      )}
      {trailing}
    </div>
  );
}
