import { useEffect, useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { equipmentsApi, materialsApi, productionOrdersApi, recipesApi } from '@/services/api';
import { Plus, Pencil, Trash2, FlaskConical, ListTree, Route, Search, Calculator, Boxes } from 'lucide-react';
import type { Recipe } from '@/types';

type RecipeStatus = Recipe['status'];

type MaterialOption = {
  materialId: number;
  materialCode: string;
  materialName: string;
  baseUomId: number;
};

type EquipmentOption = {
  equipmentId: number;
  equipmentName: string;
};

interface UiRecipe {
  recipeId: number;
  recipeCode: string;
  recipeName: string;
  materialId: number;
  materialName?: string;
  batchSize: number;
  status: RecipeStatus;
  versionNumber: number;
  approvedDate?: string;
  note?: string;
}

interface UiBomItem {
  bomId: number;
  materialId: number;
  materialName: string;
  quantity: number;
  uomId: number;
  uomName: string;
  wastePercentage: number;
  note?: string;
}

interface UiRoutingStep {
  routingId: number;
  stepNumber: number;
  stepName: string;
  defaultEquipmentId?: number;
  equipmentName?: string;
  estimatedTimeMinutes: number;
  description?: string;
}

interface RecipeFormState {
  recipeCode: string;
  recipeName: string;
  materialId: number;
  batchSize: number;
  status: RecipeStatus;
  note: string;
}

interface BomFormState {
  materialId: number;
  quantity: number;
  uomId: number;
  wastePercentage: number;
  note: string;
}

interface RoutingFormState {
  stepNumber: number;
  stepName: string;
  defaultEquipmentId: number;
  estimatedTimeMinutes: number;
  description: string;
}

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
    recipeCode: item.recipeCode ?? item.RecipeCode ?? '',
    recipeName: item.recipeName ?? item.RecipeName ?? '',
    materialId: Number(item.materialId ?? item.MaterialId ?? 0),
    materialName: item.material?.materialName ?? item.Material?.MaterialName,
    batchSize: Number(item.batchSize ?? item.BatchSize ?? 0),
    status: (item.status ?? item.Status ?? 'Draft') as RecipeStatus,
    versionNumber: Number(item.versionNumber ?? item.VersionNumber ?? 1),
    approvedDate: item.approvedDate ?? item.ApprovedDate,
    note: item.note ?? item.Note,
  };
}

function normalizeBom(item: any): UiBomItem {
  return {
    bomId: Number(item.bomId ?? item.BomId ?? 0),
    materialId: Number(item.materialId ?? item.MaterialId ?? 0),
    materialName: item.material?.materialName ?? item.Material?.MaterialName ?? item.materialName ?? 'Nguyên liệu',
    quantity: Number(item.quantity ?? item.Quantity ?? 0),
    uomId: Number(item.uomId ?? item.UomId ?? 1),
    uomName: item.uom?.uomName ?? item.Uom?.UomName ?? item.unit ?? 'mg',
    wastePercentage: Number(item.wastePercentage ?? item.WastePercentage ?? 0),
    note: item.note ?? item.Note,
  };
}

function normalizeRouting(item: any): UiRoutingStep {
  return {
    routingId: Number(item.routingId ?? item.RoutingId ?? 0),
    stepNumber: Number(item.stepNumber ?? item.StepNumber ?? item.stepOrder ?? item.StepOrder ?? 1),
    stepName: item.stepName ?? item.StepName ?? '',
    defaultEquipmentId: Number(item.defaultEquipmentId ?? item.DefaultEquipmentId ?? item.equipmentId ?? item.EquipmentId ?? 0) || undefined,
    equipmentName: item.defaultEquipment?.equipmentName ?? item.DefaultEquipment?.EquipmentName ?? item.equipmentName,
    estimatedTimeMinutes: Number(item.estimatedTimeMinutes ?? item.EstimatedTimeMinutes ?? item.durationMin ?? item.DurationMin ?? 0),
    description: item.description ?? item.Description,
  };
}

const recipeStatuses: RecipeStatus[] = ['Draft', 'Approved', 'InProcess', 'Hold', 'Completed', 'Deprecated'];

export default function Recipes() {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [selectedRecipeId, setSelectedRecipeId] = useState<number | null>(null);

  const [showRecipeModal, setShowRecipeModal] = useState(false);
  const [editingRecipe, setEditingRecipe] = useState<UiRecipe | null>(null);
  const [recipeForm, setRecipeForm] = useState<RecipeFormState>({
    recipeCode: '',
    recipeName: '',
    materialId: 0,
    batchSize: 0,
    status: 'Draft',
    note: '',
  });

  const [showBomModal, setShowBomModal] = useState(false);
  const [editingBom, setEditingBom] = useState<UiBomItem | null>(null);
  const [bomForm, setBomForm] = useState<BomFormState>({
    materialId: 0,
    quantity: 0,
    uomId: 1,
    wastePercentage: 0,
    note: '',
  });

  const [showRoutingModal, setShowRoutingModal] = useState(false);
  const [editingRouting, setEditingRouting] = useState<UiRoutingStep | null>(null);
  const [routingForm, setRoutingForm] = useState<RoutingFormState>({
    stepNumber: 1,
    stepName: '',
    defaultEquipmentId: 0,
    estimatedTimeMinutes: 0,
    description: '',
  });
  const [planForm, setPlanForm] = useState({
    cartons: 0,
    bottlesPerCarton: 10,
    tabletsPerBottle: 100,
    looseTablets: 0,
  });

  const { data: recipesRaw, isLoading } = useQuery({
    queryKey: ['recipes'],
    queryFn: () => recipesApi.getAll(),
  });

  const { data: materialsRaw } = useQuery({
    queryKey: ['materials'],
    queryFn: () => materialsApi.getAll(),
  });

  const { data: equipmentsRaw } = useQuery({
    queryKey: ['equipments'],
    queryFn: () => equipmentsApi.getAll(),
  });

  const recipes = useMemo<UiRecipe[]>(() => toRows<any>(recipesRaw).map(normalizeRecipe), [recipesRaw]);

  const materials = useMemo<MaterialOption[]>(() => {
    return toRows<any>(materialsRaw).map((item) => ({
      materialId: Number(item.materialId ?? item.MaterialId ?? 0),
      materialCode: item.materialCode ?? item.MaterialCode ?? '',
      materialName: item.materialName ?? item.MaterialName ?? '',
      baseUomId: Number(item.baseUomId ?? item.BaseUomId ?? 1),
    }));
  }, [materialsRaw]);

  const equipments = useMemo<EquipmentOption[]>(() => {
    return toRows<any>(equipmentsRaw).map((item) => ({
      equipmentId: Number(item.equipmentId ?? item.EquipmentId ?? 0),
      equipmentName: item.equipmentName ?? item.EquipmentName ?? '',
    }));
  }, [equipmentsRaw]);

  const filteredRecipes = useMemo(() => {
    const keyword = search.trim().toLowerCase();
    if (!keyword) return recipes;
    return recipes.filter(
      (recipe) =>
        recipe.recipeCode.toLowerCase().includes(keyword) ||
        recipe.recipeName.toLowerCase().includes(keyword)
    );
  }, [recipes, search]);

  useEffect(() => {
    if (!filteredRecipes.length) {
      setSelectedRecipeId(null);
      return;
    }
    const exists = filteredRecipes.some((r) => r.recipeId === selectedRecipeId);
    if (!exists) {
      setSelectedRecipeId(filteredRecipes[0].recipeId);
    }
  }, [filteredRecipes, selectedRecipeId]);

  const selectedRecipe = useMemo(
    () => recipes.find((recipe) => recipe.recipeId === selectedRecipeId) ?? null,
    [recipes, selectedRecipeId]
  );

  const { data: bomRaw } = useQuery({
    queryKey: ['recipeBom', selectedRecipeId],
    queryFn: () => recipesApi.getBOM(selectedRecipeId as number),
    enabled: !!selectedRecipeId,
  });

  const { data: routingRaw } = useQuery({
    queryKey: ['recipeRouting', selectedRecipeId],
    queryFn: () => recipesApi.getRouting(selectedRecipeId as number),
    enabled: !!selectedRecipeId,
  });

  const bomItems = useMemo<UiBomItem[]>(() => toRows<any>(bomRaw).map(normalizeBom), [bomRaw]);

  const routingSteps = useMemo<UiRoutingStep[]>(() => {
    return toRows<any>(routingRaw)
      .map(normalizeRouting)
      .sort((a, b) => a.stepNumber - b.stepNumber);
  }, [routingRaw]);

  const totalTablets = useMemo(() => {
    const byPacking = Math.max(planForm.cartons, 0) * Math.max(planForm.bottlesPerCarton, 0) * Math.max(planForm.tabletsPerBottle, 0);
    return byPacking + Math.max(planForm.looseTablets, 0);
  }, [planForm]);

  const totalPerTabletMg = useMemo(() => bomItems.reduce((sum, item) => sum + item.quantity, 0), [bomItems]);
  const totalFinishedMassKg = (totalTablets * totalPerTabletMg) / 1_000_000;

  const requiredMaterials = useMemo(() => {
    return bomItems.map((item) => {
      const baseMg = totalTablets * item.quantity;
      const withWasteMg = baseMg * (1 + (item.wastePercentage || 0) / 100);
      return { ...item, requiredKg: withWasteMg / 1_000_000 };
    });
  }, [bomItems, totalTablets]);

  const createRecipeMutation = useMutation({
    mutationFn: () => recipesApi.create(recipeForm),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['recipes'] });
      setShowRecipeModal(false);
      setEditingRecipe(null);
    },
  });

  const updateRecipeMutation = useMutation({
    mutationFn: () => recipesApi.update(editingRecipe!.recipeId, recipeForm),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['recipes'] });
      setShowRecipeModal(false);
      setEditingRecipe(null);
    },
  });

  const deleteRecipeMutation = useMutation({
    mutationFn: (id: number) => recipesApi.delete(id),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['recipes'] });
      setSelectedRecipeId(null);
    },
  });

  const addBomMutation = useMutation({
    mutationFn: () => recipesApi.addBOMItem(selectedRecipeId as number, bomForm),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['recipeBom', selectedRecipeId] });
      setShowBomModal(false);
      setEditingBom(null);
    },
  });

  const updateBomMutation = useMutation({
    mutationFn: () => recipesApi.updateBOMItem(selectedRecipeId as number, editingBom!.bomId, bomForm),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['recipeBom', selectedRecipeId] });
      setShowBomModal(false);
      setEditingBom(null);
    },
  });

  const deleteBomMutation = useMutation({
    mutationFn: (bomId: number) => recipesApi.removeBOMItem(selectedRecipeId as number, bomId),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['recipeBom', selectedRecipeId] });
    },
  });

  const addRoutingMutation = useMutation({
    mutationFn: () => recipesApi.addRoutingStep(selectedRecipeId as number, routingForm),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['recipeRouting', selectedRecipeId] });
      setShowRoutingModal(false);
      setEditingRouting(null);
    },
  });

  const updateRoutingMutation = useMutation({
    mutationFn: () => recipesApi.updateRoutingStep(selectedRecipeId as number, editingRouting!.routingId, routingForm),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['recipeRouting', selectedRecipeId] });
      setShowRoutingModal(false);
      setEditingRouting(null);
    },
  });

  const deleteRoutingMutation = useMutation({
    mutationFn: (routingId: number) => recipesApi.removeRoutingStep(selectedRecipeId as number, routingId),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['recipeRouting', selectedRecipeId] });
    },
  });

  const createOrderFromPlanMutation = useMutation({
    mutationFn: () => {
      const now = new Date();
      const end = new Date(now);
      end.setDate(end.getDate() + 7);
      const orderCode = `PO-${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}${String(now.getDate()).padStart(2, '0')}-${String(now.getHours()).padStart(2, '0')}${String(now.getMinutes()).padStart(2, '0')}`;

      return productionOrdersApi.create({
        orderCode,
        recipeId: selectedRecipeId ?? undefined,
        plannedQuantity: totalTablets,
        plannedStartDate: now.toISOString(),
        plannedEndDate: end.toISOString(),
        status: 'Draft',
      });
    },
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['productionOrders'] });
      alert('Đã tạo lệnh sản xuất từ kế hoạch đóng gói.');
    },
  });

  const openCreateRecipe = () => {
    setEditingRecipe(null);
    setRecipeForm({
      recipeCode: '',
      recipeName: '',
      materialId: 0,
      batchSize: 0,
      status: 'Draft',
      note: '',
    });
    setShowRecipeModal(true);
  };

  const openEditRecipe = (recipe: UiRecipe) => {
    setEditingRecipe(recipe);
    setRecipeForm({
      recipeCode: recipe.recipeCode,
      recipeName: recipe.recipeName,
      materialId: recipe.materialId,
      batchSize: recipe.batchSize,
      status: recipe.status,
      note: recipe.note ?? '',
    });
    setShowRecipeModal(true);
  };

  const openCreateBom = () => {
    setEditingBom(null);
    setBomForm({ materialId: 0, quantity: 0, uomId: 1, wastePercentage: 0, note: '' });
    setShowBomModal(true);
  };

  const openEditBom = (item: UiBomItem) => {
    setEditingBom(item);
    setBomForm({
      materialId: item.materialId,
      quantity: item.quantity,
      uomId: item.uomId,
      wastePercentage: item.wastePercentage,
      note: item.note ?? '',
    });
    setShowBomModal(true);
  };

  const openCreateRouting = () => {
    setEditingRouting(null);
    setRoutingForm({
      stepNumber: routingSteps.length + 1,
      stepName: '',
      defaultEquipmentId: 0,
      estimatedTimeMinutes: 0,
      description: '',
    });
    setShowRoutingModal(true);
  };

  const openEditRouting = (item: UiRoutingStep) => {
    setEditingRouting(item);
    setRoutingForm({
      stepNumber: item.stepNumber,
      stepName: item.stepName,
      defaultEquipmentId: item.defaultEquipmentId ?? 0,
      estimatedTimeMinutes: item.estimatedTimeMinutes,
      description: item.description ?? '',
    });
    setShowRoutingModal(true);
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900">Quản lý công thức sản xuất</h1>
          <p className="text-neutral-500 mt-1">Thiết lập công thức, định mức nguyên liệu và quy trình sản xuất</p>
        </div>
        <button onClick={openCreateRecipe} className="btn-primary">
          <Plus className="w-4 h-4 mr-2" />
          Tạo công thức
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="card lg:col-span-1">
          <div className="relative mb-4">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
            <input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Tìm công thức..."
              className="input pl-9"
            />
          </div>

          {isLoading ? (
            <p className="text-sm text-neutral-500">Đang tải dữ liệu...</p>
          ) : (
            <div className="space-y-2 max-h-[560px] overflow-y-auto pr-1">
              {filteredRecipes.map((recipe) => (
                <button
                  key={recipe.recipeId}
                  onClick={() => setSelectedRecipeId(recipe.recipeId)}
                  className={`w-full text-left p-3 rounded-lg border transition ${
                    selectedRecipeId === recipe.recipeId
                      ? 'border-primary-300 bg-primary-50'
                      : 'border-neutral-200 hover:border-primary-200'
                  }`}
                >
                  <p className="font-semibold text-neutral-900">{recipe.recipeCode}</p>
                  <p className="text-sm text-neutral-600 truncate">{recipe.recipeName}</p>
                  <p className="text-xs mt-1 text-neutral-500">Trạng thái: {recipe.status}</p>
                </button>
              ))}
            </div>
          )}
        </div>

        <div className="card lg:col-span-2">
          {!selectedRecipe ? (
            <p className="text-sm text-neutral-500">Chọn một công thức để quản lý định mức và quy trình.</p>
          ) : (
            <div className="space-y-6">
              <div className="flex items-start justify-between gap-3">
                <div>
                  <div className="flex items-center gap-2">
                    <FlaskConical className="w-5 h-5 text-primary-600" />
                    <h2 className="text-xl font-bold text-neutral-900">
                      {selectedRecipe.recipeCode} - {selectedRecipe.recipeName}
                    </h2>
                  </div>
                  <p className="text-sm text-neutral-600 mt-1">
                    Version v{selectedRecipe.versionNumber} | Trạng thái: {selectedRecipe.status}
                  </p>
                </div>
                <div className="flex gap-2">
                  <button onClick={() => openEditRecipe(selectedRecipe)} className="btn-ghost text-sm">
                    <Pencil className="w-4 h-4 mr-1" />Sửa công thức
                  </button>
                  <button
                    onClick={() => {
                      if (confirm('Xóa công thức này?')) {
                        deleteRecipeMutation.mutate(selectedRecipe.recipeId);
                      }
                    }}
                    className="btn-ghost text-sm text-red-600"
                  >
                    <Trash2 className="w-4 h-4 mr-1" />Xóa công thức
                  </button>
                </div>
              </div>

              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <ListTree className="w-5 h-5 text-primary-600" />
                    <h3 className="text-lg font-semibold text-neutral-900">Lập định mức cho 1 viên thuốc</h3>
                  </div>
                  <button onClick={openCreateBom} className="btn-secondary text-sm">
                    <Plus className="w-4 h-4 mr-1" />Thêm nguyên liệu
                  </button>
                </div>
                <p className="text-xs text-neutral-500">Nhập khối lượng từng nguyên liệu cho 1 viên (mg/viên).</p>
                <div className="table-container">
                  <table className="table">
                    <thead>
                      <tr>
                        <th>Nguyên liệu</th>
                        <th>Khối lượng/viên (mg)</th>
                        <th>Hao hụt (%)</th>
                        <th className="text-right">Thao tác</th>
                      </tr>
                    </thead>
                    <tbody>
                      {bomItems.map((item) => (
                        <tr key={item.bomId}>
                          <td>{item.materialName}</td>
                          <td>{item.quantity}</td>
                          <td>{item.wastePercentage}</td>
                          <td className="text-right">
                            <div className="flex justify-end gap-2">
                              <button onClick={() => openEditBom(item)} className="btn-ghost text-sm">Sửa</button>
                              <button
                                onClick={() => {
                                  if (confirm('Xóa nguyên liệu này khỏi định mức?')) {
                                    deleteBomMutation.mutate(item.bomId);
                                  }
                                }}
                                className="btn-ghost text-sm text-red-600"
                              >
                                Xóa
                              </button>
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>

              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Route className="w-5 h-5 text-primary-600" />
                    <h3 className="text-lg font-semibold text-neutral-900">Quy trình công đoạn</h3>
                  </div>
                  <button onClick={openCreateRouting} className="btn-secondary text-sm">
                    <Plus className="w-4 h-4 mr-1" />Thêm công đoạn
                  </button>
                </div>
                <div className="table-container">
                  <table className="table">
                    <thead>
                      <tr>
                        <th>Bước</th>
                        <th>Tên công đoạn</th>
                        <th>Thiết bị</th>
                        <th>Thời gian (phút)</th>
                        <th className="text-right">Thao tác</th>
                      </tr>
                    </thead>
                    <tbody>
                      {routingSteps.map((item) => (
                        <tr key={item.routingId}>
                          <td>{item.stepNumber}</td>
                          <td>{item.stepName}</td>
                          <td>{item.equipmentName ?? '-'}</td>
                          <td>{item.estimatedTimeMinutes}</td>
                          <td className="text-right">
                            <div className="flex justify-end gap-2">
                              <button onClick={() => openEditRouting(item)} className="btn-ghost text-sm">Sửa</button>
                              <button
                                onClick={() => {
                                  if (confirm('Xóa bước công đoạn này?')) {
                                    deleteRoutingMutation.mutate(item.routingId);
                                  }
                                }}
                                className="btn-ghost text-sm text-red-600"
                              >
                                Xóa
                              </button>
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>

              <div className="rounded-xl border border-primary-200 bg-primary-50/40 p-4 space-y-4">
                <div className="flex items-center gap-2">
                  <Calculator className="w-5 h-5 text-primary-700" />
                  <h3 className="text-lg font-semibold text-primary-900">Lập lệnh sản xuất N viên thuốc</h3>
                </div>
                <p className="text-sm text-primary-800">Nhập số thùng, số chai và số viên để hệ thống tự tính khối lượng thành phẩm và khối lượng từng nguyên liệu theo định mức.</p>

                <div className="grid grid-cols-1 md:grid-cols-4 gap-3">
                  <div>
                    <label className="text-xs text-neutral-600">Số thùng</label>
                    <input type="number" className="input" value={planForm.cartons} onChange={(e) => setPlanForm({ ...planForm, cartons: Number(e.target.value) })} />
                  </div>
                  <div>
                    <label className="text-xs text-neutral-600">Số chai/thùng</label>
                    <input type="number" className="input" value={planForm.bottlesPerCarton} onChange={(e) => setPlanForm({ ...planForm, bottlesPerCarton: Number(e.target.value) })} />
                  </div>
                  <div>
                    <label className="text-xs text-neutral-600">Số viên/chai</label>
                    <input type="number" className="input" value={planForm.tabletsPerBottle} onChange={(e) => setPlanForm({ ...planForm, tabletsPerBottle: Number(e.target.value) })} />
                  </div>
                  <div>
                    <label className="text-xs text-neutral-600">Viên lẻ</label>
                    <input type="number" className="input" value={planForm.looseTablets} onChange={(e) => setPlanForm({ ...planForm, looseTablets: Number(e.target.value) })} />
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-3 text-sm">
                  <div className="p-3 rounded-lg bg-white border border-primary-200">
                    <p className="text-neutral-500">Tổng số viên</p>
                    <p className="text-xl font-bold text-neutral-900">{totalTablets.toLocaleString()}</p>
                  </div>
                  <div className="p-3 rounded-lg bg-white border border-primary-200">
                    <p className="text-neutral-500">Khối lượng 1 viên</p>
                    <p className="text-xl font-bold text-neutral-900">{totalPerTabletMg.toLocaleString()} mg</p>
                  </div>
                  <div className="p-3 rounded-lg bg-white border border-primary-200">
                    <p className="text-neutral-500">Khối lượng thành phẩm</p>
                    <p className="text-xl font-bold text-neutral-900">{totalFinishedMassKg.toFixed(3)} kg</p>
                  </div>
                </div>

                <div className="table-container bg-white rounded-lg border border-primary-200">
                  <table className="table">
                    <thead>
                      <tr>
                        <th>Nguyên liệu</th>
                        <th>Định mức (mg/viên)</th>
                        <th>Khối lượng cần (kg)</th>
                      </tr>
                    </thead>
                    <tbody>
                      {requiredMaterials.length === 0 ? (
                        <tr>
                          <td colSpan={3} className="text-center py-4 text-neutral-500">Chưa có định mức nguyên liệu.</td>
                        </tr>
                      ) : (
                        requiredMaterials.map((item) => (
                          <tr key={item.bomId}>
                            <td>{item.materialName}</td>
                            <td>{item.quantity}</td>
                            <td>{item.requiredKg.toFixed(4)}</td>
                          </tr>
                        ))
                      )}
                    </tbody>
                  </table>
                </div>

                <div className="flex justify-end">
                  <button
                    className="btn-primary"
                    disabled={!selectedRecipeId || totalTablets <= 0 || createOrderFromPlanMutation.isPending}
                    onClick={() => createOrderFromPlanMutation.mutate()}
                  >
                    <Boxes className="w-4 h-4 mr-2" />Tạo lệnh sản xuất theo kế hoạch
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {showRecipeModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl w-full max-w-2xl p-6 space-y-4">
            <h3 className="text-xl font-bold">{editingRecipe ? 'Cập nhật công thức' : 'Tạo công thức mới'}</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <input
                className="input"
                placeholder="Mã công thức"
                value={recipeForm.recipeCode}
                onChange={(e) => setRecipeForm({ ...recipeForm, recipeCode: e.target.value })}
              />
              <input
                className="input"
                placeholder="Tên công thức"
                value={recipeForm.recipeName}
                onChange={(e) => setRecipeForm({ ...recipeForm, recipeName: e.target.value })}
              />
              <select
                className="input"
                value={recipeForm.materialId}
                onChange={(e) => setRecipeForm({ ...recipeForm, materialId: Number(e.target.value) })}
              >
                <option value={0}>Chọn thành phẩm</option>
                {materials.map((material) => (
                  <option key={material.materialId} value={material.materialId}>
                    {material.materialCode} - {material.materialName}
                  </option>
                ))}
              </select>
              <input
                type="number"
                className="input"
                placeholder="Cỡ lô"
                value={recipeForm.batchSize}
                onChange={(e) => setRecipeForm({ ...recipeForm, batchSize: Number(e.target.value) })}
              />
              <select
                className="input"
                value={recipeForm.status}
                onChange={(e) => setRecipeForm({ ...recipeForm, status: e.target.value as RecipeStatus })}
              >
                {recipeStatuses.map((status) => (
                  <option key={status} value={status}>
                    {status}
                  </option>
                ))}
              </select>
            </div>
            <textarea
              className="input"
              rows={3}
              placeholder="Ghi chú"
              value={recipeForm.note}
              onChange={(e) => setRecipeForm({ ...recipeForm, note: e.target.value })}
            />
            <div className="flex justify-end gap-2">
              <button onClick={() => setShowRecipeModal(false)} className="btn-ghost">Hủy</button>
              <button
                onClick={() => (editingRecipe ? updateRecipeMutation.mutate() : createRecipeMutation.mutate())}
                className="btn-primary"
                disabled={createRecipeMutation.isPending || updateRecipeMutation.isPending}
              >
                {editingRecipe ? 'Lưu cập nhật' : 'Tạo mới'}
              </button>
            </div>
          </div>
        </div>
      )}

      {showBomModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl w-full max-w-xl p-6 space-y-4">
            <h3 className="text-xl font-bold">{editingBom ? 'Cập nhật nguyên liệu định mức' : 'Thêm nguyên liệu định mức'}</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <select
                className="input"
                value={bomForm.materialId}
                onChange={(e) => {
                  const materialId = Number(e.target.value);
                  const material = materials.find((m) => m.materialId === materialId);
                  setBomForm({ ...bomForm, materialId, uomId: material?.baseUomId ?? bomForm.uomId });
                }}
              >
                <option value={0}>Chọn nguyên liệu</option>
                {materials.map((material) => (
                  <option key={material.materialId} value={material.materialId}>
                    {material.materialCode} - {material.materialName}
                  </option>
                ))}
              </select>
              <input
                type="number"
                className="input"
                placeholder="Khối lượng/viên (mg)"
                value={bomForm.quantity}
                onChange={(e) => setBomForm({ ...bomForm, quantity: Number(e.target.value) })}
              />
              <input
                type="number"
                className="input"
                placeholder="UomId"
                value={bomForm.uomId}
                onChange={(e) => setBomForm({ ...bomForm, uomId: Number(e.target.value) })}
              />
              <input
                type="number"
                className="input"
                placeholder="Hao hụt (%)"
                value={bomForm.wastePercentage}
                onChange={(e) => setBomForm({ ...bomForm, wastePercentage: Number(e.target.value) })}
              />
            </div>
            <textarea
              className="input"
              rows={2}
              placeholder="Ghi chú"
              value={bomForm.note}
              onChange={(e) => setBomForm({ ...bomForm, note: e.target.value })}
            />
            <div className="flex justify-end gap-2">
              <button onClick={() => setShowBomModal(false)} className="btn-ghost">Hủy</button>
              <button
                onClick={() => (editingBom ? updateBomMutation.mutate() : addBomMutation.mutate())}
                className="btn-primary"
                disabled={addBomMutation.isPending || updateBomMutation.isPending}
              >
                {editingBom ? 'Lưu cập nhật' : 'Thêm nguyên liệu'}
              </button>
            </div>
          </div>
        </div>
      )}

      {showRoutingModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl w-full max-w-xl p-6 space-y-4">
            <h3 className="text-xl font-bold">{editingRouting ? 'Cập nhật công đoạn' : 'Thêm công đoạn'}</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <input
                type="number"
                className="input"
                placeholder="Bước"
                value={routingForm.stepNumber}
                onChange={(e) => setRoutingForm({ ...routingForm, stepNumber: Number(e.target.value) })}
              />
              <input
                className="input"
                placeholder="Tên công đoạn"
                value={routingForm.stepName}
                onChange={(e) => setRoutingForm({ ...routingForm, stepName: e.target.value })}
              />
              <select
                className="input"
                value={routingForm.defaultEquipmentId}
                onChange={(e) => setRoutingForm({ ...routingForm, defaultEquipmentId: Number(e.target.value) })}
              >
                <option value={0}>Chọn thiết bị</option>
                {equipments.map((equipment) => (
                  <option key={equipment.equipmentId} value={equipment.equipmentId}>
                    {equipment.equipmentName}
                  </option>
                ))}
              </select>
              <input
                type="number"
                className="input"
                placeholder="Thời gian (phút)"
                value={routingForm.estimatedTimeMinutes}
                onChange={(e) => setRoutingForm({ ...routingForm, estimatedTimeMinutes: Number(e.target.value) })}
              />
            </div>
            <textarea
              className="input"
              rows={2}
              placeholder="Mô tả"
              value={routingForm.description}
              onChange={(e) => setRoutingForm({ ...routingForm, description: e.target.value })}
            />
            <div className="flex justify-end gap-2">
              <button onClick={() => setShowRoutingModal(false)} className="btn-ghost">Hủy</button>
              <button
                onClick={() => (editingRouting ? updateRoutingMutation.mutate() : addRoutingMutation.mutate())}
                className="btn-primary"
                disabled={addRoutingMutation.isPending || updateRoutingMutation.isPending}
              >
                {editingRouting ? 'Lưu cập nhật' : 'Thêm công đoạn'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}





