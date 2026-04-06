import { useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { certificatesApi, inventoryApi, materialsApi } from '@/services/api';
import type { Material } from '@/types';
import { Plus, Search, Package, FlaskConical, Eye, FileCheck2, Upload } from 'lucide-react';

type ViewTab = 'raw' | 'finished';

type UiMaterial = Material & {
  updatedAt?: string;
};

type UiLot = {
  lotId: number;
  materialId: number;
  lotNumber: string;
  quantityCurrent: number;
  manufactureDate?: string;
  expiryDate?: string;
  qcStatus?: string;
};

interface CreateLotFormState {
  materialCode: string;
  materialName: string;
  type: Material['type'];
  baseUomId: number;
  description: string;
  lotNumber: string;
  quantityCurrent: number;
  manufactureDate: string;
  expiryDate: string;
}

function normalizeMaterial(raw: any): UiMaterial {
  return {
    materialId: Number(raw.materialId ?? raw.MaterialId ?? 0),
    materialCode: raw.materialCode ?? raw.MaterialCode ?? '-',
    materialName: raw.materialName ?? raw.MaterialName ?? '-',
    type: (raw.type ?? raw.Type ?? 'RawMaterial') as Material['type'],
    baseUomId: Number(raw.baseUomId ?? raw.BaseUomId ?? 0),
    baseUomName: raw.baseUomName ?? raw.BaseUomName ?? raw.baseUom?.uomName ?? raw.BaseUom?.UomName ?? '-',
    isActive: Boolean(raw.isActive ?? raw.IsActive),
    description: raw.description ?? raw.Description,
    createdAt: raw.createdAt ?? raw.CreatedAt ?? '',
    updatedAt: raw.updatedAt ?? raw.UpdatedAt,
  };
}

function normalizeLot(raw: any): UiLot {
  return {
    lotId: Number(raw.lotId ?? raw.LotId ?? 0),
    materialId: Number(raw.materialId ?? raw.MaterialId ?? 0),
    lotNumber: raw.lotNumber ?? raw.LotNumber ?? '-',
    quantityCurrent: Number(raw.quantityCurrent ?? raw.QuantityCurrent ?? 0),
    manufactureDate: raw.manufactureDate ?? raw.ManufactureDate,
    expiryDate: raw.expiryDate ?? raw.ExpiryDate,
    qcStatus: raw.qcStatus ?? raw.QCStatus ?? raw.Qcstatus,
  };
}

export default function Materials() {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [activeTab, setActiveTab] = useState<ViewTab>('raw');
  const [showModal, setShowModal] = useState(false);
  const [detailMaterial, setDetailMaterial] = useState<UiMaterial | null>(null);
  const [certificateFile, setCertificateFile] = useState<File | null>(null);

  const [createLotForm, setCreateLotForm] = useState<CreateLotFormState>({
    materialCode: '',
    materialName: '',
    type: 'RawMaterial',
    baseUomId: 1,
    description: '',
    lotNumber: '',
    quantityCurrent: 0,
    manufactureDate: '',
    expiryDate: '',
  });

  const { data: materialsRaw, isLoading } = useQuery({
    queryKey: ['materials'],
    queryFn: () => materialsApi.getAll(),
  });

  const { data: lotsRaw } = useQuery({
    queryKey: ['inventoryLots'],
    queryFn: () => inventoryApi.getAll(),
  });

  const materials = useMemo<UiMaterial[]>(() => {
    const rows = Array.isArray(materialsRaw) ? materialsRaw : (materialsRaw as any)?.data ?? [];
    return (rows as any[]).map(normalizeMaterial);
  }, [materialsRaw]);

  const lots = useMemo<UiLot[]>(() => {
    const rows = Array.isArray(lotsRaw) ? lotsRaw : (lotsRaw as any)?.data ?? [];
    return (rows as any[]).map(normalizeLot);
  }, [lotsRaw]);

  const createLotMutation = useMutation({
    mutationFn: async () => {
      const code = createLotForm.materialCode.trim();
      const name = createLotForm.materialName.trim();
      const lot = createLotForm.lotNumber.trim();

      if (!code || !name || !lot) {
        throw new Error('Vui lòng nhập đủ mã nguyên liệu, tên nguyên liệu và mã lô.');
      }

      let materialId = materials.find((m) => m.materialCode.toLowerCase() === code.toLowerCase())?.materialId;

      if (!materialId) {
        const created: any = await materialsApi.create({
          materialCode: code,
          materialName: name,
          type: createLotForm.type,
          baseUomId: createLotForm.baseUomId,
          description: createLotForm.description,
          isActive: true,
        });
        materialId = Number(created?.data?.materialId ?? created?.data?.MaterialId ?? created?.materialId ?? 0);
      }

      if (!materialId) {
        throw new Error('Không tạo được nguyên liệu.');
      }

      await inventoryApi.receive({
        materialId,
        lotNumber: lot,
        quantityCurrent: createLotForm.quantityCurrent,
        manufactureDate: createLotForm.manufactureDate || undefined,
        expiryDate: createLotForm.expiryDate || undefined,
        qcstatus: 'Pending',
      });

      if (certificateFile) {
        await certificatesApi.uploadMaterialCertificate(code, certificateFile);
      }
    },
    onSuccess: async () => {
      await Promise.all([
        queryClient.invalidateQueries({ queryKey: ['materials'] }),
        queryClient.invalidateQueries({ queryKey: ['inventoryLots'] }),
      ]);
      setShowModal(false);
      setCertificateFile(null);
      setCreateLotForm({
        materialCode: '',
        materialName: '',
        type: 'RawMaterial',
        baseUomId: 1,
        description: '',
        lotNumber: '',
        quantityCurrent: 0,
        manufactureDate: '',
        expiryDate: '',
      });
      alert('Đã thêm lô nguyên liệu và giấy kiểm nghiệm thành công.');
    },
    onError: (err: any) => {
      alert(err?.message ?? 'Không thể thêm lô nguyên liệu.');
    },
  });

  const getMaterialLots = (materialId: number) => lots.filter((l) => l.materialId === materialId);

  const filtered = useMemo(() => {
    const keyword = search.trim().toLowerCase();
    const pool = materials.filter((m) => {
      if (activeTab === 'raw') return m.type === 'RawMaterial' || m.type === 'Packaging' || m.type === 'Intermediate';
      return m.type === 'FinishedGood';
    });

    if (!keyword) return pool;
    return pool.filter((m) => {
      const code = m.materialCode?.toLowerCase() || '';
      const name = m.materialName?.toLowerCase() || '';
      return code.includes(keyword) || name.includes(keyword);
    });
  }, [materials, activeTab, search]);

  const openCreateModal = () => {
    setCreateLotForm((prev) => ({ ...prev, type: activeTab === 'raw' ? 'RawMaterial' : 'FinishedGood' }));
    setCertificateFile(null);
    setShowModal(true);
  };

  const formatDate = (value?: string) => {
    if (!value) return '-';
    try {
      return new Date(value).toLocaleDateString('vi-VN');
    } catch {
      return '-';
    }
  };

  const finishedCertUrl = (materialCode: string) => `/certificates/${encodeURIComponent(materialCode)}.jpg`;
  const rawCertUrl = (materialCode: string) => certificatesApi.getMaterialCertificateUrl(materialCode);

  if (isLoading) {
    return (
      <div className="flex items-center justify-center p-12">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-neutral-900">Quản lý nguyên liệu và thành phẩm</h1>
        <button onClick={openCreateModal} className="btn-primary flex items-center">
          <Plus className="w-4 h-4 mr-2" />Thêm mới
        </button>
      </div>

      <div className="card space-y-4">
        <div className="flex gap-2">
          <button
            className={`px-4 py-2 rounded-lg text-sm font-medium border ${activeTab === 'raw' ? 'bg-primary-50 border-primary-300 text-primary-700' : 'bg-white border-neutral-200 text-neutral-600'}`}
            onClick={() => setActiveTab('raw')}
          >
            Nguyên liệu
          </button>
          <button
            className={`px-4 py-2 rounded-lg text-sm font-medium border ${activeTab === 'finished' ? 'bg-primary-50 border-primary-300 text-primary-700' : 'bg-white border-neutral-200 text-neutral-600'}`}
            onClick={() => setActiveTab('finished')}
          >
            Thành phẩm
          </button>
        </div>

        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="input pl-9"
            placeholder={activeTab === 'raw' ? 'Tìm mã hoặc tên nguyên liệu...' : 'Tìm mã hoặc tên thành phẩm...'}
          />
        </div>
      </div>

      <div className="card p-0 overflow-hidden">
        {filtered.length === 0 ? (
          <div className="text-center py-12 text-neutral-500">Không có dữ liệu phù hợp</div>
        ) : activeTab === 'raw' ? (
          <div className="table-container">
            <table className="table">
              <thead>
                <tr>
                  <th>Mã</th>
                  <th>Tên nguyên liệu</th>
                  <th>Số đợt nhập</th>
                  <th>Tổng số lượng tồn</th>
                  <th>Giấy kiểm nghiệm</th>
                  <th className="text-right">Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((m) => {
                  const materialLots = getMaterialLots(m.materialId);
                  const totalQty = materialLots.reduce((sum, lot) => sum + lot.quantityCurrent, 0);
                  return (
                    <tr key={m.materialId}>
                      <td><code className="text-xs bg-neutral-100 px-2 py-1 rounded font-mono text-primary-600">{m.materialCode}</code></td>
                      <td className="font-medium text-neutral-900">{m.materialName}</td>
                      <td>{materialLots.length}</td>
                      <td>{totalQty.toLocaleString()} {m.baseUomName || ''}</td>
                      <td>
                        <a className="text-primary-600 hover:underline inline-flex items-center" href={rawCertUrl(m.materialCode)} target="_blank" rel="noreferrer">
                          <FileCheck2 className="w-4 h-4 mr-1" /> Xem
                        </a>
                      </td>
                      <td className="text-right">
                        <button className="btn-ghost text-sm" onClick={() => setDetailMaterial(m)}>
                          <Eye className="w-4 h-4 mr-1" /> Xem chi tiết
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="table-container">
            <table className="table">
              <thead>
                <tr>
                  <th>Mã</th>
                  <th>Tên thành phẩm</th>
                  <th>Số lượng tồn</th>
                  <th>Đóng gói</th>
                  <th>Giấy kiểm nghiệm</th>
                  <th className="text-right">Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((m) => {
                  const productLots = getMaterialLots(m.materialId);
                  const totalQty = productLots.reduce((sum, lot) => sum + lot.quantityCurrent, 0);
                  return (
                    <tr key={m.materialId}>
                      <td><code className="text-xs bg-neutral-100 px-2 py-1 rounded font-mono text-primary-600">{m.materialCode}</code></td>
                      <td className="font-medium text-neutral-900">{m.materialName}</td>
                      <td>{totalQty.toLocaleString()} {m.baseUomName || ''}</td>
                      <td>{m.baseUomName === 'Box' ? 'Theo thùng/hộp' : `Theo ${m.baseUomName || 'quy cách chuẩn'}`}</td>
                      <td>
                        <a className="text-primary-600 hover:underline inline-flex items-center" href={finishedCertUrl(m.materialCode)} target="_blank" rel="noreferrer">
                          <FileCheck2 className="w-4 h-4 mr-1" /> Xem
                        </a>
                      </td>
                      <td className="text-right">
                        <button className="btn-ghost text-sm" onClick={() => setDetailMaterial(m)}>
                          <Eye className="w-4 h-4 mr-1" /> Xem chi tiết
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {showModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl w-full max-w-2xl p-6 space-y-4">
            <h2 className="text-2xl font-bold text-neutral-900">Thêm lô nguyên liệu mới</h2>
            <p className="text-sm text-neutral-500">Mỗi lần thêm lô, bạn có thể tải lên giấy kiểm nghiệm chất lượng của lô đó.</p>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <input className="input" required placeholder="Mã nguyên liệu" value={createLotForm.materialCode} onChange={(e) => setCreateLotForm({ ...createLotForm, materialCode: e.target.value })} />
              <input className="input" required placeholder="Tên nguyên liệu" value={createLotForm.materialName} onChange={(e) => setCreateLotForm({ ...createLotForm, materialName: e.target.value })} />
              <select className="input" value={createLotForm.type} onChange={(e) => setCreateLotForm({ ...createLotForm, type: e.target.value as Material['type'] })}>
                <option value="RawMaterial">Nguyên liệu</option>
                <option value="Packaging">Bao bì</option>
                <option value="Intermediate">Bán thành phẩm</option>
                <option value="FinishedGood">Thành phẩm</option>
              </select>
              <select className="input" value={createLotForm.baseUomId} onChange={(e) => setCreateLotForm({ ...createLotForm, baseUomId: Number(e.target.value) })}>
                <option value={1}>kg</option>
                <option value={2}>g</option>
                <option value={3}>viên</option>
                <option value={4}>lít</option>
              </select>
              <input className="input" required placeholder="Mã lô" value={createLotForm.lotNumber} onChange={(e) => setCreateLotForm({ ...createLotForm, lotNumber: e.target.value })} />
              <input type="number" className="input" required placeholder="Số lượng lô" value={createLotForm.quantityCurrent} onChange={(e) => setCreateLotForm({ ...createLotForm, quantityCurrent: Number(e.target.value) })} />
              <div>
                <label className="text-xs text-neutral-500">Ngày sản xuất</label>
                <input type="date" className="input" value={createLotForm.manufactureDate} onChange={(e) => setCreateLotForm({ ...createLotForm, manufactureDate: e.target.value })} />
              </div>
              <div>
                <label className="text-xs text-neutral-500">Hạn dùng</label>
                <input type="date" className="input" value={createLotForm.expiryDate} onChange={(e) => setCreateLotForm({ ...createLotForm, expiryDate: e.target.value })} />
              </div>
            </div>
            <textarea className="input" rows={3} placeholder="Mô tả" value={createLotForm.description} onChange={(e) => setCreateLotForm({ ...createLotForm, description: e.target.value })} />

            <div className="rounded-lg border border-dashed border-neutral-300 p-4">
              <label className="text-sm font-medium text-neutral-700 flex items-center mb-2">
                <Upload className="w-4 h-4 mr-2" />
                Tải giấy kiểm nghiệm chất lượng
              </label>
              <input
                type="file"
                accept=".jpg,.jpeg,.png,.webp"
                onChange={(e) => setCertificateFile(e.target.files?.[0] ?? null)}
              />
              <p className="text-xs text-neutral-500 mt-2">Ảnh sẽ lưu tại thư mục `PharmaceuticalProcessingManagementSystem/certificates` và đặt tên theo mã nguyên liệu.</p>
            </div>

            <div className="flex justify-end gap-2">
              <button className="btn-ghost" onClick={() => setShowModal(false)}>Hủy</button>
              <button className="btn-primary" onClick={() => createLotMutation.mutate()} disabled={createLotMutation.isPending}>Lưu</button>
            </div>
          </div>
        </div>
      )}

      {detailMaterial && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl w-full max-w-3xl p-6 space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-xl font-bold">Chi tiết: {detailMaterial.materialName}</h3>
              <button className="btn-ghost" onClick={() => setDetailMaterial(null)}>Đóng</button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-3 text-sm">
              <div className="p-3 rounded-lg bg-neutral-50 border border-neutral-200">
                <p className="text-neutral-500">Mã</p>
                <p className="font-semibold text-neutral-900">{detailMaterial.materialCode}</p>
              </div>
              <div className="p-3 rounded-lg bg-neutral-50 border border-neutral-200">
                <p className="text-neutral-500">Đơn vị</p>
                <p className="font-semibold text-neutral-900">{detailMaterial.baseUomName || '-'}</p>
              </div>
              <div className="p-3 rounded-lg bg-neutral-50 border border-neutral-200">
                <p className="text-neutral-500">Ngày tạo</p>
                <p className="font-semibold text-neutral-900">{formatDate(detailMaterial.createdAt)}</p>
              </div>
            </div>

            <div className="rounded-xl border border-neutral-200 overflow-hidden">
              <div className="px-4 py-3 bg-neutral-50 border-b border-neutral-200 font-semibold text-neutral-800 flex items-center">
                {detailMaterial.type === 'FinishedGood' ? <Package className="w-4 h-4 mr-2" /> : <FlaskConical className="w-4 h-4 mr-2" />}
                Số lượng theo từng đợt
              </div>
              <div className="table-container">
                <table className="table">
                  <thead>
                    <tr>
                      <th>Mã đợt</th>
                      <th>Số lượng</th>
                      <th>Ngày sản xuất</th>
                      <th>Hạn dùng</th>
                      <th>QC</th>
                    </tr>
                  </thead>
                  <tbody>
                    {getMaterialLots(detailMaterial.materialId).length === 0 ? (
                      <tr>
                        <td colSpan={5} className="text-center text-neutral-500 py-4">Chưa có dữ liệu đợt nhập/xuất</td>
                      </tr>
                    ) : (
                      getMaterialLots(detailMaterial.materialId).map((lot) => (
                        <tr key={lot.lotId}>
                          <td>{lot.lotNumber}</td>
                          <td>{lot.quantityCurrent.toLocaleString()} {detailMaterial.baseUomName || ''}</td>
                          <td>{formatDate(lot.manufactureDate)}</td>
                          <td>{formatDate(lot.expiryDate)}</td>
                          <td>{lot.qcStatus || '-'}</td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

