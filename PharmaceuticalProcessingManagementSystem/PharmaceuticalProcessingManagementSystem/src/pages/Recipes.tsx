import { useEffect, useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { areasApi, equipmentsApi, materialsApi, recipesApi } from '@/services/api';
import { CheckCircle2, ListTree, Pencil, Plus, Route, Search, Trash2 } from 'lucide-react';

type MaterialOption = { materialId: number; materialCode: string; materialName: string; type: string };
type AreaOption = { areaId: number; areaCode: string; areaName: string };
type EquipmentOption = { equipmentId: number; equipmentName: string; equipmentCode: string; technicalSpecification?: string };

type UiRecipe = { recipeId: number; materialId: number; materialName?: string; batchSize: number; status: string; versionNumber: number };
type UiBom = { bomId: number; materialId: number; materialName: string; quantity: number; technicalStandard?: string };
type UiRouting = {
  routingId: number;
  stepNumber: number;
  stepName: string;
  defaultEquipmentId?: number;
  materialId?: number;
  areaId?: number;
  equipmentName?: string;
  materialName?: string;
  areaName?: string;
  estimatedTimeMinutes: number;
  cleanlinessStatus?: string;
  standardTemperature?: number;
  standardHumidity?: number;
  standardPressure?: number;
  stabilityStatus?: string;
  setTemperature?: number;
  setTimeMinutes?: number;
  description?: string;
};

type RecipeCreateForm = { materialId: number; batchSize: number };
type BomDraftRow = { materialId: number; technicalStandard: string; ratioPercent: number; quantity: number };
type RoutingForm = {
  stepNumber: number;
  stepName: string;
  defaultEquipmentId: number;
  materialId: number;
  areaId: number;
  estimatedTimeMinutes: number;
  cleanlinessStatus: string;
  standardTemperature: number;
  standardHumidity: number;
  standardPressure: number;
  stabilityStatus: string;
  setTemperature: number;
  setTimeMinutes: number;
  description: string;
};

function toRows<T>(raw: unknown): T[] {
  if (Array.isArray(raw)) return raw as T[];
  if (raw && typeof raw === 'object' && 'data' in raw) {
    const data = (raw as { data?: unknown }).data;
    return Array.isArray(data) ? (data as T[]) : [];
  }
  return [];
}

function normalizeRecipe(item: any): UiRecipe {
  return {
    recipeId: Number(item.recipeId ?? item.RecipeId ?? 0),
    materialId: Number(item.materialId ?? item.MaterialId ?? 0),
    materialName: item.material?.materialName ?? item.Material?.MaterialName,
    batchSize: Number(item.batchSize ?? item.BatchSize ?? 0),
    status: item.status ?? item.Status ?? 'Draft',
    versionNumber: Number(item.versionNumber ?? item.VersionNumber ?? 1),
  };
}

function normalizeBom(item: any): UiBom {
  return {
    bomId: Number(item.bomId ?? item.BomId ?? 0),
    materialId: Number(item.materialId ?? item.MaterialId ?? 0),
    materialName: item.material?.materialName ?? item.Material?.MaterialName ?? 'Nguyên liệu',
    quantity: Number(item.quantity ?? item.Quantity ?? 0),
    technicalStandard: item.technicalStandard ?? item.TechnicalStandard ?? '',
  };
}

function normalizeRouting(item: any): UiRouting {
  return {
    routingId: Number(item.routingId ?? item.RoutingId ?? 0),
    stepNumber: Number(item.stepNumber ?? item.StepNumber ?? 1),
    stepName: item.stepName ?? item.StepName ?? '',
    defaultEquipmentId: Number(item.defaultEquipmentId ?? item.DefaultEquipmentId ?? 0) || undefined,
    materialId: Number(item.materialId ?? item.MaterialId ?? 0) || undefined,
    areaId: Number(item.areaId ?? item.AreaId ?? 0) || undefined,
    equipmentName: item.defaultEquipment?.equipmentName ?? item.DefaultEquipment?.EquipmentName,
    materialName: item.material?.materialName ?? item.Material?.MaterialName,
    areaName: item.area?.areaName ?? item.Area?.AreaName,
    estimatedTimeMinutes: Number(item.estimatedTimeMinutes ?? item.EstimatedTimeMinutes ?? 0),
    cleanlinessStatus: item.cleanlinessStatus ?? item.CleanlinessStatus,
    standardTemperature: Number(item.standardTemperature ?? item.StandardTemperature ?? 0) || undefined,
    standardHumidity: Number(item.standardHumidity ?? item.StandardHumidity ?? 0) || undefined,
    standardPressure: Number(item.standardPressure ?? item.StandardPressure ?? 0) || undefined,
    stabilityStatus: item.stabilityStatus ?? item.StabilityStatus,
    setTemperature: Number(item.setTemperature ?? item.SetTemperature ?? 0) || undefined,
    setTimeMinutes: Number(item.setTimeMinutes ?? item.SetTimeMinutes ?? 0) || undefined,
    description: item.description ?? item.Description ?? '',
  };
}

export default function Recipes() {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [selectedRecipeId, setSelectedRecipeId] = useState<number | null>(null);
  const [showRoutingModal, setShowRoutingModal] = useState(false);
  const [editingRouting, setEditingRouting] = useState<UiRouting | null>(null);

  const [createForm, setCreateForm] = useState<RecipeCreateForm>({ materialId: 0, batchSize: 0 });
  const [bomDraftRows, setBomDraftRows] = useState<BomDraftRow[]>([{ materialId: 0, technicalStandard: '', ratioPercent: 0, quantity: 0 }]);
  const [routingForm, setRoutingForm] = useState<RoutingForm>({
    stepNumber: 1,
    stepName: '',
    defaultEquipmentId: 0,
    materialId: 0,
    areaId: 0,
    estimatedTimeMinutes: 0,
    cleanlinessStatus: 'Sạch',
    standardTemperature: 25,
    standardHumidity: 60,
    standardPressure: 15,
    stabilityStatus: 'Ổn định',
    setTemperature: 25,
    setTimeMinutes: 0,
    description: '',
  });

  const { data: recipesRaw, isLoading } = useQuery({ queryKey: ['recipes'], queryFn: () => recipesApi.getAll() });
  const { data: materialsRaw } = useQuery({ queryKey: ['materials'], queryFn: () => materialsApi.getAll() });
  const { data: equipmentsRaw } = useQuery({ queryKey: ['equipments'], queryFn: () => equipmentsApi.getAll() });
  const { data: areasRaw } = useQuery({ queryKey: ['areas'], queryFn: () => areasApi.getAll() });

  const recipes = useMemo(() => toRows<any>(recipesRaw).map(normalizeRecipe), [recipesRaw]);
  const materials = useMemo<MaterialOption[]>(() => toRows<any>(materialsRaw).map((m) => ({
    materialId: Number(m.materialId ?? m.MaterialId ?? 0),
    materialCode: m.materialCode ?? m.MaterialCode ?? '',
    materialName: m.materialName ?? m.MaterialName ?? '',
    type: m.type ?? m.Type ?? '',
  })), [materialsRaw]);
  const areas = useMemo<AreaOption[]>(() => toRows<any>(areasRaw).map((a) => ({
    areaId: Number(a.areaId ?? a.AreaId ?? 0),
    areaCode: a.areaCode ?? a.AreaCode ?? '',
    areaName: a.areaName ?? a.AreaName ?? '',
  })), [areasRaw]);
  const equipments = useMemo<EquipmentOption[]>(() => toRows<any>(equipmentsRaw).map((e) => ({
    equipmentId: Number(e.equipmentId ?? e.EquipmentId ?? 0),
    equipmentName: e.equipmentName ?? e.EquipmentName ?? '',
    equipmentCode: e.equipmentCode ?? e.EquipmentCode ?? '',
    technicalSpecification: e.technicalSpecification ?? e.TechnicalSpecification ?? '',
  })), [equipmentsRaw]);

  const finishedMaterials = useMemo(() => materials.filter((m) => m.type === 'FinishedGood'), [materials]);
  const inputMaterials = useMemo(() => materials.filter((m) => m.type !== 'FinishedGood'), [materials]);

  const filteredRecipes = useMemo(() => {
    const keyword = search.trim().toLowerCase();
    if (!keyword) return recipes;
    return recipes.filter((recipe) => (recipe.materialName ?? '').toLowerCase().includes(keyword) || String(recipe.recipeId).includes(keyword));
  }, [recipes, search]);

  useEffect(() => {
    if (!filteredRecipes.length) {
      setSelectedRecipeId(null);
      return;
    }
    if (!filteredRecipes.some((r) => r.recipeId === selectedRecipeId)) {
      setSelectedRecipeId(filteredRecipes[0].recipeId);
    }
  }, [filteredRecipes, selectedRecipeId]);

  const selectedRecipe = useMemo(() => recipes.find((r) => r.recipeId === selectedRecipeId) ?? null, [recipes, selectedRecipeId]);

  const { data: bomRaw } = useQuery({ queryKey: ['recipeBom', selectedRecipeId], queryFn: () => recipesApi.getBOM(selectedRecipeId as number), enabled: !!selectedRecipeId });
  const { data: routingRaw } = useQuery({ queryKey: ['recipeRouting', selectedRecipeId], queryFn: () => recipesApi.getRouting(selectedRecipeId as number), enabled: !!selectedRecipeId });

  const bomItems = useMemo(() => toRows<any>(bomRaw).map(normalizeBom), [bomRaw]);
  const routingSteps = useMemo(() => toRows<any>(routingRaw).map(normalizeRouting).sort((a, b) => a.stepNumber - b.stepNumber), [routingRaw]);

  const totalPerTabletMg = useMemo(() => bomItems.reduce((sum, item) => sum + item.quantity, 0), [bomItems]);

  const createRecipeMutation = useMutation({
    mutationFn: () => recipesApi.create({ materialId: createForm.materialId, batchSize: createForm.batchSize, status: 'Draft', versionNumber: 1 }),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['recipes'] });
      setCreateForm({ materialId: 0, batchSize: 0 });
    },
  });

  const approveRecipeMutation = useMutation({
    mutationFn: (id: number) => recipesApi.approve(id, 'approved'),
    onSuccess: async () => queryClient.invalidateQueries({ queryKey: ['recipes'] }),
  });

  const deleteRecipeMutation = useMutation({
    mutationFn: (id: number) => recipesApi.delete(id),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['recipes'] });
      setSelectedRecipeId(null);
    },
    onError: (err: any) => alert(err?.response?.data?.message ?? err?.message ?? 'Xóa công thức thất bại'),
  });

  const addBomMutation = useMutation({
    mutationFn: (row: BomDraftRow) => recipesApi.addBOMItem(selectedRecipeId as number, {
      materialId: row.materialId,
      quantity: row.quantity,
      uomId: 2,
      technicalStandard: row.technicalStandard,
    } as any),
    onSuccess: async () => queryClient.invalidateQueries({ queryKey: ['recipeBom', selectedRecipeId] }),
  });

  const deleteBomMutation = useMutation({
    mutationFn: (bomId: number) => recipesApi.removeBOMItem(selectedRecipeId as number, bomId),
    onSuccess: async () => queryClient.invalidateQueries({ queryKey: ['recipeBom', selectedRecipeId] }),
  });

  const addRoutingMutation = useMutation({
    mutationFn: () => recipesApi.addRoutingStep(selectedRecipeId as number, routingForm as any),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['recipeRouting', selectedRecipeId] });
      setShowRoutingModal(false);
      setEditingRouting(null);
    },
  });

  const updateRoutingMutation = useMutation({
    mutationFn: () => recipesApi.updateRoutingStep(selectedRecipeId as number, editingRouting!.routingId, routingForm as any),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['recipeRouting', selectedRecipeId] });
      setShowRoutingModal(false);
      setEditingRouting(null);
    },
  });

  const deleteRoutingMutation = useMutation({
    mutationFn: (routingId: number) => recipesApi.removeRoutingStep(selectedRecipeId as number, routingId),
    onSuccess: async () => queryClient.invalidateQueries({ queryKey: ['recipeRouting', selectedRecipeId] }),
  });

  const recalcMgFromRatio = (ratioPercent: number) => {
    const oneTablet = selectedRecipe?.batchSize ?? createForm.batchSize;
    return (oneTablet * Math.max(ratioPercent, 0)) / 100;
  };

  const addDraftRow = () => setBomDraftRows((prev) => [...prev, { materialId: 0, technicalStandard: '', ratioPercent: 0, quantity: 0 }]);
  const removeDraftRow = (idx: number) => setBomDraftRows((prev) => prev.filter((_, i) => i !== idx));

  const saveDraftRows = async () => {
    const validRows = bomDraftRows.filter((r) => r.materialId > 0 && r.quantity > 0);
    if (!validRows.length) {
      alert('Vui lòng nhập ít nhất 1 dòng nguyên liệu hợp lệ.');
      return;
    }
    for (const row of validRows) {
      await addBomMutation.mutateAsync(row);
    }
    setBomDraftRows([{ materialId: 0, technicalStandard: '', ratioPercent: 0, quantity: 0 }]);
  };

  const openCreateRouting = () => {
    setEditingRouting(null);
    setRoutingForm({
      stepNumber: routingSteps.length + 1,
      stepName: '',
      defaultEquipmentId: 0,
      materialId: 0,
      areaId: 0,
      estimatedTimeMinutes: 0,
      cleanlinessStatus: 'Sạch',
      standardTemperature: 25,
      standardHumidity: 60,
      standardPressure: 15,
      stabilityStatus: 'Ổn định',
      setTemperature: 25,
      setTimeMinutes: 0,
      description: '',
    });
    setShowRoutingModal(true);
  };

  const openEditRouting = (item: UiRouting) => {
    setEditingRouting(item);
    setRoutingForm({
      stepNumber: item.stepNumber,
      stepName: item.stepName,
      defaultEquipmentId: item.defaultEquipmentId ?? 0,
      materialId: item.materialId ?? 0,
      areaId: item.areaId ?? 0,
      estimatedTimeMinutes: item.estimatedTimeMinutes,
      cleanlinessStatus: item.cleanlinessStatus ?? 'Sạch',
      standardTemperature: item.standardTemperature ?? 25,
      standardHumidity: item.standardHumidity ?? 60,
      standardPressure: item.standardPressure ?? 15,
      stabilityStatus: item.stabilityStatus ?? 'Ổn định',
      setTemperature: item.setTemperature ?? 25,
      setTimeMinutes: item.setTimeMinutes ?? item.estimatedTimeMinutes ?? 0,
      description: item.description ?? '',
    });
    setShowRoutingModal(true);
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-neutral-900">Quản lý công thức sản xuất viên nang</h1>
        <p className="text-neutral-500 mt-1">Lập định mức nguyên liệu và quy trình công đoạn theo tiêu chuẩn GMP</p>
      </div>

      <div className="card space-y-4">
        <h2 className="text-lg font-semibold text-neutral-900">Thêm công thức mới</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
          <div>
            <label className="text-xs text-neutral-500">Chọn thành phẩm mong muốn</label>
            <select className="input" value={createForm.materialId} onChange={(e) => setCreateForm({ ...createForm, materialId: Number(e.target.value) })}>
              <option value={0}>Chọn thành phẩm mong muốn</option>
              {finishedMaterials.map((m) => <option key={m.materialId} value={m.materialId}>{m.materialCode} - {m.materialName}</option>)}
            </select>
          </div>
          <div>
            <label className="text-xs text-neutral-500">Khối lượng 1 viên (mg)</label>
            <input type="number" className="input" value={createForm.batchSize} onChange={(e) => setCreateForm({ ...createForm, batchSize: Number(e.target.value) })} />
          </div>
          <div className="flex items-end">
            <button className="btn-primary w-full" onClick={() => createRecipeMutation.mutate()} disabled={createForm.materialId <= 0 || createForm.batchSize <= 0}>
              <Plus className="w-4 h-4 mr-2" />Tạo công thức
            </button>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="card lg:col-span-1">
          <div className="relative mb-4">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
            <input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Tìm công thức..." className="input pl-9" />
          </div>
          {isLoading ? <p className="text-sm text-neutral-500">Đang tải dữ liệu...</p> : (
            <div className="space-y-2 max-h-[560px] overflow-y-auto pr-1">
              {filteredRecipes.map((recipe) => (
                <button key={recipe.recipeId} onClick={() => setSelectedRecipeId(recipe.recipeId)} className={`w-full text-left p-3 rounded-lg border transition ${selectedRecipeId === recipe.recipeId ? 'border-primary-300 bg-primary-50' : 'border-neutral-200 hover:border-primary-200'}`}>
                  <p className="font-semibold text-neutral-900">Công thức #{recipe.recipeId}</p>
                  <p className="text-sm text-neutral-600 truncate">{recipe.materialName ?? '-'}</p>
                  <p className="text-xs mt-1 text-neutral-500">Trạng thái: {recipe.status}</p>
                </button>
              ))}
            </div>
          )}
        </div>

        <div className="card lg:col-span-2">
          {!selectedRecipe ? <p className="text-sm text-neutral-500">Chọn một công thức để quản lý.</p> : (
            <div className="space-y-6">
              <div className="flex items-start justify-between gap-3">
                <div>
                  <h2 className="text-xl font-bold text-neutral-900">Công thức #{selectedRecipe.recipeId} - {selectedRecipe.materialName}</h2>
                  <p className="text-sm text-neutral-600 mt-1">Version v{selectedRecipe.versionNumber} | Trạng thái: {selectedRecipe.status}</p>
                  <p className="text-sm text-neutral-600">Khối lượng 1 viên: <strong>{selectedRecipe.batchSize.toLocaleString()} mg</strong></p>
                </div>
                <div className="flex gap-2">
                  {selectedRecipe.status === 'Draft' && <button className="btn-secondary text-sm" onClick={() => approveRecipeMutation.mutate(selectedRecipe.recipeId)}><CheckCircle2 className="w-4 h-4 mr-1" /> Approved</button>}
                  <button onClick={() => { if (confirm('Xóa công thức này?')) deleteRecipeMutation.mutate(selectedRecipe.recipeId); }} className="btn-ghost text-sm text-red-600"><Trash2 className="w-4 h-4 mr-1" />Xóa công thức</button>
                </div>
              </div>

              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2"><ListTree className="w-5 h-5 text-primary-600" /><h3 className="text-lg font-semibold text-neutral-900">Lập định mức cho 1 viên thuốc</h3></div>
                  <button onClick={addDraftRow} className="btn-secondary text-sm"><Plus className="w-4 h-4 mr-1" />Thêm dòng</button>
                </div>

                <div className="table-container">
                  <table className="table">
                    <thead>
                      <tr>
                        <th>STT</th>
                        <th>Nguyên liệu</th>
                        <th>Tiêu chuẩn kỹ thuật</th>
                        <th>Tỉ lệ công thức (%)</th>
                        <th>1 viên (mg)</th>
                        <th className="text-right">Thao tác</th>
                      </tr>
                    </thead>
                    <tbody>
                      {bomItems.map((item, idx) => {
                        const ratio = totalPerTabletMg > 0 ? (item.quantity / totalPerTabletMg) * 100 : 0;
                        return (
                          <tr key={`bom-${item.bomId}`}>
                            <td>{idx + 1}</td>
                            <td>{item.materialName}</td>
                            <td>{item.technicalStandard || '-'}</td>
                            <td>{ratio.toFixed(2)}</td>
                            <td>{item.quantity.toFixed(2)}</td>
                            <td className="text-right"><button onClick={() => { if (confirm('Xóa nguyên liệu này?')) deleteBomMutation.mutate(item.bomId); }} className="btn-ghost text-sm text-red-600"><Trash2 className="w-4 h-4 mr-1" />Xóa</button></td>
                          </tr>
                        );
                      })}

                      {bomDraftRows.map((row, idx) => (
                        <tr key={`draft-${idx}`}>
                          <td>+</td>
                          <td>
                            <select className="input" value={row.materialId} onChange={(e) => {
                              const materialId = Number(e.target.value);
                              setBomDraftRows((prev) => prev.map((x, i) => i === idx ? { ...x, materialId } : x));
                            }}>
                              <option value={0}>Chọn nguyên liệu</option>
                              {inputMaterials.map((m) => <option key={m.materialId} value={m.materialId}>{m.materialCode} - {m.materialName}</option>)}
                            </select>
                          </td>
                          <td><input className="input" value={row.technicalStandard} onChange={(e) => setBomDraftRows((prev) => prev.map((x, i) => i === idx ? { ...x, technicalStandard: e.target.value } : x))} placeholder="Ví dụ: USP 30" /></td>
                          <td><input type="number" className="input" value={row.ratioPercent} onChange={(e) => {
                            const ratioPercent = Number(e.target.value);
                            const quantity = recalcMgFromRatio(ratioPercent);
                            setBomDraftRows((prev) => prev.map((x, i) => i === idx ? { ...x, ratioPercent, quantity } : x));
                          }} /></td>
                          <td><input type="number" className="input" value={row.quantity} onChange={(e) => {
                            const quantity = Number(e.target.value);
                            const ratioPercent = selectedRecipe?.batchSize ? (quantity / selectedRecipe.batchSize) * 100 : 0;
                            setBomDraftRows((prev) => prev.map((x, i) => i === idx ? { ...x, quantity, ratioPercent } : x));
                          }} /></td>
                          <td className="text-right"><button className="btn-ghost text-sm text-red-600" onClick={() => removeDraftRow(idx)}><Trash2 className="w-4 h-4 mr-1" />Xóa dòng</button></td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
                <div className="flex justify-end"><button className="btn-primary" onClick={saveDraftRows}>Lưu định mức</button></div>
              </div>

              <div className="space-y-3">
                <div className="flex items-center justify-between"><div className="flex items-center gap-2"><Route className="w-5 h-5 text-primary-600" /><h3 className="text-lg font-semibold text-neutral-900">Quy trình công đoạn</h3></div><button onClick={openCreateRouting} className="btn-secondary text-sm"><Plus className="w-4 h-4 mr-1" />Thêm công đoạn</button></div>
                <div className="table-container">
                  <table className="table">
                    <thead><tr><th>Bước</th><th>Tên công đoạn</th><th>Nguyên liệu</th><th>Phòng sản xuất</th><th>Thiết bị</th><th>Điều kiện</th><th className="text-right">Thao tác</th></tr></thead>
                    <tbody>
                      {routingSteps.length === 0 ? <tr><td colSpan={7} className="text-center text-neutral-500 py-4">Chưa có công đoạn.</td></tr> : routingSteps.map((item) => (
                        <tr key={item.routingId}>
                          <td>{item.stepNumber}</td>
                          <td>{item.stepName}</td>
                          <td>{item.materialName || '-'}</td>
                          <td>{item.areaName || '-'}</td>
                          <td>{item.equipmentName || '-'}</td>
                          <td>{`${item.cleanlinessStatus || '-'} | ${item.standardTemperature ?? '-'}°C | ${item.standardHumidity ?? '-'}% | ${item.standardPressure ?? '-'} Pa`}</td>
                          <td className="text-right"><div className="flex justify-end gap-2"><button onClick={() => openEditRouting(item)} className="btn-ghost text-sm"><Pencil className="w-4 h-4 mr-1" />Sửa</button><button onClick={() => { if (confirm('Xóa công đoạn này?')) deleteRoutingMutation.mutate(item.routingId); }} className="btn-ghost text-sm text-red-600"><Trash2 className="w-4 h-4 mr-1" />Xóa</button></div></td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {showRoutingModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl w-full max-w-3xl p-6 space-y-4">
            <h3 className="text-xl font-bold">{editingRouting ? 'Cập nhật công đoạn' : 'Thêm công đoạn'}</h3>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div><label className="text-xs text-neutral-500">Số bước</label><input type="number" className="input" value={routingForm.stepNumber} onChange={(e) => setRoutingForm({ ...routingForm, stepNumber: Number(e.target.value) })} /></div>
              <div><label className="text-xs text-neutral-500">Tên công đoạn</label><input className="input" value={routingForm.stepName} onChange={(e) => setRoutingForm({ ...routingForm, stepName: e.target.value })} /></div>
              <div><label className="text-xs text-neutral-500">Chọn nguyên liệu</label><select className="input" value={routingForm.materialId} onChange={(e) => setRoutingForm({ ...routingForm, materialId: Number(e.target.value) })}><option value={0}>Chọn nguyên liệu</option>{inputMaterials.map((m) => <option key={m.materialId} value={m.materialId}>{m.materialCode} - {m.materialName}</option>)}</select></div>
              <div><label className="text-xs text-neutral-500">Phòng sản xuất</label><select className="input" value={routingForm.areaId} onChange={(e) => setRoutingForm({ ...routingForm, areaId: Number(e.target.value) })}><option value={0}>Chọn khu vực</option>{areas.map((a) => <option key={a.areaId} value={a.areaId}>{a.areaName}</option>)}</select></div>
              <div><label className="text-xs text-neutral-500">Thiết bị</label><select className="input" value={routingForm.defaultEquipmentId} onChange={(e) => setRoutingForm({ ...routingForm, defaultEquipmentId: Number(e.target.value) })}><option value={0}>Chọn thiết bị</option>{equipments.map((eq) => <option key={eq.equipmentId} value={eq.equipmentId}>{eq.equipmentCode} - {eq.equipmentName}</option>)}</select></div>
              <div><label className="text-xs text-neutral-500">Thời gian dự kiến (phút)</label><input type="number" className="input" value={routingForm.estimatedTimeMinutes} onChange={(e) => setRoutingForm({ ...routingForm, estimatedTimeMinutes: Number(e.target.value) })} /></div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              <div><label className="text-xs text-neutral-500">Sạch/không sạch</label><select className="input" value={routingForm.cleanlinessStatus} onChange={(e) => setRoutingForm({ ...routingForm, cleanlinessStatus: e.target.value })}><option value="Sạch">Sạch</option><option value="Không sạch">Không sạch</option></select></div>
              <div><label className="text-xs text-neutral-500">Nhiệt độ tiêu chuẩn (°C)</label><input type="number" className="input" value={routingForm.standardTemperature} onChange={(e) => setRoutingForm({ ...routingForm, standardTemperature: Number(e.target.value) })} /></div>
              <div><label className="text-xs text-neutral-500">Độ ẩm tiêu chuẩn (%)</label><input type="number" className="input" value={routingForm.standardHumidity} onChange={(e) => setRoutingForm({ ...routingForm, standardHumidity: Number(e.target.value) })} /></div>
              <div><label className="text-xs text-neutral-500">Áp suất (Pa)</label><input type="number" className="input" value={routingForm.standardPressure} onChange={(e) => setRoutingForm({ ...routingForm, standardPressure: Number(e.target.value) })} /></div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div><label className="text-xs text-neutral-500">Ổn định/không ổn định</label><select className="input" value={routingForm.stabilityStatus} onChange={(e) => setRoutingForm({ ...routingForm, stabilityStatus: e.target.value })}><option value="Ổn định">Ổn định</option><option value="Không ổn định">Không ổn định</option></select></div>
              <div><label className="text-xs text-neutral-500">Nhiệt độ cài đặt (°C)</label><input type="number" className="input" value={routingForm.setTemperature} onChange={(e) => setRoutingForm({ ...routingForm, setTemperature: Number(e.target.value) })} /></div>
              <div><label className="text-xs text-neutral-500">Thời gian cài đặt (phút)</label><input type="number" className="input" value={routingForm.setTimeMinutes} onChange={(e) => setRoutingForm({ ...routingForm, setTimeMinutes: Number(e.target.value) })} /></div>
            </div>

            <div><label className="text-xs text-neutral-500">Mô tả</label><textarea className="input min-h-20" value={routingForm.description} onChange={(e) => setRoutingForm({ ...routingForm, description: e.target.value })} /></div>

            <div className="flex justify-end gap-2"><button onClick={() => setShowRoutingModal(false)} className="btn-ghost">Hủy</button><button onClick={() => (editingRouting ? updateRoutingMutation.mutate() : addRoutingMutation.mutate())} className="btn-primary">{editingRouting ? 'Lưu cập nhật' : 'Thêm công đoạn'}</button></div>
          </div>
        </div>
      )}
    </div>
  );
}
