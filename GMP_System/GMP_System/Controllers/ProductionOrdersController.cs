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

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var orders = await _unitOfWork.ProductionOrders
                .Query()
                .Select(o => new
                {
                    o.OrderId,
                    o.OrderCode,
                    o.RecipeId,
                    o.PlannedQuantity,
                    o.ActualQuantity,
                    o.Status,
                    o.StartDate,
                    o.EndDate,
                    o.CreatedAt,
                    Recipe = o.Recipe == null ? null : new
                    {
                        o.Recipe.RecipeId,
                        o.Recipe.BatchSize,
                        Material = o.Recipe.Material == null ? null : new
                        {
                            o.Recipe.Material.MaterialName,
                            UnitOfMeasure = o.Recipe.Material.BaseUom == null ? null : new { o.Recipe.Material.BaseUom.UomName }
                        }
                    },
                    ProductionBatches = o.ProductionBatches.Select(b => new
                    {
                        b.BatchId,
                        b.BatchNumber,
                        b.Status
                    })
                })
                .AsNoTracking()
                .ToListAsync();

            return Ok(new { data = orders, totalCount = orders.Count, success = true, message = "Success" });
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var order = await _unitOfWork.ProductionOrders
                .Query()
                .Where(o => o.OrderId == id)
                .Select(o => new
                {
                    o.OrderId,
                    o.OrderCode,
                    o.RecipeId,
                    o.PlannedQuantity,
                    o.ActualQuantity,
                    o.Status,
                    o.StartDate,
                    o.EndDate,
                    o.CreatedAt,
                    Recipe = o.Recipe == null ? null : new
                    {
                        o.Recipe.RecipeId,
                        o.Recipe.BatchSize,
                        o.Recipe.Note,
                        Material = o.Recipe.Material == null ? null : new
                        {
                            o.Recipe.Material.MaterialName,
                            UnitOfMeasure = o.Recipe.Material.BaseUom == null ? null : new { o.Recipe.Material.BaseUom.UomName }
                        }
                    },
                    ProductionBatches = o.ProductionBatches.Select(b => new
                    {
                        b.BatchId,
                        b.BatchNumber,
                        b.Status
                    })
                })
                .AsNoTracking()
                .FirstOrDefaultAsync();

            if (order == null)
            {
                return NotFound(new { success = false, message = $"Không tìm th?y l?nh s?n xu?t ID={id}" });
            }

            return Ok(new { data = order, success = true, message = "Success" });
        }

        [HttpGet("{orderId}/batches")]
        public async Task<IActionResult> GetBatchesByOrder(int orderId)
        {
            var batches = await _unitOfWork.ProductionBatches
                .Query()
                .Where(b => b.OrderId == orderId)
                .Select(b => new
                {
                    b.BatchId,
                    b.OrderId,
                    b.BatchNumber,
                    b.Status,
                    b.ManufactureDate,
                    b.EndTime,
                    b.ExpiryDate,
                    b.CurrentStep,
                    Order = b.Order == null ? null : new
                    {
                        b.Order.OrderId,
                        b.Order.OrderCode,
                        Recipe = b.Order.Recipe == null ? null : new
                        {
                            b.Order.Recipe.RecipeId,
                            Material = b.Order.Recipe.Material == null ? null : new
                            {
                                b.Order.Recipe.Material.MaterialName
                            }
                        }
                    }
                })
                .AsNoTracking()
                .ToListAsync();

            return Ok(new { data = batches, success = true, message = "Success" });
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] ProductionOrder order)
        {
            if (order.RecipeId == null)
            {
                return BadRequest(new { success = false, message = "Vui lòng ch?n công th?c (RecipeId)." });
            }

            if (order.PlannedQuantity <= 0)
            {
                return BadRequest(new { success = false, message = "S? lu?ng k? ho?ch ph?i l?n hon 0." });
            }

            var recipe = await _unitOfWork.Recipes.GetByIdAsync(order.RecipeId.Value);
            if (recipe == null)
            {
                return BadRequest(new { success = false, message = $"Không tìm th?y công th?c ID={order.RecipeId}" });
            }

            if (recipe.Status != "Approved" && recipe.Status != "Draft")
            {
                return BadRequest(new { success = false, message = "Công th?c ph?i ? tr?ng thái Draft ho?c Approved d? l?p l?nh s?n xu?t." });
            }

            order.Status = string.IsNullOrWhiteSpace(order.Status) ? "Draft" : order.Status;
            order.CreatedAt = DateTime.Now;
            if (!order.StartDate.HasValue) order.StartDate = DateTime.Now;
            if (!order.EndDate.HasValue) order.EndDate = order.StartDate!.Value.AddDays(2);

            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (int.TryParse(userIdClaim, out var userId))
            {
                order.CreatedBy = userId;
            }

            await _unitOfWork.ProductionOrders.AddAsync(order);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, message = "T?o l?nh s?n xu?t thành công.", data = new { orderId = order.OrderId, status = order.Status } });
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] ProductionOrder order)
        {
            var existing = await _unitOfWork.ProductionOrders.GetByIdAsync(id);
            if (existing == null)
            {
                return NotFound(new { success = false, message = "Không tìm th?y l?nh s?n xu?t." });
            }

            existing.OrderCode = string.IsNullOrWhiteSpace(order.OrderCode) ? existing.OrderCode : order.OrderCode;
            existing.RecipeId = order.RecipeId;
            existing.PlannedQuantity = order.PlannedQuantity;
            existing.StartDate = order.StartDate;
            existing.EndDate = order.EndDate;
            existing.Status = string.IsNullOrWhiteSpace(order.Status) ? existing.Status : order.Status;

            _unitOfWork.ProductionOrders.Update(existing);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, message = "C?p nh?t thành công.", orderId = id });
        }

        [HttpPost("{id}/approve")]
        public async Task<IActionResult> Approve(int id, [FromBody] SignatureRequest request)
        {
            var existing = await _unitOfWork.ProductionOrders.GetByIdAsync(id);
            if (existing == null)
            {
                return NotFound(new { success = false, message = "Không tìm th?y l?nh s?n xu?t." });
            }

            if (existing.Status != "Draft")
            {
                return BadRequest(new { success = false, message = "Ch? có th? duy?t l?nh ? tr?ng thái Draft." });
            }

            if (string.IsNullOrWhiteSpace(request.Signature))
            {
                return BadRequest(new { success = false, message = "Thi?u ch? ký di?n t?." });
            }

            existing.Status = "Approved";
            _unitOfWork.ProductionOrders.Update(existing);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, message = "Duy?t l?nh s?n xu?t thành công." });
        }

        [HttpPost("{id}/hold")]
        public async Task<IActionResult> Hold(int id, [FromBody] HoldRequest request)
        {
            var existing = await _unitOfWork.ProductionOrders.GetByIdAsync(id);
            if (existing == null)
            {
                return NotFound(new { success = false, message = "Không tìm th?y l?nh s?n xu?t." });
            }

            if (string.IsNullOrWhiteSpace(request.Reason))
            {
                return BadRequest(new { success = false, message = "Vui lòng nh?p lý do t?m ngung." });
            }

            existing.Status = "Hold";
            _unitOfWork.ProductionOrders.Update(existing);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, message = "Ðã t?m ngung l?nh s?n xu?t." });
        }

        [HttpPost("{id}/resume")]
        public async Task<IActionResult> Resume(int id)
        {
            var existing = await _unitOfWork.ProductionOrders.GetByIdAsync(id);
            if (existing == null)
            {
                return NotFound(new { success = false, message = "Không tìm th?y l?nh s?n xu?t." });
            }

            existing.Status = "InProcess";
            _unitOfWork.ProductionOrders.Update(existing);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, message = "Ðã m? l?i l?nh s?n xu?t." });
        }

        [HttpPost("{id}/complete")]
        public async Task<IActionResult> Complete(int id, [FromBody] SignatureRequest request)
        {
            var existing = await _unitOfWork.ProductionOrders.GetByIdAsync(id);
            if (existing == null)
            {
                return NotFound(new { success = false, message = "Không tìm th?y l?nh s?n xu?t." });
            }

            if (string.IsNullOrWhiteSpace(request.Signature))
            {
                return BadRequest(new { success = false, message = "Thi?u ch? ký di?n t? xác nh?n hoàn thành." });
            }

            existing.Status = "Completed";
            _unitOfWork.ProductionOrders.Update(existing);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, message = "Ðã hoàn thành l?nh s?n xu?t." });
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var order = await _unitOfWork.ProductionOrders.GetByIdAsync(id);
            if (order == null)
            {
                return NotFound(new { success = false, message = "Không tìm th?y l?nh s?n xu?t." });
            }

            _unitOfWork.ProductionOrders.Remove(order);
            await _unitOfWork.CompleteAsync();
            return Ok(new { success = true, message = "Ðã xóa l?nh s?n xu?t." });
        }
    }

    public class SignatureRequest
    {
        public string Signature { get; set; } = string.Empty;
    }

    public class HoldRequest
    {
        public string Reason { get; set; } = string.Empty;
    }
}
