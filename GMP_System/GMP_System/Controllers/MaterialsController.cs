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

        public MaterialsController(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        // GET: api/Materials
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var materials = await _unitOfWork.Materials
                .Query()
                .Include(m => m.BaseUom)
                .ToListAsync();

            return Ok(new { data = materials, success = true, message = "Success" });
        }

        // GET: api/Materials/5
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var material = await _unitOfWork.Materials
                .Query()
                .Include(m => m.BaseUom)
                .Include(m => m.InventoryLots)
                .FirstOrDefaultAsync(m => m.MaterialId == id);

            if (material == null)
                return NotFound(new { success = false, message = $"Không tìm thấy nguyên liệu ID={id}" });

            return Ok(new { data = material, success = true, message = "Success" });
        }

        // POST: api/Materials
        [HttpPost]
        public async Task<IActionResult> Create(Material material)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            material.CreatedAt = DateTime.Now;
            material.IsActive ??= true;

            await _unitOfWork.Materials.AddAsync(material);
            await _unitOfWork.CompleteAsync();

            return CreatedAtAction(nameof(GetById), new { id = material.MaterialId },
                new { success = true, data = material, message = "Tạo nguyên liệu thành công!" });
        }

        // PUT: api/Materials/5
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, Material material)
        {
            if (id != material.MaterialId)
                return BadRequest(new { success = false, message = "ID không khớp." });

            var existing = await _unitOfWork.Materials.GetByIdAsync(id);
            if (existing == null)
                return NotFound(new { success = false, message = "Không tìm thấy nguyên liệu." });

            // Map tất cả các trường có thể update
            existing.MaterialCode = material.MaterialCode;
            existing.MaterialName = material.MaterialName;
            existing.Type = material.Type;
            existing.Description = material.Description;
            existing.BaseUomId = material.BaseUomId;
            existing.IsActive = material.IsActive;

            _unitOfWork.Materials.Update(existing);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, message = "Cập nhật thành công!", materialId = id });
        }

        // DELETE: api/Materials/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var material = await _unitOfWork.Materials.GetByIdAsync(id);
            if (material == null)
                return NotFound(new { success = false, message = "Không tìm thấy nguyên liệu." });

            _unitOfWork.Materials.Remove(material);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, message = "Đã xóa nguyên liệu." });
        }
    }
}