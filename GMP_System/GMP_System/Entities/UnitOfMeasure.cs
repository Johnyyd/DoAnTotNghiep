using System;
using System.Collections.Generic;

namespace GMP_System.Entities;

public partial class UnitOfMeasure
{
    public int UomId { get; set; }

    public string UomName { get; set; } = null!;

    public string? Description { get; set; }

    public virtual ICollection<Material> Materials { get; set; } = new List<Material>();

    public virtual ICollection<RecipeBom> RecipeBoms { get; set; } = new List<RecipeBom>();

    public virtual ICollection<UomConversion> UomConversionFromUoms { get; set; } = new List<UomConversion>();

    public virtual ICollection<UomConversion> UomConversionToUoms { get; set; } = new List<UomConversion>();
}
