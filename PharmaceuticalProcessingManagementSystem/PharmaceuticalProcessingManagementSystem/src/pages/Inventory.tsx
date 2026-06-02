import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { inventoryApi } from '@/services/api';
import { PackageOpen, Search, ShieldCheck } from 'lucide-react';

export default function Inventory() {
  const [search, setSearch] = useState('');

  const { data: lots, isLoading } = useQuery({
    queryKey: ['inventory-lots'],
    queryFn: () => inventoryApi.getLots(),
  });

  const lotsData = Array.isArray(lots) ? lots : (lots as any)?.data ?? [];

  const grouped = useMemo(() => {
    const map = new Map<string, { materialCode: string; materialName: string; total: number; uom: string; lotCount: number; released: number; pending: number; locations: Set<string> }>();

    for (const lot of lotsData) {
      const material = lot.material ?? {};
      const materialType = String(material.type ?? lot.type ?? '').toLowerCase();
      if (materialType === 'finishedgood') continue;

      const materialCode = material.materialCode ?? lot.materialCode ?? `MAT-${lot.materialId}`;
      const materialName = material.materialName ?? lot.materialName ?? 'Nguyên liệu chưa rõ';
      const rawUom = String(material.baseUom?.uomName ?? material.baseUomName ?? lot.uomName ?? '').trim();
      const qty = Number(lot.quantityCurrent ?? 0);
      const key = String(materialCode);
      const location = lot.location?.locationCode ?? lot.locationCode ?? '';
      const qcStatus = lot.qcStatus ?? 'PendingQC';

      if (!map.has(key)) {
        map.set(key, { materialCode, materialName, total: 0, uom: rawUom, lotCount: 0, released: 0, pending: 0, locations: new Set() });
      }

      const row = map.get(key)!;
      row.total += qty;
      row.lotCount += 1;
      if (qcStatus === 'Released') row.released += 1;
      else row.pending += 1;
      if (location) row.locations.add(location);
      if (!row.uom && rawUom) row.uom = rawUom;
    }

    return Array.from(map.values()).map((row) => ({ ...row, locationText: Array.from(row.locations).join(', ') || '-' }));
  }, [lotsData]);

  const filtered = useMemo(() => {
    const term = search.trim().toLowerCase();
    if (!term) return grouped;
    return grouped.filter((row) => `${row.materialCode} ${row.materialName} ${row.locationText}`.toLowerCase().includes(term));
  }, [grouped, search]);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-neutral-900">Tồn kho nguyên liệu</h1>
        <p className="text-sm text-neutral-500 mt-1">Theo dõi tồn kho theo mã nguyên liệu, trạng thái duyệt và vị trí lưu trữ.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="card"><PackageOpen className="w-5 h-5 text-primary-600 mb-2" /><p className="text-sm text-neutral-500">Mã nguyên liệu có tồn</p><p className="text-2xl font-bold">{grouped.length}</p></div>
        <div className="card"><ShieldCheck className="w-5 h-5 text-green-600 mb-2" /><p className="text-sm text-neutral-500">Lô đã duyệt</p><p className="text-2xl font-bold">{grouped.reduce((sum, row) => sum + row.released, 0)}</p></div>
        <div className="card"><ShieldCheck className="w-5 h-5 text-amber-600 mb-2" /><p className="text-sm text-neutral-500">Lô chờ duyệt</p><p className="text-2xl font-bold">{grouped.reduce((sum, row) => sum + row.pending, 0)}</p></div>
      </div>

      <div className="card">
        <div className="relative w-full md:w-96">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-neutral-400" />
          <input type="text" placeholder="Tìm theo mã, tên hoặc vị trí kho..." value={search} onChange={(e) => setSearch(e.target.value)} className="input pl-10" />
        </div>
      </div>

      <div className="bg-surface border border-neutral-200 rounded-xl overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-neutral-50 border-b border-neutral-200">
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Mã nguyên liệu</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Tên nguyên liệu</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Số lô</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Trạng thái duyệt</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Vị trí</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600 text-right">Tổng tồn</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-200">
              {isLoading ? (
                <tr><td colSpan={6} className="py-8 text-center text-neutral-500">Đang tải dữ liệu tồn kho...</td></tr>
              ) : filtered.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-12 text-center text-neutral-500">
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
                    <td className="py-3 px-4 text-sm text-neutral-700">{row.released} đã duyệt / {row.pending} chờ duyệt</td>
                    <td className="py-3 px-4 text-sm text-neutral-700">{row.locationText}</td>
                    <td className="py-3 px-4 text-sm text-neutral-900 text-right font-mono">{row.total.toLocaleString('vi-VN', { maximumFractionDigits: 4 })} {row.uom}</td>
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
