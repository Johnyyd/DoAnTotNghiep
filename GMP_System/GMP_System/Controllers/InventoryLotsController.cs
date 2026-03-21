using GMP_System.Entities;
using GMP_System.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GMP_System.Controllers
{
    [Route("api/inventory-lots")]
    [ApiController]
    public class InventoryLotsController : ControllerBase
    {
        private readonly IUnitOfWork _unitOfWork;

        public InventoryLotsController(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        // GET: api/inventory-lots?materialId=1&lotNumber=LOT-001
        [HttpGet]
        public async Task<IActionResult> GetLots(
            [FromQuery] int? materialId,
            [FromQuery] string? lotNumber)
        {
            IQueryable<InventoryLot> query = _unitOfWork.InventoryLots
                .Query()
                .Include(l => l.Material);

            if (materialId.HasValue)
                query = query.Where(l => l.MaterialId == materialId.Value);

            if (!string.IsNullOrEmpty(lotNumber))
                query = query.Where(l => l.LotNumber != null && l.LotNumber.Contains(lotNumber));

            var lots = await query.OrderByDescending(l => l.LotId).ToListAsync();
            return Ok(new { data = lots, success = true, message = "Success" });
        }

        // GET: api/inventory-lots/available
        [HttpGet("available")]
        public async Task<IActionResult> GetAvailableLots()
        {
            var lots = await _unitOfWork.InventoryLots
                .Query()
                .Include(l => l.Material)
                .Where(l => l.QuantityCurrent > 0
                         && l.ExpiryDate > DateTime.Now
                         && l.Qcstatus == "Released")
                .OrderBy(l => l.ExpiryDate)
                .ToListAsync();

            return Ok(new { data = lots, success = true, message = "Success" });
        }

        // GET: api/inventory-lots/5
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var lot = await _unitOfWork.InventoryLots
                .Query()
                .Include(l => l.Material)
                .Include(l => l.MaterialUsages)
                .FirstOrDefaultAsync(l => l.LotId == id);

            if (lot == null) return NotFound(new { success = false, message = "Không tìm thấy lô." });
            return Ok(new { data = lot, success = true, message = "Success" });
        }

        // POST: api/inventory-lots — Nhập kho
        [HttpPost]
        public async Task<IActionResult> ReceiveMaterial(InventoryLot lot)
        {
            if (lot.MaterialId == null) return BadRequest(new { success = false, message = "Chưa chọn nguyên liệu." });
            if (lot.QuantityCurrent <= 0) return BadRequest(new { success = false, message = "Số lượng nhập phải > 0." });
            if (string.IsNullOrEmpty(lot.LotNumber)) return BadRequest(new { success = false, message = "Thiếu số lô." });

            lot.Qcstatus = "Quarantine"; // mặc định kiểm dịch khi nhập kho

            await _unitOfWork.InventoryLots.AddAsync(lot);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, message = "Nhập kho thành công!", data = new { lotId = lot.LotId, lotNumber = lot.LotNumber } });
        }

        // POST: api/inventory-lots/{id}/qc — Duyệt QC lô
        [HttpPost("{id}/qc")]
        public async Task<IActionResult> UpdateQcStatus(int id, [FromBody] QcUpdateRequest request)
        {
            var lot = await _unitOfWork.InventoryLots.GetByIdAsync(id);
            if (lot == null) return NotFound(new { success = false, message = "Không tìm thấy lô." });

            var validStatuses = new[] { "Released", "Rejected", "Quarantine" };
            if (!validStatuses.Contains(request.Status))
                return BadRequest(new { success = false, message = "Trạng thái phải là: Released, Rejected, Quarantine" });

            lot.Qcstatus = request.Status;
            _unitOfWork.InventoryLots.Update(lot);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, message = "Cập nhật QC thành công!", lotNumber = lot.LotNumber, status = lot.Qcstatus });
        }
    }

    public class QcUpdateRequest
    {
        public string Status { get; set; } = string.Empty;
    }
}