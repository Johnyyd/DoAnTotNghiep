using GMP_System.Entities;
using GMP_System.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GMP_System.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class MaterialsController : ControllerBase
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly GmpContext _context;

        public MaterialsController(IUnitOfWork unitOfWork, GmpContext context)
        {
            _unitOfWork = unitOfWork;
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var materials = await _unitOfWork.Materials
                .Query()
                .Include(m => m.BaseUom)
                .ToListAsync();

            return Ok(new { data = materials, success = true, message = "Success" });
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var material = await _unitOfWork.Materials
                .Query()
                .Include(m => m.BaseUom)
                .Include(m => m.InventoryLots)
                .FirstOrDefaultAsync(m => m.MaterialId == id);

            if (material == null)
            {
                return NotFound(new { success = false, message = $"Không tìm thấy nguyên liệu ID={id}" });
            }

            return Ok(new { data = material, success = true, message = "Success" });
        }

        [HttpPost]
        public async Task<IActionResult> Create(Material material)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            material.CreatedAt = DateTime.Now;
            material.IsActive ??= true;

            await _unitOfWork.Materials.AddAsync(material);
            await _unitOfWork.CompleteAsync();
            await WriteAuditAsync("Materials", material.MaterialId.ToString(), "Create", null, $"Code={material.MaterialCode};Name={material.MaterialName}");

            return CreatedAtAction(nameof(GetById), new { id = material.MaterialId },
                new { success = true, data = material, message = "Tạo nguyên liệu thành công." });
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, Material material)
        {
            if (id != material.MaterialId)
            {
                return BadRequest(new { success = false, message = "ID không khớp." });
            }

            var existing = await _unitOfWork.Materials.GetByIdAsync(id);
            if (existing == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy nguyên liệu." });
            }

            existing.MaterialCode = material.MaterialCode;
            existing.MaterialName = material.MaterialName;
            existing.Type = material.Type;
            existing.TechnicalSpecification = material.TechnicalSpecification;
            existing.BaseUomId = material.BaseUomId;
            existing.IsActive = material.IsActive;

            _unitOfWork.Materials.Update(existing);
            await _unitOfWork.CompleteAsync();
            await WriteAuditAsync("Materials", id.ToString(), "Update", null, $"Code={existing.MaterialCode};Name={existing.MaterialName}");

            return Ok(new { success = true, message = "Cập nhật thành công.", materialId = id });
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var material = await _unitOfWork.Materials.GetByIdAsync(id);
            if (material == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy nguyên liệu." });
            }

            var hasRecipeAsProduct = await _unitOfWork.Recipes.Query().AnyAsync(x => x.MaterialId == id);
            if (hasRecipeAsProduct)
            {
                return BadRequest(new
                {
                    success = false,
                    message = "Nguyên liệu đang được dùng trong công thức hoặc sản phẩm, không thể xóa."
                });
            }

            var lotIds = await _unitOfWork.InventoryLots.Query()
                .Where(x => x.MaterialId == id)
                .Select(x => x.LotId)
                .ToListAsync();

            if (lotIds.Any())
            {
                var hasUsage = await _unitOfWork.MaterialUsages.Query().AnyAsync(x => x.InventoryLotId != null && lotIds.Contains(x.InventoryLotId.Value));
                if (hasUsage)
                {
                    return BadRequest(new
                    {
                        success = false,
                        message = "Nguyên liệu đã phát sinh sử dụng trong sản xuất, không thể xóa."
                    });
                }

                var lots = await _unitOfWork.InventoryLots.Query().Where(x => x.MaterialId == id).ToListAsync();
                foreach (var lot in lots)
                {
                    _unitOfWork.InventoryLots.Remove(lot);
                }
            }

            _unitOfWork.Materials.Remove(material);
            try
            {
                await _unitOfWork.CompleteAsync();
                await WriteAuditAsync("Materials", id.ToString(), "Delete", $"Code={material.MaterialCode};Name={material.MaterialName}", null);
                return Ok(new { success = true, message = "Đã xóa nguyên liệu." });
            }
            catch (DbUpdateException)
            {
                return BadRequest(new
                {
                    success = false,
                    message = "Nguyên liệu đang liên kết dữ liệu nghiệp vụ khác nên chưa thể xóa."
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new
                {
                    success = false,
                    message = $"Không thể xóa nguyên liệu: {ex.Message}"
                });
            }
        }

        private async Task WriteAuditAsync(string tableName, string recordId, string action, string? oldValue, string? newValue)
        {
            int? changedBy = null;
            var claim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (int.TryParse(claim, out var uid))
            {
                changedBy = uid;
            }

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
