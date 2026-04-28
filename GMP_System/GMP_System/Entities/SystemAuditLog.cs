using System;
using System.Collections.Generic;

namespace GMP_System.Entities;

public partial class SystemAuditLog
{
    public long AuditId { get; set; }

    public string? TableName { get; set; }

    public string? RecordId { get; set; }

    public string? Action { get; set; }

    public string? OldValue { get; set; }

    public string? NewValue { get; set; }

    public int? ChangedBy { get; set; }

    public DateTime? ChangedDate { get; set; }

    public virtual AppUser? ChangedByNavigation { get; set; }
}
