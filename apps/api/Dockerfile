# Haven API Dockerfile - Optimized for Google Cloud Run
# Multi-stage build for minimal image size

# ============================================================================
# Stage 1: Dependencies & Build
# ============================================================================
FROM node:20-alpine AS builder

RUN apk add --no-cache libc6-compat openssl

WORKDIR /app

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Copy workspace configuration
COPY pnpm-lock.yaml pnpm-workspace.yaml ./
COPY package.json ./

# Copy package.json files for all workspaces
COPY apps/api/package.json ./apps/api/
COPY packages/core/package.json ./packages/core/
COPY packages/config/package.json ./packages/config/

# Install dependencies
RUN pnpm install --frozen-lockfile --prod=false

# Copy source code
COPY . .

# Build @haven/core first (it's a dependency)
WORKDIR /app/packages/core
RUN pnpm build

# Generate Prisma client and build API
WORKDIR /app/apps/api
RUN npx prisma generate
RUN pnpm build

# ============================================================================
# Stage 2: Production Runner
# ============================================================================
FROM node:20-alpine AS runner

RUN apk add --no-cache libc6-compat openssl dumb-init

# Create non-root user for security
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nestjs

WORKDIR /app

# Copy package.json and modify it to remove workspace protocol
COPY --from=builder /app/apps/api/package.json ./package.json.tmp

# Remove workspace dependencies and create clean package.json
RUN cat package.json.tmp | sed 's/"@haven\/core": "workspace:\*",//g' | sed 's/"@haven\/config": "workspace:\*",//g' > package.json && rm package.json.tmp

# Install production dependencies with npm
RUN npm install --omit=dev --ignore-scripts

# Copy and install @haven/core as a local package
COPY --from=builder /app/packages/core/dist ./node_modules/@haven/core/dist
COPY --from=builder /app/packages/core/package.json ./node_modules/@haven/core/

# Copy Prisma schema and generate client in production
COPY --from=builder /app/apps/api/prisma ./prisma
RUN npx prisma generate

# Copy built application
COPY --from=builder --chown=nestjs:nodejs /app/apps/api/dist ./dist

USER nestjs

# Cloud Run requires listening on PORT env variable (default 8080)
ENV PORT=8080
ENV NODE_ENV=production

EXPOSE 8080

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start the server (run migrations separately via Cloud Shell)
CMD ["node", "dist/main"]
