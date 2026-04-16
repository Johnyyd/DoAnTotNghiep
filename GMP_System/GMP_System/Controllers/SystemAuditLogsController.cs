using GMP_System.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GMP_System.Controllers
{
    [Route("api/[controller]")]
    [Route("api/audit-logs")]
    [ApiController]
    [Authorize]
    public class SystemAuditLogsController : ControllerBase
    {
        private readonly IUnitOfWork _unitOfWork;

        public SystemAuditLogsController(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        // GET: api/SystemAuditLogs
        [HttpGet]
        public async Task<IActionResult> GetLogs([FromQuery] string? entityType, [FromQuery] int? entityId, [FromQuery] int limit = 100)
        {
            var query = _unitOfWork.SystemAuditLogs.Query();

            if (!string.IsNullOrEmpty(entityType))
                query = query.Where(l => l.TableName == entityType);

            if (entityId.HasValue)
                query = query.Where(l => l.RecordId == entityId.Value.ToString());

            var logs = await query.OrderByDescending(l => l.ChangedDate)
                                  .Take(limit)
                                  .ToListAsync();

            return Ok(new { success = true, data = logs });
        }

        // GET: api/SystemAuditLogs/EntityType/EntityId
        [HttpGet("{entityType}/{entityId}")]
        public async Task<IActionResult> GetEntityLogs(string entityType, string entityId)
        {
            var logs = await _unitOfWork.SystemAuditLogs.Query()
                                  .Where(l => l.TableName == entityType && l.RecordId == entityId)
                                  .OrderByDescending(l => l.ChangedDate)
                                  .ToListAsync();

            return Ok(new { success = true, data = logs });
        }
    }
}
