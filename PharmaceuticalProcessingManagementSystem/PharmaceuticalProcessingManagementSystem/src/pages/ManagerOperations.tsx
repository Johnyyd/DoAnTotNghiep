import { useEffect, useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { LayoutPanelLeft, ListChecks, Route, ChevronRight } from 'lucide-react';
import { productionBatchesApi, productionOrdersApi, recipesApi } from '@/services/api';

type NormalizedRecipe = {
  recipeId: number;
  recipeCode: string;
  recipeName: string;
  status: string;
  versionNumber: number;
  batchSize: number;
  approvedDate?: string;
  materialName?: string;
};

type NormalizedRouting = {
  routingId: number;
  stepNumber: number;
  stepName: string;
  equipmentName: string;
  areaName: string;
  estimatedTimeMinutes: number;
  description?: string;
  standardTemperature?: string;
  standardHumidity?: string;
  standardPressure?: string;
};

type NormalizedOrder = {
  orderId: number;
  orderCode: string;
  recipeId: number;
  plannedQuantity: number;
  status: string;
  startDate?: string;
  endDate?: string;
  createdByName?: string;
};

type NormalizedBatch = {
  batchId: number;
  orderId: number;
  batchNumber: string;
  status: string;
  currentStep: number;
};

function normalizeStatus(raw?: string): string {
  if (!raw) return 'Draft';
  const value = raw.toLowerCase();
  if (value.includes('approved')) return 'Approved';
  if (value.includes('hold')) return 'Hold';
  if (value.includes('process')) return 'In-Process';
  if (value.includes('complete')) return 'Completed';
  if (value.includes('scheduled')) return 'Scheduled';
  return raw;
}

function getStatusClass(status: string) {
  switch (status) {
    case 'Completed': return 'bg-emerald-100 text-emerald-700';
    case 'In-Process': return 'bg-amber-100 text-amber-700';
    case 'Hold': return 'bg-orange-100 text-orange-700';
    case 'Scheduled': return 'bg-blue-100 text-blue-700';
    default: return 'bg-neutral-100 text-neutral-700';
  }
}

export default function ManagerOperations() {
  const [selectedOrderId, setSelectedOrderId] = useState<number | null>(null);
  const [viewedDescription, setViewedDescription] = useState<string | null>(null);

  const { data: recipesRaw } = useQuery({
    queryKey: ['recipes'],
    queryFn: () => recipesApi.getAll(),
    refetchInterval: 5000,
  });

  const { data: ordersRaw } = useQuery({
    queryKey: ['progressOrders'],
    queryFn: () => productionOrdersApi.getAll(),
    refetchInterval: 3000,
  });

  const { data: batchesRaw } = useQuery({
    queryKey: ['productionBatches'],
    queryFn: () => productionBatchesApi.getAll(),
    refetchInterval: 3000,
  });

  const recipes = useMemo<NormalizedRecipe[]>(() => {
    const rows = Array.isArray(recipesRaw) ? recipesRaw : (recipesRaw as any)?.data ?? [];
    return rows.map((item: any) => ({
      recipeId: Number(item.recipeId ?? item.RecipeId ?? 0),
      recipeCode: item.recipeCode ?? item.RecipeCode ?? `REC-${item.recipeId ?? item.RecipeId ?? ''}`,
      recipeName: item.recipeName ?? item.RecipeName ?? 'Công thức',
      status: normalizeStatus(item.status ?? item.Status),
      versionNumber: Number(item.versionNumber ?? item.VersionNumber ?? 1),
      batchSize: Number(item.batchSize ?? item.BatchSize ?? 0),
      approvedDate: item.approvedDate ?? item.ApprovedDate,
      materialName: item.material?.materialName ?? item.Material?.MaterialName,
    }));
  }, [recipesRaw]);

  const orders = useMemo<NormalizedOrder[]>(() => {
    const rows = Array.isArray(ordersRaw) ? ordersRaw : (ordersRaw as any)?.data ?? (ordersRaw as any)?.items ?? [];
    return rows.map((item: any) => ({
      orderId: Number(item.orderId ?? item.OrderId ?? 0),
      orderCode: item.orderCode ?? item.OrderCode ?? `PO-${item.orderId ?? item.OrderId ?? ''}`,
      recipeId: Number(item.recipeId ?? item.RecipeId ?? 0),
      plannedQuantity: Number(item.plannedQuantity ?? item.PlannedQuantity ?? 0),
      status: normalizeStatus(item.status ?? item.Status),
      startDate: item.startDate ?? item.StartDate,
      endDate: item.endDate ?? item.EndDate,
      createdByName: item.createdByName ?? item.CreatedByName,
    }));
  }, [ordersRaw]);

  const batches = useMemo<NormalizedBatch[]>(() => {
    const rows = Array.isArray(batchesRaw) ? batchesRaw : (batchesRaw as any)?.data ?? [];
    return rows.map((item: any) => ({
      batchId: Number(item.batchId ?? item.BatchId ?? 0),
      orderId: Number(item.orderId ?? item.OrderId ?? 0),
      batchNumber: item.batchNumber ?? item.BatchNumber ?? `BATCH-${item.batchId ?? item.BatchId ?? ''}`,
      status: normalizeStatus(item.status ?? item.Status ?? item.qcStatus ?? item.QcStatus),
      currentStep: Number(item.currentStep ?? item.CurrentStep ?? 1),
    }));
  }, [batchesRaw]);

  useEffect(() => {
    if (!selectedOrderId && orders.length) {
      const active = orders.find((o) => o.status === 'In-Process' || o.status === 'Hold' || o.status === 'Scheduled');
      setSelectedOrderId((active ?? orders[0]).orderId);
    }
  }, [orders, selectedOrderId]);

  const selectedOrder = useMemo(
    () => orders.find((order) => order.orderId === selectedOrderId) ?? null,
    [orders, selectedOrderId]
  );

  const selectedRecipe = useMemo(
    () => recipes.find((recipe) => recipe.recipeId === selectedOrder?.recipeId) ?? null,
    [recipes, selectedOrder],
  );

  const { data: routingRaw } = useQuery({
    queryKey: ['recipeRouting', selectedOrder?.recipeId, selectedOrderId],
    queryFn: () => productionOrdersApi.getCustomRoutings(selectedOrderId as number),
    enabled: !!selectedOrderId,
  });

  const routingSteps = useMemo<NormalizedRouting[]>(() => {
    const rows = Array.isArray(routingRaw) ? routingRaw : (routingRaw as any)?.data ?? [];
    return rows.map((item: any, index: number) => ({
      routingId: Number(item.routingId ?? item.RoutingId ?? index + 1),
      stepNumber: Number(item.stepNumber ?? item.StepNumber ?? index + 1),
      stepName: item.stepName ?? item.StepName ?? `Công đoạn ${index + 1}`,
      equipmentName: item.defaultEquipment?.equipmentName ?? item.DefaultEquipment?.EquipmentName ?? item.equipmentName ?? 'Chưa gán',
      areaName: item.defaultEquipment?.area?.areaName ?? item.DefaultEquipment?.Area?.AreaName ?? item.areaName ?? '-',
      estimatedTimeMinutes: Number(item.estimatedTimeMinutes ?? item.EstimatedTimeMinutes ?? 0),
      description: item.description ?? item.Description,
      standardTemperature: item.standardTemperature ?? item.StandardTemperature,
      standardHumidity: item.standardHumidity ?? item.StandardHumidity,
      standardPressure: item.standardPressure ?? item.StandardPressure,
    }));
  }, [routingRaw]);

  const orderBatches = useMemo(() => {
    return batches
      .filter((batch) => batch.orderId === selectedOrderId)
      .sort((a, b) => a.batchNumber.localeCompare(b.batchNumber));
  }, [batches, selectedOrderId]);

  const totalSteps = routingSteps.length;

  const getStepStatus = (stepNumber: number) => {
    if (orderBatches.length === 0) return 'Scheduled';
    const allCompleted = orderBatches.every(b => b.status === 'Completed' || b.currentStep > stepNumber);
    if (allCompleted) return 'Completed';
    const anyActive = orderBatches.some(b => b.status === 'In-Process' && b.currentStep === stepNumber);
    if (anyActive) return 'In-Process';
    return 'Scheduled';
  };

  const overallProgress = useMemo(() => {
    if (orderBatches.length === 0) return 0;
    const totalPossibleSteps = orderBatches.length * totalSteps;
    if (totalPossibleSteps === 0) return 0;
    
    let completedSteps = 0;
    orderBatches.forEach(b => {
      if (b.status === 'Completed') {
        completedSteps += totalSteps;
      } else {
        completedSteps += Math.max(0, b.currentStep - 1);
      }
    });
    return Math.round((completedSteps / totalPossibleSteps) * 100);
  }, [orderBatches, totalSteps]);

  return (
    <div className="space-y-6 max-w-full overflow-hidden">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900">Theo Dõi Tiến Độ Sản Xuất</h1>
          <p className="text-neutral-500 mt-1">Giám sát lệnh và các mẻ sản xuất thời gian thực</p>
        </div>
        <div className="flex gap-4 items-center">
          <label className="flex flex-col">
            <span className="text-[10px] font-bold text-neutral-400 uppercase tracking-wider ml-1 mb-1">Chọn lệnh sản xuất</span>
            <select 
              value={selectedOrderId ?? ''} 
              onChange={(e) => setSelectedOrderId(Number(e.target.value))}
              className="input bg-white shadow-sm border-neutral-200 min-w-[250px]"
            >
              {orders.map(o => (
                <option key={o.orderId} value={o.orderId}>{o.orderCode} - {o.status}</option>
              ))}
            </select>
          </label>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-5 gap-6 items-start">
        {/* Left Col: Batches List (2/5) */}
        <div className="lg:col-span-2 space-y-4">
          <div className="card">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-sm font-bold text-neutral-800 flex items-center gap-2">
                <LayoutPanelLeft className="w-4 h-4 text-primary-600" />
                DANH SÁCH MẺ
              </h3>
              <span className="text-[10px] bg-neutral-100 px-2 py-0.5 rounded font-bold text-neutral-500">{orderBatches.length} MẺ</span>
            </div>
            <div className="overflow-x-auto">
              <table className="table table-sm">
                <thead>
                  <tr>
                    <th>Mã mẻ</th>
                    <th>Trạng thái</th>
                    <th>Tiến độ</th>
                  </tr>
                </thead>
                <tbody>
                  {orderBatches.length === 0 ? (
                    <tr><td colSpan={3} className="text-center py-8 text-neutral-400 italic text-xs">Chưa có mẻ nào</td></tr>
                  ) : orderBatches.map(batch => {
                    const progress = batch.status === 'Completed' ? 100 : Math.round(((batch.currentStep - 1) / totalSteps) * 100);
                    return (
                      <tr key={batch.batchId} className="hover:bg-neutral-50 cursor-default">
                        <td className="font-mono text-xs font-semibold text-primary-700">{batch.batchNumber}</td>
                        <td>
                          <span className={`text-[10px] px-1.5 py-0.5 rounded-full font-bold uppercase ${getStatusClass(batch.status)}`}>
                            {batch.status}
                          </span>
                        </td>
                        <td className="w-24">
                          <div className="flex items-center gap-2">
                            <div className="flex-1 h-1.5 bg-neutral-100 rounded-full overflow-hidden">
                              <div className="h-full bg-primary-500 rounded-full" style={{ width: `${progress}%` }} />
                            </div>
                            <span className="text-[10px] font-bold text-neutral-500">{progress}%</span>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        {/* Right Col: Order Detail & Summary (3/5) */}
        <div className="lg:col-span-3 space-y-4">
          <div className="card bg-gradient-to-br from-white to-primary-50/30">
            <div className="flex items-center justify-between mb-6">
               <div>
                  <h2 className="text-lg font-bold text-neutral-900">{selectedOrder?.orderCode}</h2>
                  <p className="text-xs text-neutral-500">Thành phẩm: <span className="font-bold text-neutral-700">{selectedRecipe?.materialName}</span></p>
               </div>
               <div className="text-right">
                  <p className="text-xs text-neutral-500 uppercase font-bold tracking-widest mb-1">Tiến độ tổng thể</p>
                  <div className="flex items-center gap-3">
                    <span className="text-3xl font-black text-primary-600 leading-none">{overallProgress}%</span>
                    <div className="w-32 h-3 bg-neutral-200 rounded-full overflow-hidden shadow-inner">
                      <div className="h-full bg-primary-600 transition-all duration-1000 ease-out shadow-[0_0_8px_rgba(37,99,235,0.4)]" style={{ width: `${overallProgress}%` }} />
                    </div>
                  </div>
               </div>
            </div>

            <div className="grid grid-cols-3 gap-4">
               <div className="bg-white/60 backdrop-blur p-3 rounded-xl border border-white/40 shadow-sm">
                  <p className="text-[10px] text-neutral-500 font-bold uppercase mb-1">Số lượng kế hoạch</p>
                  <p className="text-lg font-bold text-neutral-900">{selectedOrder?.plannedQuantity.toLocaleString()} <span className="text-xs font-normal text-neutral-400 font-sans">đơn vị</span></p>
               </div>
               <div className="bg-white/60 backdrop-blur p-3 rounded-xl border border-white/40 shadow-sm">
                  <p className="text-[10px] text-neutral-500 font-bold uppercase mb-1">Trạng thái lệnh</p>
                  <span className={`inline-block px-2 py-0.5 rounded-md text-[11px] font-black uppercase ${getStatusClass(selectedOrder?.status ?? '')}`}>
                    {selectedOrder?.status}
                  </span>
               </div>
               <div className="bg-white/60 backdrop-blur p-3 rounded-xl border border-white/40 shadow-sm">
                  <p className="text-[10px] text-neutral-500 font-bold uppercase mb-1">Công thức</p>
                  <p className="text-xs font-bold text-neutral-700 truncate" title={selectedRecipe?.recipeName}>{selectedRecipe?.recipeName}</p>
                  <p className="text-[9px] text-neutral-400 mt-0.5">V: {selectedRecipe?.versionNumber}</p>
               </div>
            </div>
          </div>

          <div className="card">
            <h3 className="text-sm font-bold text-neutral-800 flex items-center gap-2 mb-4">
              <Route className="w-4 h-4 text-primary-600" />
              CHI TIẾT CÁC CÔNG ĐOẠN
            </h3>
            <div className="overflow-x-auto">
              <table className="table table-sm">
                <thead>
                  <tr>
                    <th className="w-8">B.</th>
                    <th>Tên công đoạn</th>
                    <th>Phòng / Thiết bị</th>
                    <th>Điều kiện kỹ thuật</th>
                    <th>Trạng thái</th>
                  </tr>
                </thead>
                <tbody>
                  {routingSteps.length === 0 ? (
                    <tr><td colSpan={5} className="text-center py-8 text-neutral-400 italic text-xs">Không có dữ liệu quy trình</td></tr>
                  ) : routingSteps.map(step => {
                    const status = getStepStatus(step.stepNumber);
                    return (
                      <tr key={step.routingId}>
                        <td className="text-center font-mono text-xs text-neutral-500">{step.stepNumber}</td>
                        <td className="font-semibold text-neutral-800 text-sm">
                          <button 
                            onClick={() => step.description && setViewedDescription(step.description)}
                            className="hover:text-primary-600 hover:underline flex items-center gap-1 group"
                            disabled={!step.description}
                          >
                            {step.stepName}
                            {step.description && <ChevronRight className="w-3 h-3 opacity-0 group-hover:opacity-100" />}
                          </button>
                        </td>
                        <td>
                          <div className="flex flex-col">
                            <span className="text-xs font-medium text-neutral-700">{step.areaName}</span>
                            <span className="text-[10px] text-neutral-500">{step.equipmentName}</span>
                          </div>
                        </td>
                        <td>
                          <div className="flex flex-col text-[10px] text-neutral-500 gap-0.5 whitespace-nowrap">
                            <span>T: <b className="text-neutral-700">{step.standardTemperature ?? "-"}</b></span>
                            <span>H: <b className="text-neutral-700">{step.standardHumidity ?? "-"}</b></span>
                            <span>P: <b className="text-neutral-700">{step.standardPressure ?? "-"}</b></span>
                          </div>
                        </td>
                        <td>
                          <span className={`text-[10px] px-1.5 py-0.5 rounded-full font-bold uppercase ${getStatusClass(status)}`}>
                            {status}
                          </span>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>

      {/* Description Modal */}
      {viewedDescription && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4" onClick={() => setViewedDescription(null)}>
          <div className="bg-white rounded-2xl w-full max-w-lg p-6 space-y-4" onClick={e => e.stopPropagation()}>
            <h3 className="text-lg font-bold text-gray-900 border-b pb-2 flex items-center gap-2">
              <ListChecks className="w-5 h-5 text-primary-600" />
              Hướng dẫn vận hành
            </h3>
            <div className="text-sm text-neutral-700 whitespace-pre-wrap leading-relaxed py-2">
              {viewedDescription}
            </div>
            <div className="flex justify-end pt-4 border-t">
              <button onClick={() => setViewedDescription(null)} className="btn-primary">Đóng</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
