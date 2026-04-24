using GMP_System.Entities;
using GMP_System.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GMP_System.Controllers
{
    [Route("api/[controller]")]
    [Route("api/inventory-lots")]
    [ApiController]
    [Authorize]
    public class InventoryLotsController : ControllerBase
    {
        private readonly IUnitOfWork _unitOfWork;

        public InventoryLotsController(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        [HttpGet]
        public async Task<IActionResult> GetLots([FromQuery] int? materialId, [FromQuery] string? lotNumber)
        {
            var query = _unitOfWork.InventoryLots.Query();

            if (materialId.HasValue)
            {
                query = query.Where(l => l.MaterialId == materialId.Value);
            }

            if (!string.IsNullOrWhiteSpace(lotNumber))
            {
                query = query.Where(l => l.LotNumber.Contains(lotNumber));
            }

            var lots = await query.Include(l => l.Material).ThenInclude(m => m!.BaseUom).ToListAsync();
            return Ok(new { success = true, data = lots });
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetLot(int id)
        {
            var lot = await _unitOfWork.InventoryLots.GetByIdWithIncludeAsync(id, l => l.Material);
            if (lot == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy lô hàng." });
            }

            return Ok(new { success = true, data = lot });
        }

        [HttpPost]
        public async Task<IActionResult> CreateLot([FromBody] InventoryLot lot)
        {
            var validationError = ValidateLotDates(lot.ManufactureDate, lot.ExpiryDate);
            if (!string.IsNullOrWhiteSpace(validationError))
            {
                return BadRequest(new { success = false, message = validationError });
            }

            if (lot.MaterialId == null || lot.MaterialId <= 0)
            {
                return BadRequest(new { success = false, message = "Vui lòng chọn nguyên liệu hợp lệ." });
            }

            if (string.IsNullOrWhiteSpace(lot.LotNumber))
            {
                return BadRequest(new { success = false, message = "Vui lòng nhập mã lô." });
            }

            if (lot.QuantityCurrent <= 0)
            {
                return BadRequest(new { success = false, message = "Số lượng phải lớn hơn 0." });
            }

            lot.Qcstatus = string.IsNullOrWhiteSpace(lot.Qcstatus) ? "Pending" : lot.Qcstatus;
            await _unitOfWork.InventoryLots.AddAsync(lot);
            await _unitOfWork.CompleteAsync();

            return CreatedAtAction(nameof(GetLot), new { id = lot.LotId }, new { success = true, data = lot });
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateLot(int id, [FromBody] InventoryLot request)
        {
            var lot = await _unitOfWork.InventoryLots.GetByIdAsync(id);
            if (lot == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy lô hàng." });
            }

            var validationError = ValidateLotDates(request.ManufactureDate, request.ExpiryDate);
            if (!string.IsNullOrWhiteSpace(validationError))
            {
                return BadRequest(new { success = false, message = validationError });
            }

            if (request.QuantityCurrent <= 0)
            {
                return BadRequest(new { success = false, message = "Số lượng phải lớn hơn 0." });
            }

            lot.QuantityCurrent = request.QuantityCurrent;
            lot.ManufactureDate = request.ManufactureDate;
            lot.ExpiryDate = request.ExpiryDate;
            if (!string.IsNullOrWhiteSpace(request.Qcstatus))
            {
                lot.Qcstatus = request.Qcstatus;
            }

            _unitOfWork.InventoryLots.Update(lot);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, message = "Đã cập nhật lô nguyên liệu.", data = lot });
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteLot(int id)
        {
            var lot = await _unitOfWork.InventoryLots.GetByIdAsync(id);
            if (lot == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy lô hàng." });
            }

            var hasUsage = await _unitOfWork.MaterialUsages.Query().AnyAsync(u => u.InventoryLotId == id);
            if (hasUsage)
            {
                return BadRequest(new { success = false, message = "Lô đã được sử dụng trong sản xuất, không thể xóa." });
            }

            _unitOfWork.InventoryLots.Remove(lot);
            await _unitOfWork.CompleteAsync();
            return Ok(new { success = true, message = "Đã xóa lô nguyên liệu." });
        }

        [HttpPost("{id}/qc")]
        public async Task<IActionResult> UpdateQcStatus(int id, [FromBody] QcUpdateDto request)
        {
            var lot = await _unitOfWork.InventoryLots.GetByIdAsync(id);
            if (lot == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy lô hàng." });
            }

            lot.Qcstatus = request.Status;
            _unitOfWork.InventoryLots.Update(lot);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, message = "Cập nhật trạng thái QC thành công." });
        }

        private static string? ValidateLotDates(DateTime? manufactureDate, DateTime expiryDate)
        {
            var today = DateTime.Today;

            if (expiryDate == default)
            {
                return "Vui lòng nhập hạn sử dụng hợp lệ.";
            }

            if (manufactureDate.HasValue && manufactureDate.Value.Date > today)
            {
                return "Ngày sản xuất phải bằng hoặc trước ngày hiện tại.";
            }

            if (expiryDate.Date < today)
            {
                return "Hạn sử dụng phải bằng hoặc sau ngày hiện tại.";
            }

            if (manufactureDate.HasValue && expiryDate.Date < manufactureDate.Value.Date)
            {
                return "Hạn sử dụng phải sau hoặc bằng ngày sản xuất.";
            }

            return null;
        }
    }

    public class QcUpdateDto
    {
        public string Status { get; set; } = string.Empty;
    }
}
