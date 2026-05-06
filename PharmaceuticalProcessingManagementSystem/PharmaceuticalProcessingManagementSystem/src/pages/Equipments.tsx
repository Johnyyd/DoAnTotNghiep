import { useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { equipmentsApi, areasApi } from '@/services/api';
import { Plus, Search, Pencil, Trash2, X } from 'lucide-react';

type UiEquipment = {
  equipmentId: number;
  equipmentCode: string;
  equipmentName: string;
  technicalSpec: string;
  usageFor: string;
  areaId: number | null;
  areaName: string;
  canEdit: boolean;
  canDelete: boolean;
};

type AreaOption = {
  areaId: number;
  areaName: string;
};

function normalizeEquipment(raw: any): UiEquipment {
  return {
    equipmentId: raw.equipmentId ?? raw.EquipmentId ?? 0,
    equipmentCode: raw.equipmentCode ?? raw.EquipmentCode ?? '-',
    equipmentName: raw.equipmentName ?? raw.EquipmentName ?? '-',
    technicalSpec: raw.technicalSpecification ?? raw.TechnicalSpecification ?? '-',
    usageFor: raw.usagePurpose ?? raw.UsagePurpose ?? '-',
    areaId: raw.areaId ?? raw.AreaId ?? raw.area?.areaId ?? raw.Area?.AreaId ?? null,
    areaName: raw.area?.areaName ?? raw.Area?.AreaName ?? '-',
    canEdit: (raw.canEdit ?? raw.CanEdit) !== false,
    canDelete: (raw.canDelete ?? raw.CanDelete) !== false,
  };
}

export default function Equipments() {
  const qc = useQueryClient();
  const [search, setSearch] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [editing, setEditing] = useState<UiEquipment | null>(null);
  const [form, setForm] = useState({
    equipmentCode: '',
    equipmentName: '',
    technicalSpecification: '',
    usagePurpose: '',
    areaId: '',
  });

  const { data: equipmentsRaw, isLoading } = useQuery({
    queryKey: ['equipments'],
    queryFn: () => equipmentsApi.getAll(),
    refetchInterval: 3000,
  });

  const { data: areasRaw } = useQuery({
    queryKey: ['productionAreas'],
    queryFn: () => areasApi.getAll(),
    refetchInterval: 3000,
  });

  const areas = useMemo(() => {
    const rows = Array.isArray(areasRaw) ? areasRaw : (areasRaw as any)?.data ?? [];
    return (rows as any[]).map((a) => ({
      areaId: a.areaId ?? a.AreaId,
      areaName: a.areaName ?? a.AreaName,
    })) as AreaOption[];
  }, [areasRaw]);

  const equipments = useMemo(() => {
    const rows = Array.isArray(equipmentsRaw) ? equipmentsRaw : (equipmentsRaw as any)?.data ?? [];
    return (rows as any[]).map(normalizeEquipment);
  }, [equipmentsRaw]);

  const filtered = useMemo(() => {
    const keyword = search.trim().toLowerCase();
    if (!keyword) return equipments;
    return equipments.filter((e) => e.equipmentCode.toLowerCase().includes(keyword) || e.equipmentName.toLowerCase().includes(keyword));
  }, [equipments, search]);

  const createMutation = useMutation({
    mutationFn: (payload: any) => equipmentsApi.create(payload),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['equipments'] });
      setShowModal(false);
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, payload }: { id: number; payload: any }) => equipmentsApi.update(id, payload),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['equipments'] });
      setShowModal(false);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: number) => equipmentsApi.delete(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['equipments'] }),
  });

  const openCreate = () => {
    setEditing(null);
    setForm({ equipmentCode: '', equipmentName: '', technicalSpecification: '', usagePurpose: '', areaId: '' });
    setShowModal(true);
  };

  const openEdit = (row: UiEquipment) => {
    setEditing(row);
    setForm({
      equipmentCode: row.equipmentCode,
      equipmentName: row.equipmentName,
      technicalSpecification: row.technicalSpec === '-' ? '' : row.technicalSpec,
      usagePurpose: row.usageFor === '-' ? '' : row.usageFor,
      areaId: row.areaId ? String(row.areaId) : '',
    });
    setShowModal(true);
  };

  const submit = async () => {
    if (!form.equipmentCode.trim() || !form.equipmentName.trim()) {
      alert('Vui long nhap ma thiet bi va ten thiet bi.');
      return;
    }

    const payload = {
      equipmentId: editing?.equipmentId ?? 0,
      equipmentCode: form.equipmentCode.trim(),
      equipmentName: form.equipmentName.trim(),
      technicalSpecification: form.technicalSpecification.trim(),
      usagePurpose: form.usagePurpose.trim(),
      areaId: form.areaId ? Number(form.areaId) : null,
    };

    try {
      if (editing) {
        await updateMutation.mutateAsync({ id: editing.equipmentId, payload });
      } else {
        await createMutation.mutateAsync(payload);
      }
    } catch (error: any) {
      alert(error?.response?.data?.message ?? 'Thao tac that bai.');
    }
  };

  const onDelete = async (row: UiEquipment) => {
    if (!confirm(`Xoa thiet bi ${row.equipmentCode}?`)) return;
    try {
      await deleteMutation.mutateAsync(row.equipmentId);
    } catch (error: any) {
      alert(error?.response?.data?.message ?? 'Xoa that bai.');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900">Quan ly thiet bi</h1>
          <p className="text-sm text-neutral-500 mt-1">Thong tin theo bieu mau CamScanner trang 2</p>
        </div>
        <button onClick={openCreate} className="btn-primary inline-flex items-center gap-2">
          <Plus className="w-4 h-4" /> Them thiet bi
        </button>
      </div>

      <div className="card">
        <div className="relative w-full md:w-96">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-neutral-400" />
          <input type="text" placeholder="Tim ma hoac ten thiet bi..." value={search} onChange={(e) => setSearch(e.target.value)} className="input pl-10" />
        </div>
      </div>

      <div className="bg-surface border border-neutral-200 rounded-xl overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-neutral-50 border-b border-neutral-200">
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Ma thiet bi</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Ten thiet bi</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Dac tinh ky thuat</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Cong dung</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Khu vuc</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600 text-right">Thao tac</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-200">
              {isLoading ? (
                <tr><td colSpan={6} className="py-8 text-center text-neutral-500">Dang tai du lieu thiet bi...</td></tr>
              ) : filtered.length === 0 ? (
                <tr><td colSpan={6} className="py-8 text-center text-neutral-500">Khong co thiet bi phu hop</td></tr>
              ) : (
                filtered.map((equip) => (
                  <tr key={equip.equipmentId} className="hover:bg-neutral-50 transition-colors">
                    <td className="py-3 px-4 text-sm font-mono text-neutral-700">{equip.equipmentCode}</td>
                    <td className="py-3 px-4 text-sm text-neutral-900 font-medium">{equip.equipmentName}</td>
                    <td className="py-3 px-4 text-sm text-neutral-700">{equip.technicalSpec}</td>
                    <td className="py-3 px-4 text-sm text-neutral-700">{equip.usageFor}</td>
                    <td className="py-3 px-4 text-sm text-neutral-700">{equip.areaName}</td>
                    <td className="py-3 px-4 text-sm text-right">
                      <div className="inline-flex items-center gap-2">
                        <button disabled={!equip.canEdit} onClick={() => openEdit(equip)} className="text-blue-600 disabled:text-neutral-300" title={equip.canEdit ? 'Sua' : 'Khong the sua vi da su dung'}>
                          <Pencil className="w-4 h-4" />
                        </button>
                        <button disabled={!equip.canDelete} onClick={() => onDelete(equip)} className="text-red-600 disabled:text-neutral-300" title={equip.canDelete ? 'Xoa' : 'Khong the xoa vi da su dung'}>
                          <Trash2 className="w-4 h-4" />
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

      {showModal && (
        <div className="fixed inset-0 z-50 bg-black/40 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl w-full max-w-2xl p-6 space-y-4" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between">
              <h2 className="text-xl font-bold">{editing ? 'Cap nhat thiet bi' : 'Them thiet bi moi'}</h2>
              <button onClick={() => setShowModal(false)}><X className="w-5 h-5" /></button>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              <input className="input" placeholder="Ma thiet bi" value={form.equipmentCode} onChange={(e) => setForm((f) => ({ ...f, equipmentCode: e.target.value }))} />
              <input className="input" placeholder="Ten thiet bi" value={form.equipmentName} onChange={(e) => setForm((f) => ({ ...f, equipmentName: e.target.value }))} />
              <input className="input md:col-span-2" placeholder="Dac tinh ky thuat" value={form.technicalSpecification} onChange={(e) => setForm((f) => ({ ...f, technicalSpecification: e.target.value }))} />
              <input className="input md:col-span-2" placeholder="Cong dung" value={form.usagePurpose} onChange={(e) => setForm((f) => ({ ...f, usagePurpose: e.target.value }))} />
              <select className="input md:col-span-2" value={form.areaId} onChange={(e) => setForm((f) => ({ ...f, areaId: e.target.value }))}>
                <option value="">Chon khu vuc</option>
                {areas.map((a) => <option key={a.areaId} value={a.areaId}>{a.areaName}</option>)}
              </select>
            </div>
            <div className="flex justify-end gap-2">
              <button className="btn-outline" onClick={() => setShowModal(false)}>Huy</button>
              <button className="btn-primary" onClick={submit} disabled={createMutation.isPending || updateMutation.isPending}>
                {editing ? 'Luu cap nhat' : 'Them moi'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
