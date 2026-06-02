using System;
using System.Collections.Generic;

namespace GMP_System.Entities;

public partial class InventoryLot
{
    public int LotId { get; set; }

    public int? MaterialId { get; set; }

    public string LotNumber { get; set; } = null!;

    public decimal QuantityCurrent { get; set; }

    public DateTime? ManufactureDate { get; set; }

    public DateTime ExpiryDate { get; set; }


    public string? SupplierLotNumber { get; set; }

    public string? SupplierName { get; set; }

    public string? ContainerType { get; set; }

    public int? ContainerCount { get; set; }

    public string? QcStatus { get; set; }

    public string? CoaFilePath { get; set; }

    public int? ReleasedBy { get; set; }

    public DateTime? ReleasedAt { get; set; }

    public string? RejectedReason { get; set; }

    public int? LocationId { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual Material? Material { get; set; }

    public virtual StorageLocation? Location { get; set; }

    public virtual AppUser? ReleasedByNavigation { get; set; }

    public virtual ICollection<MaterialUsage> MaterialUsages { get; set; } = new List<MaterialUsage>();
}
