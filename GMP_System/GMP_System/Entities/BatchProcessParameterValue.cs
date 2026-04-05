using System;

namespace GMP_System.Entities;

public partial class BatchProcessParameterValue
{
    public long ValueId { get; set; }

    public long? LogId { get; set; }

    public int? ParameterId { get; set; }

    public decimal? ActualValue { get; set; }

    public DateTime? RecordedDate { get; set; }

    public string? Note { get; set; }

    public virtual BatchProcessLog? Log { get; set; }

    public virtual StepParameter? Parameter { get; set; }
}
