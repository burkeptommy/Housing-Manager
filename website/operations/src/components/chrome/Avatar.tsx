interface AvatarProps {
  initials: string;
  color?: string;       // hex; defaults to var(--indigo)
  size?: number;        // px; default 36
  fontSize?: number;    // px; defaults derive from size
  imageUrl?: string;
}

export function Avatar({
  initials,
  color,
  size = 36,
  fontSize,
  imageUrl,
}: AvatarProps) {
  if (imageUrl) {
    return (
      <img
        className="ops-avatar"
        src={imageUrl}
        alt={initials}
        style={{
          width: size,
          height: size,
          objectFit: "cover",
        }}
      />
    );
  }
  return (
    <span
      className="ops-avatar"
      style={{
        width: size,
        height: size,
        background: color ?? undefined,
        fontSize: fontSize ?? Math.round(size * 0.4),
      }}
    >
      {initials}
    </span>
  );
}

/// Initials helper — given "Mara Chen" returns "MC"; "Tom" returns "T".
export function initialsFor(name: string): string {
  return name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0]?.toUpperCase() ?? "")
    .join("");
}
