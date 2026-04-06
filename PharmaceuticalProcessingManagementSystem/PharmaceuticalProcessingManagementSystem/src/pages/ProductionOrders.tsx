import { useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { productionOrdersApi, recipesApi } from '@/services/api';
import {
  Search,
  Plus,
  ClipboardList,
  Clock,
  AlertCircle,
  CheckCircle,
  Eye,
  MoreVertical,
  Check,
  PauseCircle,
  Pencil,
  Trash2,
} from 'lucide-react';
import type { ProductionOrder } from '@/types';

type OrderStatus = ProductionOrder['status'];

interface UiProductionOrder {
  orderId: number;
  orderCode: string;
  recipeId: number;
  recipeName?: string;
  plannedQuantity: number;
  status: OrderStatus;
  plannedStartDate?: string;
  plannedEndDate?: string;
  note?: string;
}

interface RecipeOption {
  recipeId: number;
  recipeCode: string;
  recipeName: string;
}

interface OrderFormState {
  orderCode: string;
  recipeId: number;
  plannedQuantity: number;
  startDate: string;
  endDate: string;
  status: OrderStatus;
  note: string;
}

const orderStatuses: OrderStatus[] = ['Draft', 'Approved', 'InProcess', 'Hold', 'Completed'];

function toRows<T>(raw: unknown): T[] {
  if (Array.isArray(raw)) return raw as T[];
  if (raw && typeof raw === 'object') {
    const obj = raw as { data?: unknown; items?: unknown };
    if (Array.isArray(obj.data)) return obj.data as T[];
    if (Array.isArray(obj.items)) return obj.items as T[];
  }
  return [];
}

function normalizeOrder(item: any): UiProductionOrder {
  const statusRaw = item.status ?? item.Status ?? 'Draft';
  const status = (statusRaw === 'In-Process' ? 'InProcess' : statusRaw) as OrderStatus;

  return {
    orderId: Number(item.orderId ?? item.OrderId ?? 0),
    orderCode: item.orderCode ?? item.OrderCode ?? '',
    recipeId: Number(item.recipeId ?? item.RecipeId ?? 0),
    recipeName: item.recipe?.recipeName ?? item.recipe?.material?.materialName ?? item.recipeName,
    plannedQuantity: Number(item.plannedQuantity ?? item.PlannedQuantity ?? 0),
    status,
    plannedStartDate: item.startDate ?? item.plannedStartDate ?? item.StartDate,
    plannedEndDate: item.endDate ?? item.plannedEndDate ?? item.EndDate,
    note: item.note ?? item.Note,
  };
}

export default function ProductionOrders() {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | OrderStatus>('all');
  const [showActions, setShowActions] = useState<number | null>(null);

  const [actionModal, setActionModal] = useState<{ type: 'approve' | 'hold'; order: UiProductionOrder } | null>(null);
  const [actionInput, setActionInput] = useState('');

  const [showOrderModal, setShowOrderModal] = useState(false);
  const [editingOrder, setEditingOrder] = useState<UiProductionOrder | null>(null);
  const [orderForm, setOrderForm] = useState<OrderFormState>({
    orderCode: '',
    recipeId: 0,
    plannedQuantity: 0,
    startDate: '',
    endDate: '',
    status: 'Draft',
    note: '',
  });

  const { data: ordersRaw, isLoading } = useQuery({
    queryKey: ['productionOrders'],
    queryFn: () => productionOrdersApi.getAll(),
  });

  const { data: recipesRaw } = useQuery({
    queryKey: ['recipes'],
    queryFn: () => recipesApi.getAll(),
  });

  const orders = useMemo<UiProductionOrder[]>(() => toRows<any>(ordersRaw).map(normalizeOrder), [ordersRaw]);

  const recipes = useMemo<RecipeOption[]>(() => {
    return toRows<any>(recipesRaw).map((item) => ({
      recipeId: Number(item.recipeId ?? item.RecipeId ?? 0),
      recipeCode: item.recipeCode ?? item.RecipeCode ?? '',
      recipeName: item.recipeName ?? item.RecipeName ?? '',
    }));
  }, [recipesRaw]);

  const filteredOrders = useMemo(() => {
    const keyword = search.trim().toLowerCase();
    return orders.filter((order) => {
      const matchesSearch = !keyword || order.orderCode.toLowerCase().includes(keyword);
      const matchesStatus = statusFilter === 'all' || order.status === statusFilter;
      return matchesSearch && matchesStatus;
    });
  }, [orders, search, statusFilter]);

  const createOrderMutation = useMutation({
    mutationFn: () => productionOrdersApi.create(orderForm),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['productionOrders'] });
      setShowOrderModal(false);
      setEditingOrder(null);
    },
  });

  const updateOrderMutation = useMutation({
    mutationFn: () => productionOrdersApi.update(editingOrder!.orderId, orderForm),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['productionOrders'] });
      setShowOrderModal(false);
      setEditingOrder(null);
    },
  });

  const deleteOrderMutation = useMutation({
    mutationFn: (id: number) => productionOrdersApi.delete(id),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['productionOrders'] });
    },
  });

  const approveMutation = useMutation({
    mutationFn: ({ id, signature }: { id: number; signature: string }) => productionOrdersApi.approve(id, signature),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['productionOrders'] });
      setActionModal(null);
      setActionInput('');
    },
  });

  const holdMutation = useMutation({
    mutationFn: ({ id, reason }: { id: number; reason: string }) => productionOrdersApi.hold(id, reason),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['productionOrders'] });
      setActionModal(null);
      setActionInput('');
    },
  });

  const handleActionSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!actionModal) return;
    if (actionModal.type === 'approve') {
      approveMutation.mutate({ id: actionModal.order.orderId, signature: actionInput });
      return;
    }
    holdMutation.mutate({ id: actionModal.order.orderId, reason: actionInput });
  };

  const openCreateOrder = () => {
    setEditingOrder(null);
    setOrderForm({
      orderCode: '',
      recipeId: 0,
      plannedQuantity: 0,
      startDate: '',
      endDate: '',
      status: 'Draft',
      note: '',
    });
    setShowOrderModal(true);
  };

  const openEditOrder = (order: UiProductionOrder) => {
    setEditingOrder(order);
    setOrderForm({
      orderCode: order.orderCode,
      recipeId: order.recipeId,
      plannedQuantity: order.plannedQuantity,
      startDate: order.plannedStartDate ? new Date(order.plannedStartDate).toISOString().slice(0, 10) : '',
      endDate: order.plannedEndDate ? new Date(order.plannedEndDate).toISOString().slice(0, 10) : '',
      status: order.status,
      note: order.note ?? '',
    });
    setShowOrderModal(true);
  };

  const getStatusInfo = (status: OrderStatus) => {
    switch (status) {
      case 'Draft':
        return { label: 'Nháp', badgeClass: 'bg-neutral-100 text-neutral-700', icon: Clock };
      case 'Approved':
        return { label: 'Đã duyệt', badgeClass: 'bg-blue-100 text-blue-700', icon: CheckCircle };
      case 'InProcess':
        return { label: 'Đang sản xuất', badgeClass: 'bg-purple-100 text-purple-700', icon: AlertCircle };
      case 'Hold':
        return { label: 'Tạm dừng', badgeClass: 'bg-orange-100 text-orange-700', icon: Clock };
      case 'Completed':
        return { label: 'Hoàn thành', badgeClass: 'bg-green-100 text-green-700', icon: CheckCircle };
      default:
        return { label: status || 'Unknown', badgeClass: 'bg-gray-100 text-gray-700', icon: Clock };
    }
  };

  const formatDate = (dateString?: string) => {
    if (!dateString) return '-';
    try {
      return new Date(dateString).toLocaleDateString('vi-VN');
    } catch {
      return 'Ngày không hợp lệ';
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Quản lý lệnh sản xuất</h1>
          <p className="text-neutral-500 mt-1">Tạo, sửa, xóa, duyệt và tạm dừng lệnh sản xuất</p>
        </div>
        <button onClick={openCreateOrder} className="btn-primary flex items-center">
          <Plus className="w-5 h-5 mr-2" />
          Tạo lệnh mới
        </button>
      </div>

      <div className="card">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-neutral-400" />
            <input
              type="text"
              placeholder="Tìm kiếm theo mã lệnh..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="input pl-10"
            />
          </div>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value as 'all' | OrderStatus)}
            className="input w-auto sm:w-48"
          >
            <option value="all">Tất cả trạng thái</option>
            <option value="Draft">Nháp</option>
            <option value="Approved">Đã duyệt</option>
            <option value="InProcess">Đang sản xuất</option>
            <option value="Hold">Tạm dừng</option>
            <option value="Completed">Hoàn thành</option>
          </select>
        </div>
      </div>

      <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 text-sm text-yellow-800 flex items-start">
        <AlertCircle className="w-5 h-5 mr-2 mt-0.5 flex-shrink-0" />
        <div>
          <strong>GMP:</strong> Chuyển trạng thái Draft sang Approved cần chữ ký điện tử. Trạng thái Hold cần ghi lý do.
        </div>
      </div>

      <div className="card p-0 overflow-hidden">
        {isLoading ? (
          <div className="flex items-center justify-center p-12">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
          </div>
        ) : filteredOrders.length === 0 ? (
          <div className="text-center py-12">
            <ClipboardList className="w-12 h-12 text-neutral-300 mx-auto mb-4" />
            <p className="text-neutral-500">Không tìm thấy lệnh sản xuất nào.</p>
          </div>
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
                {filteredOrders.map((order) => {
                  const statusInfo = getStatusInfo(order.status);
                  const StatusIcon = statusInfo.icon;
                  return (
                    <tr key={order.orderId}>
                      <td>
                        <code className="text-xs bg-neutral-100 px-2 py-1 rounded font-mono text-primary-600">{order.orderCode}</code>
                      </td>
                      <td className="font-medium text-neutral-900">{order.recipeName || `Công thức #${order.recipeId}`}</td>
                      <td className="text-neutral-600">{order.plannedQuantity?.toLocaleString() || 0}</td>
                      <td>
                        <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium ${statusInfo.badgeClass}`}>
                          <StatusIcon className="w-3 h-3 mr-1" />
                          {statusInfo.label}
                        </span>
                      </td>
                      <td className="text-neutral-500 text-sm">{formatDate(order.plannedStartDate)}</td>
                      <td className="text-right">
                        <div className="relative flex items-center justify-end space-x-2">
                          <button className="btn-ghost flex items-center px-2 py-1 text-sm text-neutral-600">
                            <Eye className="w-4 h-4 mr-1" /> Xem
                          </button>
                          <button onClick={() => openEditOrder(order)} className="btn-ghost text-sm">
                            <Pencil className="w-4 h-4 mr-1" /> Sửa
                          </button>
                          <button
                            onClick={() => {
                              if (confirm('Xóa lệnh sản xuất này?')) {
                                deleteOrderMutation.mutate(order.orderId);
                              }
                            }}
                            className="btn-ghost text-sm text-red-600"
                          >
                            <Trash2 className="w-4 h-4 mr-1" /> Xóa
                          </button>
                          <button
                            onClick={() => setShowActions(showActions === order.orderId ? null : order.orderId)}
                            className="p-1 rounded hover:bg-neutral-100"
                          >
                            <MoreVertical className="w-4 h-4 text-neutral-500" />
                          </button>
                          {showActions === order.orderId && (
                            <div className="absolute right-0 top-8 mt-2 w-48 bg-surface rounded-xl shadow-lg border border-neutral-200 py-2 z-10 text-left">
                              {order.status === 'Draft' && (
                                <button
                                  onClick={() => {
                                    setActionModal({ type: 'approve', order });
                                    setShowActions(null);
                                    setActionInput('');
                                  }}
                                  className="w-full flex items-center px-4 py-2 text-sm text-blue-600 hover:bg-blue-50"
                                >
                                  <Check className="w-4 h-4 mr-3" /> Duyệt lệnh
                                </button>
                              )}
                              {(order.status === 'Approved' || order.status === 'InProcess') && (
                                <button
                                  onClick={() => {
                                    setActionModal({ type: 'hold', order });
                                    setShowActions(null);
                                    setActionInput('');
                                  }}
                                  className="w-full flex items-center px-4 py-2 text-sm text-orange-600 hover:bg-orange-50"
                                >
                                  <PauseCircle className="w-4 h-4 mr-3" /> Tạm ngưng
                                </button>
                              )}
                            </div>
                          )}
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

      {showOrderModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl w-full max-w-2xl p-6 space-y-4">
            <h2 className="text-xl font-bold">{editingOrder ? 'Cập nhật lệnh sản xuất' : 'Tạo lệnh sản xuất'}</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <input
                className="input"
                placeholder="Mã lệnh"
                value={orderForm.orderCode}
                onChange={(e) => setOrderForm({ ...orderForm, orderCode: e.target.value })}
              />
              <select
                className="input"
                value={orderForm.recipeId}
                onChange={(e) => setOrderForm({ ...orderForm, recipeId: Number(e.target.value) })}
              >
                <option value={0}>Chọn công thức</option>
                {recipes.map((recipe) => (
                  <option key={recipe.recipeId} value={recipe.recipeId}>
                    {recipe.recipeCode} - {recipe.recipeName}
                  </option>
                ))}
              </select>
              <input
                type="number"
                className="input"
                placeholder="Số lượng kế hoạch"
                value={orderForm.plannedQuantity}
                onChange={(e) => setOrderForm({ ...orderForm, plannedQuantity: Number(e.target.value) })}
              />
              <select
                className="input"
                value={orderForm.status}
                onChange={(e) => setOrderForm({ ...orderForm, status: e.target.value as OrderStatus })}
              >
                {orderStatuses.map((status) => (
                  <option key={status} value={status}>
                    {status}
                  </option>
                ))}
              </select>
              <div>
                <label className="text-xs text-neutral-500">Ngày bắt đầu dự kiến</label>
                <input
                  type="date"
                  className="input"
                  value={orderForm.startDate}
                  onChange={(e) => setOrderForm({ ...orderForm, startDate: e.target.value })}
                />
              </div>
              <div>
                <label className="text-xs text-neutral-500">Ngày kết thúc dự kiến</label>
                <input
                  type="date"
                  className="input"
                  value={orderForm.endDate}
                  onChange={(e) => setOrderForm({ ...orderForm, endDate: e.target.value })}
                />
              </div>
            </div>
            <textarea
              className="input"
              rows={3}
              placeholder="Ghi chú"
              value={orderForm.note}
              onChange={(e) => setOrderForm({ ...orderForm, note: e.target.value })}
            />
            <div className="flex justify-end gap-2">
              <button onClick={() => setShowOrderModal(false)} className="btn-ghost">Hủy</button>
              <button
                onClick={() => (editingOrder ? updateOrderMutation.mutate() : createOrderMutation.mutate())}
                className="btn-primary"
                disabled={createOrderMutation.isPending || updateOrderMutation.isPending}
              >
                {editingOrder ? 'Lưu cập nhật' : 'Tạo mới'}
              </button>
            </div>
          </div>
        </div>
      )}

      {actionModal && (
        <div className="fixed inset-0 bg-neutral-900 bg-opacity-50 z-50 flex items-center justify-center p-4">
          <div className="bg-surface rounded-2xl shadow-xl w-full max-w-md">
            <div className="p-6 border-b border-neutral-200">
              <h2 className="text-xl font-bold text-neutral-900">
                {actionModal.type === 'approve' ? 'Duyệt lệnh sản xuất' : 'Tạm ngừng lệnh sản xuất'}
              </h2>
            </div>
            <form onSubmit={handleActionSubmit} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-2">
                  {actionModal.type === 'approve' ? 'Chữ ký điện tử (Mã PIN/Mật khẩu)' : 'Lý do tạm ngừng'}
                </label>
                <input
                  type={actionModal.type === 'approve' ? 'password' : 'text'}
                  required
                  value={actionInput}
                  onChange={(e) => setActionInput(e.target.value)}
                  className="input"
                  placeholder={
                    actionModal.type === 'approve'
                      ? 'Nhập mã PIN để xác nhận GMP...'
                      : 'Thiết bị hỏng, sai lệch quy trình...'
                  }
                />
              </div>
              <div className="flex justify-end space-x-3 pt-4">
                <button type="button" onClick={() => setActionModal(null)} className="btn-ghost">Hủy</button>
                <button
                  type="submit"
                  disabled={approveMutation.isPending || holdMutation.isPending}
                  className={`px-4 py-2 rounded-lg font-medium text-white ${
                    actionModal.type === 'approve' ? 'bg-primary-600 hover:bg-primary-700' : 'bg-orange-600 hover:bg-orange-700'
                  }`}
                >
                  {approveMutation.isPending || holdMutation.isPending ? 'Đang xử lý...' : 'Xác nhận'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}


