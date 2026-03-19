using GMP_System.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using System.Text.Json;

namespace GMP_System.Interceptors
{
    public class AuditLogInterceptor : SaveChangesInterceptor
    {
        public override async ValueTask<InterceptionResult<int>> SavingChangesAsync(
            DbContextEventData eventData,
            InterceptionResult<int> result,
            CancellationToken cancellationToken = default)
        {
            var context = eventData.Context;
            if (context == null) return await base.SavingChangesAsync(eventData, result, cancellationToken);

            var auditEntries = new List<SystemAuditLog>();

            // 1. Duyệt qua tất cả các thay đổi đang chờ lưu
            foreach (var entry in context.ChangeTracker.Entries())
            {
                // Bỏ qua chính bảng AuditLog để tránh vòng lặp vô tận
                if (entry.Entity is SystemAuditLog || entry.State == EntityState.Detached || entry.State == EntityState.Unchanged)
                    continue;

                string actionName = entry.State switch
                {
                    EntityState.Added => "INSERT",    // Added -> INSERT
                    EntityState.Modified => "UPDATE", // Modified -> UPDATE
                    EntityState.Deleted => "DELETE",  // Deleted -> DELETE
                    _ => "UNKNOWN"
                };

                var auditEntry = new SystemAuditLog
                {
                    TableName = entry.Entity.GetType().Name, // Tên bảng (VD: Material)
                    Action = actionName, // Added, Modified, Deleted
                    ChangedDate = DateTime.Now,
                    ChangedBy = 1 // Tạm thời để cứng là Admin (Sau này lấy từ Token User)
                };

                var oldValues = new Dictionary<string, object?>();
                var newValues = new Dictionary<string, object?>();

                // 2. Lấy giá trị từng cột
                foreach (var property in entry.Properties)
                {
                    string propertyName = property.Metadata.Name;
                    if (property.IsTemporary) continue; // Bỏ qua các giá trị tạm

                    // Lấy Primary Key (RecordID)
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

                // 3. Chuyển sang JSON để lưu
                // Chỉ lưu nếu có thay đổi
                if (oldValues.Count > 0) auditEntry.OldValue = JsonSerializer.Serialize(oldValues);
                if (newValues.Count > 0) auditEntry.NewValue = JsonSerializer.Serialize(newValues);

                auditEntries.Add(auditEntry);
            }

            // 4. Chèn Audit Log vào Database (Ngay trong Transaction hiện tại)
            if (auditEntries.Count > 0)
            {
                await context.AddRangeAsync(auditEntries);
            }

            return await base.SavingChangesAsync(eventData, result, cancellationToken);
        }
    }
}