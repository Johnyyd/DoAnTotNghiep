import { useCallback, useEffect, useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { areasApi, equipmentsApi, materialsApi, recipesApi } from '@/services/api';
import { CheckCircle2, ClipboardList, GripVertical, ListTree, Pencil, Plus, Route, Search, Trash2 } from 'lucide-react';

type MaterialOption = { materialId: number; materialCode: string; materialName: string; type: string };
type AreaOption = { areaId: number; areaCode: string; areaName: string };
type EquipmentOption = { equipmentId: number; equipmentName: string; equipmentCode: string; areaId: number; technicalSpecification?: string };

type UiRecipe = { recipeId: number; materialId: number; materialName?: string; batchSize: number; status: string; versionNumber: number };
type UiBom = { bomId: number; materialId: number; materialName: string; quantity: number; technicalStandard?: string; uomId?: number; uomName?: string };
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
  standardTemperature?: string;
  standardHumidity?: string;
  standardPressure?: string;
  stabilityStatus?: string;
  setTemperature?: number;
  setPressure?: number;
  setTimeMinutes?: number;
  description?: string;
  materialIds?: string;
};

type RecipeCreateForm = { materialId: number; batchSize: number };
type RecipeCreateUnit = 'mg' | 'g' | 'kg' | 'ml' | 'l';
type BomDraftRow = { materialId: number; technicalStandard: string; ratioPercent: number; quantity: number; uomId: number };
type BomEditRow = { bomId: number; materialId: number; technicalStandard: string; ratioPercent: number; quantity: number; uomId: number };
type RoutingForm = {
  stepNumber: number;
  stepName: string;
  defaultEquipmentId: number;
  materialId: number;
  areaId: number;
  estimatedTimeMinutes: number;
  cleanlinessStatus: string;
  standardTemperatureMin: string;
  standardTemperatureMax: string;
  standardHumidityMin: string;
  standardHumidityMax: string;
  standardPressureMin: string;
  standardPressureMax: string;
  stabilityStatus: string;
  setTemperature: number;
  setPressure: number;
  setTimeMinutes: number;
  description: string;
  materialIds: number[];
};

type UiTechSpec = { specId: number; recipeId: number; parentId: number | null; sortOrder: number; content: string; isChecked: boolean };

function toRows<T>(raw: unknown): T[] {
  if (Array.isArray(raw)) return raw as T[];
  if (raw && typeof raw === 'object') {
    const obj = raw as { data?: unknown; items?: unknown };
    if (Array.isArray(obj.data)) return obj.data as T[];
    if (Array.isArray(obj.items)) return obj.items as T[];
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
    materialName: item.material?.materialName ?? item.Material?.MaterialName ?? 'Nguyn liu',
    quantity: Number(item.quantity ?? item.Quantity ?? 0),
    technicalStandard: item.technicalStandard ?? item.TechnicalStandard ?? '',
    uomId: Number(item.uomId ?? item.UomId ?? 0) || undefined,
    uomName: item.uom?.uomName ?? item.Uom?.UomName,
  };
}


function isPackagingMaterial(material?: { materialCode?: string; materialName?: string; type?: string }) {
  if (!material) return false;
  const type = String(material.type ?? '').toLowerCase();
  const code = String(material.materialCode ?? '').toLowerCase();
  const name = String(material.materialName ?? '').toLowerCase();
  return type === 'packaging' || code.includes('nlp') || name.includes('vỏ') || name.includes('ống') || name.includes('màng') || name.includes('pvc');
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
    areaName: item.defaultEquipment?.area?.areaName ?? item.DefaultEquipment?.Area?.AreaName ?? item.area?.areaName ?? item.Area?.AreaName,
    estimatedTimeMinutes: Number(item.estimatedTimeMinutes ?? item.EstimatedTimeMinutes ?? 0),
    cleanlinessStatus: item.cleanlinessStatus ?? item.CleanlinessStatus,
    standardTemperature: item.standardTemperature ?? item.StandardTemperature ?? '',
    standardHumidity: item.standardHumidity ?? item.StandardHumidity ?? '',
    standardPressure: item.standardPressure ?? item.StandardPressure ?? '',
    stabilityStatus: item.stabilityStatus ?? item.StabilityStatus,
    setTemperature: (item.setTemperature !== undefined && item.setTemperature !== null) ? Number(item.setTemperature) : (item.SetTemperature !== undefined ? Number(item.SetTemperature) : undefined),
    setPressure: (item.setPressure !== undefined && item.setPressure !== null) ? Number(item.setPressure) : (item.SetPressure !== undefined ? Number(item.SetPressure) : undefined),
    setTimeMinutes: (item.setTimeMinutes !== undefined && item.setTimeMinutes !== null) ? Number(item.setTimeMinutes) : (item.SetTimeMinutes !== undefined ? Number(item.SetTimeMinutes) : undefined),
    description: item.description ?? item.Description ?? '',
    materialIds: item.materialIds ?? item.MaterialIds ?? '',
  };
}

export default function Recipes() {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [selectedRecipeId, setSelectedRecipeId] = useState<number | null>(null);
  const [showRoutingModal, setShowRoutingModal] = useState(false);
  const [editingRouting, setEditingRouting] = useState<UiRouting | null>(null);

  const [createForm, setCreateForm] = useState<RecipeCreateForm>({ materialId: 0, batchSize: 0 });
  const [createUnit, setCreateUnit] = useState<RecipeCreateUnit>('mg');
  const [bomDraftRows, setBomDraftRows] = useState<BomDraftRow[]>([{ materialId: 0, technicalStandard: '', ratioPercent: 0, quantity: 0, uomId: 2 }]);
  const [editingBomRows, setEditingBomRows] = useState<Record<number, BomEditRow>>({});
  const [routingForm, setRoutingForm] = useState<RoutingForm>({
    stepNumber: 1,
    stepName: '',
    defaultEquipmentId: 0,
    materialId: 0,
    areaId: 0,
    estimatedTimeMinutes: 0,
    cleanlinessStatus: 'Sạch',
    standardTemperatureMin: '',
    standardTemperatureMax: '',
    standardHumidityMin: '',
    standardHumidityMax: '',
    standardPressureMin: '',
    standardPressureMax: '',
    stabilityStatus: 'Ổn định',
    setTemperature: 0,
    setPressure: 0,
    setTimeMinutes: 0,
    description: '',
    materialIds: [],
  });

  const { data: recipesRaw, isLoading, isError, error } = useQuery({ 
    queryKey: ['recipes'], 
    queryFn: () => recipesApi.getAll(),
    retry: 1 
  });
  
  if (isError) {
    console.error('Error loading recipes:', error);
  }
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
    areaId: Number(e.areaId ?? e.AreaId ?? 0),
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
  const materialById = useMemo(() => new Map(inputMaterials.map((m) => [m.materialId, m])), [inputMaterials]);
  const allMaterialById = useMemo(() => new Map(materials.map((m) => [m.materialId, m])), [materials]);
  const selectedMaterialIds = useMemo(() => new Set<number>(bomItems.map((i) => i.materialId)), [bomItems]);
  const routingSelectableMaterials = useMemo(
    () => inputMaterials.filter((m) => selectedMaterialIds.has(m.materialId)),
    [inputMaterials, selectedMaterialIds]
  );

  const totalPerTabletMg = useMemo(() => bomItems.reduce((sum, item) => sum + item.quantity, 0), [bomItems]);

  // Tech specs
  const { data: techSpecsRaw } = useQuery({ queryKey: ['techSpecs', selectedRecipeId], queryFn: () => recipesApi.getTechSpecs(selectedRecipeId as number), enabled: !!selectedRecipeId });
  const techSpecs = useMemo<UiTechSpec[]>(() => toRows<any>(techSpecsRaw).map((s: any) => ({
    specId: s.specId ?? s.SpecId ?? 0, recipeId: s.recipeId ?? s.RecipeId ?? 0,
    parentId: s.parentId ?? s.ParentId ?? null, sortOrder: s.sortOrder ?? s.SortOrder ?? 0,
    content: s.content ?? s.Content ?? '', isChecked: !!(s.isChecked ?? s.IsChecked),
  })), [techSpecsRaw]);
  const [newSpecContent, setNewSpecContent] = useState('');
  const [newSubSpecParent, setNewSubSpecParent] = useState<number | null>(null);
  const [newSubSpecContent, setNewSubSpecContent] = useState('');

  // Drag state
  const [dragIdx, setDragIdx] = useState<number | null>(null);

  const reorderMutation = useMutation({
    mutationFn: (items: { routingId: number; stepNumber: number }[]) => recipesApi.reorderRouting(selectedRecipeId as number, items),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['recipeRouting', selectedRecipeId] }),
  });

  const addSpecMutation = useMutation({
    mutationFn: (data: any) => recipesApi.addTechSpec(selectedRecipeId as number, data),
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['techSpecs', selectedRecipeId] }); setNewSpecContent(''); setNewSubSpecContent(''); },
  });
  const updateSpecMutation = useMutation({
    mutationFn: ({ specId, data }: { specId: number; data: any }) => recipesApi.updateTechSpec(selectedRecipeId as number, specId, data),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['techSpecs', selectedRecipeId] }),
  });
  const deleteSpecMutation = useMutation({
    mutationFn: (specId: number) => recipesApi.deleteTechSpec(selectedRecipeId as number, specId),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['techSpecs', selectedRecipeId] }),
  });

  // Drag & drop handlers
  const handleDragStart = useCallback((idx: number) => setDragIdx(idx), []);
  const handleDragOver = useCallback((e: React.DragEvent) => e.preventDefault(), []);
  const handleDrop = useCallback((dropIdx: number) => {
    if (dragIdx === null || dragIdx === dropIdx) { setDragIdx(null); return; }
    const reordered = [...routingSteps];
    const [moved] = reordered.splice(dragIdx, 1);
    reordered.splice(dropIdx, 0, moved);
    const updates = reordered.map((s, i) => ({ routingId: s.routingId, stepNumber: i + 1 }));
    reorderMutation.mutate(updates);
    setDragIdx(null);
  }, [dragIdx, routingSteps, reorderMutation]);

  const createRecipeMutation = useMutation({
    mutationFn: () => {
      const toMg = (value: number, unit: RecipeCreateUnit): number => {
        if (unit === 'mg') return value;
        if (unit === 'g') return value * 1000;
        if (unit === 'kg') return value * 1000000;
        if (unit === 'ml') return value * 1000;
        if (unit === 'l') return value * 1000000;
        return value;
      };
      return recipesApi.create({ materialId: createForm.materialId, batchSize: toMg(createForm.batchSize, createUnit), status: 'Draft', versionNumber: 1 });
    },
    onSuccess: async (response: any) => {
      await queryClient.invalidateQueries({ queryKey: ['recipes'] });
      
      const newId = response?.data?.recipeId ?? response?.recipeId;
      if (newId) {
        setSelectedRecipeId(newId);
      }
      
      setCreateForm({ materialId: 0, batchSize: 0 });
      setCreateUnit('mg');
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
    onError: (err: any) => alert(err?.response?.data?.message ?? err?.message ?? 'Xa cng thc tht bi'),
  });

  const addBomMutation = useMutation({
    mutationFn: (row: BomDraftRow) => recipesApi.addBOMItem(selectedRecipeId as number, {
      materialId: row.materialId,
      quantity: row.quantity,
      uomId: row.uomId,
      technicalStandard: row.technicalStandard,
    } as any),
    onSuccess: async () => queryClient.invalidateQueries({ queryKey: ['recipeBom', selectedRecipeId] }),
  });

  const deleteBomMutation = useMutation({
    mutationFn: (bomId: number) => recipesApi.removeBOMItem(selectedRecipeId as number, bomId),
    onSuccess: async () => queryClient.invalidateQueries({ queryKey: ['recipeBom', selectedRecipeId] }),
  });

  const updateBomMutation = useMutation({
    mutationFn: async (row: BomEditRow) => {
      const material = materialById.get(row.materialId);
      const isPackaging = isPackagingMaterial(material);
      if (!isPackaging && row.ratioPercent > 0 && selectedRecipe?.batchSize) {
        row.quantity = (selectedRecipe.batchSize * row.ratioPercent) / 100;
      }
      await recipesApi.updateBOMItem(selectedRecipeId as number, row.bomId, {
        materialId: row.materialId,
        quantity: row.quantity,
        uomId: row.uomId,
      } as any);

      if (material?.materialId && row.technicalStandard !== undefined) {
        await materialsApi.update(material.materialId, {
          materialId: material.materialId,
          materialCode: material.materialCode,
          materialName: material.materialName,
          type: material.type,
          technicalSpecification: row.technicalStandard,
        } as any);
      }
    },
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['recipeBom', selectedRecipeId] });
      await queryClient.invalidateQueries({ queryKey: ['materials'] });
      setEditingBomRows({});
    },
  });

  const addRoutingMutation = useMutation({
    mutationFn: () => {
      const allowedIds = new Set(routingSelectableMaterials.map((m) => m.materialId));
      const materialIds = routingForm.materialIds.filter((id) => allowedIds.has(id));
      return recipesApi.addRoutingStep(selectedRecipeId as number, {
      ...routingForm,
      materialId: routingForm.materialId > 0 ? routingForm.materialId : null,
      areaId: routingForm.areaId > 0 ? routingForm.areaId : null,
      defaultEquipmentId: routingForm.defaultEquipmentId > 0 ? routingForm.defaultEquipmentId : null,
      standardTemperature: `${routingForm.standardTemperatureMin} - ${routingForm.standardTemperatureMax}`,
      standardHumidity: `${routingForm.standardHumidityMin} - ${routingForm.standardHumidityMax}`,
      standardPressure: `${routingForm.standardPressureMin} - ${routingForm.standardPressureMax}`,
      setTemperature: routingForm.setTemperature,
      setPressure: routingForm.setPressure,
      estimatedTimeMinutes: routingForm.setTimeMinutes,
      materialIds: materialIds.length ? materialIds.join(',') : null,
    } as any);
    },
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['recipeRouting', selectedRecipeId] });
      setShowRoutingModal(false);
      setEditingRouting(null);
    },
    onError: (error: any) => {
      alert(error?.response?.data?.message || error?.message || 'C li xy ra khi lu cng on. Vui lng kim tra li thng tin.');
    }
  });

  const updateRoutingMutation = useMutation({
    mutationFn: () => {
      const allowedIds = new Set(routingSelectableMaterials.map((m) => m.materialId));
      const materialIds = routingForm.materialIds.filter((id) => allowedIds.has(id));
      return recipesApi.updateRoutingStep(selectedRecipeId as number, editingRouting!.routingId, {
      ...routingForm,
      materialId: routingForm.materialId > 0 ? routingForm.materialId : null,
      areaId: routingForm.areaId > 0 ? routingForm.areaId : null,
      defaultEquipmentId: routingForm.defaultEquipmentId > 0 ? routingForm.defaultEquipmentId : null,
      standardTemperature: `${routingForm.standardTemperatureMin} - ${routingForm.standardTemperatureMax}`,
      standardHumidity: `${routingForm.standardHumidityMin} - ${routingForm.standardHumidityMax}`,
      standardPressure: `${routingForm.standardPressureMin} - ${routingForm.standardPressureMax}`,
      setTemperature: routingForm.setTemperature,
      setPressure: routingForm.setPressure,
      estimatedTimeMinutes: routingForm.setTimeMinutes,
      materialIds: materialIds.length ? materialIds.join(',') : null,
    } as any);
    },
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['recipeRouting', selectedRecipeId] });
      setShowRoutingModal(false);
      setEditingRouting(null);
    },
    onError: (error: any) => {
      alert(error?.response?.data?.message || error?.message || 'C li xy ra khi lu cng on. Vui lng kim tra li thng tin.');
    }
  });

  const deleteRoutingMutation = useMutation({
    mutationFn: (routingId: number) => recipesApi.removeRoutingStep(selectedRecipeId as number, routingId),
    onSuccess: async () => queryClient.invalidateQueries({ queryKey: ['recipeRouting', selectedRecipeId] }),
  });

  const recalcMgFromRatio = (ratioPercent: number) => {
    const oneTablet = selectedRecipe?.batchSize ?? createForm.batchSize;
    return (oneTablet * Math.max(ratioPercent, 0)) / 100;
  };

  const addDraftRow = () => setBomDraftRows((prev) => [...prev, { materialId: 0, technicalStandard: '', ratioPercent: 0, quantity: 0, uomId: 2 }]);
  const removeDraftRow = (idx: number) => setBomDraftRows((prev) => prev.filter((_, i) => i !== idx));

  const beginEditBom = (item: UiBom) => {
    const material = materialById.get(item.materialId);
    const isPackaging = isPackagingMaterial(material);
    const ratioPercent = !isPackaging && selectedRecipe?.batchSize ? (item.quantity / selectedRecipe.batchSize) * 100 : 0;
    setEditingBomRows((prev) => ({
      ...prev,
      [item.bomId]: {
        bomId: item.bomId,
        materialId: item.materialId,
        technicalStandard: item.technicalStandard ?? '',
        ratioPercent,
        quantity: item.quantity,
        uomId: item.uomId ?? (isPackaging ? 4 : 2),
      },
    }));
  };

  const cancelEditBom = (bomId: number) => {
    setEditingBomRows((prev) => {
      const clone = { ...prev };
      delete clone[bomId];
      return clone;
    });
  };

  const saveDraftRows = async () => {
    const validRows = bomDraftRows.filter((r) => r.materialId > 0 && r.quantity > 0);
    if (!validRows.length) {
      alert('Vui lòng nhập ít nhất 1 dòng nguyên liệu hợp lệ.');
      return;
    }

    const uniqueRows = new Set<number>();
    for (const row of validRows) {
      if (selectedMaterialIds.has(row.materialId) || uniqueRows.has(row.materialId)) {
        alert('Có nguyên liệu bị trùng trong danh sách. Vui lòng chỉ giữ mỗi nguyên liệu 1 dòng.');
        return;
      }
      uniqueRows.add(row.materialId);
    }

    for (const row of validRows) {
      await addBomMutation.mutateAsync(row);
      const material = materialById.get(row.materialId);
      if (material) {
        await materialsApi.update(material.materialId, {
          materialId: material.materialId,
          materialCode: material.materialCode,
          materialName: material.materialName,
          type: material.type,
          technicalSpecification: row.technicalStandard,
        } as any);
      }
    }
    setBomDraftRows([{ materialId: 0, technicalStandard: '', ratioPercent: 0, quantity: 0, uomId: 2 }]);
    await queryClient.invalidateQueries({ queryKey: ['materials'] });
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
      standardTemperatureMin: '',
      standardTemperatureMax: '',
      standardHumidityMin: '',
      standardHumidityMax: '',
      standardPressureMin: '',
      standardPressureMax: '',
      stabilityStatus: 'ổn định',
      setTemperature: 0,
      setPressure: 0,
      setTimeMinutes: 0,
      description: '',
      materialIds: [],
    });
    setShowRoutingModal(true);
  };

  const openEditRouting = (item: UiRouting) => {
    setEditingRouting(item);
    const allowedIds = new Set(routingSelectableMaterials.map((m) => m.materialId));
    const filteredIds = item.materialIds
      ? item.materialIds.split(',').map(Number).filter((id) => Number.isFinite(id) && allowedIds.has(id))
      : [];
    setRoutingForm({
      stepNumber: item.stepNumber,
      stepName: item.stepName,
      defaultEquipmentId: item.defaultEquipmentId ?? 0,
      materialId: item.materialId ?? 0,
      areaId: item.areaId ?? 0,
      estimatedTimeMinutes: item.estimatedTimeMinutes,
      cleanlinessStatus: item.cleanlinessStatus ?? 'Sch',
      standardTemperatureMin: item.standardTemperature ? item.standardTemperature.split('-')[0]?.trim() ?? '' : '',
      standardTemperatureMax: item.standardTemperature ? item.standardTemperature.split('-')[1]?.trim() ?? '' : '',
      standardHumidityMin: item.standardHumidity ? item.standardHumidity.split('-')[0]?.trim() ?? '' : '',
      standardHumidityMax: item.standardHumidity ? item.standardHumidity.split('-')[1]?.trim() ?? '' : '',
      standardPressureMin: item.standardPressure ? item.standardPressure.split('-')[0]?.trim() ?? '' : '',
      standardPressureMax: item.standardPressure ? item.standardPressure.split('-')[1]?.trim() ?? '' : '',
      stabilityStatus: item.stabilityStatus ?? 'n nh',
      setTemperature: item.setTemperature ?? 0,
      setPressure: item.setPressure ?? 0,
      setTimeMinutes: item.setTimeMinutes ?? item.estimatedTimeMinutes ?? 0,
      description: item.description ?? '',
      materialIds: filteredIds,
    });
    setShowRoutingModal(true);
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-neutral-900">Quản lý công thức sản xuất viên nang</h1>
        <p className="text-neutral-500 mt-1">Lập định mức nguyên liệu và quy trình công đoạn theo tiêu chuẩn GMP</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Left: Create form */}
        <div className="card self-start space-y-3">
          <h2 className="text-base font-semibold text-neutral-900">Thêm công thức mới</h2>
          <div>
            <label className="text-xs text-neutral-500">Chọn thành phẩm mong muốn</label>
            <select className="input mt-1" value={createForm.materialId} onChange={(e) => setCreateForm({ ...createForm, materialId: Number(e.target.value) })}>
              <option value={0}>Chọn thành phẩm mong muốn</option>
              {finishedMaterials.map((m) => <option key={m.materialId} value={m.materialId}>{m.materialCode} - {m.materialName}</option>)}
            </select>
          </div>
          <div>
            <label className="text-xs text-neutral-500">Kh?i l??ng 1 vi?n</label>
            <div className="mt-1 grid grid-cols-[1fr_120px] gap-2">
              <input type="number" className="input" value={createForm.batchSize} onChange={(e) => setCreateForm({ ...createForm, batchSize: Number(e.target.value) })} />
              <select className="input" value={createUnit} onChange={(e) => setCreateUnit(e.target.value as RecipeCreateUnit)}>
                <option value="mg">mg</option>
                <option value="g">g</option>
                <option value="kg">kg</option>
                <option value="ml">ml</option>
                <option value="l">L</option>
              </select>
            </div>
          </div>
          <button className="btn-primary w-full" onClick={() => createRecipeMutation.mutate()} disabled={createForm.materialId <= 0 || createForm.batchSize <= 0}>
            <Plus className="w-4 h-4 mr-2" />Tạo công thức
          </button>
        </div>

        {/* Right: Recipe list */}
        <div className="card self-start">
          <h2 className="text-base font-semibold text-neutral-900 mb-2">Danh sách công thức</h2>
          <div className="relative mb-2">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
            <input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Tìm công thức..." className="input pl-9" />
          </div>
          {isLoading ? <p className="text-sm text-neutral-500 italic animate-pulse">ang ti d liu...</p> : isError ? (
            <div className="p-3 bg-red-50 border border-red-200 rounded-lg text-red-600 text-xs">
              Lỗi khi tải danh sách. Vui lòng kiểm tra Backend.
            </div>
          ) : filteredRecipes.length === 0 ? (
            <p className="text-sm text-neutral-400 italic">Không tìm thấy công thức nào.</p>
          ) : (
            <div className="space-y-1.5 max-h-[200px] overflow-y-auto pr-1">
              {filteredRecipes.map((recipe) => (
                <button key={recipe.recipeId} onClick={() => setSelectedRecipeId(recipe.recipeId)} className={`w-full text-left px-3 py-2 rounded-lg border transition text-sm ${selectedRecipeId === recipe.recipeId ? 'border-primary-300 bg-primary-50' : 'border-neutral-200 hover:border-primary-200'}`}>
                  <p className="font-semibold text-neutral-900 truncate">#{recipe.recipeId} - {recipe.materialName ?? '-'}</p>
                  <p className="text-xs text-neutral-500">{recipe.status}</p>
                </button>
              ))}
            </div>
          )}
        </div>
      </div>

      <div className="card">
          {!selectedRecipe ? <p className="text-sm text-neutral-500">Chn mt cng thc  qun l.</p> : (
            <div className="space-y-6">
              <div className="flex items-start justify-between gap-3">
                <div>
                  <h2 className="text-xl font-bold text-neutral-900">Công thức #{selectedRecipe.recipeId} - {selectedRecipe.materialName}</h2>
                  <p className="text-sm text-neutral-600">Khối lượng 1 viên: <strong>{selectedRecipe.batchSize.toLocaleString()} mg</strong></p>
                </div>
                <div className="flex gap-2">
                  {selectedRecipe.status === 'Draft' && <button className="btn-secondary text-sm" onClick={() => approveRecipeMutation.mutate(selectedRecipe.recipeId)}><CheckCircle2 className="w-4 h-4 mr-1" /> Approved</button>}
                  <button onClick={() => { if (confirm('Xa cng thc ny?')) deleteRecipeMutation.mutate(selectedRecipe.recipeId); }} className="btn-ghost text-sm text-red-600"><Trash2 className="w-4 h-4 mr-1" />Xa cng thc</button>
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
                        const material = materialById.get(item.materialId);
                        const isPackaging = isPackagingMaterial(material);
                        const editing = editingBomRows[item.bomId];
                        const ratio = totalPerTabletMg > 0 ? (item.quantity / totalPerTabletMg) * 100 : 0;
                        return (
                          <tr key={`bom-${item.bomId}`}>
                            <td>{idx + 1}</td>
                            <td>
                              {editing ? (
                                <select className="input" value={editing.materialId} onChange={(e) => {
                                  const materialId = Number(e.target.value);
                                  const nextMaterial = materialById.get(materialId);
                                  const nextPackaging = isPackagingMaterial(nextMaterial);
                                  setEditingBomRows((prev) => ({
                                    ...prev,
                                    [item.bomId]: {
                                      ...prev[item.bomId],
                                      materialId,
                                      uomId: nextPackaging ? 4 : 2,
                                      ratioPercent: nextPackaging ? 0 : prev[item.bomId].ratioPercent,
                                      quantity: nextPackaging ? Math.max(1, Math.round(prev[item.bomId].quantity || 1)) : prev[item.bomId].quantity,
                                    },
                                  }));
                                }}>
                                  {inputMaterials.filter((m) => m.materialId === editing.materialId || !selectedMaterialIds.has(m.materialId)).map((m) => (
                                    <option key={m.materialId} value={m.materialId}>{m.materialCode} - {m.materialName}</option>
                                  ))}
                                </select>
                              ) : item.materialName}
                            </td>
                            <td>{editing ? <input className="input" value={editing.technicalStandard} onChange={(e) => setEditingBomRows((prev) => ({ ...prev, [item.bomId]: { ...prev[item.bomId], technicalStandard: e.target.value } }))} /> : (item.technicalStandard || '-')}</td>
                            <td>
                              {editing ? (
                                <input type="number" className="input" disabled={isPackagingMaterial(materialById.get(editing.materialId))} value={editing.ratioPercent} onChange={(e) => {
                                  const ratioPercent = Number(e.target.value);
                                  const quantity = recalcMgFromRatio(ratioPercent);
                                  setEditingBomRows((prev) => ({ ...prev, [item.bomId]: { ...prev[item.bomId], ratioPercent, quantity } }));
                                }} />
                              ) : (
                                isPackaging ? '-' : ratio.toFixed(2)
                              )}
                            </td>
                            <td>{editing ? <input type="number" step={isPackagingMaterial(materialById.get(editing.materialId)) ? 1 : 0.01} className="input" value={editing.quantity} onChange={(e) => {
                              const currentPackaging = isPackagingMaterial(materialById.get(editing.materialId));
                              const quantityInput = Number(e.target.value);
                              const quantity = currentPackaging ? Math.max(1, Math.round(quantityInput)) : quantityInput;
                              const ratioPercent = currentPackaging ? 0 : (selectedRecipe?.batchSize ? (quantity / selectedRecipe.batchSize) * 100 : 0);
                              setEditingBomRows((prev) => ({ ...prev, [item.bomId]: { ...prev[item.bomId], quantity, ratioPercent } }));
                            }} /> : item.quantity.toFixed(2)}</td>
                            <td className="text-right">
                              {editing ? (
                                <div className="flex justify-end gap-2">
                                  <button className="btn-secondary text-xs" onClick={() => updateBomMutation.mutate(editing)}>Lưu</button>
                                  <button className="btn-ghost text-xs" onClick={() => cancelEditBom(item.bomId)}>Há»§y</button>
                                </div>
                              ) : (
                                <div className="flex justify-end gap-2">
                                  <button className="btn-ghost text-sm" onClick={() => beginEditBom(item)}><Pencil className="w-4 h-4 mr-1" />Sá»­a</button>
                                  <button onClick={() => { if (confirm('Xa nguyn liu ny?')) deleteBomMutation.mutate(item.bomId); }} className="btn-ghost text-sm text-red-600"><Trash2 className="w-4 h-4 mr-1" />Xa</button>
                                </div>
                              )}
                            </td>
                          </tr>
                        );
                      })}

                      {bomDraftRows.map((row, idx) => (
                        <tr key={`draft-${idx}`}>
                          <td>+</td>
                          <td>
                            <select className="input" value={row.materialId} onChange={(e) => {
                              const materialId = Number(e.target.value);
                              const material = materialById.get(materialId);
                              const isPackaging = isPackagingMaterial(material);
                              setBomDraftRows((prev) => prev.map((x, i) => i === idx ? { ...x, materialId, ratioPercent: isPackaging ? 0 : x.ratioPercent, quantity: isPackaging ? Math.max(1, Math.round(x.quantity || 1)) : x.quantity, uomId: isPackaging ? 4 : 2 } : x));
                            }}>
                              <option value={0}>Chọn nguyên liệu</option>
                              {inputMaterials.filter((m) => !selectedMaterialIds.has(m.materialId) && !bomDraftRows.some((r, rIndex) => rIndex !== idx && r.materialId === m.materialId)).map((m) => <option key={m.materialId} value={m.materialId}>{m.materialCode} - {m.materialName}</option>)}
                            </select>
                          </td>
                          <td><input className="input" value={row.technicalStandard} onChange={(e) => setBomDraftRows((prev) => prev.map((x, i) => i === idx ? { ...x, technicalStandard: e.target.value } : x))} placeholder="V d: USP 30" /></td>
                          <td><input type="number" className="input" disabled={isPackagingMaterial(materialById.get(row.materialId))} value={row.ratioPercent} onChange={(e) => {
                            const ratioPercent = Number(e.target.value);
                            const quantity = recalcMgFromRatio(ratioPercent);
                            setBomDraftRows((prev) => prev.map((x, i) => i === idx ? { ...x, ratioPercent, quantity } : x));
                          }} /></td>
                          <td><input type="number" step={isPackagingMaterial(materialById.get(row.materialId)) ? 1 : 0.01} className="input" value={row.quantity} onChange={(e) => {
                            const isPackaging = isPackagingMaterial(materialById.get(row.materialId));
                            const quantityInput = Number(e.target.value);
                            const quantity = isPackaging ? Math.max(1, Math.round(quantityInput)) : quantityInput;
                            const ratioPercent = isPackaging ? 0 : (selectedRecipe?.batchSize ? (quantity / selectedRecipe.batchSize) * 100 : 0);
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
                    <thead><tr><th className="w-8"></th><th className="w-12 text-center">Bước</th><th>Tên công đoạn</th><th>Nguyên liệu</th><th>Phòng sản xuất</th><th>Thiết bị</th><th>Điều kiện</th><th className="text-right w-24">Thao tác</th></tr></thead>
                    <tbody>
                      {routingSteps.length === 0 ? <tr><td colSpan={8} className="text-center text-neutral-500 py-4">Cha c cng on.</td></tr> : routingSteps.map((item, idx) => {
                        // Resolve multi-material names
                        const matNames: string[] = [];
                        if (item.materialIds) {
                          item.materialIds.split(',').forEach((idStr) => {
                            const mid = Number(idStr.trim());
                            if (mid) { const m = allMaterialById.get(mid); if (m) matNames.push(m.materialName); }
                          });
                        }
                        if (!matNames.length && item.materialName) matNames.push(item.materialName);
                        return (
                        <tr key={item.routingId} draggable onDragStart={() => handleDragStart(idx)} onDragOver={handleDragOver} onDrop={() => handleDrop(idx)} className={`cursor-grab ${dragIdx === idx ? 'opacity-40' : ''}`}>
                          <td className="text-center"><GripVertical className="w-4 h-4 text-neutral-300 inline-block" /></td>
                          <td className="text-center font-mono text-sm">{item.stepNumber}</td>
                          <td>{item.stepName}</td>
                          <td>{matNames.length ? matNames.join(', ') : '-'}</td>
                          <td>{item.areaName || '-'}</td>
                          <td>{item.equipmentName || '-'}</td>
                          <td>
                            <div className="flex flex-col text-xs text-neutral-600 gap-0.5">
                              <span>Nhit : <b>{item.standardTemperature ?? '-'}C</b></span>
                              <span> m: <b>{item.standardHumidity ?? '-'}%</b></span>
                              <span>p sut: <b>{item.standardPressure ?? '-'} Pa</b></span>
                            </div>
                          </td>
                          <td className="text-right"><div className="flex justify-end gap-1"><button onClick={() => openEditRouting(item)} className="p-1.5 text-neutral-500 hover:text-primary-600 hover:bg-primary-50 rounded"><Pencil className="w-4 h-4" /></button><button onClick={() => { if (confirm('Xa cng on ny?')) deleteRoutingMutation.mutate(item.routingId); }} className="p-1.5 text-neutral-500 hover:text-red-600 hover:bg-red-50 rounded"><Trash2 className="w-4 h-4" /></button></div></td>
                        </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              </div>

              {/* Tech Specs */}
              <div className="space-y-3">
                <div className="flex items-center gap-2"><ClipboardList className="w-5 h-5 text-primary-600" /><h3 className="text-lg font-semibold text-neutral-900">Tiêu chuẩn kỹ thuật</h3></div>
                <div className="space-y-1">
                  {techSpecs.length === 0 && (
                    <div className="text-sm text-neutral-500 px-2 py-2 border border-dashed border-neutral-300 rounded-lg">
                      Chưa có tiêu chuẩn kỹ thuật. Bạn có thể thêm mới ngay bên dưới.
                    </div>
                  )}
                  {techSpecs.filter(s => !s.parentId).map((spec) => (
                    <div key={spec.specId}>
                      <div className="flex items-center gap-2 py-1.5 px-2 rounded hover:bg-neutral-50 group">
                        <input type="checkbox" checked={spec.isChecked} onChange={(e) => updateSpecMutation.mutate({ specId: spec.specId, data: { ...spec, isChecked: e.target.checked } })} className="w-4 h-4 accent-primary-600" />
                        <span className="flex-1 text-sm text-neutral-800">{spec.content}</span>
                        <button onClick={() => setNewSubSpecParent(newSubSpecParent === spec.specId ? null : spec.specId)} className="opacity-0 group-hover:opacity-100 text-xs text-primary-600 hover:underline">+ Thm</button>
                        <button onClick={() => { if (confirm('Xa tiu chun ny?')) deleteSpecMutation.mutate(spec.specId); }} className="opacity-0 group-hover:opacity-100 p-1 text-neutral-400 hover:text-red-500"><Trash2 className="w-3.5 h-3.5" /></button>
                      </div>
                      {/* Sub-specs */}
                      {techSpecs.filter(sub => sub.parentId === spec.specId).map((sub) => (
                        <div key={sub.specId} className="flex items-center gap-2 py-1 px-2 ml-8 rounded hover:bg-neutral-50 group">
                          <input type="checkbox" checked={sub.isChecked} onChange={(e) => updateSpecMutation.mutate({ specId: sub.specId, data: { ...sub, isChecked: e.target.checked } })} className="w-4 h-4 accent-primary-600" />
                          <span className="flex-1 text-sm text-neutral-700">{sub.content}</span>
                          <button onClick={() => { if (confirm('Xa?')) deleteSpecMutation.mutate(sub.specId); }} className="opacity-0 group-hover:opacity-100 p-1 text-neutral-400 hover:text-red-500"><Trash2 className="w-3.5 h-3.5" /></button>
                        </div>
                      ))}
                      {/* Add sub-spec input */}
                      {newSubSpecParent === spec.specId && (
                        <div className="flex items-center gap-2 ml-8 mt-1">
                          <input className="input flex-1 text-sm" value={newSubSpecContent} onChange={(e) => setNewSubSpecContent(e.target.value)} onKeyDown={(e) => { if (e.key === 'Enter' && newSubSpecContent.trim()) { addSpecMutation.mutate({ parentId: spec.specId, sortOrder: techSpecs.filter(s => s.parentId === spec.specId).length, content: newSubSpecContent.trim(), isChecked: false }); setNewSubSpecContent(''); }}} />
                          <button className="btn-secondary text-xs" onClick={() => { if (newSubSpecContent.trim()) { addSpecMutation.mutate({ parentId: spec.specId, sortOrder: techSpecs.filter(s => s.parentId === spec.specId).length, content: newSubSpecContent.trim(), isChecked: false }); setNewSubSpecContent(''); }}}>Thêm</button>
                        </div>
                      )}
                    </div>
                  ))}
                </div>
                {/* Add top-level spec */}
                <div className="flex items-center gap-2">
                  <input className="input flex-1" placeholder="Nhập tiêu chuẩn kỹ thuật mới..." value={newSpecContent} onChange={(e) => setNewSpecContent(e.target.value)} onKeyDown={(e) => { if (e.key === 'Enter' && newSpecContent.trim()) { addSpecMutation.mutate({ parentId: null, sortOrder: techSpecs.filter(s => !s.parentId).length, content: newSpecContent.trim(), isChecked: false }); }}} />
                  <button className="btn-primary text-sm" disabled={!newSpecContent.trim()} onClick={() => { if (newSpecContent.trim()) addSpecMutation.mutate({ parentId: null, sortOrder: techSpecs.filter(s => !s.parentId).length, content: newSpecContent.trim(), isChecked: false }); }}><Plus className="w-4 h-4 mr-1" />Thêm</button>
                </div>
              </div>
            </div>
          )}
        </div>

      {showRoutingModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4" onClick={() => setShowRoutingModal(false)}>
          <div className="bg-white rounded-2xl w-full max-w-5xl p-6 space-y-4" onClick={(e) => e.stopPropagation()}>
            <h3 className="text-xl font-bold">{editingRouting ? 'Cp nht cng on' : 'Thm cng on'}</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-6 gap-4">
              <div><label className="text-xs text-neutral-500">Số bước</label><input type="number" className="input" value={routingForm.stepNumber} onChange={(e) => setRoutingForm({ ...routingForm, stepNumber: Number(e.target.value) })} /></div>
              <div className="lg:col-span-2"><label className="text-xs text-neutral-500">Tên công đoạn</label><input className="input" value={routingForm.stepName} onChange={(e) => setRoutingForm({ ...routingForm, stepName: e.target.value })} /></div>
              <div className="lg:col-span-3">
                <label className="text-xs text-neutral-500">Chọn nguyên liệu ({routingForm.materialIds.length} đã chọn)</label>
                <div className="flex items-center gap-2 mt-1 mb-2">
                  <button
                    type="button"
                    className="btn-ghost text-xs px-2 py-1"
                    onClick={() =>
                      setRoutingForm({
                        ...routingForm,
                        materialIds: routingSelectableMaterials.map((m) => m.materialId),
                        materialId: routingSelectableMaterials[0]?.materialId ?? 0,
                      })
                    }
                  >
                    Chọn tất cả
                  </button>
                  <button
                    type="button"
                    className="btn-ghost text-xs px-2 py-1"
                    onClick={() => setRoutingForm({ ...routingForm, materialIds: [], materialId: 0 })}
                  >
                    Bỏ chọn
                  </button>
                </div>
                <div className="border border-neutral-200 rounded-lg max-h-[150px] overflow-y-auto p-2 space-y-1">
                  {routingSelectableMaterials.map((m) => (
                    <label key={m.materialId} className="flex items-center gap-2 text-sm cursor-pointer hover:bg-neutral-50 px-1 py-0.5 rounded">
                      <input type="checkbox" checked={routingForm.materialIds.includes(m.materialId)} onChange={(e) => {
                        const ids = e.target.checked ? [...routingForm.materialIds, m.materialId] : routingForm.materialIds.filter(id => id !== m.materialId);
                        setRoutingForm({ ...routingForm, materialIds: ids, materialId: ids[0] ?? 0 });
                      }} className="w-3.5 h-3.5 accent-primary-600" />
                      <span>{m.materialCode} - {m.materialName}</span>
                    </label>
                  ))}
                  {routingSelectableMaterials.length === 0 && (
                    <p className="text-xs text-neutral-500 px-1 py-1">Chưa có nguyên liệu trong phần định mức bên trên.</p>
                  )}
                </div>
              </div>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div><label className="text-xs text-neutral-500">Phòng sản xuất</label><select className="input" value={routingForm.areaId} onChange={(e) => {
                setRoutingForm({ ...routingForm, areaId: Number(e.target.value), defaultEquipmentId: 0 });
              }}><option value={0}>Chọn khu vực</option>{areas.map((a) => <option key={a.areaId} value={a.areaId}>{a.areaName}</option>)}</select></div>
              <div><label className="text-xs text-neutral-500">Thit b</label><select className="input disabled:opacity-50" value={routingForm.defaultEquipmentId} disabled={routingForm.areaId === 0} onChange={(e) => setRoutingForm({ ...routingForm, defaultEquipmentId: Number(e.target.value) })}><option value={0}>{routingForm.areaId === 0 ? 'Vui lng chn phng trc' : 'Chn thit b'}</option>{equipments.filter(e => e.areaId === routingForm.areaId).map((eq) => <option key={eq.equipmentId} value={eq.equipmentId}>{eq.equipmentCode} - {eq.equipmentName}</option>)}</select></div>
            </div>

            {(() => {
              const currentEquipment = equipments.find((e) => e.equipmentId === routingForm.defaultEquipmentId);
              const eqName = currentEquipment ? currentEquipment.equipmentName.toLowerCase() : '';
              const isWeighting = eqName.includes('cân điện tử');
              const isPackaging = /máy đóng nang|máy lau nang|máy in số lô|máy gấp toa|máy đóng chai/i.test(eqName);
              const disableTime = isWeighting;
              const disableSetParams = isWeighting || isPackaging;

              return (
                <>
                  <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
                    <div>
                      <label className="text-xs text-neutral-500">Nhiệt độ tiêu chuẩn (°C)</label>
                      <div className="flex gap-2">
                        <input type="text" className="input text-center" placeholder="Min" value={routingForm.standardTemperatureMin} onChange={(e) => setRoutingForm({ ...routingForm, standardTemperatureMin: e.target.value })} />
                        <span className="text-neutral-400 self-center">-</span>
                        <input type="text" className="input text-center" placeholder="Max" value={routingForm.standardTemperatureMax} onChange={(e) => setRoutingForm({ ...routingForm, standardTemperatureMax: e.target.value })} />
                      </div>
                    </div>
                    <div>
                      <label className="text-xs text-neutral-500">Độ ẩm tiêu chuẩn (%)</label>
                      <div className="flex gap-2">
                        <input type="text" className="input text-center" placeholder="Min" value={routingForm.standardHumidityMin} onChange={(e) => setRoutingForm({ ...routingForm, standardHumidityMin: e.target.value })} />
                        <span className="text-neutral-400 self-center">-</span>
                        <input type="text" className="input text-center" placeholder="Max" value={routingForm.standardHumidityMax} onChange={(e) => setRoutingForm({ ...routingForm, standardHumidityMax: e.target.value })} />
                      </div>
                    </div>
                    <div>
                      <label className="text-xs text-neutral-500">Áp suất tiêu chuẩn (Pa)</label>
                      <div className="flex gap-2">
                        <input type="text" className="input text-center" placeholder="Min" value={routingForm.standardPressureMin} onChange={(e) => setRoutingForm({ ...routingForm, standardPressureMin: e.target.value })} />
                        <span className="text-neutral-400 self-center">-</span>
                        <input type="text" className="input text-center" placeholder="Max" value={routingForm.standardPressureMax} onChange={(e) => setRoutingForm({ ...routingForm, standardPressureMax: e.target.value })} />
                      </div>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div><label className="text-xs text-neutral-500">Thời gian cài đặt (phút)</label><input type="number" className="input disabled:opacity-50 disabled:bg-neutral-100" disabled={disableTime} value={routingForm.setTimeMinutes} onChange={(e) => setRoutingForm({ ...routingForm, setTimeMinutes: Number(e.target.value) })} /></div>
                    <div><label className="text-xs text-neutral-500">Nhiệt độ cài đặt (°C)</label><input type="number" className="input disabled:opacity-50 disabled:bg-neutral-100" disabled={disableSetParams} value={routingForm.setTemperature} onChange={(e) => setRoutingForm({ ...routingForm, setTemperature: Number(e.target.value) })} /></div>
                    <div><label className="text-xs text-neutral-500">Áp suất cài đặt (Pa)</label><input type="number" className="input disabled:opacity-50 disabled:bg-neutral-100" disabled={disableSetParams} value={routingForm.setPressure} onChange={(e) => setRoutingForm({ ...routingForm, setPressure: Number(e.target.value) })} /></div>
                  </div>
                </>
              );
            })()}

            <div>
              <label className="text-xs text-neutral-500">Mô tả</label>
              <textarea className="input min-h-[100px]" value={routingForm.description} onChange={(e) => setRoutingForm({ ...routingForm, description: e.target.value })} />
            </div>


            <div className="flex justify-end gap-2"><button onClick={() => setShowRoutingModal(false)} className="btn-ghost">Hy</button><button onClick={() => (editingRouting ? updateRoutingMutation.mutate() : addRoutingMutation.mutate())} className="btn-primary">{editingRouting ? 'Lu cp nht' : 'Thm cng on'}</button></div>
          </div>
        </div>
      )}
    </div>
  );
}
