using System;
using System.Collections.Generic;

namespace GMP_System.Entities;

public partial class BatchProcessLog
{
    public long LogId { get; set; }

    public int? BatchId { get; set; }

    public int? RoutingId { get; set; }

    public int? EquipmentId { get; set; }

    public int? OperatorId { get; set; }

    public DateTime? StartTime { get; set; }

    public DateTime? EndTime { get; set; }

    public string? ResultStatus { get; set; }

    public string? ParametersData { get; set; }

    public virtual ProductionBatch? Batch { get; set; }

    public virtual Equipment? Equipment { get; set; }

    public virtual RecipeRouting? Routing { get; set; }
}
