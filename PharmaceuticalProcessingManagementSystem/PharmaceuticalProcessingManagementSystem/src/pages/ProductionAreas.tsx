import { useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { areasApi } from '@/services/api';
import { Search, MapPin, Plus, Pencil, Trash2, X } from 'lucide-react';

type Area = {
  areaId: number;
  areaCode: string;
  areaName: string;
  description: string;
  canEdit: boolean;
  canDelete: boolean;
};

export default function ProductionAreas() {
  const qc = useQueryClient();
  const [search, setSearch] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [editing, setEditing] = useState<Area | null>(null);
  const [form, setForm] = useState({ areaCode: '', areaName: '', description: '' });

  const { data: areasRaw, isLoading } = useQuery({
    queryKey: ['productionAreas'],
    queryFn: () => areasApi.getAll(),
    refetchInterval: 3000,
  });

  const areas = useMemo(() => {
    const rows = Array.isArray(areasRaw) ? areasRaw : (areasRaw as any)?.data ?? [];
    return (rows as any[]).map((a) => ({
      areaId: a.areaId ?? a.AreaId,
      areaCode: a.areaCode ?? a.AreaCode,
      areaName: a.areaName ?? a.AreaName,
      description: a.description ?? a.Description ?? '',
      canEdit: (a.canEdit ?? a.CanEdit) !== false,
      canDelete: (a.canDelete ?? a.CanDelete) !== false,
    })) as Area[];
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

  const createMutation = useMutation({
    mutationFn: (payload: any) => areasApi.create(payload),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['productionAreas'] });
      setShowModal(false);
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, payload }: { id: number; payload: any }) => areasApi.update(id, payload),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['productionAreas'] });
      setShowModal(false);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: number) => areasApi.delete(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['productionAreas'] }),
  });

  const openCreate = () => {
    setEditing(null);
    setForm({ areaCode: '', areaName: '', description: '' });
    setShowModal(true);
  };

  const openEdit = (row: Area) => {
    setEditing(row);
    setForm({ areaCode: row.areaCode, areaName: row.areaName, description: row.description ?? '' });
    setShowModal(true);
  };

  const submit = async () => {
    if (!form.areaCode.trim() || !form.areaName.trim()) {
      alert('Vui long nhap ma khu va ten khu san xuat.');
      return;
    }

    const payload = {
      areaId: editing?.areaId ?? 0,
      areaCode: form.areaCode.trim(),
      areaName: form.areaName.trim(),
      description: form.description.trim(),
    };

    try {
      if (editing) {
        await updateMutation.mutateAsync({ id: editing.areaId, payload });
      } else {
        await createMutation.mutateAsync(payload);
      }
    } catch (error: any) {
      alert(error?.response?.data?.message ?? 'Thao tac that bai.');
    }
  };

  const onDelete = async (row: Area) => {
    if (!confirm(`Xoa khu san xuat ${row.areaCode}?`)) return;
    try {
      await deleteMutation.mutateAsync(row.areaId);
    } catch (error: any) {
      alert(error?.response?.data?.message ?? 'Xoa that bai.');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900">Khu san xuat</h1>
          <p className="text-sm text-neutral-500 mt-1">Danh muc cac khu vuc va phong chuc nang trong nha may</p>
        </div>
        <button className="btn-primary inline-flex items-center gap-2" onClick={openCreate}>
          <Plus className="w-4 h-4" /> Them khu vuc
        </button>
      </div>

      <div className="card">
        <div className="relative w-full md:w-96">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-neutral-400" />
          <input
            type="text"
            placeholder="Tim ma hoac ten khu..."
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
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Ma khu</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Ten khu san xuat</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Mo ta chi tiet</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600 text-right">Thao tac</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-200">
              {isLoading ? (
                <tr>
                  <td colSpan={5} className="py-8 text-center text-neutral-500">
                    Dang tai du lieu...
                  </td>
                </tr>
              ) : filtered.length === 0 ? (
                <tr>
                  <td colSpan={5} className="py-8 text-center text-neutral-500">
                    Khong co du lieu khu san xuat
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
                      {area.description || 'Chua co mo ta'}
                    </td>
                    <td className="py-3 px-4 text-sm text-right">
                      <div className="inline-flex items-center gap-2">
                        <button disabled={!area.canEdit} onClick={() => openEdit(area)} className="text-blue-600 disabled:text-neutral-300" title={area.canEdit ? 'Sua' : 'Dang co lenh InProcess'}>
                          <Pencil className="w-4 h-4" />
                        </button>
                        <button disabled={!area.canDelete} onClick={() => onDelete(area)} className="text-red-600 disabled:text-neutral-300" title={area.canDelete ? 'Xoa' : 'Dang co lenh InProcess'}>
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
          <div className="bg-white rounded-2xl w-full max-w-xl p-6 space-y-4" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between">
              <h2 className="text-xl font-bold">{editing ? 'Cap nhat khu san xuat' : 'Them khu san xuat moi'}</h2>
              <button onClick={() => setShowModal(false)}><X className="w-5 h-5" /></button>
            </div>
            <div className="space-y-3">
              <input className="input" placeholder="Ma khu" value={form.areaCode} onChange={(e) => setForm((f) => ({ ...f, areaCode: e.target.value }))} />
              <input className="input" placeholder="Ten khu san xuat" value={form.areaName} onChange={(e) => setForm((f) => ({ ...f, areaName: e.target.value }))} />
              <textarea className="input min-h-[110px]" placeholder="Mo ta" value={form.description} onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))} />
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
