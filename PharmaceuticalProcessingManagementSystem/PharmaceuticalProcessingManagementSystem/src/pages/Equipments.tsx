import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { equipmentsApi } from '@/services/api';
import { Search, Settings, Filter, Plus, PenTool, CheckCircle2, AlertTriangle, AlertOctagon } from 'lucide-react';

export default function Equipments() {
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');

  const { data: equipments, isLoading } = useQuery({
    queryKey: ['equipments', statusFilter],
    queryFn: () => equipmentsApi.getAll({ status: statusFilter || undefined }),
  });

  const equipData = Array.isArray(equipments) ? equipments : (equipments as any)?.data ?? [];

  const normalizedEquips = equipData.map((m: any) => ({
    equipmentId: m.EquipmentId || m.equipmentId,
    equipmentCode: m.EquipmentCode || m.equipmentCode,
    equipmentName: m.EquipmentName || m.equipmentName,
    status: m.Status || m.status || 'Active',
    lastMaintenanceDate: m.LastMaintenanceDate || m.lastMaintenanceDate,
  }));

  const filteredEquips = normalizedEquips.filter((e: any) => {
    if (!e) return false;
    const term = search.toLowerCase();
    const code = typeof e.equipmentCode === 'string' ? e.equipmentCode.toLowerCase() : '';
    const name = typeof e.equipmentName === 'string' ? e.equipmentName.toLowerCase() : '';
    return code.includes(term) || name.includes(term);
  });

  const getStatusDisplay = (status: string) => {
    switch (status) {
      case 'Active':
      case 'Running':
      case 'Hoạt động':
        return (
          <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700">
            <CheckCircle2 className="w-3.5 h-3.5 mr-1" />
            Đang hoạt động
          </span>
        );
      case 'Maintenance':
      case 'Bảo trì':
        return (
          <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-700">
            <AlertTriangle className="w-3.5 h-3.5 mr-1" />
            Đang bảo trì
          </span>
        );
      case 'Broken':
      case 'Hỏng hóc':
        return (
          <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-red-100 text-red-700">
            <AlertOctagon className="w-3.5 h-3.5 mr-1" />
            Hỏng hóc
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-neutral-100 text-neutral-700">
            {status}
          </span>
        );
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center space-y-4 sm:space-y-0">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900">Quản Lý Thiết Bị</h1>
          <p className="text-sm text-neutral-500 mt-1">
            Theo dõi tình trạng hoạt động và thông tin bảo trì của máy móc thiết bị.
          </p>
        </div>
        <button className="btn-primary w-full sm:w-auto">
          <Plus className="w-5 h-5 mr-2" />
          Thêm thiết bị mới
        </button>
      </div>

      <div className="bg-surface border border-neutral-200 rounded-xl overflow-hidden shadow-sm">
        <div className="p-4 border-b border-neutral-200 bg-neutral-50/50 flex flex-col sm:flex-row gap-4 justify-between">
          <div className="relative w-full sm:w-96">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-neutral-400" />
            <input
              type="text"
              placeholder="Tìm kiếm mã máy, tên thiết bị..."
              value={search}
              onChange={(e: React.ChangeEvent<HTMLInputElement>) => setSearch(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-neutral-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500 transition-shadow"
            />
          </div>
          <div className="flex gap-2 w-full sm:w-auto">
            <select
              value={statusFilter}
              onChange={(e: React.ChangeEvent<HTMLSelectElement>) => setStatusFilter(e.target.value)}
              className="w-full sm:w-auto px-3 py-2 border border-neutral-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500 bg-white"
            >
              <option value="">Tất cả trạng thái</option>
              <option value="Active">Đang hoạt động</option>
              <option value="Maintenance">Đang bảo trì</option>
              <option value="Broken">Hỏng hóc</option>
            </select>
            <button className="btn-secondary whitespace-nowrap">
              <Filter className="w-4 h-4 mr-2" />
              Lọc chi tiết
            </button>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-neutral-50 border-b border-neutral-200">
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">ID</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Mã Thiết Bị</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Tên Thiết Bị</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Trạng Thái</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Bảo Trì Gần Nhất</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600 text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-200">
              {isLoading ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-neutral-500">
                    <div className="flex items-center justify-center space-x-2">
                      <div className="w-5 h-5 border-2 border-primary-500 border-t-transparent rounded-full animate-spin" />
                      <span>Đang tải dữ liệu thiết bị...</span>
                    </div>
                  </td>
                </tr>
              ) : filteredEquips.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-12 text-center text-neutral-500">
                    <Settings className="w-12 h-12 text-neutral-300 mx-auto mb-3" />
                    <p className="text-lg font-medium text-neutral-900">Không có thiết bị</p>
                    <p className="text-sm">Chưa có thiết bị nào trong dây chuyền hoặc từ khóa tìm kiếm không khớp.</p>
                  </td>
                </tr>
              ) : (
                filteredEquips.map((equip: any) => (
                  <tr key={equip.equipmentId} className="hover:bg-neutral-50 transition-colors">
                    <td className="py-3 px-4 text-sm text-neutral-900 font-medium">#{equip.equipmentId}</td>
                    <td className="py-3 px-4 text-sm font-mono text-neutral-600">{equip.equipmentCode}</td>
                    <td className="py-3 px-4 text-sm text-neutral-900 font-medium">{equip.equipmentName}</td>
                    <td className="py-3 px-4">
                      {getStatusDisplay(equip.status)}
                    </td>
                    <td className="py-3 px-4 text-sm text-neutral-500">
                      {equip.lastMaintenanceDate ? new Date(equip.lastMaintenanceDate).toLocaleDateString('vi-VN') : '-'}
                    </td>
                    <td className="py-3 px-4 text-right">
                      <div className="flex items-center justify-end space-x-2">
                        <button className="p-1.5 text-neutral-400 hover:text-primary-600 hover:bg-primary-50 rounded-lg transition-colors" title="Cập nhật bảo trì">
                          <PenTool className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
