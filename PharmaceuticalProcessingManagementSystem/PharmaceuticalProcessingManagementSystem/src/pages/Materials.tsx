import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { materialsApi } from '@/services/api';
import { Material } from '@/types';
import { Plus, Trash2, Search, Package, Filter, MoreVertical, Edit2 } from 'lucide-react';

export default function Materials() {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [editingMaterial, setEditingMaterial] = useState<Material | null>(null);
  const [formData, setFormData] = useState<Partial<Material>>({});
  const [showActions, setShowActions] = useState<number | null>(null);

  const { data: materials, isLoading } = useQuery({
    queryKey: ['materials'],
    queryFn: () => materialsApi.getAll(),
  });

  // API can return either array directly or { data: array }
  const materialsData = Array.isArray(materials) ? materials : (materials as any)?.data ?? [];

  const createMutation = useMutation({
    mutationFn: materialsApi.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['materials'] });
      setShowModal(false);
      setFormData({});
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: number; data: Partial<Material> }) =>
      materialsApi.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['materials'] });
      setShowModal(false);
      setEditingMaterial(null);
      setFormData({});
    },
  });

  const deleteMutation = useMutation({
    mutationFn: materialsApi.delete,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['materials'] });
    },
  });

  const materialsList = (materialsData as Material[]).filter((m: Material) =>
    m.materialName.toLowerCase().includes(search.toLowerCase()) ||
    m.materialCode.toLowerCase().includes(search.toLowerCase())
  ) || [];
  const filteredMaterials: Material[] = materialsList;

  const openCreateModal = () => {
    setEditingMaterial(null);
    setFormData({ isActive: true });
    setShowModal(true);
  };

  const openEditModal = (material: Material) => {
    setEditingMaterial(material);
    setFormData(material);
    setShowModal(true);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (editingMaterial) {
      updateMutation.mutate({ id: editingMaterial.materialId, data: formData });
    } else {
      createMutation.mutate(formData);
    }
  };

  const getTypeLabel = (type: string) => {
    const labels: Record<string, { label: string; color: string }> = {
      RawMaterial: { label: 'Nguyên liệu', color: 'bg-blue-100 text-blue-700' },
      Packaging: { label: 'Bao bì', color: 'bg-purple-100 text-purple-700' },
      FinishedGood: { label: 'Thành phẩm', color: 'bg-green-100 text-green-700' },
      Intermediate: { label: 'Bán thành phẩm', color: 'bg-orange-100 text-orange-700' },
    };
    return labels[type] || { label: type, color: 'bg-neutral-100 text-neutral-700' };
  };

  const getStatusBadge = (isActive: boolean) => (
    <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${isActive ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
      {isActive ? 'Hoạt động' : 'Ngưng'}
    </span>
  );

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900">Quản Lý Nguyên Liệu & Thành Phẩm</h1>
          <p className="text-neutral-500 mt-1">Quản lý kho, theo dõi chất lượng và truy xuất nguồn gốc</p>
        </div>
        <button
          onClick={openCreateModal}
          className="btn-primary flex items-center"
        >
          <Plus className="w-5 h-5 mr-2" />
          Thêm mới
        </button>
      </div>

      {/* Filters & Search */}
      <div className="card">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-neutral-400" />
            <input
              type="text"
              placeholder="Tìm kiếm theo mã hoặc tên nguyên liệu..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="input pl-10"
            />
          </div>
          <button className="btn-outline flex items-center">
            <Filter className="w-5 h-5 mr-2" />
            Bộ lọc
          </button>
        </div>

        {/* Stats */}
        <div className="mt-6 flex items-center space-x-6 text-sm">
          <div className="flex items-center space-x-2">
            <span className="text-neutral-500">Tổng:</span>
            <span className="font-bold text-neutral-900">{filteredMaterials.length}</span>
          </div>
          <div className="flex items-center space-x-2">
            <span className="text-neutral-500">Hoạt động:</span>
            <span className="font-bold text-secondary-600">{filteredMaterials.filter(m => m.isActive).length}</span>
          </div>
          <div className="flex items-center space-x-2">
            <span className="text-neutral-500">Ngưng:</span>
            <span className="font-bold text-accent-600">{filteredMaterials.filter(m => !m.isActive).length}</span>
          </div>
        </div>
      </div>

      {/* Table */}
      <div className="card p-0 overflow-hidden">
        {isLoading ? (
          <div className="flex items-center justify-center p-12">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
          </div>
        ) : filteredMaterials.length === 0 ? (
          <div className="text-center py-12">
            <Package className="w-12 h-12 text-neutral-300 mx-auto mb-4" />
            <p className="text-neutral-500">Không tìm thấy nguyên liệu nào</p>
          </div>
        ) : (
          <div className="table-container">
            <table className="table">
              <thead>
                <tr>
                  <th>Mã</th>
                  <th>Tên</th>
                  <th>Loại</th>
                  <th>Đơn vị</th>
                  <th>Trạng thái</th>
                  <th>Ngày tạo</th>
                  <th className="text-right">Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {filteredMaterials.map((material) => {
                  const typeInfo = getTypeLabel(material.type);
                  return (
                    <tr key={material.materialId}>
                      <td>
                        <code className="text-xs bg-neutral-100 px-2 py-1 rounded font-mono text-primary-600">
                          {material.materialCode}
                        </code>
                      </td>
                      <td className="font-medium text-neutral-900">{material.materialName}</td>
                      <td>
                        <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium ${typeInfo.color}`}>
                          {typeInfo.label}
                        </span>
                      </td>
                      <td className="text-neutral-600">{material.baseUomName || '-'}</td>
                      <td>{getStatusBadge(material.isActive)}</td>
                      <td className="text-neutral-500 text-sm">
                        {new Date(material.createdAt).toLocaleDateString('vi-VN')}
                      </td>
                      <td className="text-right">
                        <div className="relative">
                          <button
                            onClick={() => setShowActions(showActions === material.materialId ? null : material.materialId)}
                            className="p-2 rounded-lg hover:bg-neutral-100 transition-colors"
                          >
                            <MoreVertical className="w-4 h-4 text-neutral-500" />
                          </button>
                          {showActions === material.materialId && (
                            <div className="absolute right-0 mt-2 w-48 bg-surface rounded-xl shadow-lg border border-neutral-200 py-2 z-10">
                              <button
                                onClick={() => {
                                  openEditModal(material);
                                  setShowActions(null);
                                }}
                                className="w-full flex items-center px-4 py-2 text-sm text-neutral-700 hover:bg-neutral-50"
                              >
                                <Edit2 className="w-4 h-4 mr-3" />
                                Chỉnh sửa
                              </button>
                              <button
                                onClick={() => {
                                  if (confirm('Xóa nguyên liệu này?')) {
                                    deleteMutation.mutate(material.materialId);
                                  }
                                  setShowActions(null);
                                }}
                                className="w-full flex items-center px-4 py-2 text-sm text-red-600 hover:bg-red-50"
                              >
                                <Trash2 className="w-4 h-4 mr-3" />
                                Xóa
                              </button>
                            </div>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Create/Edit Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-neutral-900 bg-opacity-50 z-50 flex items-center justify-center p-4">
          <div className="bg-surface rounded-2xl shadow-2xl w-full max-w-lg max-h-[90vh] overflow-y-auto">
            <div className="p-6 border-b border-neutral-200">
              <div className="flex items-center justify-between">
                <h2 className="text-xl font-bold text-neutral-900">
                  {editingMaterial ? 'Chỉnh sửa nguyên liệu' : 'Thêm nguyên liệu mới'}
                </h2>
                <button onClick={() => setShowModal(false)} className="text-neutral-400 hover:text-neutral-600">
                  <span className="sr-only">Đóng</span>
                  &times;
                </button>
              </div>
            </div>

            <form onSubmit={handleSubmit} className="p-6 space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-2">Mã nguyên liệu</label>
                  <input
                    type="text"
                    required
                    value={formData.materialCode || ''}
                    onChange={(e) => setFormData({ ...formData, materialCode: e.target.value })}
                    className="input"
                    placeholder="VD: MAT-001"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-2">Tên nguyên liệu</label>
                  <input
                    type="text"
                    required
                    value={formData.materialName || ''}
                    onChange={(e) => setFormData({ ...formData, materialName: e.target.value })}
                    className="input"
                    placeholder="VD: Paracetamol 500mg"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-2">Loại</label>
                  <select
                    required
                    value={formData.type || ''}
                    onChange={(e) => setFormData({ ...formData, type: e.target.value as any })}
                    className="input"
                  >
                    <option value="">Chọn loại</option>
                    <option value="RawMaterial">Nguyên liệu</option>
                    <option value="Packaging">Bao bì</option>
                    <option value="FinishedGood">Thành phẩm</option>
                    <option value="Intermediate">Bán thành phẩm</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-2">Đơn vị cơ sở</label>
                  <select
                    required
                    value={formData.baseUomId || ''}
                    onChange={(e) => setFormData({ ...formData, baseUomId: Number(e.target.value) })}
                    className="input"
                  >
                    <option value="">Chọn đơn vị</option>
                    <option value="1">Kilogram (kg)</option>
                    <option value="2">Gram (g)</option>
                    <option value="3">Viên (tablet)</option>
                    <option value="4">Lít (L)</option>
                  </select>
                </div>
                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-neutral-700 mb-2">Mô tả</label>
                  <textarea
                    rows={3}
                    value={formData.description || ''}
                    onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                    className="input"
                    placeholder="Mô tả chi tiết về nguyên liệu..."
                  />
                </div>
                <div className="md:col-span-2">
                  <label className="flex items-center space-x-2">
                    <input
                      type="checkbox"
                      checked={formData.isActive}
                      onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })}
                      className="w-4 h-4 text-primary-600 rounded focus:ring-primary-500"
                    />
                    <span className="text-sm font-medium text-neutral-700">Hoạt động</span>
                  </label>
                </div>
              </div>

              <div className="flex justify-end space-x-3 pt-4 border-t border-neutral-200">
                <button
                  type="button"
                  onClick={() => setShowModal(false)}
                  className="btn-ghost"
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  disabled={createMutation.isPending || updateMutation.isPending}
                  className="btn-primary"
                >
                  {createMutation.isPending || updateMutation.isPending ? (
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                  ) : null}
                  {editingMaterial ? 'Cập nhật' : 'Tạo mới'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
