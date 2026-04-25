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
                .FirstOrDefaultAsync(r => r.RecipeId == id);

            if (recipe == null)
            {
                return NotFound(new { success = false, message = $"Không tìm th?y công th?c ID={id}" });
            }

            return Ok(new { data = recipe, success = true, message = "Success" });
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] Recipe recipe)
        {
            if (!recipe.MaterialId.HasValue)
            {
                return BadRequest(new { success = false, message = "Vui lòng ch?n thành ph?m cho công th?c." });
            }

            if (recipe.BatchSize <= 0)
            {
                return BadRequest(new { success = false, message = "Kh?i lu?ng m?t viên ph?i l?n hon 0." });
            }

            recipe.Status = "Draft";
            recipe.VersionNumber = recipe.VersionNumber <= 0 ? 1 : recipe.VersionNumber;
            recipe.CreatedAt = DateTime.Now;

            await _unitOfWork.Recipes.AddAsync(recipe);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, data = recipe, message = "T?o công th?c thành công." });
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] Recipe recipe)
        {
            var existing = await _unitOfWork.Recipes.GetByIdAsync(id);
            if (existing == null)
            {
                return NotFound(new { success = false, message = "Không tìm th?y công th?c." });
            }

            existing.MaterialId = recipe.MaterialId;
            existing.BatchSize = recipe.BatchSize;
            existing.Note = recipe.Note;
            existing.EffectiveDate = recipe.EffectiveDate;
            existing.Status = recipe.Status;

            _unitOfWork.Recipes.Update(existing);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, message = "C?p nh?t công th?c thành công.", recipeId = id });
        }

        [HttpPost("{id}/approve")]
        public async Task<IActionResult> Approve(int id)
        {
            var recipe = await _unitOfWork.Recipes.GetByIdAsync(id);
            if (recipe == null)
            {
                return NotFound(new { success = false, message = "Không tìm th?y công th?c." });
            }

            if (recipe.Status != "Draft")
            {
                return BadRequest(new { success = false, message = "Ch? có th? duy?t công th?c ? tr?ng thái Draft." });
            }

            recipe.Status = "Approved";
            recipe.ApprovedDate = DateTime.Now;

            _unitOfWork.Recipes.Update(recipe);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, message = "Ðã duy?t công th?c.", recipeId = id });
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var recipe = await _unitOfWork.Recipes.GetByIdAsync(id);
            if (recipe == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy công thức." });
            }

            // Kiểm tra xem công thức đã được sử dụng trong Lệnh sản xuất nào chưa
            var hasOrders = await _context.ProductionOrders.AnyAsync(o => o.RecipeId == id);
            if (hasOrders)
            {
                return BadRequest(new { success = false, message = "Không thể xóa công thức vì đã có Lệnh sản xuất sử dụng công thức này." });
            }

            // Xoá các dữ liệu liên quan (BOM và Routing) trước khi xoá Recipe để tránh lỗi Khóa ngoại
            var boms = await _context.RecipeBoms.Where(b => b.RecipeId == id).ToListAsync();
            var routings = await _context.RecipeRoutings.Where(r => r.RecipeId == id).ToListAsync();

            if (boms.Any()) _context.RecipeBoms.RemoveRange(boms);
            if (routings.Any()) _context.RecipeRoutings.RemoveRange(routings);

            // Xoá các dữ liệu liên quan ở DB trước khi xoá dữ liệu cha
            await _context.SaveChangesAsync();

            _unitOfWork.Recipes.Remove(recipe);
            await _unitOfWork.CompleteAsync();
            return Ok(new { success = true, message = "Đã xóa công thức thành công." });
        }

        [HttpGet("{id}/bom")]
        public async Task<IActionResult> GetBom(int id)
        {
            var exists = await _context.Recipes.AnyAsync(r => r.RecipeId == id);
            if (!exists)
            {
                return NotFound(new { success = false, message = "Không tìm th?y công th?c." });
            }

            var items = await _context.RecipeBoms
                .Where(b => b.RecipeId == id)
                .Include(b => b.Material)
                .Include(b => b.Uom)
                .OrderBy(b => b.BomId)
                .Select(b => new
                {
                    b.BomId,
                    b.RecipeId,
                    b.MaterialId,
                    b.Quantity,
                    b.UomId,
                    b.WastePercentage,
                    b.Note,
                    TechnicalStandard = b.Material != null ? b.Material.TechnicalSpecification : null,
                    Material = b.Material == null ? null : new { b.Material.MaterialId, b.Material.MaterialCode, b.Material.MaterialName },
                    Uom = b.Uom == null ? null : new { b.Uom.UomId, b.Uom.UomName }
                })
                .ToListAsync();

            return Ok(new { success = true, data = items });
        }

        [HttpPost("{id}/bom")]
        public async Task<IActionResult> AddBomItem(int id, [FromBody] RecipeBom request)
        {
            var recipe = await _context.Recipes.FindAsync(id);
            if (recipe == null)
            {
                return NotFound(new { success = false, message = "Không tìm th?y công th?c." });
            }

            if (!request.MaterialId.HasValue || request.Quantity <= 0)
            {
                return BadRequest(new { success = false, message = "Thi?u nguyên li?u ho?c kh?i lu?ng không h?p l?." });
            }

            var bom = new RecipeBom
            {
                RecipeId = id,
                MaterialId = request.MaterialId,
                Quantity = request.Quantity,
                UomId = request.UomId,
                WastePercentage = request.WastePercentage ?? 0m,
                Note = request.Note
            };

            _context.RecipeBoms.Add(bom);
            await _context.SaveChangesAsync();

            return Ok(new { success = true, data = bom, message = "Ðã thêm nguyên li?u d?nh m?c." });
        }

        [HttpPut("{id}/bom/{bomId}")]
        public async Task<IActionResult> UpdateBomItem(int id, int bomId, [FromBody] RecipeBom request)
        {
            var bom = await _context.RecipeBoms.FirstOrDefaultAsync(b => b.BomId == bomId && b.RecipeId == id);
            if (bom == null)
            {
                return NotFound(new { success = false, message = "Không tìm th?y dòng d?nh m?c." });
            }

            if (!request.MaterialId.HasValue || request.Quantity <= 0)
            {
                return BadRequest(new { success = false, message = "D? li?u d?nh m?c không h?p l?." });
            }

            bom.MaterialId = request.MaterialId;
            bom.Quantity = request.Quantity;
            bom.UomId = request.UomId;
            bom.WastePercentage = request.WastePercentage ?? 0m;
            bom.Note = request.Note;

            await _context.SaveChangesAsync();
            return Ok(new { success = true, data = bom, message = "Ðã c?p nh?t d?nh m?c." });
        }

        [HttpDelete("{id}/bom/{bomId}")]
        public async Task<IActionResult> DeleteBomItem(int id, int bomId)
        {
            var bom = await _context.RecipeBoms.FirstOrDefaultAsync(b => b.BomId == bomId && b.RecipeId == id);
            if (bom == null)
            {
                return NotFound(new { success = false, message = "Không tìm th?y dòng d?nh m?c." });
            }

            _context.RecipeBoms.Remove(bom);
            await _context.SaveChangesAsync();
            return Ok(new { success = true, message = "Ðã xóa dòng d?nh m?c." });
        }

        [HttpGet("{id}/routing")]
        public async Task<IActionResult> GetRouting(int id)
        {
            var exists = await _context.Recipes.AnyAsync(r => r.RecipeId == id);
            if (!exists)
            {
                return NotFound(new { success = false, message = "Không tìm th?y công th?c." });
            }

            var steps = await _context.RecipeRoutings
                .Where(r => r.RecipeId == id)
                .Include(r => r.DefaultEquipment)
                    .ThenInclude(e => e!.Area)
                .OrderBy(r => r.StepNumber)
                .Select(r => new
                {
                    r.RoutingId,
                    r.RecipeId,
                    r.StepNumber,
                    r.StepName,
                    r.Description,
                    r.EstimatedTimeMinutes,
                    r.DefaultEquipmentId,
                    r.MaterialId,
                    r.AreaId,
                    r.CleanlinessStatus,
                    r.StandardTemperature,
                    r.StandardHumidity,
                    r.StandardPressure,
                    r.StabilityStatus,
                    r.SetTemperature,
                    r.SetTimeMinutes,
                    Material = r.Material == null ? null : new { r.Material.MaterialName },
                    Area = r.Area == null ? null : new { r.Area.AreaName },
                    DefaultEquipment = r.DefaultEquipment == null ? null : new
                    {
                        r.DefaultEquipment.EquipmentId,
                        r.DefaultEquipment.EquipmentName,
                        r.DefaultEquipment.EquipmentCode,
                        Area = r.DefaultEquipment.Area == null ? null : new
                        {
                            r.DefaultEquipment.Area.AreaId,
                            r.DefaultEquipment.Area.AreaName,
                            r.DefaultEquipment.Area.AreaCode
                        }
                    }
                })
                .ToListAsync();

            return Ok(new { success = true, data = steps });
        }

        [HttpPost("{id}/routing")]
        public async Task<IActionResult> AddRoutingStep(int id, [FromBody] RecipeRouting request)
        {
            var recipe = await _context.Recipes.FindAsync(id);
            if (recipe == null)
            {
                return NotFound(new { success = false, message = "Không tìm th?y công th?c." });
            }

            if (request.StepNumber <= 0 || string.IsNullOrWhiteSpace(request.StepName))
            {
                return BadRequest(new { success = false, message = "Thông tin công do?n không h?p l?." });
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
            return Ok(new { success = true, data = step, message = "Ðã thêm công do?n." });
        }

        [HttpPut("{id}/routing/{routingId}")]
        public async Task<IActionResult> UpdateRoutingStep(int id, int routingId, [FromBody] RecipeRouting request)
        {
            var step = await _context.RecipeRoutings.FirstOrDefaultAsync(r => r.RoutingId == routingId && r.RecipeId == id);
            if (step == null)
            {
                return NotFound(new { success = false, message = "Không tìm th?y công do?n." });
            }

            if (request.StepNumber <= 0 || string.IsNullOrWhiteSpace(request.StepName))
            {
                return BadRequest(new { success = false, message = "Thông tin công do?n không h?p l?." });
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
            return Ok(new { success = true, data = step, message = "Ðã c?p nh?t công do?n." });
        }

        [HttpDelete("{id}/routing/{routingId}")]
        public async Task<IActionResult> DeleteRoutingStep(int id, int routingId)
        {
            var step = await _context.RecipeRoutings.FirstOrDefaultAsync(r => r.RoutingId == routingId && r.RecipeId == id);
            if (step == null)
            {
                return NotFound(new { success = false, message = "Không tìm th?y công do?n." });
            }

            _context.RecipeRoutings.Remove(step);
            await _context.SaveChangesAsync();
            return Ok(new { success = true, message = "Ðã xóa công do?n." });
        }
    }
}
