using GMP_System.Entities;

namespace GMP_System.Interfaces
{
    public interface IUnitOfWork : IDisposable
    {
        // Khai bÃ¡o cÃ¡c báº£ng cáº§n dÃ¹ng
        IGenericRepository<Material> Materials { get; }
        IGenericRepository<Recipe> Recipes { get; }
        IGenericRepository<ProductionOrder> ProductionOrders { get; }
        IGenericRepository<ProductionArea> ProductionAreas { get; }
        IGenericRepository<AppUser> AppUsers { get; }
        IGenericRepository<ProductionBatch> ProductionBatches { get; }
        IGenericRepository<BatchProcessLog> BatchProcessLogs { get; }
        IGenericRepository<InventoryLot> InventoryLots { get; }
        IGenericRepository<MaterialUsage> MaterialUsages { get; }
        IGenericRepository<Equipment> Equipments { get; }
        IGenericRepository<UnitOfMeasure> UnitOfMeasures { get; }
        IGenericRepository<UomConversion> UomConversions { get; }
        IGenericRepository<StepParameter> StepParameters { get; }
        IGenericRepository<BatchProcessParameterValue> BatchProcessParameterValues { get; }
        IGenericRepository<RecipeRouting> RecipeRoutings { get; }
        // HÃ m lÆ°u thay Ä‘á»•i (Commit)
        Task<int> CompleteAsync();
    }
}
