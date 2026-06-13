import { cn } from '@/lib/utils';

interface StatusBadgeProps {
  status: string;
  className?: string;
}

export function StatusBadge({ status, className }: StatusBadgeProps) {
  const styles: Record<string, string> = {
    Draft: 'bg-yellow-100 text-yellow-800',
    Approved: 'bg-blue-100 text-blue-800',
    InProcess: 'bg-purple-100 text-purple-800',
    Hold: 'bg-orange-100 text-orange-800',
    Completed: 'bg-green-100 text-green-800',
    Pending: 'bg-yellow-100 text-yellow-800',
    'Pending Worker': 'bg-gray-100 text-gray-800 border border-gray-200',
    Passed: 'bg-green-100 text-green-800',
    Failed: 'bg-red-100 text-red-800',
  };

  const labels: Record<string, string> = {
    Draft: 'Bản nháp',
    Approved: 'Đã duyệt',
    InProcess: 'Đang sản xuất',
    'Pending Worker': 'Chờ công nhân',
    Hold: 'Tạm dừng',
    Completed: 'Hoàn thành',
    Pending: 'Chờ duyệt',
    PendingQC: 'Chờ duyệt',
    Passed: 'Đạt',
    Failed: 'Không đạt',
  };

  const defaultStyle = 'bg-gray-100 text-gray-800';
  const displayLabel = labels[status] || status;

  return (
    <span
      className={cn(
        'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium',
        styles[status] || defaultStyle,
        className
      )}
    >
      {displayLabel}
    </span>
  );
}
