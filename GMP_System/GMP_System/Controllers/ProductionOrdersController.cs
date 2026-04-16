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
                .Include(o => o.ProductionBatches)
                .ToListAsync();

            // Auto-initialize batches for display if missing
            bool layoutChanged = false;
            foreach (var o in orders)
            {
                if (o.Status != "Draft" && o.Status != "Cancelled" && (o.ProductionBatches == null || !o.ProductionBatches.Any()))
                {
                    if (await InitializeBatchesForOrder(o)) layoutChanged = true;
                }
            }
            if (layoutChanged) await _unitOfWork.CompleteAsync();

            var result = orders.Select(o => new {
                o.OrderId,
                o.OrderCode,
                o.PlannedQuantity,
                o.PlannedCartons,
                o.ActualQuantity,
                o.Status,
                o.StartDate,
                o.EndDate,
                o.CreatedAt,
                Recipe = o.Recipe == null ? null : new {
                    o.Recipe.RecipeId,
                    o.Recipe.BatchSize,
                    Material = o.Recipe.Material == null ? null : new {
                        o.Recipe.Material.MaterialName,
                        UnitOfMeasure = o.Recipe.Material.BaseUom == null ? null : new {
                            o.Recipe.Material.BaseUom.UomName
                        }
                    }
                },
                ProductionBatches = o.ProductionBatches.Select(b => new {
                    b.BatchId,
                    b.BatchNumber,
                    b.Status,
                    LatestLogStatus = b.BatchProcessLogs.OrderByDescending(l => l.LogId).Select(l => l.ResultStatus).FirstOrDefault()
                })
            });

            return Ok(new { data = result, totalCount = orders.Count, success = true, message = "Success" });
        }

        // GET: api/production-orders/5
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var existing = await _unitOfWork.ProductionOrders.Query()
                .Include(o => o.Recipe)
                .Include(o => o.ProductionBatches)
                .FirstOrDefaultAsync(o => o.OrderId == id);

            if (existing == null)
                return NotFound(new { success = false, message = $"Không tìm thấy lệnh sản xuất ID={id}" });

            // Auto-initialize batches if missing
            if (existing.Status != "Draft" && existing.Status != "Cancelled" && (existing.ProductionBatches == null || !existing.ProductionBatches.Any()))
            {
                if (await InitializeBatchesForOrder(existing))
                {
                    await _unitOfWork.CompleteAsync();
                }
            }

            var orderDto = new {
                existing.OrderId,
                existing.OrderCode,
                existing.PlannedQuantity,
                // existing.PlannedCartons,
                existing.ActualQuantity,
                existing.Status,
                existing.StartDate,
                existing.EndDate,
                existing.CreatedAt,
                Recipe = existing.Recipe == null ? null : new {
                    existing.Recipe.RecipeId,
                    existing.Recipe.BatchSize,
                    existing.Recipe.Note,
                    Material = existing.Recipe.Material == null ? null : new {
                        existing.Recipe.Material.MaterialName,
                        UnitOfMeasure = existing.Recipe.Material.BaseUom == null ? null : new {
                            existing.Recipe.Material.BaseUom.UomName
                        }
                    }
                },
                ProductionBatches = existing.ProductionBatches.Select(b => new {
                    b.BatchId,
                    b.BatchNumber,
                    b.Status,
                    LatestLogStatus = b.BatchProcessLogs.OrderByDescending(l => l.LogId).Select(l => l.ResultStatus).FirstOrDefault()
                })
            };

            return Ok(new { data = orderDto, success = true, message = "Success" });
        }

        // GET: api/production-orders/{orderId}/batches
        [HttpGet("{orderId}/batches")]
        public async Task<IActionResult> GetBatchesByOrder(int orderId)
        {
            var batches = await _unitOfWork.ProductionBatches
                .Query()
                .Where(b => b.OrderId == orderId)
                .Include(b => b.MaterialUsages)
                .ToListAsync();

            return Ok(new { data = batches, success = true, message = "Success" });
        }

        // POST: api/production-orders
        [HttpPost]
        public async Task<IActionResult> Create(ProductionOrder order)
        {
            if (order.RecipeId == null)
                return BadRequest(new { success = false, message = "Vui lòng chọn công thức (RecipeId)." });

            // Logic tính toán theo yêu cầu: Lệnh dựa trên số Thùng (Cartons)
            if (order.PlannedCartons.HasValue && order.PlannedCartons > 0)
            {
                // Quy cách: 1 Thùng = 80 Chai * 40 Viên = 3200 Viên
                order.PlannedQuantity = (decimal)(order.PlannedCartons.Value * 3200);
            }

            if (order.PlannedQuantity <= 0)
                return BadRequest(new { success = false, message = "Số lượng kế hoạch (hoặc số thùng) phải lớn hơn 0." });

            var recipe = await _unitOfWork.Recipes.GetByIdAsync(order.RecipeId.Value);
            if (recipe == null)
                return BadRequest(new { success = false, message = $"Không tìm thấy công thức ID={order.RecipeId}" });

            if (recipe.Status != "Approved")
                return BadRequest(new { success = false, message = "Chỉ có thể tạo lệnh sản xuất từ công thức đã được duyệt." });

            order.Status = "Draft";
            order.CreatedAt = DateTime.Now;
            if (!order.StartDate.HasValue) order.StartDate = DateTime.Now;
            if (!order.EndDate.HasValue) order.EndDate = order.StartDate!.Value.AddDays(2);

            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (int.TryParse(userIdClaim, out var userId)) order.CreatedBy = userId;

            await _unitOfWork.ProductionOrders.AddAsync(order);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, message = "Tạo lệnh sản xuất thành công!", data = new { orderId = order.OrderId, status = order.Status, plannedQuantity = order.PlannedQuantity } });
        }

        // PATCH: api/production-orders/5/status
        [HttpPatch("{id}/status")]
        public async Task<IActionResult> UpdateStatus(int id, [FromBody] string newStatus)
        {
            if (string.IsNullOrWhiteSpace(newStatus))
                return BadRequest(new { success = false, message = "Status không được để trống." });

            var existing = await _unitOfWork.ProductionOrders.Query()
                .Include(o => o.Recipe)
                .Include(o => o.ProductionBatches)
                .FirstOrDefaultAsync(o => o.OrderId == id);

            if (existing == null)
                return NotFound(new { success = false, message = "Không tìm thấy lệnh sản xuất." });

            existing.Status = newStatus;

            // Kích hoạt chia mẻ khi Duyệt lệnh
            if (newStatus == "Approved" && (existing.ProductionBatches == null || !existing.ProductionBatches.Any()))
            {
                await InitializeBatchesForOrder(existing);
            }

            _unitOfWork.ProductionOrders.Update(existing);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, message = "Cập nhật trạng thái thành công!", orderId = id, status = newStatus });
        }

        private async Task<bool> InitializeBatchesForOrder(ProductionOrder order)
        {
            if (order.Recipe == null) return false;
            
            // Công thức chuẩn theo yêu cầu Pharma:
            // 1 viên = 540mg (0.54g)
            // 1 mẻ tối đa = 50kg (50,000g)
            // => Số viên tối đa 1 mẻ = 50,000 / 0.54 = 92,592.59... -> Lấy 92,592 viên
            const decimal tabletWeightG = 0.540m;
            const decimal maxBatchWeightG = 50000.0m;
            decimal unitsPerBatch = Math.Floor(maxBatchWeightG / tabletWeightG); // 92592
            
            // Nếu Recipe có BatchSize riêng thì ưu tiên dùng (trong demo này là 92592)
            if (order.Recipe.BatchSize > 0) unitsPerBatch = order.Recipe.BatchSize;

            decimal totalPlanned = order.PlannedQuantity;
            if (totalPlanned <= 0) return false;

            int batchCount = (int)Math.Ceiling(totalPlanned / unitsPerBatch);
            for (int i = 1; i <= batchCount; i++)
            {
                decimal qtyThisBatch = (i == batchCount) ? (totalPlanned - (unitsPerBatch * (i - 1))) : unitsPerBatch;
                if (qtyThisBatch <= 0) break;

                var newBatch = new ProductionBatch
                {
                    OrderId = order.OrderId,
                    BatchNumber = $"{order.OrderCode}-{i:D2}",
                    Status = "Scheduled",
                    PlannedQuantity = qtyThisBatch,
                    CurrentStep = 1,
                    CreatedAt = DateTime.Now
                };
                await _unitOfWork.ProductionBatches.AddAsync(newBatch);
            }
            return true;
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