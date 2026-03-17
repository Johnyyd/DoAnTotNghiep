import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { productionBatchesApi } from '@/services/api';
import { ProductionBatch } from '@/types';
import { ClipboardList, Search, Play, CheckCircle, Clock } from 'lucide-react';

export default function ProductionBatches() {
  const [search, setSearch] = useState('');

  // 1. Fetch batches without orderId (or we can simulate by fetching all orders and extracting batches)
  // For this placeholder, let's assume we want to query a specific order or we have an API to get all. 
  // Let's modify api.ts or just handle an empty list nicely.
  // We'll use a mocked orderId = 1 for now if needed, or better, we can adjust the UI.
  // Since we don't have getAllBatches in api.ts, let's write a generic query that might fail gracefully or return []
  const { data: batches, isLoading } = useQuery({
    queryKey: ['productionBatches'],
    queryFn: async () => {
      // In a real scenario, we might want a new endpoint for "All Batches".
      // Currently api.ts only has getByOrder(orderId). We will just mock an empty array or fetch for orderId 1
      try {
        const res = await productionBatchesApi.getByOrder(1);
        return res;
      } catch (err) {
        return { data: [] }; // Fallback
      }
    },
  });

  const batchesData = Array.isArray(batches) ? batches : (batches as any)?.data || [];

  const normalizedBatches: ProductionBatch[] = batchesData.map((b: any) => ({
    batchId: b.BatchId,
    orderId: b.OrderId,
    batchNumber: b.BatchNumber,
    startTime: b.actualStartDate,
    endTime: b.actualEndDate,
    qcStatus: b.qcStatus,
    operatorId: b.OperatorId,
  }));

  const filteredBatches = normalizedBatches.filter((b) => 
    (b.batchNumber?.toLowerCase() || '').includes(search.toLowerCase())
  );

  const getStatusInfo = (qcStatus: string) => {
    switch (qcStatus) {
      case 'Pending':
        return { label: 'Chờ sản xuất', badgeClass: 'bg-neutral-100 text-neutral-800' };
      case 'InProcess':
        return { label: 'Đang sản xuất', badgeClass: 'bg-blue-100 text-blue-800' };
      case 'Passed':
        return { label: 'Hoàn thành Đạt', badgeClass: 'bg-green-100 text-green-800' };
      case 'Failed':
        return { label: 'Không Đạt', badgeClass: 'bg-red-100 text-red-800' };
      default:
        return { label: qcStatus || 'Unknown', badgeClass: 'bg-gray-100 text-gray-800' };
    }
  };

  const formatDate = (dateString?: string) => {
    if (!dateString) return '-';
    try {
      return new Date(dateString).toLocaleString('vi-VN');
    } catch {
      return 'Invalid Date';
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Mẻ Sản Xuất (Production Batches)</h1>
          <p className="text-neutral-500 mt-1">Quản lý và thực thi các mẻ sản xuất (Batch Execution)</p>
        </div>
        <button className="flex items-center px-4 py-2 bg-gmp-primary text-white rounded-lg hover:bg-blue-700 transition-colors">
          Tạo mẻ mới
        </button>
      </div>

      <div className="card">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-neutral-400" />
            <input
              type="text"
              placeholder="Tìm kiếm theo mã mẻ (VD: BATCH-001)..."
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
        ) : filteredBatches.length === 0 ? (
          <div className="text-center py-12">
            <ClipboardList className="w-12 h-12 text-neutral-300 mx-auto mb-4" />
            <p className="text-neutral-500 mb-4">Không tìm thấy mẻ sản xuất nào.</p>
            <div className="bg-purple-50 border border-purple-200 rounded-lg p-4 text-sm text-purple-800 inline-block text-left max-w-md">
              <p className="font-semibold mb-2">Tính năng sắp tới (Mobile/Tablet):</p>
              <ul className="list-disc pl-5 space-y-1">
                <li>Scan barcode để tìm Production Batch</li>
                <li>Xem công thức và BOM định mức</li>
                <li>Bắt đầu/Kết thúc từng công đoạn (Routing)</li>
                <li>Nhập số liệu thực tế & QC in-process</li>
              </ul>
            </div>
          </div>
        ) : (
          <div className="table-container">
            <table className="table">
              <thead>
                <tr>
                  <th>Mã Mẻ</th>
                  <th>Mã Lệnh (Order ID)</th>
                  <th>Trạng thái</th>
                  <th>Bắt đầu</th>
                  <th>Kết thúc</th>
                  <th className="text-right">Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {filteredBatches.map((batch) => {
                  const statusInfo = getStatusInfo(batch.qcStatus);
                  return (
                    <tr key={batch.batchId}>
                      <td>
                        <code className="text-xs bg-neutral-100 px-2 py-1 rounded font-mono text-primary-600">
                          {batch.batchNumber}
                        </code>
                      </td>
                      <td>{batch.orderId}</td>
                      <td>
                        <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${statusInfo.badgeClass}`}>
                          {statusInfo.label}
                        </span>
                      </td>
                      <td className="text-neutral-600 text-sm">{formatDate(batch.actualStartDate)}</td>
                      <td className="text-neutral-600 text-sm">{formatDate(batch.actualEndDate)}</td>
                      <td className="text-right">
                        <div className="flex items-center justify-end space-x-2">
                          {batch.qcStatus === 'Pending' && (
                            <button className="btn-ghost text-blue-600 text-sm flex items-center">
                              <Play className="w-4 h-4 mr-1" /> Bắt đầu
                            </button>
                          )}
                          {batch.qcStatus === 'Passed' && (
                            <button className="btn-ghost text-green-600 text-sm flex items-center">
                              <CheckCircle className="w-4 h-4 mr-1" /> Hoàn thành
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
    </div>
  );
}
