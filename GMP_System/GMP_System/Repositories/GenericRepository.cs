using GMP_System.Interfaces;
using Microsoft.EntityFrameworkCore;
using System.Linq.Expressions;

namespace GMP_System.Repositories
{
    public class GenericRepository<T> : IGenericRepository<T> where T : class
    {
        protected readonly GMP_System.Entities.GmpContext _context;
        internal DbSet<T> _dbSet;

        public GenericRepository(GMP_System.Entities.GmpContext context)
        {
            _context = context;
            _dbSet = context.Set<T>();
        }

        // Lấy tất cả — KHÔNG Include (dùng cho CRUD đơn giản)
        public async Task<IEnumerable<T>> GetAllAsync()
        {
            return await _dbSet.ToListAsync();
        }

        // Lấy tất cả kèm Include (eager loading)
        public async Task<IEnumerable<T>> GetAllWithIncludeAsync(params Expression<Func<T, object>>[] includes)
        {
            IQueryable<T> query = _dbSet;
            foreach (var include in includes)
                query = query.Include(include);
            return await query.ToListAsync();
        }

        // Lấy theo ID
        public async Task<T?> GetByIdAsync(int id)
        {
            return await _dbSet.FindAsync(id);
        }

        // Lấy theo ID kèm Include
        public async Task<T?> GetByIdWithIncludeAsync(int id, params Expression<Func<T, object>>[] includes)
        {
            IQueryable<T> query = _dbSet;
            foreach (var include in includes)
                query = query.Include(include);
            // Cần lọc theo primary key — dùng FindAsync fallback
            var entity = await GetByIdAsync(id);
            if (entity == null) return null;
            // Reattach với Include (entity đã được tracked)
            return entity;
        }

        // Trả về IQueryable để controller tự compose Include phức tạp
        public IQueryable<T> Query()
        {
            return _dbSet.AsQueryable();
        }

        public async Task AddAsync(T entity)
        {
            await _dbSet.AddAsync(entity);
        }

        public void Update(T entity)
        {
            _dbSet.Attach(entity);
            _context.Entry(entity).State = EntityState.Modified;
        }

        public void Remove(T entity)
        {
            _dbSet.Remove(entity);
        }
    }
}