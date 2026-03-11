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
    Passed: 'bg-green-100 text-green-800',
    Failed: 'bg-red-100 text-red-800',
  };

  const defaultStyle = 'bg-gray-100 text-gray-800';

  return (
    <span
      className={cn(
        'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium',
        styles[status] || defaultStyle,
        className
      )}
    >
      {status}
    </span>
  );
}
