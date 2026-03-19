# GMP-WHO Frontend Admin (React + TypeScript)
# Sử dụng công nghệ Multi-stage build để tối ưu cho Production
# Stage 1: Build mã nguồn React ra các file tĩnh chuẩn (HTML, CSS, JS) bằng Node.js
# Stage 2: Nhúng mã tĩnh để phân phối qua Web Server Nginx (Giảm triệt để dung lượng)
# Stage 1: Build
FROM node:20-alpine AS build
WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm install

# Copy source code
COPY . .

# Build arguments
ARG VITE_API_URL=/api
ENV VITE_API_URL=${VITE_API_URL}

# Build the app
RUN npm run build

# Stage 2: Production
FROM nginx:alpine AS production
WORKDIR /usr/share/nginx/html

# Copy built files
COPY --from=build /app/dist .

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
