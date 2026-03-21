using GMP_System.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

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

        // GET: api/audit-logs?tableName=Recipe&recordId=1
        [HttpGet]
        public async Task<IActionResult> GetAll(
            [FromQuery] string? tableName,
            [FromQuery] string? recordId)
        {
            IQueryable<GMP_System.Entities.SystemAuditLog> query = _unitOfWork.SystemAuditLogs
                .Query()
                .Include(l => l.ChangedByNavigation);

            if (!string.IsNullOrEmpty(tableName))
                query = query.Where(l => l.TableName == tableName);

            if (!string.IsNullOrEmpty(recordId))
                query = query.Where(l => l.RecordId == recordId);

            var logs = await query.OrderByDescending(l => l.ChangedDate).ToListAsync();
            return Ok(new { data = logs, success = true, message = "Success" });
        }

        // GET: api/audit-logs/{tableName}/{recordId}
        [HttpGet("{tableName}/{recordId}")]
        public async Task<IActionResult> GetHistory(string tableName, string recordId)
        {
            var history = await _unitOfWork.SystemAuditLogs
                .Query()
                .Include(l => l.ChangedByNavigation)
                .Where(l => l.TableName == tableName && l.RecordId == recordId)
                .OrderByDescending(l => l.ChangedDate)
                .ToListAsync();

            return Ok(new { data = history, success = true, message = "Success" });
        }
    }
}