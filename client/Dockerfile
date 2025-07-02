# ---- Base ----
FROM node:18-alpine AS base
WORKDIR /usr/src/app

# Set production environment
ENV NODE_ENV=production

# Install dependencies
COPY client/package.json client/package-lock.json ./client/
RUN cd client && npm ci

# Copy the rest of the application
COPY client/ ./client/

# Build the Next.js app
RUN cd client && npm run build

EXPOSE 3001
ENV PORT 3001

# Start the server
CMD ["npm", "start", "--workspace=client"]
