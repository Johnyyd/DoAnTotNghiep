using System;
using System.Collections.Generic;

namespace GMP_System.Entities;

public partial class ProductionArea
{
    public int AreaId { get; set; }

    public string AreaCode { get; set; } = null!;

    public string AreaName { get; set; } = null!;

    public string? Description { get; set; }

    public virtual ICollection<Equipment> Equipments { get; set; } = new List<Equipment>();

    public virtual ICollection<RecipeRouting> RecipeRoutings { get; set; } = new List<RecipeRouting>();
}
