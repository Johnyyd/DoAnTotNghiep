using GMP_System.Entities;
using GMP_System.Interfaces;
using System.Security.Cryptography;

namespace GMP_System.Repositories
{
    public class UnitOfWork : IUnitOfWork
    {
        private readonly GmpContext _context;

        public UnitOfWork(GmpContext context)
        {
            _context = context;
            // Khởi tạo các Repository con
            Materials = new GenericRepository<Material>(_context);
            Recipes = new GenericRepository<Recipe>(_context);
            ProductionOrders = new GenericRepository<ProductionOrder>(_context);
            AppUsers = new GenericRepository<AppUser>(_context);
            ProductionBatches = new GenericRepository<ProductionBatch>(_context);
            BatchProcessLogs = new GenericRepository<BatchProcessLog>(_context);
            InventoryLots = new GenericRepository<InventoryLot>(_context);
            MaterialUsages = new GenericRepository<MaterialUsage>(_context);
            SystemAuditLogs = new GenericRepository<SystemAuditLog>(_context);
        }

        public IGenericRepository<Material> Materials { get; private set; }
        public IGenericRepository<Recipe> Recipes { get; private set; }
        public IGenericRepository<ProductionOrder> ProductionOrders { get; private set; }
        public IGenericRepository<AppUser> AppUsers { get; private set; }
        public IGenericRepository<ProductionBatch> ProductionBatches { get; private set; }
        public IGenericRepository<BatchProcessLog> BatchProcessLogs { get; private set; }
        public IGenericRepository<InventoryLot> InventoryLots { get; private set; }
        public IGenericRepository<MaterialUsage> MaterialUsages { get; private set; }
        public IGenericRepository<SystemAuditLog> SystemAuditLogs { get; private set; }

        public async Task<int> CompleteAsync()
        {
            return await _context.SaveChangesAsync();
        }

        public void Dispose()
        {
            _context.Dispose();
        }
    }
}
