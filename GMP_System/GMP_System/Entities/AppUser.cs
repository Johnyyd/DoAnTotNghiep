using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace GMP_System.Entities;

public partial class AppUser
{
    public int UserId { get; set; }

    public string Username { get; set; } = null!;

    public string FullName { get; set; } = null!;

    public string? PasswordHash { get; set; }


    public string? Role { get; set; }

    public bool? IsActive { get; set; }

    public DateTime? CreatedAt { get; set; }

    [JsonIgnore]
    public virtual ICollection<MaterialUsage> MaterialUsages { get; set; } = new List<MaterialUsage>();

    [JsonIgnore]
    public virtual ICollection<ProductionOrder> ProductionOrders { get; set; } = new List<ProductionOrder>();

    [JsonIgnore]
    public virtual ICollection<Recipe> Recipes { get; set; } = new List<Recipe>();


    [JsonIgnore]
    public virtual ICollection<BatchProcessLog> BatchProcessLogOperators { get; set; } = new List<BatchProcessLog>();

    [JsonIgnore]
    public virtual ICollection<BatchProcessLog> BatchProcessLogVerifiers { get; set; } = new List<BatchProcessLog>();
}
