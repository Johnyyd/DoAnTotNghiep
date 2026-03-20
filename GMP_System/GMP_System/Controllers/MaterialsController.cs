using GMP_System.Entities;
using GMP_System.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace GMP_System.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class MaterialsController : ControllerBase
    {
        private readonly IUnitOfWork _unitOfWork;

        // Inject UnitOfWork vào đây (kỹ thuật Dependency Injection)
        public MaterialsController(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        // GET: api/Materials
        // Lấy danh sách tất cả nguyên liệu
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var materials = await _unitOfWork.Materials.GetAllAsync();
            return Ok(new { data = materials, success = true, message = "Success" });
        }

        // GET: api/Materials/5
        // Lấy chi tiết 1 nguyên liệu theo ID
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var material = await _unitOfWork.Materials.GetByIdAsync(id);
            if (material == null)
            {
                return NotFound($"Không tìm thấy nguyên liệu có ID = {id}");
            }
            return Ok(material);
        }

        // POST: api/Materials
        // Tạo mới nguyên liệu
        [HttpPost]
        public async Task<IActionResult> Create(Material material)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            await _unitOfWork.Materials.AddAsync(material);
            await _unitOfWork.CompleteAsync(); // Lưu xuống SQL

            return CreatedAtAction(nameof(GetById), new { id = material.MaterialId }, material);
        }

        // 3. Cập nhật Nguyên liệu (Để test Audit Log: Modified)
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, Material material)
        {
            // Kiểm tra ID gửi lên có khớp không
            if (id != material.MaterialId)
                return BadRequest("Lỗi: ID trên URL và trong Body không khớp nhau.");

            // 1. Lấy dữ liệu cũ từ Database
            var existingMaterial = await _unitOfWork.Materials.GetByIdAsync(id);
            if (existingMaterial == null) return NotFound("Không tìm thấy nguyên liệu này.");

            // 2. Cập nhật các thông tin mới
            // (EF Core sẽ tự động nhận biết sự thay đổi giữa existingMaterial và giá trị mới gán vào)
            existingMaterial.MaterialCode = material.MaterialCode;
            existingMaterial.MaterialName = material.MaterialName;
            existingMaterial.Type = material.Type;
            // existingMaterial.Description = material.Description; // Nếu có

            // 3. Gọi lệnh Update trong Repository
            _unitOfWork.Materials.Update(existingMaterial);

            // 4. Lưu xuống DB -> Lúc này Interceptor sẽ nhảy vào chụp ảnh "Trước vs Sau"
            await _unitOfWork.CompleteAsync();

            return Ok(new { Message = "Cập nhật thành công!", MaterialId = id });
        }
    }
}