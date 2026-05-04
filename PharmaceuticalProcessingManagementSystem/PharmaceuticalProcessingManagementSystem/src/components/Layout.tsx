import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard,
  Pill,
  ClipboardList,
  Warehouse,
  Search,
  Menu,
  X,
  Users,
  Package,
  LogOut,
  Settings,
  FileText,
  BarChart3,
  Factory,
} from 'lucide-react';
import { useState } from 'react';
import { useAuth } from '@/context/AuthContext';

const navigation = [
  { name: 'Bảng Điều Khiển', href: '/dashboard', icon: LayoutDashboard, roles: ['Admin', 'Manager', 'QualityControl', 'Operator'] },
  { name: 'Nguyên Liệu', href: '/materials', icon: Pill, roles: ['Admin', 'Manager', 'QualityControl'] },
  { name: 'Công Thức', href: '/recipes', icon: ClipboardList, roles: ['Admin', 'Manager'] },
  { name: 'Lệnh Sản Xuất', href: '/production-orders', icon: Warehouse, roles: ['Admin', 'Manager'] },
  { name: 'Thành Phẩm', href: '/finished-products', icon: Package, roles: ['Admin', 'Manager', 'QualityControl'] },
  { name: 'Truy Xuất', href: '/traceability', icon: Search, roles: ['Admin', 'Manager', 'QualityControl'] },
  { name: 'Thiết Bị', href: '/equipments', icon: Settings, roles: ['Admin', 'Manager'] },
  { name: 'Theo Dõi Tiến Độ', href: '/manager-operations', icon: FileText, roles: ['Admin', 'Manager'] },
  { name: 'Phòng Sản Xuất', href: '/production-areas', icon: Factory, roles: ['Admin', 'Manager'] },
  { name: 'Thống Kê Thành Phẩm', href: '/finished-goods-stats', icon: BarChart3, roles: ['Admin', 'Manager'] },
  { name: 'Tài Khoản', href: '/users', icon: Users, roles: ['Admin'] },
];

const roleLabels: Record<string, string> = {
  Admin: 'Quản trị viên',
  QualityControl: 'Kiểm soát chất lượng',
  Manager: 'Trưởng phòng',
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
      {sidebarOpen && (
        <div
          className="fixed inset-0 bg-neutral-800 bg-opacity-50 z-40 lg:hidden transition-opacity"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      <aside
        className={`print:hidden fixed inset-y-0 left-0 z-50 w-[258px] bg-surface border-r border-neutral-200 transform transition-transform duration-300 ease-in-out lg:translate-x-0 flex flex-col ${
          sidebarOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
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

        <div className="flex-1 overflow-y-auto py-6">
          <nav className="px-3 space-y-1">
            {navigation.filter((item) => !user?.role || item.roles.includes(user.role)).map((item) => (
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

      <div className="flex-1 lg:ml-[258px] print:m-0 print:w-full">
        <header className="print:hidden bg-surface border-b border-neutral-200 h-16 flex items-center px-6 sticky top-0 z-30">
          <button
            className="lg:hidden p-2 rounded-lg hover:bg-neutral-100 mr-4"
            onClick={() => setSidebarOpen(true)}
          >
            <Menu className="w-6 h-6 text-neutral-700" />
          </button>

          <div className="flex-1">
            <h2 className="text-lg font-semibold text-neutral-900">Theo dõi tiến độ</h2>
          </div>


        </header>

        <main className="p-6 lg:p-8">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
