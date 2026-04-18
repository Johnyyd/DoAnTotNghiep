import { useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { productionBatchesApi, productionOrdersApi } from '@/services/api';
import { ClipboardList, Search, CheckCircle, Clock, RefreshCw, Plus } from 'lucide-react';
import { toast } from 'sonner';

interface OrderOption {
  orderId: number;
  orderCode: string;
}

interface BatchFormState {
  orderId: number;
  batchNumber: string;
  status: string;
  manufactureDate: string;
  expiryDate: string;
  currentStep: number;
}

interface UiBatch {
  batchId: number;
  batchNumber: string;
  orderId: number;
  status?: string;
  qcStatus?: string;
  manufactureDate?: string;
  endTime?: string;
  order?: {
    orderCode?: string;
    recipe?: {
      material?: {
        materialName?: string;
      };
    };
  };
}

function toRows<T>(raw: unknown): T[] {
  if (Array.isArray(raw)) return raw as T[];
  if (raw && typeof raw === 'object' && 'data' in raw) {
    const data = (raw as { data?: unknown }).data;
    return Array.isArray(data) ? (data as T[]) : [];
  }
  return [];
}

export default function ProductionBatches() {
  const [search, setSearch] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [form, setForm] = useState<BatchFormState>({
    orderId: 0,
    batchNumber: '',
    status: 'In-Process',
    manufactureDate: '',
    expiryDate: '',
    currentStep: 1,
  });

  const queryClient = useQueryClient();

  const { data: response, isLoading } = useQuery({
    queryKey: ['productionBatches'],
    queryFn: () => productionBatchesApi.getAll(),
  });

  const { data: ordersRaw } = useQuery({
    queryKey: ['productionOrders'],
    queryFn: () => productionOrdersApi.getAll(),
  });

  const orders = useMemo<OrderOption[]>(() => {
    const rows = Array.isArray(ordersRaw)
      ? ordersRaw
      : (ordersRaw as { data?: unknown; items?: unknown })?.data ??
        (ordersRaw as { data?: unknown; items?: unknown })?.items ??
        [];

    return (rows as any[]).map((item) => ({
      orderId: Number(item.orderId ?? item.OrderId ?? 0),
      orderCode: item.orderCode ?? item.OrderCode ?? '',
    }));
  }, [ordersRaw]);

  const createBatchMutation = useMutation({
    mutationFn: () => productionBatchesApi.create(form),
    onSuccess: async () => {
      toast.success('Tạo mẻ sản xuất thành công');
      await queryClient.invalidateQueries({ queryKey: ['productionBatches'] });
      setShowModal(false);
      setForm({ orderId: 0, batchNumber: '', status: 'In-Process', manufactureDate: '', expiryDate: '', currentStep: 1 });
    },
    onError: (err: any) => {
      toast.error(err?.response?.data?.message || 'Không thể tạo mẻ sản xuất');
    },
  });

  const finishMutation = useMutation({
    mutationFn: (batchId: number) => productionBatchesApi.finish(batchId),
    onSuccess: async () => {
      toast.success('Đóng mẻ sản xuất thành công');
      await queryClient.invalidateQueries({ queryKey: ['productionBatches'] });
    },
    onError: (err: any) => {
      toast.error(err?.response?.data?.message || 'Không thể đóng mẻ. Vui lòng thử lại.');
    },
  });

  const batches = useMemo<UiBatch[]>(() => toRows<any>(response), [response]);

  const filtered = useMemo(() => {
    const keyword = search.trim().toLowerCase();
    return batches.filter((b) => (b.batchNumber ?? '').toLowerCase().includes(keyword));
  }, [batches, search]);

  const getStatusInfo = (status?: string) => {
    const normalized = (status || '').toLowerCase();
    if (normalized.includes('process')) return { label: 'Đang sản xuất', badgeClass: 'bg-blue-100 text-blue-700' };
    if (normalized.includes('complete')) return { label: 'Hoàn thành', badgeClass: 'bg-green-100 text-green-700' };
    if (normalized.includes('hold')) return { label: 'Tạm dừng', badgeClass: 'bg-orange-100 text-orange-700' };
    return { label: status || 'Unknown', badgeClass: 'bg-gray-100 text-gray-800' };
  };

  const fmt = (dateString?: string) => {
    if (!dateString) return '-';
    try {
      return new Date(dateString).toLocaleString('vi-VN');
    } catch {
      return '-';
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900">Quản lý lô thành phẩm</h1>
          <p className="text-neutral-500 mt-1">Theo dõi và cập nhật các mẻ/lô thành phẩm</p>
        </div>
        <button onClick={() => setShowModal(true)} className="btn-primary">
          <Plus className="w-4 h-4 mr-2" />
          Tạo mẻ mới
        </button>
      </div>

      <div className="card">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-neutral-400" />
            <input
              type="text"
              placeholder="Tìm kiếm theo mã mẻ..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="input pl-10"
            />
          </div>
        </div>
      </div>

      <div className="card p-0 overflow-hidden">
        {isLoading ? (
          <div className="flex items-center justify-center p-12">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
          </div>
        ) : filtered.length === 0 ? (
          <div className="text-center py-12">
            <ClipboardList className="w-12 h-12 text-neutral-300 mx-auto mb-4" />
            <p className="text-neutral-500">Không tìm thấy mẻ sản xuất nào.</p>
          </div>
        ) : (
          <div className="table-container">
            <table className="table">
              <thead>
                <tr>
                  <th>Mã mẻ</th>
                  <th>Lệnh SX</th>
                  <th>Sản phẩm</th>
                  <th>Trạng thái</th>
                  <th>Bắt đầu</th>
                  <th>Kết thúc</th>
                  <th className="text-right">Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((batch) => {
                  const statusInfo = getStatusInfo(batch.status ?? batch.qcStatus);
                  return (
                    <tr key={batch.batchId}>
                      <td>
                        <code className="text-xs bg-neutral-100 px-2 py-1 rounded font-mono text-primary-600">{batch.batchNumber}</code>
                      </td>
                      <td className="text-sm text-neutral-600">{batch.order?.orderCode ?? `#${batch.orderId}`}</td>
                      <td className="text-sm text-neutral-700">{batch.order?.recipe?.material?.materialName ?? '-'}</td>
                      <td>
                        <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${statusInfo.badgeClass}`}>
                          {statusInfo.label}
                        </span>
                      </td>
                      <td className="text-neutral-600 text-sm">{fmt(batch.manufactureDate)}</td>
                      <td className="text-neutral-600 text-sm">{fmt(batch.endTime)}</td>
                      <td className="text-right">
                        <div className="flex items-center justify-end space-x-2">
                          {(batch.status === 'In-Process' || batch.status === 'InProcess') && (
                            <button
                              onClick={() => finishMutation.mutate(batch.batchId)}
                              disabled={finishMutation.isPending}
                              className="btn-ghost text-green-600 text-sm flex items-center"
                            >
                              {finishMutation.isPending ? (
                                <RefreshCw className="w-4 h-4 mr-1 animate-spin" />
                              ) : (
                                <CheckCircle className="w-4 h-4 mr-1" />
                              )}
                              Hoàn thành
                            </button>
                          )}
                          <button className="btn-ghost text-sm flex items-center">
                            <Clock className="w-4 h-4 mr-1" /> Logs
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {showModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl w-full max-w-xl p-6 space-y-4">
            <h3 className="text-xl font-bold">Tạo mẻ thành phẩm</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <select className="input" value={form.orderId} onChange={(e) => setForm({ ...form, orderId: Number(e.target.value) })}>
                <option value={0}>Chọn lệnh sản xuất</option>
                {orders.map((order) => (
                  <option key={order.orderId} value={order.orderId}>
                    {order.orderCode}
                  </option>
                ))}
              </select>
              <input
                className="input"
                placeholder="Mã mẻ"
                value={form.batchNumber}
                onChange={(e) => setForm({ ...form, batchNumber: e.target.value })}
              />
              <select className="input" value={form.status} onChange={(e) => setForm({ ...form, status: e.target.value })}>
                <option value="In-Process">In-Process</option>
                <option value="On-Hold">On-Hold</option>
                <option value="Completed">Completed</option>
              </select>
              <input
                type="number"
                className="input"
                placeholder="Bước hiện tại"
                value={form.currentStep}
                onChange={(e) => setForm({ ...form, currentStep: Number(e.target.value) })}
              />
              <div>
                <label className="text-xs text-neutral-500">Ngày sản xuất</label>
                <input
                  type="date"
                  className="input"
                  value={form.manufactureDate}
                  onChange={(e) => setForm({ ...form, manufactureDate: e.target.value })}
                />
              </div>
              <div>
                <label className="text-xs text-neutral-500">Hạn dùng</label>
                <input
                  type="date"
                  className="input"
                  value={form.expiryDate}
                  onChange={(e) => setForm({ ...form, expiryDate: e.target.value })}
                />
              </div>
            </div>
            <div className="flex justify-end gap-2">
              <button onClick={() => setShowModal(false)} className="btn-ghost">Hủy</button>
              <button onClick={() => createBatchMutation.mutate()} className="btn-primary">Tạo mẻ</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
