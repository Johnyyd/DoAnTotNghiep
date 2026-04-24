import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { areasApi } from '@/services/api';
import { Search, MapPin } from 'lucide-react';

type Area = {
  areaId: number;
  areaCode: string;
  areaName: string;
  description: string;
};

export default function ProductionAreas() {
  const [search, setSearch] = useState('');

  const { data: areasRaw, isLoading } = useQuery({
    queryKey: ['productionAreas'],
    queryFn: () => areasApi.getAll(),
  });

  const areas = useMemo(() => {
    const rows = Array.isArray(areasRaw) ? areasRaw : (areasRaw as any)?.data ?? [];
    return rows as Area[];
  }, [areasRaw]);

  const filtered = useMemo(() => {
    const keyword = search.trim().toLowerCase();
    if (!keyword) return areas;
    return areas.filter(
      (a) =>
        a.areaCode.toLowerCase().includes(keyword) ||
        a.areaName.toLowerCase().includes(keyword)
    );
  }, [areas, search]);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900">Phòng sản xuất</h1>
          <p className="text-sm text-neutral-500 mt-1">Danh mục các khu vực và phòng chức năng trong nhà máy</p>
        </div>
      </div>

      <div className="card">
        <div className="relative w-full md:w-96">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-neutral-400" />
          <input
            type="text"
            placeholder="Tìm mã hoặc tên phòng..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="input pl-10"
          />
        </div>
      </div>

      <div className="bg-surface border border-neutral-200 rounded-xl overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-neutral-50 border-b border-neutral-200">
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600 w-16 text-center">STT</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Mã phòng</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Tên phòng sản xuất</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Mô tả chi tiết</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-200">
              {isLoading ? (
                <tr>
                  <td colSpan={4} className="py-8 text-center text-neutral-500">
                    Đang tải dữ liệu...
                  </td>
                </tr>
              ) : filtered.length === 0 ? (
                <tr>
                  <td colSpan={4} className="py-8 text-center text-neutral-500">
                    Không có dữ liệu phòng sản xuất
                  </td>
                </tr>
              ) : (
                filtered.map((area, index) => (
                  <tr key={area.areaId} className="hover:bg-neutral-50 transition-colors">
                    <td className="py-3 px-4 text-sm text-neutral-500 text-center">{index + 1}</td>
                    <td className="py-3 px-4 text-sm font-mono text-primary-700 font-medium">#{area.areaCode}</td>
                    <td className="py-3 px-4">
                      <div className="flex items-center gap-2">
                        <MapPin className="w-4 h-4 text-neutral-400" />
                        <span className="text-sm text-neutral-900 font-semibold">{area.areaName}</span>
                      </div>
                    </td>
                    <td className="py-3 px-4 text-sm text-neutral-600 italic">
                      {area.description || 'Chưa có mô tả'}
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
