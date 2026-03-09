using System;
using System.Collections.Generic;

namespace GMP_System.Entities;

public partial class AppUser
{
    public int UserId { get; set; }

    public string Username { get; set; } = null!;

    public string FullName { get; set; } = null!;

    public string? Role { get; set; }

    public bool? IsActive { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual ICollection<MaterialUsage> MaterialUsages { get; set; } = new List<MaterialUsage>();

    public virtual ICollection<ProductionOrder> ProductionOrders { get; set; } = new List<ProductionOrder>();

    public virtual ICollection<Recipe> Recipes { get; set; } = new List<Recipe>();

    public virtual ICollection<SystemAuditLog> SystemAuditLogs { get; set; } = new List<SystemAuditLog>();
}
