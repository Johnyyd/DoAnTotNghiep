using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace GMP_System.Entities;

public partial class UnitOfMeasure
{
    public int UomId { get; set; }

    public string UomName { get; set; } = null!;

    public string? Description { get; set; }

    [JsonIgnore]
    public virtual ICollection<Material> Materials { get; set; } = new List<Material>();

    [JsonIgnore]
    public virtual ICollection<RecipeBom> RecipeBoms { get; set; } = new List<RecipeBom>();

    [JsonIgnore]
    public virtual ICollection<UomConversion> UomConversionFromUoms { get; set; } = new List<UomConversion>();

    [JsonIgnore]
    public virtual ICollection<UomConversion> UomConversionToUoms { get; set; } = new List<UomConversion>();
}
