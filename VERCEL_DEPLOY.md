# Deploy Web Admin lên Vercel

## Phạm vi

Vercel chỉ host frontend React/Vite trong thư mục:

```text
PharmaceuticalProcessingManagementSystem/PharmaceuticalProcessingManagementSystem
```

Backend `.NET API` và SQL Server vẫn chạy bằng Docker trên máy của bạn. Frontend Vercel cần gọi API qua một URL public, ví dụ Cloudflare Tunnel/Quick Tunnel.

## 1. Public API backend trước

Chạy backend bằng Docker như bình thường:

```powershell
docker compose up -d --build
```

Nếu chưa có domain cố định, dùng Quick Tunnel tạm:

```powershell
cloudflared tunnel --url http://localhost:5001
```

Cloudflare sẽ trả URL dạng:

```text
https://random-name.trycloudflare.com
```

Giá trị `VITE_API_URL` sẽ là:

```text
https://random-name.trycloudflare.com/api
```

## 2. Import project vào Vercel

1. Vào `https://vercel.com/new`.
2. Chọn repo GitHub của bạn.
3. Ở phần `Root Directory`, chọn:

```text
PharmaceuticalProcessingManagementSystem/PharmaceuticalProcessingManagementSystem
```

4. Framework Preset: `Vite`.
5. Build Command: `npm run build`.
6. Output Directory: `dist`.

## 3. Thêm Environment Variable

Trong Vercel project:

`Settings` → `Environment Variables`

Thêm:

```text
VITE_API_URL=https://random-name.trycloudflare.com/api
```

Chọn cả `Production`, `Preview`, `Development` nếu bạn muốn dùng chung.

## 4. Deploy

Bấm `Deploy`.

Sau khi deploy xong, Vercel sẽ cấp link dạng:

```text
https://ten-project.vercel.app
```

## 5. Khi Quick Tunnel đổi link

Quick Tunnel tạo link random. Nếu bạn tắt/mở lại tunnel:

1. Copy link mới.
2. Vào Vercel → `Settings` → `Environment Variables`.
3. Sửa `VITE_API_URL`.
4. Vào `Deployments` → redeploy bản mới nhất.

## 6. Lưu ý

- Không đưa SQL Server lên public Internet.
- Backend hiện đã cho phép origin chứa `vercel.app` trong CORS.
- File `vercel.json` đã có rewrite về `index.html` để các route React như `/dashboard`, `/materials` không bị 404 khi refresh.
