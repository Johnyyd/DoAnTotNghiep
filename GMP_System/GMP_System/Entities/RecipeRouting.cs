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
    
    public int? NumberOfRouting { get; set; } = 1;

    public int? MaterialId { get; set; }

    public int? AreaId { get; set; }

    public string? CleanlinessStatus { get; set; }

    public decimal? StandardTemperature { get; set; }

    public decimal? StandardHumidity { get; set; }

    public decimal? StandardPressure { get; set; }

    public string? StabilityStatus { get; set; }

    public decimal? SetTemperature { get; set; }

    public int? SetTimeMinutes { get; set; }

    public virtual ICollection<BatchProcessLog> BatchProcessLogs { get; set; } = new List<BatchProcessLog>();

    public virtual ProductionArea? Area { get; set; }

    public virtual Equipment? DefaultEquipment { get; set; }

    public virtual Material? Material { get; set; }

    public virtual Recipe? Recipe { get; set; }

    public virtual ICollection<StepParameter> StepParameters { get; set; } = new List<StepParameter>();
}
