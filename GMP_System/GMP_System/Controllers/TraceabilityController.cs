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
        // Truy xuất ngược: từ lô thành phẩm → tìm lại các lô nguyên liệu đã dùng
        [HttpGet("backward/{batchNumber}")]
        public async Task<IActionResult> Backward(string batchNumber)
        {
            // Load batch kèm Order → Recipe → Material (chain Include)
            var targetBatch = await _unitOfWork.ProductionBatches
                .Query()
                .Include(b => b.Order)
                    .ThenInclude(o => o!.Recipe)
                        .ThenInclude(r => r!.Material)
                .Where(b => b.BatchNumber != null &&
                            b.BatchNumber.Contains(batchNumber, StringComparison.OrdinalIgnoreCase))
                .FirstOrDefaultAsync();

            if (targetBatch == null)
                return NotFound(new { success = false, message = $"Không tìm thấy lô sản xuất: {batchNumber}" });

            var order = targetBatch.Order;
            var recipe = order?.Recipe;

            // Load MaterialUsages của batch này, kèm InventoryLot → Material
            var batchUsages = await _unitOfWork.MaterialUsages
                .Query()
                .Include(u => u.InventoryLot)
                    .ThenInclude(l => l!.Material)
                .Where(u => u.BatchId == targetBatch.BatchId)
                .ToListAsync();

            var result = new
            {
                batchNumber = batchNumber,
                finishedGood = new
                {
                    name = recipe?.Material?.MaterialName ?? "Unknown",
                    batchNumber = batchNumber,
                    producedDate = targetBatch.ManufactureDate?.ToString("yyyy-MM-dd") ?? "",
                    quantity = order?.PlannedQuantity ?? 0
                },
                rawMaterials = batchUsages.Select(u => new
                {
                    name = u.InventoryLot?.Material?.MaterialName ?? "Unknown",
                    batchNumber = u.InventoryLot?.LotNumber ?? "N/A",
                    quantity = u.ActualAmount,
                    supplier = "N/A",
                    qcStatus = u.InventoryLot?.Qcstatus ?? "N/A"
                }).ToList()
            };

            return Ok(result);
        }

        // GET: /api/traceability/forward/{lotNumber}
        // Truy xuất xuôi: từ số lô nguyên liệu → tìm các lô thành phẩm đã dùng nó
        [HttpGet("forward/{lotNumber}")]
        public async Task<IActionResult> Forward(string lotNumber)
        {
            // Tìm inventory lot kèm Material info
            var lot = await _unitOfWork.InventoryLots
                .Query()
                .Include(l => l.Material)
                .Where(l => l.LotNumber != null &&
                            l.LotNumber.Contains(lotNumber, StringComparison.OrdinalIgnoreCase))
                .FirstOrDefaultAsync();

            if (lot == null)
                return NotFound(new { success = false, message = $"Không tìm thấy lô nguyên liệu: {lotNumber}" });

            // Tìm usages cho lot này kèm Batch → Order → Recipe → Material
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
                lotNumber = lotNumber,
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
