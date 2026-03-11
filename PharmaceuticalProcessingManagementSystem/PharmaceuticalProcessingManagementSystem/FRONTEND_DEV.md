# GMP-WHO Frontend Quick Start

## 📦 Dependencies

- Node.js 18+
- npm 9+

## 🚀 Local Development

```bash
# Navigate to frontend directory
cd PharmaceuticalProcessingManagementSystem/PharmaceuticalProcessingManagementSystem

# Install dependencies
npm install

# Start development server
npm run dev
```

Mở trình duyệt: http://localhost:5173

## 🏗️ Production Build

```bash
# Build for production
npm run build

# Output sẽ nằm trong thư mục `dist/`
```

## 🐳 Docker Build

```bash
# Build Docker image
docker build -t gmp-who-frontend .

# Run container
docker run -d -p 8080:80 --name gmp-frontend gmp-who-frontend
```

## 🔧 Configuration

- API URL được cấu hình qua environment variable `VITE_API_URL`
- Trong development (npm run dev): mặc định là `http://localhost:5001` qua proxy trong vite.config.ts
- Trong Docker build: truyền qua build-arg `--build-arg VITE_API_URL=http://gmp-api:5000`

## 📁 Project Structure

```
src/
├── components/       # Reusable UI components
│   ├── Layout.tsx   # Main layout with sidebar
│   └── StatusBadge.tsx
├── pages/           # Route pages
│   ├── Dashboard.tsx
│   ├── Materials.tsx
│   ├── Recipes.tsx
│   ├── ProductionOrders.tsx
│   ├── ProductionBatches.tsx
│   └── Traceability.tsx
├── services/        # API clients
│   └── api.ts
├── types/           # TypeScript interfaces
│   └── index.ts
└── lib/             # Utilities
    └── utils.ts
```

## 🧪 Tech Stack

- React 18 + TypeScript
- Vite (build tool)
- React Router v6 (routing)
- TanStack Query (data fetching)
- Tailwind CSS (styling)
- Lucide React (icons)
- Sonner (toast notifications)
- Axios (HTTP client)

---

**Note:** Đây là giai đoạn đầu, một số trang vẫn là placeholder. Các tính năng đầy đủ sẽ được phát triển theo yêu cầu GMP-WHO.
