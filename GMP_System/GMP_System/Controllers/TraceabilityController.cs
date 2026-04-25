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

        [HttpGet("backward/{batchNumber}")]
        public async Task<IActionResult> Backward(string batchNumber)
        {
            var keyword = (batchNumber ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(keyword))
            {
                return BadRequest(new { success = false, message = "Mã lô không hợp lệ." });
            }

            var targetBatch = await _unitOfWork.ProductionBatches
                .Query()
                .Include(b => b.Order)
                    .ThenInclude(o => o!.Recipe)
                        .ThenInclude(r => r!.Material)
                .Include(b => b.Order)
                    .ThenInclude(o => o!.Recipe)
                        .ThenInclude(r => r!.RecipeBoms)
                            .ThenInclude(b => b.Material)
                                .ThenInclude(m => m!.BaseUom)
                .Include(b => b.Order)
                    .ThenInclude(o => o!.Recipe)
                        .ThenInclude(r => r!.RecipeBoms)
                            .ThenInclude(b => b.Uom)
                .Where(b => b.BatchNumber != null && EF.Functions.Like(b.BatchNumber, $"%{keyword}%"))
                .OrderByDescending(b => b.BatchId)
                .FirstOrDefaultAsync();

            if (targetBatch != null)
            {
                var order = targetBatch.Order;
                var recipe = order?.Recipe;

                var batchUsages = await _unitOfWork.MaterialUsages
                    .Query()
                    .Include(u => u.InventoryLot)
                        .ThenInclude(l => l!.Material)
                            .ThenInclude(m => m!.BaseUom)
                    .Where(u => u.BatchId == targetBatch.BatchId)
                    .ToListAsync();

                var totalUsed = batchUsages.Sum(x => x.ActualAmount);
                var rawRows = batchUsages.Select(u =>
                {
                    var materialCode = u.InventoryLot?.Material?.MaterialCode ?? "N/A";
                    var quantityUsed = u.ActualAmount;
                    var ratio = totalUsed > 0 ? Math.Round((quantityUsed / totalUsed) * 100m, 2) : 0m;

                    return new
                    {
                        materialCode,
                        materialName = u.InventoryLot?.Material?.MaterialName ?? "Unknown",
                        inventoryLotNumber = u.InventoryLot?.LotNumber ?? "N/A",
                        quantityUsed,
                        uom = u.InventoryLot?.Material?.BaseUom?.UomName ?? string.Empty,
                        usedAt = u.Timestamp,
                        usedBy = u.DispensedBy,
                        Status = u.InventoryLot?.QCStatus ?? "N/A",
                        lotQuantityCurrent = u.InventoryLot?.QuantityCurrent,
                        ratioPercent = ratio,
                        certificateUrl = $"/api/certificates/material/{Uri.EscapeDataString(materialCode)}"
                    };
                }).ToList();

                if (!rawRows.Any() && recipe?.RecipeBoms != null)
                {
                    var fallbackTotal = recipe.RecipeBoms.Sum(b => b.Quantity);
                    rawRows = recipe.RecipeBoms.Select(b => new
                    {
                        materialCode = b.Material?.MaterialCode ?? "N/A",
                        materialName = b.Material?.MaterialName ?? "Unknown",
                        inventoryLotNumber = "N/A",
                        quantityUsed = b.Quantity,
                        uom = b.Uom?.UomName ?? b.Material?.BaseUom?.UomName ?? "mg",
                        usedAt = (DateTime?)null,
                        usedBy = (int?)null,
                        Status = "N/A",
                        lotQuantityCurrent = (decimal?)null,
                        ratioPercent = fallbackTotal > 0 ? Math.Round((b.Quantity / fallbackTotal) * 100m, 2) : 0m,
                        certificateUrl = $"/api/certificates/material/{Uri.EscapeDataString(b.Material?.MaterialCode ?? "")}" 
                    }).ToList();
                }

                var result = new
                {
                    finishedGoodBatchNumber = targetBatch.BatchNumber,
                    productName = recipe?.Material?.MaterialName ?? "Unknown",
                    productionOrderId = targetBatch.OrderId,
                    quantityProduced = order?.PlannedQuantity ?? 0,
                    batchId = targetBatch.BatchId,
                    finishedCertificateUrl = $"/api/certificates/lot/{Uri.EscapeDataString(targetBatch.BatchNumber ?? string.Empty)}",
                    rawMaterials = rawRows
                };

                return Ok(result);
            }

            var finishedLot = await _unitOfWork.InventoryLots
                .Query()
                .Include(l => l.Material)
                    .ThenInclude(m => m!.BaseUom)
                .Where(l => l.LotNumber != null
                    && EF.Functions.Like(l.LotNumber, $"%{keyword}%")
                    && l.Material != null
                    && l.Material.Type == "FinishedGood")
                .OrderByDescending(l => l.LotId)
                .FirstOrDefaultAsync();

            if (finishedLot == null)
            {
                return NotFound(new { success = false, message = $"Không tìm thấy lô sản xuất: {batchNumber}" });
            }

            var recipeForFinishedGood = await _unitOfWork.Recipes
                .Query()
                .Include(r => r.RecipeBoms)
                    .ThenInclude(b => b.Material)
                        .ThenInclude(m => m!.BaseUom)
                .Include(r => r.RecipeBoms)
                    .ThenInclude(b => b.Uom)
                .Where(r => r.MaterialId == finishedLot.MaterialId)
                .OrderByDescending(r => r.RecipeId)
                .FirstOrDefaultAsync();

            var fallbackRows = new List<object>();
            if (recipeForFinishedGood?.RecipeBoms != null)
            {
                var total = recipeForFinishedGood.RecipeBoms.Sum(x => x.Quantity);
                fallbackRows = recipeForFinishedGood.RecipeBoms.Select(b => new
                {
                    materialCode = b.Material?.MaterialCode ?? "N/A",
                    materialName = b.Material?.MaterialName ?? "Unknown",
                    inventoryLotNumber = "N/A",
                    quantityUsed = b.Quantity,
                    uom = b.Uom?.UomName ?? b.Material?.BaseUom?.UomName ?? "mg",
                    usedAt = (DateTime?)null,
                    usedBy = (int?)null,
                    Status = "N/A",
                    lotQuantityCurrent = (decimal?)null,
                    ratioPercent = total > 0 ? Math.Round((b.Quantity / total) * 100m, 2) : 0m,
                    certificateUrl = $"/api/certificates/material/{Uri.EscapeDataString(b.Material?.MaterialCode ?? "")}"
                }).Cast<object>().ToList();
            }
            else
            {
                var rawMaterials = await _unitOfWork.Materials.Query()
                    .Include(m => m.BaseUom)
                    .Where(m => m.Type != "FinishedGood")
                    .OrderBy(m => m.MaterialId)
                    .Take(6)
                    .ToListAsync();

                if (rawMaterials.Any())
                {
                    var ratio = Math.Round(100m / rawMaterials.Count, 2);
                    fallbackRows = rawMaterials.Select(m => new
                    {
                        materialCode = m.MaterialCode,
                        materialName = m.MaterialName,
                        inventoryLotNumber = "N/A",
                        quantityUsed = 0m,
                        uom = m.BaseUom?.UomName ?? string.Empty,
                        usedAt = (DateTime?)null,
                        usedBy = (int?)null,
                        Status = "N/A",
                        lotQuantityCurrent = (decimal?)null,
                        ratioPercent = ratio,
                        certificateUrl = $"/api/certificates/material/{Uri.EscapeDataString(m.MaterialCode ?? "")}"
                    }).Cast<object>().ToList();
                }
            }

            return Ok(new
            {
                finishedGoodBatchNumber = finishedLot.LotNumber,
                productName = finishedLot.Material?.MaterialName ?? "Unknown",
                productionOrderId = (int?)null,
                quantityProduced = finishedLot.QuantityCurrent,
                batchId = (int?)null,
                finishedCertificateUrl = $"/api/certificates/lot/{Uri.EscapeDataString(finishedLot.LotNumber ?? string.Empty)}",
                rawMaterials = fallbackRows
            });
        }

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
                    productionDate = u.Batch?.ManufactureDate?.ToString("yyyy-MM-dd") ?? string.Empty,
                    quantityUsed = u.ActualAmount,
                    product = u.Batch?.Order?.Recipe?.Material?.MaterialName ?? "Unknown"
                }).ToList()
            };

            return Ok(result);
        }
    }
}
