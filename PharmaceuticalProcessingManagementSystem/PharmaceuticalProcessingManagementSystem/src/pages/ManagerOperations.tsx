import { useEffect, useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { FlaskConical, Search } from 'lucide-react';
import { productionBatchesApi, productionOrdersApi, recipesApi } from '@/services/api';
import { formatNumber, formatRecipeBatchSize, isRecipeLiquid } from '@/utils/format';

type NormalizedRecipe = {
  recipeId: number;
  recipeCode: string;
  recipeName: string;
  status: string;
  versionNumber: number;
  batchSize: number;
  approvedDate?: string;
  materialName?: string;
  uomName?: string;
  batchUomName?: string;
};
type NormalizedRouting = {
  routingId: number;
  stepNumber: number;
  stepName: string;
  equipmentName: string;
  equipmentCode: string;
  areaName: string;
  estimatedTimeMinutes: number;
  description?: string;
};

type NormalizedOrder = {
  orderId: number;
  orderCode: string;
  recipeId: number;
  recipeName?: string;
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



function getStatusLabel(status: string) {
  if (status === 'Draft') return 'Bản nháp';
  if (status === 'Approved') return 'Đã duyệt';
  if (status === 'InProcess' || status === 'In-Process') return 'Đang chạy';
  if (status === 'Hold') return 'Chờ';
  if (status === 'Scheduled') return 'Đã lên lịch';
  if (status === 'Completed') return 'Hoàn thành';
  return status;
}

function normalizeStatus(raw?: string): string {
  if (!raw) return 'Draft';
  const value = raw.toLowerCase();
  if (value.includes('approved')) return 'Approved';
  if (value.includes('hold')) return 'Hold';
  if (value.includes('process')) return 'InProcess';
  if (value.includes('complete')) return 'Completed';
  return raw;
}

export default function ManagerOperations() {
  const [selectedRecipeId, setSelectedRecipeId] = useState<number | null>(null);
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
      uomName: item.material?.baseUom?.uomName ?? item.Material?.BaseUom?.UomName,
      batchUomName: item.batchUom?.uomName ?? item.BatchUom?.UomName,
    }));
  }, [recipesRaw]);

  const orders = useMemo<NormalizedOrder[]>(() => {
    const rows = Array.isArray(ordersRaw) ? ordersRaw : (ordersRaw as any)?.data ?? (ordersRaw as any)?.items ?? [];
    return rows.map((item: any) => {
      const recipe = recipes.find((r) => r.recipeId === Number(item.recipeId ?? item.RecipeId));
      const rName = item.recipe?.recipeName ?? item.recipe?.RecipeName ?? recipe?.recipeName ?? '';
      const mName = item.recipe?.material?.materialName ?? item.recipe?.Material?.MaterialName ?? recipe?.materialName ?? '';
      const bSize = recipe?.batchSize ?? item.recipe?.batchSize ?? item.recipe?.BatchSize ?? 0;
      const uom = recipe?.uomName ?? item.recipe?.material?.baseUom?.uomName ?? item.recipe?.Material?.BaseUom?.UomName ?? 'viên';
      const batchUom = recipe?.batchUomName ?? item.recipe?.batchUom?.uomName ?? item.recipe?.BatchUom?.UomName;
      const formattedBatchSize = formatRecipeBatchSize(bSize, isRecipeLiquid(mName, uom), batchUom);

      const recipeName = rName
        ? `${rName} ${mName} (${formattedBatchSize})`
        : `${mName} (${formattedBatchSize})`;

      return {
        orderId: Number(item.orderId ?? item.OrderId ?? 0),
        orderCode: item.orderCode ?? item.OrderCode ?? `PO-${item.orderId ?? item.OrderId ?? ''}`,
        recipeId: Number(item.recipeId ?? item.RecipeId ?? 0),
        recipeName: recipeName || `Công thức #${item.recipeId ?? item.RecipeId}`,
        plannedQuantity: Number(item.plannedQuantity ?? item.PlannedQuantity ?? 0),
        status: normalizeStatus(item.status ?? item.Status),
        startDate: item.startDate ?? item.StartDate,
        endDate: item.endDate ?? item.EndDate,
        createdByName: item.createdByName ?? item.CreatedByName,
      };
    });
  }, [ordersRaw, recipes]);

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
    if (!orders.length) {
      if (selectedOrderId !== null) setSelectedOrderId(null);
      return;
    }

    const hasSelectedOrder = selectedOrderId !== null
      && orders.some((o) => o.orderId === selectedOrderId);

    if (!hasSelectedOrder) {
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


  const { data: routingRaw } = useQuery({
    queryKey: ['orderRouting', selectedOrderId],
    queryFn: () => productionOrdersApi.getRoutings(selectedOrderId as number),
    enabled: selectedOrderId !== null,
  });

  const routingSteps = useMemo<NormalizedRouting[]>(() => {
    const rows = Array.isArray(routingRaw) ? routingRaw : (routingRaw as any)?.data ?? [];
    const normalized = rows.map((item: any, index: number) => ({
      routingId: Number(item.routingId ?? item.RoutingId ?? index + 1),
      stepNumber: Number(item.stepNumber ?? item.StepNumber ?? index + 1),
      stepName: item.stepName ?? item.StepName ?? `Công đoạn ${index + 1}`,
      equipmentName: item.equipment?.equipmentName
        ?? item.Equipment?.EquipmentName
        ?? item.defaultEquipment?.equipmentName
        ?? item.DefaultEquipment?.EquipmentName
        ?? item.equipmentName
        ?? 'Chưa gán thiết bị',
      equipmentCode: item.equipment?.equipmentCode
        ?? item.Equipment?.EquipmentCode
        ?? item.defaultEquipment?.equipmentCode
        ?? item.DefaultEquipment?.EquipmentCode
        ?? item.equipmentCode
        ?? item.EquipmentCode
        ?? '',
      areaName: item.area?.areaName
        ?? item.Area?.AreaName
        ?? item.defaultEquipment?.area?.areaName
        ?? item.DefaultEquipment?.Area?.AreaName
        ?? item.areaName
        ?? '-',
      estimatedTimeMinutes: Number(item.estimatedTimeMinutes ?? item.EstimatedTimeMinutes ?? 0),
      description: item.description ?? item.Description,
    }));
    const dedup = new Map<string, NormalizedRouting>();
    normalized.forEach((item: NormalizedRouting) => {
      const key = `${item.stepNumber}-${item.stepName}`;
      if (!dedup.has(key)) dedup.set(key, item);
    });
    return Array.from(dedup.values()).sort((a, b) => a.stepNumber - b.stepNumber);
  }, [routingRaw]);

  const orderBatches = useMemo(() => {
    const selected = batches
      .filter((batch) => batch.orderId === selectedOrderId)
      .sort((a, b) => a.batchNumber.localeCompare(b.batchNumber));

    return selected;
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



  const getPipelineState = (batchIndex: number, stepNumber: number, batch: NormalizedBatch) => {
    const pointer = getStepPointer(batch);
    const prevBatch = batchIndex > 0 ? orderBatches[batchIndex - 1] : null;
    const prevPointer = prevBatch ? getStepPointer(prevBatch) : totalSteps + 1;
    const gateOpen = !prevBatch || prevPointer > stepNumber;

    // If order or batch is scheduled, everything is waiting
    if (selectedOrder?.status === 'Scheduled' || batch.status === 'Scheduled') return 'waiting';

    if (batch.status === 'Completed' || pointer > stepNumber) return 'done';
    if (pointer === stepNumber && gateOpen) return 'active';
    if (!gateOpen && pointer <= stepNumber) return 'blocked';
    return 'waiting';
  };

  const getStepAggregateStatus = (stepNumber: number) => {
    const done = orderBatches.filter((batch, batchIndex) => getPipelineState(batchIndex, stepNumber, batch) === "done").length;
    const active = orderBatches.some((batch, batchIndex) => getPipelineState(batchIndex, stepNumber, batch) === "active");
    if (active) return "InProcess";
    if (done === orderBatches.length && orderBatches.length > 0) return "Completed";
    return "Hold";
  };

  const getStatusClass = (status: string) => {
    const normalized = normalizeStatus(status);
    if (normalized === 'Approved') return 'bg-blue-100 text-blue-700 border border-blue-200';
    if (normalized === 'InProcess') return 'bg-orange-100 text-orange-700 border border-orange-200';
    if (normalized === 'Hold') return 'bg-red-100 text-red-700 border border-red-200';
    if (normalized === 'Scheduled') return 'bg-blue-100 text-blue-700 border border-blue-200';
    if (normalized === 'Completed') return 'bg-green-100 text-green-700 border border-green-200';
    return 'bg-white text-gray-700 border border-gray-200';
  };



  if (orders.length === 0) {
    return <div className="space-y-6"><div className="card text-neutral-500">Chưa có lệnh sản xuất trong cơ sở dữ liệu</div></div>;
  }

  return (
    <div className="space-y-6">
      <div className="gmp-sheet">
        <div className="mb-4">
          <label className="text-sm font-bold text-neutral-900">
            Chọn lệnh sản xuất
            <select
              value={selectedOrderId ?? ""}
              onChange={(event) =>
                setSelectedOrderId(Number(event.target.value))
              }
              className="input mt-1"
            >
              {orders.length === 0 && (
                <option value="">Chưa có lệnh sản xuất</option>
              )}
              {orders.map((order) => (
                <option key={order.orderId} value={order.orderId}>
                  {order.orderCode} - ({order.recipeName}) - {getStatusLabel(order.status)} - {" "}
                  {formatNumber(order.plannedQuantity, 0)} đơn vị
                </option>
              ))}
            </select>
          </label>
          {selectedOrder && (
            <div className="mt-3 flex items-start gap-3 bg-neutral-50 border border-neutral-200 rounded-lg p-3">
              <FlaskConical className="w-5 h-5 text-primary-600 mt-0.5" />
              <div>
                <p className="font-bold text-neutral-900 text-sm">
                  {selectedOrder.recipeName || selectedRecipe?.recipeName || "-"}
                </p>
              </div>
            </div>
          )}
        </div>
        <div className="gmp-title-row">Các công đoạn</div>
        <table className="gmp-grid-table mb-5">
          <thead>
            <tr>
              <th className="w-16">Bước</th>
              <th>Công đoạn</th>
              <th>Thiết bị được sử dụng</th>
              <th className="w-px whitespace-nowrap">Khu vá»±c</th>
              <th className="w-px whitespace-nowrap">Thời gian</th>
              <th className="w-px whitespace-nowrap">Mô tả</th>
            </tr>
          </thead>
          <tbody>
            {routingSteps.length === 0 && (
              <tr>
                <td colSpan={6} className="text-center py-4 text-neutral-500">
                  Chưa có dữ liệu quy trình công đoạn.
                </td>
              </tr>
            )}
            {routingSteps.map((step) => {
              const aggregateStatus = getStepAggregateStatus(step.stepNumber);
              return (
              <tr key={step.routingId}>
                <td className="relative">
                  <div className="font-bold">{step.stepNumber}</div>
                  <span className={`mt-1 inline-flex px-2 py-0.5 rounded-full text-[11px] font-semibold ${getStatusClass(aggregateStatus)}`}>
                    {getStatusLabel(aggregateStatus)}
                  </span>
                </td>
                <td className="font-medium text-neutral-900">{step.stepName}</td>
                <td>
                  <span>{step.equipmentName}</span>
                  {step.equipmentCode ? (
                    <span className="ml-2 inline-flex rounded bg-neutral-100 px-2 py-0.5 font-mono text-xs text-neutral-600">
                      {step.equipmentCode}
                    </span>
                  ) : null}
                </td>
                <td className="whitespace-nowrap">{step.areaName}</td>
                <td className="whitespace-nowrap">
                  {step.estimatedTimeMinutes
                    ? `${step.estimatedTimeMinutes} phút`
                    : "-"}
                </td>
                <td className="text-center">
                  {step.description &&
                  step.description.trim() !== "" &&
                  step.description !== "-" ? (
                    <button
                      onClick={() =>
                        setViewedDescription(step.description ?? null)
                      }
                      className="text-primary-600 hover:bg-primary-50 p-1.5 rounded-md transition-colors"
                    >
                      <Search className="w-4 h-4" />
                    </button>
                  ) : (
                    "-"
                  )}
                </td>
              </tr>
            )})}
          </tbody>
        </table>

        <div className="gmp-title-row">
          Danh sách mẻ
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
            {orderBatches.length === 0 && (
              <tr>
                <td colSpan={4} className="text-center py-4 text-neutral-500">
                  Chưa có dữ liệu mẻ sản xuất cho lệnh này.
                </td>
              </tr>
            )}
            {orderBatches.map((batch) => {
              const pointer = Math.min(getStepPointer(batch), totalSteps);
              if (orders.length === 0) {
                return (
                  <div className="space-y-6">
                    <div className="card text-neutral-500">
                      Chưa có lệnh sản xuất trong cơ sở dữ liệu
                    </div>
                  </div>
                );
              }

              return (
                <tr key={batch.batchId}>
                  <td>{batch.batchNumber}</td>
                  <td>
                    <span
                      className={`inline-flex px-2.5 py-1 rounded-full text-xs font-semibold ${getStatusClass(batch.status)}`}
                    >
                      {getStatusLabel(batch.status)}
                    </span>
                  </td>
                  <td>
                    {routingSteps.find((step) => step.stepNumber === pointer)
                      ?.stepName ?? "-"}
                  </td>
                  <td>
                    <div className="w-full">
                      <div className="progress-track">
                        <div
                          className="progress-fill"
                          style={{ width: `${getBatchProgress(batch)}%` }}
                        />
                      </div>
                      <p className="text-xs text-neutral-600 mt-1">
                        {getBatchProgress(batch)}%
                      </p>
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>

        {/* Removd TIẾN ĐỘ SẢN XUẤT table to simplify UI as requested */}

        {/* Description Modal */}
        {viewedDescription && (
          <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
            <div className="bg-white rounded-2xl w-full max-w-lg p-6 space-y-4">
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-bold text-gray-900 border-b pb-2 mb-2 w-full text-left">
                  Mô tả công đoạn
                </h3>
              </div>
              <div className="text-sm text-neutral-700 whitespace-pre-wrap">
                {viewedDescription}
              </div>
              <div className="flex justify-end pt-4 mt-4 border-t">
                <button
                  onClick={() => setViewedDescription(null)}
                  className="btn-primary"
                >
                  Đóng
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
