# ==============================================================================================
# GMP-WHO Backend API (.NET 8)
# Kịch bản đóng gói Docker (Dockerfile) sử dụng phương pháp "Multi-stage build" (Xây dựng đa mốc).
# Đích đến: Giết chết môi trường Cồng kềnh lúc Build, bế xuất ra môi trường Siêu nhẹ lúc Chạy.
# ==============================================================================================

# ----------------------------------------------------------------------------------------------
# STAGE 1 (Mốc Build & Publish): Công xưởng chứa máy móc biên dịch (SDK)
# ----------------------------------------------------------------------------------------------
# Sóng gọi Image hệ điều hành tích hợp công cụ lập trình .NET 8 SDK từ Registry Microsoft (mcr)
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# BƯỚC 1.1: Tranh thủ nạp Thư viện C# ngầm trước (Restore)
# Chiến thuật: Nhặt mỗi file .csproj thả vào trước để đoạt trọn cơ chế Cache Layer của nền Docker.
# Lợi ích: Nếu bạn sửa file CS logic mà không tải thêm thư viện mới -> Docker tua thẳng qua dòng này khỏi tải lại -> Tốc độ Build tính bằng mili giây.
COPY ["GMP_System.csproj", "./"]
RUN dotnet restore "GMP_System.csproj"

# BƯỚC 1.2: Biên dịch Mã nguồn (Build)
# Copy toàn bộ đống chăn màn, mã nguồn C# còn lại chui tọt vào kho ảo '/src'
COPY . .
# Kích đạn Compiler C# (-c Release) loại bỏ file gỡ gỡ lỗi PDB nặng nề. Gom rác Build nhét vào `/app/build`
RUN dotnet build "GMP_System.csproj" -c Release -o /app/build

# BƯỚC 1.3: Đóng cục phần mềm (Publish)
# Vo viên đống nhị phân lại, siết bóp thành thành phẩm độc lập 1 Thư mục. Tham số UseAppHost=false giúp từ chối sinh file .EXE dư thừa trên Linux
RUN dotnet publish "GMP_System.csproj" -c Release -o /app/publish /p:UseAppHost=false

# ----------------------------------------------------------------------------------------------
# STAGE 2 (Mốc Runtime): Trạm gác siêu mỏng cuối cùng
# ----------------------------------------------------------------------------------------------
# Tuyệt kỹ rũ bỏ bộ rễ: Xin một cái xác hệ điều hành mới tinh (ASP.NET 8 Runtime), sạch bong mã nguồn, không có tool Build (SDK)
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app # Lấy thư mục trung tâm '/app' làm nhà

# Bổ túc mảng OS Linux: Bơm lệnh `curl` vào huyết quản để hệ thống ngoài (docker-compose) có thể gọi chọc khoáy ping đường ruột.
RUN apt-get update \
    && apt-get install -y curl \
    && rm -rf /var/lib/apt/lists/* # Giết sạch rác lệnh tải OS để ảnh không phình kích cỡ

# Áp chế thông số Máy chủ Web Kestrel (Lõi ASP.NET) ép nó chổng tai nghe đón Request trên Post 5000 bằng mọi IP v4 (0.0.0.0)
ENV ASPNETCORE_URLS=http://0.0.0.0:5000

# MÀN ẢO THUẬT COPY (Truyền tống dữ kiện liên chiều) --from=build
# Chỉ lục lại cái tàn tích của Mốc 1 (Stage 1 build), quơ đúng thư mục `publish` vác sang nhà mới trắng trơn. Thùng rác mã nguồn cũ chìm vào lãng quên.
COPY --from=build /app/publish .

# Báo hiệu Khẩu Độ Ống Khói (Expose): Tờ giấy khai sinh rêu rao Container này làm việc ở ngưỡng Port 5000
EXPOSE 5000

# Nút Kích Hoạt (ENTRYPOINT): Chốt hạ lệnh còi sẽ thổi khi vừa khởi động xong hệ thống ảo -> Server bật nguồn ngay tắp lự.
ENTRYPOINT ["dotnet", "GMP_System.dll"]
