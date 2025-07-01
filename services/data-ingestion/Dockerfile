FROM node:18-alpine

WORKDIR /app

RUN apk add --no-cache curl

# Add non-root user
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001

# Install dependencies
COPY package.json package-lock.json ./
RUN npm ci --only=production

# Copy source code and assign ownership
COPY --chown=nodejs:nodejs . .

# Create logs directory
RUN mkdir -p logs

# Switch to non-root user
USER nodejs

# Expose service port
EXPOSE 3002

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD wget --quiet --spider http://localhost:3002/health || exit 1

CMD ["node", "index.js"]
