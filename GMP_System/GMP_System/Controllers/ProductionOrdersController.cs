using GMP_System.Entities;
using GMP_System.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace GMP_System.Controllers
{
    [Route("api/production-orders")]
    [ApiController]
    public class ProductionOrdersController : ControllerBase
    {
        private readonly IUnitOfWork _unitOfWork;

        public ProductionOrdersController(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        // 1. Lấy danh sách lệnh sản xuất
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var orders = await _unitOfWork.ProductionOrders.GetAllAsync();
            // Wrap in PaginatedResponse format expected by frontend
            return Ok(new { data = orders, totalCount = orders.Count(), success = true, message = "Success" });
        }

        // 1.5 Lấy danh sách Mẻ thuộc Lệnh sản xuất
        [HttpGet("{orderId}/batches")]
        public async Task<IActionResult> GetBatchesByOrder(int orderId)
        {
            // Tạm thời lấy tất cả và filter, nếu Repository chưa có hàm GetBatchesByOrderAsync
            var allBatches = await _unitOfWork.ProductionBatches.GetAllAsync();
            var batches = allBatches.Where(b => b.OrderId == orderId).ToList();
            return Ok(new { data = batches, success = true, message = "Success" }); // Wrap by ApiResponse format if needed, but the original returns raw array according to other APIs
        }

        // 2. Tạo Lệnh Sản Xuất Mới
        [HttpPost]
        public async Task<IActionResult> Create(ProductionOrder order)
        {
            // SỬA LỖI 1: Kiểm tra RecipeId (int?) trước khi dùng
            if (order.RecipeId == null)
            {
                return BadRequest("Lỗi: Vui lòng nhập ID công thức (RecipeId).");
            }

            // Dùng .Value để lấy giá trị int thật sự
            var recipe = await _unitOfWork.Recipes.GetByIdAsync(order.RecipeId.Value);

            if (order.PlannedQuantity <= 0)
                return BadRequest("Số lượng kế hoạch phải lớn hơn 0");

            if (recipe == null)
            {
                return BadRequest($"Lỗi: Không tìm thấy Công thức có ID = {order.RecipeId}");
            }

            // Tự động điền dữ liệu
            order.Status = "Draft";
            order.CreatedAt = DateTime.Now;

            // SỬA LỖI 2: Xử lý ngày tháng (DateTime?)
            if (!order.StartDate.HasValue) order.StartDate = DateTime.Now;

            // Phải dùng .Value thì mới cộng ngày được
            if (!order.EndDate.HasValue) order.EndDate = order.StartDate.Value.AddDays(2);

            // Lưu vào DB
            await _unitOfWork.ProductionOrders.AddAsync(order);
            await _unitOfWork.CompleteAsync();

            return Ok(new
            {
                Message = "Tạo lệnh sản xuất thành công!",
                ProductionOrderId = order.OrderId, // Đảm bảo tên biến đúng với Entity
                Status = order.Status
            });
        }
    }
}