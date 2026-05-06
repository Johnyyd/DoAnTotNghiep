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
                .Select(r => new {
                    r.RecipeId,
                    r.MaterialId,
                    r.VersionNumber,
                    r.BatchSize,
                    r.Status,
                    r.ApprovedBy,
                    r.ApprovedDate,
                    r.CreatedAt,
                    r.EffectiveDate,
                    r.Note,
                    Material = r.Material == null ? null : new {
                        r.Material.MaterialId,
                        r.Material.MaterialName,
                        r.Material.MaterialCode
                    }
                })
                .OrderBy(r => r.RecipeId)
                .ToListAsync();

            return Ok(new { data = recipes, success = true, message = "Success" });
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var recipe = await _context.Recipes
                .Where(r => r.RecipeId == id)
                .Select(r => new {
                    r.RecipeId,
                    r.MaterialId,
                    r.VersionNumber,
                    r.BatchSize,
                    r.Status,
                    r.ApprovedBy,
                    r.ApprovedDate,
                    r.CreatedAt,
                    r.EffectiveDate,
                    r.Note,
                    Material = r.Material == null ? null : new {
                        r.Material.MaterialId,
                        r.Material.MaterialName,
                        r.Material.MaterialCode
                    }
                })
                .FirstOrDefaultAsync();

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
                return BadRequest(new { success = false, message = "Vui lòng chọn thành phẩm cho công thức." });
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
                return BadRequest(new { success = false, message = "Không thể duyệt công thức ở trạng thái " + recipe.Status + "." });
            }

            recipe.Status = "Approved";
            recipe.ApprovedDate = DateTime.Now;

            _unitOfWork.Recipes.Update(recipe);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, message = "Đã duyệt công thức.", recipeId = id });
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
            
            // Xoá StepParameters của các Routing thuộc Recipe này
            if (routings.Any())
            {
                var routingIds = routings.Select(rt => (int?)rt.RoutingId).ToList();
                var stepParams = await _context.StepParameters.Where(p => routingIds.Contains(p.RoutingId)).ToListAsync();
                if (stepParams.Any()) _context.StepParameters.RemoveRange(stepParams);
            }

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
                return NotFound(new { success = false, message = "Không tìm thấy công thức." });
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
                return NotFound(new { success = false, message = "Không tìm thấy công thức." });
            }

            if (!request.MaterialId.HasValue || request.Quantity <= 0)
            {
                return BadRequest(new { success = false, message = "Thiếu nguyên liệu hoặc khối lượng không hợp lệ." });
            }

            var duplicatedMaterial = await _context.RecipeBoms
                .AnyAsync(b => b.RecipeId == id && b.MaterialId == request.MaterialId);
            if (duplicatedMaterial)
            {
                return BadRequest(new { success = false, message = "Nguyên liệu này đã có trong danh sách định mức." });
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

            var duplicatedMaterial = await _context.RecipeBoms
                .AnyAsync(b => b.RecipeId == id && b.BomId != bomId && b.MaterialId == request.MaterialId);
            if (duplicatedMaterial)
            {
                return BadRequest(new { success = false, message = "Nguyên liệu này đã có trong danh sách định mức." });
            }

            bom.MaterialId = request.MaterialId;
            bom.Quantity = request.Quantity;
            bom.UomId = request.UomId;
            bom.WastePercentage = request.WastePercentage ?? 0m;
            bom.Note = request.Note;

            await _context.SaveChangesAsync();
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
                    r.SetPressure,
                    r.SetTimeMinutes,
                    r.MaterialIds,
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
                SetPressure = request.SetPressure,
                SetTimeMinutes = request.SetTimeMinutes,
                MaterialIds = request.MaterialIds
            };

            _context.RecipeRoutings.Add(step);
            await _context.SaveChangesAsync();
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
            step.SetPressure = request.SetPressure;
            step.SetTimeMinutes = request.SetTimeMinutes;
            step.MaterialIds = request.MaterialIds;

            await _context.SaveChangesAsync();
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
            return Ok(new { success = true, message = "Đã xóa công đoạn." });
        }

        // PUT: api/recipes/{id}/routing/reorder
        [HttpPut("{id}/routing/reorder")]
        public async Task<IActionResult> ReorderRoutingSteps(int id, [FromBody] List<ReorderItem> items)
        {
            if (items == null || items.Count == 0)
                return BadRequest(new { success = false, message = "Danh sách rỗng." });

            var steps = await _context.RecipeRoutings.Where(r => r.RecipeId == id).ToListAsync();
            foreach (var item in items)
            {
                var step = steps.FirstOrDefault(s => s.RoutingId == item.RoutingId);
                if (step != null)
                {
                    step.StepNumber = item.StepNumber;
                }
            }
            await _context.SaveChangesAsync();
            return Ok(new { success = true, message = "Đã cập nhật thứ tự." });
        }

        // ===== TECH SPECS =====

        [HttpGet("{id}/tech-specs")]
        public async Task<IActionResult> GetTechSpecs(int id)
        {
            var specs = await _context.RecipeTechSpecs
                .Where(s => s.RecipeId == id)
                .OrderBy(s => s.SortOrder)
                .Select(s => new { s.SpecId, s.RecipeId, s.ParentId, s.SortOrder, s.Content, s.IsChecked })
                .ToListAsync();
            return Ok(new { success = true, data = specs });
        }

        [HttpPost("{id}/tech-specs")]
        public async Task<IActionResult> AddTechSpec(int id, [FromBody] RecipeTechSpec request)
        {
            var recipe = await _context.Recipes.FindAsync(id);
            if (recipe == null) return NotFound(new { success = false, message = "Không tìm thấy công thức." });

            var spec = new RecipeTechSpec
            {
                RecipeId = id,
                ParentId = request.ParentId,
                SortOrder = request.SortOrder,
                Content = request.Content?.Trim() ?? "",
                IsChecked = request.IsChecked
            };
            _context.RecipeTechSpecs.Add(spec);
            await _context.SaveChangesAsync();
            return Ok(new { success = true, data = new { spec.SpecId, spec.RecipeId, spec.ParentId, spec.SortOrder, spec.Content, spec.IsChecked } });
        }

        [HttpPut("{id}/tech-specs/{specId}")]
        public async Task<IActionResult> UpdateTechSpec(int id, int specId, [FromBody] RecipeTechSpec request)
        {
            var spec = await _context.RecipeTechSpecs.FirstOrDefaultAsync(s => s.SpecId == specId && s.RecipeId == id);
            if (spec == null) return NotFound(new { success = false, message = "Không tìm thấy tiêu chuẩn." });

            spec.Content = request.Content?.Trim() ?? spec.Content;
            spec.IsChecked = request.IsChecked;
            spec.SortOrder = request.SortOrder;
            spec.ParentId = request.ParentId;
            await _context.SaveChangesAsync();
            return Ok(new { success = true, data = new { spec.SpecId, spec.RecipeId, spec.ParentId, spec.SortOrder, spec.Content, spec.IsChecked } });
        }

        [HttpDelete("{id}/tech-specs/{specId}")]
        public async Task<IActionResult> DeleteTechSpec(int id, int specId)
        {
            var spec = await _context.RecipeTechSpecs.FirstOrDefaultAsync(s => s.SpecId == specId && s.RecipeId == id);
            if (spec == null) return NotFound(new { success = false, message = "Không tìm thấy tiêu chuẩn." });

            // Also delete child specs
            var children = await _context.RecipeTechSpecs.Where(s => s.ParentId == specId).ToListAsync();
            _context.RecipeTechSpecs.RemoveRange(children);
            _context.RecipeTechSpecs.Remove(spec);
            await _context.SaveChangesAsync();
            return Ok(new { success = true, message = "Đã xóa tiêu chuẩn." });
        }
    }

    public class ReorderItem
    {
        public int RoutingId { get; set; }
        public int StepNumber { get; set; }
    }
}
