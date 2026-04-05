using GMP_System.Entities;
using GMP_System.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;

namespace GMP_System.Controllers
{
    [Route("api/batch-process-logs")]
    [ApiController]
    public class BatchProcessLogsController : ControllerBase
    {
        private readonly IUnitOfWork _unitOfWork;

        public BatchProcessLogsController(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        // 1. Xem nhật ký của một Lô cụ thể (Virtual Workflow: Routing + Logs)
        [HttpGet("batch/{batchId}")]
        public async Task<IActionResult> GetLogsByBatch(int batchId)
        {
            // 1. Lấy mẻ sản xuất kèm Recipe và Định tuyến đầy đủ
            var batch = await _unitOfWork.ProductionBatches.Query()
                .Include(b => b.Order)
                    .ThenInclude(o => o!.Recipe)
                        .ThenInclude(r => r!.RecipeRoutings)
                            .ThenInclude(rr => rr.StepParameters) 
                .Include(b => b.Order)
                    .ThenInclude(o => o!.Recipe)
                        .ThenInclude(r => r!.Material) // Đảm bảo lấy được Material
                .FirstOrDefaultAsync(b => b.BatchId == batchId);

            if (batch == null) return NotFound(new { success = false, message = "Không tìm thấy mẻ." });

            // 2. Lấy danh sách các bước định nghĩa trong Recipe
            var routings = batch.Order?.Recipe?.RecipeRoutings
                .OrderBy(r => r.StepNumber)
                .ToList() ?? new List<RecipeRouting>();

            // 3. Lấy các log thực tế đã phát sinh
            var existingLogs = await _unitOfWork.BatchProcessLogs.Query()
                .Include(x => x.Routing)
                    .ThenInclude(r => r!.StepParameters)
                .Include(x => x.ParameterValues)
                    .ThenInclude(pv => pv.Parameter!)
                .Where(x => x.BatchId == batchId)
                .ToListAsync();

            // 4. Ghép nối (Join): Mỗi Routing Step phải xuất hiện, kèm theo Log nếu có
            var workflow = routings.Select(r => {
                var log = existingLogs.FirstOrDefault(l => l.RoutingId == r.RoutingId);
                return new {
                    // Cấp độ gốc
                    stepId = r.RoutingId,
                    logId = log?.LogId,
                    resultStatus = log?.ResultStatus ?? "None",
                    startTime = log?.StartTime,
                    endTime = log?.EndTime,
                    parametersData = log?.ParametersData,
                    isDeviation = log?.IsDeviation ?? false,
                    // Đối tượng step (Tương thích với mobile UI hiện tại)
                    step = new {
                        stepId = r.RoutingId,
                        stepName = r.StepName,
                        stepNumber = r.StepNumber
                    },
                    // Đối tượng routing (Chứa thông số chuẩn cho Min-Max)
                    routing = new {
                        routingId = r.RoutingId,
                        stepName = r.StepName,
                        stepParameters = r.StepParameters ?? new List<StepParameter>() 
                    }
                };
            });

            return Ok(new { data = workflow, success = true, count = routings.Count });
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] BatchProcessLog log)
        {
            if (log == null) return BadRequest("Dữ liệu không hợp lệ.");

            // --- UPSERT LOGIC (Sửa nếu đã tồn tại, tránh trùng lặp cho 5 bước nhỏ) ---
            var existingLog = await _unitOfWork.BatchProcessLogs.Query()
                .Include(x => x.ParameterValues)
                .FirstOrDefaultAsync(x => x.BatchId == log.BatchId && x.RoutingId == log.RoutingId);

            BatchProcessLog activeLog = log;
            bool isNew = true;

            if (existingLog != null)
            {
                activeLog = existingLog;
                isNew = false;
                
                // Cập nhật thông tin cơ bản
                activeLog.OperatorId = log.OperatorId ?? activeLog.OperatorId;
                activeLog.EquipmentId = log.EquipmentId ?? activeLog.EquipmentId;
                activeLog.ParametersData = log.ParametersData ?? activeLog.ParametersData;
                activeLog.Notes = log.Notes ?? activeLog.Notes;
                activeLog.StartTime = log.StartTime != default ? log.StartTime : activeLog.StartTime;
                activeLog.EndTime = log.EndTime != default ? log.EndTime : activeLog.EndTime;
            }

            if (activeLog.StartTime == default) activeLog.StartTime = DateTime.Now;
            if (activeLog.EndTime == default) activeLog.EndTime = DateTime.Now;

            // Nếu client truyền lên trang thái cụ thể (vd: Running, PendingQC) thì dùng,
            // nếu không mặc định là PendingQC để giữ logic cũ.
            if (!string.IsNullOrEmpty(log.ResultStatus))
                activeLog.ResultStatus = log.ResultStatus;
            else if (isNew)
                activeLog.ResultStatus = "PendingQC";

            activeLog.IsDeviation = false;

            // --- BÓC TÁCH & KIỂM TRA THÔNG SỐ (DEVIATION CHECK) ---
            if (!string.IsNullOrEmpty(log.ParametersData))
            {
                // Xóa ParameterValues cũ để nạp lại từ ParametersData mới nhất
                activeLog.ParameterValues.Clear();
                
                try 
                {
                    var paramsDict = JsonSerializer.Deserialize<Dictionary<string, object>>(log.ParametersData);
                    if (paramsDict != null && log.RoutingId.HasValue)
                    {
                        var standardParams = await _unitOfWork.StepParameters.Query()
                            .Where(sp => sp.RoutingId == log.RoutingId)
                            .ToListAsync();

                        foreach (var sp in standardParams)
                        {
                            // Tìm giá trị trong JSON có phím trùng tên hoặc chứa tên
                            var entry = paramsDict.FirstOrDefault(p => 
                                p.Key.Equals(sp.ParameterName, StringComparison.OrdinalIgnoreCase) ||
                                sp.ParameterName.Contains(p.Key, StringComparison.OrdinalIgnoreCase));
                            
                            if (entry.Key != null)
                            {
                                decimal actualVal = 0;
                                string valStr = entry.Value?.ToString() ?? "0";
                                if (decimal.TryParse(valStr, out actualVal))
                                {
                                    // Lưu vào bảng Value
                                    activeLog.ParameterValues.Add(new BatchProcessParameterValue
                                    {
                                        ParameterId = sp.ParameterId,
                                        ActualValue = actualVal,
                                        RecordedDate = DateTime.Now
                                    });

                                    // Kiểm tra sai lệch (Range check)
                                    if (sp.MinValue.HasValue && actualVal < sp.MinValue.Value) activeLog.IsDeviation = true;
                                    if (sp.MaxValue.HasValue && actualVal > sp.MaxValue.Value) activeLog.IsDeviation = true;
                                }
                            }
                        }
                    }
                }
                catch { /* Bỏ qua nếu JSON lỗi format */ }
            }

            // --- AUTO-PROGRESSION: Nếu công đoạn đã hoàn thành (Passed) -> Tăng CurrentStep cho mẻ ---
            if (activeLog.ResultStatus == "Passed" && activeLog.BatchId.HasValue && activeLog.RoutingId.HasValue)
            {
                var batch = await _unitOfWork.ProductionBatches.GetByIdAsync(activeLog.BatchId.Value);
                if (batch != null)
                {
                    var currentRouting = await _unitOfWork.RecipeRoutings.GetByIdAsync(activeLog.RoutingId.Value);
                    if (currentRouting != null)
                    {
                        batch.CurrentStep = currentRouting.StepNumber + 1;
                        _unitOfWork.ProductionBatches.Update(batch);
                    }
                }
            }

            if (isNew)
                await _unitOfWork.BatchProcessLogs.AddAsync(activeLog);
            else
                _unitOfWork.BatchProcessLogs.Update(activeLog);

            await _unitOfWork.CompleteAsync();

            return Ok(new { 
                Message = activeLog.IsDeviation == true ? "Ghi nhật ký thành công (CẢNH BÁO TỒN TẠI SAI LỆCH)!" : "Ghi nhật ký thành công!",
                LogId = activeLog.LogId,
                IsDeviation = activeLog.IsDeviation
            });
        }

        // 3. QC Phê duyệt công đoạn
        [HttpPost("verify")]
        public async Task<IActionResult> Verify([FromBody] JsonElement body)
        {
            if (!body.TryGetProperty("logId", out var logIdProp) || !body.TryGetProperty("verifierId", out var verifierIdProp))
                return BadRequest("Thiếu thông tin LogId hoặc VerifierId.");

            long logId = logIdProp.GetInt64();
            int verifierId = verifierIdProp.GetInt32();
            string status = body.TryGetProperty("status", out var s) ? s.GetString() ?? "Passed" : "Passed";
            string? notes = body.TryGetProperty("notes", out var n) ? n.GetString() : null;

            var log = await _unitOfWork.BatchProcessLogs.GetByIdAsync((int)logId);
            if (log == null) return NotFound("Không tìm thấy nhật ký.");

            log.VerifiedById = verifierId;
            log.VerifiedDate = DateTime.Now;
            log.ResultStatus = status; // Thường là Passed hoặc Failed
            if (!string.IsNullOrEmpty(notes)) log.Notes = (log.Notes ?? "") + "\nQC Note: " + notes;

            await _unitOfWork.CompleteAsync();
            return Ok(new { Message = "Xác nhận QC thành công!", Status = log.ResultStatus });
        }
    }
}