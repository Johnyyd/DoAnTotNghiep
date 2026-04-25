using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace GMP_System.Entities;

public partial class ProductionOrder
{
    public int OrderId { get; set; }

    public string OrderCode { get; set; } = null!;

    public int? RecipeId { get; set; }

    public decimal PlannedQuantity { get; set; }

    public decimal? ActualQuantity { get; set; }

    public DateTime? StartDate { get; set; }

    public DateTime? EndDate { get; set; }

    public string? Status { get; set; }

    public int? CreatedBy { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual AppUser? CreatedByNavigation { get; set; }

    public virtual ICollection<ProductionBatch> ProductionBatches { get; set; } = new List<ProductionBatch>();

    [JsonIgnore]
    public virtual Recipe? Recipe { get; set; }
}
