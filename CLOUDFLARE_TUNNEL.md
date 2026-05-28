# Cloudflare Tunnel cho đồ án GMP-WHO

## Mục tiêu

Expose các service đang chạy bằng Docker mà không mở port router:

- Web Admin: `gmp-frontend:80`
- Mobile Flutter Web: `gmp-mobile:80`
- API: đi qua `/api` nhờ nginx/proxy có sẵn trong Web Admin và Mobile
- SQL Server: không public ra Internet

## Cách chạy bằng tunnel chính thức

### 1. Tạo tunnel trên Cloudflare

1. Đăng nhập Cloudflare Zero Trust.
2. Vào `Networks` → `Tunnels`.
3. Chọn `Create a tunnel`.
4. Chọn connector `cloudflared`.
5. Chọn môi trường `Docker`.
6. Copy token sau `--token`.

### 2. Thêm token vào `.env`

Trong file `.env` ở thư mục gốc project:

```env
CLOUDFLARE_TUNNEL_TOKEN=token_cloudflare_cua_ban
```

Không commit token thật lên GitHub.

### 3. Tạo Public Hostnames

Trong cấu hình tunnel trên Cloudflare, thêm các hostname:

| Hostname | Service |
|---|---|
| `web.<domain-cua-ban>` | `http://gmp-frontend:80` |
| `mobile.<domain-cua-ban>` | `http://gmp-mobile:80` |

Không cần public riêng SQL Server.

Nếu muốn gọi API trực tiếp từ bên ngoài, thêm:

| Hostname | Service |
|---|---|
| `api.<domain-cua-ban>` | `http://gmp-api:5000` |

### 4. Chạy Docker với tunnel

```powershell
docker compose --profile tunnel up -d --build
```

Xem log tunnel:

```powershell
docker logs -f gmp-cloudflared
```

Tắt riêng tunnel:

```powershell
docker compose --profile tunnel stop cloudflared
```

## Cách không cần domain: Quick Tunnel

Dùng để demo tạm, link sẽ thay đổi mỗi lần chạy và không có cam kết uptime.

Web Admin:

```powershell
cloudflared tunnel --url http://localhost:8080
```

Mobile:

```powershell
cloudflared tunnel --url http://localhost:8081
```

## Domain miễn phí

### Phương án thực tế nhất nếu không tốn tiền

- Dùng Quick Tunnel `*.trycloudflare.com`.
- Không cần mua domain.
- Nhược điểm: link random, không ổn định dài hạn.

### GitHub Pages

- GitHub Pages cho domain miễn phí dạng `https://<username>.github.io`.
- Chỉ phù hợp host static site.
- Không chạy được Docker, SQL Server, backend .NET trực tiếp.
- Nếu dùng GitHub Pages cho frontend, backend/API vẫn phải chạy ở nơi khác hoặc qua tunnel.

### Domain/subdomain miễn phí khác

Một số dịch vụ subdomain miễn phí có thể hoạt động nếu cho bạn cấu hình DNS/CNAME hoặc nameserver, nhưng không ổn định bằng domain riêng. Với Cloudflare Tunnel chính thức, cách dễ nhất vẫn là có một domain nằm trong Cloudflare.

## Ghi chú vận hành

- Máy chạy Docker phải bật và có Internet thì link mới truy cập được.
- Không expose port `1435`/SQL Server ra Internet.
- Nếu dùng tunnel chính thức, truy cập Web Admin qua `https://web.<domain>` và Mobile qua `https://mobile.<domain>`.
