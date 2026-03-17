import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { productionOrdersApi } from '@/services/api';
import { ProductionOrder } from '@/types';
import { Search, Plus, ClipboardList, Clock, AlertCircle, CheckCircle, Eye, MoreVertical } from 'lucide-react';

export default function ProductionOrders() {
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');

  const { data: ordersData, isLoading } = useQuery({
    queryKey: ['productionOrders'],
    queryFn: () => productionOrdersApi.getAll(),
  });

  const ordersList = Array.isArray(ordersData) ? ordersData : (ordersData as any)?.data || [];

  const normalizedOrders: ProductionOrder[] = ordersList.map((o: any) => ({
    orderId: o.OrderId,
    orderCode: o.OrderCode,
    recipeId: o.RecipeId,
    plannedQuantity: o.PlannedQuantity,
    actualQuantity: o.ActualQuantity,
    status: o.Status,
    plannedStartDate: o.PlannedStartDate,
    plannedEndDate: o.PlannedEndDate,
    actualStartDate: o.ActualStartDate,
    actualEndDate: o.ActualEndDate,
    approvedBy: o.ApprovedBy,
    approvedDate: o.ApprovedDate,
    recipe: o.Recipe,
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
      return 'Invalid Date';
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Lệnh Sản Xuất (Production Orders)</h1>
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
              onChange={(e) => setSearch(e.target.value)}
              className="input pl-10"
            />
          </div>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
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
                  <th>Công thức (Recipe)</th>
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
                        {order.recipeName || `Recipe #${order.recipeId}`}
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
                        <div className="flex items-center justify-end space-x-2">
                          <button className="btn-ghost flex items-center px-2 py-1 text-sm text-neutral-600 hover:text-primary-600">
                            <Eye className="w-4 h-4 mr-1" /> Xem
                          </button>
                          <button className="p-1 rounded hover:bg-neutral-100">
                            <MoreVertical className="w-4 h-4 text-neutral-500" />
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
    </div>
  );
}
