using GMP_System.Entities;
using GMP_System.Interfaces;
using Microsoft.AspNetCore.Mvc;

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

        // 1. Lấy danh sách công thức (Kèm theo chi tiết BOM)
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            // Lưu ý: Mặc định GenericRepository chỉ lấy bảng chính.
            // Để lấy cả BOM, ta cần sửa Repository hoặc dùng Include (sẽ hướng dẫn sau).
            // Tạm thời lấy danh sách Recipe cơ bản.
            var recipes = await _unitOfWork.Recipes.GetAllAsync();
            return Ok(recipes);
        }

        // 2. Tạo công thức mới (Kèm danh sách nguyên liệu BOM)
        // Đây là chức năng quan trọng nhất để test Transaction
        [HttpPost]
        public async Task<IActionResult> Create(Recipe recipe)
        {
            // Logic kiểm tra GMP cơ bản
            if (recipe.BatchSize <= 0)
            {
                return BadRequest("Kích thước lô (BatchSize) phải lớn hơn 0");
            }

            // Gán trạng thái mặc định
            recipe.Status = "Draft";
            recipe.VersionNumber = 1; // Phiên bản đầu tiên
            recipe.CreatedAt = DateTime.Now;

            // UnitOfWork sẽ tự động xử lý việc thêm Recipe VÀ thêm các RecipeBoms đi kèm
            await _unitOfWork.Recipes.AddAsync(recipe);

            // Lưu xuống DB (Nếu lỗi ở bất kỳ dòng BOM nào, nó sẽ Rollback hết -> An toàn tuyệt đối)
            await _unitOfWork.CompleteAsync();

            return Ok(recipe);
        }

        // 3. Duyệt công thức (Chỉ Admin/QA mới được làm)
        [HttpPost("{id}/approve")]
        public async Task<IActionResult> Approve(int id)
        {
            var recipe = await _unitOfWork.Recipes.GetByIdAsync(id);
            if (recipe == null) return NotFound();

            if (recipe.Status != "Draft")
                return BadRequest("Chỉ có thể duyệt công thức đang ở trạng thái Nháp (Draft)");

            recipe.Status = "Approved";
            recipe.ApprovedDate = DateTime.Now;
            // recipe.ApprovedBy = ... (Lấy từ Token người đăng nhập - làm sau)

            _unitOfWork.Recipes.Update(recipe);
            await _unitOfWork.CompleteAsync();

            return Ok(new { message = "Đã duyệt công thức thành công!", recipeId = id });
        }
    }
}