import { useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { certificatesApi, inventoryApi, materialsApi } from '@/services/api';
import { FileCheck2, Plus, Search } from 'lucide-react';
import FinishedGoodsStats from './FinishedGoodsStats';

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
  const [showAddModal, setShowAddModal] = useState(false);
  const [addForm, setAddForm] = useState({ materialCode: '', materialName: '' });

  const queryClient = useQueryClient();

  const { data: materialsRaw, isLoading } = useQuery({ queryKey: ['materials'], queryFn: () => materialsApi.getAll() });
  const { data: lotsRaw } = useQuery({ queryKey: ['inventoryLots'], queryFn: () => inventoryApi.getAll() });

  const addMaterialMutation = useMutation({
    mutationFn: () => materialsApi.create({ ...addForm, type: 'FinishedGood', baseUomId: 1, categoryId: 1 } as any),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['materials'] });
      setShowAddModal(false);
      setAddForm({ materialCode: '', materialName: '' });
    }
  });

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
      return (g?.completedQty ?? 0) === 0;
    });
  }, [materials, grouped, tab, search]);

  if (isLoading) {
    return <div className="flex items-center justify-center p-12"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div></div>;
  }

  return (
    <div className="space-y-6">
      <div><h1 className="text-2xl font-bold text-neutral-900">Quản lý thành phẩm</h1></div>

      <div className="card space-y-3">
        <div className="flex justify-between items-center">
          <div className="flex gap-2">
            <button className={`px-4 py-2 rounded-lg border ${tab === 'completed' ? 'bg-primary-600 text-white border-primary-600' : 'bg-white border-neutral-300'}`} onClick={() => setTab('completed')}>Thành phẩm đã hoàn thành</button>
            <button className={`px-4 py-2 rounded-lg border ${tab === 'target' ? 'bg-primary-600 text-white border-primary-600' : 'bg-white border-neutral-300'}`} onClick={() => setTab('target')}>Thành phẩm mong muốn</button>
          </div>
          {tab === 'target' && (
            <button className="btn-primary flex items-center" onClick={() => setShowAddModal(true)}>
              <Plus className="w-4 h-4 mr-1" /> Nhập thành phẩm đầu ra
            </button>
          )}
        </div>
        <div className="relative"><Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" /><input value={search} onChange={(e) => setSearch(e.target.value)} className="input pl-9" placeholder="Tìm mã hoặc tên thành phẩm..." /></div>
      </div>

      {tab === 'completed' && (
        <div className="card">
          <div className="[&>div>div:first-child]:hidden"><FinishedGoodsStats /></div>
        </div>
      )}

      <div className="card p-0 overflow-hidden">
        {filtered.length === 0 ? <div className="text-center py-12 text-neutral-500">Không có dữ liệu phù hợp</div> : (
          <div className="table-container">
            <table className="table">
              <thead>
                <tr>
                  <th>Mã</th>
                  <th>Tên thành phẩm</th>
                  {tab === 'completed' && <th>Số lượng thành phẩm</th>}
                  {tab === 'completed' && <th>Giấy kiểm nghiệm</th>}
                </tr>
              </thead>
              <tbody>
                {filtered.map((m) => {
                  const g = grouped.get(m.materialId);
                  const qty = tab === 'completed' ? (g?.completedQty ?? 0) : null;
                  const displayQty = qty !== null ? `${qty.toLocaleString()} ` : 'N/A';
                  const unit = displayQty !== 'N/A' ? viUnit(g?.unit || m.baseUomName || '') : '';
                  return (
                    <tr key={m.materialId}>
                      <td><code className="text-xs bg-neutral-100 px-2 py-1 rounded font-mono text-primary-600">{m.materialCode}</code></td>
                      <td className="font-medium text-neutral-900">{m.materialName}</td>
                      {tab === 'completed' && <td>{displayQty}{unit}</td>}
                      {tab === 'completed' && <td><a className="text-primary-600 hover:underline inline-flex items-center" href={certificatesApi.getFinishedCertificateUrl(m.materialCode)} target="_blank" rel="noreferrer"><FileCheck2 className="w-4 h-4 mr-1" /> Xem</a></td>}
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {showAddModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4" onClick={() => setShowAddModal(false)}>
          <div className="bg-white rounded-2xl w-full max-w-md p-6 space-y-4" onClick={(e) => e.stopPropagation()}>
            <h3 className="text-xl font-bold">Thêm thành phẩm mong muốn</h3>
            <div className="space-y-3">
              <div>
                <label className="text-xs text-neutral-500">Mã thành phẩm</label>
                <input className="input" value={addForm.materialCode} onChange={(e) => setAddForm({ ...addForm, materialCode: e.target.value })} placeholder="VD: TP-001" />
              </div>
              <div>
                <label className="text-xs text-neutral-500">Tên thành phẩm</label>
                <input className="input" value={addForm.materialName} onChange={(e) => setAddForm({ ...addForm, materialName: e.target.value })} placeholder="VD: Viên nén XYZ" />
              </div>
            </div>
            <div className="flex justify-end gap-2 mt-4">
              <button className="btn-ghost" onClick={() => setShowAddModal(false)}>Hủy</button>
              <button className="btn-primary" disabled={!addForm.materialCode || !addForm.materialName} onClick={() => addMaterialMutation.mutate()}>Xác nhận</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
