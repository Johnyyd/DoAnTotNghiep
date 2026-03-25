# GMP-WHO Mobile Application (Flutter Web)
# Bỏ qua Stage build Flutter vì thiếu RAM WSL, build trước bằng lệnh local trên Windows

FROM nginx:alpine AS production
WORKDIR /usr/share/nginx/html

# Copy pre-built files (Yêu cầu build locally flutter build web trước)
COPY build/web .

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
