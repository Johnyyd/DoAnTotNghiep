import { useMemo, useState, type ReactNode } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { storageLocationsApi } from '@/services/api';
import { Archive, Pencil, Plus, Search, X } from 'lucide-react';

type StorageLocation = {
  locationId: number;
  locationCode: string;
  locationName: string;
  locationType: string;
  temperatureMin: number | null;
  temperatureMax: number | null;
  humidityMin: number | null;
  humidityMax: number | null;
  cleanlinessStatus: string;
  isQualified: boolean;
  note: string;
  isInUse: boolean;
  canEdit: boolean;
};

const emptyForm = {
  locationCode: '',
  locationName: '',
  locationType: '',
  temperatureMin: '',
  temperatureMax: '',
  humidityMin: '',
  humidityMax: '',
  cleanlinessStatus: '',
  isQualified: true,
  note: '',
};

function rowsFrom(raw: unknown): any[] {
  if (Array.isArray(raw)) return raw;
  if (raw && typeof raw === 'object' && Array.isArray((raw as any).data)) return (raw as any).data;
  return [];
}

function decimalOrNull(value: string) {
  if (value.trim() === '') return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

export default function StorageLocations() {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [editing, setEditing] = useState<StorageLocation | null>(null);
  const [form, setForm] = useState(emptyForm);

  const { data: locationsRaw, isLoading } = useQuery({
    queryKey: ['storageLocations'],
    queryFn: () => storageLocationsApi.getAll(),
  });

  const locations = useMemo<StorageLocation[]>(() => rowsFrom(locationsRaw).map((location) => ({
    locationId: Number(location.locationId ?? location.LocationId ?? 0),
    locationCode: location.locationCode ?? location.LocationCode ?? '',
    locationName: location.locationName ?? location.LocationName ?? '',
    locationType: location.locationType ?? location.LocationType ?? '',
    temperatureMin: location.temperatureMin ?? location.TemperatureMin ?? null,
    temperatureMax: location.temperatureMax ?? location.TemperatureMax ?? null,
    humidityMin: location.humidityMin ?? location.HumidityMin ?? null,
    humidityMax: location.humidityMax ?? location.HumidityMax ?? null,
    cleanlinessStatus: location.cleanlinessStatus ?? location.CleanlinessStatus ?? '',
    isQualified: (location.isQualified ?? location.IsQualified) !== false,
    note: location.note ?? location.Note ?? '',
    isInUse: (location.isInUse ?? location.IsInUse) === true,
    canEdit: (location.canEdit ?? location.CanEdit) !== false,
  })), [locationsRaw]);

  const filtered = useMemo(() => {
    const keyword = search.trim().toLowerCase();
    if (!keyword) return locations;
    return locations.filter((location) =>
      `${location.locationCode} ${location.locationName} ${location.locationType}`.toLowerCase().includes(keyword)
    );
  }, [locations, search]);

  const createMutation = useMutation({
    mutationFn: (payload: any) => storageLocationsApi.create(payload),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['storageLocations'] });
      setShowModal(false);
    },
    onError: (error: any) => alert(error?.response?.data?.message ?? 'Không thể thêm kho.'),
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, payload }: { id: number; payload: any }) => storageLocationsApi.update(id, payload),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['storageLocations'] });
      setShowModal(false);
      setEditing(null);
    },
    onError: (error: any) => alert(error?.response?.data?.message ?? 'Không thể cập nhật kho.'),
  });

  const openCreate = () => {
    setEditing(null);
    setForm(emptyForm);
    setShowModal(true);
  };

  const openEdit = (location: StorageLocation) => {
    setEditing(location);
    setForm({
      locationCode: location.locationCode,
      locationName: location.locationName,
      locationType: location.locationType,
      temperatureMin: location.temperatureMin?.toString() ?? '',
      temperatureMax: location.temperatureMax?.toString() ?? '',
      humidityMin: location.humidityMin?.toString() ?? '',
      humidityMax: location.humidityMax?.toString() ?? '',
      cleanlinessStatus: location.cleanlinessStatus,
      isQualified: location.isQualified,
      note: location.note,
    });
    setShowModal(true);
  };

  const submit = () => {
    const payload = {
      locationId: editing?.locationId ?? 0,
      locationCode: form.locationCode,
      locationName: form.locationName,
      locationType: form.locationType,
      temperatureMin: decimalOrNull(form.temperatureMin),
      temperatureMax: decimalOrNull(form.temperatureMax),
      humidityMin: decimalOrNull(form.humidityMin),
      humidityMax: decimalOrNull(form.humidityMax),
      cleanlinessStatus: form.cleanlinessStatus,
      isQualified: form.isQualified,
      note: form.note,
    };

    if (editing) {
      updateMutation.mutate({ id: editing.locationId, payload });
    } else {
      createMutation.mutate(payload);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900">Quản lý kho</h1>
          <p className="text-sm text-neutral-500 mt-1">Quản lý kho nguyên liệu, kho mát, tủ hóa chất và điều kiện lưu trữ.</p>
        </div>
        <button className="btn-primary inline-flex items-center gap-2" onClick={openCreate}>
          <Plus className="w-4 h-4" /> Thêm kho
        </button>
      </div>

      <div className="card">
        <div className="relative w-full md:w-96">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-neutral-400" />
          <input className="input pl-10" placeholder="Tìm mã kho, tên kho..." value={search} onChange={(event) => setSearch(event.target.value)} />
        </div>
      </div>

      <div className="bg-surface border border-neutral-200 rounded-xl overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-neutral-50 border-b border-neutral-200">
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Mã kho</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Tên kho</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Loại kho</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Nhiệt độ</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Độ ẩm</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Trạng thái</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600 text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-200">
              {isLoading ? (
                <tr><td colSpan={7} className="py-8 text-center text-neutral-500">Đang tải danh sách kho...</td></tr>
              ) : filtered.length === 0 ? (
                <tr><td colSpan={7} className="py-10 text-center text-neutral-500"><Archive className="w-10 h-10 mx-auto mb-2 text-neutral-300" />Không có kho phù hợp.</td></tr>
              ) : filtered.map((location) => (
                <tr key={location.locationId} className="hover:bg-neutral-50">
                  <td className="py-3 px-4 text-sm font-mono text-primary-700">#{location.locationCode}</td>
                  <td className="py-3 px-4 text-sm font-semibold text-neutral-900">{location.locationName}</td>
                  <td className="py-3 px-4 text-sm text-neutral-600">{location.locationType || '-'}</td>
                  <td className="py-3 px-4 text-sm text-neutral-600">{location.temperatureMin ?? '-'} - {location.temperatureMax ?? '-'} °C</td>
                  <td className="py-3 px-4 text-sm text-neutral-600">{location.humidityMin ?? '-'} - {location.humidityMax ?? '-'} %</td>
                  <td className="py-3 px-4">
                    <span className={`inline-flex rounded-full px-2 py-1 text-xs font-semibold ${location.isInUse ? 'bg-blue-100 text-blue-700' : 'bg-green-100 text-green-700'}`}>
                      {location.isInUse ? 'Đang được sử dụng' : 'Chưa sử dụng'}
                    </span>
                  </td>
                  <td className="py-3 px-4 text-right">
                    <button disabled={!location.canEdit} className="btn-ghost text-sm disabled:text-neutral-300" title={location.canEdit ? 'Sửa kho' : 'Kho đã được sử dụng, không thể sửa'} onClick={() => openEdit(location)}>
                      <Pencil className="w-4 h-4 mr-1" />Sửa
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {showModal && (
        <div className="fixed inset-0 z-50 bg-black/40 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl w-full max-w-5xl p-6 space-y-4" onClick={(event) => event.stopPropagation()}>
            <div className="flex items-center justify-between">
              <h2 className="text-xl font-bold">{editing ? 'Cập nhật kho' : 'Thêm kho mới'}</h2>
              <button onClick={() => setShowModal(false)}><X className="w-5 h-5" /></button>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
              <Field label="Mã kho"><input className="input" placeholder="Ví dụ: KHO-NL-MAT" value={form.locationCode} onChange={(event) => setForm((current) => ({ ...current, locationCode: event.target.value }))} /></Field>
              <Field label="Tên kho"><input className="input" placeholder="Nhập tên kho" value={form.locationName} onChange={(event) => setForm((current) => ({ ...current, locationName: event.target.value }))} /></Field>
              <Field label="Loại kho"><input className="input" placeholder="Ví dụ: Kho mát, tủ hóa chất" value={form.locationType} onChange={(event) => setForm((current) => ({ ...current, locationType: event.target.value }))} /></Field>
              <Field label="Nhiệt độ tối thiểu (°C)"><input className="input" type="number" placeholder="Nhập nhiệt độ min" value={form.temperatureMin} onChange={(event) => setForm((current) => ({ ...current, temperatureMin: event.target.value }))} /></Field>
              <Field label="Nhiệt độ tối đa (°C)"><input className="input" type="number" placeholder="Nhập nhiệt độ max" value={form.temperatureMax} onChange={(event) => setForm((current) => ({ ...current, temperatureMax: event.target.value }))} /></Field>
              <Field label="Cấp sạch/tình trạng vệ sinh"><input className="input" placeholder="Ví dụ: Đạt GMP, sạch, khô" value={form.cleanlinessStatus} onChange={(event) => setForm((current) => ({ ...current, cleanlinessStatus: event.target.value }))} /></Field>
              <Field label="Độ ẩm tối thiểu (%)"><input className="input" type="number" placeholder="Nhập độ ẩm min" value={form.humidityMin} onChange={(event) => setForm((current) => ({ ...current, humidityMin: event.target.value }))} /></Field>
              <Field label="Độ ẩm tối đa (%)"><input className="input" type="number" placeholder="Nhập độ ẩm max" value={form.humidityMax} onChange={(event) => setForm((current) => ({ ...current, humidityMax: event.target.value }))} /></Field>
              <Field label="Đủ điều kiện lưu trữ"><select className="input" value={form.isQualified ? 'true' : 'false'} onChange={(event) => setForm((current) => ({ ...current, isQualified: event.target.value === 'true' }))}>
                <option value="true">Đủ điều kiện</option>
                <option value="false">Không đủ điều kiện</option>
              </select></Field>
              <Field label="Ghi chú" className="md:col-span-3"><textarea className="input min-h-[90px]" placeholder="Ghi chú thêm về kho" value={form.note} onChange={(event) => setForm((current) => ({ ...current, note: event.target.value }))} /></Field>
            </div>
            <div className="flex justify-end gap-2">
              <button className="btn-ghost" onClick={() => setShowModal(false)}>Hủy</button>
              <button className="btn-primary" onClick={submit} disabled={createMutation.isPending || updateMutation.isPending}>{editing ? 'Lưu cập nhật' : 'Thêm kho'}</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function Field({ label, className = '', children }: { label: string; className?: string; children: ReactNode }) {
  return (
    <label className={`space-y-1 ${className}`}>
      <span className="block text-xs font-semibold text-neutral-600">{label}</span>
      {children}
    </label>
  );
}
