using System;
using System.Collections.Generic;

namespace GMP_System.Entities;

public partial class InventoryLot
{
    public int LotId { get; set; }

    public int? MaterialId { get; set; }

    public string LotNumber { get; set; } = null!;

    public decimal Quantity { get; set; }

    public DateTime? ManufactureDate { get; set; }

    public DateTime ExpiryDate { get; set; }

    public string? Status { get; set; }

    public string? SupplierName { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual Material? Material { get; set; }

    public virtual ICollection<MaterialUsage> MaterialUsages { get; set; } = new List<MaterialUsage>();
}
