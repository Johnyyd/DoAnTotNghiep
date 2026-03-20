using GMP_System.Entities;
using GMP_System.Interfaces;
using Microsoft.AspNetCore.Mvc;

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

        // 1. Lấy danh sách các Lô đang chạy
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var batches = await _unitOfWork.ProductionBatches.GetAllAsync();
            return Ok(new { data = batches, success = true, message = "Success" });
        }

        // 2. Bắt đầu một Lô sản xuất mới
        [HttpPost]
        public async Task<IActionResult> Create(ProductionBatch batch)
        {
            // --- VALIDATION ---
            if (batch.OrderId == null)
            {
                return BadRequest("Lỗi: Phải gắn với một Lệnh sản xuất (OrderId).");
            }

            var order = await _unitOfWork.ProductionOrders.GetByIdAsync(batch.OrderId.Value);
            if (order == null)
            {
                return BadRequest("Lỗi: Không tìm thấy Lệnh sản xuất tương ứng.");
            }

            // --- TỰ ĐỘNG ĐIỀN DỮ LIỆU ---
            // 1. Tạo mã lô tự động (Nếu chưa có)
            if (string.IsNullOrEmpty(batch.BatchNumber))
            {
                // Format: BATCH-YYYYMMDD-OrderID (Ví dụ: BATCH-20260205-1)
                batch.BatchNumber = $"BATCH-{DateTime.Now:yyyyMMdd}-{batch.OrderId}";
            }

            // 2. Ngày sản xuất (Khớp với SQL: ManufactureDate)
            batch.ManufactureDate = DateTime.Now;

            // 3. Trạng thái (QUAN TRỌNG: Dùng từ khóa 'In-Process' khớp với SQL Order)
            // SQL mặc định là 'Queued', nhưng khi gọi API Start này nghĩa là muốn chạy luôn
            batch.Status = "In-Process";

            // 4. Bước hiện tại (Mặc định là 0)
            batch.CurrentStep = 0;

            // Lưu Lô sản xuất vào DB
            await _unitOfWork.ProductionBatches.AddAsync(batch);

            // --- LOGIC NGHIỆP VỤ: Cập nhật trạng thái Order cha ---
            // Khi có Lô bắt đầu chạy, thì Lệnh sản xuất cha cũng phải chuyển sang 'In-Process'
            if (order.Status != "In-Process")
            {
                order.Status = "In-Process"; // Nhớ dùng đúng từ có gạch ngang trong SQL
                // _unitOfWork.ProductionOrders.Update(order); // (Bỏ comment dòng này nếu Repository có hàm Update)
            }

            await _unitOfWork.CompleteAsync();

            return Ok(new
            {
                Message = "Đã khởi động lô sản xuất thành công!",
                BatchId = batch.BatchId, // Chú ý: Entity của bạn là BatchId hay BatchID?
                BatchNumber = batch.BatchNumber,
                Status = batch.Status,
                ManufactureDate = batch.ManufactureDate
            });
        }

        // 3. Kết thúc Lô sản xuất (Finish/Close Batch)
        [HttpPost("finish")]
        public async Task<IActionResult> FinishBatch(int batchId)
        {
            // Tìm lô hàng
            var batch = await _unitOfWork.ProductionBatches.GetByIdAsync(batchId);

            if (batch == null) return BadRequest("Lỗi: Không tìm thấy Lô sản xuất này.");

            // Kiểm tra: Chỉ được kết thúc nếu đang chạy
            // Lưu ý: Kiểm tra lại từ khóa trạng thái trong DB của bạn ('Running', 'In-Process' hay 'Started')
            // Ở đây mình check chung chung để tránh lỗi logic
            if (batch.Status == "Completed")
            {
                return BadRequest("Lô này đã kết thúc rồi.");
            }

            // Cập nhật thông tin
            batch.Status = "Completed";
            batch.EndTime = DateTime.Now; // Ghi nhận thời gian kết thúc thực tế

            // (Tùy chọn) Cập nhật luôn Lệnh SX cha (Order) thành Completed nếu cần
            // var order = await _unitOfWork.ProductionOrders.GetByIdAsync(batch.OrderId.Value);
            // order.Status = "Completed";

            await _unitOfWork.CompleteAsync();

            return Ok(new
            {
                Message = "Đã đóng Lô sản xuất thành công!",
                BatchNumber = batch.BatchNumber,
                EndTime = batch.EndTime,
                NewStatus = batch.Status
            });
        }
    }
}