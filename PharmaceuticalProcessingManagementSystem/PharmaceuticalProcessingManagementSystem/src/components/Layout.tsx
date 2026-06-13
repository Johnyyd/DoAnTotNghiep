import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard,
  Pill,
  ClipboardList,
  Warehouse,
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

const roleLabels: Record<string, string> = {
  Admin: 'Quản trị viên',
  QualityControl: 'Kiểm soát chất lượng',
  ProductionManager: 'Quản lý',
  Operator: 'Nhân viên vận hành',
  WarehouseStaff: 'Nhân viên kho',
};

const navigation = [
  { name: 'Bảng Điều Khiển', href: '/dashboard', icon: LayoutDashboard, roles: ['Admin', 'ProductionManager', 'Operator'] },
  { name: 'Nguyên Liệu', href: '/materials', icon: Pill, roles: ['Admin', 'ProductionManager', 'QualityControl', 'QA_QC', 'WarehouseStaff'] },
  { name: 'Thành Phẩm', href: '/finished-products', icon: Package, roles: ['Admin', 'ProductionManager'] },
  { name: 'Công Thức', href: '/recipes', icon: ClipboardList, roles: ['Admin', 'ProductionManager'] },
  { name: 'Lệnh Sản Xuất', href: '/production-orders', icon: Warehouse, roles: ['Admin', 'ProductionManager', 'QualityControl', 'QA_QC'] },
  { name: 'Mẻ Sản Xuất', href: '/batches', icon: Package, roles: ['Admin', 'ProductionManager', 'Operator'] },
  { name: 'Theo Dõi Tiến Độ', href: '/manager-operations', icon: FileText, roles: ['Admin', 'ProductionManager'] },
  { name: 'Thống Kê', href: '/finished-goods-stats', icon: BarChart3, roles: ['Admin', 'ProductionManager'] },
  { name: 'Thiết Bị', href: '/equipments', icon: Settings, roles: ['Admin', 'ProductionManager'] },
  { name: 'Khu Sản Xuất', href: '/production-areas', icon: Factory, roles: ['Admin', 'ProductionManager'] },
  { name: 'Kho', href: '/storage-locations', icon: Warehouse, roles: ['Admin', 'ProductionManager'] },
  { name: 'Tài Khoản', href: '/users', icon: Users, roles: ['Admin'] },
];

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
        className={`print:hidden fixed inset-y-0 left-0 z-50 w-[236px] bg-surface border-r border-neutral-200 transform transition-transform duration-300 ease-in-out lg:translate-x-0 flex flex-col ${sidebarOpen ? 'translate-x-0' : '-translate-x-full'
          }`}
      >
        <div className="flex items-center justify-between h-16 px-6 border-b border-neutral-200">
          <div className="flex items-center space-x-3">
            <img src="/icon.png" alt="Logo" className="w-10 h-10 object-contain" />
            <div>
              <h1 className="text-lg font-bold text-primary-700">HUIT</h1>
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

      </aside>

      <div className="flex-1 lg:ml-[236px] print:m-0 print:w-full">
        <header className="print:hidden bg-surface border-b border-neutral-200 h-16 flex items-center px-6 sticky top-0 z-30">
          <button
            className="lg:hidden p-2 rounded-lg hover:bg-neutral-100 mr-4"
            onClick={() => setSidebarOpen(true)}
          >
            <Menu className="w-6 h-6 text-neutral-700" />
          </button>

          <div className="flex-1">
            <h2 className="text-lg font-semibold text-neutral-900">Công ty dược phẩm HUIT-Pharma</h2>
          </div>

          <div className="ml-4 flex items-center gap-3 rounded-xl border border-neutral-200 bg-surface px-3 py-2 shadow-sm">
            <div className="w-9 h-9 bg-gradient-to-br from-primary-400 to-primary-600 rounded-full flex items-center justify-center shrink-0">
              <span className="text-white font-bold text-sm">
                {user?.username?.charAt(0).toUpperCase() ?? 'U'}
              </span>
            </div>
            <div className="hidden sm:block min-w-0">
              <p className="text-sm font-medium text-neutral-900 truncate max-w-[180px]">{user?.fullName ?? user?.username}</p>
              <p className="text-xs text-neutral-500 truncate max-w-[180px]">{roleLabels[user?.role ?? ''] ?? user?.role}</p>
            </div>
            <button
              onClick={handleLogout}
              className="flex items-center justify-center px-3 py-2 text-sm text-red-600 bg-red-50 rounded-lg hover:bg-red-100 transition-colors"
            >
              <LogOut className="w-4 h-4 sm:mr-2" />
              <span className="hidden sm:inline">Đăng xuất</span>
            </button>
          </div>
        </header>

        <main className="p-6 lg:p-8">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
