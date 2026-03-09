using System;
using System.Collections.Generic;

namespace GMP_System.Entities;

public partial class Equipment
{
    public int EquipmentId { get; set; }

    public string EquipmentCode { get; set; } = null!;

    public string EquipmentName { get; set; } = null!;

    public string? Status { get; set; }

    public DateTime? LastMaintenanceDate { get; set; }

    public virtual ICollection<BatchProcessLog> BatchProcessLogs { get; set; } = new List<BatchProcessLog>();

    public virtual ICollection<RecipeRouting> RecipeRoutings { get; set; } = new List<RecipeRouting>();
}
