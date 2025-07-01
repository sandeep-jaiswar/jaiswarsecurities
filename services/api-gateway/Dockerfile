FROM node:18-alpine

# Create app directory
WORKDIR /app

# Add system dependencies
RUN apk add --no-cache curl

# Add a non-root user
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001

# Install dependencies
COPY package.json package-lock.json ./
RUN npm ci --only=production

# Copy app code and give ownership
COPY --chown=nodejs:nodejs . .

# Switch user
USER nodejs

# Create logs directory
RUN mkdir -p logs

# Expose API port
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD wget --quiet --spider http://localhost:3000/health || exit 1

CMD ["node", "index.js"]
