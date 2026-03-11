import { useQuery } from '@tanstack/react-query';
import { systemApi } from '@/services/api';
import { LayoutDashboard, Package, ClipboardList, Warehouse, AlertCircle } from 'lucide-react';

export default function Dashboard() {
  const { data: health, isLoading: healthLoading } = useQuery({
    queryKey: ['health'],
    queryFn: () => systemApi.health(),
  });

  const stats = [
    { name: 'Tổng Sản Phẩm', value: '12', icon: Package, color: 'bg-blue-500' },
    { name: 'Công Thức', value: '8', icon: ClipboardList, color: 'bg-green-500' },
    { name: 'Lệnh Sản Xuất', value: '5', icon: Warehouse, color: 'bg-purple-500' },
    { name: 'Đang Hoạt Động', value: '3', icon: LayoutDashboard, color: 'bg-orange-500' },
  ];

  const healthStatus = (health as any)?.data?.status || (healthLoading ? 'checking' : 'unknown');

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
        <div className="flex items-center space-x-2">
          <div className={`w-3 h-3 rounded-full ${healthStatus === 'healthy' ? 'bg-green-500' : 'bg-red-500'}`} />
          <span className="text-sm text-gray-600">
            {healthLoading ? 'Checking...' : healthStatus === 'healthy' ? 'Hệ thống hoạt động bình thường' : 'Hệ thống có vấn đề'}
          </span>
        </div>
      </div>

      {/* Stats cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat) => (
          <div key={stat.name} className="bg-white rounded-xl shadow-sm p-6 border border-gray-200">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">{stat.name}</p>
                <p className="text-3xl font-bold text-gray-900 mt-2">{stat.value}</p>
              </div>
              <div className={`${stat.color} p-3 rounded-lg`}>
                <stat.icon className="w-6 h-6 text-white" />
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Quick actions */}
      <div className="bg-white rounded-xl shadow-sm p-6 border border-gray-200">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Truy Cập Nhanh</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <a
            href="/production-orders"
            className="flex flex-col items-center p-4 border-2 border-dashed border-gray-300 rounded-lg hover:border-gmp-primary hover:bg-gmp-background transition-colors"
          >
            <ClipboardList className="w-8 h-8 text-gmp-primary mb-2" />
            <span className="text-sm font-medium text-gray-700">Tạo Lệnh Sản Xuất</span>
          </a>
          <a
            href="/materials"
            className="flex flex-col items-center p-4 border-2 border-dashed border-gray-300 rounded-lg hover:border-gmp-primary hover:bg-gmp-background transition-colors"
          >
            <Package className="w-8 h-8 text-gmp-primary mb-2" />
            <span className="text-sm font-medium text-gray-700">Quản Lý Nguyên Liệu</span>
          </a>
          <a
            href="/recipes"
            className="flex flex-col items-center p-4 border-2 border-dashed border-gray-300 rounded-lg hover:border-gmp-primary hover:bg-gmp-background transition-colors"
          >
            <ClipboardList className="w-8 h-8 text-gmp-primary mb-2" />
            <span className="text-sm font-medium text-gray-700">Công Thức</span>
          </a>
          <a
            href="/traceability"
            className="flex flex-col items-center p-4 border-2 border-dashed border-gray-300 rounded-lg hover:border-gmp-primary hover:bg-gmp-background transition-colors"
          >
            <AlertCircle className="w-8 h-8 text-gmp-primary mb-2" />
            <span className="text-sm font-medium text-gray-700">Truy Xuất Nguồn Gốc</span>
          </a>
        </div>
      </div>

      {/* GMP Compliance Status */}
      <div className="bg-white rounded-xl shadow-sm p-6 border border-gray-200">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">GMP Compliance Status</h2>
        <div className="space-y-4">
          <div className="flex items-center justify-between p-4 bg-green-50 border border-green-200 rounded-lg">
            <div>
              <p className="font-medium text-green-900">Audit Trail</p>
              <p className="text-sm text-green-700">Đang hoạt động - Tự động ghi log mọi thay đổi</p>
            </div>
            <div className="w-3 h-3 bg-green-500 rounded-full animate-pulse" />
          </div>
          <div className="flex items-center justify-between p-4 bg-blue-50 border border-blue-200 rounded-lg">
            <div>
              <p className="font-medium text-blue-900">State Machine</p>
              <p className="text-sm text-blue-700">Draft → Approved → InProcess → Hold → Completed</p>
            </div>
            <div className="w-3 h-3 bg-blue-500 rounded-full" />
          </div>
          <div className="flex items-center justify-between p-4 bg-purple-50 border border-purple-200 rounded-lg">
            <div>
              <p className="font-medium text-purple-900">BOM Management</p>
              <p className="text-sm text-purple-700">Hỗ trợ cấu trúc đệ quy nhiều cấp</p>
            </div>
            <div className="w-3 h-3 bg-purple-500 rounded-full" />
          </div>
          <div className="flex items-center justify-between p-4 bg-orange-50 border border-orange-200 rounded-lg">
            <div>
              <p className="font-medium text-orange-900">Data Locking</p>
              <p className="text-sm text-orange-700">Recipe snapshot khi Approved, không cho phép sửa</p>
            </div>
            <div className="w-3 h-3 bg-orange-500 rounded-full" />
          </div>
        </div>
      </div>
    </div>
  );
}
