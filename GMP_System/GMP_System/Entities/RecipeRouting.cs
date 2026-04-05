using System;
using System.Collections.Generic;

namespace GMP_System.Entities;

public partial class RecipeRouting
{
    public int RoutingId { get; set; }

    public int? RecipeId { get; set; }

    public int StepNumber { get; set; }

    public string StepName { get; set; } = null!;

    public string? Description { get; set; }

    public int? EstimatedTimeMinutes { get; set; }

    public int? DefaultEquipmentId { get; set; }

    public virtual ICollection<BatchProcessLog> BatchProcessLogs { get; set; } = new List<BatchProcessLog>();

    public virtual Equipment? DefaultEquipment { get; set; }

    public virtual Recipe? Recipe { get; set; }

    public virtual ICollection<StepParameter> StepParameters { get; set; } = new List<StepParameter>();
}
