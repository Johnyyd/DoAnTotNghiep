using GMP_System.Entities;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GMP_System.Controllers
{
    [Route("api/storage-locations")]
    [ApiController]
    public class StorageLocationsController : ControllerBase
    {
        private readonly GmpContext _context;

        public StorageLocationsController(GmpContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var usedIds = await _context.InventoryLots
                .Where(l => l.LocationId != null)
                .Select(l => l.LocationId!.Value)
                .Distinct()
                .ToListAsync();

            var usedSet = new HashSet<int>(usedIds);
            var rows = await _context.StorageLocations
                .OrderBy(l => l.LocationCode)
                .ToListAsync();

            var data = rows.Select(location => new
            {
                location.LocationId,
                location.LocationCode,
                location.LocationName,
                location.LocationType,
                location.TemperatureMin,
                location.TemperatureMax,
                location.HumidityMin,
                location.HumidityMax,
                location.CleanlinessStatus,
                location.IsQualified,
                location.Note,
                IsInUse = usedSet.Contains(location.LocationId),
                CanEdit = !usedSet.Contains(location.LocationId)
            });

            return Ok(new { success = true, data });
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] StorageLocation location)
        {
            var validationError = Validate(location);
            if (validationError != null)
            {
                return BadRequest(new { success = false, message = validationError });
            }

            location.LocationCode = location.LocationCode.Trim().ToUpperInvariant();
            location.LocationName = location.LocationName.Trim();
            _context.StorageLocations.Add(location);
            await _context.SaveChangesAsync();

            return Ok(new { success = true, message = "Đã thêm kho.", data = location });
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] StorageLocation request)
        {
            var existing = await _context.StorageLocations.FindAsync(id);
            if (existing == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy kho." });
            }

            var isInUse = await _context.InventoryLots.AnyAsync(l => l.LocationId == id);
            if (isInUse)
            {
                return Conflict(new { success = false, message = "Kho đã có lô nguyên liệu sử dụng, không thể chỉnh sửa." });
            }

            var validationError = Validate(request);
            if (validationError != null)
            {
                return BadRequest(new { success = false, message = validationError });
            }

            existing.LocationCode = request.LocationCode.Trim().ToUpperInvariant();
            existing.LocationName = request.LocationName.Trim();
            existing.LocationType = request.LocationType;
            existing.TemperatureMin = request.TemperatureMin;
            existing.TemperatureMax = request.TemperatureMax;
            existing.HumidityMin = request.HumidityMin;
            existing.HumidityMax = request.HumidityMax;
            existing.CleanlinessStatus = request.CleanlinessStatus;
            existing.IsQualified = request.IsQualified;
            existing.Note = request.Note;

            await _context.SaveChangesAsync();
            return Ok(new { success = true, message = "Đã cập nhật kho.", data = existing });
        }

        private static string? Validate(StorageLocation location)
        {
            if (string.IsNullOrWhiteSpace(location.LocationCode))
            {
                return "Vui lòng nhập mã kho.";
            }

            if (string.IsNullOrWhiteSpace(location.LocationName))
            {
                return "Vui lòng nhập tên kho.";
            }

            if (location.TemperatureMin.HasValue && location.TemperatureMax.HasValue && location.TemperatureMin > location.TemperatureMax)
            {
                return "Nhiệt độ tối thiểu không được lớn hơn nhiệt độ tối đa.";
            }

            if (location.HumidityMin.HasValue && location.HumidityMax.HasValue && location.HumidityMin > location.HumidityMax)
            {
                return "Độ ẩm tối thiểu không được lớn hơn độ ẩm tối đa.";
            }

            return null;
        }
    }
}
