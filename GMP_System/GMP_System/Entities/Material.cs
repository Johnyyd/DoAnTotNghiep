using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace GMP_System.Entities;

public partial class Material
{
    public int MaterialId { get; set; }

    public string MaterialCode { get; set; } = null!;

    public string MaterialName { get; set; } = null!;

    public string? Type { get; set; }

    public int? BaseUomId { get; set; }

    public bool? IsActive { get; set; }

    public string? TechnicalSpecification { get; set; }

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual UnitOfMeasure? BaseUom { get; set; }

    [JsonIgnore]
    public virtual ICollection<InventoryLot> InventoryLots { get; set; } = new List<InventoryLot>();

    [JsonIgnore]
    public virtual ICollection<RecipeBom> RecipeBoms { get; set; } = new List<RecipeBom>();

    [JsonIgnore]
    public virtual ICollection<Recipe> Recipes { get; set; } = new List<Recipe>();
}
