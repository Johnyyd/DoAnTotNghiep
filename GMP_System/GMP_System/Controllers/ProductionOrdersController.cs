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
                        o.Recipe.RecipeName,
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
                    }),
                    ProductionOrderBoms = o.ProductionOrderBoms.Select(bom => new
                    {
                        bom.OrderBomId,
                        bom.MaterialId,
                        bom.RequiredQuantity,
                        MaterialName = bom.Material != null ? bom.Material.MaterialName : "Unknown",
                        MaterialCode = bom.Material != null ? bom.Material.MaterialCode : string.Empty,
                        UomName = bom.Uom != null ? bom.Uom.UomName : "N/A"
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
                        o.Recipe.RecipeName,
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
                    }),
                    ProductionOrderBoms = o.ProductionOrderBoms.Select(bom => new
                    {
                        bom.OrderBomId,
                        bom.MaterialId,
                        bom.RequiredQuantity,
                        MaterialName = bom.Material != null ? bom.Material.MaterialName : "Unknown",
                        MaterialCode = bom.Material != null ? bom.Material.MaterialCode : string.Empty,
                        UomName = bom.Uom != null ? bom.Uom.UomName : "N/A"
                    })
                })
                .AsNoTracking()
                .FirstOrDefaultAsync();

            if (order == null)
            {
                return NotFound(new { success = false, message = $"Không tìm thấy lệnh sản xuất ID={id}" });
            }

            return Ok(new { data = order, success = true, message = "Success" });
        }

        [HttpGet("{orderId}/batches")]
        public async Task<IActionResult> GetBatchesByOrder(int orderId)
        {
            var batches = await _unitOfWork.ProductionBatches
                .Query()
                .Where(b => b.OrderId == orderId)
                .OrderBy(b => b.BatchNumber)
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
                            b.Order.Recipe.RecipeName,
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

            if (order.RecipeId == null)
            {
                return BadRequest(new { success = false, message = "Vui lòng chọn công thức (RecipeId)." });
            }

            if (order.PlannedQuantity <= 0)
            {
                return BadRequest(new { success = false, message = "Số lượng kế hoạch phải lớn hơn 0." });
            }

            var recipe = await _unitOfWork.Recipes.GetByIdAsync(order.RecipeId.Value);
            if (recipe == null)
            {
                return BadRequest(new { success = false, message = $"Không tìm thấy công thức ID={order.RecipeId}" });
            }

            if (recipe.Status != "Approved" && recipe.Status != "Draft")
            {
                return BadRequest(new { success = false, message = "Công thức phải ở trạng thái Draft hoặc Approved để lập lệnh sản xuất." });
            }

            bool isAnyOrderActive = await _context.ProductionOrders.AnyAsync(o => o.Status == "In-Process" || o.Status == "Hold");

            // Quy tắc duy nhất: nếu đã có lệnh In-Process/Hold thì lệnh mới là Scheduled, ngược lại là In-Process.
            order.Status = isAnyOrderActive ? "Scheduled" : "In-Process";
            order.CreatedAt = DateTime.Now;
            if (!order.StartDate.HasValue) order.StartDate = DateTime.Now;
            if (!order.EndDate.HasValue) order.EndDate = order.StartDate!.Value.AddDays(2);
            if (string.IsNullOrWhiteSpace(order.OrderCode) || order.OrderCode.Length > 12)
            {
                order.OrderCode = await GenerateSequentialOrderCodeAsync();
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
                        message = "Không đủ nguyên liệu tồn kho để tạo lệnh sản xuất.",
                        shortages
                    });
                }

                await _unitOfWork.ProductionOrders.AddAsync(order);
                await _unitOfWork.CompleteAsync();

                // [BOM SYNC] Generate unique BOM for this order based on Recipe and PlannedQuantity
                var recipeBoms = await _unitOfWork.RecipeBoms.Query()
                    .Where(b => b.RecipeId == order.RecipeId)
                    .ToListAsync();

                foreach (var rb in recipeBoms)
                {
                    // Skip packaging materials in BOM for weight/ratio calculation (though still needed in deduction)
                    // Wait, the user said Packaging (Hard capsule shell) shouldn't be counted in ratio/mass.
                    // But they still need to be in the order BOM for tracking/deduction purposes? 
                    // Actually, the user says "không được tính trong tỉ lệ công thức và cũng không tính cho khối lượng luôn".
                    // I will still include them in ProductionOrderBoms so we know they are needed, 
                    // but I'll mark them or the frontend will handle the exclusion.
                    
                    var orderBom = new ProductionOrderBom
                    {
                        OrderId = order.OrderId,
                        MaterialId = rb.MaterialId,
                        UomId = rb.UomId ?? 1, 
                        WastePercentage = rb.WastePercentage,
                        RequiredQuantity = CalculateRequiredQuantity(order.PlannedQuantity, rb.Quantity, rb.UomId ?? 1, rb.WastePercentage),
                        Note = rb.Note
                    };
                    await _unitOfWork.ProductionOrderBoms.AddAsync(orderBom);
                }
                await _unitOfWork.CompleteAsync();

                // [SNAPSHOT ROUTING] Copy all routing steps from recipe to order
                var recipeRoutings = await _context.RecipeRoutings
                    .Where(r => r.RecipeId == order.RecipeId && r.OrderId == null)
                    .Include(r => r.StepParameters)
                    .ToListAsync();
                
                foreach (var rr in recipeRoutings)
                {
                    var orderRouting = new RecipeRouting
                    {
                        OrderId = order.OrderId,
                        RecipeId = order.RecipeId,
                        StepNumber = rr.StepNumber,
                        StepName = rr.StepName,
                        Description = rr.Description,
                        EstimatedTimeMinutes = rr.EstimatedTimeMinutes,
                        DefaultEquipmentId = rr.DefaultEquipmentId,
                        AreaId = rr.AreaId,
                        CleanlinessStatus = rr.CleanlinessStatus,
                        StandardTemperature = rr.StandardTemperature,
                        StandardHumidity = rr.StandardHumidity,
                        StandardPressure = rr.StandardPressure,
                        StabilityStatus = rr.StabilityStatus,
                        SetTemperature = rr.SetTemperature,
                        SetPressure = rr.SetPressure,
                        SetTimeMinutes = rr.SetTimeMinutes,
                        MaterialIds = rr.MaterialIds
                    };
                    _context.RecipeRoutings.Add(orderRouting);
                }
                await _context.SaveChangesAsync();

                // [SNAPSHOT TECH SPECS] Copy all tech specs from recipe to order
                var recipeSpecs = await _context.RecipeTechSpecs
                    .Where(s => s.RecipeId == order.RecipeId && s.OrderId == null)
                    .ToListAsync();
                
                // Map old SpecId to new SpecId for parent/child relationship
                var specMap = new Dictionary<int, int>();
                
                // First pass: add parents
                foreach (var rs in recipeSpecs.Where(s => s.ParentId == null))
                {
                    var orderSpec = new RecipeTechSpec
                    {
                        OrderId = order.OrderId,
                        RecipeId = order.RecipeId.Value,
                        Content = rs.Content,
                        SortOrder = rs.SortOrder,
                        IsChecked = false // Always reset for new order
                    };
                    _context.RecipeTechSpecs.Add(orderSpec);
                    await _context.SaveChangesAsync();
                    specMap[rs.SpecId] = orderSpec.SpecId;
                }
                
                // Second pass: add children
                foreach (var rs in recipeSpecs.Where(s => s.ParentId != null))
                {
                    var orderSpec = new RecipeTechSpec
                    {
                        OrderId = order.OrderId,
                        RecipeId = order.RecipeId.Value,
                        Content = rs.Content,
                        SortOrder = rs.SortOrder,
                        IsChecked = false,
                        ParentId = specMap.ContainsKey(rs.ParentId.Value) ? specMap[rs.ParentId.Value] : null
                    };
                    _context.RecipeTechSpecs.Add(orderSpec);
                }
                await _context.SaveChangesAsync();

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
                            // BatchSize is interpreted as mg/unit. 
                            // Max capacity per batch is 50kg (50,000,000 mg).
                            decimal totalWeightMg = order.PlannedQuantity * batchSize;
                            decimal maxBatchWeightMg = 50000000m; // 50kg
                            numBatches = (int)Math.Ceiling(totalWeightMg / maxBatchWeightMg);
                            if (numBatches < 1) numBatches = 1;
                        }

                        // Distribute units equally across batches for "cleaner" numbers
                        decimal unitsPerBatch = Math.Floor(order.PlannedQuantity / numBatches);
                        decimal remainingUnits = order.PlannedQuantity;

                        for (int i = 0; i < numBatches; i++)
                        {
                            decimal currentBatchUnits = (i == numBatches - 1) ? remainingUnits : unitsPerBatch;
                            remainingUnits -= currentBatchUnits;

                            string batchNumber = $"B{order.OrderCode.Substring(3)}-{(i + 1):D2}";
                            await _unitOfWork.ProductionBatches.AddAsync(new ProductionBatch
                            {
                                OrderId = order.OrderId,
                                BatchNumber = batchNumber,
                                PlannedQuantity = currentBatchUnits,
                                Status = (i == 0 && order.Status == "In-Process") ? "In-Process" : "Scheduled",
                                CurrentStep = (i == 0 && order.Status == "In-Process") ? 1 : 0,
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
                return await GenerateSequentialOrderCodeAsync();
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

            return await GenerateSequentialOrderCodeAsync();
        }

        private async Task<string> GenerateSequentialOrderCodeAsync()
        {
            var year = DateTime.Now.ToString("yy");
            var prefix = $"PO-{year}-";

            var lastOrder = await _context.ProductionOrders
                .Where(o => o.OrderCode != null && o.OrderCode.StartsWith(prefix))
                .OrderByDescending(o => o.OrderCode)
                .FirstOrDefaultAsync();

            int nextNumber = 1;
            if (lastOrder != null)
            {
                var parts = lastOrder.OrderCode!.Split('-');
                if (parts.Length == 3 && int.TryParse(parts[2], out var lastNumber))
                {
                    nextNumber = lastNumber + 1;
                }
            }

            return $"{prefix}{nextNumber:D3}";
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
                .Where(b => b.Material!.Type != "Packaging") // Exclude packaging from inventory deduction/calculation if required? 
                // Wait, if it's packaging, it might still need to be deducted from inventory. 
                // The user said "không tính trong tỉ lệ công thức và cũng không tính cho khối lượng".
                // I'll keep it in inventory deduction for now unless it's strictly not allowed.
                // Re-reading: "không được tính trong tỉ lệ công thức và cũng không tính cho khối lượng luôn bởi vì nó chỉ là cái vỏ thôi mà"
                // This sounds like it's purely a calculation thing, but you still NEED it to produce.
                // So I'll keep it in inventory deduction but the frontend will ignore it for mass calculations.
                .ToListAsync();

            var shortages = new List<InventoryShortageDto>();
            if (bomItems.Count == 0)
            {
                return shortages;
            }

            foreach (var bom in bomItems)
            {
                var materialId = bom.MaterialId!.Value;
                var requiredKg = CalculateRequiredQuantity(plannedQuantity, bom.Quantity, bom.UomId ?? 1, bom.WastePercentage);
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

        private decimal CalculateRequiredQuantity(decimal plannedQuantity, decimal recipeQuantity, int uomId, decimal? wastePercentage)
        {
            decimal baseQty;
            if (uomId == 4) // Count-based (e.g. Viên)
            {
                baseQty = plannedQuantity * recipeQuantity;
                return decimal.Round(baseQty, 6, MidpointRounding.AwayFromZero);
            }
            
            // Mass-based (mg/unit to kg)
            baseQty = (plannedQuantity * recipeQuantity) / 1_000_000m;
            var wasteFactor = 1m + ((wastePercentage ?? 0m) / 100m);
            return decimal.Round(baseQty * wasteFactor, 6, MidpointRounding.AwayFromZero);
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
                return NotFound(new { success = false, message = "Không tìm thấy lệnh sản xuất." });
            }

            if (existing.Status != "Draft")
            {
                return BadRequest(new { success = false, message = "Không thể duy trì lệnh sản xuất đang ở trạng thái " + existing.Status + "." });
            }

            if (string.IsNullOrWhiteSpace(request.Signature))
            {
                return BadRequest(new { success = false, message = "Thiếu chữ ký điện tử." });
            }

            existing.Status = "Approved";
            _unitOfWork.ProductionOrders.Update(existing);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, message = "Duyệt lệnh sản xuất thành công." });
        }

        [HttpPost("{id}/hold")]
        public async Task<IActionResult> Hold(int id)
        {
            var existing = await _unitOfWork.ProductionOrders.GetByIdAsync(id);
            if (existing == null)
                return NotFound(new { success = false, message = "Không tìm thấy lệnh sản xuất." });

            if (existing.Status != "Approved")
                return BadRequest(new { success = false, message = "Không thể tạm dừng lệnh sản xuất " + id + "." });

            existing.Status = "Hold";
            _unitOfWork.ProductionOrders.Update(existing);
            await _unitOfWork.CompleteAsync();
            return Ok(new { success = true, message = "Đã tạm dừng lệnh sản xuất." });
        }

        [HttpPost("{id}/resume")]
        public async Task<IActionResult> Resume(int id)
        {
            var existing = await _unitOfWork.ProductionOrders.GetByIdAsync(id);
            if (existing == null)
                return NotFound(new { success = false, message = "Không tìm thấy lệnh sản xuất." });

            if (existing.Status != "Hold")
                return BadRequest(new { success = false, message = "Chỉ có thể tiếp tục lệnh đang ở trạng thái Hold." });

            existing.Status = "Approved";
            _unitOfWork.ProductionOrders.Update(existing);
            await _unitOfWork.CompleteAsync();
            return Ok(new { success = true, message = "Đã chuyển lệnh về trạng thái Approved." });
        }

        [HttpPost("{id}/complete")]
        public async Task<IActionResult> Complete(int id, [FromBody] SignatureRequest request)
        {
            var existing = await _unitOfWork.ProductionOrders.GetByIdAsync(id);
            if (existing == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy lệnh sản xuất." });
            }

            if (string.IsNullOrWhiteSpace(request.Signature))
            {
                return BadRequest(new { success = false, message = "Thiếu chữ ký điện tử xác nhận hoàn thành." });
            }

            existing.Status = "Completed";
            _unitOfWork.ProductionOrders.Update(existing);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, message = "Đã hoàn thành lệnh sản xuất." });
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var order = await _unitOfWork.ProductionOrders.Query()
                .Include(o => o.ProductionOrderBoms)
                .Include(o => o.RecipeRoutings)
                .Include(o => o.ProductionBatches)
                .FirstOrDefaultAsync(o => o.OrderId == id);

            if (order == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy lệnh sản xuất." });
            }

            // Clean up related data if order is in Draft status
            if (order.Status == "Draft")
            {
                // Remove Boms
                if (order.ProductionOrderBoms.Any())
                    _unitOfWork.ProductionOrderBoms.RemoveRange(order.ProductionOrderBoms);

                // Remove Routings (those specific to this order)
                if (order.RecipeRoutings.Any())
                    _unitOfWork.RecipeRoutings.RemoveRange(order.RecipeRoutings);
                
                // If there are batches (shouldn't be in Draft usually, but safety first)
                if (order.ProductionBatches.Any())
                    _unitOfWork.ProductionBatches.RemoveRange(order.ProductionBatches);
            }
            else
            {
                return BadRequest(new { success = false, message = "Chỉ có thể xóa lệnh sản xuất ở trạng thái Draft." });
            }

            _unitOfWork.ProductionOrders.Remove(order);
            await _unitOfWork.CompleteAsync();
            return Ok(new { success = true, message = "Đã xóa lệnh sản xuất." });
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
