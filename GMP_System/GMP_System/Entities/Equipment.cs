using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace GMP_System.Entities;

public partial class Equipment
{
    public int EquipmentId { get; set; }

    public string EquipmentCode { get; set; } = null!;

    public string EquipmentName { get; set; } = null!;

    public string? TechnicalSpecification { get; set; }

    public string? UsagePurpose { get; set; }

    public int? AreaId { get; set; }



    [JsonIgnore]
    public virtual ICollection<BatchProcessLog> BatchProcessLogs { get; set; } = new List<BatchProcessLog>();

    public virtual ProductionArea? Area { get; set; }

    [JsonIgnore]
    public virtual ICollection<RecipeRouting> RecipeRoutings { get; set; } = new List<RecipeRouting>();
}
