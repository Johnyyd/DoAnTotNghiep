using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace GMP_System.Entities;

public partial class RecipeBom
{
    public int BomId { get; set; }

    public int? RecipeId { get; set; }

    public int? MaterialId { get; set; }

    public decimal Quantity { get; set; }

    public int? UomId { get; set; }

    public decimal? WastePercentage { get; set; }

    [NotMapped]
    public string? TechnicalStandard { get; set; }

    public string? Note { get; set; }

    public virtual Material? Material { get; set; }

    [JsonIgnore]
    public virtual Recipe? Recipe { get; set; }

    public virtual UnitOfMeasure? Uom { get; set; }
}
