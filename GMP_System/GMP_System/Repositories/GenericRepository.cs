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

            // Giả định PK tên là 'Id' hoặc dùng Reflection/EF Metadata để tìm
            // Để đơn giản và chính xác nhất cho project này, ta sẽ dùng Lambda:
            // return await query.FirstOrDefaultAsync(e => EF.Property<int>(e, "BatchId") == id);
            // Tuy nhiên, vì T là generic, ta dùng Query() mang tính linh hoạt hơn ở Controller.
            // Ở đây sửa lại logic cơ bản:
            var parameter = Expression.Parameter(typeof(T), "e");
            // Thử các tên PK phổ biến trong project: UserId, MaterialId, BatchId... 
            // Hoặc ép người dùng dùng .Query() nếu phức tạp.
            // Tạm thời fix cứng logic execute query:
            return await query.FirstOrDefaultAsync(CreateIdPredicate(id));
        }

        // Helper tạo predicate lọc theo ID (Giả định ID là property đầu tiên hoặc có tên chứa 'Id')
        private Expression<Func<T, bool>> CreateIdPredicate(int id)
        {
            var parameter = Expression.Parameter(typeof(T), "e");
            var propertyName = typeof(T).Name + "Id"; // Ví dụ: BatchId, MaterialId
            // Fallback nếu không khớp (ví dụ AppUser -> UserId)
            if (typeof(T).Name == "AppUser") propertyName = "UserId";
            
            var property = Expression.Property(parameter, propertyName);
            var equality = Expression.Equal(property, Expression.Constant(id));
            return Expression.Lambda<Func<T, bool>>(equality, parameter);
        }

        public async Task<T?> GetSingleWithIncludeAsync(Expression<Func<T, bool>> predicate, params Expression<Func<T, object>>[] includes)
        {
            IQueryable<T> query = _dbSet;
            foreach (var include in includes)
                query = query.Include(include);
            return await query.FirstOrDefaultAsync(predicate);
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