using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;

namespace GMP_System.Entities;

public partial class ProductionArea
{
    public int AreaId { get; set; }

    public string AreaCode { get; set; } = null!;

    public string AreaName { get; set; } = null!;

    public string? Description { get; set; }

    public virtual ICollection<Equipment> Equipments { get; set; } = new List<Equipment>();

    [NotMapped]
    public virtual ICollection<RecipeRouting> RecipeRoutings { get; set; } = new List<RecipeRouting>();
}
