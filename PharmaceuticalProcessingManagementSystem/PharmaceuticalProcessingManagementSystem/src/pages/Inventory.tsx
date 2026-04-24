import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { inventoryApi } from '@/services/api';
import { Search, PackageOpen } from 'lucide-react';

export default function Inventory() {
  const [search, setSearch] = useState('');

  const { data: lots, isLoading } = useQuery({
    queryKey: ['inventory-lots'],
    queryFn: () => inventoryApi.getLots(),
  });

  const lotsData = Array.isArray(lots) ? lots : (lots as any)?.data ?? [];

  const grouped = useMemo(() => {
    const map = new Map<string, { materialCode: string; materialName: string; total: number; uom: string; lotCount: number }>();

    for (const lot of lotsData) {
      const material = lot.material ?? {};
      const materialCode = material.materialCode ?? lot.materialCode ?? `MAT-${lot.materialId}`;
      const materialName = material.materialName ?? lot.materialName ?? 'Nguyên liệu chưa rõ';
      const uom = material.baseUom?.uomName ?? material.baseUomName ?? lot.uomName ?? '';
      const qty = Number(lot.quantityCurrent ?? 0);
      const key = String(materialCode);

      if (!map.has(key)) {
        map.set(key, { materialCode, materialName, total: 0, uom, lotCount: 0 });
      }

      const row = map.get(key)!;
      row.total += qty;
      row.lotCount += 1;
      if (!row.uom && uom) row.uom = uom;
    }

    return Array.from(map.values());
  }, [lotsData]);

  const filtered = useMemo(() => {
    const term = search.trim().toLowerCase();
    if (!term) return grouped;
    return grouped.filter((row) => row.materialCode.toLowerCase().includes(term) || row.materialName.toLowerCase().includes(term));
  }, [grouped, search]);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-neutral-900">Quản lý tồn kho nguyên liệu</h1>
        <p className="text-sm text-neutral-500 mt-1">Theo dõi tổng tồn theo từng mã nguyên liệu</p>
      </div>

      <div className="card">
        <div className="relative w-full md:w-96">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-neutral-400" />
          <input type="text" placeholder="Tìm theo mã hoặc tên nguyên liệu..." value={search} onChange={(e) => setSearch(e.target.value)} className="input pl-10" />
        </div>
      </div>

      <div className="bg-surface border border-neutral-200 rounded-xl overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-neutral-50 border-b border-neutral-200">
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Mã nguyên liệu</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Tên nguyên liệu</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Số đợt nhập</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600 text-right">Tổng tồn hiện tại</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-200">
              {isLoading ? (
                <tr><td colSpan={4} className="py-8 text-center text-neutral-500">Đang tải dữ liệu tồn kho...</td></tr>
              ) : filtered.length === 0 ? (
                <tr>
                  <td colSpan={4} className="py-12 text-center text-neutral-500">
                    <PackageOpen className="w-12 h-12 text-neutral-300 mx-auto mb-3" />
                    <p className="text-lg font-medium text-neutral-900">Không có dữ liệu</p>
                    <p className="text-sm">Không tìm thấy nguyên liệu phù hợp.</p>
                  </td>
                </tr>
              ) : (
                filtered.map((row) => (
                  <tr key={row.materialCode} className="hover:bg-neutral-50 transition-colors">
                    <td className="py-3 px-4 text-sm font-mono text-primary-700">{row.materialCode}</td>
                    <td className="py-3 px-4 text-sm text-neutral-900 font-medium">{row.materialName}</td>
                    <td className="py-3 px-4 text-sm text-neutral-700">{row.lotCount}</td>
                    <td className="py-3 px-4 text-sm text-neutral-900 text-right font-mono">{row.total.toLocaleString()} {row.uom}</td>
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
