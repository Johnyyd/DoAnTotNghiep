using GMP_System.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using System.Security.Claims;
using System.Text.Json;

namespace GMP_System.Interceptors
{
    public class AuditLogInterceptor : SaveChangesInterceptor
    {
        private readonly IHttpContextAccessor? _httpContextAccessor;

        // Constructor cho DI (khi được inject qua IHttpContextAccessor)
        public AuditLogInterceptor(IHttpContextAccessor httpContextAccessor)
        {
            _httpContextAccessor = httpContextAccessor;
        }

        // Constructor mặc định (dùng khi khởi tạo trực tiếp — fallback)
        public AuditLogInterceptor()
        {
            _httpContextAccessor = null;
        }

        public override async ValueTask<InterceptionResult<int>> SavingChangesAsync(
            DbContextEventData eventData,
            InterceptionResult<int> result,
            CancellationToken cancellationToken = default)
        {
            var context = eventData.Context;
            if (context == null) return await base.SavingChangesAsync(eventData, result, cancellationToken);

            // Lấy UserId từ JWT Claims (nếu có HTTP context)
            int? currentUserId = null;
            var userIdClaim = _httpContextAccessor?.HttpContext?.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (int.TryParse(userIdClaim, out var parsedId))
                currentUserId = parsedId;

            var auditEntries = new List<SystemAuditLog>();

            foreach (var entry in context.ChangeTracker.Entries())
            {
                if (entry.Entity is SystemAuditLog || entry.State == EntityState.Detached || entry.State == EntityState.Unchanged)
                    continue;

                string actionName = entry.State switch
                {
                    EntityState.Added => "INSERT",
                    EntityState.Modified => "UPDATE",
                    EntityState.Deleted => "DELETE",
                    _ => "UNKNOWN"
                };

                var auditEntry = new SystemAuditLog
                {
                    TableName = entry.Entity.GetType().Name,
                    Action = actionName,
                    ChangedDate = DateTime.Now,
                    ChangedBy = currentUserId // null nếu không có token (seed time)
                };

                var oldValues = new Dictionary<string, object?>();
                var newValues = new Dictionary<string, object?>();

                foreach (var property in entry.Properties)
                {
                    string propertyName = property.Metadata.Name;
                    if (property.IsTemporary) continue;

                    // Không log PasswordHash vào audit trail
                    if (propertyName == "PasswordHash") continue;

                    if (property.Metadata.IsPrimaryKey())
                    {
                        auditEntry.RecordId = property.CurrentValue?.ToString();
                    }

                    switch (entry.State)
                    {
                        case EntityState.Added:
                            newValues[propertyName] = property.CurrentValue;
                            break;
                        case EntityState.Deleted:
                            oldValues[propertyName] = property.OriginalValue;
                            break;
                        case EntityState.Modified:
                            if (property.IsModified)
                            {
                                oldValues[propertyName] = property.OriginalValue;
                                newValues[propertyName] = property.CurrentValue;
                            }
                            break;
                    }
                }

                if (oldValues.Count > 0) auditEntry.OldValue = JsonSerializer.Serialize(oldValues);
                if (newValues.Count > 0) auditEntry.NewValue = JsonSerializer.Serialize(newValues);

                auditEntries.Add(auditEntry);
            }

            if (auditEntries.Count > 0)
            {
                await context.AddRangeAsync(auditEntries);
            }

            return await base.SavingChangesAsync(eventData, result, cancellationToken);
        }
    }
}