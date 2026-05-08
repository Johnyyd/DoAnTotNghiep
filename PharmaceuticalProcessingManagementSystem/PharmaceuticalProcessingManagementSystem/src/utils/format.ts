/**
 * Formats a number for display in the GMP system.
 * - Thousands separator: space ( )
 * - Decimal separator: comma (,)
 * @param value The number to format
 * @param decimals Number of decimal places (default: 2)
 */
export function formatNumber(value: number | string | undefined | null, decimals: number = 2): string {
  if (value === undefined || value === null) return '0';
  const num = typeof value === 'string' ? parseFloat(value) : value;
  if (isNaN(num)) return '0';

  // Use Intl.NumberFormat for robust formatting
  // We use 'fr-FR' or similar because it uses space for thousands and comma for decimal
  return new Intl.NumberFormat('fr-FR', {
    minimumFractionDigits: 0,
    maximumFractionDigits: decimals,
  }).format(num).replace(/\u00a0/g, ' '); // Replace non-breaking space with regular space
}

/**
 * Formats a date string to DD/MM/YYYY
 */
export function formatDate(dateStr: string | undefined | null): string {
  if (!dateStr) return '-';
  const date = new Date(dateStr);
  if (isNaN(date.getTime())) return '-';
  return date.toLocaleDateString('vi-VN');
}
