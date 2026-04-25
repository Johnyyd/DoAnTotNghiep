import { useEffect, useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Clock3, FlaskConical, ShieldCheck } from 'lucide-react';
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

type NormalizedBom = {
  bomId: number;
  materialName: string;
  technicalStandard?: string;
  quantity: number;
  ratioPercent: number;
  uomName: string;
};

type NormalizedRouting = {
  routingId: number;
  stepNumber: number;
  stepName: string;
  equipmentName: string;
  areaName: string;
  estimatedTimeMinutes: number;
  description?: string;
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


const fallbackBom: NormalizedBom[] = [
  { bomId: 1, materialName: 'NLC 3 - Cao khô Trinh nữ Crila', technicalStandard: 'TCCS', quantity: 250, ratioPercent: 46.6, uomName: 'mg' },
  { bomId: 2, materialName: 'TD 1 - Aerosil', technicalStandard: 'USP 30', quantity: 1.62, ratioPercent: 0.3, uomName: 'mg' },
  { bomId: 3, materialName: 'TD 3 - Sodium starch glycolate', technicalStandard: 'USP 30', quantity: 29.7, ratioPercent: 5.5, uomName: 'mg' },
  { bomId: 4, materialName: 'TD 4 - Talc', technicalStandard: 'ĐĐVN V', quantity: 4.05, ratioPercent: 0.75, uomName: 'mg' },
  { bomId: 5, materialName: 'TD 5 - Magnesi stearat', technicalStandard: 'ĐĐVN V', quantity: 4.05, ratioPercent: 0.75, uomName: 'mg' },
  { bomId: 6, materialName: 'TD 8 - Tinh bột', technicalStandard: 'ĐĐVN V', quantity: 250.58, ratioPercent: 46.7, uomName: 'mg' },
];

const fallbackRouting: NormalizedRouting[] = [
  { routingId: 1, stepNumber: 1, stepName: 'Cân nguyên liệu', equipmentName: 'IW2-60 / PMA-5000', areaName: 'Phòng cân', estimatedTimeMinutes: 50 },
  { routingId: 2, stepNumber: 2, stepName: 'Trộn khô', equipmentName: 'AD-LP-200', areaName: 'Phòng trộn khô', estimatedTimeMinutes: 45 },
  { routingId: 3, stepNumber: 3, stepName: 'Sấy', equipmentName: 'KBC-TS-50', areaName: 'Phòng sấy', estimatedTimeMinutes: 180 },
  { routingId: 4, stepNumber: 4, stepName: 'Đóng nang', equipmentName: 'NJP-1200D', areaName: 'Phòng đóng nang', estimatedTimeMinutes: 120 },
];


function normalizeStatus(raw?: string): string {
  if (!raw) return 'Draft';
  const value = raw.toLowerCase();
  if (value.includes('approved')) return 'Approved';
  if (value.includes('hold')) return 'Hold';
  if (value.includes('process')) return 'InProcess';
  if (value.includes('complete')) return 'Completed';
  return raw;
}

function formatDate(value?: string): string {
  if (!value) return '-';
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return '-';
  return parsed.toLocaleDateString('vi-VN');
}

export default function ManagerOperations() {
  const [selectedRecipeId, setSelectedRecipeId] = useState<number | null>(null);
  const [selectedOrderId, setSelectedOrderId] = useState<number | null>(null);
  const [viewedDescription, setViewedDescription] = useState<string | null>(null);

  const { data: recipesRaw } = useQuery({
    queryKey: ['recipes'],
    queryFn: () => recipesApi.getAll(),
  });

  const { data: ordersRaw } = useQuery({ queryKey: ['progressOrders'], queryFn: () => productionOrdersApi.getAll() });

  const { data: batchesRaw } = useQuery({
    queryKey: ['productionBatches'],
    queryFn: () => productionBatchesApi.getAll(),
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
    if (!selectedRecipeId && recipes.length) {
      const approved = recipes.find((r) => r.status === 'Approved');
      setSelectedRecipeId((approved ?? recipes[0]).recipeId);
    }
  }, [recipes, selectedRecipeId]);

  useEffect(() => {
    if (!selectedOrderId && orders.length) {
      const inProcess = orders.find((o) => o.status === 'InProcess');
      setSelectedOrderId((inProcess ?? orders[0]).orderId);
    }
  }, [orders, selectedOrderId]);

  const selectedOrder = useMemo(
    () => orders.find((order) => order.orderId === selectedOrderId) ?? null,
    [orders, selectedOrderId]
  );

  useEffect(() => {
    if (selectedOrder?.recipeId && selectedRecipeId !== selectedOrder.recipeId) {
      setSelectedRecipeId(selectedOrder.recipeId);
    }
  }, [selectedOrder, selectedRecipeId]);

  const selectedRecipe = useMemo(
    () => recipes.find((recipe) => recipe.recipeId === selectedRecipeId) ?? null,
    [recipes, selectedRecipeId]
  );

  const { data: bomRaw } = useQuery({
    queryKey: ['recipeBOM', selectedRecipeId],
    queryFn: () => recipesApi.getBOM(selectedRecipeId as number),
    enabled: !!selectedRecipeId,
  });

  const { data: routingRaw } = useQuery({
    queryKey: ['recipeRouting', selectedRecipeId],
    queryFn: () => recipesApi.getRouting(selectedRecipeId as number),
    enabled: !!selectedRecipeId,
  });

  const bomItems = useMemo<NormalizedBom[]>(() => {
    const rows = Array.isArray(bomRaw) ? bomRaw : (bomRaw as any)?.data ?? [];
    const normalized: NormalizedBom[] = rows.map((item: any) => ({
      bomId: Number(item.bomId ?? item.BomId ?? 0),
      materialName: item.material?.materialName ?? item.Material?.MaterialName ?? item.materialName ?? 'Nguyên liệu',
      technicalStandard: item.technicalStandard ?? item.TechnicalStandard ?? '',
      quantity: Number(item.quantity ?? item.Quantity ?? 0),
      ratioPercent: 0, // computed below
      uomName: item.uom?.uomName ?? item.Uom?.UomName ?? item.unit ?? 'kg',
    }));
    // compute ratio from total
    const total = normalized.reduce((s, b) => s + b.quantity, 0);
    normalized.forEach((b) => { b.ratioPercent = total > 0 ? (b.quantity / total) * 100 : 0; });
    return normalized.length ? normalized : fallbackBom;
  }, [bomRaw]);

  const routingSteps = useMemo<NormalizedRouting[]>(() => {
    const rows = Array.isArray(routingRaw) ? routingRaw : (routingRaw as any)?.data ?? [];
    const normalized = rows.map((item: any, index: number) => ({
      routingId: Number(item.routingId ?? item.RoutingId ?? index + 1),
      stepNumber: Number(item.stepNumber ?? item.StepNumber ?? index + 1),
      stepName: item.stepName ?? item.StepName ?? `Công đoạn ${index + 1}`,
      equipmentName: item.defaultEquipment?.equipmentName
        ?? item.DefaultEquipment?.EquipmentName
        ?? item.equipmentName
        ?? 'Chưa gán thiết bị',
      areaName: item.defaultEquipment?.area?.areaName
        ?? item.DefaultEquipment?.Area?.AreaName
        ?? '-',
      estimatedTimeMinutes: Number(item.estimatedTimeMinutes ?? item.EstimatedTimeMinutes ?? 0),
      description: item.description ?? item.Description,
    }));
    return normalized.length ? normalized : fallbackRouting;
  }, [routingRaw]);

  const orderBatches = useMemo(() => {
    const selected = batches
      .filter((batch) => batch.orderId === selectedOrderId)
      .sort((a, b) => a.batchNumber.localeCompare(b.batchNumber));

    if (selected.length) return selected;

    return [
      { batchId: 1, orderId: selectedOrderId ?? 0, batchNumber: 'ME-01', status: 'InProcess', currentStep: 2 },
      { batchId: 2, orderId: selectedOrderId ?? 0, batchNumber: 'ME-02', status: 'InProcess', currentStep: 1 },
      { batchId: 3, orderId: selectedOrderId ?? 0, batchNumber: 'ME-03', status: 'Draft', currentStep: 1 },
    ] as NormalizedBatch[];
  }, [batches, selectedOrderId]);

  const totalSteps = Math.max(1, routingSteps.length);

  const getStepPointer = (batch: NormalizedBatch) => {
    if (batch.status === 'Completed') return totalSteps + 1;
    const value = Number(batch.currentStep);
    if (!Number.isFinite(value)) return 1;
    return Math.min(Math.max(1, value), totalSteps + 1);
  };

  const getBatchProgress = (batch: NormalizedBatch) => {
    if (batch.status === 'Completed') return 100;
    const pointer = getStepPointer(batch);
    return Math.round(((pointer - 1) / totalSteps) * 100);
  };

  const overallProgress = useMemo(() => {
    if (!orderBatches.length) return 0;
    const sum = orderBatches.reduce((acc, batch) => acc + getBatchProgress(batch), 0);
    return Math.round(sum / orderBatches.length);
  }, [orderBatches]);

  const getPipelineState = (batchIndex: number, stepNumber: number, batch: NormalizedBatch) => {
    const pointer = getStepPointer(batch);
    const prevBatch = batchIndex > 0 ? orderBatches[batchIndex - 1] : null;
    const prevPointer = prevBatch ? getStepPointer(prevBatch) : totalSteps + 1;
    const gateOpen = !prevBatch || prevPointer > stepNumber;

    if (batch.status === 'Completed' || pointer > stepNumber) return 'done';
    if (pointer === stepNumber && gateOpen) return 'active';
    if (!gateOpen && pointer <= stepNumber) return 'blocked';
    return 'waiting';
  };

  const getStatusClass = (status: string) => {
    const normalized = normalizeStatus(status);
    if (normalized === 'Approved') return 'bg-blue-100 text-blue-700';
    if (normalized === 'InProcess') return 'bg-amber-100 text-amber-700';
    if (normalized === 'Hold') return 'bg-red-100 text-red-700';
    if (normalized === 'Completed') return 'bg-emerald-100 text-emerald-700';
    return 'bg-neutral-100 text-neutral-700';
  };



  return (
    <div className="space-y-6">
      <div className="gmp-sheet">
        <div className="gmp-sheet-header">
          <div>
            <p className="text-xs font-semibold tracking-[0.18em] text-neutral-600">CÔNG TY ABC</p>
            <h1 className="text-xl font-bold text-neutral-900">THEO DÕI TIẾN ĐỘ CÁC LỆNH SẢN XUẤT</h1>
          </div>
          <div className="text-right text-sm text-neutral-700">
            <p>Số tờ: ...</p>
            <p>Ngày: {new Date().toLocaleDateString('vi-VN')}</p>
            <p>Hiệu lực: Đang vận hành</p>
          </div>
        </div>

        <div className="mb-4">
          <label className="text-sm font-medium text-neutral-700">
            Chọn Lệnh Sản Xuất
            <select
              value={selectedOrderId ?? ''}
              onChange={(event) => setSelectedOrderId(Number(event.target.value))}
              className="input mt-1"
            >
              {orders.map((order) => (
                <option key={order.orderId} value={order.orderId}>
                  {order.orderCode} - {order.status} - {order.plannedQuantity.toLocaleString()} đơn vị
                </option>
              ))}
            </select>
          </label>
        </div>

        <div className="gmp-title-row">I - THÀNH PHẦN BOM (Bill of Materials)</div>
        <table className="gmp-grid-table mb-5">
          <thead>
            <tr>
              <th>STT</th>
              <th>Tên nguyên liệu</th>
              <th>Tiêu chuẩn kỹ thuật</th>
              <th>Số lượng</th>
              <th>Đơn vị</th>
              <th>Tỉ lệ công thức (%)</th>
            </tr>
          </thead>
          <tbody>
            {bomItems.map((item, index) => (
              <tr key={item.bomId || index}>
                <td>{index + 1}</td>
                <td>{item.materialName}</td>
                <td>{item.technicalStandard || '-'}</td>
                <td>{item.quantity.toLocaleString()}</td>
                <td>{item.uomName}</td>
                <td>{item.ratioPercent.toFixed(2)}</td>
              </tr>
            ))}
          </tbody>
        </table>

        <div className="gmp-title-row">II - RECIPE & ROUTING</div>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 mb-4">
          <div className="gmp-info-card">
            <FlaskConical className="w-5 h-5 text-primary-600" />
            <div>
              <p className="text-xs uppercase tracking-wide text-neutral-500">Recipe</p>
              <p className="font-semibold text-neutral-900">{selectedRecipe?.recipeCode ?? '-'}</p>
              <p className="text-sm text-neutral-600">{selectedRecipe?.recipeName ?? '-'}</p>
            </div>
          </div>
          <div className="gmp-info-card">
            <ShieldCheck className="w-5 h-5 text-emerald-600" />
            <div>
              <p className="text-xs uppercase tracking-wide text-neutral-500">Trạng thái</p>
              <span className={`inline-flex px-2.5 py-1 rounded-full text-xs font-semibold ${getStatusClass(selectedRecipe?.status ?? 'Draft')}`}>
                {selectedRecipe?.status ?? 'Draft'}
              </span>
              <p className="text-sm text-neutral-600 mt-1">Ngày duyệt: {formatDate(selectedRecipe?.approvedDate)}</p>
            </div>
          </div>
        </div>

        <table className="gmp-grid-table mb-5">
          <thead>
            <tr>
              <th>Bước</th>
              <th>Công đoạn</th>
              <th>Thiết bị được sử dụng</th>
              <th>Khu vực</th>
              <th>Thời gian cài đặt</th>
              <th>Mô tả</th>
            </tr>
          </thead>
          <tbody>
            {routingSteps.map((step) => (
              <tr key={step.routingId}>
                <td>{step.stepNumber}</td>
                <td>{step.stepName}</td>
                <td>{step.equipmentName}</td>
                <td>{step.areaName}</td>
                <td>{step.estimatedTimeMinutes ? `${step.estimatedTimeMinutes} phút` : '-'}</td>
                <td>
                  {step.description && step.description.trim() !== '' && step.description !== '-' ? (
                    <button 
                      onClick={() => setViewedDescription(step.description ?? null)}
                      className="text-primary-600 hover:underline text-sm font-medium"
                    >
                      Xem
                    </button>
                  ) : '-'}
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        <div className="gmp-title-row">III - LẬP LỆNH SẢN XUẤT VÀ DANH SÁCH MẺ</div>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 mb-4">
          <div className="border border-neutral-300 rounded-lg p-4">
            <p className="text-xs uppercase tracking-wide text-neutral-500 mb-2">Thông tin lệnh</p>
            <div className="space-y-2 text-sm">
              <p><span className="font-semibold">Mã lệnh:</span> {selectedOrder?.orderCode ?? '-'}</p>
              <p><span className="font-semibold">Trạng thái:</span> {selectedOrder?.status ?? '-'}</p>
              <p><span className="font-semibold">Số lượng kế hoạch:</span> {(selectedOrder?.plannedQuantity ?? 0).toLocaleString()}</p>
              <p><span className="font-semibold">Ngày bắt đầu:</span> {formatDate(selectedOrder?.startDate)}</p>
              <p><span className="font-semibold">Ngày kết thúc:</span> {formatDate(selectedOrder?.endDate)}</p>
            </div>
          </div>
          <div className="border border-neutral-300 rounded-lg p-4">
            <p className="text-xs uppercase tracking-wide text-neutral-500 mb-2">Phê duyệt GMP</p>
            <div className="grid grid-cols-3 gap-3 text-sm">
              <div className="border border-dashed border-neutral-300 rounded-md p-2 text-center">
                <p className="font-semibold">Người soạn</p>
                <p className="text-neutral-700 font-medium mt-4 text-sm">{selectedOrder?.createdByName ?? '................'}</p>
              </div>
              <div className="border border-dashed border-neutral-300 rounded-md p-2 text-center">
                <p className="font-semibold">Người kiểm tra</p>
                <p className="text-neutral-500 mt-6">................</p>
              </div>
              <div className="border border-dashed border-neutral-300 rounded-md p-2 text-center">
                <p className="font-semibold">Người phê duyệt</p>
                <p className="text-neutral-500 mt-6">................</p>
              </div>
            </div>
          </div>
        </div>

        <table className="gmp-grid-table mb-5">
          <thead>
            <tr>
              <th>Mẻ</th>
              <th>Trạng thái</th>
              <th>Công đoạn hiện tại</th>
              <th>Tỉ lệ hoàn thành</th>
            </tr>
          </thead>
          <tbody>
            {orderBatches.map((batch) => {
              const pointer = Math.min(getStepPointer(batch), totalSteps);
              return (
                <tr key={batch.batchId}>
                  <td>{batch.batchNumber}</td>
                  <td>
                    <span className={`inline-flex px-2.5 py-1 rounded-full text-xs font-semibold ${getStatusClass(batch.status)}`}>
                      {batch.status}
                    </span>
                  </td>
                  <td>{routingSteps.find((step) => step.stepNumber === pointer)?.stepName ?? '-'}</td>
                  <td>
                    <div className="w-full">
                      <div className="progress-track">
                        <div className="progress-fill" style={{ width: `${getBatchProgress(batch)}%` }} />
                      </div>
                      <p className="text-xs text-neutral-600 mt-1">{getBatchProgress(batch)}%</p>
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>

        <div className="gmp-title-row">IV - BÁO CÁO TIẾN ĐỘ (Pipeline theo mẻ và công đoạn)</div>
        <div className="border border-neutral-300 rounded-lg p-4 mb-3">
          <div className="flex items-center justify-between mb-2">
            <p className="text-sm font-semibold text-neutral-800">Tiến độ tổng lệnh {selectedOrder?.orderCode ?? ''}</p>
            <span className="text-sm font-semibold text-primary-700">{overallProgress}%</span>
          </div>
          <div className="progress-track h-3">
            <div className="progress-fill h-3" style={{ width: `${overallProgress}%` }} />
          </div>
          <p className="text-xs text-neutral-600 mt-2">
            Logic dây chuyền: mẻ trước chuyển sang bước tiếp theo thì mẻ sau mới được vào bước trước đó.
          </p>
        </div>

        <div className="overflow-x-auto">
          <table className="gmp-grid-table">
            <thead>
              <tr>
                <th>Mẻ / Bước</th>
                {routingSteps.map((step) => (
                  <th key={step.routingId}>{`Bước ${step.stepNumber}`}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {orderBatches.map((batch, batchIndex) => (
                <tr key={batch.batchId}>
                  <td className="font-semibold">{batch.batchNumber}</td>
                  {routingSteps.map((step) => {
                    const state = getPipelineState(batchIndex, step.stepNumber, batch);
                    const label = state === 'done'
                      ? 'Hoàn thành'
                      : state === 'active'
                        ? 'Đang thực hiện'
                        : state === 'blocked'
                          ? 'Chờ mẻ trước'
                          : 'Chờ đến lượt';
                    const classes = state === 'done'
                      ? 'bg-emerald-100 text-emerald-700'
                      : state === 'active'
                        ? 'bg-amber-100 text-amber-700'
                        : state === 'blocked'
                          ? 'bg-red-100 text-red-700'
                          : 'bg-neutral-100 text-neutral-700';
                    return (
                      <td key={`${batch.batchId}-${step.routingId}`}>
                        <span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-semibold ${classes}`}>
                          {label}
                        </span>
                      </td>
                    );
                  })}
                </tr>
              ))}
            </tbody>
          </table>
        </div>



        <div className="flex items-center justify-between text-xs text-neutral-500 mt-4">
          <div className="flex items-center gap-2">
            <Clock3 className="w-4 h-4" />
            Báo cáo tự động cập nhật theo API backend .NET + SQL Server
          </div>
          <p>Role thực hiện: Trưởng phòng (người phê duyệt)</p>
        </div>

        {/* Description Modal */}
        {viewedDescription && (
          <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
            <div className="bg-white rounded-2xl w-full max-w-lg p-6 space-y-4">
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-bold text-gray-900 border-b pb-2 mb-2 w-full text-left">Mô tả công đoạn</h3>
              </div>
              <div className="text-sm text-neutral-700 whitespace-pre-wrap">{viewedDescription}</div>
              <div className="flex justify-end pt-4 mt-4 border-t">
                <button onClick={() => setViewedDescription(null)} className="btn-primary">Đóng</button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
