using GMP_System.Entities;
using GMP_System.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GMP_System.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class RecipesController : ControllerBase
    {
        private readonly IUnitOfWork _unitOfWork;

        public RecipesController(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        // GET: api/Recipes
        // Lấy danh sách công thức kèm Material, BOM và Routing
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var recipes = await _unitOfWork.Recipes
                .Query()
                .Include(r => r.Material)
                .Include(r => r.RecipeBoms)
                    .ThenInclude(b => b.Material)
                .Include(r => r.RecipeBoms)
                    .ThenInclude(b => b.Uom)
                .Include(r => r.RecipeRoutings)
                    .ThenInclude(rt => rt.DefaultEquipment)
                .Include(r => r.ApprovedByNavigation)
                .ToListAsync();

            return Ok(new { data = recipes, success = true, message = "Success" });
        }

        // GET: api/Recipes/5
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var recipe = await _unitOfWork.Recipes
                .Query()
                .Include(r => r.Material)
                .Include(r => r.RecipeBoms)
                    .ThenInclude(b => b.Material)
                .Include(r => r.RecipeBoms)
                    .ThenInclude(b => b.Uom)
                .Include(r => r.RecipeRoutings)
                    .ThenInclude(rt => rt.DefaultEquipment)
                .FirstOrDefaultAsync(r => r.RecipeId == id);

            if (recipe == null) return NotFound(new { success = false, message = $"Không tìm thấy công thức ID={id}" });
            return Ok(new { data = recipe, success = true, message = "Success" });
        }

        // POST: api/Recipes
        [HttpPost]
        public async Task<IActionResult> Create(Recipe recipe)
        {
            if (recipe.BatchSize <= 0)
                return BadRequest(new { success = false, message = "Kích thước lô (BatchSize) phải lớn hơn 0" });

            recipe.Status = "Draft";
            recipe.VersionNumber = 1;
            recipe.CreatedAt = DateTime.Now;

            await _unitOfWork.Recipes.AddAsync(recipe);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, data = recipe, message = "Tạo công thức thành công!" });
        }

        // PUT: api/Recipes/5
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, Recipe recipe)
        {
            var existing = await _unitOfWork.Recipes.GetByIdAsync(id);
            if (existing == null)
                return NotFound(new { success = false, message = "Không tìm thấy công thức." });

            if (existing.Status == "Approved")
                return BadRequest(new { success = false, message = "Không thể sửa công thức đã được duyệt." });

            existing.MaterialId = recipe.MaterialId;
            existing.BatchSize = recipe.BatchSize;
            existing.Note = recipe.Note;
            existing.EffectiveDate = recipe.EffectiveDate;

            _unitOfWork.Recipes.Update(existing);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, message = "Cập nhật công thức thành công!", recipeId = id });
        }

        // POST: api/Recipes/5/approve
        [HttpPost("{id}/approve")]
        public async Task<IActionResult> Approve(int id)
        {
            var recipe = await _unitOfWork.Recipes.GetByIdAsync(id);
            if (recipe == null) return NotFound();

            if (recipe.Status != "Draft")
                return BadRequest(new { success = false, message = "Chỉ có thể duyệt công thức đang ở trạng thái Draft." });

            recipe.Status = "Approved";
            recipe.ApprovedDate = DateTime.Now;

            _unitOfWork.Recipes.Update(recipe);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, message = "Đã duyệt công thức!", recipeId = id });
        }

        // DELETE: api/Recipes/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var recipe = await _unitOfWork.Recipes.GetByIdAsync(id);
            if (recipe == null) return NotFound();
            if (recipe.Status == "Approved")
                return BadRequest(new { success = false, message = "Không thể xóa công thức đã được duyệt." });

            _unitOfWork.Recipes.Remove(recipe);
            await _unitOfWork.CompleteAsync();
            return Ok(new { success = true, message = "Đã xóa công thức." });
        }
    }
}