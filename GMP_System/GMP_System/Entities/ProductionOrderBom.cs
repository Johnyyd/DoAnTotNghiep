using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace GMP_System.Entities;

public partial class ProductionOrderBom
{
    public int OrderBomId { get; set; }

    public int? OrderId { get; set; }

    public int? MaterialId { get; set; }

    public decimal RequiredQuantity { get; set; }

    public int? UomId { get; set; }

    public decimal? WastePercentage { get; set; }

    public string? Note { get; set; }

    public virtual Material? Material { get; set; }

    [JsonIgnore]
    public virtual ProductionOrder? Order { get; set; }

    public virtual UnitOfMeasure? Uom { get; set; }
}
