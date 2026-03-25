import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { productionOrdersApi } from '@/services/api';
import { ProductionOrder } from '@/types';
import { Search, Plus, ClipboardList, Clock, AlertCircle, CheckCircle, Eye, MoreVertical, Check, PauseCircle } from 'lucide-react';

export default function ProductionOrders() {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [showActions, setShowActions] = useState<number | null>(null);
  const [actionModal, setActionModal] = useState<{ type: 'approve' | 'hold', order: ProductionOrder } | null>(null);
  const [actionInput, setActionInput] = useState('');

  const { data: ordersData, isLoading } = useQuery({
    queryKey: ['productionOrders'],
    queryFn: () => productionOrdersApi.getAll(),
  });

  const approveMutation = useMutation({
    mutationFn: ({ id, signature }: { id: number; signature: string }) => productionOrdersApi.approve(id, signature),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['productionOrders'] });
      setActionModal(null);
      setActionInput('');
    },
  });

  const holdMutation = useMutation({
    mutationFn: ({ id, reason }: { id: number; reason: string }) => productionOrdersApi.hold(id, reason),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['productionOrders'] });
      setActionModal(null);
      setActionInput('');
    },
  });

  const handleActionSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!actionModal) return;
    if (actionModal.type === 'approve') {
      approveMutation.mutate({ id: actionModal.order.orderId, signature: actionInput });
    } else {
      holdMutation.mutate({ id: actionModal.order.orderId, reason: actionInput });
    }
  };

  const ordersList = Array.isArray(ordersData) ? ordersData : (ordersData as any)?.data || [];

  const normalizedOrders: ProductionOrder[] = ordersList.map((o: any) => ({
    orderId: o.orderId ?? o.OrderId,
    orderCode: o.orderCode ?? o.OrderCode,
    recipeId: o.recipeId ?? o.RecipeId,
    productId: o.productId ?? o.recipeId,
    productName: o.recipe?.material?.materialName ?? o.productName ?? `Công thức #${o.recipeId ?? o.RecipeId}`,
    recipeName: o.recipe?.material?.materialName ?? o.recipeName,
    recipeCode: o.recipe?.recipeCode ?? o.recipeCode,
    plannedQuantity: o.plannedQuantity ?? o.PlannedQuantity,
    actualQuantity: o.actualQuantity ?? o.ActualQuantity,
    status: o.status ?? o.Status,
    plannedStartDate: o.startDate ?? o.plannedStartDate ?? o.StartDate,
    plannedEndDate: o.endDate ?? o.plannedEndDate ?? o.EndDate,
    actualStartDate: o.actualStartDate,
    actualEndDate: o.actualEndDate,
    approvedBy: o.approvedBy ?? o.ApprovedBy,
    approvedDate: o.approvedDate ?? o.ApprovedDate,
    createdBy: o.createdBy ?? o.CreatedBy,
    createdAt: o.createdAt ?? o.CreatedAt,
  }));

  const filteredOrders = normalizedOrders.filter((order) => {
    const matchesSearch = (order.orderCode?.toLowerCase() || '').includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'all' || order.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const getStatusInfo = (status: string) => {
    switch (status) {
      case 'Draft':
        return { label: 'Nháp', badgeClass: 'bg-neutral-100 text-neutral-700', icon: Clock };
      case 'Approved':
        return { label: 'Đã duyệt', badgeClass: 'bg-blue-100 text-blue-700', icon: CheckCircle };
      case 'In-Process':
        return { label: 'Đang sản xuất', badgeClass: 'bg-purple-100 text-purple-700', icon: AlertCircle };
      case 'On-Hold':
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
      return 'Invalid Date';
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Lệnh Sản Xuất</h1>
          <p className="text-neutral-500 mt-1">Quản lý và theo dõi tiến độ các lệnh sản xuất</p>
        </div>
        <button className="flex items-center px-4 py-2 bg-gmp-primary text-white rounded-lg hover:bg-blue-700 transition-colors">
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
              placeholder="Tìm kiếm theo mã lệnh (VD: PO-001)..."
              value={search}
              onChange={(e: React.ChangeEvent<HTMLInputElement>) => setSearch(e.target.value)}
              className="input pl-10"
            />
          </div>
          <select
            value={statusFilter}
            onChange={(e: React.ChangeEvent<HTMLSelectElement>) => setStatusFilter(e.target.value)}
            className="input w-auto sm:w-48"
          >
            <option value="all">Tất cả trạng thái</option>
            <option value="Draft">Nháp</option>
            <option value="Approved">Đã duyệt</option>
            <option value="In-Process">Đang sản xuất</option>
            <option value="On-Hold">Tạm dừng</option>
            <option value="Completed">Hoàn thành</option>
          </select>
        </div>
      </div>

      {/* Info Banner */}
      <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 text-sm text-yellow-800 flex items-start">
        <AlertCircle className="w-5 h-5 mr-2 mt-0.5 flex-shrink-0" />
        <div>
          <strong>GMP Critical:</strong> Không cho phép chuyển trạng thái tùy tiện. Việc chuyển trạng thái từ Draft sang Approved (hoặc Complete) cần có Digital Signature (Chữ ký điện tử).
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
                  <th>Mã Lệnh</th>
                  <th>Công thức</th>
                  <th>Số lượng Kế hoạch</th>
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
                        <code className="text-xs bg-neutral-100 px-2 py-1 rounded font-mono text-primary-600">
                          {order.orderCode}
                        </code>
                      </td>
                      <td className="font-medium text-neutral-900">
                        {order.recipeName || `Công thức #${order.recipeId}`}
                      </td>
                      <td className="text-neutral-600">
                        {order.plannedQuantity?.toLocaleString() || 0}
                      </td>
                      <td>
                        <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium ${statusInfo.badgeClass}`}>
                          <StatusIcon className="w-3 h-3 mr-1" />
                          {statusInfo.label}
                        </span>
                      </td>
                      <td className="text-neutral-500 text-sm">
                        {formatDate(order.plannedStartDate)}
                      </td>
                      <td className="text-right">
                        <div className="relative flex items-center justify-end space-x-2">
                          <button className="btn-ghost flex items-center px-2 py-1 text-sm text-neutral-600 hover:text-primary-600">
                            <Eye className="w-4 h-4 mr-1" /> Xem
                          </button>
                          <button onClick={() => setShowActions(showActions === order.orderId ? null : order.orderId)} className="p-1 rounded hover:bg-neutral-100">
                            <MoreVertical className="w-4 h-4 text-neutral-500" />
                          </button>
                          {showActions === order.orderId && (
                            <div className="absolute right-0 top-8 mt-2 w-48 bg-surface rounded-xl shadow-lg border border-neutral-200 py-2 z-10 text-left">
                              {order.status === 'Draft' && (
                                <button
                                  onClick={() => { setActionModal({ type: 'approve', order }); setShowActions(null); setActionInput(''); }}
                                  className="w-full flex items-center px-4 py-2 text-sm text-blue-600 hover:bg-blue-50"
                                >
                                  <Check className="w-4 h-4 mr-3" />
                                  Duyệt lệnh (Approve)
                                </button>
                              )}
                              {(order.status === 'Approved' || order.status === 'InProcess') && (
                                <button
                                  onClick={() => { setActionModal({ type: 'hold', order }); setShowActions(null); setActionInput(''); }}
                                  className="w-full flex items-center px-4 py-2 text-sm text-orange-600 hover:bg-orange-50"
                                >
                                  <PauseCircle className="w-4 h-4 mr-3" />
                                  Tạm ngưng (Hold)
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

      {/* Action Modal */}
      {actionModal && (
        <div className="fixed inset-0 bg-neutral-900 bg-opacity-50 z-50 flex items-center justify-center p-4">
          <div className="bg-surface rounded-2xl shadow-xl w-full max-w-md">
            <div className="p-6 border-b border-neutral-200">
              <h2 className="text-xl font-bold text-neutral-900">
                {actionModal.type === 'approve' ? 'Duyệt lệnh sản xuất' : 'Tạm ngưng lệnh sản xuất'}
              </h2>
            </div>
            <form onSubmit={handleActionSubmit} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-2">
                  {actionModal.type === 'approve' ? 'Chữ ký điện tử (Mã PIN/Mật khẩu)' : 'Lý do tạm ngưng'}
                </label>
                <input
                  type={actionModal.type === 'approve' ? 'password' : 'text'}
                  required
                  value={actionInput}
                  onChange={(e) => setActionInput(e.target.value)}
                  className="input"
                  placeholder={actionModal.type === 'approve' ? 'Nhập mã PIN để xác nhận GMP...' : 'Trang thiết bị hỏng, ...'}
                />
              </div>
              <div className="flex justify-end space-x-3 pt-4">
                <button type="button" onClick={() => setActionModal(null)} className="btn-ghost">Hủy</button>
                <button
                  type="submit"
                  disabled={approveMutation.isPending || holdMutation.isPending}
                  className={`px-4 py-2 rounded-lg font-medium text-white ${actionModal.type === 'approve' ? 'bg-primary-600 hover:bg-primary-700' : 'bg-orange-600 hover:bg-orange-700'}`}
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
