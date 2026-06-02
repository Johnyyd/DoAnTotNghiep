using System;
using System.Collections.Generic;

namespace GMP_System.Entities;

public partial class StorageLocation
{
    public int LocationId { get; set; }

    public string LocationCode { get; set; } = null!;

    public string LocationName { get; set; } = null!;

    public string? LocationType { get; set; }

    public decimal? TemperatureMin { get; set; }

    public decimal? TemperatureMax { get; set; }

    public decimal? HumidityMin { get; set; }

    public decimal? HumidityMax { get; set; }

    public string? CleanlinessStatus { get; set; }

    public bool? IsQualified { get; set; }

    public string? Note { get; set; }

    public virtual ICollection<InventoryLot> InventoryLots { get; set; } = new List<InventoryLot>();
}
