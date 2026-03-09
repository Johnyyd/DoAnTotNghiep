using GMP_System.Entities;

namespace GMP_System.Interfaces
{
    public interface IUnitOfWork : IDisposable
    {
        // Khai báo các bảng cần dùng
        IGenericRepository<Material> Materials { get; }
        IGenericRepository<Recipe> Recipes { get; }
        IGenericRepository<ProductionOrder> ProductionOrders { get; }
        IGenericRepository<AppUser> AppUsers { get; }
        IGenericRepository<ProductionBatch> ProductionBatches { get; }
        IGenericRepository<BatchProcessLog> BatchProcessLogs { get; }
        IGenericRepository<InventoryLot> InventoryLots { get; }
        IGenericRepository<MaterialUsage> MaterialUsages { get; }
        IGenericRepository<SystemAuditLog> SystemAuditLogs { get; }
        // Hàm lưu thay đổi (Commit)
        Task<int> CompleteAsync();
    }
}