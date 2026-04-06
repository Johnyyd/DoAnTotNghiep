import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { equipmentsApi } from '@/services/api';
import { Search, Filter, Plus, Eye } from 'lucide-react';

type UiEquipment = {
  equipmentId: number;
  equipmentCode: string;
  equipmentName: string;
  status: string;
  lastMaintenanceDate?: string;
};

function normalizeEquipment(raw: any): UiEquipment {
  return {
    equipmentId: Number(raw.equipmentId ?? raw.EquipmentId ?? 0),
    equipmentCode: raw.equipmentCode ?? raw.EquipmentCode ?? '-',
    equipmentName: raw.equipmentName ?? raw.EquipmentName ?? '-',
    status: raw.status ?? raw.Status ?? 'Ready',
    lastMaintenanceDate: raw.lastMaintenanceDate ?? raw.LastMaintenanceDate,
  };
}

export default function Equipments() {
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');

  const { data: equipmentsRaw, isLoading } = useQuery({
    queryKey: ['equipments', statusFilter],
    queryFn: () => equipmentsApi.getAll({ status: statusFilter || undefined }),
  });

  const equipments = useMemo<UiEquipment[]>(() => {
    const rows = Array.isArray(equipmentsRaw) ? equipmentsRaw : (equipmentsRaw as any)?.data ?? [];
    return (rows as any[]).map(normalizeEquipment);
  }, [equipmentsRaw]);

  const filtered = useMemo(() => {
    const keyword = search.trim().toLowerCase();
    if (!keyword) return equipments;
    return equipments.filter((e) => e.equipmentCode.toLowerCase().includes(keyword) || e.equipmentName.toLowerCase().includes(keyword));
  }, [equipments, search]);

  const statusBadge = (status: string) => {
    const s = status.toLowerCase();
    if (s.includes('ready') || s.includes('active')) return 'bg-neutral-100 text-neutral-700';
    if (s.includes('maint')) return 'bg-yellow-100 text-yellow-700';
    if (s.includes('broken')) return 'bg-red-100 text-red-700';
    return 'bg-neutral-100 text-neutral-700';
  };

  const formatDate = (value?: string) => {
    if (!value) return '-';
    try {
      return new Date(value).toLocaleDateString('vi-VN');
    } catch {
      return '-';
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900">Quản Lý Thiết Bị</h1>
          <p className="text-sm text-neutral-500 mt-1">Theo dõi tình trạng hoạt động và thông tin bảo trì của máy móc thiết bị.</p>
        </div>
        <button className="btn-primary">
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
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-neutral-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
            />
          </div>
          <div className="flex gap-2 w-full sm:w-auto">
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="w-full sm:w-auto px-3 py-2 border border-neutral-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500 bg-white"
            >
              <option value="">Tất cả trạng thái</option>
              <option value="Ready">Ready</option>
              <option value="Maintenance">Maintenance</option>
              <option value="Broken">Broken</option>
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
                  <td colSpan={6} className="py-8 text-center text-neutral-500">Đang tải dữ liệu thiết bị...</td>
                </tr>
              ) : filtered.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-neutral-500">Không có thiết bị phù hợp</td>
                </tr>
              ) : (
                filtered.map((equip) => (
                  <tr key={equip.equipmentId} className="hover:bg-neutral-50 transition-colors">
                    <td className="py-3 px-4 text-sm text-neutral-900 font-medium">#{equip.equipmentId}</td>
                    <td className="py-3 px-4 text-sm font-mono text-neutral-600">{equip.equipmentCode}</td>
                    <td className="py-3 px-4 text-sm text-neutral-900 font-medium">{equip.equipmentName}</td>
                    <td className="py-3 px-4">
                      <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium ${statusBadge(equip.status)}`}>
                        {equip.status}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-sm text-neutral-500">{formatDate(equip.lastMaintenanceDate)}</td>
                    <td className="py-3 px-4 text-right">
                      <button className="btn-ghost text-sm inline-flex items-center">
                        <Eye className="w-4 h-4 mr-1" />Xem
                      </button>
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

