import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { equipmentsApi } from '@/services/api';
import { Search } from 'lucide-react';

type UiEquipment = {
  equipmentCode: string;
  equipmentName: string;
  technicalSpec: string;
  usageFor: string;
  areaName: string;
  status: string;
};

function normalizeEquipment(raw: any): UiEquipment {
  return {
    equipmentCode: raw.equipmentCode ?? raw.EquipmentCode ?? '-',
    equipmentName: raw.equipmentName ?? raw.EquipmentName ?? '-',
    status: raw.status ?? raw.Status ?? 'Ready',
    technicalSpec: raw.technicalSpecification ?? raw.TechnicalSpecification ?? '-',
    usageFor: raw.usagePurpose ?? raw.UsagePurpose ?? '-',
    areaName: raw.area?.areaName ?? raw.Area?.AreaName ?? '-',
  };
}

export default function Equipments() {
  const [search, setSearch] = useState('');

  const { data: equipmentsRaw, isLoading } = useQuery({
    queryKey: ['equipments'],
    queryFn: () => equipmentsApi.getAll(),
  });

  const equipments = useMemo(() => {
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
    if (s.includes('ready') || s.includes('active')) return 'bg-green-100 text-green-700';
    if (s.includes('maint')) return 'bg-yellow-100 text-yellow-700';
    if (s.includes('broken')) return 'bg-red-100 text-red-700';
    return 'bg-neutral-100 text-neutral-700';
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-neutral-900">Quản lý thiết bị</h1>
        <p className="text-sm text-neutral-500 mt-1">Biểu mẫu thiết bị theo trang 2 CamScanner</p>
      </div>

      <div className="card">
        <div className="relative w-full md:w-96">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-neutral-400" />
          <input type="text" placeholder="Tìm mã hoặc tên thiết bị..." value={search} onChange={(e) => setSearch(e.target.value)} className="input pl-10" />
        </div>
      </div>

      <div className="bg-surface border border-neutral-200 rounded-xl overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-neutral-50 border-b border-neutral-200">
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Mã thiết bị</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Tên thiết bị</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Đặc tính kỹ thuật</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Công dụng</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Khu vực</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Trạng thái</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-200">
              {isLoading ? (
                <tr><td colSpan={6} className="py-8 text-center text-neutral-500">Đang tải dữ liệu thiết bị...</td></tr>
              ) : filtered.length === 0 ? (
                <tr><td colSpan={6} className="py-8 text-center text-neutral-500">Không có thiết bị phù hợp</td></tr>
              ) : (
                filtered.map((equip) => (
                  <tr key={equip.equipmentCode} className="hover:bg-neutral-50 transition-colors">
                    <td className="py-3 px-4 text-sm font-mono text-neutral-700">{equip.equipmentCode}</td>
                    <td className="py-3 px-4 text-sm text-neutral-900 font-medium">{equip.equipmentName}</td>
                    <td className="py-3 px-4 text-sm text-neutral-700">{equip.technicalSpec}</td>
                    <td className="py-3 px-4 text-sm text-neutral-700">{equip.usageFor}</td>
                    <td className="py-3 px-4 text-sm text-neutral-700">{equip.areaName}</td>
                    <td className="py-3 px-4"><span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium ${statusBadge(equip.status)}`}>{equip.status}</span></td>
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
