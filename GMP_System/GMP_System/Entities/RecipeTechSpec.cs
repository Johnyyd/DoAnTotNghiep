using System.Text.Json.Serialization;

namespace GMP_System.Entities;

public class RecipeTechSpec
{
    public int SpecId { get; set; }
    public int RecipeId { get; set; }
    public int? ParentId { get; set; }
    public int SortOrder { get; set; }
    public string Content { get; set; } = null!;
    public bool IsChecked { get; set; }

    [JsonIgnore]
    public virtual Recipe? Recipe { get; set; }
}
