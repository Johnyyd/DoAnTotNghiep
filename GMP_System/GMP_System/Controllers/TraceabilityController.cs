using GMP_System.Entities;
using GMP_System.Interfaces;
using Microsoft.AspNetCore.Mvc;

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
        // Truy xuất ngược: từ lô thành phẩm → nguyên liệu đầu vào
        [HttpGet("backward/{batchNumber}")]
        public async Task<IActionResult> Backward(string batchNumber)
        {
            // Tìm production batch với batch number
            var batches = await _unitOfWork.ProductionBatches.GetAllAsync();
            var targetBatch = batches.FirstOrDefault(b => b.BatchNumber != null && b.BatchNumber.Contains(batchNumber, StringComparison.OrdinalIgnoreCase));

            if (targetBatch == null)
            {
                return NotFound($"Không tìm thấy lô sản xuất với mã: {batchNumber}");
            }

            // Lấy production order và recipe
            var order = targetBatch.Order;
            var recipe = order?.Recipe;

            // Lấy danh sách nguyên liệu đã dùng (MaterialUsages)
            var materialUsages = await _unitOfWork.MaterialUsages.GetAllAsync();
            var batchUsages = materialUsages.Where(m => m.BatchId == targetBatch.BatchId).ToList();

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
        // Truy xuất xuôi: từ lô nguyên liệu → các lô thành phẩm đã sử dụng
        [HttpGet("forward/{lotNumber}")]
        public async Task<IActionResult> Forward(string lotNumber)
        {
            // Tìm inventory lot
            var lots = await _unitOfWork.InventoryLots.GetAllAsync();
            var lot = lots.FirstOrDefault(l => l.LotNumber != null && l.LotNumber.Contains(lotNumber, StringComparison.OrdinalIgnoreCase));

            if (lot == null)
            {
                return NotFound($"Không tìm thấy lô nguyên liệu với mã: {lotNumber}");
            }

            // Tìm các production batches đã sử dụng lô này
            var materialUsages = await _unitOfWork.MaterialUsages.GetAllAsync();
            var usages = materialUsages.Where(m => m.InventoryLotId == lot.LotId).ToList();

            var batches = await _unitOfWork.ProductionBatches.GetAllAsync();
            var batchIds = usages.Select(u => u.BatchId).Distinct().ToList();
            var usedBatches = batches.Where(b => batchIds.Contains(b.BatchId)).ToList();

            var result = new
            {
                lotNumber = lotNumber,
                materialName = lot.Material?.MaterialName ?? "Unknown",
                supplier = "N/A",
                quantityReceived = lot.QuantityCurrent,
                usedInBatches = usedBatches.Select(b => new
                {
                    batchNumber = b.BatchNumber,
                    productionDate = b.ManufactureDate?.ToString("yyyy-MM-dd") ?? "",
                    quantityUsed = usages.FirstOrDefault(u => u.BatchId == b.BatchId)?.ActualAmount ?? 0,
                    product = b.Order?.Recipe?.Material?.MaterialName ?? "Unknown"
                }).ToList()
            };

            return Ok(result);
        }
    }
}
