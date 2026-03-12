import { useQuery } from '@tanstack/react-query';
import { systemApi } from '@/services/api';
import { LayoutDashboard, Package, ClipboardList, Warehouse, TrendingUp, Activity, Shield, Search } from 'lucide-react';

export default function Dashboard() {
  const { data: health, isLoading: healthLoading } = useQuery({
    queryKey: ['health'],
    queryFn: () => systemApi.health(),
    refetchInterval: 30000,
  });

  const stats = [
    { 
      name: 'Tổng Sản Phẩm', 
      value: '12', 
      icon: Package, 
      color: 'primary',
      trend: '+2 này tuần',
      gradient: 'from-blue-500 to-blue-600'
    },
    { 
      name: 'Công Thức', 
      value: '8', 
      icon: ClipboardList, 
      color: 'secondary',
      trend: '1 chờ duyệt',
      gradient: 'from-teal-500 to-teal-600'
    },
    { 
      name: 'Lệnh Sản Xuất', 
      value: '5', 
      icon: Warehouse, 
      color: 'purple',
      gradient: 'from-purple-500 to-purple-600'
    },
    { 
      name: 'Đang Hoạt Động', 
      value: '3', 
      icon: Activity, 
      color: 'accent',
      trend: '90% hiệu quả',
      gradient: 'from-amber-500 to-amber-600'
    },
  ];

  // health is AxiosResponse<{status: string; ...}>, access via health.data.status
  const healthStatus = health?.data?.status || (healthLoading ? 'checking' : 'unknown');

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'healthy': return 'text-secondary-700 bg-secondary-50 border-secondary-200';
      case 'unhealthy': return 'text-red-700 bg-red-50 border-red-200';
      default: return 'text-neutral-600 bg-neutral-50 border-neutral-200';
    }
  };

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900">Dashboard</h1>
          <p className="text-neutral-500 mt-1">Tổng quan hệ thống GMP-WHO</p>
        </div>
        <div className={`inline-flex items-center px-4 py-2 rounded-xl border ${getStatusColor(healthStatus)}`}>
          <div className={`w-2 h-2 rounded-full mr-2 ${healthStatus === 'healthy' ? 'bg-secondary-500 animate-pulse' : 'bg-red-500 animate-pulse'}`} />
          <span className="font-medium text-sm">
            {healthLoading ? 'Đang kiểm tra...' : healthStatus === 'healthy' ? 'Hệ thống hoạt động bình thường' : 'Hệ thống có vấn đề'}
          </span>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat) => (
          <div key={stat.name} className="card group">
            <div className="flex items-start justify-between">
              <div className="flex-1">
                <p className="text-sm font-medium text-neutral-500 mb-1">{stat.name}</p>
                <p className="text-4xl font-bold text-neutral-900 mb-2">{stat.value}</p>
                {stat.trend && (
                  <div className="inline-flex items-center text-sm text-secondary-600 bg-secondary-50 px-2 py-1 rounded-lg">
                    <TrendingUp className="w-3 h-3 mr-1" />
                    {stat.trend}
                  </div>
                )}
              </div>
              <div className={`p-4 rounded-2xl bg-gradient-to-br ${stat.gradient} shadow-lg group-hover:shadow-xl transition-shadow`}>
                <stat.icon className="w-7 h-7 text-white" />
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Quick Actions */}
      <div className="card">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-lg font-bold text-neutral-900">Truy Cập Nhanh</h2>
          <span className="text-sm text-neutral-500">Thao tác thường dùng</span>
        </div>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {[
            { name: 'Tạo Lệnh Sản Xuất', icon: ClipboardList, href: '/production-orders', action: 'create' },
            { name: 'Quản Lý Nguyên Liệu', icon: Package, href: '/materials', action: 'manage' },
            { name: 'Công Thức', icon: ClipboardList, href: '/recipes', action: 'view' },
            { name: 'Truy Xuất Nguồn Gốc', icon: Search, href: '/traceability', action: 'track' },
          ].map((action) => (
            <a
              key={action.name}
              href={action.href}
              className="group flex flex-col items-center p-6 rounded-xl border-2 border-dashed border-neutral-300 hover:border-primary-400 hover:bg-primary-50 transition-all duration-300"
            >
              <div className="p-4 bg-neutral-100 rounded-xl group-hover:bg-primary-100 transition-colors mb-3">
                <action.icon className="w-8 h-8 text-primary-600 group-hover:scale-110 transition-transform" />
              </div>
              <span className="text-sm font-medium text-neutral-700 group-hover:text-primary-700 text-center">
                {action.name}
              </span>
            </a>
          ))}
        </div>
      </div>

      {/* GMP Compliance Status */}
      <div className="card">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-lg font-bold text-neutral-900">GMP Compliance Status</h2>
          <div className="inline-flex items-center px-3 py-1 bg-secondary-50 text-secondary-700 rounded-lg text-sm">
            <Shield className="w-4 h-4 mr-2" />
            Audit Trail Active
          </div>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {[
            {
              title: 'Audit Trail',
              desc: 'Đang hoạt động - Tự động ghi log mọi thay đổi',
              icon: Activity,
              color: 'bg-green-50 border-green-200 text-green-900',
              iconBg: 'bg-green-100 text-green-600',
              status: 'active'
            },
            {
              title: 'State Machine',
              desc: 'Draft → Approved → InProcess → Hold → Completed',
              icon: LayoutDashboard,
              color: 'bg-blue-50 border-blue-200 text-blue-900',
              iconBg: 'bg-blue-100 text-blue-600',
              status: 'active'
            },
            {
              title: 'BOM Management',
              desc: 'Hỗ trợ cấu trúc đệ quy nhiều cấp',
              icon: Package,
              color: 'bg-purple-50 border-purple-200 text-purple-900',
              iconBg: 'bg-purple-100 text-purple-600',
              status: 'active'
            },
            {
              title: 'Data Locking',
              desc: 'Recipe snapshot khi Approved, không cho phép sửa',
              icon: Shield,
              color: 'bg-orange-50 border-orange-200 text-orange-900',
              iconBg: 'bg-orange-100 text-orange-600',
              status: 'locked'
            },
          ].map((item, idx) => (
            <div key={idx} className={`p-4 rounded-xl border ${item.color}`}>
              <div className="flex items-start space-x-4">
                <div className={`p-3 rounded-xl ${item.iconBg}`}>
                  <item.icon className="w-6 h-6" />
                </div>
                <div className="flex-1">
                  <h3 className="font-semibold mb-1">{item.title}</h3>
                  <p className="text-sm opacity-90">{item.desc}</p>
                </div>
                <div className="w-2 h-2 rounded-full bg-current opacity-60 mt-2" />
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Recent Activity Section (placeholder for future enhancement) */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="card">
          <h2 className="text-lg font-bold text-neutral-900 mb-4">Hệ Thống</h2>
          <div className="space-y-4">
            <div className="flex items-center justify-between p-3 rounded-lg bg-neutral-50">
              <span className="text-sm text-neutral-700">API Endpoint</span>
              <code className="text-xs bg-neutral-200 px-2 py-1 rounded">:5001</code>
            </div>
            <div className="flex items-center justify-between p-3 rounded-lg bg-neutral-50">
              <span className="text-sm text-neutral-700">Frontend</span>
              <code className="text-xs bg-neutral-200 px-2 py-1 rounded">:8080</code>
            </div>
            <div className="flex items-center justify-between p-3 rounded-lg bg-neutral-50">
              <span className="text-sm text-neutral-700">Database</span>
              <code className="text-xs bg-neutral-200 px-2 py-1 rounded">SQL Server 2022</code>
            </div>
            <div className="flex items-center justify-between p-3 rounded-lg bg-neutral-50">
              <span className="text-sm text-neutral-700">Environment</span>
              <span className="text-xs bg-secondary-100 text-secondary-700 px-2 py-1 rounded">Production</span>
            </div>
          </div>
        </div>

        <div className="card">
          <h2 className="text-lg font-bold text-neutral-900 mb-4">Thông Tin Hệ Thống</h2>
          <div className="space-y-4">
            <div className="p-4 bg-gradient-to-r from-primary-50 to-secondary-50 rounded-xl border border-primary-100">
              <p className="text-sm font-medium text-primary-900 mb-2">Phiên bản</p>
              <p className="text-2xl font-bold text-primary-700">1.0.0</p>
              <p className="text-xs text-primary-600 mt-1">GMP-WHO Standard</p>
            </div>
            <div className="p-4 bg-neutral-50 rounded-xl border border-neutral-200">
              <p className="text-sm font-medium text-neutral-900 mb-2">Ngày cập nhật</p>
              <p className="text-lg font-bold text-neutral-700">2025-03-11</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
