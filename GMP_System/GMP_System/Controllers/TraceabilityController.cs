using GMP_System.Entities;
using GMP_System.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace GMP_System.Controllers
{
    // Định nghĩa đường dẫn base cho toàn bộ Controller (Route). Bắt HTTP Call dạng: http://localhost/api/Traceability
    [Route("api/[controller]")]
    // Đánh dấu đây là API Controller chuyên phục vụ Data (JSON), tự động bắt lỗi Model Validation ngầm định
    [ApiController]
    public class TraceabilityController : ControllerBase
    {
        // Khai báo Dependency Injection (DI) để kết nối UnitOfWork thao tác với cơ sở dữ liệu Entity Framework
        // Từ khóa 'readonly' bảo vệ biến này không bị gán đè (override) sau khi khởi tạo -> tránh lỗi đứt tham chiếu
        private readonly IUnitOfWork _unitOfWork;

        // Constructor mặc định. Hệ thống .NET Service Container sẽ tự động cấp một Instance của UnitOfWork nhét vào Constructor này.
        public TraceabilityController(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork; // Lưu vào trường nội bộ (private field) để các hàm bên dưới gọi cơ sở dữ liệu thoải mái.
        }

        // GET: /api/traceability/backward/{batchNumber}
        // API Truy xuất ngược (Backward Traceability): 
        // Lấy thông tin từ 1 Lô sản phẩm hoàn chỉnh (Thành phẩm) và truy lùi lại toàn bộ
        // danh sách số lô nguyên liệu đầu vào đã dùng tạo ra nó, nhằm phục vụ thu hồi/kiểm kê.
        [HttpGet("backward/{batchNumber}")]
        public async Task<IActionResult> Backward(string batchNumber)
        {
            // BƯỚC 1: Gọi hàm bất đồng bộ (await) GetAllAsync() để Load trọn vẹn danh sách lô sản xuất từ bảng ProductionBatches.
            // Điều này ép giải phóng Theard pool (luồng xử lý) rảnh tay phục vụ HTTP khác trong lúc chờ Database query.
            var batches = await _unitOfWork.ProductionBatches.GetAllAsync();
            // Sử dụng LINQ FirstOrDefault quét dò xem Lô (batch) nào có thông tin BatchNumber trùng mảng param truyền từ URL vào.
            // StringComparison.OrdinalIgnoreCase so sánh String loại trừ tính chất Hoa/Thường (VD: Batch01 vs batch01 được xem là bằng nhau).
            var targetBatch = batches.FirstOrDefault(b => b.BatchNumber != null && b.BatchNumber.Contains(batchNumber, StringComparison.OrdinalIgnoreCase));

            if (targetBatch == null)
            {
                // Return HTTP Status 404 (Not Found) nếu LINQ trả null. Thả thông báo lỗi bằng tiếng Việt String Interpolation ($"").
                return NotFound($"Không tìm thấy lô sản xuất với mã: {batchNumber}");
            }

            // BƯỚC 2: Truy vấn dữ liệu Quan hệ (Navigation Properties do EntityFramework bảo hộ) liên quan đến Lô sản xuất.
            var order = targetBatch.Order; // Lấy ra Phiếu Lệnh Sản Xuất (Production Order) đã sinh ra Lô Thành Phẩm này.
            var recipe = order?.Recipe; // Toán tử '?.' (Null-conditional) phòng rủi ro biến cha order bị rỗng sẽ ko ném ra NullReferenceException.

            // BƯỚC 3: Tìm toàn bộ rễ nguyên liệu (Root) mà lô thành phẩm này đã "hút" làm cấu thành.
            // GetAllAsync: Trải phẳng bảng MaterialUsages (Lịch sử sử dụng nguyên vật liệu).
            var materialUsages = await _unitOfWork.MaterialUsages.GetAllAsync();
            // Trích lọc trích xuất các Record có mã lô sản xuất bằng với Mã lô ta đang điều tra (targetBatch.BatchId).
            var batchUsages = materialUsages.Where(m => m.BatchId == targetBatch.BatchId).ToList();

            // BƯỚC 4: Chế biến dữ liệu thô (.NET Objects) thành đối tượng trung gian (Anonymous Type object) - cấu trúc Cây JSON API.
            var result = new
            {
                batchNumber = batchNumber,
                finishedGood = new
                {
                    // Toán tử '??' (Null-coalescing): Nếu không tìm được Vật tư (vế trái null), hãy ép gán chuỗi default thay thế "Unknown" (Vế phải).
                    name = recipe?.Material?.MaterialName ?? "Unknown",
                    batchNumber = batchNumber,
                    // Parse DateTime? thành Chuỗi String format ISO (yyyy-MM-dd) giúp FE Client (React) dễ parse Calendar.
                    producedDate = targetBatch.ManufactureDate?.ToString("yyyy-MM-dd") ?? "",
                    quantity = order?.PlannedQuantity ?? 0
                },
                // Dùng .Select mapping danh sách dòng Sử Dụng Vật Tư (List Type C#) thành mảng đối tượng cục bộ có cấu trúc tĩnh (Array List JSON).
                rawMaterials = batchUsages.Select(u => new
                {
                    name = u.InventoryLot?.Material?.MaterialName ?? "Unknown",
                    batchNumber = u.InventoryLot?.LotNumber ?? "N/A",
                    quantity = u.ActualAmount, // Khối lượng nguyên vật liệu bị khấu trừ đi tạo sản phẩm.
                    supplier = "N/A", // Trường tĩnh (Placeholder field) đề phòng bảng Nhà Cung Cấp chưa code kịp Data Model
                    qcStatus = u.InventoryLot?.Qcstatus ?? "N/A"
                }).ToList()
            };

            // BƯỚC 5: Bao gói Object Dictionary JSON Result này vào một hộp HTTP OK và xuất phản hồi Status 200 ra Socket Response.
            return Ok(result);
        }

        // GET: /api/traceability/forward/{lotNumber}
        // API Truy xuất xuôi (Forward Traceability): 
        // Nhận vào số lô nguyên liệu, từ đó tra cứu bảng MaterialUsages xem nguyên liệu này
        // đã được dùng để sản xuất ra những Lô thành phẩm nào (Production Batches).
        // Cực kỳ quan trọng để khoanh vùng sản phẩm khi khiếu nại nguyên liệu nhập có lỗi.
        [HttpGet("forward/{lotNumber}")]
        public async Task<IActionResult> Forward(string lotNumber)
        {
            // Tìm Inventory Lots: Trải phẳng mảng lưu trong kho (Bảng Lô Nguyên Liệu).
            var lots = await _unitOfWork.InventoryLots.GetAllAsync();
            // Lọc ra Lô khớp tuyệt đối với số lô (LotNumber) mà hàm cung cấp (truy tìm gắt gao lỗi).
            var lot = lots.FirstOrDefault(l => l.LotNumber != null && l.LotNumber.Contains(lotNumber, StringComparison.OrdinalIgnoreCase));

            if (lot == null)
            {
                return NotFound($"Không tìm thấy lô nguyên liệu với mã: {lotNumber}");
            }

            // Gieo mẻ lưới càn quét bảng tiêu hao lịch sử (MaterialUsages) nơi bắt gặp lô kho này được xả ra làm pha chế.
            var materialUsages = await _unitOfWork.MaterialUsages.GetAllAsync();
            // Nhặt danh sách các Record thể hiện lô này bị vắt sữa.
            var usages = materialUsages.Where(m => m.InventoryLotId == lot.LotId).ToList();

            // Cập nhật list tổng danh sách Các Mẻ Sản Xuất (Batches) trên hệ thống.
            var batches = await _unitOfWork.ProductionBatches.GetAllAsync();
            // Đẩy ID mẻ thành List độc lập.
            // Hàm Distinct() chặn tình trạng: Ví dụ người ta thêm 2 lần Nguyên Liệu đó vào 1 mẻ, Distinct triệt tiêu bớt nhánh trùng ID.
            var batchIds = usages.Select(u => u.BatchId).Distinct().ToList();
            // Lọc list đối tượng Batches nào nằm trong khu vực "Lô bị nhúng tràm/Ảnh hưởng khoanh vùng"
            var usedBatches = batches.Where(b => batchIds.Contains(b.BatchId)).ToList();

            // Nhồi Cấu trúc JSON API Response
            var result = new
            {
                lotNumber = lotNumber,
                materialName = lot.Material?.MaterialName ?? "Unknown",
                supplier = "N/A",
                quantityReceived = lot.QuantityCurrent, // Thông số cân nặng nguyên liệu đang xót lại trong kho
                usedInBatches = usedBatches.Select(b => new
                {
                    batchNumber = b.BatchNumber,
                    productionDate = b.ManufactureDate?.ToString("yyyy-MM-dd") ?? "", // Phơi ngày sản xuất
                    // Rung cây dò lại bảng Logs Usage xem mẻ lô Thành Phẩm này thực thi ăn bao nhiêu kí của kiện Nguyên Vật Liệu nọ bằng LINQ Lambda
                    quantityUsed = usages.FirstOrDefault(u => u.BatchId == b.BatchId)?.ActualAmount ?? 0,
                    product = b.Order?.Recipe?.Material?.MaterialName ?? "Unknown" // Truy vấn móc ngang Component cấu thành
                }).ToList()
            };

            return Ok(result);
        }
    }
}
