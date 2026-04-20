import { useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { equipmentsApi, inventoryApi, productionBatchesApi, productionOrdersApi, recipesApi } from '@/services/api';
import { Calculator, ClipboardList, Pencil, Plus, Search, Trash2 } from 'lucide-react';
import { RecipeRouting, StepParameter } from '@/types';

type OrderStatus = 'Draft' | 'Approved' | 'InProcess' | 'Hold' | 'Completed';
type MassUnit = 'kg' | 'g' | 'vien';

interface UiProductionOrder {
  orderId: number;
  orderCode: string;
  recipeId: number;
  recipeName?: string;
  plannedQuantity: number;
  status: OrderStatus;
  plannedStartDate?: string;
  endDate?: string;
}

function toRows<T>(raw: unknown): T[] {
  if (Array.isArray(raw)) return raw as T[];
  if (raw && typeof raw === 'object') {
    const obj = raw as { data?: unknown; items?: unknown };
    if (Array.isArray(obj.data)) return obj.data as T[];
    if (Array.isArray(obj.items)) return obj.items as T[];
  }
  return [];
}

function parseCapacityKg(spec?: string): number | null {
  if (!spec) return null;
  const m = spec.replace(',', '.').match(/(\d+(?:\.\d+)?)\s*kg/i);
  if (!m) return null;
  const v = Number(m[1]);
  return Number.isFinite(v) && v > 0 ? v : null;
}

export default function ProductionOrders() {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [showOrderModal, setShowOrderModal] = useState(false);
  const [editingOrder, setEditingOrder] = useState<UiProductionOrder | null>(null);

  const [orderForm, setOrderForm] = useState({ orderCode: '', recipeId: 0, plannedQuantity: 0, startDate: '', endDate: '', status: 'Draft' as OrderStatus });
  const [planForm, setPlanForm] = useState({ recipeId: 0, cartons: 0, bottlesPerCarton: 10, tabletsPerBottle: 100, looseTablets: 0, massUnit: 'kg' as MassUnit });
  const [activeTab, setActiveTab] = useState<'info' | 'routing'>('info');
  const [customRoutings, setCustomRoutings] = useState<RecipeRouting[]>([]);

  const { data: ordersRaw, isLoading } = useQuery({ queryKey: ['productionOrders'], queryFn: () => productionOrdersApi.getAll() });
  const { data: recipesRaw } = useQuery({ queryKey: ['recipes'], queryFn: () => recipesApi.getAll() });
  const { data: lotsRaw } = useQuery({ queryKey: ['inventoryLots'], queryFn: () => inventoryApi.getAll() });
  const { data: equipmentsRaw } = useQuery({ queryKey: ['equipments'], queryFn: () => equipmentsApi.getAll() });

  const orders = useMemo<UiProductionOrder[]>(() => toRows<any>(ordersRaw).map((o) => ({
    orderId: Number(o.orderId ?? o.OrderId ?? 0),
    orderCode: o.orderCode ?? o.OrderCode ?? '',
    recipeId: Number(o.recipeId ?? o.RecipeId ?? 0),
    recipeName: o.recipe?.material?.materialName ?? o.recipeName,
    plannedQuantity: Number(o.plannedQuantity ?? o.PlannedQuantity ?? 0),
    status: (o.status ?? o.Status ?? 'Draft') as OrderStatus,
    plannedStartDate: o.startDate ?? o.StartDate,
  })), [ordersRaw]);

  const recipes = useMemo(() => toRows<any>(recipesRaw).map((r) => ({
    recipeId: Number(r.recipeId ?? r.RecipeId ?? 0),
    recipeName: r.material?.materialName ?? r.Material?.MaterialName ?? `Công thức #${r.recipeId ?? r.RecipeId}`,
    batchSize: Number(r.batchSize ?? r.BatchSize ?? 0),
  })), [recipesRaw]);

  const selectedRecipe = useMemo(() => recipes.find((r) => r.recipeId === planForm.recipeId), [recipes, planForm.recipeId]);

  const { data: bomRaw } = useQuery({ queryKey: ['recipeBomForOrder', planForm.recipeId], queryFn: () => recipesApi.getBOM(planForm.recipeId), enabled: planForm.recipeId > 0 });
  const { data: routingRaw } = useQuery({ queryKey: ['recipeRoutingForOrder', planForm.recipeId], queryFn: () => recipesApi.getRouting(planForm.recipeId), enabled: planForm.recipeId > 0 });

  const bomItems = useMemo(() => toRows<any>(bomRaw).map((b) => ({
    materialId: Number(b.materialId ?? b.MaterialId ?? 0),
    materialName: b.material?.materialName ?? b.Material?.MaterialName ?? 'Nguyên liệu',
    mgPerTablet: Number(b.quantity ?? b.Quantity ?? 0),
  })), [bomRaw]);

  const routingSteps = useMemo(() => toRows<any>(routingRaw).map((r) => ({
    stepNumber: Number(r.stepNumber ?? r.StepNumber ?? 1),
    defaultEquipmentId: Number(r.defaultEquipmentId ?? r.DefaultEquipmentId ?? 0),
    stepName: r.stepName ?? r.StepName ?? '',
  })), [routingRaw]);

  const equipments = useMemo(() => toRows<any>(equipmentsRaw).map((e) => ({
    equipmentId: Number(e.equipmentId ?? e.EquipmentId ?? 0),
    equipmentName: e.equipmentName ?? e.EquipmentName ?? '',
    technicalSpecification: e.technicalSpecification ?? e.TechnicalSpecification ?? '',
  })), [equipmentsRaw]);

  const stockByMaterial = useMemo(() => {
    const map = new Map<number, number>();
    const lots = toRows<any>(lotsRaw);
    for (const lot of lots) {
      const materialId = Number(lot.materialId ?? lot.MaterialId ?? 0);
      const qty = Number(lot.quantityCurrent ?? lot.QuantityCurrent ?? 0);
      if (!materialId) continue;
      map.set(materialId, (map.get(materialId) ?? 0) + qty);
    }
    return map;
  }, [lotsRaw]);

  const filteredOrders = useMemo(() => {
    const keyword = search.trim().toLowerCase();
    if (!keyword) return orders;
    return orders.filter((order) => order.orderCode.toLowerCase().includes(keyword));
  }, [orders, search]);

  const totalTablets = useMemo(() => {
    const packed = Math.max(planForm.cartons, 0) * Math.max(planForm.bottlesPerCarton, 0) * Math.max(planForm.tabletsPerBottle, 0);
    return packed + Math.max(planForm.looseTablets, 0);
  }, [planForm]);

  const oneTabletMg = selectedRecipe?.batchSize ?? 0;
  const totalMassMg = totalTablets * oneTabletMg;
  const totalMassKg = totalMassMg / 1_000_000;

  const displayFinishedMass = useMemo(() => {
    if (planForm.massUnit === 'g') return `${(totalMassMg / 1000).toFixed(2)} g`;
    if (planForm.massUnit === 'vien') return `${totalTablets.toLocaleString()} viên`;
    return `${totalMassKg.toFixed(3)} kg`;
  }, [planForm.massUnit, totalMassMg, totalTablets, totalMassKg]);

  const requiredMaterials = useMemo(() => {
    return bomItems.map((item) => {
      const requiredKg = (totalTablets * item.mgPerTablet) / 1_000_000;
      const available = stockByMaterial.get(item.materialId) ?? 0;
      return { ...item, requiredKg, available, enough: available >= requiredKg };
    });
  }, [bomItems, totalTablets, stockByMaterial]);

  const insufficientMaterials = useMemo(() => requiredMaterials.filter((m) => !m.enough), [requiredMaterials]);

  const batchPlan = useMemo(() => {
    if (totalTablets <= 0 || oneTabletMg <= 0) return { batches: 0, tabletsPerBatch: 0, reason: 'Thiếu dữ liệu để tính mẻ.' };

    const capacitiesKg = routingSteps
      .map((s) => equipments.find((e) => e.equipmentId === s.defaultEquipmentId))
      .map((e) => parseCapacityKg(e?.technicalSpecification ?? ''))
      .filter((v): v is number => v !== null && Number.isFinite(v) && v > 0);

    const minCapacityKg = capacitiesKg.length ? Math.min(...capacitiesKg) : totalMassKg;
    const tabletsPerBatch = Math.max(1, Math.floor((minCapacityKg * 1_000_000) / oneTabletMg));
    const batches = Math.ceil(totalTablets / tabletsPerBatch);

    return {
      batches,
      tabletsPerBatch,
      reason: capacitiesKg.length ? `Tách theo sức chứa tối thiểu ${minCapacityKg.toLocaleString()} kg/mẻ của thiết bị.` : 'Không có giới hạn sức chứa theo kg, giữ 1 mẻ.',
    };
  }, [routingSteps, equipments, totalTablets, oneTabletMg, totalMassKg]);

  const createOrderMutation = useMutation({
    mutationFn: async () => {
      const resp: any = await productionOrdersApi.create({
        orderCode: orderForm.orderCode,
        recipeId: orderForm.recipeId,
        plannedQuantity: orderForm.plannedQuantity,
        startDate: orderForm.startDate ? new Date(orderForm.startDate).toISOString() : undefined,
        endDate: orderForm.endDate ? new Date(orderForm.endDate).toISOString() : undefined,
        status: orderForm.status,
      } as any);
      
      const orderId = Number(resp?.data?.orderId ?? resp?.orderId ?? 0);
      if (orderId) {
        // Save routings if any
        if (customRoutings.length > 0) {
          await productionOrdersApi.saveRoutings(orderId, customRoutings);
        }
      }
      return resp;
    },
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['productionOrders'] });
      await queryClient.invalidateQueries({ queryKey: ['productionBatches'] });
      setShowOrderModal(false);
      setEditingOrder(null);
    },
    onError: (err: any) => {
      alert(err?.response?.data?.message ?? err?.message ?? 'Không thể tạo lệnh sản xuất');
    },
  });

  const updateOrderMutation = useMutation({
    mutationFn: async () => {
      const resp = await productionOrdersApi.update(editingOrder!.orderId, {
        orderCode: orderForm.orderCode,
        recipeId: orderForm.recipeId,
        plannedQuantity: orderForm.plannedQuantity,
        startDate: orderForm.startDate ? new Date(orderForm.startDate).toISOString() : undefined,
        endDate: orderForm.endDate ? new Date(orderForm.endDate).toISOString() : undefined,
        status: orderForm.status,
      } as any);
      
      await productionOrdersApi.saveRoutings(editingOrder!.orderId, customRoutings);
      return resp;
    },
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['productionOrders'] });
      setShowOrderModal(false);
      setEditingOrder(null);
    },
  });

  const deleteOrderMutation = useMutation({
    mutationFn: (id: number) => productionOrdersApi.delete(id),
    onSuccess: async () => queryClient.invalidateQueries({ queryKey: ['productionOrders'] }),
  });

  const createOrderFromPlanMutation = useMutation({
    mutationFn: async () => {
      if (insufficientMaterials.length) {
        throw new Error('Không đủ nguyên liệu tồn kho để tạo lệnh sản xuất.');
      }

      const now = new Date();
      const end = new Date(now);
      end.setDate(end.getDate() + 7);
      const orderCode = `PO-${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}${String(now.getDate()).padStart(2, '0')}-${String(now.getHours()).padStart(2, '0')}${String(now.getMinutes()).padStart(2, '0')}`;

      const created: any = await productionOrdersApi.create({
        orderCode,
        recipeId: planForm.recipeId,
        plannedQuantity: totalTablets,
        startDate: now.toISOString(),
        endDate: end.toISOString(),
        status: 'Draft',
      } as any);

      const orderId = Number(created?.data?.orderId ?? created?.orderId ?? created?.data?.OrderId ?? 0);
      if (!orderId) return;

      for (let i = 0; i < batchPlan.batches; i++) {
        const batchCode = `${orderCode.replace('PO', 'B')}-${String(i + 1).padStart(2, '0')}`;
        await productionBatchesApi.create({
          orderId,
          batchNumber: batchCode,
          status: i === 0 ? 'InProcess' : 'Scheduled',
          currentStep: 1,
        } as any);
      }
    },
    onSuccess: async () => {
      await Promise.all([
        queryClient.invalidateQueries({ queryKey: ['productionOrders'] }),
        queryClient.invalidateQueries({ queryKey: ['productionBatches'] }),
      ]);
      alert('Đã tạo lệnh sản xuất và tách mẻ tự động.');
    },
    onError: (err: any) => alert(err?.message ?? 'Không thể tạo lệnh sản xuất'),
  });

  const openCreateOrder = () => {
    const now = new Date();
    const randomSuffix = Math.floor(Math.random() * 100);
    const autoCode = `PO-${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}${String(now.getDate()).padStart(2, '0')}-${String(now.getHours()).padStart(2, '0')}${String(now.getMinutes()).padStart(2, '0')}${String(now.getSeconds()).padStart(2, '0')}-${randomSuffix}`;
    
    setEditingOrder(null);
    setOrderForm({ orderCode: autoCode, recipeId: 0, plannedQuantity: 0, startDate: '', endDate: '', status: 'Draft' });
    setCustomRoutings([]);
    setActiveTab('info');
    setShowOrderModal(true);
  };

  const openEditOrder = async (order: UiProductionOrder) => {
    setEditingOrder(order);
    setOrderForm({
      orderCode: order.orderCode,
      recipeId: order.recipeId,
      plannedQuantity: order.plannedQuantity,
      startDate: order.plannedStartDate ? new Date(order.plannedStartDate).toISOString().slice(0, 10) : '',
      endDate: order.endDate ? new Date(order.endDate).toISOString().slice(0, 10) : '',
      status: order.status,
    });
    
    // Fetch custom routings for this order
    try {
      const resp = await productionOrdersApi.getRoutings(order.orderId);
      setCustomRoutings(toRows<RecipeRouting>(resp));
    } catch (e) {
      setCustomRoutings([]);
    }
    
    setActiveTab('info');
    setShowOrderModal(true);
  };

  const onRecipeChange = async (recipeId: number) => {
    setOrderForm({ ...orderForm, recipeId });
    if (recipeId > 0) {
      try {
        const resp = await recipesApi.getRouting(recipeId);
        setCustomRoutings(toRows<RecipeRouting>(resp));
      } catch (e) {
        setCustomRoutings([]);
      }
    } else {
      setCustomRoutings([]);
    }
  };

  const handleAddStep = () => {
    const nextStep = customRoutings.length > 0 ? Math.max(...customRoutings.map(r => r.stepNumber)) + 1 : 1;
    setCustomRoutings([...customRoutings, {
      routingId: 0,
      stepNumber: nextStep,
      stepName: 'Công đoạn mới',
      estimatedTimeMinutes: 30,
      stepParameters: []
    }]);
  };

  const handleRemoveStep = (index: number) => {
    setCustomRoutings(customRoutings.filter((_, i) => i !== index));
  };

  const handleUpdateStep = (index: number, data: Partial<RecipeRouting>) => {
    const next = [...customRoutings];
    next[index] = { ...next[index], ...data };
    setCustomRoutings(next);
  };

  const handleAddParam = (stepIndex: number) => {
    const next = [...customRoutings];
    next[stepIndex].stepParameters = [
      ...(next[stepIndex].stepParameters || []),
      { parameterId: 0, parameterName: 'Thông số mới', unit: '', isCritical: true }
    ];
    setCustomRoutings(next);
  };

  const handleRemoveParam = (stepIndex: number, paramIndex: number) => {
    const next = [...customRoutings];
    if (next[stepIndex].stepParameters) {
      next[stepIndex].stepParameters = next[stepIndex].stepParameters!.filter((_, i) => i !== paramIndex);
      setCustomRoutings(next);
    }
  };

  const handleUpdateParam = (stepIndex: number, paramIndex: number, data: Partial<StepParameter>) => {
    const next = [...customRoutings];
    if (next[stepIndex].stepParameters) {
      const params = [...next[stepIndex].stepParameters!];
      params[paramIndex] = { ...params[paramIndex], ...data };
      next[stepIndex].stepParameters = params;
      setCustomRoutings(next);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Quản lý lệnh sản xuất</h1>
          <p className="text-neutral-500 mt-1">Lập lệnh sản xuất và kiểm tra tồn kho/ngưỡng thiết bị</p>
        </div>
        <button onClick={openCreateOrder} className="btn-primary flex items-center"><Plus className="w-5 h-5 mr-2" />Tạo lệnh mới</button>
      </div>

      <div className="rounded-xl border border-primary-200 bg-primary-50/40 p-4 space-y-4">
        <div className="flex items-center gap-2"><Calculator className="w-5 h-5 text-primary-700" /><h3 className="text-lg font-semibold text-primary-900">Lập lệnh sản xuất N viên thuốc</h3></div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          <div>
            <label className="text-xs text-neutral-600">Chọn công thức</label>
            <select className="input" value={planForm.recipeId} onChange={(e) => setPlanForm({ ...planForm, recipeId: Number(e.target.value) })}>
              <option value={0}>Chọn công thức</option>
              {recipes.map((recipe) => <option key={recipe.recipeId} value={recipe.recipeId}>#{recipe.recipeId} - {recipe.recipeName}</option>)}
            </select>
          </div>
          <div>
            <label className="text-xs text-neutral-600">Đơn vị hiển thị khối lượng thành phẩm</label>
            <select className="input" value={planForm.massUnit} onChange={(e) => setPlanForm({ ...planForm, massUnit: e.target.value as MassUnit })}>
              <option value="kg">kg</option><option value="g">g</option><option value="vien">viên</option>
            </select>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-4 gap-3">
          <div><label className="text-xs text-neutral-600">Số thùng</label><input type="number" className="input" value={planForm.cartons} onChange={(e) => setPlanForm({ ...planForm, cartons: Number(e.target.value) })} /></div>
          <div><label className="text-xs text-neutral-600">Số chai/thùng</label><input type="number" className="input" value={planForm.bottlesPerCarton} onChange={(e) => setPlanForm({ ...planForm, bottlesPerCarton: Number(e.target.value) })} /></div>
          <div><label className="text-xs text-neutral-600">Số viên/chai</label><input type="number" className="input" value={planForm.tabletsPerBottle} onChange={(e) => setPlanForm({ ...planForm, tabletsPerBottle: Number(e.target.value) })} /></div>
          <div><label className="text-xs text-neutral-600">Viên lẻ</label><input type="number" className="input" value={planForm.looseTablets} onChange={(e) => setPlanForm({ ...planForm, looseTablets: Number(e.target.value) })} /></div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-3 text-sm">
          <div className="p-3 rounded-lg bg-white border border-primary-200"><p className="text-neutral-500">Tổng số viên</p><p className="text-xl font-bold text-neutral-900">{totalTablets.toLocaleString()}</p></div>
          <div className="p-3 rounded-lg bg-white border border-primary-200"><p className="text-neutral-500">Khối lượng 1 viên</p><p className="text-xl font-bold text-neutral-900">{oneTabletMg.toLocaleString()} mg</p></div>
          <div className="p-3 rounded-lg bg-white border border-primary-200"><p className="text-neutral-500">Khối lượng thành phẩm</p><p className="text-xl font-bold text-neutral-900">{displayFinishedMass}</p></div>
        </div>

        {insufficientMaterials.length > 0 && (
          <div className="border border-red-300 bg-red-50 rounded-lg p-3 text-red-700 text-sm">
            <p className="font-semibold mb-1">Không đủ nguyên liệu tồn kho:</p>
            {insufficientMaterials.map((m) => <p key={m.materialId}>- {m.materialName}: cần {m.requiredKg.toFixed(4)} kg, hiện có {m.available.toFixed(4)} kg</p>)}
          </div>
        )}

        <div className="border border-amber-300 bg-amber-50 rounded-lg p-3 text-amber-800 text-sm">
          <p><strong>Kế hoạch tách mẻ tự động:</strong> {batchPlan.batches} mẻ, mỗi mẻ tối đa {batchPlan.tabletsPerBatch.toLocaleString()} viên.</p>
          <p>{batchPlan.reason}</p>
        </div>

        <div className="table-container bg-white rounded-lg border border-primary-200">
          <table className="table">
            <thead><tr><th>Nguyên liệu</th><th>Định mức (mg/viên)</th><th>Khối lượng cần (kg)</th><th>Tồn hiện tại (kg)</th><th>Đủ/Thiếu</th></tr></thead>
            <tbody>
              {requiredMaterials.length === 0 ? <tr><td colSpan={5} className="text-center py-4 text-neutral-500">Chưa có định mức nguyên liệu.</td></tr> : requiredMaterials.map((item, idx) => (
                <tr key={`${item.materialName}-${idx}`}>
                  <td>{item.materialName}</td><td>{item.mgPerTablet.toFixed(2)}</td><td>{item.requiredKg.toFixed(4)}</td><td>{item.available.toFixed(4)}</td>
                  <td><span className={`px-2 py-1 rounded-full text-xs ${item.enough ? 'bg-emerald-100 text-emerald-700' : 'bg-red-100 text-red-700'}`}>{item.enough ? 'Đủ' : 'Thiếu'}</span></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <div className="flex justify-end">
          <button className="btn-primary" disabled={planForm.recipeId <= 0 || totalTablets <= 0 || insufficientMaterials.length > 0 || createOrderFromPlanMutation.isPending} onClick={() => createOrderFromPlanMutation.mutate()}>
            Tạo lệnh sản xuất theo kế hoạch
          </button>
        </div>
      </div>

      <div className="card">
        <div className="relative flex-1"><Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-neutral-400" /><input type="text" placeholder="Tìm kiếm theo mã lệnh..." value={search} onChange={(e) => setSearch(e.target.value)} className="input pl-10" /></div>
      </div>

      <div className="card p-0 overflow-hidden">
        {isLoading ? (
          <div className="flex items-center justify-center p-12"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div></div>
        ) : filteredOrders.length === 0 ? (
          <div className="text-center py-12"><ClipboardList className="w-12 h-12 text-neutral-300 mx-auto mb-4" /><p className="text-neutral-500">Không tìm thấy lệnh sản xuất nào.</p></div>
        ) : (
          <div className="table-container"><table className="table"><thead><tr><th>Mã lệnh</th><th>Công thức</th><th>Số lượng kế hoạch</th><th>Trạng thái</th><th>Dự kiến bắt đầu</th><th className="text-right">Thao tác</th></tr></thead><tbody>{filteredOrders.map((order) => (
            <tr key={order.orderId}>
              <td><code className="text-xs bg-neutral-100 px-2 py-1 rounded font-mono text-primary-600">{order.orderCode}</code></td>
              <td className="font-medium text-neutral-900">{order.recipeName || `Công thức #${order.recipeId}`}</td>
              <td>{order.plannedQuantity.toLocaleString()}</td>
              <td>{order.status}</td>
              <td>{order.plannedStartDate ? new Date(order.plannedStartDate).toLocaleDateString('vi-VN') : '-'}</td>
              <td className="text-right"><div className="flex justify-end gap-2"><button onClick={() => openEditOrder(order)} className="btn-ghost text-sm"><Pencil className="w-4 h-4 mr-1" />Sửa</button><button onClick={() => { if (confirm('Xóa lệnh sản xuất này?')) deleteOrderMutation.mutate(order.orderId); }} className="btn-ghost text-sm text-red-600"><Trash2 className="w-4 h-4 mr-1" />Xóa</button></div></td>
            </tr>
          ))}</tbody></table></div>
        )}
      </div>

      {showOrderModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl w-full max-w-4xl max-h-[90vh] flex flex-col overflow-hidden">
            <div className="p-6 border-b border-neutral-200 flex items-center justify-between">
              <h2 className="text-xl font-bold">{editingOrder ? 'Cập nhật lệnh sản xuất' : 'Tạo lệnh sản xuất'}</h2>
              <div className="flex bg-neutral-100 p-1 rounded-lg">
                <button 
                  onClick={() => setActiveTab('info')}
                  className={`px-4 py-1.5 rounded-md text-sm font-medium transition-colors ${activeTab === 'info' ? 'bg-white shadow-sm text-primary-700' : 'text-neutral-500 hover:text-neutral-700'}`}
                >
                  Thông tin chung
                </button>
                <button 
                  onClick={() => setActiveTab('routing')}
                  className={`px-4 py-1.5 rounded-md text-sm font-medium transition-colors ${activeTab === 'routing' ? 'bg-white shadow-sm text-primary-700' : 'text-neutral-500 hover:text-neutral-700'}`}
                >
                  Cấu hình công đoạn
                </button>
              </div>
            </div>

            <div className="flex-1 overflow-y-auto p-6">
              {activeTab === 'info' && (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="text-xs text-neutral-500 mb-1 block">Mã lệnh</label>
                    <input className="input" placeholder="Mã lệnh" value={orderForm.orderCode} onChange={(e) => setOrderForm({ ...orderForm, orderCode: e.target.value })} />
                  </div>
                  <div>
                    <label className="text-xs text-neutral-500 mb-1 block">Công thức</label>
                    <select className="input" value={orderForm.recipeId} onChange={(e) => onRecipeChange(Number(e.target.value))}>
                      <option value={0}>Chọn công thức</option>
                      {recipes.map((recipe) => <option key={recipe.recipeId} value={recipe.recipeId}>#{recipe.recipeId} - {recipe.recipeName}</option>)}
                    </select>
                  </div>
                  <div>
                    <label className="text-xs text-neutral-500 mb-1 block">Số lượng kế hoạch</label>
                    <input type="number" className="input" placeholder="Số lượng kế hoạch" value={orderForm.plannedQuantity} onChange={(e) => setOrderForm({ ...orderForm, plannedQuantity: Number(e.target.value) })} />
                  </div>
                  <div>
                    <label className="text-xs text-neutral-500 mb-1 block">Trạng thái</label>
                    <select className="input" value={orderForm.status} onChange={(e) => setOrderForm({ ...orderForm, status: e.target.value as OrderStatus })}>
                      <option value="Draft">Draft</option>
                      <option value="Approved">Approved</option>
                      <option value="InProcess">InProcess</option>
                      <option value="Hold">Hold</option>
                      <option value="Completed">Completed</option>
                    </select>
                  </div>
                  <div>
                    <label className="text-xs text-neutral-500 mb-1 block">Ngày bắt đầu dự kiến</label>
                    <input type="date" className="input" value={orderForm.startDate} onChange={(e) => setOrderForm({ ...orderForm, startDate: e.target.value })} />
                  </div>
                  <div>
                    <label className="text-xs text-neutral-500 mb-1 block">Ngày kết thúc dự kiến</label>
                    <input type="date" className="input" value={orderForm.endDate} onChange={(e) => setOrderForm({ ...orderForm, endDate: e.target.value })} />
                  </div>
                </div>
              )}

              {activeTab === 'routing' && (
                <div className="space-y-6">
                  <div className="flex items-center justify-between">
                    <h3 className="font-semibold text-neutral-800">Danh sách công đoạn</h3>
                    <button onClick={handleAddStep} className="btn-ghost text-primary-600 text-sm">
                      <Plus className="w-4 h-4 mr-1" /> Thêm công đoạn
                    </button>
                  </div>

                  {customRoutings.length === 0 ? (
                    <div className="text-center py-8 border-2 border-dashed border-neutral-200 rounded-xl">
                      <p className="text-neutral-500">Chưa có công đoạn nào được cấu hình.</p>
                    </div>
                  ) : (
                    <div className="space-y-4">
                      {customRoutings.map((step, sIdx) => (
                        <div key={sIdx} className="p-4 border border-neutral-200 rounded-xl bg-neutral-50/50 space-y-4">
                          <div className="flex items-start justify-between gap-4">
                            <div className="w-12">
                              <label className="text-[10px] text-neutral-400 uppercase font-bold">Thứ tự</label>
                              <input 
                                type="number" 
                                className="input py-1 px-2 text-center" 
                                value={step.stepNumber} 
                                onChange={(e) => handleUpdateStep(sIdx, { stepNumber: Number(e.target.value) })}
                              />
                            </div>
                            <div className="flex-1">
                              <label className="text-[10px] text-neutral-400 uppercase font-bold">Tên công đoạn</label>
                              <input 
                                className="input py-1" 
                                value={step.stepName} 
                                onChange={(e) => handleUpdateStep(sIdx, { stepName: e.target.value })}
                              />
                            </div>
                            <div className="w-40">
                              <label className="text-[10px] text-neutral-400 uppercase font-bold">Thiết bị mặc định</label>
                              <select 
                                className="input py-1" 
                                value={step.defaultEquipmentId || 0}
                                onChange={(e) => handleUpdateStep(sIdx, { defaultEquipmentId: Number(e.target.value) })}
                              >
                                <option value={0}>Chọn thiết bị</option>
                                {equipments.map(eq => (
                                  <option key={eq.equipmentId} value={eq.equipmentId}>{eq.equipmentName}</option>
                                ))}
                              </select>
                            </div>
                            <button onClick={() => handleRemoveStep(sIdx)} className="mt-6 text-red-500 hover:text-red-700">
                              <Trash2 className="w-4 h-4" />
                            </button>
                          </div>

                          <div className="pl-4 border-l-2 border-primary-200 space-y-2">
                            <div className="flex items-center justify-between">
                              <span className="text-xs font-bold text-neutral-500 uppercase">Thông số kiểm soát</span>
                              <button onClick={() => handleAddParam(sIdx)} className="text-[10px] text-primary-600 hover:underline">
                                + Thêm thông số
                              </button>
                            </div>
                            
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
                              {step.stepParameters?.map((param, pIdx) => (
                                <div key={pIdx} className="flex items-center gap-2 bg-white p-2 rounded-lg border border-neutral-200 group">
                                  <input 
                                    className="flex-1 text-xs border-none focus:ring-0 p-0" 
                                    placeholder="Tên thông số" 
                                    value={param.parameterName} 
                                    onChange={(e) => handleUpdateParam(sIdx, pIdx, { parameterName: e.target.value })}
                                  />
                                  <input 
                                    className="w-12 text-xs border-none focus:ring-0 p-0 text-neutral-500" 
                                    placeholder="Đơn vị" 
                                    value={param.unit || ''} 
                                    onChange={(e) => handleUpdateParam(sIdx, pIdx, { unit: e.target.value })}
                                  />
                                  <button onClick={() => handleRemoveParam(sIdx, pIdx)} className="text-neutral-300 hover:text-red-500 opacity-0 group-hover:opacity-100 transition-opacity">
                                    <Trash2 className="w-3 h-3" />
                                  </button>
                                </div>
                              ))}
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              )}
            </div>

            <div className="p-6 border-t border-neutral-200 flex justify-end gap-2 bg-neutral-50">
              <button onClick={() => setShowOrderModal(false)} className="btn-ghost">Hủy</button>
              <button 
                onClick={() => (editingOrder ? updateOrderMutation.mutate() : createOrderMutation.mutate())} 
                className="btn-primary px-8"
                disabled={createOrderMutation.isPending || updateOrderMutation.isPending}
              >
                {createOrderMutation.isPending || updateOrderMutation.isPending ? 'Đang lưu...' : (editingOrder ? 'Lưu cập nhật' : 'Tạo mới lệnh')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
