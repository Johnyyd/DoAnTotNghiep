using GMP_System.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace GMP_System.Controllers
{
    [Route("api/audit-logs")]
    [ApiController]
    public class SystemAuditLogsController : ControllerBase
    {
        private readonly IUnitOfWork _unitOfWork;

        public SystemAuditLogsController(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var logs = await _unitOfWork.SystemAuditLogs.GetAllAsync();
            // Sắp xếp mới nhất lên đầu
            return Ok(logs.OrderByDescending(x => x.ChangedDate));
        }

        // Xem lịch sử của 1 bản ghi cụ thể (VD: Xem lịch sử sửa Công thức số 1)
        [HttpGet("{tableName}/{recordId}")]
        public async Task<IActionResult> GetHistory(string tableName, string recordId)
        {
            var allLogs = await _unitOfWork.SystemAuditLogs.GetAllAsync();
            var history = allLogs
                .Where(x => x.TableName == tableName && x.RecordId == recordId)
                .OrderByDescending(x => x.ChangedDate);
            return Ok(history);
        }
    }
}