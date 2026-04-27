import type { CSSProperties, MouseEvent, ReactNode } from "react";

interface CardProps {
  children: ReactNode;
  padding?: "default" | "tight";
  hoverable?: boolean;
  onClick?: (e: MouseEvent<HTMLDivElement>) => void;
  className?: string;
  style?: CSSProperties;
}

export function Card({
  children,
  padding = "default",
  hoverable = false,
  onClick,
  className,
  style,
}: CardProps) {
  const classes = [
    "ops-card",
    padding === "tight" ? "is-padded-tight" : "",
    hoverable ? "is-hoverable" : "",
    className ?? "",
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <div
      className={classes}
      style={style}
      onClick={onClick}
      role={onClick ? "button" : undefined}
      tabIndex={onClick ? 0 : undefined}
    >
      {children}
    </div>
  );
}
