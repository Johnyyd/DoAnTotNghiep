import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { productionBatchesApi } from '@/services/api';
import { ClipboardList, Search, CheckCircle, Clock, RefreshCw } from 'lucide-react';
import { toast } from 'sonner';

export default function ProductionBatches() {
  const [search, setSearch] = useState('');
  const queryClient = useQueryClient();

  // Fetch ALL batches from the backend
  const { data: response, isLoading } = useQuery({
    queryKey: ['productionBatches'],
    queryFn: () => productionBatchesApi.getAll(),
  });

  // Finish a batch
  const finishMutation = useMutation({
    mutationFn: (batchId: number) => productionBatchesApi.finish(batchId),
    onSuccess: () => {
      toast.success('Đóng mẻ sản xuất thành công!');
      queryClient.invalidateQueries({ queryKey: ['productionBatches'] });
    },
    onError: (err: any) => {
      toast.error(err?.response?.data?.message || 'Không thể đóng mẻ. Vui lòng thử lại.');
    },
  });

  // Backend returns camelCase JSON from ASP.NET Core
  const batches: any[] = Array.isArray(response)
    ? response
    : (response as any)?.data ?? [];

  const filtered = batches.filter((b) =>
    (b.batchNumber ?? '').toLowerCase().includes(search.toLowerCase())
  );

  const getStatusInfo = (status: string) => {
    switch (status) {
      case 'In-Process':
        return { label: 'Đang sản xuất', badgeClass: 'badge-info' };
      case 'Completed':
        return { label: 'Hoàn thành', badgeClass: 'badge-success' };
      case 'On-Hold':
        return { label: 'Tạm dừng', badgeClass: 'badge-warning' };
      default:
        return { label: status || 'Unknown', badgeClass: 'bg-gray-100 text-gray-800' };
    }
  };

  const fmt = (dateString?: string) => {
    if (!dateString) return '-';
    try { return new Date(dateString).toLocaleString('vi-VN'); } catch { return '-'; }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900">Mẻ Sản Xuất</h1>
          <p className="text-neutral-500 mt-1">Quản lý và thực thi các mẻ sản xuất</p>
        </div>
      </div>

      <div className="card">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-neutral-400" />
            <input
              type="text"
              placeholder="Tìm kiếm theo mã mẻ..."
              value={search}
              onChange={(e: React.ChangeEvent<HTMLInputElement>) => setSearch(e.target.value)}
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
                  <th>Mã Mẻ</th>
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
                        <code className="text-xs bg-neutral-100 px-2 py-1 rounded font-mono text-primary-600">
                          {batch.batchNumber}
                        </code>
                      </td>
                      <td className="text-sm text-neutral-600">
                        {batch.order?.orderCode ?? `#${batch.orderId}`}
                      </td>
                      <td className="text-sm text-neutral-700">
                        {batch.order?.recipe?.material?.materialName ?? '-'}
                      </td>
                      <td>
                        <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${statusInfo.badgeClass}`}>
                          {statusInfo.label}
                        </span>
                      </td>
                      <td className="text-neutral-600 text-sm">{fmt(batch.manufactureDate)}</td>
                      <td className="text-neutral-600 text-sm">{fmt(batch.endTime)}</td>
                      <td className="text-right">
                        <div className="flex items-center justify-end space-x-2">
                          {batch.status === 'In-Process' && (
                            <button
                              onClick={() => finishMutation.mutate(batch.batchId)}
                              disabled={finishMutation.isPending}
                              className="btn-ghost text-green-600 text-sm flex items-center"
                            >
                              {finishMutation.isPending
                                ? <RefreshCw className="w-4 h-4 mr-1 animate-spin" />
                                : <CheckCircle className="w-4 h-4 mr-1" />}
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
    </div>
  );
}
