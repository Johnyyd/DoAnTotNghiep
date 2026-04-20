import { useState, useEffect, useMemo } from 'react';
import { Package, ClipboardList, Warehouse, TrendingUp, Activity, Search } from 'lucide-react';
import { useQuery } from '@tanstack/react-query';
import { inventoryApi, productionOrdersApi, productionBatchesApi } from '@/services/api';

export default function Dashboard() {
  const { data: lotsData } = useQuery({
    queryKey: ['inventory-lots'],
    queryFn: () => inventoryApi.getLots(),
  });

  const { data: ordersRes } = useQuery({
    queryKey: ['production-orders'],
    // Fetch all for dashboard aggregation
    queryFn: () => productionOrdersApi.getAll({ page: 1, pageSize: 1000 }), 
  });

  const { data: batchesRes } = useQuery({
    queryKey: ['production-batches'],
    queryFn: () => productionBatchesApi.getAll(),
  });

  // Calculate inventory summary and metrics
  const lots = Array.isArray(lotsData) ? lotsData : (lotsData as any)?.data ?? [];
  const inventorySummary = useMemo(() => {
    const map = new Map<string, { materialCode: string; materialName: string; total: number; uom: string; lotCount: number }>();
    for (const lot of lots) {
      const material = lot.material ?? {};
      const materialCode = material.materialCode ?? lot.materialCode ?? `MAT-${lot.materialId}`;
      const materialName = material.materialName ?? lot.materialName ?? 'Nguyên liệu chưa rõ';
      const uom = material.baseUom?.uomName ?? material.baseUomName ?? lot.uomName ?? '';
      const qty = Number(lot.quantityCurrent ?? 0);
      const key = String(materialCode);

      if (!map.has(key)) {
        map.set(key, { materialCode, materialName, total: 0, uom, lotCount: 0 });
      }

      const row = map.get(key)!;
      row.total += qty;
      row.lotCount += 1;
      if (!row.uom && uom) row.uom = uom;
    }
    return Array.from(map.values());
  }, [lots]);

  const [currentInvIdx, setCurrentInvIdx] = useState(0);
  useEffect(() => {
    if (inventorySummary.length <= 1) return;
    const interval = setInterval(() => {
      setCurrentInvIdx(prev => (prev + 1) % inventorySummary.length);
    }, 4000);
    return () => clearInterval(interval);
  }, [inventorySummary.length]);

  const orders = Array.isArray(ordersRes) ? ordersRes : (ordersRes as any)?.items ?? (ordersRes as any)?.data ?? [];
  const batches = Array.isArray(batchesRes) ? batchesRes : (batchesRes as any)?.data ?? [];

  const totalOrders = orders.length;
  const inProcessOrders = orders.filter((o: any) => o.status === 'InProcess');
  const inProcessOrderIds = new Set(inProcessOrders.map((o: any) => o.orderId));
  const activeBatchesCount = batches.filter((b: any) => inProcessOrderIds.has(b.orderId)).length;

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900">Dashboard</h1>
          <p className="text-neutral-500 mt-1">Tổng quan hệ thống quản lý chế biến thuốc</p>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        
        {/* Card 1: Inventory (Carousel) */}
        <div className="card group relative overflow-hidden">
          <div className="flex items-start justify-between">
            <div className="flex-1 w-full overflow-hidden">
              <p className="text-sm font-medium text-neutral-500 mb-1">Nguyên liệu còn tồn kho</p>
              
              <div className="relative w-full h-[4.5rem]">
                {inventorySummary.length > 0 ? (
                  <div 
                    className="absolute top-0 left-0 flex w-full h-full transition-transform duration-500 ease-in-out" 
                    style={{ transform: `translateX(-${currentInvIdx * 100}%)` }}
                  >
                    {inventorySummary.map((inv) => (
                      <div key={inv.materialCode} className="w-full h-full flex-shrink-0 flex flex-col justify-start pt-1 pr-4">
                        <p className="text-lg font-bold text-neutral-900 mb-1 truncate" title={inv.materialName}>
                          {inv.materialName}
                        </p>
                        <div className="w-max inline-flex items-center text-xs font-semibold text-primary-700 bg-primary-50 px-2 py-1 rounded-lg">
                          <Package className="w-3 h-3 mr-1" />
                          {inv.total.toLocaleString('vi-VN')} {inv.uom}
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="w-full h-full flex flex-col justify-center">
                    <p className="text-2xl font-bold text-neutral-900 mb-1">0</p>
                    <p className="text-sm text-neutral-500">Đang tải...</p>
                  </div>
                )}
              </div>
            </div>


          </div>
          
          {inventorySummary.length > 1 && (
            <div className="absolute bottom-2 left-1/2 -translate-x-1/2 flex space-x-1 z-10">
              {inventorySummary.map((_, idx) => (
                <div key={idx} className={`h-1.5 rounded-full transition-all duration-300 ${idx === currentInvIdx ? 'w-4 bg-primary-500' : 'w-1.5 bg-neutral-200'}`} />
              ))}
            </div>
          )}
        </div>

        {/* Card 2: Lệnh Sản Xuất */}
        <div className="card group">
          <div className="flex items-start justify-between">
            <div className="flex-1">
              <p className="text-sm font-medium text-neutral-500 mb-1">Lệnh sản xuất</p>
              <p className="text-4xl font-bold text-neutral-900 mb-2">{totalOrders}</p>
              <div className="inline-flex items-center text-sm text-purple-600 bg-purple-50 px-2 py-1 rounded-lg">
                <TrendingUp className="w-3 h-3 mr-1" />
                {inProcessOrders.length} đang thực hiện
              </div>
            </div>
            <div className="p-4 rounded-2xl bg-gradient-to-br from-purple-500 to-purple-600 shadow-lg group-hover:shadow-xl transition-shadow shrink-0 ml-4">
              <Warehouse className="w-7 h-7 text-white" />
            </div>
          </div>
        </div>

        {/* Card 3: Mẻ Sản Xuất */}
        <div className="card group">
          <div className="flex items-start justify-between">
            <div className="flex-1">
              <p className="text-sm font-medium text-neutral-500 mb-1">Mẻ sản xuất</p>
              <p className="text-4xl font-bold text-neutral-900 mb-2">{activeBatchesCount}</p>
              <div className="inline-flex items-center text-sm text-teal-600 bg-teal-50 px-2 py-1 rounded-lg">
                <Activity className="w-3 h-3 mr-1" />
                Thuộc lệnh hiện tại
              </div>
            </div>
            <div className="p-4 rounded-2xl bg-gradient-to-br from-teal-500 to-teal-600 shadow-lg group-hover:shadow-xl transition-shadow shrink-0 ml-4">
              <Activity className="w-7 h-7 text-white" />
            </div>
          </div>
        </div>

      </div>

      {/* Quick Actions */}
      <div className="card">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-lg font-bold text-neutral-900">Truy Cập Nhanh</h2>
          <span className="text-sm text-neutral-500">Thao tác thường dùng</span>
        </div>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {[
            { name: 'Tạo Lệnh Sản Xuất', icon: ClipboardList, href: '/production-orders', action: 'create' },
            { name: 'Quản Lý Nguyên Liệu', icon: Package, href: '/materials', action: 'manage' },
            { name: 'Công Thức', icon: ClipboardList, href: '/recipes', action: 'view' },
            { name: 'Truy Xuất Nguồn Gốc', icon: Search, href: '/traceability', action: 'track' },
          ].map((action) => (
            <a
              key={action.name}
              href={action.href}
              className="group flex flex-col items-center p-6 rounded-xl border-2 border-dashed border-neutral-300 hover:border-primary-400 hover:bg-primary-50 transition-all duration-300"
            >
              <div className="p-4 bg-neutral-100 rounded-xl group-hover:bg-primary-100 transition-colors mb-3">
                <action.icon className="w-8 h-8 text-primary-600 group-hover:scale-110 transition-transform" />
              </div>
              <span className="text-sm font-medium text-neutral-700 group-hover:text-primary-700 text-center">
                {action.name}
              </span>
            </a>
          ))}
        </div>
      </div>
    </div>
  );
}
