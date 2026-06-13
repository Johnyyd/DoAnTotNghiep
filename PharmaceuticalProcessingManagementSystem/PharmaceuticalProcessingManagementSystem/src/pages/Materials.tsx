import { useMemo, useState, type ReactNode } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { certificatesApi, inventoryApi, materialsApi } from '@/services/api';
import { Eye, FileCheck2, PackageCheck, Pencil, Plus, Search, ShieldCheck, Trash2, Upload } from 'lucide-react';
import { formatNumber } from '@/utils/format';
import { useAuth } from '@/context/AuthContext';

type QcStatus = 'PendingQC' | 'Sampling' | 'Released' | 'Rejected' | 'OnHold';
type MaterialType = 'RawMaterial' | 'Packaging' | 'FinishedGood';
type QuantityDisplayMode = 'auto' | 'large' | 'small';

interface MaterialForm {
  materialCode: string;
  materialName: string;
  type: MaterialType;
  baseUomId: number;
  physicalForm: string;
  technicalSpecification: string;
  storageCondition: string;
  minStorageTemperature: string;
  maxStorageTemperature: string;
  minStorageHumidity: string;
  maxStorageHumidity: string;
  minPh: string;
  maxPh: string;
  storageNotes: string;
  quantityCurrent: number;
  manufactureDate: string;
  expiryDate: string;
  supplierLotNumber: string;
  supplierName: string;
  containerType: string;
  containerCount: number;
  qcStatus: QcStatus;
  locationId: number;
}

interface LotForm {
  lotId: number;
  lotNumber: string;
  quantityCurrent: number;
  manufactureDate: string;
  expiryDate: string;
  supplierLotNumber: string;
  supplierName: string;
  containerType: string;
  containerCount: number;
  qcStatus: QcStatus;
  coaFilePath: string;
  rejectedReason: string;
  locationId: number;
}

const today = () => new Date().toISOString().slice(0, 10);

const physicalForms = ['Bột', 'Hạt', 'Lỏng', 'Gel', 'Viên', 'Vỏ nang', 'Bao bì', 'Bao bì thuỷ tinh', 'Cuộn màng', 'Khác'];
const containerTypes = ['Thùng carton', 'Thùng lót PE', 'Bao PE', 'Can nhựa', 'Chai', 'Tủ chuyên dụng', 'Cuộn trong thùng', 'Pallet', 'Khác'];
const qcStatuses: { value: QcStatus; label: string; className: string }[] = [
  { value: 'PendingQC', label: 'Chờ duyệt', className: 'bg-amber-100 text-amber-700' },
  { value: 'Sampling', label: 'Đang lấy mẫu', className: 'bg-blue-100 text-blue-700' },
  { value: 'Released', label: 'Đã duyệt', className: 'bg-green-100 text-green-700' },
  { value: 'Rejected', label: 'Không đạt', className: 'bg-red-100 text-red-700' },
  { value: 'OnHold', label: 'Tạm giữ', className: 'bg-neutral-200 text-neutral-700' },
];

function toRows(raw: any): any[] {
  return Array.isArray(raw) ? raw : raw?.data ?? [];
}

function numOrUndefined(value: string) {
  if (value === '') return undefined;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : undefined;
}

function normalizeMaterial(raw: any) {
  const baseUomId = Number(raw.baseUomId ?? raw.BaseUomId ?? 0);
  const fallbackById: Record<number, string> = { 1: 'kg', 2: 'g', 3: 'L', 4: 'Viên', 8: 'Cái', 9: 'mg', 10: 'ml' };
  return {
    materialId: Number(raw.materialId ?? raw.MaterialId ?? 0),
    materialCode: raw.materialCode ?? raw.MaterialCode ?? '-',
    materialName: raw.materialName ?? raw.MaterialName ?? '-',
    type: raw.type ?? raw.Type ?? 'RawMaterial',
    baseUomId,
    baseUomName: raw.baseUomName ?? raw.BaseUomName ?? raw.baseUom?.uomName ?? raw.BaseUom?.UomName ?? fallbackById[baseUomId] ?? '',
    technicalSpecification: raw.technicalSpecification ?? raw.TechnicalSpecification ?? '',
    physicalForm: raw.physicalForm ?? raw.PhysicalForm ?? '',
    storageCondition: raw.storageCondition ?? raw.StorageCondition ?? '',
    minStorageTemperature: raw.minStorageTemperature ?? raw.MinStorageTemperature,
    maxStorageTemperature: raw.maxStorageTemperature ?? raw.MaxStorageTemperature,
    minStorageHumidity: raw.minStorageHumidity ?? raw.MinStorageHumidity,
    maxStorageHumidity: raw.maxStorageHumidity ?? raw.MaxStorageHumidity,
    minPh: raw.minPh ?? raw.MinPh,
    maxPh: raw.maxPh ?? raw.MaxPh,
    storageNotes: raw.storageNotes ?? raw.StorageNotes ?? '',
  };
}

function normalizeLot(raw: any) {
  const location = raw.location ?? raw.Location;
  return {
    lotId: Number(raw.lotId ?? raw.LotId ?? 0),
    materialId: Number(raw.materialId ?? raw.MaterialId ?? 0),
    lotNumber: raw.lotNumber ?? raw.LotNumber ?? '-',
    quantityCurrent: Number(raw.quantityCurrent ?? raw.QuantityCurrent ?? 0),
    manufactureDate: raw.manufactureDate ?? raw.ManufactureDate,
    expiryDate: raw.expiryDate ?? raw.ExpiryDate,
    createdAt: raw.createdAt ?? raw.CreatedAt,
    supplierLotNumber: raw.supplierLotNumber ?? raw.SupplierLotNumber ?? '',
    supplierName: raw.supplierName ?? raw.SupplierName ?? '',
    containerType: raw.containerType ?? raw.ContainerType ?? '',
    containerCount: Number(raw.containerCount ?? raw.ContainerCount ?? 0),
    qcStatus: (raw.qcStatus ?? raw.QcStatus ?? 'PendingQC') as QcStatus,
    coaFilePath: raw.coaFilePath ?? raw.CoaFilePath ?? '',
    releasedAt: raw.releasedAt ?? raw.ReleasedAt,
    rejectedReason: raw.rejectedReason ?? raw.RejectedReason ?? '',
    locationId: Number(raw.locationId ?? raw.LocationId ?? 0),
    locationName: location?.locationName ?? location?.LocationName ?? '',
    locationCode: location?.locationCode ?? location?.LocationCode ?? '',
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

function formatDate(value?: string) {
  if (!value) return '-';
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return '-';
  return parsed.toLocaleDateString('vi-VN');
}

function toInputDate(value?: string) {
  if (!value) return '';
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return '';
  return parsed.toISOString().slice(0, 10);
}

function statusBadge(status: QcStatus) {
  const meta = qcStatuses.find((item) => item.value === status) ?? qcStatuses[0];
  return <span className={`inline-flex rounded-full px-2 py-1 text-xs font-semibold ${meta.className}`}>{meta.label}</span>;
}

function validateLotDates(manufactureDate: string, expiryDate: string) {
  if (!manufactureDate || !expiryDate) return 'Vui lòng nhập đầy đủ ngày sản xuất và hạn dùng.';
  const todayValue = new Date();
  todayValue.setHours(0, 0, 0, 0);
  const mfg = new Date(manufactureDate);
  const exp = new Date(expiryDate);
  mfg.setHours(0, 0, 0, 0);
  exp.setHours(0, 0, 0, 0);
  if (mfg > todayValue) return 'Ngày sản xuất không được sau ngày hiện tại.';
  if (exp <= todayValue) return 'Hạn dùng phải sau ngày hiện tại.';
  if (exp < mfg) return 'Hạn dùng phải sau hoặc bằng ngày sản xuất.';
  return null;
}

function makeDefaultForm(): MaterialForm {
  return {
    materialCode: '',
    materialName: '',
    type: 'RawMaterial',
    baseUomId: 1,
    physicalForm: '',
    technicalSpecification: '',
    storageCondition: '',
    minStorageTemperature: '',
    maxStorageTemperature: '',
    minStorageHumidity: '',
    maxStorageHumidity: '',
    minPh: '',
    maxPh: '',
    storageNotes: '',
    quantityCurrent: 0,
    manufactureDate: '',
    expiryDate: '',
    supplierLotNumber: '',
    supplierName: '',
    containerType: '',
    containerCount: 0,
    qcStatus: 'PendingQC',
    locationId: 0,
  };
}

export default function Materials() {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [showImportModal, setShowImportModal] = useState(false);
  const [importMaterialId, setImportMaterialId] = useState(0);
  const [detailMaterial, setDetailMaterial] = useState<any | null>(null);
  const [editingLot, setEditingLot] = useState<LotForm | null>(null);
  const [certificateFile, setCertificateFile] = useState<File | null>(null);
  const [importCertFile, setImportCertFile] = useState<File | null>(null);
  const [quantityDisplayMode, setQuantityDisplayMode] = useState<QuantityDisplayMode>('auto');
  const [form, setForm] = useState<MaterialForm>(makeDefaultForm());
  const [importForm, setImportForm] = useState<Omit<MaterialForm, 'materialCode' | 'materialName' | 'type' | 'baseUomId' | 'physicalForm' | 'technicalSpecification' | 'storageCondition' | 'minStorageTemperature' | 'maxStorageTemperature' | 'minStorageHumidity' | 'maxStorageHumidity' | 'minPh' | 'maxPh' | 'storageNotes'>>(makeDefaultForm());

  const { user } = useAuth();
  const isReadOnly = user?.role === 'QualityControl' || user?.role === 'QA_QC' || user?.role === 'WarehouseStaff';

  const { data: materialsRaw, isLoading } = useQuery({ queryKey: ['materials'], queryFn: () => materialsApi.getAll() });
  const { data: lotsRaw } = useQuery({ queryKey: ['inventoryLots'], queryFn: () => inventoryApi.getAll() });
  const { data: locationsRaw } = useQuery({ queryKey: ['storageLocations'], queryFn: () => inventoryApi.getStorageLocations() });

  const materials = useMemo(() => toRows(materialsRaw).map(normalizeMaterial).filter((m) => m.type !== 'FinishedGood'), [materialsRaw]);
  const lots = useMemo(() => toRows(lotsRaw).map(normalizeLot), [lotsRaw]);
  const locations = useMemo(() => toRows(locationsRaw), [locationsRaw]);

  const filtered = useMemo(() => {
    const keyword = search.trim().toLowerCase();
    if (!keyword) return materials;
    return materials.filter((m) =>
      `${m.materialCode} ${m.materialName} ${m.physicalForm} ${m.storageCondition}`.toLowerCase().includes(keyword)
    );
  }, [materials, search]);

  const selectedImportMaterial = useMemo(() => materials.find((m) => m.materialId === importMaterialId) ?? null, [materials, importMaterialId]);

  const refreshLists = async () => {
    await Promise.all([
      queryClient.invalidateQueries({ queryKey: ['materials'] }),
      queryClient.invalidateQueries({ queryKey: ['inventoryLots'] }),
      queryClient.invalidateQueries({ queryKey: ['storageLocations'] }),
    ]);
  };

  const buildMaterialPayload = (data: MaterialForm) => ({
    materialCode: data.materialCode.trim(),
    materialName: data.materialName.trim(),
    type: data.type,
    baseUomId: data.baseUomId,
    isActive: true,
    technicalSpecification: data.technicalSpecification,
    physicalForm: data.physicalForm,
    storageCondition: data.storageCondition,
    minStorageTemperature: numOrUndefined(data.minStorageTemperature),
    maxStorageTemperature: numOrUndefined(data.maxStorageTemperature),
    minStorageHumidity: numOrUndefined(data.minStorageHumidity),
    maxStorageHumidity: numOrUndefined(data.maxStorageHumidity),
    minPh: numOrUndefined(data.minPh),
    maxPh: numOrUndefined(data.maxPh),
    storageNotes: data.storageNotes,
  });

  const buildLotPayload = (materialId: number, materialCode: string, data: typeof importForm | MaterialForm) => ({
    materialId,
    lotNumber: buildAutoLotNumber(materialCode),
    quantityCurrent: data.quantityCurrent,
    manufactureDate: data.manufactureDate,
    expiryDate: data.expiryDate,
    supplierLotNumber: data.supplierLotNumber,
    supplierName: data.supplierName,
    containerType: data.containerType,
    containerCount: data.containerCount,
    qcStatus: data.qcStatus,
    locationId: data.locationId || null,
  });

  const createMutation = useMutation({
    mutationFn: async () => {
      if (!form.materialCode.trim() || !form.materialName.trim()) throw new Error('Vui lòng nhập mã và tên nguyên liệu.');
      if (form.quantityCurrent <= 0) throw new Error('Số lượng phải lớn hơn 0.');
      const dateError = validateLotDates(form.manufactureDate, form.expiryDate);
      if (dateError) throw new Error(dateError);

      const created: any = await materialsApi.create(buildMaterialPayload(form));
      const materialId = Number(created?.data?.materialId ?? created?.data?.MaterialId ?? created?.materialId ?? 0);
      if (!materialId) throw new Error('Không tạo được nguyên liệu.');

      await inventoryApi.receive(buildLotPayload(materialId, form.materialCode, form));
      if (certificateFile) await certificatesApi.uploadMaterialCertificate(form.materialCode, certificateFile);
    },
    onSuccess: async () => {
      await refreshLists();
      setShowModal(false);
      setCertificateFile(null);
      setForm(makeDefaultForm());
      alert('Đã thêm nguyên liệu và lô nhập kho.');
    },
    onError: (err: any) => alert(err?.response?.data?.message ?? err?.message ?? 'Không thể thêm nguyên liệu.'),
  });

  const importMutation = useMutation({
    mutationFn: async () => {
      const material = selectedImportMaterial;
      if (!material) throw new Error('Vui lòng chọn nguyên liệu.');
      if (importForm.quantityCurrent <= 0) throw new Error('Số lượng phải lớn hơn 0.');
      const dateError = validateLotDates(importForm.manufactureDate, importForm.expiryDate);
      if (dateError) throw new Error(dateError);

      await inventoryApi.receive(buildLotPayload(material.materialId, material.materialCode, importForm));
      if (importCertFile) await certificatesApi.uploadMaterialCertificate(material.materialCode, importCertFile);
    },
    onSuccess: async () => {
      await refreshLists();
      setShowImportModal(false);
      setImportMaterialId(0);
      setImportCertFile(null);
      setImportForm(makeDefaultForm());
      alert('Đã nhập thêm lô nguyên liệu.');
    },
    onError: (err: any) => alert(err?.response?.data?.message ?? err?.message ?? 'Không thể nhập nguyên liệu.'),
  });

  const updateLotMutation = useMutation({
    mutationFn: (payload: LotForm) => {
      const dateError = validateLotDates(payload.manufactureDate, payload.expiryDate);
      if (dateError) throw new Error(dateError);
      if (payload.quantityCurrent <= 0) throw new Error('Số lượng phải lớn hơn 0.');
      return inventoryApi.updateLot(payload.lotId, {
        lotNumber: payload.lotNumber,
        quantityCurrent: payload.quantityCurrent,
        manufactureDate: payload.manufactureDate,
        expiryDate: payload.expiryDate,
        supplierLotNumber: payload.supplierLotNumber,
        supplierName: payload.supplierName,
        containerType: payload.containerType,
        containerCount: payload.containerCount,
        qcStatus: payload.qcStatus,
        coaFilePath: payload.coaFilePath,
        rejectedReason: payload.rejectedReason,
        locationId: payload.locationId || null,
      });
    },
    onSuccess: async () => {
      await refreshLists();
      setEditingLot(null);
      alert('Đã cập nhật lô nguyên liệu.');
    },
    onError: (err: any) => alert(err?.response?.data?.message ?? err?.message ?? 'Không thể cập nhật lô.'),
  });

  const deleteMaterialMutation = useMutation({
    mutationFn: (materialId: number) => materialsApi.delete(materialId),
    onSuccess: async () => {
      await refreshLists();
      setDetailMaterial(null);
      alert('Đã xóa nguyên liệu.');
    },
    onError: (err: any) => alert(err?.response?.data?.message ?? err?.message ?? 'Không thể xóa nguyên liệu.'),
  });

  const deleteLotMutation = useMutation({
    mutationFn: (lotId: number) => inventoryApi.deleteLot(lotId),
    onSuccess: refreshLists,
    onError: (err: any) => alert(err?.response?.data?.message ?? err?.message ?? 'Không thể xóa lô.'),
  });

  const getMaterialLots = (materialId: number) => lots.filter((lot) => lot.materialId === materialId);
  const formatQty = (value: number, unit: string) => {
    const normalizedUnit = (unit || '').trim().toLowerCase();
    let displayValue = value;
    let displayUnit = unit;

    if (quantityDisplayMode === 'large') {
      if (normalizedUnit === 'g') {
        displayValue = value / 1000;
        displayUnit = 'kg';
      } else if (normalizedUnit === 'ml') {
        displayValue = value / 1000;
        displayUnit = 'L';
      }
    }

    if (quantityDisplayMode === 'small') {
      if (normalizedUnit === 'kg') {
        displayValue = value * 1000;
        displayUnit = 'g';
      } else if (normalizedUnit === 'l') {
        displayValue = value * 1000;
        displayUnit = 'ml';
      }
    }

    return `${formatNumber(displayValue, 4)} ${displayUnit}`;
  };
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  const tomorrowInput = tomorrow.toISOString().slice(0, 10);
  const expiryWarnings = useMemo(() => {
    const todayValue = new Date();
    todayValue.setHours(0, 0, 0, 0);
    const nearLimit = new Date(todayValue);
    nearLimit.setMonth(nearLimit.getMonth() + 2);
    const expired = lots.filter((lot) => lot.expiryDate && new Date(lot.expiryDate) < todayValue);
    const nearExpiry = lots.filter((lot) => {
      if (!lot.expiryDate) return false;
      const expiry = new Date(lot.expiryDate);
      return expiry >= todayValue && expiry <= nearLimit;
    });
    return { expired, nearExpiry };
  }, [lots]);

  if (isLoading) {
    return <div className="flex items-center justify-center p-12"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" /></div>;
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900">Quản lý nguyên liệu GMP</h1>
          <p className="text-sm text-neutral-500 mt-1">Theo dõi dạng nguyên liệu, điều kiện bảo quản, lô nhập, trạng thái duyệt và vị trí kho.</p>
        </div>
        <div className="flex items-center gap-2">
          {!isReadOnly && (
            <>
              <button onClick={() => setShowImportModal(true)} className="btn-secondary flex items-center"><Plus className="w-4 h-4 mr-2" />Nhập lô</button>
              <button onClick={() => setShowModal(true)} className="btn-primary flex items-center"><Plus className="w-4 h-4 mr-2" />Thêm nguyên liệu</button>
            </>
          )}
        </div>
      </div>

      <div className="card grid grid-cols-1 md:grid-cols-[1fr_220px] gap-3">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
          <input value={search} onChange={(e) => setSearch(e.target.value)} className="input pl-9" placeholder="Tìm mã, tên, dạng hoặc điều kiện bảo quản..." />
        </div>
        <select className="input" value={quantityDisplayMode} onChange={(e) => setQuantityDisplayMode(e.target.value as QuantityDisplayMode)}>
          <option value="auto">Đơn vị gốc</option>
          <option value="large">Hiển thị kg / L</option>
          <option value="small">Hiển thị g / ml</option>
        </select>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <div className="card"><PackageCheck className="w-5 h-5 text-primary-600 mb-2" /><p className="text-sm text-neutral-500">Tổng nguyên liệu</p><p className="text-2xl font-bold">{materials.length}</p></div>
        <div className="card"><ShieldCheck className="w-5 h-5 text-green-600 mb-2" /><p className="text-sm text-neutral-500">Lô đã duyệt</p><p className="text-2xl font-bold">{lots.filter((l) => l.qcStatus === 'Released').length}</p></div>
        <div className="card"><FileCheck2 className="w-5 h-5 text-amber-600 mb-2" /><p className="text-sm text-neutral-500">Lô chờ duyệt</p><p className="text-2xl font-bold">{lots.filter((l) => l.qcStatus !== 'Released').length}</p></div>
      </div>

      {(expiryWarnings.expired.length > 0 || expiryWarnings.nearExpiry.length > 0) && (
        <div className="rounded-xl border border-amber-200 bg-amber-50 p-4">
          <h3 className="font-semibold text-amber-900">Cảnh báo hạn dùng gửi QC</h3>
          <p className="text-sm text-amber-800 mt-1">
            Quá hạn: {expiryWarnings.expired.length} lô. Sắp hết hạn trong 2 tháng: {expiryWarnings.nearExpiry.length} lô.
          </p>
          <div className="mt-3 grid grid-cols-1 md:grid-cols-2 gap-2 text-sm">
            {[...expiryWarnings.expired, ...expiryWarnings.nearExpiry].slice(0, 8).map((lot) => {
              const material = materials.find((m) => m.materialId === lot.materialId);
              const isExpired = expiryWarnings.expired.some((item) => item.lotId === lot.lotId);
              return (
                <div key={lot.lotId} className="rounded-lg bg-white border border-amber-100 px-3 py-2">
                  <span className="font-semibold">{lot.lotNumber}</span> - {material?.materialName ?? 'Nguyên liệu'}:
                  <span className={isExpired ? ' text-red-600' : ' text-amber-700'}> {isExpired ? 'quá hạn' : 'sắp hết hạn'} {formatDate(lot.expiryDate)}</span>
                </div>
              );
            })}
          </div>
        </div>
      )}

      <div className="card p-0 overflow-hidden">
        <div className="table-container">
          <table className="table">
            <thead>
              <tr>
                <th>Mã</th>
                <th>Tên nguyên liệu</th>
                <th>Dạng</th>
                <th>Ghi chú</th>
                <th>Tồn kho</th>
                <th>Trạng thái lô</th>
                <th className="text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((material) => {
                const materialLots = getMaterialLots(material.materialId);
                const total = materialLots.reduce((sum, lot) => sum + lot.quantityCurrent, 0);
                return (
                  <tr key={material.materialId}>
                    <td><code className="text-xs bg-neutral-100 px-2 py-1 rounded font-mono text-primary-600">{material.materialCode}</code></td>
                    <td className="font-medium text-neutral-900">{material.materialName}</td>
                    <td>{material.physicalForm || '-'}</td>
                    <td className="max-w-xs text-sm text-neutral-600">{material.storageCondition || '-'}</td>
                    <td>{formatQty(total, material.baseUomName)}</td>
                    <td>{statusBadge(materialLots.every((lot) => lot.qcStatus === 'Released') && materialLots.length ? 'Released' : 'PendingQC')}</td>
                    <td className="text-right">
                      <div className="flex justify-end gap-2">
                        <button className="btn-ghost text-sm" onClick={() => setDetailMaterial(material)}><Eye className="w-4 h-4 mr-1" />Xem</button>
                        {!isReadOnly && (
                          <button className="btn-ghost text-sm text-red-600" onClick={() => confirm(`Xóa ${material.materialCode}?`) && deleteMaterialMutation.mutate(material.materialId)}><Trash2 className="w-4 h-4 mr-1" />Xóa</button>
                        )}
                      </div>
                    </td>
                  </tr>
                );
              })}
              {filtered.length === 0 && <tr><td colSpan={7} className="text-center text-neutral-500 py-8">Không có dữ liệu phù hợp.</td></tr>}
            </tbody>
          </table>
        </div>
      </div>

      {showModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4" onClick={() => setShowModal(false)}>
          <div className="bg-white rounded-2xl w-full max-w-7xl p-6 space-y-4 max-h-[92vh] overflow-y-auto" onClick={(e) => e.stopPropagation()}>
            <h2 className="text-2xl font-bold text-neutral-900">Thêm nguyên liệu mới</h2>
            <Section title="Thông tin danh mục">
              <Field label="Mã nguyên liệu"><input className="input" placeholder="Ví dụ: NLC-001" value={form.materialCode} onChange={(e) => setForm({ ...form, materialCode: e.target.value })} /></Field>
              <Field label="Tên nguyên liệu"><input className="input" placeholder="Nhập tên nguyên liệu" value={form.materialName} onChange={(e) => setForm({ ...form, materialName: e.target.value })} /></Field>
              <Field label="Loại nguyên liệu"><select className="input" value={form.type} onChange={(e) => setForm({ ...form, type: e.target.value as MaterialType })}>
                <option value="RawMaterial">Nguyên liệu</option>
                <option value="Packaging">Bao bì</option>
              </select></Field>
              <Field label="Dạng nguyên liệu"><select className="input" value={form.physicalForm} onChange={(e) => setForm({ ...form, physicalForm: e.target.value })}><option value="">Chọn dạng nguyên liệu</option>{physicalForms.map((item) => <option key={item}>{item}</option>)}</select></Field>
              <Field label="Đơn vị tính"><select className="input" value={form.baseUomId} onChange={(e) => setForm({ ...form, baseUomId: Number(e.target.value) })}>
                <option value={9}>mg</option><option value={2}>g</option><option value={1}>kg</option><option value={10}>ml</option><option value={3}>L</option><option value={4}>Viên</option><option value={8}>Cái</option>
              </select></Field>
              <Field label="Tiêu chuẩn kỹ thuật"><input className="input" placeholder="Ví dụ: USP/BP/EP hoặc tiêu chuẩn cơ sở" value={form.technicalSpecification} onChange={(e) => setForm({ ...form, technicalSpecification: e.target.value })} /></Field>
            </Section>
            <Section title="Tiêu chuẩn lưu trữ">
              <Field label="Điều kiện bảo quản" className="md:col-span-2"><input className="input" placeholder="Ví dụ: Bảo quản kín, khô, tránh ánh sáng" value={form.storageCondition} onChange={(e) => setForm({ ...form, storageCondition: e.target.value })} /></Field>
              <Field label="Nhiệt độ tối thiểu (°C)"><input className="input" type="number" placeholder="Nhập nhiệt độ min" value={form.minStorageTemperature} onChange={(e) => setForm({ ...form, minStorageTemperature: e.target.value })} /></Field>
              <Field label="Nhiệt độ tối đa (°C)"><input className="input" type="number" placeholder="Nhập nhiệt độ max" value={form.maxStorageTemperature} onChange={(e) => setForm({ ...form, maxStorageTemperature: e.target.value })} /></Field>
              <Field label="Độ ẩm tối thiểu (%)"><input className="input" type="number" placeholder="Nhập độ ẩm min" value={form.minStorageHumidity} onChange={(e) => setForm({ ...form, minStorageHumidity: e.target.value })} /></Field>
              <Field label="Độ ẩm tối đa (%)"><input className="input" type="number" placeholder="Nhập độ ẩm max" value={form.maxStorageHumidity} onChange={(e) => setForm({ ...form, maxStorageHumidity: e.target.value })} /></Field>
              <Field label="pH tối thiểu"><input className="input" type="number" step="0.1" placeholder="Nhập pH min nếu có" value={form.minPh} onChange={(e) => setForm({ ...form, minPh: e.target.value })} /></Field>
              <Field label="pH tối đa"><input className="input" type="number" step="0.1" placeholder="Nhập pH max nếu có" value={form.maxPh} onChange={(e) => setForm({ ...form, maxPh: e.target.value })} /></Field>
              <Field label="Ghi chú lưu trữ" className="md:col-span-2"><input className="input" placeholder="Ghi chú riêng về lưu kho nếu có" value={form.storageNotes} onChange={(e) => setForm({ ...form, storageNotes: e.target.value })} /></Field>
            </Section>
            <Section title="Lô nhập kho đầu tiên">
              <Field label="Số lượng nhập"><input className="input" type="number" min={0.0001} placeholder="Nhập số lượng" value={form.quantityCurrent || ''} onChange={(e) => setForm({ ...form, quantityCurrent: Number(e.target.value) })} /></Field>
              <Field label="Số lô nhà cung cấp"><input className="input" placeholder="Nhập số lô từ nhà cung cấp" value={form.supplierLotNumber} onChange={(e) => setForm({ ...form, supplierLotNumber: e.target.value })} /></Field>
              <Field label="Nhà cung cấp"><input className="input" placeholder="Nhập tên nhà cung cấp" value={form.supplierName} onChange={(e) => setForm({ ...form, supplierName: e.target.value })} /></Field>
              <Field label="Kiểu vật chứa"><select className="input" value={form.containerType} onChange={(e) => setForm({ ...form, containerType: e.target.value })}><option value="">Chọn kiểu vật chứa</option>{containerTypes.map((item) => <option key={item}>{item}</option>)}</select></Field>
              <Field label="Số đơn vị chứa"><input className="input" type="number" min={0} placeholder="Nhập số thùng/chai/bao" value={form.containerCount || ''} onChange={(e) => setForm({ ...form, containerCount: Number(e.target.value) })} /></Field>
              <Field label="Trạng thái duyệt"><select className="input" value={form.qcStatus} onChange={(e) => setForm({ ...form, qcStatus: e.target.value as QcStatus })}>{qcStatuses.map((item) => <option key={item.value} value={item.value}>{item.label}</option>)}</select></Field>
              <Field label="Ngày sản xuất"><input className="input" type="date" max={today()} value={form.manufactureDate} onChange={(e) => setForm({ ...form, manufactureDate: e.target.value })} /></Field>
              <Field label="Hạn sử dụng"><input className="input" type="date" min={tomorrowInput} value={form.expiryDate} onChange={(e) => setForm({ ...form, expiryDate: e.target.value })} /></Field>
              <Field label="Vị trí kho"><select className="input" value={form.locationId} onChange={(e) => setForm({ ...form, locationId: Number(e.target.value) })}>
                <option value={0}>Chọn vị trí kho</option>
                {locations.map((loc: any) => <option key={loc.locationId} value={loc.locationId}>{loc.locationCode} - {loc.locationName}</option>)}
              </select></Field>
            </Section>
            <div className="rounded-lg border border-dashed border-neutral-300 p-4">
              <label className="text-sm font-medium text-neutral-700 flex items-center mb-2"><Upload className="w-4 h-4 mr-2" />Tải giấy kiểm nghiệm</label>
              <input type="file" accept=".jpg,.jpeg,.png,.webp,.pdf" onChange={(e) => setCertificateFile(e.target.files?.[0] ?? null)} />
            </div>
            <div className="flex justify-end gap-2"><button className="btn-ghost" onClick={() => setShowModal(false)}>Hủy</button><button className="btn-primary" onClick={() => createMutation.mutate()} disabled={createMutation.isPending}>Lưu</button></div>
          </div>
        </div>
      )}

      {showImportModal && (
        <LotModal
          title="Nhập lô nguyên liệu"
          materials={materials}
          locations={locations}
          materialId={importMaterialId}
          onMaterialChange={setImportMaterialId}
          value={importForm}
          onChange={setImportForm}
          onClose={() => setShowImportModal(false)}
          onSubmit={() => importMutation.mutate()}
          file={importCertFile}
          setFile={setImportCertFile}
          pending={importMutation.isPending}
        />
      )}

      {detailMaterial && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl w-full max-w-6xl p-6 space-y-4 max-h-[92vh] overflow-y-auto">
            <div className="flex items-center justify-between"><h3 className="text-xl font-bold">Chi tiết: {detailMaterial.materialName}</h3><button className="btn-ghost" onClick={() => setDetailMaterial(null)}>Đóng</button></div>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-3 text-sm">
              <Info label="Dạng" value={detailMaterial.physicalForm} />
              <Info label="Tiêu chuẩn" value={detailMaterial.technicalSpecification} />
              <Info label="Đơn vị tính" value={detailMaterial.baseUomName} />
              <Info label="Điều kiện bảo quản" value={detailMaterial.storageCondition} />
              <Info label="Nhiệt độ" value={`${detailMaterial.minStorageTemperature ?? '-'} - ${detailMaterial.maxStorageTemperature ?? '-'} °C`} />
              <Info label="Độ ẩm" value={`${detailMaterial.minStorageHumidity ?? '-'} - ${detailMaterial.maxStorageHumidity ?? '-'} %`} />
              <Info label="pH" value={`${detailMaterial.minPh ?? '-'} - ${detailMaterial.maxPh ?? '-'}`} />
              <Info label="Ghi chú" value={detailMaterial.storageNotes} />
            </div>
            <div className="rounded-xl border border-neutral-200 overflow-hidden">
              <div className="px-4 py-3 bg-neutral-50 border-b border-neutral-200 font-semibold text-neutral-800">Lô tồn kho</div>
              <div className="table-container">
                <table className="table">
                  <thead><tr><th>Mã lô</th><th>Lô NCC</th><th>Số lượng</th><th>Trạng thái duyệt</th><th>Vị trí</th><th>Chứa đựng</th><th>HSD</th><th>GCN</th><th className="text-right">Thao tác</th></tr></thead>
                  <tbody>
                    {getMaterialLots(detailMaterial.materialId).map((lot) => (
                      <tr key={lot.lotId}>
                        <td>{lot.lotNumber}</td>
                        <td>{lot.supplierLotNumber || '-'}</td>
                        <td>{formatQty(lot.quantityCurrent, detailMaterial.baseUomName)}</td>
                        <td>{statusBadge(lot.qcStatus)}</td>
                        <td>{lot.locationCode || '-'}</td>
                        <td>{lot.containerType || '-'} {lot.containerCount ? `(${lot.containerCount})` : ''}</td>
                        <td>{formatDate(lot.expiryDate)}</td>
                        <td><a className="text-primary-600 hover:underline inline-flex items-center" href={certificatesApi.getMaterialCertificateUrl(detailMaterial.materialCode)} target="_blank" rel="noreferrer"><FileCheck2 className="w-4 h-4 mr-1" />Xem</a></td>
                        <td className="text-right">
                          {!isReadOnly && (
                            <>
                              <button className="btn-ghost text-sm" onClick={() => setEditingLot({
                                lotId: lot.lotId,
                                lotNumber: lot.lotNumber,
                                quantityCurrent: lot.quantityCurrent,
                                manufactureDate: toInputDate(lot.manufactureDate),
                                expiryDate: toInputDate(lot.expiryDate),
                                supplierLotNumber: lot.supplierLotNumber,
                                supplierName: lot.supplierName,
                                containerType: lot.containerType,
                                containerCount: lot.containerCount,
                                qcStatus: lot.qcStatus,
                                coaFilePath: lot.coaFilePath,
                                rejectedReason: lot.rejectedReason,
                                locationId: lot.locationId,
                              })}><Pencil className="w-4 h-4 mr-1" />Sửa</button>
                              <button className="btn-ghost text-sm text-red-600" onClick={() => confirm(`Xóa lô ${lot.lotNumber}?`) && deleteLotMutation.mutate(lot.lotId)}><Trash2 className="w-4 h-4 mr-1" />Xóa</button>
                            </>
                          )}
                        </td>
                      </tr>
                    ))}
                    {getMaterialLots(detailMaterial.materialId).length === 0 && <tr><td colSpan={9} className="text-center text-neutral-500 py-4">Chưa có lô nhập.</td></tr>}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      )}

      {editingLot && (
        <EditLotModal
          value={editingLot}
          locations={locations}
          onChange={setEditingLot}
          onClose={() => setEditingLot(null)}
          onSubmit={() => updateLotMutation.mutate(editingLot)}
          pending={updateLotMutation.isPending}
        />
      )}
    </div>
  );
}

function Section({ title, children }: { title: string; children: ReactNode }) {
  return <div><h3 className="font-semibold text-neutral-800 mb-2">{title}</h3><div className="grid grid-cols-1 md:grid-cols-3 gap-3">{children}</div></div>;
}

function Info({ label, value }: { label: string; value?: string | number | null }) {
  return <div className="rounded-lg border border-neutral-200 p-3"><p className="text-neutral-500">{label}</p><p className="font-medium text-neutral-900">{value || '-'}</p></div>;
}

function Field({ label, className = '', children }: { label: string; className?: string; children: ReactNode }) {
  return (
    <label className={`space-y-1 ${className}`}>
      <span className="block text-xs font-semibold text-neutral-600">{label}</span>
      {children}
    </label>
  );
}

function LotModal(props: {
  title: string;
  materials: any[];
  locations: any[];
  materialId: number;
  onMaterialChange: (id: number) => void;
  value: any;
  onChange: (value: any) => void;
  onClose: () => void;
  onSubmit: () => void;
  file: File | null;
  setFile: (file: File | null) => void;
  pending: boolean;
}) {
  const { title, materials, locations, materialId, onMaterialChange, value, onChange, onClose, onSubmit, setFile, pending } = props;
  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl w-full max-w-6xl p-6 space-y-4 max-h-[92vh] overflow-y-auto">
        <h2 className="text-2xl font-bold text-neutral-900">{title}</h2>
        <Section title="Thông tin lô">
          <Field label="Nguyên liệu"><select className="input" value={materialId} onChange={(e) => onMaterialChange(Number(e.target.value))}>
            <option value={0}>Chọn nguyên liệu</option>
            {materials.map((m) => <option key={m.materialId} value={m.materialId}>{m.materialCode} - {m.materialName}</option>)}
          </select></Field>
          <Field label="Số lượng nhập"><input className="input" type="number" min={0.0001} placeholder="Nhập số lượng" value={value.quantityCurrent || ''} onChange={(e) => onChange({ ...value, quantityCurrent: Number(e.target.value) })} /></Field>
          <Field label="Số lô nhà cung cấp"><input className="input" placeholder="Nhập số lô từ nhà cung cấp" value={value.supplierLotNumber} onChange={(e) => onChange({ ...value, supplierLotNumber: e.target.value })} /></Field>
          <Field label="Nhà cung cấp"><input className="input" placeholder="Nhập tên nhà cung cấp" value={value.supplierName} onChange={(e) => onChange({ ...value, supplierName: e.target.value })} /></Field>
          <Field label="Kiểu vật chứa"><select className="input" value={value.containerType} onChange={(e) => onChange({ ...value, containerType: e.target.value })}><option value="">Chọn kiểu vật chứa</option>{containerTypes.map((item) => <option key={item}>{item}</option>)}</select></Field>
          <Field label="Số đơn vị chứa"><input className="input" type="number" min={0} placeholder="Nhập số thùng/chai/bao" value={value.containerCount || ''} onChange={(e) => onChange({ ...value, containerCount: Number(e.target.value) })} /></Field>
          <Field label="Trạng thái duyệt"><select className="input" value={value.qcStatus} onChange={(e) => onChange({ ...value, qcStatus: e.target.value as QcStatus })}>{qcStatuses.map((item) => <option key={item.value} value={item.value}>{item.label}</option>)}</select></Field>
          <Field label="Vị trí kho"><select className="input" value={value.locationId} onChange={(e) => onChange({ ...value, locationId: Number(e.target.value) })}>
            <option value={0}>Chọn vị trí kho</option>
            {locations.map((loc: any) => <option key={loc.locationId} value={loc.locationId}>{loc.locationCode} - {loc.locationName}</option>)}
          </select></Field>
          <Field label="Ngày sản xuất"><input className="input" type="date" max={today()} value={value.manufactureDate} onChange={(e) => onChange({ ...value, manufactureDate: e.target.value })} /></Field>
          <Field label="Hạn sử dụng"><input className="input" type="date" value={value.expiryDate} onChange={(e) => onChange({ ...value, expiryDate: e.target.value })} /></Field>
        </Section>
        <div className="rounded-lg border border-dashed border-neutral-300 p-4">
          <label className="text-sm font-medium text-neutral-700 flex items-center mb-2"><Upload className="w-4 h-4 mr-2" />Tải giấy kiểm nghiệm</label>
          <input type="file" accept=".jpg,.jpeg,.png,.webp,.pdf" onChange={(e) => setFile(e.target.files?.[0] ?? null)} />
        </div>
        <div className="flex justify-end gap-2"><button className="btn-ghost" onClick={onClose}>Hủy</button><button className="btn-primary" onClick={onSubmit} disabled={pending}>Lưu</button></div>
      </div>
    </div>
  );
}

function EditLotModal(props: { value: LotForm; locations: any[]; onChange: (value: LotForm) => void; onClose: () => void; onSubmit: () => void; pending: boolean }) {
  const { value, locations, onChange, onClose, onSubmit, pending } = props;
  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl w-full max-w-6xl p-6 space-y-4 max-h-[92vh] overflow-y-auto">
        <h3 className="text-xl font-bold text-neutral-900">Cập nhật lô nguyên liệu</h3>
        <Section title="Thông tin lô">
          <Field label="Mã lô"><input className="input" value={value.lotNumber} disabled /></Field>
          <Field label="Số lượng hiện có"><input className="input" type="number" min={0.0001} value={value.quantityCurrent || ''} onChange={(e) => onChange({ ...value, quantityCurrent: Number(e.target.value) })} /></Field>
          <Field label="Số lô nhà cung cấp"><input className="input" placeholder="Nhập số lô từ nhà cung cấp" value={value.supplierLotNumber} onChange={(e) => onChange({ ...value, supplierLotNumber: e.target.value })} /></Field>
          <Field label="Nhà cung cấp"><input className="input" placeholder="Nhập tên nhà cung cấp" value={value.supplierName} onChange={(e) => onChange({ ...value, supplierName: e.target.value })} /></Field>
          <Field label="Kiểu vật chứa"><select className="input" value={value.containerType} onChange={(e) => onChange({ ...value, containerType: e.target.value })}><option value="">Chọn kiểu vật chứa</option>{containerTypes.map((item) => <option key={item}>{item}</option>)}</select></Field>
          <Field label="Số đơn vị chứa"><input className="input" type="number" min={0} value={value.containerCount || ''} onChange={(e) => onChange({ ...value, containerCount: Number(e.target.value) })} /></Field>
          <Field label="Trạng thái duyệt"><select className="input" value={value.qcStatus} onChange={(e) => onChange({ ...value, qcStatus: e.target.value as QcStatus })}>{qcStatuses.map((item) => <option key={item.value} value={item.value}>{item.label}</option>)}</select></Field>
          <Field label="Vị trí kho"><select className="input" value={value.locationId} onChange={(e) => onChange({ ...value, locationId: Number(e.target.value) })}>
            <option value={0}>Chọn vị trí kho</option>
            {locations.map((loc: any) => <option key={loc.locationId} value={loc.locationId}>{loc.locationCode} - {loc.locationName}</option>)}
          </select></Field>
          <Field label="Ngày sản xuất"><input className="input" type="date" value={value.manufactureDate} onChange={(e) => onChange({ ...value, manufactureDate: e.target.value })} /></Field>
          <Field label="Hạn sử dụng"><input className="input" type="date" value={value.expiryDate} onChange={(e) => onChange({ ...value, expiryDate: e.target.value })} /></Field>
          <Field label="Đường dẫn GCN"><input className="input" placeholder="Nhập đường dẫn giấy chứng nhận" value={value.coaFilePath} onChange={(e) => onChange({ ...value, coaFilePath: e.target.value })} /></Field>
          {value.qcStatus === 'Rejected' && <Field label="Lý do không đạt" className="md:col-span-2"><input className="input" placeholder="Nhập lý do không đạt" value={value.rejectedReason} onChange={(e) => onChange({ ...value, rejectedReason: e.target.value })} /></Field>}
        </Section>
        <div className="flex justify-end gap-2"><button className="btn-ghost" onClick={onClose}>Hủy</button><button className="btn-primary" onClick={onSubmit} disabled={pending}>Lưu thay đổi</button></div>
      </div>
    </div>
  );
}
