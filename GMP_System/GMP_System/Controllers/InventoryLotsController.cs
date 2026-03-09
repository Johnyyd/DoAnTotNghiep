using GMP_System.Entities;
using GMP_System.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace GMP_System.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class InventoryLotsController : ControllerBase
    {
        private readonly IUnitOfWork _unitOfWork;

        public InventoryLotsController(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        // 1. Kiểm tra tồn kho (Lấy danh sách các lô có thể dùng)
        [HttpGet("available")]
        public async Task<IActionResult> GetAvailableLots()
        {
            var lots = await _unitOfWork.InventoryLots.GetAllAsync();
            // Lọc: Còn hàng (>0) VÀ Chưa hết hạn VÀ Đã được QC duyệt (Released)
            var available = lots.Where(x => x.QuantityCurrent > 0
                                         && x.ExpiryDate > DateTime.Now
                                         // Lưu ý: Entity của bạn là Qcstatus (chữ s thường)
                                         && x.Qcstatus == "Released")
                                .OrderBy(x => x.ExpiryDate);
            return Ok(available);
        }

        // 2. Nhập Kho Nguyên Liệu
        [HttpPost]
        public async Task<IActionResult> ReceiveMaterial(InventoryLot lot)
        {
            if (lot.MaterialId == null) return BadRequest("Chưa chọn nguyên liệu.");
            if (lot.QuantityCurrent <= 0) return BadRequest("Số lượng nhập phải > 0.");
            if (string.IsNullOrEmpty(lot.LotNumber)) return BadRequest("Thiếu số lô nhà cung cấp.");

            // Mặc định là 'Quarantine'
            lot.Qcstatus = "Quarantine";

            await _unitOfWork.InventoryLots.AddAsync(lot);
            await _unitOfWork.CompleteAsync();

            return Ok(new { Message = "Đã nhập kho thành công!", LotId = lot.LotId });
        }

        // 3. API DUYỆT LÔ (QUAN TRỌNG: Đây là cái bạn đang thiếu)
        [HttpPost("approve")]
        public async Task<IActionResult> ApproveLot(int lotId, string status)
        {
            var lot = await _unitOfWork.InventoryLots.GetByIdAsync(lotId);
            if (lot == null) return BadRequest("Lỗi: Không tìm thấy lô này.");

            // Kiểm tra từ khóa hợp lệ
            if (status != "Released" && status != "Rejected" && status != "Quarantine")
            {
                return BadRequest("Trạng thái phải là: Released, Rejected hoặc Quarantine");
            }

            // Cập nhật trạng thái
            lot.Qcstatus = status;

            await _unitOfWork.CompleteAsync(); // Lưu xuống DB

            return Ok(new
            {
                Message = "Cập nhật QC thành công!",
                LotNumber = lot.LotNumber,
                NewStatus = lot.Qcstatus
            });
        }
    }
}