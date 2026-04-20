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

        private static readonly HashSet<string> RepeatableFailureStatuses = new(StringComparer.OrdinalIgnoreCase)
        {
            "Failed",
            "Rejected",
            "OnHold",
            "Hold"
        };

        private static readonly HashSet<string> AttemptStartStatuses = new(StringComparer.OrdinalIgnoreCase)
        {
            "Running",
            "PendingQC",
            "Passed"
        };

        public BatchProcessLogsController(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        [HttpGet("batch/{batchId}")]
        public async Task<IActionResult> GetLogsByBatch(int batchId)
        {
            var batch = await _unitOfWork.ProductionBatches.GetByIdAsync(batchId);
            if (batch == null) return NotFound(new { success = false, message = "KhÃ´ng tÃ¬m tháº¥y máº»." });

            var order = await _unitOfWork.ProductionOrders.Query()
                .Include(o => o.Recipe)
                .FirstOrDefaultAsync(o => o.OrderId == batch.OrderId);

            if (order == null) return NotFound(new { success = false, message = "KhÃ´ng tÃ¬m tháº¥y lá»‡nh sáº£n xuáº¥t." });

            // Prioritize Order-specific routings (custom steps)
            var routings = await _unitOfWork.RecipeRoutings.Query()
                .Where(r => r.OrderId == batch.OrderId)
                .Include(r => r.StepParameters)
                .OrderBy(r => r.StepNumber)
                .ToListAsync();

            if (routings == null || routings.Count == 0)
            {
                // Fallback to Recipe-default routings
                // Some older data might have OrderId = 0 instead of NULL
                routings = await _unitOfWork.RecipeRoutings.Query()
                    .Where(r => r.RecipeId == order.RecipeId && (r.OrderId == null || r.OrderId == 0))
                    .Include(r => r.StepParameters)
                    .OrderBy(r => r.StepNumber)
                    .ToListAsync();
            }

            var existingLogs = await _unitOfWork.BatchProcessLogs.Query()
                .Include(x => x.Routing)
                    .ThenInclude(r => r!.StepParameters)
                .Where(x => x.BatchId == batchId)
                .ToListAsync();

            var workflow = routings.Select(r =>
            {
                var logsForStep = existingLogs.Where(l => l.RoutingId == r.RoutingId)
                    .OrderBy(l => l.NumberOfRouting)
                    .ThenBy(l => l.LogId)
                    .Select(log => new
                    {
                        logId = log.LogId,
                        resultStatus = log.ResultStatus,
                        startTime = log.StartTime,
                        endTime = log.EndTime,
                        parametersData = log.ParametersData,
                        isDeviation = log.IsDeviation,
                        numberOfRouting = log.NumberOfRouting
                    })
                    .ToList();

                var latestLog = logsForStep.LastOrDefault();
                var configuredAttempts = Math.Max(1, r.NumberOfRouting ?? 1);

                return new
                {
                    stepId = r.RoutingId,
                    logId = latestLog?.logId,
                    resultStatus = latestLog?.resultStatus ?? "None",
                    startTime = latestLog?.startTime,
                    endTime = latestLog?.endTime,
                    parametersData = latestLog?.parametersData,
                    isDeviation = latestLog?.isDeviation ?? false,
                    numberOfRouting = latestLog?.numberOfRouting ?? 1,
                    step = new
                    {
                        stepId = r.RoutingId,
                        stepName = r.StepName,
                        stepNumber = r.StepNumber
                    },
                    numberOfRoutingConfig = configuredAttempts,
                    logs = logsForStep,
                    latestLog,
                    routing = new
                    {
                        routingId = r.RoutingId,
                        stepName = r.StepName,
                        stepParameters = (r.StepParameters ?? new List<StepParameter>()).Select(sp => new
                        {
                            sp.ParameterId,
                            sp.ParameterName,
                            sp.Unit,
                            sp.MinValue,
                            sp.MaxValue,
                            sp.IsCritical
                        }).ToList()
                    }
                };
            });

            return Ok(new { data = workflow, success = true, count = routings.Count });
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] BatchProcessLog log)
        {
            if (log == null) return BadRequest("Dá»¯ liá»‡u khÃ´ng há»£p lá»‡.");
            if (!log.BatchId.HasValue || !log.RoutingId.HasValue)
                return BadRequest("Thiáº¿u BatchId hoáº·c RoutingId.");

            var routing = await _unitOfWork.RecipeRoutings.GetByIdAsync(log.RoutingId.Value);
            if (routing == null)
                return BadRequest("KhÃ´ng tÃ¬m tháº¥y cÃ´ng Ä‘oáº¡n quy trÃ¬nh.");

            var maxAttempts = Math.Max(1, routing.NumberOfRouting ?? 1);
            var stepLogs = await _unitOfWork.BatchProcessLogs.Query()
                .Include(x => x.ParameterValues)
                .Where(x => x.BatchId == log.BatchId && x.RoutingId == log.RoutingId)
                .OrderBy(x => x.NumberOfRouting)
                .ThenBy(x => x.LogId)
                .ToListAsync();

            var latestStepLog = stepLogs.LastOrDefault();
            var resolvedAttempt = ResolveAttemptNumber(log.NumberOfRouting, latestStepLog, log.ResultStatus, maxAttempts);
            if (resolvedAttempt > maxAttempts)
            {
                return BadRequest(new
                {
                    success = false,
                    message = $"CÃ´ng Ä‘oáº¡n nÃ y chá»‰ Ä‘Æ°á»£c thá»±c hiá»‡n tá»‘i Ä‘a {maxAttempts} láº§n."
                });
            }

            var existingLog = stepLogs.FirstOrDefault(x => (x.NumberOfRouting ?? 1) == resolvedAttempt);

            BatchProcessLog activeLog = log;
            bool isNew = true;

            if (existingLog != null)
            {
                activeLog = existingLog;
                isNew = false;
                activeLog.OperatorId = log.OperatorId ?? activeLog.OperatorId;
                activeLog.EquipmentId = log.EquipmentId ?? activeLog.EquipmentId;
                activeLog.ParametersData = log.ParametersData ?? activeLog.ParametersData;
                activeLog.Notes = log.Notes ?? activeLog.Notes;
                activeLog.StartTime = log.StartTime != default ? log.StartTime : activeLog.StartTime;
                activeLog.EndTime = log.EndTime != default ? log.EndTime : activeLog.EndTime;
            }

            activeLog.NumberOfRouting = resolvedAttempt;

            if (activeLog.StartTime == default) activeLog.StartTime = DateTime.Now;
            if (activeLog.EndTime == default) activeLog.EndTime = DateTime.Now;

            if (!string.IsNullOrEmpty(log.ResultStatus))
                activeLog.ResultStatus = log.ResultStatus;
            else if (isNew)
                activeLog.ResultStatus = "PendingQC";

            activeLog.IsDeviation = false;

            if (!string.IsNullOrEmpty(log.ParametersData))
            {
                activeLog.ParameterValues.Clear();

                try
                {
                    var paramsDict = JsonSerializer.Deserialize<Dictionary<string, object>>(log.ParametersData);
                    if (paramsDict != null)
                    {
                        var standardParams = await _unitOfWork.StepParameters.Query()
                            .Where(sp => sp.RoutingId == log.RoutingId)
                            .ToListAsync();

                        foreach (var sp in standardParams)
                        {
                            var entry = paramsDict.FirstOrDefault(p =>
                                p.Key.Equals(sp.ParameterName, StringComparison.OrdinalIgnoreCase) ||
                                sp.ParameterName.Contains(p.Key, StringComparison.OrdinalIgnoreCase));

                            if (entry.Key == null) continue;
                            if (!decimal.TryParse(entry.Value?.ToString() ?? "0", out var actualVal)) continue;

                            activeLog.ParameterValues.Add(new BatchProcessParameterValue
                            {
                                ParameterId = sp.ParameterId,
                                ActualValue = actualVal,
                                RecordedDate = DateTime.Now
                            });

                            if (sp.MinValue.HasValue && actualVal < sp.MinValue.Value) activeLog.IsDeviation = true;
                            if (sp.MaxValue.HasValue && actualVal > sp.MaxValue.Value) activeLog.IsDeviation = true;

                            // Logic kiểm tra ĐỘ ẨM để tự động yêu cầu sấy lại (Rework Loop)
                            bool isHumidityParam = sp.ParameterName.Contains("Độ ẩm", StringComparison.OrdinalIgnoreCase) || 
                                                 sp.ParameterName.Contains("Do am", StringComparison.OrdinalIgnoreCase);

                            if (isHumidityParam && sp.MaxValue.HasValue && actualVal > sp.MaxValue.Value)
                            {
                                activeLog.ResultStatus = "Failed";
                                activeLog.IsDeviation = true;
                                activeLog.Notes = (activeLog.Notes ?? "") + 
                                    $"\n[SYSTEM] Kết quả Độ ẩm ({actualVal}%) không đạt tiêu chuẩn (<= {sp.MaxValue.Value}%). Hệ thống yêu cầu THỰC HIỆN LẠI công đoạn sấy.";
                            }
                        }
                    }
                }
                catch
                {
                }
            }

            if (activeLog.BatchId.HasValue)
            {
                var batch = await _unitOfWork.ProductionBatches.GetByIdAsync(activeLog.BatchId.Value);
                if (batch != null)
                {
                    if (string.Equals(activeLog.ResultStatus, "Passed", StringComparison.OrdinalIgnoreCase))
                    {
                        batch.CurrentStep = routing.StepNumber + 1;
                        if (string.Equals(batch.Status, "OnHold", StringComparison.OrdinalIgnoreCase))
                        {
                            batch.Status = "In-Process";
                        }
                    }
                    else
                    {
                        batch.CurrentStep = routing.StepNumber;
                        if (IsFailureStatus(activeLog.ResultStatus) && resolvedAttempt >= maxAttempts)
                        {
                            batch.Status = "OnHold";
                        }
                    }

                    _unitOfWork.ProductionBatches.Update(batch);
                }
            }

            if (isNew)
                await _unitOfWork.BatchProcessLogs.AddAsync(activeLog);
            else
                _unitOfWork.BatchProcessLogs.Update(activeLog);

            await _unitOfWork.CompleteAsync();

            return Ok(new
            {
                Message = activeLog.IsDeviation == true
                    ? "Ghi nháº­t kÃ½ thÃ nh cÃ´ng (Cáº¢NH BÃO Tá»’N Táº I SAI Lá»†CH)!"
                    : "Ghi nháº­t kÃ½ thÃ nh cÃ´ng!",
                LogId = activeLog.LogId,
                IsDeviation = activeLog.IsDeviation,
                NumberOfRouting = activeLog.NumberOfRouting,
                MaxNumberOfRouting = maxAttempts
            });
        }

        [HttpPost("verify")]
        public async Task<IActionResult> Verify([FromBody] JsonElement body)
        {
            if (!body.TryGetProperty("logId", out var logIdProp) || !body.TryGetProperty("verifierId", out var verifierIdProp))
                return BadRequest("Thiáº¿u thÃ´ng tin LogId hoáº·c VerifierId.");

            long logId = logIdProp.GetInt64();
            int verifierId = verifierIdProp.GetInt32();
            string status = body.TryGetProperty("status", out var s) ? s.GetString() ?? "Passed" : "Passed";
            string? notes = body.TryGetProperty("notes", out var n) ? n.GetString() : null;

            var log = await _unitOfWork.BatchProcessLogs.Query()
                .FirstOrDefaultAsync(x => x.LogId == logId);

            if (log == null) return NotFound("KhÃ´ng tÃ¬m tháº¥y nháº­t kÃ½ máº».");

            log.VerifiedById = verifierId;
            log.VerifiedDate = DateTime.Now;
            log.ResultStatus = status;
            if (!string.IsNullOrEmpty(notes)) log.Notes = (log.Notes ?? "") + "\nQC Note: " + notes;

            if (log.BatchId.HasValue && log.RoutingId.HasValue)
            {
                var batch = await _unitOfWork.ProductionBatches.GetByIdAsync(log.BatchId.Value);
                var routing = await _unitOfWork.RecipeRoutings.GetByIdAsync(log.RoutingId.Value);
                if (batch != null && routing != null)
                {
                    batch.CurrentStep = routing.StepNumber;
                    if (IsFailureStatus(status) && (log.NumberOfRouting ?? 1) >= Math.Max(1, routing.NumberOfRouting ?? 1))
                    {
                        batch.Status = "OnHold";
                    }

                    _unitOfWork.ProductionBatches.Update(batch);
                }
            }

            await _unitOfWork.CompleteAsync();
            return Ok(new { Message = "XÃ¡c nháº­n QC thÃ nh cÃ´ng!", Status = log.ResultStatus });
        }

        private static int ResolveAttemptNumber(int? requestedAttempt, BatchProcessLog? latestStepLog, string? incomingStatus, int maxAttempts)
        {
            if (requestedAttempt.HasValue && requestedAttempt.Value > 0)
            {
                return requestedAttempt.Value;
            }

            if (latestStepLog == null)
            {
                return 1;
            }

            var latestAttempt = Math.Max(1, latestStepLog.NumberOfRouting ?? 1);
            if (latestAttempt < maxAttempts &&
                IsFailureStatus(latestStepLog.ResultStatus) &&
                IsAttemptStartStatus(incomingStatus))
            {
                return latestAttempt + 1;
            }

            return latestAttempt;
        }

        private static bool IsFailureStatus(string? status)
        {
            return !string.IsNullOrWhiteSpace(status) && RepeatableFailureStatuses.Contains(status);
        }

        private static bool IsAttemptStartStatus(string? status)
        {
            return !string.IsNullOrWhiteSpace(status) && AttemptStartStatuses.Contains(status);
        }
    }
}
