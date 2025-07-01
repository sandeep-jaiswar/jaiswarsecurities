FROM node:18-alpine

WORKDIR /app

# Add system tools
RUN apk add --no-cache curl

# Add non-root user
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001

# Install dependencies
COPY package.json package-lock.json ./
RUN npm ci --only=production

# Copy application code and set ownership
COPY --chown=nodejs:nodejs . .

# Create logs dir (if needed by app)
RUN mkdir -p logs

# Run as non-root
USER nodejs

# Expose service port
EXPOSE 3003

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD wget --quiet --spider http://localhost:3003/health || exit 1

CMD ["node", "index.js"]
