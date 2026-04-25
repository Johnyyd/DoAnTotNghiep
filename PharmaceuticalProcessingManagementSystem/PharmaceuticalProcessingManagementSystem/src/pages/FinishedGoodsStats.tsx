import { useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import { productionBatchesApi, productionOrdersApi, recipesApi } from '@/services/api';
import { BarChart3, PackageCheck, Factory, Clock3 } from 'lucide-react';

interface OrderStatSource {
  orderId: number;
  product: string;
  plannedQuantity: number;
  unit: string;
}

interface BatchStatSource {
  orderId: number;
  status: string;
}

type StatRow = {
  product: string;
  completedBatches: number;
  inProgressBatches: number;
  holdBatches: number;
  totalPlannedQty: number;
  unit: string;
};

function normalizeStatus(raw?: string): string {
  if (!raw) return 'Draft';
  const value = raw.toLowerCase();
  if (value.includes('complete')) return 'Completed';
  if (value.includes('hold')) return 'Hold';
  if (value.includes('process')) return 'InProcess';
  if (value.includes('approved')) return 'Approved';
  return raw;
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

export default function FinishedGoodsStats() {
  const { data: ordersRaw, isLoading: ordersLoading } = useQuery({
    queryKey: ['productionOrders'],
    queryFn: () => productionOrdersApi.getAll(),
  });

  const { data: batchesRaw, isLoading: batchesLoading } = useQuery({
    queryKey: ['productionBatches'],
    queryFn: () => productionBatchesApi.getAll(),
  });

  const { data: recipesRaw } = useQuery({
    queryKey: ['recipes'],
    queryFn: () => recipesApi.getAll(),
  });

  const recipes = useMemo(() => {
    return toRows<any>(recipesRaw).map((r) => ({
      recipeId: Number(r.recipeId ?? r.RecipeId ?? 0),
      recipeName: r.material?.materialName ?? r.Material?.MaterialName ?? `Công thức #${r.recipeId ?? r.RecipeId}`,
      uomName: r.material?.baseUom?.uomName ?? r.Material?.BaseUom?.UomName ?? 'đơn vị',
    }));
  }, [recipesRaw]);

  const orders = useMemo<OrderStatSource[]>(() => {
    return toRows<any>(ordersRaw).map((item) => {
      const recipeId = Number(item.recipeId ?? item.RecipeId ?? 0);
      const recipe = recipes.find(r => r.recipeId === recipeId);
      return {
        orderId: Number(item.orderId ?? item.OrderId ?? 0),
        product: item.recipe?.material?.materialName ?? item.recipeName ?? recipe?.recipeName ?? `Recipe #${recipeId || '-'}`,
        plannedQuantity: Number(item.plannedQuantity ?? item.PlannedQuantity ?? 0),
        unit: item.recipe?.material?.baseUom?.uomName ?? item.recipe?.uomName ?? recipe?.uomName ?? 'đơn vị',
      };
    });
  }, [ordersRaw, recipes]);

  const batches = useMemo<BatchStatSource[]>(() => {
    return toRows<any>(batchesRaw).map((item) => ({
      orderId: Number(item.orderId ?? item.OrderId ?? 0),
      status: normalizeStatus(item.status ?? item.Status ?? item.qcStatus ?? item.QcStatus),
    }));
  }, [batchesRaw]);

  const rows = useMemo<StatRow[]>(() => {
    const map = new Map<string, StatRow>();

    orders.forEach((order) => {
      if (!map.has(order.product)) {
        map.set(order.product, {
          product: order.product,
          completedBatches: 0,
          inProgressBatches: 0,
          holdBatches: 0,
          totalPlannedQty: 0,
          unit: order.unit,
        });
      }
      const row = map.get(order.product)!;
      row.totalPlannedQty += order.plannedQuantity;
    });

    batches.forEach((batch) => {
      const order = orders.find((item) => item.orderId === batch.orderId);
      const product = order?.product ?? 'Chưa xác định';

      if (!map.has(product)) {
        map.set(product, {
          product,
          completedBatches: 0,
          inProgressBatches: 0,
          holdBatches: 0,
          totalPlannedQty: 0,
          unit: order?.unit ?? 'đơn vị',
        });
      }

      const row = map.get(product)!;
      if (batch.status === 'Completed') row.completedBatches += 1;
      else if (batch.status === 'Hold') row.holdBatches += 1;
      else row.inProgressBatches += 1;
    });

    return Array.from(map.values()).sort((a, b) => b.completedBatches - a.completedBatches);
  }, [orders, batches]);

  const totalCompleted = rows.reduce((acc, row) => acc + row.completedBatches, 0);
  const totalInProgress = rows.reduce((acc, row) => acc + row.inProgressBatches, 0);
  const totalHold = rows.reduce((acc, row) => acc + row.holdBatches, 0);
  const totalPlannedQty = rows.reduce((acc, row) => acc + row.totalPlannedQty, 0);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-neutral-900">Thống kê thành phẩm</h1>
        <p className="text-neutral-500 mt-1">Tổng hợp dữ liệu lô thành phẩm theo từng sản phẩm</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-neutral-500">Lô hoàn thành</p>
              <p className="text-2xl font-bold text-neutral-900">{totalCompleted}</p>
            </div>
            <PackageCheck className="w-7 h-7 text-emerald-600" />
          </div>
        </div>
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-neutral-500">Lô đang sản xuất</p>
              <p className="text-2xl font-bold text-neutral-900">{totalInProgress}</p>
            </div>
            <Factory className="w-7 h-7 text-blue-600" />
          </div>
        </div>
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-neutral-500">Lô tạm dừng</p>
              <p className="text-2xl font-bold text-neutral-900">{totalHold}</p>
            </div>
            <Clock3 className="w-7 h-7 text-amber-600" />
          </div>
        </div>
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-neutral-500">Số lượng kế hoạch</p>
              <p className="text-2xl font-bold text-neutral-900">{totalPlannedQty.toLocaleString()} <span className="text-sm font-normal text-neutral-500">đơn vị</span></p>
            </div>
            <BarChart3 className="w-7 h-7 text-primary-600" />
          </div>
        </div>
      </div>

      <div className="table-container">
        <table className="table">
          <thead>
            <tr>
              <th>Thành phẩm</th>
              <th>Lô hoàn thành</th>
              <th>Lô đang sản xuất</th>
              <th>Lô tạm dừng</th>
              <th>Tổng số lượng kế hoạch</th>
            </tr>
          </thead>
          <tbody>
            {ordersLoading || batchesLoading ? (
              <tr>
                <td colSpan={5} className="text-center py-6 text-neutral-500">Đang tải dữ liệu thống kê...</td>
              </tr>
            ) : rows.length === 0 ? (
              <tr>
                <td colSpan={5} className="text-center py-6 text-neutral-500">Chưa có dữ liệu thành phẩm.</td>
              </tr>
            ) : (
              rows.map((row) => (
                <tr key={row.product}>
                  <td className="font-medium text-neutral-900">{row.product}</td>
                  <td>{row.completedBatches}</td>
                  <td>{row.inProgressBatches}</td>
                  <td>{row.holdBatches}</td>
                  <td>{row.totalPlannedQty.toLocaleString()} {row.unit}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
