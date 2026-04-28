# ==============================================================================================
# GMP-WHO Mobile Application (Flutter Web)
# ==============================================================================================

# STAGE 1: Build Flutter Web
# Sử dụng Image Flutter chính thức để đóng gói mã nguồn
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

# Tối ưu hóa Cache cho Flutter Pub Get
COPY pubspec.* .
RUN flutter pub get

# Copy toàn bộ mã nguồn và thực hiện build
COPY . .
RUN flutter build web --release

# ----------------------------------------------------------------------------------------------
# STAGE 2: Production (Phân phối qua Nginx)
# ----------------------------------------------------------------------------------------------
FROM nginx:alpine AS production
WORKDIR /usr/share/nginx/html

# Chuyển thành phẩm từ Stage Build sang
COPY --from=build /app/build/web .

# Cấu hình Nginx để hỗ trợ Single Page Application (SPA)
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]