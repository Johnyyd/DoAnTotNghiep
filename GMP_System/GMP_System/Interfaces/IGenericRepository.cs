using System.Linq.Expressions;

namespace GMP_System.Interfaces
{
    public interface IGenericRepository<T> where T : class
    {
        Task<IEnumerable<T>> GetAllAsync();
        Task<T?> GetByIdAsync(int id);
        Task AddAsync(T entity);
        void Update(T entity);
        void Remove(T entity);

        // Overloads hỗ trợ eager loading (.Include)
        Task<IEnumerable<T>> GetAllWithIncludeAsync(params Expression<Func<T, object>>[] includes);
        Task<T?> GetByIdWithIncludeAsync(int id, params Expression<Func<T, object>>[] includes);
        IQueryable<T> Query();
    }
}