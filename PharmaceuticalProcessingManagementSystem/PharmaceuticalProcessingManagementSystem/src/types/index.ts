// Types for GMP-WHO System

export interface User {
  userId: number;
  username: string;
  fullName: string;
  role: 'Admin' | 'QualityControl' | 'Operator' | 'Manager';
  isActive: boolean;
  createdAt?: string;
}

export interface Material {
  materialId: number;
  materialCode: string;
  materialName: string;
  type: 'RawMaterial' | 'Packaging' | 'FinishedGood' | 'Intermediate';
  baseUomId: number;
  baseUomName?: string;
  description?: string;
  isActive: boolean;
  createdAt: string;
}

export interface MaterialBatch {
  batchId: number;
  batchNumber: string;
  materialId: number;
  materialCode?: string;
  materialName?: string;
  quantity: number;
  unit: string;
  manufactureDate: string;
  expiryDate: string;
  qcStatus: 'Pending' | 'Passed' | 'Failed';
  qcDate?: string;
  qcBy?: number;
}

export interface UnitOfMeasure {
  uomId: number;
  uomName: string;
  description?: string;
}

export interface Recipe {
  recipeId: number;
  recipeCode: string;
  recipeName: string;
  version: string;
  versionNumber?: number; // Added from API
  batchSize?: number; // Added from API
  status: 'Draft' | 'Approved' | 'InProcess' | 'Hold' | 'Completed' | 'Deprecated';
  approvedBy?: number;
  approvedDate?: string;
  createdAt: string;
  effectiveDate?: string;
  note?: string;
  materialId: number;
  material?: Material;
  recipeBoms?: RecipeBOM[];
  recipeRoutings?: RecipeRouting[];
  productionOrders?: ProductionOrder[];
}

export interface RecipeBOM {
  bomId: number;
  recipeId: number;
  materialId: number;
  materialCode?: string;
  materialName?: string;
  quantity: number;
  unit: string;
  tolerancePercent: number;
  parentItemId?: number;
  children?: RecipeBOM[];
}

export interface RecipeRouting {
  routingId: number;
  recipeId?: number;
  orderId?: number;
  stepNumber: number;
  stepName: string;
  description?: string;
  estimatedTimeMinutes?: number;
  defaultEquipmentId?: number;
  numberOfRouting?: number;
  stepParameters?: StepParameter[];
}

export interface StepParameter {
  parameterId: number;
  routingId?: number;
  parameterName: string;
  unit?: string;
  minValue?: number;
  maxValue?: number;
  isCritical?: boolean;
  note?: string;
}

export interface ProductionOrder {
  orderId: number;
  orderCode: string;
  productId: number;
  productName?: string;
  plannedQuantity: number;
  actualQuantity?: number;
  plannedStartDate: string;
  plannedEndDate: string;
  actualStartDate?: string;
  actualEndDate?: string;
  status: 'Draft' | 'Approved' | 'InProcess' | 'Hold' | 'Completed';
  recipeId: number;
  recipeCode?: string;
  recipeName?: string;
  snapshotRecipe?: string; // JSON string of frozen recipe
  createdBy: number;
  createdByName?: string;
  createdAt: string;
  approvedBy?: number;
  approvedDate?: string;
  approvedSignature?: string;
}

export interface ProductionBatch {
  batchId: number;
  batchNumber: string;
  orderId: number;
  orderCode?: string;
  plannedQuantity: number;
  actualQuantity?: number;
  actualStartDate?: string;
  actualEndDate?: string;
  operatorId?: number;
  operatorName?: string;
  qcStatus: 'Pending' | 'Passed' | 'Failed';
}

export interface BatchProcessLog {
  logId: number;
  batchId: number;
  stepId: number;
  stepName?: string;
  startTime: string;
  endTime?: string;
  operatorId?: number;
  operatorName?: string;
  actualQuantity?: number;
  notes?: string;
  qcResult?: 'Pass' | 'Fail';
  qcSignature?: string;
}

export interface SystemAuditLog {
  logId: number;
  entityType: string;
  entityId: number;
  action: 'Create' | 'Update' | 'Delete' | 'Approve' | 'Complete';
  changedBy: number;
  changedByName?: string;
  changedAt: string;
  oldValue?: string;
  newValue?: string;
  reason?: string;
  ipAddress?: string;
}

export interface ApiResponse<T> {
  success: boolean;
  message?: string;
  data?: T;
  error?: string;
}

export interface PaginationParams {
  page: number;
  pageSize: number;
}

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

// State transition validation
export const ProductionOrderStates = [
  'Draft',
  'Approved',
  'InProcess',
  'Hold',
  'Completed'
] as const;

export type ProductionOrderState = (typeof ProductionOrderStates)[number];

export const allowedTransitions: Record<string, string[]> = {
  Draft: ['Approved'],
  Approved: ['InProcess', 'Hold'],
  InProcess: ['Hold', 'Completed'],
  Hold: ['InProcess', 'Completed'],
  Completed: []
};
