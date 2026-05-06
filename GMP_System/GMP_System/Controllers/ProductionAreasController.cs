using GMP_System.Entities;
using GMP_System.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GMP_System.Controllers
{
    [Route("api/[controller]")]
    [Route("api/areas")]
    [ApiController]
    public class ProductionAreasController : ControllerBase
    {
        private readonly IUnitOfWork _unitOfWork;

        public ProductionAreasController(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var rows = await _unitOfWork.ProductionAreas.Query()
                .OrderBy(a => a.AreaName)
                .ToListAsync();

            var areaIds = rows.Select(x => x.AreaId).ToList();
            var inProcessAreaIds = await (
                from rr in _unitOfWork.RecipeRoutings.Query()
                join po in _unitOfWork.ProductionOrders.Query() on rr.OrderId equals po.OrderId
                where rr.AreaId.HasValue
                    && areaIds.Contains(rr.AreaId.Value)
                    && po.Status != null
                    && po.Status.ToLower() == "inprocess"
                select rr.AreaId!.Value
            ).Distinct().ToListAsync();

            var inProcessSet = new HashSet<int>(inProcessAreaIds);
            var data = rows.Select(a => new
            {
                a.AreaId,
                a.AreaCode,
                a.AreaName,
                a.Description,
                IsInUseByInProcessOrder = inProcessSet.Contains(a.AreaId),
                CanEdit = !inProcessSet.Contains(a.AreaId),
                CanDelete = !inProcessSet.Contains(a.AreaId)
            });

            return Ok(new { success = true, data });
        }

        [HttpPost]
        public async Task<IActionResult> Create(ProductionArea area)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            await _unitOfWork.ProductionAreas.AddAsync(area);
            await _unitOfWork.CompleteAsync();
            return Ok(new { success = true, data = area });
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, ProductionArea area)
        {
            if (id != area.AreaId)
                return BadRequest(new { success = false, message = "ID tren URL va trong body khong khop nhau." });

            var existing = await _unitOfWork.ProductionAreas.GetByIdAsync(id);
            if (existing == null) return NotFound(new { success = false, message = "Khong tim thay khu san xuat." });

            var isInProcess = await (
                from rr in _unitOfWork.RecipeRoutings.Query()
                join po in _unitOfWork.ProductionOrders.Query() on rr.OrderId equals po.OrderId
                where rr.AreaId == id && po.Status != null && po.Status.ToLower() == "inprocess"
                select rr.RoutingId
            ).AnyAsync();

            if (isInProcess)
            {
                return Conflict(new
                {
                    success = false,
                    message = "Khu san xuat dang duoc su dung boi lenh san xuat InProcess, khong the chinh sua."
                });
            }

            existing.AreaCode = area.AreaCode;
            existing.AreaName = area.AreaName;
            existing.Description = area.Description;

            _unitOfWork.ProductionAreas.Update(existing);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, message = "Cap nhat thanh cong!", areaId = id });
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var existing = await _unitOfWork.ProductionAreas.GetByIdAsync(id);
            if (existing == null) return NotFound(new { success = false, message = "Khong tim thay khu san xuat." });

            var isInProcess = await (
                from rr in _unitOfWork.RecipeRoutings.Query()
                join po in _unitOfWork.ProductionOrders.Query() on rr.OrderId equals po.OrderId
                where rr.AreaId == id && po.Status != null && po.Status.ToLower() == "inprocess"
                select rr.RoutingId
            ).AnyAsync();

            if (isInProcess)
            {
                return Conflict(new
                {
                    success = false,
                    message = "Khu san xuat dang duoc su dung boi lenh san xuat InProcess, khong the xoa."
                });
            }

            _unitOfWork.ProductionAreas.Remove(existing);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, message = "Xoa thanh cong!", areaId = id });
        }
    }
}
