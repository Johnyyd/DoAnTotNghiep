import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { auditApi } from '@/services/api';
import { History, Search } from 'lucide-react';

export default function AuditLogs() {
  const [search, setSearch] = useState('');
  const [actionFilter, setActionFilter] = useState('');

  const { data: logs, isLoading, isError } = useQuery({ queryKey: ['audit-logs'], queryFn: () => auditApi.getAll() });

  const rows = (Array.isArray(logs) ? logs : (logs as any)?.data ?? []).map((m: any) => ({
    logId: m.auditId ?? m.AuditId,
    entityType: m.tableName ?? m.TableName,
    entityId: m.recordId ?? m.RecordId,
    action: m.action ?? m.Action,
    changedBy: m.changedBy ?? m.ChangedBy,
    changedByName: m.changedByNavigation?.fullName ?? m.ChangedByNavigation?.FullName ?? `User ${m.changedBy ?? m.ChangedBy ?? '-'}`,
    changedAt: m.changedDate ?? m.ChangedDate,
    oldValue: m.oldValue ?? m.OldValue,
    newValue: m.newValue ?? m.NewValue,
  }));

  const filtered = rows.filter((log: any) => {
    if (actionFilter && log.action !== actionFilter) return false;
    const t = search.toLowerCase();
    return `${log.entityType} ${log.action} ${log.entityId}`.toLowerCase().includes(t);
  });

  const getActionInfo = (action: string) => {
    switch (action) {
      case 'Create': return { label: 'Tạo mới', classes: 'bg-green-100 text-green-700' };
      case 'Update': return { label: 'Cập nhật', classes: 'bg-blue-100 text-blue-700' };
      case 'Delete': return { label: 'Xóa', classes: 'bg-red-100 text-red-700' };
      case 'Approve': return { label: 'Phê duyệt', classes: 'bg-purple-100 text-purple-700' };
      case 'Complete': return { label: 'Hoàn thành', classes: 'bg-teal-100 text-teal-700' };
      default: return { label: action || '-', classes: 'bg-neutral-100 text-neutral-700' };
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-neutral-900">Nhật ký hệ thống</h1>
        <p className="text-sm text-neutral-500 mt-1">Lưu vết thao tác theo tài khoản thực hiện</p>
      </div>

      <div className="bg-surface border border-neutral-200 rounded-xl overflow-hidden shadow-sm">
        <div className="p-4 border-b border-neutral-200 bg-neutral-50/50 flex flex-col sm:flex-row gap-4 justify-between">
          <div className="relative w-full sm:w-96">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-neutral-400" />
            <input type="text" placeholder="Tìm theo bảng, thao tác, record ID..." value={search} onChange={(e) => setSearch(e.target.value)} className="w-full pl-10 pr-4 py-2 border border-neutral-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500" />
          </div>
          <select className="px-3 py-2 border border-neutral-300 rounded-lg text-sm bg-white" value={actionFilter} onChange={(e) => setActionFilter(e.target.value)}>
            <option value="">Tất cả thao tác</option>
            <option value="Create">Tạo mới</option>
            <option value="Update">Cập nhật</option>
            <option value="Delete">Xóa</option>
            <option value="Approve">Phê duyệt</option>
            <option value="Complete">Hoàn thành</option>
          </select>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-neutral-50 border-b border-neutral-200">
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">ID</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Thời gian</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Tài khoản</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Thao tác</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Bảng</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Record</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Giá trị cũ</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Giá trị mới</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-200">
              {isLoading ? (
                <tr><td colSpan={8} className="py-8 text-center text-neutral-500">Đang tải dữ liệu...</td></tr>
              ) : isError ? (
                <tr><td colSpan={8} className="py-8 text-center text-red-600">Không tải được nhật ký hệ thống.</td></tr>
              ) : filtered.length === 0 ? (
                <tr>
                  <td colSpan={8} className="py-12 text-center text-neutral-500">
                    <History className="w-12 h-12 text-neutral-300 mx-auto mb-3" />
                    <p className="text-lg font-medium text-neutral-900">Chưa có log phù hợp</p>
                  </td>
                </tr>
              ) : (
                filtered.map((log: any) => {
                  const info = getActionInfo(log.action);
                  return (
                    <tr key={log.logId} className="hover:bg-neutral-50 transition-colors">
                      <td className="py-3 px-4 text-sm font-medium">#{log.logId}</td>
                      <td className="py-3 px-4 text-sm text-neutral-500">{log.changedAt ? new Date(log.changedAt).toLocaleString('vi-VN') : '-'}</td>
                      <td className="py-3 px-4 text-sm">{log.changedByName}</td>
                      <td className="py-3 px-4"><span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium ${info.classes}`}>{info.label}</span></td>
                      <td className="py-3 px-4 text-sm">{log.entityType}</td>
                      <td className="py-3 px-4 text-sm">{log.entityId}</td>
                      <td className="py-3 px-4 text-xs font-mono max-w-xs truncate" title={log.oldValue}>{log.oldValue || '-'}</td>
                      <td className="py-3 px-4 text-xs font-mono max-w-xs truncate" title={log.newValue}>{log.newValue || '-'}</td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
