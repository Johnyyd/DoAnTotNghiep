using GMP_System.Entities;

namespace GMP_System.Interfaces
{
    public interface IUnitOfWork : IDisposable
    {
        // Khai báo các bảng cần dùng
        IGenericRepository<Material> Materials { get; }
        IGenericRepository<Recipe> Recipes { get; }
        IGenericRepository<ProductionOrder> ProductionOrders { get; }
        IGenericRepository<ProductionArea> ProductionAreas { get; }
        IGenericRepository<AppUser> AppUsers { get; }
        IGenericRepository<ProductionBatch> ProductionBatches { get; }
        IGenericRepository<BatchProcessLog> BatchProcessLogs { get; }
        IGenericRepository<InventoryLot> InventoryLots { get; }
        IGenericRepository<MaterialUsage> MaterialUsages { get; }
        IGenericRepository<SystemAuditLog> SystemAuditLogs { get; }
        IGenericRepository<Equipment> Equipments { get; }
        IGenericRepository<UnitOfMeasure> UnitOfMeasures { get; }
        IGenericRepository<UomConversion> UomConversions { get; }
        IGenericRepository<StepParameter> StepParameters { get; }
        IGenericRepository<BatchProcessParameterValue> BatchProcessParameterValues { get; }
        IGenericRepository<RecipeRouting> RecipeRoutings { get; }
        // Hàm lưu thay đổi (Commit)
        Task<int> CompleteAsync();
    }
}
