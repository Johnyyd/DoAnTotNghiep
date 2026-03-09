using GMP_System.Entities;
using GMP_System.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace GMP_System.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class MaterialUsagesController : ControllerBase
    {
        private readonly IUnitOfWork _unitOfWork;

        public MaterialUsagesController(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        // CẤP PHÁT NGUYÊN LIỆU CHO SẢN XUẤT (Dispensing)
        [HttpPost]
        public async Task<IActionResult> DispenseMaterial(MaterialUsage usage)
        {
            // --- 1. Validation ---
            if (usage.InventoryLotId == null) return BadRequest("Phải chọn Lô nguyên liệu để xuất.");
            if (usage.BatchId == null) return BadRequest("Phải gắn với Lô sản xuất đích.");
            if (usage.ActualAmount <= 0) return BadRequest("Khối lượng cấp phát phải > 0.");

            // --- 2. Kiểm tra Lô nguyên liệu ---
            var sourceLot = await _unitOfWork.InventoryLots.GetByIdAsync(usage.InventoryLotId.Value);

            if (sourceLot == null) return BadRequest("Lô nguyên liệu không tồn tại.");

            // Kiểm tra QC: Chỉ được cấp phát lô đã 'Released'
            if (sourceLot.Qcstatus != "Released")
            {
                return BadRequest($"Lô {sourceLot.LotNumber} đang ở trạng thái {sourceLot.Qcstatus}, chưa được phép sử dụng!");
            }

            // Kiểm tra số lượng tồn
            if (sourceLot.QuantityCurrent < usage.ActualAmount)
            {
                return BadRequest($"Kho không đủ hàng! Tồn: {sourceLot.QuantityCurrent}, Yêu cầu: {usage.ActualAmount}");
            }

            // --- 3. Thực hiện Trừ Kho (Logic quan trọng) ---
            sourceLot.QuantityCurrent -= usage.ActualAmount;
            // _unitOfWork.InventoryLots.Update(sourceLot); // (Bỏ comment nếu Repo có hàm Update riêng)

            // --- 4. Ghi nhận lịch sử sử dụng ---
            usage.Timestamp = DateTime.Now;
            await _unitOfWork.MaterialUsages.AddAsync(usage);

            // Lưu tất cả thay đổi (Update Lô + Insert Usage) cùng lúc
            await _unitOfWork.CompleteAsync();

            return Ok(new
            {
                Message = "Cấp phát thành công!",
                UsageID = usage.UsageId,
                RemainingStock = sourceLot.QuantityCurrent
            });
        }
    }
}