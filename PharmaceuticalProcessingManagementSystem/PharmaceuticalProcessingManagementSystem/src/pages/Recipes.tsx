import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { recipesApi } from '@/services/api';
import { ClipboardList, Plus, Search, MoreVertical, Eye, Edit, Lock, Clock, CheckCircle, AlertCircle } from 'lucide-react';

export default function Recipes() {
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');

  const { data: recipes, isLoading } = useQuery({
    queryKey: ['recipes'],
    queryFn: () => recipesApi.getAll(),
  });

  // API can return either array directly or { data: array }
  const recipesList = Array.isArray(recipes) ? recipes : (recipes as any)?.data || [];

  const filteredRecipes = recipesList.filter((recipe: any) => {
    if (!recipe) return false;
    const matchesSearch = (recipe.recipeCode?.toLowerCase() || '').includes(search.toLowerCase()) ||
                         (recipe.recipeName?.toLowerCase() || '').includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'all' || recipe.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const getStatusInfo = (status: string) => {
    switch (status) {
      case 'Draft':
        return { 
          label: 'Nháp', 
          badgeClass: 'inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-accent-50 text-accent-700 border border-accent-200',
          icon: Clock,
          iconBg: 'bg-accent-100 text-accent-600'
        };
      case 'Approved':
        return { 
          label: 'Đã duyệt', 
          badgeClass: 'inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-primary-50 text-primary-700 border border-primary-200',
          icon: CheckCircle,
          iconBg: 'bg-primary-100 text-primary-600'
        };
      case 'InProcess':
        return { 
          label: 'Đang sản xuất', 
          badgeClass: 'inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-purple-50 text-purple-700 border border-purple-200',
          icon: AlertCircle,
          iconBg: 'bg-purple-100 text-purple-600'
        };
      case 'Hold':
        return { 
          label: 'Tạm dừng', 
          badgeClass: 'inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-orange-50 text-orange-700 border border-orange-200',
          icon: Clock,
          iconBg: 'bg-orange-100 text-orange-600'
        };
      case 'Completed':
        return { 
          label: 'Hoàn thành', 
          badgeClass: 'inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-secondary-50 text-secondary-700 border border-secondary-200',
          icon: CheckCircle,
          iconBg: 'bg-secondary-100 text-secondary-600'
        };
      default:
        return { 
          label: status, 
          badgeClass: 'inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-neutral-50 text-neutral-700 border border-neutral-200',
          icon: Clock,
          iconBg: 'bg-neutral-100 text-neutral-600'
        };
    }
  };

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900">Quản Lý Công Thức & BOM</h1>
          <p className="text-neutral-500 mt-1">Tạo, quản lý và duyệt công thức sản xuất theo GMP</p>
        </div>
        <button className="btn-primary flex items-center">
          <Plus className="w-5 h-5 mr-2" />
          Thêm công thức
        </button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {[
          { label: 'Tổng công thức', value: recipesList.length, bg: 'bg-primary-50', iconBg: 'bg-primary-100 text-primary-600' },
          { label: 'Nháp', value: recipesList.filter((r: any) => r.status === 'Draft').length, bg: 'bg-accent-50', iconBg: 'bg-accent-100 text-accent-600' },
          { label: 'Đã duyệt', value: recipesList.filter((r: any) => r.status === 'Approved').length, bg: 'bg-primary-50', iconBg: 'bg-primary-100 text-primary-600' },
          { label: 'Đang hoạt động', value: recipesList.filter((r: any) => r.status === 'InProcess').length, bg: 'bg-secondary-50', iconBg: 'bg-secondary-100 text-secondary-600' },
        ].map((stat) => (
          <div key={stat.label} className="card p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-neutral-500">{stat.label}</p>
                <p className="text-2xl font-bold text-neutral-900 mt-1">{stat.value}</p>
              </div>
              <div className={`w-10 h-10 rounded-xl ${stat.bg} flex items-center justify-center`}>
                <ClipboardList className={`w-5 h-5 ${stat.iconBg.split(' ')[1]}`} />
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Filters */}
      <div className="card">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-neutral-400" />
            <input
              type="text"
              placeholder="Tìm kiếm công thức..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="input pl-10"
            />
          </div>
          <div className="flex items-center space-x-2">
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="input w-auto"
            >
              <option value="all">Tất cả trạng thái</option>
              <option value="Draft">Nháp</option>
              <option value="Approved">Đã duyệt</option>
              <option value="InProcess">Đang sản xuất</option>
              <option value="Hold">Tạm dừng</option>
              <option value="Completed">Hoàn thành</option>
            </select>
          </div>
        </div>
      </div>

      {/* Recipes Grid */}
      {isLoading ? (
        <div className="flex items-center justify-center p-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
        </div>
      ) : filteredRecipes.length === 0 ? (
        <div className="card text-center py-12">
          <ClipboardList className="w-12 h-12 text-neutral-300 mx-auto mb-4" />
          <p className="text-neutral-500">Chưa có công thức nào</p>
          <button className="btn-primary mt-4">Tạo công thức đầu tiên</button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredRecipes.map((recipe: any) => {
            const statusInfo = getStatusInfo(recipe.status);
            const StatusIcon = statusInfo.icon;
            return (
              <div key={recipe.recipeId} className="card group hover:shadow-lg transition-shadow">
                <div className="flex items-start justify-between mb-4">
                  <div className="flex items-center space-x-3">
                    <div className={`p-2 rounded-lg ${statusInfo.iconBg}`}>
                      <ClipboardList className="w-5 h-5 text-primary-600" />
                    </div>
                    <div>
                      <p className="font-mono text-sm text-primary-600">{recipe.recipeCode}</p>
                      <h3 className="font-semibold text-neutral-900">{recipe.recipeName}</h3>
                    </div>
                  </div>
                  <button className="p-1 rounded hover:bg-neutral-100">
                    <MoreVertical className="w-4 h-4 text-neutral-500" />
                  </button>
                </div>

                <div className="space-y-3 mb-4">
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-neutral-500">Version</span>
                    <span className="font-medium">v{recipe.version || 1}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-neutral-500">Batch Size</span>
                    <span className="font-medium">{recipe.batchSize || '-'}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-neutral-500">Trạng thái</span>
                    <span className={statusInfo.badgeClass}>
                      <StatusIcon className="w-3 h-3 mr-1" />
                      {statusInfo.label}
                    </span>
                  </div>
                  {recipe.approvedDate && (
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-neutral-500">Duyệt bởi</span>
                      <span className="font-medium">{recipe.approvedBy || 'Admin'}</span>
                    </div>
                  )}
                </div>

                <div className="pt-4 border-t border-neutral-200 flex items-center justify-between">
                  <div className="text-xs text-neutral-500">
                    Tạo: {new Date(recipe.createdAt).toLocaleDateString('vi-VN')}
                  </div>
                  <div className="flex items-center space-x-2">
                    <button className="btn-ghost text-sm flex items-center">
                      <Eye className="w-4 h-4 mr-1" />
                      Xem
                    </button>
                    {recipe.status === 'Draft' ? (
                      <button className="btn-ghost text-sm flex items-center">
                        <Edit className="w-4 h-4 mr-1" />
                        Sửa
                      </button>
                    ) : (
                      <button className="btn-ghost text-sm flex items-center text-neutral-400" disabled title="Chỉ có thể chỉnh sửa ở trạng thái Nháp">
                        <Lock className="w-4 h-4 mr-1" />
                        Khóa
                      </button>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* GMP Info Banner */}
      <div className="bg-gradient-to-r from-primary-50 to-secondary-50 rounded-xl p-6 border border-primary-100">
        <div className="flex items-start space-x-4">
          <div className="p-2 bg-primary-100 rounded-lg">
            <AlertCircle className="w-6 h-6 text-primary-600" />
          </div>
          <div>
            <h3 className="font-semibold text-primary-900 mb-2">Quy trình Quản lý Công thức (GMP)</h3>
            <ul className="text-sm text-primary-800 space-y-1">
              <li>• Chỉ có thể chỉnh sửa công thức ở trạng thái <strong>Nháp (Draft)</strong></li>
              <li>• Khi duyệt (Approved), công thức sẽ bị khóa và tạo snapshot cho Production Order</li>
              <li>• Mỗi lần sửa sẽ tạo version mới, giữ lại lịch sử phiên bản</li>
              <li>• Audit Trail tự động ghi lại mọi thay đổi</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
}
