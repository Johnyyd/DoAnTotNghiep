export function formatNumber(value: number | undefined | null, decimals: number = 2): string {
  if (value === undefined || value === null || isNaN(value)) return "0";

  return new Intl.NumberFormat("en-US", {
    useGrouping: false,
    minimumFractionDigits: 0,
    maximumFractionDigits: decimals,
  }).format(value);
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

export function isRecipeLiquid(materialName: string = "", uomName: string = ""): boolean {
  const normalizedMaterialName = normalizeText(materialName);
  const normalizedUomName = normalizeText(uomName);

  return (
    normalizedMaterialName.includes("nuoc") ||
    normalizedMaterialName.includes("dung dich") ||
    normalizedMaterialName.includes("siro") ||
    normalizedUomName.includes("ml") ||
    normalizedUomName === "l" ||
    normalizedUomName.includes("chai") ||
    normalizedUomName.includes("ong")
  );
}

export function formatRecipeBatchSize(batchSize: number, isLiquid: boolean, unitName?: string): string {
  if (unitName) return `${formatNumber(batchSize)} ${unitName}`;

  if (isLiquid) {
    if (batchSize >= 1000 && batchSize % 1000 === 0) return `${formatNumber(batchSize / 1000)} L`;
    return `${formatNumber(batchSize)} ml`;
  }

  if (batchSize >= 1000000 && batchSize % 1000000 === 0) return `${formatNumber(batchSize / 1000000)} kg`;
  if (batchSize >= 1000 && batchSize % 1000 === 0) return `${formatNumber(batchSize / 1000)} g`;
  return `${formatNumber(batchSize)} mg`;
}

function normalizeText(value: string): string {
  return value
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/đ/g, "d")
    .replace(/Đ/g, "D")
    .toLowerCase()
    .trim();
}
