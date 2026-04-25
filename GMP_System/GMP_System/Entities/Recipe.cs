using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace GMP_System.Entities;

public partial class Recipe
{
    public int RecipeId { get; set; }

    public int? MaterialId { get; set; }

    public int VersionNumber { get; set; }

    public decimal BatchSize { get; set; }

    public string? Status { get; set; }

    public int? ApprovedBy { get; set; }

    public DateTime? ApprovedDate { get; set; }

    public DateTime? CreatedAt { get; set; }

    public DateTime? EffectiveDate { get; set; }

    public string? Note { get; set; }

    public virtual AppUser? ApprovedByNavigation { get; set; }

    public virtual Material? Material { get; set; }

    [JsonIgnore]
    public virtual ICollection<ProductionOrder> ProductionOrders { get; set; } = new List<ProductionOrder>();

    public virtual ICollection<RecipeBom> RecipeBoms { get; set; } = new List<RecipeBom>();

    public virtual ICollection<RecipeRouting> RecipeRoutings { get; set; } = new List<RecipeRouting>();
}
