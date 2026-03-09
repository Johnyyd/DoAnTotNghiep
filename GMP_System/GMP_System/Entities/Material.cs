using System;
using System.Collections.Generic;

namespace GMP_System.Entities;

public partial class Material
{
    public int MaterialId { get; set; }

    public string MaterialCode { get; set; } = null!;

    public string MaterialName { get; set; } = null!;

    public string? Type { get; set; }

    public int? BaseUomId { get; set; }

    public bool? IsActive { get; set; }

    public string? Description { get; set; }

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual UnitOfMeasure? BaseUom { get; set; }

    public virtual ICollection<InventoryLot> InventoryLots { get; set; } = new List<InventoryLot>();

    public virtual ICollection<RecipeBom> RecipeBoms { get; set; } = new List<RecipeBom>();

    public virtual ICollection<Recipe> Recipes { get; set; } = new List<Recipe>();
}
