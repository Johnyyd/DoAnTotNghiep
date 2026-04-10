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
                .AsNoTracking()
                .ToListAsync();

            return Ok(new { data = batches, success = true, message = "Success" });
        }

        // GET: api/production-batches/5
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var batch = await _unitOfWork.ProductionBatches
                .Query()
                .Where(b => b.BatchId == id)
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
                        b.Order.OrderCode,
                        Recipe = b.Order.Recipe == null ? null : new {
                            b.Order.Recipe.RecipeId,
                            Material = b.Order.Recipe.Material == null ? null : new {
                                b.Order.Recipe.Material.MaterialName,
                                UnitOfMeasure = b.Order.Recipe.Material.BaseUom == null ? null : new {
                                    b.Order.Recipe.Material.BaseUom.UomName
                                }
                            },
                            RecipeBoms = b.Order.Recipe.RecipeBoms.Select(bom => new {
                                bom.BomId,
                                bom.Quantity,
                                Material = bom.Material == null ? null : new { bom.Material.MaterialName },
                                Uom = bom.Uom == null ? null : new { bom.Uom.UomName }
                            }),
                            RecipeRoutings = b.Order.Recipe.RecipeRoutings.Select(r => new {
                                r.RoutingId,
                                r.StepNumber,
                                r.StepName,
                                r.Description,
                                r.EstimatedTimeMinutes,
                                r.DefaultEquipmentId,
                                r.NumberOfRouting,
                                StepParameters = r.StepParameters.Select(sp => new {
                                    sp.ParameterId,
                                    sp.ParameterName,
                                    sp.MinValue,
                                    sp.MaxValue,
                                    sp.Unit
                                })
                            })
                        }
                    },
                    BatchProcessLogs = b.BatchProcessLogs.Select(l => new {
                        l.LogId,
                        l.RoutingId,
                        l.ResultStatus,
                        l.StartTime,
                        l.EndTime,
                        l.NumberOfRouting
                    })
                })
                .AsNoTracking()
                .FirstOrDefaultAsync();

            if (batch == null) return NotFound(new { success = false, message = "Không tìm thấy mẻ sản xuất." });
            return Ok(new { data = batch, success = true, message = "Success" });
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
            var batch = await _unitOfWork.ProductionBatches.GetByIdAsync(id);
            if (batch == null) return NotFound(new { success = false, message = "Không tìm thấy mẻ sản xuất." });
            if (batch.Status == "Completed") return BadRequest(new { success = false, message = "Mẻ này đã kết thúc rồi." });

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
