# ==============================================================================================
# GMP-WHO Mobile Application (Nginx Only)
# Hướng dẫn: Bạn cần chạy 'flutter build web --release' trên máy thật trước khi build Docker.
# ==============================================================================================

FROM nginx:alpine AS production
WORKDIR /usr/share/nginx/html

# Copy thành phẩm đã build sẵn từ máy thật vào
# Đảm bảo bạn đã chạy lệnh build trước đó
COPY build/web .

# Cấu hình Nginx để hỗ trợ Single Page Application (SPA)
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
