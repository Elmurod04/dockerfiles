# ── Stage 1: Install dependencies ──────────────────────────
FROM node:20-alpine AS deps

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

# ── Stage 2: Run the app ────────────────────────────────────
FROM node:20-alpine AS runner

# Security: don't run as root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy only what's needed from deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Tell Node it's production
ENV NODE_ENV=production

EXPOSE 3000

# Health check — Docker will ping this every 30s
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

# Switch to non-root user
USER appuser

CMD ["node", "--require", "@opentelemetry/auto-instrumentations-node/register", "server.js"]