# GMP-WHO Mobile Application (Flutter Web)
# Multi-stage build for production

# Stage 1: Build
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Run flutter doctor to ensure environment is ready
RUN flutter doctor -v

# Copy project files
COPY . .

# Get dependencies
RUN flutter pub get

# Build Flutter Web
RUN flutter build web --release

# Stage 2: Production
FROM nginx:alpine AS production
WORKDIR /usr/share/nginx/html

# Copy built files
COPY --from=build /app/build/web .

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
