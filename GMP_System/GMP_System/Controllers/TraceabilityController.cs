using GMP_System.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GMP_System.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class TraceabilityController : ControllerBase
    {
        private readonly IUnitOfWork _unitOfWork;

        public TraceabilityController(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        // GET: /api/traceability/backward/{batchNumber}
        // Truy xuất ngược: từ lô thành phẩm -> tìm lại các lô nguyên liệu đã dùng
        [HttpGet("backward/{batchNumber}")]
        public async Task<IActionResult> Backward(string batchNumber)
        {
            var keyword = (batchNumber ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(keyword))
            {
                return BadRequest(new { success = false, message = "Mã lô không hợp lệ." });
            }

            // Dùng EF.Functions.Like để tương thích SQL Server, tránh lỗi dịch LINQ -> SQL
            var targetBatch = await _unitOfWork.ProductionBatches
                .Query()
                .Include(b => b.Order)
                    .ThenInclude(o => o!.Recipe)
                        .ThenInclude(r => r!.Material)
                .Where(b => b.BatchNumber != null && EF.Functions.Like(b.BatchNumber, $"%{keyword}%"))
                .OrderByDescending(b => b.BatchId)
                .FirstOrDefaultAsync();

            if (targetBatch == null)
            {
                return NotFound(new { success = false, message = $"Không tìm thấy lô sản xuất: {batchNumber}" });
            }

            var order = targetBatch.Order;
            var recipe = order?.Recipe;

            var batchUsages = await _unitOfWork.MaterialUsages
                .Query()
                .Include(u => u.InventoryLot)
                    .ThenInclude(l => l!.Material)
                        .ThenInclude(m => m!.BaseUom)
                .Where(u => u.BatchId == targetBatch.BatchId)
                .ToListAsync();

            // Chuẩn hóa key theo màn hình frontend Traceability.tsx đang dùng
            var result = new
            {
                finishedGoodBatchNumber = targetBatch.BatchNumber,
                productName = recipe?.Material?.MaterialName ?? "Unknown",
                productionOrderId = targetBatch.OrderId,
                quantityProduced = order?.PlannedQuantity ?? 0,
                rawMaterials = batchUsages.Select(u => new
                {
                    materialCode = u.InventoryLot?.Material?.MaterialCode ?? "N/A",
                    materialName = u.InventoryLot?.Material?.MaterialName ?? "Unknown",
                    inventoryLotNumber = u.InventoryLot?.LotNumber ?? "N/A",
                    quantityUsed = u.ActualAmount,
                    uom = u.InventoryLot?.Material?.BaseUom?.UomName ?? "",
                    usedAt = u.Timestamp,
                    usedBy = u.DispensedBy,
                    qcStatus = u.InventoryLot?.Qcstatus ?? "N/A"
                }).ToList()
            };

            return Ok(result);
        }

        // GET: /api/traceability/forward/{lotNumber}
        // Truy xuất xuôi: từ số lô nguyên liệu -> tìm các lô thành phẩm đã dùng nó
        [HttpGet("forward/{lotNumber}")]
        public async Task<IActionResult> Forward(string lotNumber)
        {
            var keyword = (lotNumber ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(keyword))
            {
                return BadRequest(new { success = false, message = "Mã lô không hợp lệ." });
            }

            var lot = await _unitOfWork.InventoryLots
                .Query()
                .Include(l => l.Material)
                .Where(l => l.LotNumber != null && EF.Functions.Like(l.LotNumber, $"%{keyword}%"))
                .OrderByDescending(l => l.LotId)
                .FirstOrDefaultAsync();

            if (lot == null)
            {
                return NotFound(new { success = false, message = $"Không tìm thấy lô nguyên liệu: {lotNumber}" });
            }

            var usages = await _unitOfWork.MaterialUsages
                .Query()
                .Include(u => u.Batch)
                    .ThenInclude(b => b!.Order)
                        .ThenInclude(o => o!.Recipe)
                            .ThenInclude(r => r!.Material)
                .Where(u => u.InventoryLotId == lot.LotId)
                .ToListAsync();

            var result = new
            {
                lotNumber = lot.LotNumber,
                materialName = lot.Material?.MaterialName ?? "Unknown",
                supplier = "N/A",
                quantityReceived = lot.QuantityCurrent,
                usedInBatches = usages.Select(u => new
                {
                    batchNumber = u.Batch?.BatchNumber ?? "N/A",
                    productionDate = u.Batch?.ManufactureDate?.ToString("yyyy-MM-dd") ?? "",
                    quantityUsed = u.ActualAmount,
                    product = u.Batch?.Order?.Recipe?.Material?.MaterialName ?? "Unknown"
                }).ToList()
            };

            return Ok(result);
        }
    }
}

