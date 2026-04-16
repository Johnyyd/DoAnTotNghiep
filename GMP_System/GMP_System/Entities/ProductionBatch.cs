using System;
using System.Collections.Generic;

namespace GMP_System.Entities;

public partial class ProductionBatch
{
    public int BatchId { get; set; }

    public int? OrderId { get; set; }

    public string BatchNumber { get; set; } = null!;

    public DateTime? ManufactureDate { get; set; }

    public DateTime? EndTime { get; set; }

    public DateTime? ExpiryDate { get; set; }

    public int? CurrentStep { get; set; }

    public string? Status { get; set; }
    public decimal? PlannedQuantity { get; set; }
    public DateTime? CreatedAt { get; set; }

    public virtual ICollection<BatchProcessLog> BatchProcessLogs { get; set; } = new List<BatchProcessLog>();

    public virtual ICollection<MaterialUsage> MaterialUsages { get; set; } = new List<MaterialUsage>();

    public virtual ProductionOrder? Order { get; set; }
}
