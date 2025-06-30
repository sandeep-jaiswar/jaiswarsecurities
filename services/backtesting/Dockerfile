FROM node:18-alpine

WORKDIR /app

# Install dependencies
COPY package.json ./
# Generate package-lock.json if it doesn't exist
RUN if [ ! -f package-lock.json ]; then npm install --package-lock-only; fi
COPY package-lock.json* ./
RUN npm ci --only=production

# Copy application code
COPY . .

# Create logs directory
RUN mkdir -p logs

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001

# Change ownership of the app directory
RUN chown -R nodejs:nodejs /app
USER nodejs

EXPOSE 3003

CMD ["node", "index.js"]