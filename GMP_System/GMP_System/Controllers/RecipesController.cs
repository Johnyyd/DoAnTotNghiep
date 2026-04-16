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
        private readonly GmpContext _context;

        public RecipesController(IUnitOfWork unitOfWork, GmpContext context)
        {
            _unitOfWork = unitOfWork;
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var recipes = await _context.Recipes
                .Include(r => r.Material)
                .Include(r => r.RecipeBoms)
                    .ThenInclude(b => b.Material)
                .Include(r => r.RecipeBoms)
                    .ThenInclude(b => b.Uom)
                .Include(r => r.RecipeRoutings)
                    .ThenInclude(rt => rt.DefaultEquipment)
                .Include(r => r.RecipeRoutings)
                    .ThenInclude(rt => rt.Area)
                .Include(r => r.RecipeRoutings)
                    .ThenInclude(rt => rt.Material)
                .Include(r => r.ApprovedByNavigation)
                .OrderBy(r => r.RecipeId)
                .ToListAsync();

            return Ok(new { data = recipes, success = true, message = "Success" });
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var recipe = await _context.Recipes
                .Include(r => r.Material)
                .Include(r => r.RecipeBoms)
                    .ThenInclude(b => b.Material)
                .Include(r => r.RecipeBoms)
                    .ThenInclude(b => b.Uom)
                .Include(r => r.RecipeRoutings)
                    .ThenInclude(rt => rt.DefaultEquipment)
                .Include(r => r.RecipeRoutings)
                    .ThenInclude(rt => rt.Area)
                .Include(r => r.RecipeRoutings)
                    .ThenInclude(rt => rt.Material)
                .FirstOrDefaultAsync(r => r.RecipeId == id);

            if (recipe == null)
            {
                return NotFound(new { success = false, message = $"Không tìm thấy công thức ID={id}" });
            }

            return Ok(new { data = recipe, success = true, message = "Success" });
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] Recipe recipe)
        {
            if (!recipe.MaterialId.HasValue)
            {
                return BadRequest(new { success = false, message = "Vui lòng chọn thành phẩm mong muốn." });
            }

            if (recipe.BatchSize <= 0)
            {
                return BadRequest(new { success = false, message = "Khối lượng một viên phải lớn hơn 0." });
            }

            recipe.Status = "Draft";
            recipe.VersionNumber = recipe.VersionNumber <= 0 ? 1 : recipe.VersionNumber;
            recipe.CreatedAt = DateTime.Now;

            await _unitOfWork.Recipes.AddAsync(recipe);
            await _unitOfWork.CompleteAsync();
            await WriteAuditAsync("Recipes", recipe.RecipeId.ToString(), "Create", null, $"MaterialId={recipe.MaterialId};BatchSize={recipe.BatchSize}");

            return Ok(new { success = true, data = recipe, message = "Tạo công thức thành công." });
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] Recipe recipe)
        {
            var existing = await _unitOfWork.Recipes.GetByIdAsync(id);
            if (existing == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy công thức." });
            }

            existing.MaterialId = recipe.MaterialId;
            existing.BatchSize = recipe.BatchSize;
            existing.Note = recipe.Note;
            existing.EffectiveDate = recipe.EffectiveDate;
            existing.Status = recipe.Status;

            _unitOfWork.Recipes.Update(existing);
            await _unitOfWork.CompleteAsync();
            await WriteAuditAsync("Recipes", id.ToString(), "Update", null, $"MaterialId={existing.MaterialId};BatchSize={existing.BatchSize}");

            return Ok(new { success = true, message = "Cập nhật công thức thành công.", recipeId = id });
        }

        [HttpPost("{id}/approve")]
        public async Task<IActionResult> Approve(int id)
        {
            var recipe = await _unitOfWork.Recipes.GetByIdAsync(id);
            if (recipe == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy công thức." });
            }

            if (recipe.Status != "Draft")
            {
                return BadRequest(new { success = false, message = "Chỉ có thể duyệt công thức ở trạng thái Draft." });
            }

            recipe.Status = "Approved";
            recipe.ApprovedDate = DateTime.Now;

            _unitOfWork.Recipes.Update(recipe);
            await _unitOfWork.CompleteAsync();
            await WriteAuditAsync("Recipes", id.ToString(), "Approve", "Draft", "Approved");

            return Ok(new { success = true, message = "Đã duyệt công thức.", recipeId = id });
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var recipe = await _context.Recipes
                .Include(r => r.RecipeBoms)
                .Include(r => r.RecipeRoutings)
                .FirstOrDefaultAsync(r => r.RecipeId == id);

            if (recipe == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy công thức." });
            }

            var hasOrders = await _context.ProductionOrders.AnyAsync(o => o.RecipeId == id);
            if (hasOrders)
            {
                return BadRequest(new { success = false, message = "Công thức đã được dùng trong lệnh sản xuất, không thể xóa." });
            }

            _context.RecipeBoms.RemoveRange(recipe.RecipeBoms);
            _context.RecipeRoutings.RemoveRange(recipe.RecipeRoutings);
            _context.Recipes.Remove(recipe);

            try
            {
                await _context.SaveChangesAsync();
                await WriteAuditAsync("Recipes", id.ToString(), "Delete", $"RecipeId={id}", null);
                return Ok(new { success = true, message = "Đã xóa công thức." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { success = false, message = $"Không thể xóa công thức: {ex.Message}" });
            }
        }

        [HttpGet("{id}/bom")]
        public async Task<IActionResult> GetBom(int id)
        {
            var exists = await _context.Recipes.AnyAsync(r => r.RecipeId == id);
            if (!exists)
            {
                return NotFound(new { success = false, message = "Không tìm thấy công thức." });
            }

            var items = await _context.RecipeBoms
                .Where(b => b.RecipeId == id)
                .Include(b => b.Material)
                .Include(b => b.Uom)
                .OrderBy(b => b.BomId)
                .ToListAsync();

            return Ok(new { success = true, data = items });
        }

        [HttpPost("{id}/bom")]
        public async Task<IActionResult> AddBomItem(int id, [FromBody] RecipeBom request)
        {
            var recipe = await _context.Recipes.FindAsync(id);
            if (recipe == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy công thức." });
            }

            if (!request.MaterialId.HasValue || request.Quantity <= 0)
            {
                return BadRequest(new { success = false, message = "Thiếu nguyên liệu hoặc khối lượng không hợp lệ." });
            }

            var bom = new RecipeBom
            {
                RecipeId = id,
                MaterialId = request.MaterialId,
                Quantity = request.Quantity,
                UomId = request.UomId,
                WastePercentage = request.WastePercentage ?? 0m,
                TechnicalStandard = request.TechnicalStandard,
                Note = request.Note
            };

            _context.RecipeBoms.Add(bom);
            await _context.SaveChangesAsync();
            await WriteAuditAsync("RecipeBom", bom.BomId.ToString(), "Create", null, $"RecipeId={id};MaterialId={bom.MaterialId}");

            return Ok(new { success = true, data = bom, message = "Đã thêm nguyên liệu định mức." });
        }

        [HttpPut("{id}/bom/{bomId}")]
        public async Task<IActionResult> UpdateBomItem(int id, int bomId, [FromBody] RecipeBom request)
        {
            var bom = await _context.RecipeBoms.FirstOrDefaultAsync(b => b.BomId == bomId && b.RecipeId == id);
            if (bom == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy dòng định mức." });
            }

            if (!request.MaterialId.HasValue || request.Quantity <= 0)
            {
                return BadRequest(new { success = false, message = "Dữ liệu định mức không hợp lệ." });
            }

            bom.MaterialId = request.MaterialId;
            bom.Quantity = request.Quantity;
            bom.UomId = request.UomId;
            bom.WastePercentage = request.WastePercentage ?? 0m;
            bom.TechnicalStandard = request.TechnicalStandard;
            bom.Note = request.Note;

            await _context.SaveChangesAsync();
            await WriteAuditAsync("RecipeBom", bom.BomId.ToString(), "Update", null, $"MaterialId={bom.MaterialId};Qty={bom.Quantity}");
            return Ok(new { success = true, data = bom, message = "Đã cập nhật định mức." });
        }

        [HttpDelete("{id}/bom/{bomId}")]
        public async Task<IActionResult> DeleteBomItem(int id, int bomId)
        {
            var bom = await _context.RecipeBoms.FirstOrDefaultAsync(b => b.BomId == bomId && b.RecipeId == id);
            if (bom == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy dòng định mức." });
            }

            _context.RecipeBoms.Remove(bom);
            await _context.SaveChangesAsync();
            await WriteAuditAsync("RecipeBom", bomId.ToString(), "Delete", $"RecipeId={id}", null);
            return Ok(new { success = true, message = "Đã xóa dòng định mức." });
        }

        [HttpGet("{id}/routing")]
        public async Task<IActionResult> GetRouting(int id)
        {
            var exists = await _context.Recipes.AnyAsync(r => r.RecipeId == id);
            if (!exists)
            {
                return NotFound(new { success = false, message = "Không tìm thấy công thức." });
            }

            var steps = await _context.RecipeRoutings
                .Where(r => r.RecipeId == id)
                .Include(r => r.DefaultEquipment)
                .Include(r => r.Material)
                .Include(r => r.Area)
                .OrderBy(r => r.StepNumber)
                .ToListAsync();

            return Ok(new { success = true, data = steps });
        }

        [HttpPost("{id}/routing")]
        public async Task<IActionResult> AddRoutingStep(int id, [FromBody] RecipeRouting request)
        {
            var recipe = await _context.Recipes.FindAsync(id);
            if (recipe == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy công thức." });
            }

            if (request.StepNumber <= 0 || string.IsNullOrWhiteSpace(request.StepName))
            {
                return BadRequest(new { success = false, message = "Thông tin công đoạn không hợp lệ." });
            }

            var step = new RecipeRouting
            {
                RecipeId = id,
                StepNumber = request.StepNumber,
                StepName = request.StepName.Trim(),
                Description = request.Description,
                EstimatedTimeMinutes = request.EstimatedTimeMinutes,
                DefaultEquipmentId = request.DefaultEquipmentId,
                MaterialId = request.MaterialId,
                AreaId = request.AreaId,
                CleanlinessStatus = request.CleanlinessStatus,
                StandardTemperature = request.StandardTemperature,
                StandardHumidity = request.StandardHumidity,
                StandardPressure = request.StandardPressure,
                StabilityStatus = request.StabilityStatus,
                SetTemperature = request.SetTemperature,
                SetTimeMinutes = request.SetTimeMinutes
            };

            _context.RecipeRoutings.Add(step);
            await _context.SaveChangesAsync();
            await WriteAuditAsync("RecipeRouting", step.RoutingId.ToString(), "Create", null, $"RecipeId={id};Step={step.StepNumber}");
            return Ok(new { success = true, data = step, message = "Đã thêm công đoạn." });
        }

        [HttpPut("{id}/routing/{routingId}")]
        public async Task<IActionResult> UpdateRoutingStep(int id, int routingId, [FromBody] RecipeRouting request)
        {
            var step = await _context.RecipeRoutings.FirstOrDefaultAsync(r => r.RoutingId == routingId && r.RecipeId == id);
            if (step == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy công đoạn." });
            }

            if (request.StepNumber <= 0 || string.IsNullOrWhiteSpace(request.StepName))
            {
                return BadRequest(new { success = false, message = "Thông tin công đoạn không hợp lệ." });
            }

            step.StepNumber = request.StepNumber;
            step.StepName = request.StepName.Trim();
            step.Description = request.Description;
            step.EstimatedTimeMinutes = request.EstimatedTimeMinutes;
            step.DefaultEquipmentId = request.DefaultEquipmentId;
            step.MaterialId = request.MaterialId;
            step.AreaId = request.AreaId;
            step.CleanlinessStatus = request.CleanlinessStatus;
            step.StandardTemperature = request.StandardTemperature;
            step.StandardHumidity = request.StandardHumidity;
            step.StandardPressure = request.StandardPressure;
            step.StabilityStatus = request.StabilityStatus;
            step.SetTemperature = request.SetTemperature;
            step.SetTimeMinutes = request.SetTimeMinutes;

            await _context.SaveChangesAsync();
            await WriteAuditAsync("RecipeRouting", step.RoutingId.ToString(), "Update", null, $"Step={step.StepNumber}");
            return Ok(new { success = true, data = step, message = "Đã cập nhật công đoạn." });
        }

        [HttpDelete("{id}/routing/{routingId}")]
        public async Task<IActionResult> DeleteRoutingStep(int id, int routingId)
        {
            var step = await _context.RecipeRoutings.FirstOrDefaultAsync(r => r.RoutingId == routingId && r.RecipeId == id);
            if (step == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy công đoạn." });
            }

            _context.RecipeRoutings.Remove(step);
            await _context.SaveChangesAsync();
            await WriteAuditAsync("RecipeRouting", routingId.ToString(), "Delete", $"RecipeId={id}", null);
            return Ok(new { success = true, message = "Đã xóa công đoạn." });
        }

        private async Task WriteAuditAsync(string tableName, string recordId, string action, string? oldValue, string? newValue)
        {
            int? changedBy = null;
            var claim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (int.TryParse(claim, out var uid)) changedBy = uid;

            _context.SystemAuditLogs.Add(new SystemAuditLog
            {
                TableName = tableName,
                RecordId = recordId,
                Action = action,
                OldValue = oldValue,
                NewValue = newValue,
                ChangedBy = changedBy,
                ChangedDate = DateTime.Now
            });

            await _context.SaveChangesAsync();
        }
    }
}
