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
        private readonly GmpContext _context;

        public ProductionOrdersController(IUnitOfWork unitOfWork, GmpContext context)
        {
            _unitOfWork = unitOfWork;
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var orders = await _unitOfWork.ProductionOrders
                .Query()
                .Include(o => o.CreatedByNavigation)
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
                    o.CreatedBy,
                    CreatedByName = o.CreatedByNavigation == null ? null : o.CreatedByNavigation.FullName,
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
                .OrderBy(b => b.BatchId)
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

        [HttpGet("{orderId}/routings")]
        public async Task<IActionResult> GetCustomRoutings(int orderId)
        {
            var order = await _unitOfWork.ProductionOrders.GetByIdAsync(orderId);
            if (order == null) return NotFound(new { success = false, message = "Không tìm thấy lệnh sản xuất." });

            var routings = await _unitOfWork.RecipeRoutings.Query()
                .Where(r => r.OrderId == orderId)
                .Include(r => r.StepParameters)
                .OrderBy(r => r.StepNumber)
                .ToListAsync();

            // If no custom routings, fallback to Recipe routings (for preview/initial state)
            if (!routings.Any() && order.RecipeId.HasValue)
            {
                routings = await _unitOfWork.RecipeRoutings.Query()
                    .Where(r => r.RecipeId == order.RecipeId && r.OrderId == null)
                    .Include(r => r.StepParameters)
                    .OrderBy(r => r.StepNumber)
                    .AsNoTracking()
                    .ToListAsync();
            }

            return Ok(new { success = true, data = routings });
        }

        [HttpPost("{orderId}/routings")]
        public async Task<IActionResult> SaveCustomRoutings(int orderId, [FromBody] List<RecipeRouting> routings)
        {
            var order = await _unitOfWork.ProductionOrders.GetByIdAsync(orderId);
            if (order == null) return NotFound(new { success = false, message = "Không tìm thấy lệnh sản xuất." });

            // Remove existing custom routings for this order
            var existing = await _unitOfWork.RecipeRoutings.Query()
                .Where(r => r.OrderId == orderId)
                .ToListAsync();
            
            foreach (var r in existing)
            {
                _unitOfWork.RecipeRoutings.Remove(r);
            }

            // Add new custom routings
            foreach (var r in routings)
            {
                r.RoutingId = 0; // Ensure new ID
                r.OrderId = orderId;
                r.RecipeId = order.RecipeId;
                
                // Clear links to avoid EF issues
                r.Order = null;
                r.Recipe = null;
                r.DefaultEquipment = null;
                r.Area = null;
                r.BatchProcessLogs = new List<BatchProcessLog>();

                await _unitOfWork.RecipeRoutings.AddAsync(r);
            }

            await _unitOfWork.CompleteAsync();
            return Ok(new { success = true, message = "Đã cập nhật cấu hình công đoạn cho lệnh sản xuất." });
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] ProductionOrder order)
        {
            if (string.IsNullOrWhiteSpace(order.OrderCode))
            {
                // Auto-generate if missing
                order.OrderCode = $"PO-{DateTime.Now:yyyyMMdd}-{new Random().Next(1000, 9999)}";
            }

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
            if (string.IsNullOrWhiteSpace(order.OrderCode))
            {
                order.OrderCode = BuildUniqueOrderCode();
            }
            else
            {
                order.OrderCode = await EnsureUniqueOrderCodeAsync(order.OrderCode);
            }

            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (int.TryParse(userIdClaim, out var userId))
            {
                order.CreatedBy = userId;
            }

            await using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var shortages = await DeductInventoryForOrderAsync(order.RecipeId.Value, order.PlannedQuantity);
                if (shortages.Count > 0)
                {
                    await transaction.RollbackAsync();
                    return BadRequest(new
                    {
                        success = false,
                        message = "Khong du nguyen lieu ton kho de tao lenh san xuat.",
                        shortages
                    });
                }

                await _unitOfWork.ProductionOrders.AddAsync(order);
                await _unitOfWork.CompleteAsync();

                // Auto-split into batches if not already present
                if (order.RecipeId.HasValue && order.PlannedQuantity > 0)
                {
                    var recipes = await _unitOfWork.Recipes.Query().FirstOrDefaultAsync(r => r.RecipeId == order.RecipeId);
                    decimal batchSize = recipes?.BatchSize ?? 0;
                    
                    var existingBatches = await _unitOfWork.ProductionBatches.Query().AnyAsync(b => b.OrderId == order.OrderId);
                    if (!existingBatches)
                    {
                        int numBatches = 1;
                        if (batchSize > 0)
                        {
                            numBatches = (int)Math.Ceiling(order.PlannedQuantity / batchSize);
                        }

                        for (int i = 0; i < numBatches; i++)
                        {
                            string batchNumber = $"{order.OrderCode.Replace("PO", "B")}-{(i + 1):D2}";
                            await _unitOfWork.ProductionBatches.AddAsync(new ProductionBatch
                            {
                                OrderId = order.OrderId,
                                BatchNumber = batchNumber,
                                Status = i == 0 ? "In-Process" : "Scheduled",
                                CurrentStep = 0,
                                ManufactureDate = DateTime.Now
                            });
                        }
                        await _unitOfWork.CompleteAsync();
                    }
                }

                await transaction.CommitAsync();
            }
            catch (DbUpdateException ex)
            {
                await transaction.RollbackAsync();
                return BadRequest(new
                {
                    success = false,
                    message = $"Không thể tạo lệnh sản xuất: {GetInnermostMessage(ex)}"
                });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, new
                {
                    success = false,
                    message = $"Không thể tạo lệnh sản xuất: {ex.Message}"
                });
            }

            return Ok(new { success = true, message = "Tạo lệnh sản xuất thành công.", data = new { orderId = order.OrderId, status = order.Status } });
        }

        private async Task<string> EnsureUniqueOrderCodeAsync(string requestedCode)
        {
            var normalized = requestedCode.Trim();
            if (string.IsNullOrWhiteSpace(normalized))
            {
                return BuildUniqueOrderCode();
            }

            var exists = await _context.ProductionOrders.AnyAsync(x => x.OrderCode == normalized);
            if (!exists)
            {
                return normalized;
            }

            for (var i = 1; i <= 999; i++)
            {
                var candidate = $"{normalized}-{i:000}";
                var taken = await _context.ProductionOrders.AnyAsync(x => x.OrderCode == candidate);
                if (!taken)
                {
                    return candidate;
                }
            }

            return BuildUniqueOrderCode();
        }

        private static string BuildUniqueOrderCode()
        {
            var now = DateTime.Now;
            return $"PO-{now:yyyyMMdd-HHmmss}-{now:fff}";
        }

        private static string GetInnermostMessage(Exception ex)
        {
            var current = ex;
            while (current.InnerException != null)
            {
                current = current.InnerException;
            }

            return current.Message;
        }

        private sealed class InventoryShortageDto
        {
            public int MaterialId { get; set; }
            public string MaterialCode { get; set; } = string.Empty;
            public string MaterialName { get; set; } = string.Empty;
            public decimal RequiredKg { get; set; }
            public decimal AvailableKg { get; set; }
        }

        private async Task<List<InventoryShortageDto>> DeductInventoryForOrderAsync(int recipeId, decimal plannedQuantity)
        {
            var bomItems = await _context.RecipeBoms
                .Where(b => b.RecipeId == recipeId && b.MaterialId != null && b.Quantity > 0)
                .Include(b => b.Material)
                .ToListAsync();

            var shortages = new List<InventoryShortageDto>();
            if (bomItems.Count == 0)
            {
                return shortages;
            }

            foreach (var bom in bomItems)
            {
                var materialId = bom.MaterialId!.Value;
                var requiredKg = CalculateRequiredKg(plannedQuantity, bom.Quantity, bom.WastePercentage);
                if (requiredKg <= 0)
                {
                    continue;
                }

                var lots = await _context.InventoryLots
                    .Where(l => l.MaterialId == materialId && l.QuantityCurrent > 0)
                    .OrderBy(l => l.ExpiryDate)
                    .ThenBy(l => l.ManufactureDate)
                    .ThenBy(l => l.LotId)
                    .ToListAsync();

                var availableKg = lots.Sum(l => l.QuantityCurrent);
                if (availableKg < requiredKg)
                {
                    shortages.Add(new InventoryShortageDto
                    {
                        MaterialId = materialId,
                        MaterialCode = bom.Material?.MaterialCode ?? string.Empty,
                        MaterialName = bom.Material?.MaterialName ?? string.Empty,
                        RequiredKg = decimal.Round(requiredKg, 4, MidpointRounding.AwayFromZero),
                        AvailableKg = decimal.Round(availableKg, 4, MidpointRounding.AwayFromZero)
                    });
                    continue;
                }

                var remaining = requiredKg;
                foreach (var lot in lots)
                {
                    if (remaining <= 0)
                    {
                        break;
                    }

                    var deduct = Math.Min(lot.QuantityCurrent, remaining);
                    lot.QuantityCurrent = decimal.Round(lot.QuantityCurrent - deduct, 4, MidpointRounding.AwayFromZero);
                    remaining -= deduct;
                }
            }

            if (shortages.Count == 0)
            {
                await _unitOfWork.CompleteAsync();
            }

            return shortages;
        }

        private static decimal CalculateRequiredKg(decimal plannedQuantity, decimal mgPerUnit, decimal? wastePercentage)
        {
            var baseKg = (plannedQuantity * mgPerUnit) / 1_000_000m;
            var wasteFactor = 1m + ((wastePercentage ?? 0m) / 100m);
            return decimal.Round(baseKg * wasteFactor, 6, MidpointRounding.AwayFromZero);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] ProductionOrder order)
        {
            var existing = await _unitOfWork.ProductionOrders.GetByIdAsync(id);
            if (existing == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy lệnh sản xuất." });
            }

            // Only overwrite each field if caller provided a non-default value
            if (!string.IsNullOrWhiteSpace(order.OrderCode))
                existing.OrderCode = order.OrderCode;

            if (order.RecipeId.HasValue && order.RecipeId.Value > 0)
                existing.RecipeId = order.RecipeId;

            if (order.PlannedQuantity > 0)
                existing.PlannedQuantity = order.PlannedQuantity;

            if (order.StartDate.HasValue)
                existing.StartDate = order.StartDate;

            if (order.EndDate.HasValue)
                existing.EndDate = order.EndDate;

            if (!string.IsNullOrWhiteSpace(order.Status))
                existing.Status = order.Status;

            _unitOfWork.ProductionOrders.Update(existing);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, message = "Cập nhật thành công.", orderId = id });
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
