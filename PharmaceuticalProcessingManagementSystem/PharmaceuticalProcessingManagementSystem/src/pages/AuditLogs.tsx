import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { auditApi } from '@/services/api';
import { SystemAuditLog } from '@/types';
import { Search, History, Filter } from 'lucide-react';

export default function AuditLogs() {
  const [search, setSearch] = useState('');

  const { data: logs, isLoading } = useQuery({
    queryKey: ['audit-logs'],
    queryFn: () => auditApi.getAll(),
  });

  const logsData = Array.isArray(logs) ? logs : (logs as any)?.data ?? [];

  const normalizedLogs: SystemAuditLog[] = logsData.map((m: any) => ({
    logId: m.AuditId || m.logId,
    entityType: m.TableName || m.entityType,
    entityId: typeof m.RecordId === 'string' ? parseInt(m.RecordId) : (m.RecordId || m.entityId),
    action: m.Action || m.action,
    changedBy: m.ChangedBy || m.changedBy,
    changedByName: m.ChangedByNavigation?.UserName || m.changedByName || `User ${m.ChangedBy || m.changedBy}`,
    changedAt: m.ChangedDate || m.changedAt,
    oldValue: m.OldValue || m.oldValue,
    newValue: m.NewValue || m.newValue,
  }));

  const filteredLogs = normalizedLogs.filter((log: SystemAuditLog) => {
    if (!log) return false;
    const type = log.entityType?.toLowerCase() || '';
    const action = log.action?.toLowerCase() || '';
    const term = search.toLowerCase();
    return type.includes(term) || action.includes(term) || log.entityId?.toString().includes(term);
  });

  const getActionInfo = (action: string) => {
    switch (action) {
      case 'Create':
        return { label: 'Tạo mới', classes: 'bg-green-100 text-green-700' };
      case 'Update':
        return { label: 'Cập nhật', classes: 'bg-blue-100 text-blue-700' };
      case 'Delete':
        return { label: 'Xóa', classes: 'bg-red-100 text-red-700' };
      case 'Approve':
        return { label: 'Phê duyệt', classes: 'bg-purple-100 text-purple-700' };
      case 'Complete':
        return { label: 'Hoàn thành', classes: 'bg-teal-100 text-teal-700' };
      default:
        return { label: action, classes: 'bg-neutral-100 text-neutral-700' };
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center space-y-4 sm:space-y-0">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900">Nhật Ký Hệ Thống</h1>
          <p className="text-sm text-neutral-500 mt-1">
            Theo dõi thao tác (Audit Trail) của người dùng trên toàn hệ thống.
          </p>
        </div>
      </div>

      <div className="bg-surface border border-neutral-200 rounded-xl overflow-hidden shadow-sm">
        <div className="p-4 border-b border-neutral-200 bg-neutral-50/50 flex flex-col sm:flex-row gap-4 justify-between">
          <div className="relative w-full sm:w-96">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-neutral-400" />
            <input
              type="text"
              placeholder="Tìm kiếm theo bảng dữ liệu, thao tác..."
              value={search}
              onChange={(e: React.ChangeEvent<HTMLInputElement>) => setSearch(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-neutral-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500 transition-shadow"
            />
          </div>
          <div className="flex gap-2">
            <button className="btn-secondary">
              <Filter className="w-4 h-4 mr-2" />
              Lọc
            </button>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-neutral-50 border-b border-neutral-200">
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">ID Lịch sử</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Thời gian</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Người thực hiện</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Thao tác</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Bảng dữ liệu (Entity)</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Record ID</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Giá trị cũ</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Giá trị mới</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-200">
              {isLoading ? (
                <tr>
                  <td colSpan={8} className="py-8 text-center text-neutral-500">
                    <div className="flex items-center justify-center space-x-2">
                      <div className="w-5 h-5 border-2 border-primary-500 border-t-transparent rounded-full animate-spin" />
                      <span>Đang tải dữ liệu...</span>
                    </div>
                  </td>
                </tr>
              ) : filteredLogs.length === 0 ? (
                <tr>
                  <td colSpan={8} className="py-12 text-center text-neutral-500">
                    <History className="w-12 h-12 text-neutral-300 mx-auto mb-3" />
                    <p className="text-lg font-medium text-neutral-900">Không tìm thấy nhật ký</p>
                    <p className="text-sm">Chưa có thao tác nào hoặc không khớp với tìm kiếm.</p>
                  </td>
                </tr>
              ) : (
                filteredLogs.map((log: SystemAuditLog) => (
                  <tr key={log.logId} className="hover:bg-neutral-50 transition-colors">
                    <td className="py-3 px-4 text-sm text-neutral-900 font-medium">#{log.logId}</td>
                    <td className="py-3 px-4 text-sm text-neutral-500">
                      {log.changedAt ? new Date(log.changedAt).toLocaleString('vi-VN') : '-'}
                    </td>
                    <td className="py-3 px-4 text-sm text-neutral-900">{log.changedByName}</td>
                    <td className="py-3 px-4">
                      {(() => {
                        const info = getActionInfo(log.action);
                        return (
                          <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium ${info.classes}`}>
                            {info.label}
                          </span>
                        );
                      })()}
                    </td>
                    <td className="py-3 px-4 text-sm text-neutral-900">{log.entityType}</td>
                    <td className="py-3 px-4 text-sm text-neutral-900">{log.entityId}</td>
                    <td className="py-3 px-4 text-xs font-mono text-neutral-500 max-w-xs truncate" title={log.oldValue}>
                      {log.oldValue || '-'}
                    </td>
                    <td className="py-3 px-4 text-xs font-mono text-neutral-900 max-w-xs truncate" title={log.newValue}>
                      {log.newValue || '-'}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
