export function formatNumber(value: number | undefined | null, decimals: number = 2): string {
  if (value === undefined || value === null || isNaN(value)) return "0";
  const str = new Intl.NumberFormat("en-US", {
    minimumFractionDigits: 0,
    maximumFractionDigits: decimals,
  }).format(value);
  return str.replace(/,/g, " ");
}

export function formatDate(date: string | Date | undefined | null): string {
  if (!date) return "-";
  try {
    const d = new Date(date);
    if (isNaN(d.getTime())) return "-";
    return new Intl.DateTimeFormat("vi-VN", {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    }).format(d);
  } catch {
    return "-";
  }
}

export function isRecipeLiquid(materialName: string = '', uomName: string = ''): boolean {
  const n = materialName.toLowerCase();
  const u = uomName.toLowerCase();
  return n.includes('nước') || n.includes('dung dịch') || n.includes('siro') || n.includes('sirô') ||
    u.includes('ml') || u.includes('l') || u.includes('chai') || u.includes('ống');
}

export function formatRecipeBatchSize(batchSize: number, isLiquid: boolean): string {
  if (isLiquid) {
    if (batchSize >= 1000 && batchSize % 1000 === 0) return `${formatNumber(batchSize / 1000)} L`;
    return `${formatNumber(batchSize)} ml`;
  } else {
    if (batchSize >= 1000000 && batchSize % 1000000 === 0) return `${formatNumber(batchSize / 1000000)} kg`;
    if (batchSize >= 1000 && batchSize % 1000 === 0) return `${formatNumber(batchSize / 1000)} g`;
    return `${formatNumber(batchSize)} mg`;
  }
}
