import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard,
  Pill,
  ClipboardList,
  Warehouse,
  Search,
  Activity,
  Menu,
  X,
  Bell,
  Users,
  Package,
  LogOut,
  Settings
} from 'lucide-react';
import { useState } from 'react';
import { useAuth } from '@/context/AuthContext';

const navigation = [
  { name: 'Bảng Điều Khiển', href: '/dashboard', icon: LayoutDashboard },
  { name: 'Nguyên Liệu', href: '/materials', icon: Pill },
  { name: 'Công Thức', href: '/recipes', icon: ClipboardList },
  { name: 'Lệnh Sản Xuất', href: '/production-orders', icon: Warehouse },
  { name: 'Mẻ Sản Xuất', href: '/batches', icon: Activity },
  { name: 'Truy Xuất', href: '/traceability', icon: Search },
  { name: 'Tồn Kho', href: '/inventory', icon: Package },
  { name: 'Thiết Bị', href: '/equipments', icon: Settings },
  { name: 'Tài Khoản', href: '/users', icon: Users },
  { name: 'Nhật Ký Hệ Thống', href: '/audit-logs', icon: ClipboardList },
];

const roleLabels: Record<string, string> = {
  Admin: 'Quản trị viên',
  QualityControl: 'Kiểm soát chất lượng',
  Manager: 'Quản lý',
  Operator: 'Nhân viên vận hành',
};

export default function Layout() {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login', { replace: true });
  };

  return (
    <div className="min-h-screen bg-neutral-50 flex">
      {/* Mobile sidebar backdrop */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 bg-neutral-800 bg-opacity-50 z-40 lg:hidden transition-opacity"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside
        className={`fixed inset-y-0 left-0 z-50 w-72 bg-surface border-r border-neutral-200 transform transition-transform duration-300 ease-in-out lg:translate-x-0 flex flex-col ${
          sidebarOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        {/* Logo */}
        <div className="flex items-center justify-between h-16 px-6 border-b border-neutral-200">
          <div className="flex items-center space-x-3">
            <div className="w-8 h-8 bg-gradient-to-br from-primary-500 to-primary-700 rounded-lg flex items-center justify-center">
              <span className="text-white font-bold text-sm">GMP</span>
            </div>
            <div>
              <h1 className="text-lg font-bold text-primary-700">GMP-WHO</h1>
              <p className="text-xs text-neutral-500 -mt-1">Dược phẩm</p>
            </div>
          </div>
          <button
            className="lg:hidden p-1 rounded-lg hover:bg-neutral-100"
            onClick={() => setSidebarOpen(false)}
          >
            <X className="w-5 h-5 text-neutral-600" />
          </button>
        </div>

        {/* Navigation */}
        <div className="flex-1 overflow-y-auto py-6">
          <nav className="px-3 space-y-1">
            {navigation.map((item) => (
              <NavLink
                key={item.name}
              to={item.href}
              onClick={() => setSidebarOpen(false)}
              className={({ isActive }) =>
                `nav-item group ${isActive ? 'nav-item-active' : ''}`
              }
            >
              <item.icon className="w-5 h-5 mr-3" />
              {item.name}
            </NavLink>
          ))}
          </nav>
        </div>

        {/* User section */}
        <div className="p-4 border-t border-neutral-200 bg-surface">
          <div className="flex items-center space-x-3 mb-3">
            <div className="w-10 h-10 bg-gradient-to-br from-primary-400 to-primary-600 rounded-full flex items-center justify-center shrink-0">
              <span className="text-white font-bold text-sm">
                {user?.username?.charAt(0).toUpperCase() ?? 'U'}
              </span>
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-neutral-900 truncate">{user?.fullName ?? user?.username}</p>
              <p className="text-xs text-neutral-500 truncate">{roleLabels[user?.role ?? ''] ?? user?.role}</p>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-2">
            <button className="flex items-center justify-center px-3 py-2 text-sm text-neutral-600 bg-neutral-100 rounded-lg hover:bg-neutral-200 transition-colors">
              <Settings className="w-4 h-4 mr-2" />
              Cài đặt
            </button>
            <button
              onClick={handleLogout}
              className="flex items-center justify-center px-3 py-2 text-sm text-red-600 bg-red-50 rounded-lg hover:bg-red-100 transition-colors"
            >
              <LogOut className="w-4 h-4 mr-2" />
              Đăng xuất
            </button>
          </div>
        </div>
      </aside>

      {/* Main content */}
      <div className="flex-1 lg:ml-72">
        {/* Top header */}
        <header className="bg-surface border-b border-neutral-200 h-16 flex items-center px-6 sticky top-0 z-30">
          <button
            className="lg:hidden p-2 rounded-lg hover:bg-neutral-100 mr-4"
            onClick={() => setSidebarOpen(true)}
          >
            <Menu className="w-6 h-6 text-neutral-700" />
          </button>

          {/* Breadcrumb / Page title */}
          <div className="flex-1">
            <h2 className="text-lg font-semibold text-neutral-900">
              Quản Lý Sản Xuất Dược Phẩm
            </h2>
          </div>

          {/* Header actions */}
          <div className="flex items-center space-x-4">
            {/* Notifications */}
            <button className="relative p-2 rounded-lg hover:bg-neutral-100 transition-colors">
              <Bell className="w-5 h-5 text-neutral-600" />
              <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full"></span>
            </button>

            {/* Quick status indicator */}
            <div className="hidden sm:flex items-center space-x-2 px-3 py-1.5 bg-secondary-50 border border-secondary-200 rounded-lg">
              <div className="w-2 h-2 bg-secondary-500 rounded-full animate-pulse" />
              <span className="text-sm font-medium text-secondary-700">Hoạt động tốt</span>
            </div>
          </div>
        </header>

        {/* Page content */}
        <main className="p-6 lg:p-8">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
