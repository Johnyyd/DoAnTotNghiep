import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { recipesApi, materialsApi } from '@/services/api';
import { Recipe } from '@/types';
import { ClipboardList, Plus, Search, MoreVertical, Eye, Edit, Lock, Clock, CheckCircle, AlertCircle, Trash2 } from 'lucide-react';

export default function Recipes() {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [showModal, setShowModal] = useState(false);
  const [editingRecipe, setEditingRecipe] = useState<Recipe | null>(null);
  const [formData, setFormData] = useState<Partial<Recipe>>({});
  const [showActions, setShowActions] = useState<number | null>(null);

  const { data: recipes, isLoading } = useQuery({
    queryKey: ['recipes'],
    queryFn: () => recipesApi.getAll(),
  });

  // API can return either array directly or { data: array }
  const recipesData = Array.isArray(recipes) ? recipes : (recipes as any)?.data || [];

  const { data: materialsData } = useQuery({
    queryKey: ['materials'],
    queryFn: () => materialsApi.getAll(),
  });
  const materials = Array.isArray(materialsData) ? materialsData : (materialsData as any)?.data || [];

  const createMutation = useMutation({
    mutationFn: recipesApi.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['recipes'] });
      setShowModal(false);
      setFormData({});
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: number; data: Partial<Recipe> }) =>
      recipesApi.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['recipes'] });
      setShowModal(false);
      setEditingRecipe(null);
      setFormData({});
    },
  });

  const deleteMutation = useMutation({
    mutationFn: recipesApi.delete,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['recipes'] });
    },
  });

  const openCreateModal = () => {
    setEditingRecipe(null);
    setFormData({ status: 'Draft', versionNumber: 1 });
    setShowModal(true);
  };

  const openEditModal = (recipe: Recipe) => {
    setEditingRecipe(recipe);
    setFormData(recipe);
    setShowModal(true);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (editingRecipe) {
      updateMutation.mutate({ id: editingRecipe.recipeId, data: formData });
    } else {
      createMutation.mutate(formData);
    }
  };

  // Map API data to match frontend Recipe type
  const normalizedRecipes: Recipe[] = recipesData.map((r: any) => ({
    recipeId: r.RecipeId,
    recipeCode: r.RecipeCode,
    recipeName: r.RecipeName,
    materialId: r.MaterialId,
    batchSize: r.BatchSize,
    status: r.Status,
    versionNumber: r.VersionNumber,
    createdAt: r.CreatedAt,
    effectiveDate: r.EffectiveDate,
    note: r.Note,
    approvedBy: r.ApprovedBy,
    approvedDate: r.ApprovedDate,
    material: r.Material,
    productionOrders: r.ProductionOrders || [],
    recipeBoms: r.RecipeBoms || [],
    recipeRoutings: r.RecipeRoutings || [],
  }));

  const filteredRecipes = normalizedRecipes.filter((recipe: Recipe) => {
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
          label: status || 'Không xác định', 
          badgeClass: 'inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-neutral-50 text-neutral-700 border border-neutral-200',
          icon: Clock,
          iconBg: 'bg-neutral-100 text-neutral-600'
        };
    }
  };

  const formatDate = (dateString?: string) => {
    if (!dateString) return '-';
    try {
      return new Date(dateString).toLocaleDateString('vi-VN');
    } catch {
      return 'Invalid Date';
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900">Quản Lý Công Thức & BOM</h1>
          <p className="text-neutral-500 mt-1">Tạo, quản lý và duyệt công thức sản xuất theo GMP</p>
        </div>
        <button onClick={openCreateModal} className="btn-primary flex items-center">
          <Plus className="w-5 h-5 mr-2" />
          Thêm công thức
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {[
          { label: 'Tổng công thức', value: filteredRecipes.length, bg: 'bg-primary-50', iconBg: 'bg-primary-100 text-primary-600' },
          { label: 'Nháp', value: filteredRecipes.filter(c => c.status === 'Draft').length, bg: 'bg-accent-50', iconBg: 'bg-accent-100 text-accent-600' },
          { label: 'Đã duyệt', value: filteredRecipes.filter(c => c.status === 'Approved').length, bg: 'bg-primary-50', iconBg: 'bg-primary-100 text-primary-600' },
          { label: 'Đang hoạt động', value: filteredRecipes.filter(c => c.status === 'InProcess').length, bg: 'bg-secondary-50', iconBg: 'bg-secondary-100 text-secondary-600' },
        ].map((stat, idx) => (
          <div key={idx} className={`card p-4`}>
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-neutral-500">{stat.label}</p>
                <p className="text-2xl font-bold text-neutral-900 mt-1">{stat.value}</p>
              </div>
              <div className={`p-3 rounded-xl ${stat.bg}`}>
                <ClipboardList className={`w-6 h-6 ${stat.iconBg.split(' ')[1]}`} />
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
              onChange={(e: React.ChangeEvent<HTMLInputElement>) => setSearch(e.target.value)}
              className="input pl-10"
            />
          </div>
          <div className="flex items-center space-x-2">
            <select
              value={statusFilter}
              onChange={(e: React.ChangeEvent<HTMLSelectElement>) => setStatusFilter(e.target.value)}
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

      {/* Recipe Grid */}
      {isLoading ? (
        <div className="flex items-center justify-center p-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
        </div>
      ) : filteredRecipes.length === 0 ? (
        <div className="card text-center py-12">
          <ClipboardList className="w-12 h-12 text-neutral-300 mx-auto mb-4" />
          <p className="text-neutral-500">Chưa có công thức nào</p>
          <button onClick={openCreateModal} className="btn-primary mt-4">Tạo công thức đầu tiên</button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredRecipes.map((recipe) => {
            const statusInfo = getStatusInfo(recipe.status);
            return (
              <div key={recipe.recipeId} className="card group hover:shadow-lg transition-shadow">
                <div className="flex items-start justify-between mb-4">
                  <div className="flex items-center space-x-3">
                    <div className={`p-2 rounded-lg ${statusInfo.iconBg}`}>
                      <statusInfo.icon className="w-5 h-5 text-primary-600" />
                    </div>
                    <div>
                      <p className="font-mono text-sm text-primary-600">{recipe.recipeCode}</p>
                      <h3 className="font-semibold text-neutral-900">{recipe.recipeName}</h3>
                    </div>
                  </div>
                  <div className="relative">
                    <button onClick={() => setShowActions(showActions === recipe.recipeId ? null : recipe.recipeId)} className="p-1 rounded hover:bg-neutral-100">
                      <MoreVertical className="w-4 h-4 text-neutral-500" />
                    </button>
                    {showActions === recipe.recipeId && (
                      <div className="absolute right-0 mt-2 w-48 bg-surface rounded-xl shadow-lg border border-neutral-200 py-2 z-10">
                        <button
                          onClick={() => { if (confirm('Xóa công thức này?')) deleteMutation.mutate(recipe.recipeId); setShowActions(null); }}
                          className="w-full flex items-center px-4 py-2 text-sm text-red-600 hover:bg-red-50"
                        >
                          <Trash2 className="w-4 h-4 mr-3" />
                          Xóa
                        </button>
                      </div>
                    )}
                  </div>
                </div>
                <div className="space-y-3 mb-4">
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-neutral-500">Phiên bản</span>
                    <span className="font-medium">v{recipe.versionNumber || 1}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-neutral-500">Cỡ lô</span>
                    <span className="font-medium">{recipe.batchSize?.toLocaleString() || '-'}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-neutral-500">Trạng thái</span>
                    <span className={statusInfo.badgeClass}>
                      <statusInfo.icon className="w-3 h-3 mr-1" />
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
                    Tạo: {formatDate(recipe.createdAt)}
                  </div>
                  <div className="flex items-center space-x-2">
                    <button className="btn-ghost text-sm flex items-center">
                      <Eye className="w-4 h-4 mr-1" />
                      Xem
                    </button>
                    {recipe.status === 'Draft' ? (
                      <button onClick={() => openEditModal(recipe)} className="btn-ghost text-sm flex items-center">
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

      {/* Info Box */}
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

      {/* Create/Edit Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-neutral-900 bg-opacity-50 z-50 flex items-center justify-center p-4">
          <div className="bg-surface rounded-2xl shadow-2xl w-full max-w-lg max-h-[90vh] overflow-y-auto">
            <div className="p-6 border-b border-neutral-200">
              <div className="flex items-center justify-between">
                <h2 className="text-xl font-bold text-neutral-900">
                  {editingRecipe ? 'Chỉnh sửa công thức' : 'Thêm công thức mới'}
                </h2>
                <button onClick={() => setShowModal(false)} className="text-neutral-400 hover:text-neutral-600 text-2xl">&times;</button>
              </div>
            </div>
            <form onSubmit={handleSubmit} className="p-6 space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-2">Mã công thức</label>
                  <input
                    type="text"
                    required
                    value={formData.recipeCode || ''}
                    onChange={(e) => setFormData({ ...formData, recipeCode: e.target.value })}
                    className="input"
                    placeholder="VD: REC-001"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-2">Tên công thức</label>
                  <input
                    type="text"
                    required
                    value={formData.recipeName || ''}
                    onChange={(e) => setFormData({ ...formData, recipeName: e.target.value })}
                    className="input"
                    placeholder="VD: Paracetamol 500mg"
                  />
                </div>
                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-neutral-700 mb-2">Thành phẩm (Material)</label>
                  <select
                    required
                    value={formData.materialId || ''}
                    onChange={(e) => setFormData({ ...formData, materialId: Number(e.target.value) })}
                    className="input"
                  >
                    <option value="">Chọn thành phẩm...</option>
                    {materials.map((m: any) => (
                      <option key={m.MaterialId ?? m.materialId} value={m.MaterialId ?? m.materialId}>
                        {(m.MaterialCode ?? m.materialCode)} - {(m.MaterialName ?? m.materialName)}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-2">Cỡ lô (Batch Size)</label>
                  <input
                    type="number"
                    required
                    value={formData.batchSize || ''}
                    onChange={(e) => setFormData({ ...formData, batchSize: Number(e.target.value) })}
                    className="input"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-2">Trạng thái</label>
                  <select
                    required
                    value={formData.status || ''}
                    onChange={(e) => setFormData({ ...formData, status: e.target.value as NonNullable<Recipe['status']> })}
                    className="input"
                    disabled={!!editingRecipe && editingRecipe.status !== 'Draft'}
                  >
                    <option value="Draft">Nháp (Draft)</option>
                    <option value="Approved">Đã duyệt (Approved)</option>
                    <option value="InProcess">Đang thực hiện (InProcess)</option>
                    <option value="Hold">Tạm ngưng (Hold)</option>
                    <option value="Completed">Hoàn thành (Completed)</option>
                  </select>
                </div>
                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-neutral-700 mb-2">Ghi chú</label>
                  <textarea
                    rows={3}
                    value={formData.note || ''}
                    onChange={(e) => setFormData({ ...formData, note: e.target.value })}
                    className="input"
                  />
                </div>
              </div>
              <div className="flex justify-end space-x-3 pt-4 border-t border-neutral-200">
                <button type="button" onClick={() => setShowModal(false)} className="btn-ghost">Hủy</button>
                <button
                  type="submit"
                  disabled={createMutation.isPending || updateMutation.isPending}
                  className="btn-primary"
                >
                  {createMutation.isPending || updateMutation.isPending ? 'Đang lưu...' : (editingRecipe ? 'Cập nhật' : 'Tạo mới')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
