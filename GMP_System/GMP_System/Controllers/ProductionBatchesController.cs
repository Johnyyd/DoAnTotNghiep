using GMP_System.Entities;
using GMP_System.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GMP_System.Controllers
{
    [Route("api/production-batches")]
    [ApiController]
    public class ProductionBatchesController : ControllerBase
    {
        private readonly IUnitOfWork _unitOfWork;

        public ProductionBatchesController(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        // GET: api/production-batches
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var batches = await _unitOfWork.ProductionBatches
                .Query()
                .Select(b => new {
                    b.BatchId,
                    b.OrderId,
                    b.BatchNumber,
                    b.Status,
                    b.ManufactureDate,
                    b.EndTime,
                    b.ExpiryDate,
                    b.CurrentStep,
                    Order = b.Order == null ? null : new {
                        b.Order.OrderId,
                        b.Order.OrderCode,
                        Recipe = b.Order.Recipe == null ? null : new {
                            b.Order.Recipe.RecipeId,
                            Material = b.Order.Recipe.Material == null ? null : new {
                                b.Order.Recipe.Material.MaterialName
                            }
                        }
                    }
                })
                .OrderBy(b => b.BatchId)
                .AsNoTracking()
                .ToListAsync();

            return Ok(new { data = batches, success = true, message = "Success" });
        }

        // GET: api/production-batches/5
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var batch = await _unitOfWork.ProductionBatches.Query()
                .Include(b => b.Order)
                    .ThenInclude(o => o.Recipe)
                        .ThenInclude(r => r.Material)
                            .ThenInclude(m => m.BaseUom)
                .Include(b => b.Order)
                    .ThenInclude(o => o.Recipe)
                        .ThenInclude(r => r.RecipeBoms)
                            .ThenInclude(bom => bom.Material)
                .Where(b => b.BatchId == id)
                .FirstOrDefaultAsync();

            if (batch == null) return NotFound(new { success = false, message = "KhÃ´ng tÃ¬m tháº¥y máº» sáº£n xuáº¥t." });

            // Fetch Routings separately with StepParameters included
            var routingsQuery = _unitOfWork.RecipeRoutings.Query()
                .Include(r => r.DefaultEquipment)
                .Include(r => r.StepParameters);
            
            var orderRoutings = await routingsQuery.Where(r => r.OrderId == batch.OrderId).ToListAsync();
            var recipeId = batch.Order?.RecipeId;
            var finalRoutings = orderRoutings.Any() 
                ? orderRoutings 
                : await routingsQuery.Where(r => r.RecipeId == recipeId && r.OrderId == null).ToListAsync();

            // Fetch unique BOM for this order
            var bomsWithQC = new List<object>();
            if (batch.Order != null)
            {
                var orderBoms = await _unitOfWork.ProductionOrderBoms.Query()
                    .Where(bom => bom.OrderId == batch.OrderId)
                    .Include(bom => bom.Material)
                    .Include(bom => bom.Uom)
                    .Select(bom => new {
                        bom.OrderBomId,
                        bom.MaterialId,
                        bom.RequiredQuantity,
                        bom.UomId,
                        MaterialName = bom.Material != null ? bom.Material.MaterialName : "Unknown",
                        MaterialCode = bom.Material != null ? bom.Material.MaterialCode : "N/A",
                        UomName = bom.Uom != null ? bom.Uom.UomName : "kg"
                    }).ToListAsync();

                foreach (var bom in orderBoms) 
                {
                    var suggestedQC = await _unitOfWork.InventoryLots.Query()
                        .Where(l => l.MaterialId == bom.MaterialId && l.QuantityCurrent > 0)
                        .OrderByDescending(l => l.LotId)
                        .Select(l => l.LotNumber) 
                        .FirstOrDefaultAsync();

                    bomsWithQC.Add(new {
                        bom.OrderBomId,
                        bom.MaterialId,
                        Quantity = bom.RequiredQuantity, 
                        bom.UomId,
                        Material = new {
                            MaterialName = bom.MaterialName,
                            MaterialCode = bom.MaterialCode,
                            SuggestedQCNumber = suggestedQC,
                            UnitOfMeasure = new {
                                UomName = bom.UomName
                            }
                        }
                    });
                }
            }

            var result = new {
                batch.BatchId,
                batch.OrderId,
                batch.BatchNumber,
                batch.Status,
                batch.PlannedQuantity,
                batch.ManufactureDate,
                batch.EndTime,
                batch.ExpiryDate,
                batch.CurrentStep,
                Order = batch.Order == null ? null : new {
                    batch.Order.OrderId,
                    batch.Order.OrderCode,
                    batch.Order.RecipeId,
                    Recipe = batch.Order.Recipe == null ? null : new {
                        batch.Order.Recipe.RecipeId,
                        Material = batch.Order.Recipe.Material == null ? null : new {
                            batch.Order.Recipe.Material.MaterialName,
                            UnitOfMeasure = batch.Order.Recipe.Material.BaseUom == null ? null : new {
                                batch.Order.Recipe.Material.BaseUom.UomName
                            }
                        },
                        RecipeBoms = bomsWithQC
                    }
                },
                Routings = finalRoutings.OrderBy(r => r.StepNumber).Select(r => new {
                    r.RoutingId,
                    r.StepNumber,
                    r.StepName,
                    r.EstimatedTimeMinutes,
                    r.Description,
                    r.NumberOfRouting,
                    r.SetTemperature,
                    r.SetPressure,
                    r.SetTimeMinutes,
                    r.CleanlinessStatus,
                    r.StandardTemperature,
                    r.StandardHumidity,
                    r.StandardPressure,
                    r.AreaId,
                    DefaultEquipment = r.DefaultEquipment == null ? null : new {
                        r.DefaultEquipment.EquipmentId,
                        r.DefaultEquipment.EquipmentCode,
                        r.DefaultEquipment.EquipmentName
                    },
                    StepParameters = r.StepParameters.Select(sp => new {
                        sp.ParameterId,
                        sp.ParameterName,
                        sp.Unit,
                        sp.MinValue,
                        sp.MaxValue
                    }).ToList()
                }).ToList()
            };

            return Ok(new { data = result, success = true, message = "Success" });

        }

        // POST: api/production-batches — Tạo mẻ sản xuất mới
        [HttpPost]
        public async Task<IActionResult> Create(ProductionBatch batch)
        {
            if (batch.OrderId == null)
                return BadRequest(new { success = false, message = "Phải gắn với một Lệnh sản xuất (OrderId)." });

            var order = await _unitOfWork.ProductionOrders.GetByIdAsync(batch.OrderId.Value);
            if (order == null)
                return BadRequest(new { success = false, message = "Không tìm thấy Lệnh sản xuất." });

            if (string.IsNullOrEmpty(batch.BatchNumber))
                batch.BatchNumber = $"BATCH-{DateTime.Now:yyyyMMdd}-{batch.OrderId}";

            batch.ManufactureDate = DateTime.Now;
            batch.Status = "In-Process";
            batch.CurrentStep = 0;

            await _unitOfWork.ProductionBatches.AddAsync(batch);

            // Cập nhật trạng thái Order cha thành In-Process
            if (order.Status != "In-Process" && order.Status != "Completed")
            {
                order.Status = "In-Process";
                _unitOfWork.ProductionOrders.Update(order);
            }

            await _unitOfWork.CompleteAsync();

            return Ok(new
            {
                success = true,
                message = "Khởi động mẻ sản xuất thành công!",
                data = new { batchId = batch.BatchId, batchNumber = batch.BatchNumber, status = batch.Status }
            });
        }

        // POST: api/production-batches/{id}/finish — Kết thúc mẻ
        [HttpPost("{id}/finish")]
        public async Task<IActionResult> FinishBatch(int id)
        {
            var batch = await _unitOfWork.ProductionBatches.Query()
                .Include(b => b.Order)
                .FirstOrDefaultAsync(b => b.BatchId == id);

            if (batch == null) return NotFound(new { success = false, message = "Không tìm thấy mẻ sản xuất." });
            if (batch.Status == "Completed") return BadRequest(new { success = false, message = "Mẻ này đã kết thúc rồi." });

            // [GMP ENFORCEMENT] Verify all steps are Passed
            var routingsQuery = _unitOfWork.RecipeRoutings.Query();
            var orderRoutings = await routingsQuery.Where(r => r.OrderId == batch.OrderId).ToListAsync();
            var recipeId = batch.Order?.RecipeId;
            var finalRoutings = orderRoutings.Any()
                ? orderRoutings
                : await routingsQuery.Where(r => r.RecipeId == recipeId && r.OrderId == null).ToListAsync();

            if (finalRoutings.Any())
            {
                var passedLogs = await _unitOfWork.BatchProcessLogs.Query()
                    .Where(l => l.BatchId == id && (l.ResultStatus == "Passed" || l.ResultStatus == "Approved"))
                    .Select(l => l.RoutingId)
                    .Distinct()
                    .ToListAsync();

                var missingStepIds = finalRoutings
                    .Select(r => r.RoutingId)
                    .Where(rid => !passedLogs.Contains(rid))
                    .ToList();

                if (missingStepIds.Any())
                {
                    var missingStepNames = finalRoutings
                        .Where(r => missingStepIds.Contains(r.RoutingId))
                        .Select(r => r.StepName)
                        .ToList();

                    return BadRequest(new
                    {
                        success = false,
                        message = "⚠ Vi phạm quy trình GMP: Không thể kết thúc mẻ vì vẫn còn công đoạn chưa hoàn thành hoặc chưa được QC duyệt.",
                        details = $"Công đoạn chưa xong: {string.Join(", ", missingStepNames)}"
                    });
                }
            }

            batch.Status = "Completed";
            batch.EndTime = DateTime.Now;
            _unitOfWork.ProductionBatches.Update(batch);

            // Cập nhật trạng thái Order cha nếu tất cả batches đã completed
            if (batch.OrderId.HasValue)
            {
                var allBatches = await _unitOfWork.ProductionBatches
                    .Query()
                    .Where(b => b.OrderId == batch.OrderId && b.BatchId != id)
                    .ToListAsync();

                var allDone = allBatches.All(b => b.Status == "Completed");
                if (allDone)
                {
                    var order = await _unitOfWork.ProductionOrders.GetByIdAsync(batch.OrderId.Value);
                    if (order != null)
                    {
                        order.Status = "Completed";
                        _unitOfWork.ProductionOrders.Update(order);
                    }
                }
            }

            await _unitOfWork.CompleteAsync();

            return Ok(new
            {
                success = true,
                message = "Đóng mẻ sản xuất thành công!",
                data = new { batchNumber = batch.BatchNumber, endTime = batch.EndTime }
            });
        }
    }
}
