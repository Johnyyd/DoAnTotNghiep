using GMP_System.Entities;
using GMP_System.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace GMP_System.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class BatchProcessLogsController : ControllerBase
    {
        private readonly IUnitOfWork _unitOfWork;

        public BatchProcessLogsController(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        // 1. Xem nhật ký của một Lô cụ thể
        [HttpGet("batch/{batchId}")]
        public async Task<IActionResult> GetLogsByBatch(int batchId)
        {
            var allLogs = await _unitOfWork.BatchProcessLogs.GetAllAsync();
            // SỬA TÊN BIẾN: BatchID (theo SQL) thay vì BatchId
            var batchLogs = allLogs.Where(x => x.BatchId == batchId).OrderBy(x => x.StartTime);
            return Ok(batchLogs);
        }

        // 2. Ghi nhận một bước công việc
        [HttpPost]
        public async Task<IActionResult> Create(BatchProcessLog log)
        {
            // --- VALIDATION ---
            // SỬA TÊN BIẾN: BatchID
            if (log.BatchId == null)
            {
                return BadRequest("Lỗi: Phải gắn với một Lô sản xuất (BatchID).");
            }

            // Kiểm tra Lô có tồn tại không
            var batch = await _unitOfWork.ProductionBatches.GetByIdAsync(log.BatchId.Value);
            if (batch == null) return BadRequest("Lỗi: Không tìm thấy Lô sản xuất này.");

            // --- TỰ ĐỘNG ĐIỀN DỮ LIỆU ---
            // SỬA TÊN BIẾN: StartTime, EndTime (Đã đúng với SQL)
            if (log.StartTime == default) log.StartTime = DateTime.Now;
            if (log.EndTime == default) log.EndTime = DateTime.Now;

            // XỬ LÝ TRẠNG THÁI (Khớp với CHECK constraint)
            if (string.IsNullOrEmpty(log.ResultStatus))
            {
                log.ResultStatus = "Passed";
            }
            else
            {
                // Kiểm tra sơ bộ để tránh lỗi SQL
                var validStatuses = new[] { "Passed", "Failed", "PendingQC" };
                if (!validStatuses.Contains(log.ResultStatus))
                {
                    return BadRequest("Lỗi: Trạng thái (ResultStatus) phải là: Passed, Failed hoặc PendingQC");
                }
            }

            // Lưu vào DB
            await _unitOfWork.BatchProcessLogs.AddAsync(log);
            await _unitOfWork.CompleteAsync();

            return Ok(new
            {
                Message = "Ghi nhật ký thành công!",
                // SỬA TÊN BIẾN: LogID (SQL là BIGINT -> C# là long)
                LogId = log.LogId,
                Status = log.ResultStatus
            });
        }
    }
}