FROM node:18-alpine

# Create app directory
WORKDIR /app

# Add system dependencies
RUN apk add --no-cache curl

# Add a non-root user
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001

# Copy package.json and package-lock.json from the root of the monorepo
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci

# Copy the api-gateway service
COPY services/api-gateway ./

# Switch user
USER nodejs

# Create logs directory
RUN mkdir -p logs

# Expose API port
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD wget --quiet --spider http://localhost:3000/health || exit 1

CMD ["node", "index.js"]
