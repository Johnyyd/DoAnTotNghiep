using System;
using System.Collections.Generic;

namespace GMP_System.Entities;

public partial class StepParameter
{
    public int ParameterId { get; set; }

    public int? RoutingId { get; set; }

    public string ParameterName { get; set; } = null!;

    public string? Unit { get; set; }

    public decimal? MinValue { get; set; }

    public decimal? MaxValue { get; set; }

    public bool? IsCritical { get; set; }

    public string? Note { get; set; }

    public virtual RecipeRouting? Routing { get; set; }

    public virtual ICollection<BatchProcessParameterValue> ParameterValues { get; set; } = new List<BatchProcessParameterValue>();
}
