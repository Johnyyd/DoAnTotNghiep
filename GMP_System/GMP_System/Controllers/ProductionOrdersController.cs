using GMP_System.Entities;
using GMP_System.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

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

        // GET: api/production-orders
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var orders = await _unitOfWork.ProductionOrders
                .Query()
                .Include(o => o.Recipe)
                    .ThenInclude(r => r!.Material)
                .Include(o => o.Recipe)
                    .ThenInclude(r => r!.RecipeBoms)
                        .ThenInclude(b => b.Material)
                .Include(o => o.Recipe)
                    .ThenInclude(r => r!.RecipeBoms)
                        .ThenInclude(b => b.Uom)
                .Include(o => o.CreatedByNavigation)
                .Include(o => o.ProductionBatches)
                .ToListAsync();

            return Ok(new { data = orders, totalCount = orders.Count, success = true, message = "Success" });
        }

        // GET: api/production-orders/5
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var order = await _unitOfWork.ProductionOrders
                .Query()
                .Include(o => o.Recipe)
                    .ThenInclude(r => r!.Material)
                .Include(o => o.Recipe)
                    .ThenInclude(r => r!.RecipeBoms)
                        .ThenInclude(b => b.Material)
                .Include(o => o.Recipe)
                    .ThenInclude(r => r!.RecipeBoms)
                        .ThenInclude(b => b.Uom)
                .Include(o => o.ProductionBatches)
                .Include(o => o.CreatedByNavigation)
                .FirstOrDefaultAsync(o => o.OrderId == id);

            if (order == null)
                return NotFound(new { success = false, message = $"Không tìm thấy lệnh sản xuất ID={id}" });

            return Ok(new { data = order, success = true, message = "Success" });
        }

        // GET: api/production-orders/{orderId}/batches
        [HttpGet("{orderId}/batches")]
        public async Task<IActionResult> GetBatchesByOrder(int orderId)
        {
            var batches = await _unitOfWork.ProductionBatches
                .Query()
                .Where(b => b.OrderId == orderId)
                .Include(b => b.MaterialUsages)
                    .ThenInclude(u => u.InventoryLot)
                        .ThenInclude(l => l!.Material)
                .ToListAsync();

            return Ok(new { data = batches, success = true, message = "Success" });
        }

        // POST: api/production-orders
        [HttpPost]
        public async Task<IActionResult> Create(ProductionOrder order)
        {
            if (order.RecipeId == null)
                return BadRequest(new { success = false, message = "Vui lòng chọn công thức (RecipeId)." });

            if (order.PlannedQuantity <= 0)
                return BadRequest(new { success = false, message = "Số lượng kế hoạch phải lớn hơn 0." });

            var recipe = await _unitOfWork.Recipes.GetByIdAsync(order.RecipeId.Value);
            if (recipe == null)
                return BadRequest(new { success = false, message = $"Không tìm thấy công thức ID={order.RecipeId}" });

            if (recipe.Status != "Approved")
                return BadRequest(new { success = false, message = "Chỉ có thể tạo lệnh sản xuất từ công thức đã được duyệt." });

            order.Status = "Draft";
            order.CreatedAt = DateTime.Now;
            if (!order.StartDate.HasValue) order.StartDate = DateTime.Now;
            if (!order.EndDate.HasValue) order.EndDate = order.StartDate!.Value.AddDays(2);

            // Lấy UserId từ JWT để gán CreatedBy
            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (int.TryParse(userIdClaim, out var userId)) order.CreatedBy = userId;

            await _unitOfWork.ProductionOrders.AddAsync(order);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, message = "Tạo lệnh sản xuất thành công!", data = new { orderId = order.OrderId, status = order.Status } });
        }

        // PUT: api/production-orders/5
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, ProductionOrder order)
        {
            var existing = await _unitOfWork.ProductionOrders.GetByIdAsync(id);
            if (existing == null)
                return NotFound(new { success = false, message = "Không tìm thấy lệnh sản xuất." });

            if (existing.Status != "Draft")
                return BadRequest(new { success = false, message = "Chỉ có thể chỉnh sửa lệnh ở trạng thái Draft." });

            existing.PlannedQuantity = order.PlannedQuantity;
            existing.StartDate = order.StartDate;
            existing.EndDate = order.EndDate;

            _unitOfWork.ProductionOrders.Update(existing);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, message = "Cập nhật thành công!", orderId = id });
        }

        // PATCH: api/production-orders/5/status
        [HttpPatch("{id}/status")]
        public async Task<IActionResult> UpdateStatus(int id, [FromBody] string newStatus)
        {
            if (string.IsNullOrWhiteSpace(newStatus))
                return BadRequest(new { success = false, message = "Status không được để trống." });

            var existing = await _unitOfWork.ProductionOrders.GetByIdAsync(id);
            if (existing == null)
                return NotFound(new { success = false, message = "Không tìm thấy lệnh sản xuất." });

            existing.Status = newStatus;
            _unitOfWork.ProductionOrders.Update(existing);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, message = "Cập nhật trạng thái thành công!", orderId = id, status = newStatus });
        }

        // DELETE: api/production-orders/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var order = await _unitOfWork.ProductionOrders.GetByIdAsync(id);
            if (order == null)
                return NotFound(new { success = false, message = "Không tìm thấy lệnh sản xuất." });

            if (order.Status != "Draft")
                return BadRequest(new { success = false, message = "Chỉ có thể xóa lệnh ở trạng thái Draft." });

            _unitOfWork.ProductionOrders.Remove(order);
            await _unitOfWork.CompleteAsync();
            return Ok(new { success = true, message = "Đã xóa lệnh sản xuất." });
        }
    }
}