import { useMemo, useRef, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { certificatesApi, productionBatchesApi, productionOrdersApi, recipesApi } from '@/services/api';
import { Calculator, CheckCircle2, ClipboardList, FileCheck2, Layers, Pencil, Search, Trash2, Upload, X } from 'lucide-react';
import { formatNumber, formatDate } from '@/utils/format';

type OrderStatus = 'Draft' | 'Approved' | 'InProcess' | 'Hold' | 'Completed';

interface UiProductionOrder {
  orderId: number;
  orderCode: string;
  recipeId: number;
  recipeName?: string;
  uomName?: string;
  plannedQuantity: number;
  status: OrderStatus;
  plannedStartDate?: string;
  plannedEndDate?: string;
  productionOrderBoms?: any[];
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

function statusClass(status: string) {
  if (status === 'Draft') return 'bg-gray-100 text-gray-700 border-gray-200';
  if (status === 'Approved') return 'bg-green-100 text-green-700 border-green-200';
  if (status === 'InProcess') return 'bg-orange-100 text-orange-700 border-orange-200';
  if (status === 'Hold') return 'bg-red-100 text-red-700 border-red-200';
  if (status === 'Scheduled') return 'bg-blue-100 text-blue-700 border-blue-200';
  if (status === 'Completed') return 'bg-green-100 text-green-700 border-green-200';
  return 'bg-gray-100 text-gray-700 border-gray-200';
}

function getStatusLabel(status: string) {
  if (status === 'Draft') return 'Bản nháp';
  if (status === 'Approved') return 'Đã duyệt';
  if (status === 'InProcess') return 'Đang chạy';
  if (status === 'Hold') return 'Chờ';
  if (status === 'Scheduled') return 'Đã lên lịch';
  if (status === 'Completed') return 'Hoàn thành';
  return status;
}

type MassUnit = 'kg' | 'g' | 'vien';


export default function ProductionOrders() {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [showOrderModal, setShowOrderModal] = useState(false);
  const [editingOrder, setEditingOrder] = useState<UiProductionOrder | null>(null);
  const [batchPopupOrderId, setBatchPopupOrderId] = useState<number | null>(null);
  const [batchPopupLabel, setBatchPopupLabel] = useState('');
  const [uploadingForBatch, setUploadingForBatch] = useState<string | null>(null);
  const uploadInputRef = useRef<HTMLInputElement>(null);

  const [orderForm, setOrderForm] = useState({
    orderCode: '',
    recipeId: 0,
    plannedQuantity: 0,
    startDate: '',
    endDate: '',
    status: 'Approved' as OrderStatus,
  });

  const [planForm, setPlanForm] = useState({
    recipeId: 0,
    cartons: 0,
    bottlesPerCarton: 0,
    tabletsPerBottle: 0,
    looseTablets: 0,
    massUnit: 'vien' as MassUnit,
  });

  const { data: ordersRaw, isLoading } = useQuery({ queryKey: ['productionOrders'], queryFn: () => productionOrdersApi.getAll() });
  const { data: recipesRaw } = useQuery({ queryKey: ['recipes'], queryFn: () => recipesApi.getAll() });

  const recipes = useMemo(() => toRows<any>(recipesRaw).map((r) => {
    const rName = r.recipeName ?? r.RecipeName ?? '';
    const mName = r.material?.materialName ?? r.Material?.MaterialName ?? `Sản phẩm #${r.materialId ?? r.MaterialId}`;
    return {
      recipeId: Number(r.recipeId ?? r.RecipeId ?? 0),
      recipeName: rName ? `${rName} - ${mName}` : mName,
      batchSize: Number(r.batchSize ?? r.BatchSize ?? 0),
      uomName: r.material?.baseUom?.uomName ?? r.Material?.BaseUom?.UomName ?? 'viên',
    };
  }), [recipesRaw]);

  const selectedPlanRecipe = useMemo(() => recipes.find((r) => r.recipeId === planForm.recipeId) ?? null, [recipes, planForm.recipeId]);

  const { data: bomRaw } = useQuery({
    queryKey: ['recipeBom', planForm.recipeId],
    queryFn: () => recipesApi.getBOM(planForm.recipeId),
    enabled: planForm.recipeId > 0,
  });

  const { data: inventoryRaw } = useQuery({ queryKey: ['inventoryLots'], queryFn: () => (import('@/services/api').then(m => m.inventoryApi.getAll())) });

  const bomItems = useMemo(() => toRows<any>(bomRaw).map((item: any) => ({
    materialId: Number(item.materialId ?? item.MaterialId ?? 0),
    materialCode: item.material?.materialCode ?? item.Material?.MaterialCode ?? '',
    materialName: item.material?.materialName ?? item.Material?.MaterialName ?? 'Nguyên liệu',
    mgPerTablet: Number(item.quantity ?? item.Quantity ?? 0),
    wastePercentage: Number(item.wastePercentage ?? item.WastePercentage ?? 0),
  })), [bomRaw]);

  const stockByMaterial = useMemo(() => {
    const map = new Map<number, number>();
    toRows<any>(inventoryRaw).forEach((lot: any) => {
      const mid = Number(lot.materialId ?? 0);
      const qty = Number(lot.quantityCurrent ?? 0);
      map.set(mid, (map.get(mid) ?? 0) + qty);
    });
    return map;
  }, [inventoryRaw]);

  const totalTablets = useMemo(() => {
    const packed = Math.max(planForm.cartons, 0) * Math.max(planForm.bottlesPerCarton, 0) * Math.max(planForm.tabletsPerBottle, 0);
    return packed + Math.max(planForm.looseTablets, 0);
  }, [planForm]);

  const oneTabletMg = selectedPlanRecipe?.batchSize ?? 0;


  const requiredMaterials = useMemo(() => {
    return bomItems.map((item) => {
      // Robust packaging detection
      const nameLower = item.materialName.toLowerCase();
      const isPackaging = nameLower.includes('vỏ nang') || 
                          nameLower.includes('vỏ') || 
                          nameLower.includes('ống') || 
                          nameLower.includes('màng') || 
                          nameLower.includes('pvc');
      
      const baseRequired = (totalTablets * item.mgPerTablet);
      
      let requiredValue: number;
      if (isPackaging) {
        // No waste for packaging (UOM 4 - pieces)
        requiredValue = baseRequired;
      } else {
        // Apply waste and convert mg to kg
        const wasteFactor = 1 + (item.wastePercentage / 100);
        requiredValue = (baseRequired * wasteFactor) / 1_000_000;
      }
        
      const available = stockByMaterial.get(item.materialId) ?? 0;
      return { ...item, requiredKg: requiredValue, available, enough: available >= requiredValue, isPackaging };
    });
  }, [bomItems, totalTablets, stockByMaterial]);

  const insufficientMaterials = useMemo(() => requiredMaterials.filter((m) => !m.enough), [requiredMaterials]);

  const totalMassMgExclPackaging = useMemo(() => {
    return requiredMaterials
      .filter(m => !m.isPackaging)
      .reduce((acc, m) => acc + (totalTablets * m.mgPerTablet), 0);
  }, [requiredMaterials, totalTablets]);

  const displayFinishedMass = useMemo(() => {
    if (planForm.massUnit === 'g') return `${formatNumber(totalMassMgExclPackaging / 1000)} g`;
    if (planForm.massUnit === 'vien') return `${formatNumber(totalTablets, 0)} viên`;
    return `${formatNumber(totalMassMgExclPackaging / 1_000_000, 3)} kg`;
  }, [planForm.massUnit, totalMassMgExclPackaging, totalTablets]);

  const orders = useMemo<UiProductionOrder[]>(() => toRows<any>(ordersRaw).map((o) => {
    const recipe = recipes.find((r) => r.recipeId === Number(o.recipeId ?? o.RecipeId));
    const rName = o.recipe?.recipeName ?? o.recipe?.RecipeName ?? recipe?.recipeName ?? '';
    const mName = o.recipe?.material?.materialName ?? o.recipe?.Material?.MaterialName ?? '';
    
    return {
      orderId: Number(o.orderId ?? o.OrderId ?? 0),
      orderCode: o.orderCode ?? o.OrderCode ?? '',
      recipeId: Number(o.recipeId ?? o.RecipeId ?? 0),
      recipeName: rName ? `${rName} - ${mName}` : mName,
      uomName: o.recipe?.material?.baseUom?.uomName ?? recipe?.uomName ?? 'viên',
      plannedQuantity: Number(o.plannedQuantity ?? o.PlannedQuantity ?? 0),
      status: (o.status ?? o.Status ?? 'Draft') as OrderStatus,
      plannedStartDate: o.startDate ?? o.StartDate,
      plannedEndDate: o.endDate ?? o.EndDate,
      productionOrderBoms: o.productionOrderBoms ?? o.ProductionOrderBoms,
    };
  }), [ordersRaw, recipes]);

  const filteredOrders = useMemo(() => {
    const keyword = search.trim().toLowerCase();
    if (!keyword) return orders;
    return orders.filter((order) => order.orderCode.toLowerCase().includes(keyword));
  }, [orders, search]);

  const { data: batchesRaw } = useQuery({
    queryKey: ['batchesForOrder', batchPopupOrderId],
    queryFn: () => productionBatchesApi.getByOrder(batchPopupOrderId!),
    enabled: batchPopupOrderId !== null,
    refetchInterval: batchPopupOrderId !== null ? 3000 : false,
  });

  const { data: techSpecsRaw } = useQuery({
    queryKey: ['orderTechSpecs', batchPopupOrderId],
    queryFn: () => recipesApi.getTechSpecsByOrder(batchPopupOrderId!),
    enabled: batchPopupOrderId !== null,
  });

  const orderTechSpecs = useMemo(() => toRows<any>(techSpecsRaw), [techSpecsRaw]);

  const allSpecsChecked = useMemo(() => {
    if (orderTechSpecs.length === 0) return true;
    return orderTechSpecs.every(s => s.isChecked);
  }, [orderTechSpecs]);

  const batchesForPopup = useMemo(() => {
    if (batchPopupOrderId === null) return [];
    return toRows<any>(batchesRaw);
  }, [batchesRaw, batchPopupOrderId]);

  const createOrderFromPlanMutation = useMutation({
    mutationFn: async () => {
      if (insufficientMaterials.length) throw new Error('Không đủ nguyên liệu tồn kho.');
      const now = new Date();
      const end = new Date(now); end.setDate(end.getDate() + 7);
      await productionOrdersApi.create({
        recipeId: planForm.recipeId,
        plannedQuantity: totalTablets,
        startDate: now.toISOString(),
        endDate: end.toISOString(),
        status: 'Approved',
      } as any);
    },
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['productionOrders'] });
      await queryClient.invalidateQueries({ queryKey: ['inventoryLots'] });
      await queryClient.invalidateQueries({ queryKey: ['inventory-lots'] });
      alert('Đã tạo lệnh sản xuất thành công.');
    },
    onError: (err: any) => alert(err?.response?.data?.message ?? err?.message ?? 'Không thể tạo lệnh sản xuất'),
  });

  const createOrderMutation = useMutation({
    mutationFn: () => productionOrdersApi.create({
      recipeId: orderForm.recipeId,
      plannedQuantity: orderForm.plannedQuantity,
      startDate: orderForm.startDate ? orderForm.startDate : undefined,
      endDate: orderForm.endDate ? orderForm.endDate : undefined,
      status: orderForm.status,
    } as any),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['productionOrders'] });
      setShowOrderModal(false);
    },
    onError: (err: any) => alert(err?.response?.data?.message ?? 'Không thể tạo lệnh sản xuất'),
  });

  const updateOrderMutation = useMutation({
    mutationFn: () => productionOrdersApi.update(editingOrder!.orderId, {
      orderCode: orderForm.orderCode,
      recipeId: orderForm.recipeId,
      plannedQuantity: orderForm.plannedQuantity,
      startDate: orderForm.startDate ? orderForm.startDate : undefined,
      endDate: orderForm.endDate ? orderForm.endDate : undefined,
      status: orderForm.status,
    } as any),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['productionOrders'] });
      setShowOrderModal(false);
      setEditingOrder(null);
    },
    onError: (err: any) => alert(err?.response?.data?.message ?? 'Không thể cập nhật lệnh sản xuất'),
  });


  const deleteOrderMutation = useMutation({
    mutationFn: (id: number) => productionOrdersApi.delete(id),
    onSuccess: async () => queryClient.invalidateQueries({ queryKey: ['productionOrders'] }),
  });

  const uploadBatchCertMutation = useMutation({
    mutationFn: ({ batchNumber, file }: { batchNumber: string; file: File }) =>
      certificatesApi.uploadBatchCertificate(batchNumber, file),
    onSuccess: () => { setUploadingForBatch(null); alert('Đã tải giấy kiểm nghiệm mẻ thành công.'); },
    onError: (err: any) => alert(err?.response?.data?.message ?? 'Không thể tải lên giấy kiểm nghiệm.'),
  });

  const holdOrderMutation = useMutation({
    mutationFn: (id: number) => productionOrdersApi.hold(id),
    onSuccess: async () => { await queryClient.invalidateQueries({ queryKey: ['productionOrders'] }); alert('Đã tạm dừng lệnh sản xuất.'); },
    onError: (err: any) => alert(err?.response?.data?.message ?? err?.message ?? 'Không thể tạm dừng lệnh.'),
  });

  const resumeOrderMutation = useMutation({
    mutationFn: (id: number) => productionOrdersApi.resume(id),
    onSuccess: async () => { await queryClient.invalidateQueries({ queryKey: ['productionOrders'] }); alert('Đã chuyển lệnh về trạng thái Approved.'); },
    onError: (err: any) => alert(err?.response?.data?.message ?? err?.message ?? 'Không thể tiếp tục lệnh.'),
  });



  const openEditOrder = (order: UiProductionOrder) => {
    setEditingOrder(order);
    setOrderForm({
      orderCode: order.orderCode,
      recipeId: order.recipeId,
      plannedQuantity: order.plannedQuantity,
      startDate: order.plannedStartDate ? order.plannedStartDate.split('T')[0] : '',
      endDate: order.plannedEndDate ? order.plannedEndDate.split('T')[0] : '',
      status: order.status,
    });
    setShowOrderModal(true);
  };

  const openBatchPopup = (order: UiProductionOrder) => {
    setBatchPopupOrderId(order.orderId);
    setBatchPopupLabel(`${order.orderCode} — ${order.recipeName ?? ''}`);
  };

  const allStatuses: OrderStatus[] = ['Draft', 'Approved', 'InProcess', 'Hold', 'Completed'];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Quản lý lệnh sản xuất</h1>
          <p className="text-neutral-500 mt-1">Lập lệnh sản xuất và kiểm tra tồn kho/ngưỡng thiết bị</p>
        </div>
      </div>

      {/* Planning Panel */}
      <div className="rounded-xl border border-primary-200 bg-primary-50/40 p-4 space-y-4">
        <div className="flex items-center gap-2"><Calculator className="w-5 h-5 text-primary-700" /><h3 className="text-lg font-semibold text-primary-900">Lập lệnh sản xuất</h3></div>

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
          <div className="p-3 rounded-lg bg-white border border-primary-200"><p className="text-neutral-500">Tổng số viên</p><p className="text-xl font-bold text-neutral-900">{formatNumber(totalTablets, 0)}</p></div>
          <div className="p-3 rounded-lg bg-white border border-primary-200"><p className="text-neutral-500">Khối lượng 1 viên</p><p className="text-xl font-bold text-neutral-900">{formatNumber(oneTabletMg)} mg</p></div>
          <div className="p-3 rounded-lg bg-white border border-primary-200"><p className="text-neutral-500">Khối lượng thành phẩm lý thuyết</p><p className="text-xl font-bold text-neutral-900">{displayFinishedMass}</p></div>
        </div>

        {insufficientMaterials.length > 0 && (
          <div className="border border-red-300 bg-red-50 rounded-lg p-3 text-red-700 text-sm">
            <p className="font-semibold mb-1">Không đủ nguyên liệu tồn kho:</p>
            {insufficientMaterials.map((m) => (
              <p key={m.materialId}>
                - {m.materialName}: cần {formatNumber(m.requiredKg, 4)} {m.isPackaging ? 'viên' : 'kg'}, hiện có {formatNumber(m.available, 4)} {m.isPackaging ? 'viên' : 'kg'}
              </p>
            ))}
          </div>
        )}

        {requiredMaterials.length > 0 && (
          <div className="table-container bg-white rounded-lg border border-primary-200">
            <table className="table">
              <thead><tr><th>Nguyên liệu</th><th>Định mức (mg/viên)</th><th>Số lượng cần (kg/viên)</th><th>Tồn hiện tại</th><th>Đủ/Thiếu</th></tr></thead>
              <tbody>
                {requiredMaterials.map((item, idx) => (
                  <tr key={`${item.materialId}-${idx}`}>
                    <td>{item.materialName} {item.isPackaging && <span className="text-[10px] bg-neutral-100 px-1 rounded text-neutral-500">Packaging</span>}</td>
                    <td>{item.isPackaging ? "-" : formatNumber(item.mgPerTablet)}</td>
                    <td>{formatNumber(item.requiredKg, item.isPackaging ? 0 : 4)}</td>
                    <td>{formatNumber(item.available, item.isPackaging ? 0 : 4)}</td>
                    <td>
                      <span className={`px-2 py-1 rounded-full text-xs ${item.enough ? 'bg-emerald-100 text-emerald-700' : 'bg-red-100 text-red-700'}`}>
                        {item.enough ? 'Đủ' : 'Thiếu'}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        <div className="flex justify-end">
          <button className="btn-primary" disabled={planForm.recipeId <= 0 || totalTablets <= 0 || insufficientMaterials.length > 0 || createOrderFromPlanMutation.isPending} onClick={() => createOrderFromPlanMutation.mutate()}>
            Tạo lệnh sản xuất theo kế hoạch
          </button>
        </div>
      </div>

      {/* Search */}
      <div className="card">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-neutral-400" />
          <input type="text" placeholder="Tìm kiếm theo mã lệnh..." value={search} onChange={(e) => setSearch(e.target.value)} className="input pl-10" />
        </div>
      </div>

      {/* Orders table */}
      <div className="card p-0 overflow-hidden">
        {isLoading ? (
          <div className="flex items-center justify-center p-12"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div></div>
        ) : filteredOrders.length === 0 ? (
          <div className="text-center py-12"><ClipboardList className="w-12 h-12 text-neutral-300 mx-auto mb-4" /><p className="text-neutral-500">Không tìm thấy lệnh sản xuất nào.</p></div>
        ) : (
          <div className="table-container">
            <table className="table">
              <thead>
                <tr>
                  <th>Mã lệnh</th>
                  <th>Công thức</th>
                  <th>Số lượng kế hoạch</th>
                  <th>Trạng thái</th>
                  <th>Dự kiến bắt đầu</th>
                  <th className="text-right">Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {filteredOrders.map((order) => (
                  <tr key={order.orderId}>
                    <td>
                      <button
                        onClick={() => openBatchPopup(order)}
                        className="flex items-center gap-1.5 text-primary-600 hover:text-primary-800 hover:underline transition-colors"
                        title="Xem danh sách mẻ"
                      >
                        <code className="text-xs bg-neutral-100 px-2 py-1 rounded font-mono">{order.orderCode}</code>
                        <Layers className="w-3.5 h-3.5 opacity-60" />
                      </button>
                    </td>
                     <td className="font-medium text-neutral-900">{order.recipeName || `Công thức #${order.recipeId}`}</td>
                    <td>{formatNumber(order.plannedQuantity, 0)} <span className="text-neutral-500 text-xs">{order.uomName}</span></td>
                    <td>
                      <span className={`px-2 py-1 rounded-full text-[10px] font-bold border ${statusClass(order.status)}`}>
                        {getStatusLabel(order.status)}
                      </span>
                    </td>
                    <td>{formatDate(order.plannedStartDate)}</td>
                    <td className="text-right">
                      <div className="flex justify-end gap-2">
                        {order.status === 'Approved' && (
                          <button onClick={() => holdOrderMutation.mutate(order.orderId)} className="btn-ghost text-sm text-orange-600">Tạm dừng</button>
                        )}
                        {order.status === 'Hold' && (
                          <button onClick={() => resumeOrderMutation.mutate(order.orderId)} className="btn-ghost text-sm text-blue-600">Tiếp tục</button>
                        )}
                        {(order.status === 'Draft' || order.status === 'Hold') && (
                          <button onClick={() => openEditOrder(order)} className="btn-ghost text-sm"><Pencil className="w-4 h-4 mr-1" />Sửa</button>
                        )}
                        <button onClick={() => { 
                          if (order.status === 'Completed') {
                            alert('Lệnh này đã hoàn thành, không thể xoá!');
                            return;
                          }
                          if (confirm('Xóa lệnh sản xuất này?')) deleteOrderMutation.mutate(order.orderId); 
                        }} className="btn-ghost text-sm text-red-600"><Trash2 className="w-4 h-4 mr-1" />Xóa</button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Order create/edit modal */}
      {showOrderModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4" onClick={() => { setShowOrderModal(false); setEditingOrder(null); }}>
          <div className="bg-white rounded-2xl w-full max-w-2xl p-6 space-y-4" onClick={(e) => e.stopPropagation()}>
            <h2 className="text-xl font-bold">{editingOrder ? 'Cập nhật lệnh sản xuất' : 'Tạo lệnh sản xuất'}</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div><label className="text-xs text-neutral-500">Mã lệnh (Tự động)</label>
                <input disabled className="input bg-neutral-100 cursor-not-allowed" placeholder="Hệ thống tự sinh" value={orderForm.orderCode} />
              </div>
              <div><label className="text-xs text-neutral-500">Công thức</label>
                <select className="input" value={orderForm.recipeId} onChange={(e) => setOrderForm({ ...orderForm, recipeId: Number(e.target.value) })}>
                  <option value={0}>Chọn công thức</option>
                  {recipes.map((recipe) => <option key={recipe.recipeId} value={recipe.recipeId}>#{recipe.recipeId} - {recipe.recipeName}</option>)}
                </select>
              </div>
              <div><label className="text-xs text-neutral-500">Số lượng kế hoạch</label>
                <input type="number" className="input" placeholder="Số lượng kế hoạch" value={orderForm.plannedQuantity} onChange={(e) => setOrderForm({ ...orderForm, plannedQuantity: Number(e.target.value) })} />
              </div>
              <div><label className="text-xs text-neutral-500">Trạng thái</label>
                <select disabled className="input bg-neutral-100 cursor-not-allowed" value={orderForm.status} onChange={(e) => setOrderForm({ ...orderForm, status: e.target.value as OrderStatus })}>
                  {allStatuses.map((s) => <option key={s} value={s}>{s}</option>)}
                </select>
              </div>
              <div><label className="text-xs text-neutral-500">Ngày bắt đầu</label>
                <input type="date" className="input" max={new Date().toISOString().split('T')[0]} value={orderForm.startDate ? orderForm.startDate.split('T')[0] : ''} onChange={(e) => setOrderForm({ ...orderForm, startDate: e.target.value })} />
              </div>
              <div><label className="text-xs text-neutral-500">Ngày kết thúc dự kiến</label>
                <input type="date" className="input" min={orderForm.startDate ? orderForm.startDate.split('T')[0] : new Date().toISOString().split('T')[0]} value={orderForm.endDate ? orderForm.endDate.split('T')[0] : ''} onChange={(e) => setOrderForm({ ...orderForm, endDate: e.target.value })} />
              </div>
            </div>

            {/* Hold order: packaging edit fields */}
            {editingOrder && editingOrder.status === 'Hold' && (
              <div className="border border-orange-200 bg-orange-50 rounded-xl p-4 space-y-3">
                <h3 className="text-sm font-semibold text-orange-700">Chỉnh sửa chi tiết đóng gói (lệnh đang Hold)</h3>
                <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
                  <div><label className="text-xs text-neutral-500">Đơn vị hiển thị KL thành phẩm</label>
                    <select className="input" value={planForm.massUnit} onChange={(e) => setPlanForm({ ...planForm, massUnit: e.target.value as MassUnit })}>
                      <option value="kg">kg</option>
                      <option value="g">g</option>
                      <option value="vien">viên</option>
                    </select>
                  </div>
                  <div><label className="text-xs text-neutral-500">Số thùng</label>
                    <input type="number" min={0} className="input" value={planForm.cartons} onChange={(e) => setPlanForm({ ...planForm, cartons: Number(e.target.value) })} />
                  </div>
                  <div><label className="text-xs text-neutral-500">Số chai/thùng</label>
                    <input type="number" min={0} className="input" value={planForm.bottlesPerCarton} onChange={(e) => setPlanForm({ ...planForm, bottlesPerCarton: Number(e.target.value) })} />
                  </div>
                  <div><label className="text-xs text-neutral-500">Số viên/chai</label>
                    <input type="number" min={0} className="input" value={planForm.tabletsPerBottle} onChange={(e) => setPlanForm({ ...planForm, tabletsPerBottle: Number(e.target.value) })} />
                  </div>
                  <div><label className="text-xs text-neutral-500">Viên lẻ</label>
                    <input type="number" min={0} className="input" value={planForm.looseTablets} onChange={(e) => setPlanForm({ ...planForm, looseTablets: Number(e.target.value) })} />
                  </div>
                  <div><label className="text-xs text-neutral-500">Tổng viên tính được</label>
                    <input type="number" className="input bg-neutral-100" readOnly value={Math.max(planForm.cartons,0) * Math.max(planForm.bottlesPerCarton,0) * Math.max(planForm.tabletsPerBottle,0) + Math.max(planForm.looseTablets,0)} />
                  </div>
                </div>
                <button className="btn-secondary text-sm" onClick={() => {
                  const total = Math.max(planForm.cartons,0) * Math.max(planForm.bottlesPerCarton,0) * Math.max(planForm.tabletsPerBottle,0) + Math.max(planForm.looseTablets,0);
                  setOrderForm({ ...orderForm, plannedQuantity: total });
                }}>Áp dụng số lượng vào lệnh</button>
              </div>
            )}
            <div className="flex justify-end gap-2">
              <button onClick={() => { setShowOrderModal(false); setEditingOrder(null); }} className="btn-ghost">Hủy</button>
              <button onClick={() => (editingOrder ? updateOrderMutation.mutate() : createOrderMutation.mutate())} className="btn-primary">{editingOrder ? 'Lưu cập nhật' : 'Tạo mới'}</button>
            </div>
          </div>
        </div>
      )}

      {/* Batch popup */}
      {batchPopupOrderId !== null && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4" onClick={() => { setBatchPopupOrderId(null); setUploadingForBatch(null); }}>
          <div className="bg-white rounded-2xl w-full max-w-6xl max-h-[90vh] overflow-y-auto p-6 space-y-4" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between">
              <div>
                <h2 className="text-xl font-bold">Danh sách mẻ sản xuất</h2>
                <p className="text-sm text-neutral-500 mt-0.5">Lệnh: {batchPopupLabel}</p>
              </div>
              <button onClick={() => { setBatchPopupOrderId(null); setUploadingForBatch(null); }} className="p-2 rounded-lg hover:bg-neutral-100">
                <X className="w-5 h-5 text-neutral-600" />
              </button>
            </div>

            {/* Order BOM Summary in Popup */}
            {filteredOrders.find(o => o.orderId === batchPopupOrderId)?.productionOrderBoms && (
              <div className="bg-neutral-50 border border-neutral-200 rounded-xl p-4">
                <h3 className="text-sm font-bold text-neutral-700 mb-3 flex items-center gap-2">
                  <ClipboardList className="w-4 h-4" />
                  Định mức nguyên liệu cho toàn lệnh (BOM)
                </h3>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3">
                  {filteredOrders.find(o => o.orderId === batchPopupOrderId)?.productionOrderBoms?.map((bom: any) => (
                    <div key={bom.orderBomId} className="bg-white p-2.5 rounded-lg border border-neutral-200 flex justify-between items-center shadow-sm">
                      <div>
                        <p className="text-xs font-semibold text-neutral-900">{bom.materialName}</p>
                        <p className="text-[10px] text-neutral-500">Mã: {bom.materialCode ?? '-'}</p>
                      </div>
                      <div className="text-right">
                        <p className="text-xs font-bold text-primary-700">{formatNumber(bom.requiredQuantity, 4)} {bom.uomName || 'kg'}</p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
            <div className="table-container">
              <table className="table">
                <thead>
                  <tr>
                    <th>Mã mẻ</th>
                    <th>Trạng thái</th>
                    <th>Bước hiện tại</th>
                    <th>Ngày bắt đầu</th>
                    <th>Ngày kết thúc</th>
                    <th>Giấy kiểm nghiệm</th>
                  </tr>
                </thead>
                <tbody>
                  {batchesForPopup.length === 0 ? (
                    <tr><td colSpan={5} className="text-center text-neutral-500 py-6">Chưa có mẻ nào cho lệnh này.</td></tr>
                  ) : batchesForPopup.map((b: any) => {
                    const s = b.status ?? b.Status ?? '';
                    const batchNum = b.batchNumber ?? b.BatchNumber ?? '';
                    const isCompleted = s === 'Completed';
                    const rawStep = Number(b.currentStep ?? b.CurrentStep ?? 0);
                    const currentStepDisplay =
                      (s === 'In-Process' && rawStep <= 0) ? 1 : rawStep;
                    return (
                      <tr key={b.batchId ?? b.BatchId}>
                        <td><code className="text-xs bg-neutral-100 px-2 py-1 rounded font-mono text-primary-600">{batchNum}</code></td>
                        <td><span className={`text-[10px] font-bold px-2 py-1 rounded-full border ${statusClass(s)}`}>{getStatusLabel(s)}</span></td>
                        <td>{Number.isFinite(currentStepDisplay) ? currentStepDisplay : '-'}</td>
                        <td>{formatDate(b.manufactureDate)}</td>
                        <td>{formatDate(b.endTime)}</td>
                        <td>
                          {isCompleted ? (
                            <div className="flex items-center gap-2">
                              <a href={certificatesApi.getBatchCertificateUrl(batchNum)} target="_blank" rel="noreferrer" className="text-primary-600 hover:underline inline-flex items-center text-xs">
                                <FileCheck2 className="w-3.5 h-3.5 mr-1" />Xem
                              </a>
                              <button
                                className={`text-xs inline-flex items-center ${allSpecsChecked ? 'text-primary-600 hover:underline' : 'text-neutral-400 cursor-not-allowed'}`}
                                disabled={!allSpecsChecked}
                                title={!allSpecsChecked ? "Cần đạt tất cả các tiêu chuẩn kĩ thuật trước" : ""}
                                onClick={() => { setUploadingForBatch(batchNum); uploadInputRef.current?.click(); }}
                              >
                                <Upload className="w-3.5 h-3.5 mr-1" />Tải lên
                              </button>
                            </div>
                          ) : (
                            <span className="text-xs text-neutral-400">-</span>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>

            {/* Tech Specs Verification Section */}
            {orderTechSpecs.length > 0 && (
              <div className="bg-primary-50/50 border border-primary-200 rounded-xl p-4">
                <h3 className="text-sm font-bold text-primary-800 mb-3 flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4" />
                  Tiêu chuẩn kỹ thuật (QC)
                </h3>
                <div className="space-y-2">
                  {orderTechSpecs.filter((s) => !s.parentId).map((spec) => (
                    <div key={spec.specId} className="space-y-1">
                      <div className="text-sm text-neutral-800 font-medium">{spec.content}</div>
                      {orderTechSpecs
                        .filter((sub) => sub.parentId === spec.specId)
                        .map((sub) => (
                          <div key={sub.specId} className="text-xs text-neutral-700 ml-6">{sub.content}</div>
                        ))}
                    </div>
                  ))}
                </div>
                <p className="text-[10px] text-primary-600 mt-2 italic font-medium">* Xác nhận checklist và tải giấy kiểm nghiệm thực hiện trên giao diện QC Mobile.</p>
              </div>
            )}
{/* Hidden file input for batch cert upload */}
            <input
              ref={uploadInputRef}
              type="file"
              accept=".jpg,.jpeg,.png,.webp,.pdf"
              className="hidden"
              onChange={(e) => {
                const file = e.target.files?.[0];
                if (file && uploadingForBatch) {
                  uploadBatchCertMutation.mutate({ batchNumber: uploadingForBatch, file });
                }
                e.target.value = '';
              }}
            />
            {uploadBatchCertMutation.isPending && (
              <div className="text-sm text-primary-600 text-center">Đang tải lên giấy kiểm nghiệm...</div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
