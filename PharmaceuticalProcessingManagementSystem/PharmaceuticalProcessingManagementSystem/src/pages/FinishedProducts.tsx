import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { certificatesApi, inventoryApi, materialsApi } from '@/services/api';
import { FileCheck2, Search } from 'lucide-react';

function normalizeMaterial(raw: any) {
  return {
    materialId: Number(raw.materialId ?? raw.MaterialId ?? 0),
    materialCode: raw.materialCode ?? raw.MaterialCode ?? '-',
    materialName: raw.materialName ?? raw.MaterialName ?? '-',
    type: raw.type ?? raw.Type ?? 'RawMaterial',
    baseUomName: raw.baseUomName ?? raw.BaseUomName ?? raw.baseUom?.uomName ?? raw.BaseUom?.UomName ?? '-',
  };
}

function viUnit(unit: string) {
  const u = unit.toLowerCase();
  if (u.includes('box')) return 'thùng';
  if (u.includes('tablet')) return 'viên';
  if (u.includes('carton')) return 'thùng';
  return unit || 'đơn vị';
}

export default function FinishedProducts() {
  const [search, setSearch] = useState('');
  const [tab, setTab] = useState<'completed' | 'target'>('completed');

  const { data: materialsRaw, isLoading } = useQuery({ queryKey: ['materials'], queryFn: () => materialsApi.getAll() });
  const { data: lotsRaw } = useQuery({ queryKey: ['inventoryLots'], queryFn: () => inventoryApi.getAll() });

  const materials = useMemo(() => {
    const rows = Array.isArray(materialsRaw) ? materialsRaw : (materialsRaw as any)?.data ?? [];
    return (rows as any[]).map(normalizeMaterial).filter((m) => m.type === 'FinishedGood');
  }, [materialsRaw]);

  const lots = useMemo(() => {
    const rows = Array.isArray(lotsRaw) ? lotsRaw : (lotsRaw as any)?.data ?? [];
    return rows as any[];
  }, [lotsRaw]);

  const grouped = useMemo(() => {
    const map = new Map<number, { completedQty: number; targetQty: number; unit: string }>();
    for (const lot of lots) {
      const materialId = Number(lot.materialId ?? lot.MaterialId ?? 0);
      const qty = Number(lot.quantityCurrent ?? lot.QuantityCurrent ?? 0);
      const status = (lot.qcstatus ?? lot.QCStatus ?? '').toString().toLowerCase();
      const unit = lot.material?.baseUom?.uomName ?? lot.material?.BaseUom?.UomName ?? '';
      if (!materialId) continue;
      if (!map.has(materialId)) map.set(materialId, { completedQty: 0, targetQty: 0, unit: unit || '' });
      const row = map.get(materialId)!;
      if (status.includes('completed') || status.includes('released')) row.completedQty += qty;
      else row.targetQty += qty;
      if (!row.unit && unit) row.unit = unit;
    }
    return map;
  }, [lots]);

  const filtered = useMemo(() => {
    const keyword = search.trim().toLowerCase();
    let rows = materials;
    if (keyword) {
      rows = rows.filter((m) => m.materialCode.toLowerCase().includes(keyword) || m.materialName.toLowerCase().includes(keyword));
    }

    return rows.filter((m) => {
      const g = grouped.get(m.materialId);
      if (tab === 'completed') return (g?.completedQty ?? 0) > 0;
      return true;
    });
  }, [materials, grouped, tab, search]);

  if (isLoading) {
    return <div className="flex items-center justify-center p-12"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div></div>;
  }

  return (
    <div className="space-y-6">
      <div><h1 className="text-2xl font-bold text-neutral-900">Quản lý thành phẩm</h1></div>

      <div className="card space-y-3">
        <div className="flex gap-2">
          <button className={`px-4 py-2 rounded-lg border ${tab === 'completed' ? 'bg-primary-600 text-white border-primary-600' : 'bg-white border-neutral-300'}`} onClick={() => setTab('completed')}>Thành phẩm đã hoàn thành</button>
          <button className={`px-4 py-2 rounded-lg border ${tab === 'target' ? 'bg-primary-600 text-white border-primary-600' : 'bg-white border-neutral-300'}`} onClick={() => setTab('target')}>Thành phẩm mong muốn</button>
        </div>
        <div className="relative"><Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" /><input value={search} onChange={(e) => setSearch(e.target.value)} className="input pl-9" placeholder="Tìm mã hoặc tên thành phẩm..." /></div>
      </div>

      <div className="card p-0 overflow-hidden">
        {filtered.length === 0 ? <div className="text-center py-12 text-neutral-500">Không có dữ liệu phù hợp</div> : (
          <div className="table-container">
            <table className="table">
              <thead><tr><th>Mã</th><th>Tên thành phẩm</th><th>Số lượng thành phẩm</th><th>Giấy kiểm nghiệm</th></tr></thead>
              <tbody>
                {filtered.map((m) => {
                  const g = grouped.get(m.materialId);
                  const qty = tab === 'completed' ? (g?.completedQty ?? 0) : (g?.targetQty ?? 2);
                  const unit = viUnit(g?.unit || m.baseUomName || 'đơn vị');
                  return (
                    <tr key={m.materialId}>
                      <td><code className="text-xs bg-neutral-100 px-2 py-1 rounded font-mono text-primary-600">{m.materialCode}</code></td>
                      <td className="font-medium text-neutral-900">{m.materialName}</td>
                      <td>{qty.toLocaleString()} {unit}</td>
                      <td><a className="text-primary-600 hover:underline inline-flex items-center" href={certificatesApi.getFinishedCertificateUrl(m.materialCode)} target="_blank" rel="noreferrer"><FileCheck2 className="w-4 h-4 mr-1" /> Xem</a></td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
