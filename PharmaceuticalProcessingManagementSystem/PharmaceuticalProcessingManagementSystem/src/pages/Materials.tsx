import { useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { certificatesApi, inventoryApi, materialsApi } from '@/services/api';
import { Plus, Search, Eye, FileCheck2, Upload, Pencil, Trash2 } from 'lucide-react';

interface CreateMaterialLotForm {
  materialCode: string;
  materialName: string;
  baseUomId: number;
  quantityCurrent: number;
  manufactureDate: string;
  expiryDate: string;
}

interface EditLotForm {
  lotId: number;
  lotNumber: string;
  quantityCurrent: number;
  manufactureDate: string;
  expiryDate: string;
  qcstatus: string;
}

function normalizeMaterial(raw: any) {
  return {
    materialId: Number(raw.materialId ?? raw.MaterialId ?? 0),
    materialCode: raw.materialCode ?? raw.MaterialCode ?? '-',
    materialName: raw.materialName ?? raw.MaterialName ?? '-',
    type: raw.type ?? raw.Type ?? 'RawMaterial',
    baseUomName: raw.baseUomName ?? raw.BaseUomName ?? raw.baseUom?.uomName ?? raw.BaseUom?.UomName ?? '-',
  };
}

function normalizeLot(raw: any) {
  return {
    lotId: Number(raw.lotId ?? raw.LotId ?? 0),
    materialId: Number(raw.materialId ?? raw.MaterialId ?? 0),
    lotNumber: raw.lotNumber ?? raw.LotNumber ?? '-',
    quantityCurrent: Number(raw.quantityCurrent ?? raw.QuantityCurrent ?? 0),
    manufactureDate: raw.manufactureDate ?? raw.ManufactureDate,
    expiryDate: raw.expiryDate ?? raw.ExpiryDate,
    qcStatus: raw.qcStatus ?? raw.QCStatus ?? raw.Qcstatus ?? '-',
  };
}

function buildAutoLotNumber(materialCode: string) {
  const now = new Date();
  const yy = String(now.getFullYear()).slice(-2);
  const mm = String(now.getMonth() + 1).padStart(2, '0');
  const dd = String(now.getDate()).padStart(2, '0');
  const hh = String(now.getHours()).padStart(2, '0');
  const mi = String(now.getMinutes()).padStart(2, '0');
  return `${materialCode.toUpperCase()}-${yy}${mm}${dd}-${hh}${mi}`;
}

function formatDateDDMMYYYY(value?: string) {
  if (!value) return '-';
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return '-';
  const dd = String(d.getDate()).padStart(2, '0');
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  const yyyy = d.getFullYear();
  return `${dd}/${mm}/${yyyy}`;
}

function toInputDate(value?: string) {
  if (!value) return '';
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return '';
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  const dd = String(d.getDate()).padStart(2, '0');
  return `${d.getFullYear()}-${mm}-${dd}`;
}

function validateLotDates(manufactureDate: string, expiryDate: string) {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  if (!manufactureDate || !expiryDate) {
    return 'Vui lòng nhập đầy đủ ngày sản xuất và hạn dùng.';
  }

  const mfg = new Date(manufactureDate);
  const exp = new Date(expiryDate);
  mfg.setHours(0, 0, 0, 0);
  exp.setHours(0, 0, 0, 0);

  if (mfg > today) {
    return 'Ngày sản xuất phải bằng hoặc trước ngày hiện tại của hệ thống.';
  }

  if (exp < today) {
    return 'Hạn sử dụng phải bằng hoặc sau ngày hiện tại của hệ thống.';
  }

  if (exp < mfg) {
    return 'Hạn sử dụng phải sau hoặc bằng ngày sản xuất.';
  }

  return null;
}

export default function Materials() {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [showImportModal, setShowImportModal] = useState(false);
  const [importMaterialId, setImportMaterialId] = useState(0);
  const [importForm, setImportForm] = useState({ quantityCurrent: 0, manufactureDate: new Date().toISOString().slice(0, 10), expiryDate: new Date(new Date().setFullYear(new Date().getFullYear() + 2)).toISOString().slice(0, 10) });
  const [importCertFile, setImportCertFile] = useState<File | null>(null);
  const [detailMaterial, setDetailMaterial] = useState<any | null>(null);
  const [certificateFile, setCertificateFile] = useState<File | null>(null);
  const [editingLot, setEditingLot] = useState<EditLotForm | null>(null);

  const [form, setForm] = useState<CreateMaterialLotForm>({
    materialCode: '',
    materialName: '',
    baseUomId: 1,
    quantityCurrent: 100,
    manufactureDate: new Date().toISOString().slice(0, 10),
    expiryDate: new Date(new Date().setFullYear(new Date().getFullYear() + 2)).toISOString().slice(0, 10),
  });

  const { data: materialsRaw, isLoading } = useQuery({
    queryKey: ['materials'],
    queryFn: () => materialsApi.getAll(),
  });

  const { data: lotsRaw } = useQuery({
    queryKey: ['inventoryLots'],
    queryFn: () => inventoryApi.getAll(),
  });

  const materials = useMemo(() => {
    const rows = Array.isArray(materialsRaw) ? materialsRaw : (materialsRaw as any)?.data ?? [];
    return (rows as any[]).map(normalizeMaterial).filter((m) => m.type !== 'FinishedGood');
  }, [materialsRaw]);

  const lots = useMemo(() => {
    const rows = Array.isArray(lotsRaw) ? lotsRaw : (lotsRaw as any)?.data ?? [];
    return (rows as any[]).map(normalizeLot);
  }, [lotsRaw]);

  const filtered = useMemo(() => {
    const keyword = search.trim().toLowerCase();
    if (!keyword) return materials;
    return materials.filter((m) => m.materialCode.toLowerCase().includes(keyword) || m.materialName.toLowerCase().includes(keyword));
  }, [materials, search]);

  const refreshLists = async () => {
    await Promise.all([
      queryClient.invalidateQueries({ queryKey: ['materials'] }),
      queryClient.invalidateQueries({ queryKey: ['inventoryLots'] }),
    ]);
  };

  const importMutation = useMutation({
    mutationFn: async () => {
      const mat = materials.find((m) => m.materialId === importMaterialId);
      if (!mat) throw new Error('Vui lòng chọn nguyên liệu.');
      if (importForm.quantityCurrent <= 0) throw new Error('Số lượng phải lớn hơn 0.');
      const dateError = validateLotDates(importForm.manufactureDate, importForm.expiryDate);
      if (dateError) throw new Error(dateError);

      await inventoryApi.receive({
        materialId: importMaterialId,
        lotNumber: buildAutoLotNumber(mat.materialCode),
        quantityCurrent: importForm.quantityCurrent,
        manufactureDate: importForm.manufactureDate,
        expiryDate: importForm.expiryDate,
        qcstatus: 'Pending',
      } as any);

      if (importCertFile) {
        await certificatesApi.uploadMaterialCertificate(mat.materialCode, importCertFile);
      }
    },
    onSuccess: async () => {
      await refreshLists();
      setShowImportModal(false);
      setImportCertFile(null);
      setImportForm({ quantityCurrent: 0, manufactureDate: new Date().toISOString().slice(0, 10), expiryDate: new Date(new Date().setFullYear(new Date().getFullYear() + 2)).toISOString().slice(0, 10) });
      alert('Đã nhập nguyên liệu thành công.');
    },
    onError: (err: any) => alert(err?.response?.data?.message ?? err?.message ?? 'Không thể nhập nguyên liệu.'),
  });

  const createMutation = useMutation({
    mutationFn: async () => {
      const code = form.materialCode.trim();
      const name = form.materialName.trim();
      if (!code || !name) {
        throw new Error('Vui lòng nhập mã và tên nguyên liệu.');
      }

      if (form.quantityCurrent <= 0) {
        throw new Error('Số lượng phải lớn hơn 0.');
      }

      const dateError = validateLotDates(form.manufactureDate, form.expiryDate);
      if (dateError) {
        throw new Error(dateError);
      }

      let materialId = materials.find((m) => m.materialCode.toLowerCase() === code.toLowerCase())?.materialId;
      if (!materialId) {
        const created: any = await materialsApi.create({
          materialCode: code,
          materialName: name,
          type: 'RawMaterial',
          baseUomId: form.baseUomId,
          isActive: true,
        });
        materialId = Number(created?.data?.materialId ?? created?.data?.MaterialId ?? created?.materialId ?? 0);
      }

      if (!materialId) {
        throw new Error('Không tạo được nguyên liệu.');
      }

      await inventoryApi.receive({
        materialId,
        lotNumber: buildAutoLotNumber(code),
        quantityCurrent: form.quantityCurrent,
        manufactureDate: form.manufactureDate,
        expiryDate: form.expiryDate,
        qcstatus: 'Pending',
      } as any);

      if (certificateFile) {
        await certificatesApi.uploadMaterialCertificate(code, certificateFile);
      }
    },
    onSuccess: async () => {
      await refreshLists();
      setShowModal(false);
      setCertificateFile(null);
      setForm({
        materialCode: '',
        materialName: '',
        baseUomId: 1,
        quantityCurrent: 100,
        manufactureDate: new Date().toISOString().slice(0, 10),
        expiryDate: new Date(new Date().setFullYear(new Date().getFullYear() + 2)).toISOString().slice(0, 10),
      });
      alert('Đã thêm nguyên liệu và đợt nhập thành công.');
    },
    onError: (err: any) => {
      alert(err?.response?.data?.message ?? err?.message ?? 'Không thể thêm nguyên liệu.');
    },
  });

  const deleteMaterialMutation = useMutation({
    mutationFn: (materialId: number) => materialsApi.delete(materialId),
    onSuccess: async () => {
      await refreshLists();
      setDetailMaterial(null);
      alert('Đã xóa nguyên liệu.');
    },
    onError: (err: any) => {
      alert(err?.response?.data?.message ?? err?.message ?? 'Không thể xóa nguyên liệu.');
    },
  });

  const updateLotMutation = useMutation({
    mutationFn: (payload: EditLotForm) => {
      const dateError = validateLotDates(payload.manufactureDate, payload.expiryDate);
      if (dateError) {
        throw new Error(dateError);
      }
      if (payload.quantityCurrent <= 0) {
        throw new Error('Số lượng phải lớn hơn 0.');
      }

      return inventoryApi.updateLot(payload.lotId, {
        lotNumber: payload.lotNumber,
        quantityCurrent: payload.quantityCurrent,
        manufactureDate: payload.manufactureDate,
        expiryDate: payload.expiryDate,
        qcstatus: payload.qcstatus,
      });
    },
    onSuccess: async () => {
      await refreshLists();
      setEditingLot(null);
      alert('Đã cập nhật lô nguyên liệu.');
    },
    onError: (err: any) => {
      alert(err?.response?.data?.message ?? err?.message ?? 'Không thể cập nhật lô nguyên liệu.');
    },
  });

  const deleteLotMutation = useMutation({
    mutationFn: (lotId: number) => inventoryApi.deleteLot(lotId),
    onSuccess: async () => {
      await refreshLists();
      alert('Đã xóa lô nguyên liệu.');
    },
    onError: (err: any) => {
      alert(err?.response?.data?.message ?? err?.message ?? 'Không thể xóa lô nguyên liệu.');
    },
  });

  const getMaterialLots = (materialId: number) => lots.filter((l) => l.materialId === materialId);

  if (isLoading) {
    return (
      <div className="flex items-center justify-center p-12">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
      </div>
    );
  }

  const todayInput = new Date().toISOString().slice(0, 10);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-neutral-900">Quản lý nguyên liệu</h1>
        <div className="flex items-center gap-2">
          <button onClick={() => { setImportMaterialId(0); setShowImportModal(true); }} className="btn-secondary flex items-center">
            <Plus className="w-4 h-4 mr-2" />Nhập nguyên liệu
          </button>
          <button onClick={() => setShowModal(true)} className="btn-primary flex items-center">
            <Plus className="w-4 h-4 mr-2" />Thêm nguyên liệu mới
          </button>
        </div>
      </div>

      <div className="card">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
          <input value={search} onChange={(e) => setSearch(e.target.value)} className="input pl-9" placeholder="Tìm mã hoặc tên nguyên liệu..." />
        </div>
      </div>

      <div className="card p-0 overflow-hidden">
        {filtered.length === 0 ? (
          <div className="text-center py-12 text-neutral-500">Không có dữ liệu phù hợp</div>
        ) : (
          <div className="table-container">
            <table className="table">
              <thead>
                <tr>
                  <th>Mã</th>
                  <th>Tên nguyên liệu</th>
                  <th>Số đợt nhập</th>
                  <th>Giấy kiểm nghiệm</th>
                  <th className="text-right">Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((m) => {
                  const materialLots = getMaterialLots(m.materialId);
                  return (
                    <tr key={m.materialId}>
                      <td><code className="text-xs bg-neutral-100 px-2 py-1 rounded font-mono text-primary-600">{m.materialCode}</code></td>
                      <td className="font-medium text-neutral-900">{m.materialName}</td>
                      <td>{materialLots.length}</td>
                      <td>
                        <a className="text-primary-600 hover:underline inline-flex items-center" href={certificatesApi.getMaterialCertificateUrl(m.materialCode)} target="_blank" rel="noreferrer">
                          <FileCheck2 className="w-4 h-4 mr-1" /> Xem
                        </a>
                      </td>
                      <td className="text-right">
                        <div className="flex justify-end gap-2">
                          <button className="btn-ghost text-sm" onClick={() => setDetailMaterial(m)}>
                            <Eye className="w-4 h-4 mr-1" /> Xem chi tiết
                          </button>
                          <button
                            className="btn-ghost text-sm text-red-600"
                            onClick={() => {
                              if (confirm(`Bạn có chắc muốn xóa nguyên liệu ${m.materialCode}?`)) {
                                deleteMaterialMutation.mutate(m.materialId);
                              }
                            }}
                          >
                            <Trash2 className="w-4 h-4 mr-1" /> Xóa
                          </button>
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

      {showModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl w-full max-w-2xl p-6 space-y-4">
            <h2 className="text-2xl font-bold text-neutral-900">Thêm nguyên liệu mới</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <input className="input" required placeholder="Mã nguyên liệu" value={form.materialCode} onChange={(e) => setForm({ ...form, materialCode: e.target.value })} />
              <input className="input" required placeholder="Tên nguyên liệu" value={form.materialName} onChange={(e) => setForm({ ...form, materialName: e.target.value })} />
              <div>
                <label className="text-xs text-neutral-500">Số lượng nhập đợt đầu</label>
                <input type="number" min={0.0001} className="input" required value={form.quantityCurrent} onChange={(e) => setForm({ ...form, quantityCurrent: Number(e.target.value) })} />
              </div>
              <div>
                <label className="text-xs text-neutral-500">Đơn vị tính</label>
                <select className="input" value={form.baseUomId} onChange={(e) => setForm({ ...form, baseUomId: Number(e.target.value) })}>
                  <option value={2}>g</option>
                  <option value={1}>kg</option>
                  <option value={3}>viên</option>
                  <option value={4}>lít</option>
                </select>
              </div>
              <div>
                <label className="text-xs text-neutral-500">Ngày sản xuất</label>
                <input type="date" max={todayInput} className="input" value={form.manufactureDate} onChange={(e) => setForm({ ...form, manufactureDate: e.target.value })} />
              </div>
              <div>
                <label className="text-xs text-neutral-500">Hạn dùng</label>
                <input type="date" min={todayInput} className="input" value={form.expiryDate} onChange={(e) => setForm({ ...form, expiryDate: e.target.value })} />
              </div>
            </div>

            <div className="rounded-lg border border-dashed border-neutral-300 p-4">
              <label className="text-sm font-medium text-neutral-700 flex items-center mb-2">
                <Upload className="w-4 h-4 mr-2" />
                Tải giấy kiểm nghiệm chất lượng
              </label>
              <input type="file" accept=".jpg,.jpeg,.png,.webp" onChange={(e) => setCertificateFile(e.target.files?.[0] ?? null)} />
            </div>

            <div className="flex justify-end gap-2">
              <button className="btn-ghost" onClick={() => setShowModal(false)}>Hủy</button>
              <button className="btn-primary" onClick={() => createMutation.mutate()} disabled={createMutation.isPending}>Lưu</button>
            </div>
          </div>
        </div>
      )}

      {showImportModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl w-full max-w-xl p-6 space-y-4">
            <h2 className="text-2xl font-bold text-neutral-900">Nhập nguyên liệu</h2>
            <p className="text-sm text-neutral-500">Thêm một đợt nhập mới cho nguyên liệu đã có trong hệ thống. Số đợt nhập sẽ tăng lên 1.</p>
            <div className="grid grid-cols-1 gap-4">
              <div>
                <label className="text-xs text-neutral-500">Chọn nguyên liệu</label>
                <select className="input" value={importMaterialId} onChange={(e) => setImportMaterialId(Number(e.target.value))}>
                  <option value={0}>Chọn nguyên liệu</option>
                  {materials.map((m) => <option key={m.materialId} value={m.materialId}>{m.materialCode} - {m.materialName}</option>)}
                </select>
              </div>
              <div>
                <label className="text-xs text-neutral-500">Số lượng nhập</label>
                <input type="number" min={0.0001} className="input" value={importForm.quantityCurrent} onChange={(e) => setImportForm({ ...importForm, quantityCurrent: Number(e.target.value) })} />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-xs text-neutral-500">Ngày sản xuất</label>
                  <input type="date" max={new Date().toISOString().slice(0,10)} className="input" value={importForm.manufactureDate} onChange={(e) => setImportForm({ ...importForm, manufactureDate: e.target.value })} />
                </div>
                <div>
                  <label className="text-xs text-neutral-500">Hạn dùng</label>
                  <input type="date" min={new Date().toISOString().slice(0,10)} className="input" value={importForm.expiryDate} onChange={(e) => setImportForm({ ...importForm, expiryDate: e.target.value })} />
                </div>
              </div>
            </div>
            <div className="rounded-lg border border-dashed border-neutral-300 p-4">
              <label className="text-sm font-medium text-neutral-700 flex items-center mb-2">
                <Upload className="w-4 h-4 mr-2" />Tải giấy kiểm nghiệm (tuỳ chọn)
              </label>
              <input type="file" accept=".jpg,.jpeg,.png,.webp" onChange={(e) => setImportCertFile(e.target.files?.[0] ?? null)} />
            </div>
            <div className="flex justify-end gap-2">
              <button className="btn-ghost" onClick={() => setShowImportModal(false)}>Hủy</button>
              <button className="btn-primary" onClick={() => importMutation.mutate()} disabled={importMutation.isPending}>Nhập</button>
            </div>
          </div>
        </div>
      )}

      {detailMaterial && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl w-full max-w-4xl p-6 space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-xl font-bold">Chi tiết: {detailMaterial.materialName}</h3>
              <button className="btn-ghost" onClick={() => setDetailMaterial(null)}>Đóng</button>
            </div>

            <div className="rounded-xl border border-neutral-200 overflow-hidden">
              <div className="px-4 py-3 bg-neutral-50 border-b border-neutral-200 font-semibold text-neutral-800">Số lượng theo từng đợt</div>
              <div className="table-container">
                <table className="table">
                  <thead>
                    <tr>
                      <th>Mã đợt</th>
                      <th>Số lượng</th>
                      <th>Ngày sản xuất</th>
                      <th>Hạn dùng</th>
                      <th>QC</th>
                      <th className="text-right">Thao tác</th>
                    </tr>
                  </thead>
                  <tbody>
                    {getMaterialLots(detailMaterial.materialId).length === 0 ? (
                      <tr>
                        <td colSpan={6} className="text-center text-neutral-500 py-4">Chưa có dữ liệu đợt nhập</td>
                      </tr>
                    ) : (
                      getMaterialLots(detailMaterial.materialId).map((lot) => (
                        <tr key={lot.lotId}>
                          <td>{lot.lotNumber}</td>
                          <td>{lot.quantityCurrent.toLocaleString()} {detailMaterial.baseUomName || ''}</td>
                          <td>{formatDateDDMMYYYY(lot.manufactureDate)}</td>
                          <td>{formatDateDDMMYYYY(lot.expiryDate)}</td>
                          <td>{lot.qcStatus || '-'}</td>
                          <td className="text-right">
                            <div className="flex justify-end gap-2">
                              <button
                                className="btn-ghost text-sm"
                                onClick={() => setEditingLot({
                                  lotId: lot.lotId,
                                  lotNumber: lot.lotNumber,
                                  quantityCurrent: lot.quantityCurrent,
                                  manufactureDate: toInputDate(lot.manufactureDate),
                                  expiryDate: toInputDate(lot.expiryDate),
                                  qcstatus: lot.qcStatus || 'Pending',
                                })}
                              >
                                <Pencil className="w-4 h-4 mr-1" /> Sửa
                              </button>
                              <button
                                className="btn-ghost text-sm text-red-600"
                                onClick={() => {
                                  if (confirm(`Bạn có chắc muốn xóa lô ${lot.lotNumber}?`)) {
                                    deleteLotMutation.mutate(lot.lotId);
                                  }
                                }}
                              >
                                <Trash2 className="w-4 h-4 mr-1" /> Xóa
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
        </div>
      )}

      {editingLot && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl w-full max-w-xl p-6 space-y-4">
            <h3 className="text-xl font-bold text-neutral-900">Cập nhật đợt nguyên liệu</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="md:col-span-2">
                <label className="text-xs text-neutral-500">Mã đợt</label>
                <input className="input" value={editingLot.lotNumber} disabled />
              </div>
              <div>
                <label className="text-xs text-neutral-500">Số lượng</label>
                <input
                  type="number"
                  min={0.0001}
                  className="input"
                  value={editingLot.quantityCurrent}
                  onChange={(e) => setEditingLot({ ...editingLot, quantityCurrent: Number(e.target.value) })}
                />
              </div>
              <div>
                <label className="text-xs text-neutral-500">Trạng thái QC</label>
                <select className="input" value={editingLot.qcstatus} onChange={(e) => setEditingLot({ ...editingLot, qcstatus: e.target.value })}>
                  <option value="Pending">Pending</option>
                  <option value="Approved">Approved</option>
                  <option value="Rejected">Rejected</option>
                </select>
              </div>
              <div>
                <label className="text-xs text-neutral-500">Ngày sản xuất</label>
                <input
                  type="date"
                  max={todayInput}
                  className="input"
                  value={editingLot.manufactureDate}
                  onChange={(e) => setEditingLot({ ...editingLot, manufactureDate: e.target.value })}
                />
              </div>
              <div>
                <label className="text-xs text-neutral-500">Hạn dùng</label>
                <input
                  type="date"
                  min={todayInput}
                  className="input"
                  value={editingLot.expiryDate}
                  onChange={(e) => setEditingLot({ ...editingLot, expiryDate: e.target.value })}
                />
              </div>
            </div>

            <div className="flex justify-end gap-2">
              <button className="btn-ghost" onClick={() => setEditingLot(null)}>Hủy</button>
              <button className="btn-primary" onClick={() => updateLotMutation.mutate(editingLot)} disabled={updateLotMutation.isPending}>Lưu thay đổi</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
