using GMP_System.Entities;
using GMP_System.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GMP_System.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class InventoryLotsController : ControllerBase
    {
        private readonly IUnitOfWork _unitOfWork;

        public InventoryLotsController(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        // GET: api/InventoryLots
        [HttpGet]
        public async Task<IActionResult> GetLots([FromQuery] int? materialId, [FromQuery] string? lotNumber)
        {
            var query = _unitOfWork.InventoryLots.Query();
            
            if (materialId.HasValue)
                query = query.Where(l => l.MaterialId == materialId.Value);
            
            if (!string.IsNullOrEmpty(lotNumber))
                query = query.Where(l => l.LotNumber.Contains(lotNumber));

            var lots = await query.Include(l => l.Material).ToListAsync();
            return Ok(new { success = true, data = lots });
        }

        // GET: api/InventoryLots/5
        [HttpGet("{id}")]
        public async Task<IActionResult> GetLot(int id)
        {
            var lot = await _unitOfWork.InventoryLots.GetByIdWithIncludeAsync(id, l => l.Material);
            if (lot == null) return NotFound(new { success = false, message = "Không tìm thấy lô hàng." });

            return Ok(new { success = true, data = lot });
        }

        // POST: api/InventoryLots
        [HttpPost]
        public async Task<IActionResult> CreateLot([FromBody] InventoryLot lot)
        {
            // lot.CreatedAt = DateTime.Now; // InventoryLot doesn't have CreatedAt
            await _unitOfWork.InventoryLots.AddAsync(lot);
            await _unitOfWork.CompleteAsync();

            return CreatedAtAction(nameof(GetLot), new { id = lot.LotId }, new { success = true, data = lot });
        }

        // POST: api/InventoryLots/{id}/qc
        [HttpPost("{id}/qc")]
        public async Task<IActionResult> UpdateQcStatus(int id, [FromBody] QcUpdateDto request)
        {
            var lot = await _unitOfWork.InventoryLots.GetByIdAsync(id);
            if (lot == null) return NotFound(new { success = false, message = "Không tìm thấy lô hàng." });

            lot.Qcstatus = request.Status;
            _unitOfWork.InventoryLots.Update(lot);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, message = "Cập nhật trạng thái QC thành công." });
        }
    }

    public class QcUpdateDto
    {
        public string Status { get; set; } = string.Empty;
    }
}