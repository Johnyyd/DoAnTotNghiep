using System;
using System.Collections.Generic;

namespace GMP_System.Entities;

public partial class UomConversion
{
    public int ConversionId { get; set; }

    public int? FromUomId { get; set; }

    public int? ToUomId { get; set; }

    public decimal ConversionFactor { get; set; }

    public string? Note { get; set; }

    public virtual UnitOfMeasure? FromUom { get; set; }

    public virtual UnitOfMeasure? ToUom { get; set; }
}
