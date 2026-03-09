using System;
using System.Collections.Generic;

namespace GMP_System.Entities;

public partial class MaterialUsage
{
    public long UsageId { get; set; }

    public int? BatchId { get; set; }

    public int? InventoryLotId { get; set; }

    public decimal? PlannedAmount { get; set; }

    public decimal ActualAmount { get; set; }

    public int? DispensedBy { get; set; }

    public DateTime? Timestamp { get; set; }

    public string? Note { get; set; }

    public virtual ProductionBatch? Batch { get; set; }

    public virtual AppUser? DispensedByNavigation { get; set; }

    public virtual InventoryLot? InventoryLot { get; set; }
}
