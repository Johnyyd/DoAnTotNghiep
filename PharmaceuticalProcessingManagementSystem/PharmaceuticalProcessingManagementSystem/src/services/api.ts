import axios from 'axios';
import type {
  ApiResponse,
  Material,
  MaterialBatch,
  Recipe,
  RecipeBOM,
  RecipeRouting,
  ProductionOrder,
  ProductionBatch,
  BatchProcessLog,
  SystemAuditLog,
  User,
  PaginatedResponse,
  PaginationParams
} from '@/types';

// Use relative URL to leverage nginx proxy in production
// In development, VITE_API_URL should be set to /api or http://localhost:5001
const API_BASE_URL = import.meta.env.VITE_API_URL || '/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add auth token (if implemented)
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('gmp_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor for error handling
api.interceptors.response.use(
  (response) => response.data,
  (error) => {
    if (error.response?.status === 401) {
      // Token expired or invalid — clear storage
      localStorage.removeItem('gmp_token');
      localStorage.removeItem('gmp_user');
    }
    console.error('API Error:', error.response?.data || error.message);
    // Preserve the full error so AuthContext can read error.response.data.message
    return Promise.reject(error);
  }
);

// ============== AUTH & USERS ==============
export const authApi = {
  login: (credentials: { username: string; password: string }) =>
    api.post<ApiResponse<{ user: User; token: string }>>('/auth/login', credentials),
  me: () => api.get<ApiResponse<User>>('/auth/me'),
};

// ============== MATERIALS ==============
export const materialsApi = {
  getAll: () => api.get<ApiResponse<Material[]>>('/materials'),
  getById: (id: number) => api.get<ApiResponse<Material>>(`/materials/${id}`),
  create: (data: Partial<Material>) => api.post<ApiResponse<Material>>('/materials', data),
  update: (id: number, data: Partial<Material>) =>
    api.put<ApiResponse<Material>>(`/materials/${id}`, data),
  delete: (id: number) => api.delete<ApiResponse<null>>(`/materials/${id}`),
  getBatches: (materialId: number) =>
    api.get<ApiResponse<MaterialBatch[]>>(`/materials/${materialId}/batches`),
  createBatch: (data: Partial<MaterialBatch>) =>
    api.post<ApiResponse<MaterialBatch>>('/material-batches', data),
};

// ============== RECIPES & BOM ==============
export const recipesApi = {
  getAll: () => api.get<ApiResponse<Recipe[]>>('/recipes'),
  getById: (id: number) => api.get<ApiResponse<Recipe>>(`/recipes/${id}`),
  create: (data: Partial<Recipe>) => api.post<ApiResponse<Recipe>>('/recipes', data),
  update: (id: number, data: Partial<Recipe>) =>
    api.put<ApiResponse<Recipe>>(`/recipes/${id}`, data),
  delete: (id: number) => api.delete<ApiResponse<null>>(`/recipes/${id}`),
  approve: (id: number, signature: string) =>
    api.post<ApiResponse<Recipe>>(`/recipes/${id}/approve`, { signature }),

  getBOM: (recipeId: number) => api.get<ApiResponse<RecipeBOM[]>>(`/recipes/${recipeId}/bom`),
  addBOMItem: (recipeId: number, data: Partial<RecipeBOM>) =>
    api.post<ApiResponse<RecipeBOM>>(`/recipes/${recipeId}/bom`, data),
  updateBOMItem: (recipeId: number, bomId: number, data: Partial<RecipeBOM>) =>
    api.put<ApiResponse<RecipeBOM>>(`/recipes/${recipeId}/bom/${bomId}`, data),
  removeBOMItem: (recipeId: number, bomId: number) =>
    api.delete<ApiResponse<null>>(`/recipes/${recipeId}/bom/${bomId}`),

  getRouting: (recipeId: number) => api.get<ApiResponse<RecipeRouting[]>>(`/recipes/${recipeId}/routing`),
  addRoutingStep: (recipeId: number, data: Partial<RecipeRouting>) =>
    api.post<ApiResponse<RecipeRouting>>(`/recipes/${recipeId}/routing`, data),
  updateRoutingStep: (recipeId: number, stepId: number, data: Partial<RecipeRouting>) =>
    api.put<ApiResponse<RecipeRouting>>(`/recipes/${recipeId}/routing/${stepId}`, data),
  removeRoutingStep: (recipeId: number, stepId: number) =>
    api.delete<ApiResponse<null>>(`/recipes/${recipeId}/routing/${stepId}`),
};

// ============== PRODUCTION ORDERS ==============
export const productionOrdersApi = {
  getAll: (params?: PaginationParams) =>
    api.get<PaginatedResponse<ProductionOrder>>('/production-orders', { params }),
  getById: (id: number) => api.get<ApiResponse<ProductionOrder>>(`/production-orders/${id}`),
  create: (data: Partial<ProductionOrder>) =>
    api.post<ApiResponse<ProductionOrder>>('/production-orders', data),
  update: (id: number, data: Partial<ProductionOrder>) =>
    api.put<ApiResponse<ProductionOrder>>(`/production-orders/${id}`, data),
  delete: (id: number) => api.delete<ApiResponse<null>>(`/production-orders/${id}`),

  approve: (id: number, signature: string) =>
    api.post<ApiResponse<ProductionOrder>>(`/production-orders/${id}/approve`, { signature }),

  hold: (id: number, reason: string) =>
    api.post<ApiResponse<ProductionOrder>>(`/production-orders/${id}/hold`, { reason }),

  resume: (id: number) =>
    api.post<ApiResponse<ProductionOrder>>(`/production-orders/${id}/resume`),

  complete: (id: number, signature: string) =>
    api.post<ApiResponse<ProductionOrder>>(`/production-orders/${id}/complete`, { signature }),

  calculateMaterials: (recipeId: number, quantity: number) =>
    api.get<ApiResponse<any[]>>(`/production-orders/calculate-materials`, {
      params: { recipeId, quantity },
    }),
};

// ============== PRODUCTION BATCHES ==============
export const productionBatchesApi = {
  getAll: () =>
    api.get<ApiResponse<ProductionBatch[]>>('/production-batches'),
  getByOrder: (orderId: number) =>
    api.get<ApiResponse<ProductionBatch[]>>(`/production-orders/${orderId}/batches`),
  getById: (id: number) =>
    api.get<ApiResponse<ProductionBatch>>(`/production-batches/${id}`),
  create: (data: Partial<ProductionBatch>) =>
    api.post<ApiResponse<ProductionBatch>>('/production-batches', data),
  finish: (batchId: number) =>
    api.post<ApiResponse<ProductionBatch>>(`/production-batches/${batchId}/finish`),

  getProcessLogs: (batchId: number) =>
    api.get<ApiResponse<BatchProcessLog[]>>(`/batchprocesslogs/batch/${batchId}`),

  logStep: (data: Partial<BatchProcessLog>) =>
    api.post<ApiResponse<BatchProcessLog>>('/batchprocesslogs', data),
};

// ============== INVENTORY & TRACEABILITY ==============
export const inventoryApi = {
  getAll: () =>
    api.get<ApiResponse<any[]>>('/inventory-lots'),
  getLots: (params?: { materialId?: number; lotNumber?: string }) =>
    api.get<ApiResponse<any[]>>('/inventory-lots', { params }),
  receive: (data: any) =>
    api.post<ApiResponse<any>>('/inventory-lots', data),
  updateQc: (lotId: number, status: string) =>
    api.post<ApiResponse<any>>(`/inventory-lots/${lotId}/qc`, { status }),

  // Traceability: track finished goods back to raw materials
  traceBackward: (finishedGoodBatchNumber: string) =>
    api.get<ApiResponse<any>>(`/traceability/backward/${finishedGoodBatchNumber}`),

  // Traceability: track raw materials forward to finished goods
  traceForward: (rawMaterialBatchNumber: string) =>
    api.get<ApiResponse<any>>(`/traceability/forward/${rawMaterialBatchNumber}`),
};

export const appUsersApi = {
  getAll: (params?: { role?: string; isActive?: boolean }) =>
    api.get<ApiResponse<any[]>>('/app-users', { params }),
  create: (data: any) => api.post<ApiResponse<any>>('/app-users', data),
  update: (id: number, data: any) => api.put<ApiResponse<any>>(`/app-users/${id}`, data),
  delete: (id: number) => api.delete<ApiResponse<any>>(`/app-users/${id}`),
};

export const equipmentsApi = {
  getAll: (params?: { status?: string; keyword?: string }) =>
    api.get<ApiResponse<any[]>>('/equipments', { params }),
  create: (data: any) => api.post<ApiResponse<any>>('/equipments', data),
  update: (id: number, data: any) => api.put<ApiResponse<any>>(`/equipments/${id}`, data),
  delete: (id: number) => api.delete<ApiResponse<any>>(`/equipments/${id}`),
};

// ============== AUDIT LOGS ==============
export const auditApi = {
  getAll: (params?: { entityType?: string; entityId?: number; limit?: number }) =>
    api.get<ApiResponse<SystemAuditLog[]>>('/audit-logs', { params }),
  getByEntity: (entityType: string, entityId: number) =>
    api.get<ApiResponse<SystemAuditLog[]>>(`/audit-logs/${entityType}/${entityId}`),
};

// ============== HEALTH & SYSTEM ==============
export const systemApi = {
  health: () => api.get<{ status: string; timestamp: string; version?: string }>('/health'),
};

export default api;
