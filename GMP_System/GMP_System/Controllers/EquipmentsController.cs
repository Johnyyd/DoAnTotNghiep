using GMP_System.Entities;
using GMP_System.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GMP_System.Controllers
{
    [Route("api/equipments")]
    [ApiController]
    public class EquipmentsController : ControllerBase
    {
        private readonly IUnitOfWork _unitOfWork;

        public EquipmentsController(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var equipments = await _unitOfWork.Equipments.Query()
                .Include(e => e.Area)
                .OrderBy(e => e.EquipmentCode)
                .ToListAsync();

            var ids = equipments.Select(e => e.EquipmentId).ToList();
            var routingUsageIds = await _unitOfWork.RecipeRoutings.Query()
                .Where(r => r.DefaultEquipmentId.HasValue && ids.Contains(r.DefaultEquipmentId.Value) && r.OrderId != null)
                .Select(r => r.DefaultEquipmentId!.Value)
                .Distinct()
                .ToListAsync();
            var logUsageIds = await _unitOfWork.BatchProcessLogs.Query()
                .Where(l => l.EquipmentId.HasValue && ids.Contains(l.EquipmentId.Value))
                .Select(l => l.EquipmentId!.Value)
                .Distinct()
                .ToListAsync();

            var usedIds = new HashSet<int>(routingUsageIds.Concat(logUsageIds));
            var data = equipments.Select(e => new
            {
                e.EquipmentId,
                e.EquipmentCode,
                e.EquipmentName,
                e.TechnicalSpecification,
                e.UsagePurpose,
                e.AreaId,
                Area = e.Area,
                IsUsedInProduction = usedIds.Contains(e.EquipmentId),
                CanEdit = !usedIds.Contains(e.EquipmentId),
                CanDelete = !usedIds.Contains(e.EquipmentId)
            });

            return Ok(new { data, success = true, message = "Success" });
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var equipment = await _unitOfWork.Equipments.Query()
                .Include(e => e.Area)
                .FirstOrDefaultAsync(e => e.EquipmentId == id);

            if (equipment == null)
            {
                return NotFound(new { success = false, message = $"Khong tim thay thiet bi co ID = {id}" });
            }
            return Ok(new { success = true, data = equipment });
        }

        [HttpPost]
        public async Task<IActionResult> Create(Equipment equipment)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            await _unitOfWork.Equipments.AddAsync(equipment);
            await _unitOfWork.CompleteAsync();

            return CreatedAtAction(nameof(GetById), new { id = equipment.EquipmentId }, new { success = true, data = equipment });
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, Equipment equipment)
        {
            if (id != equipment.EquipmentId)
                return BadRequest(new { success = false, message = "ID tren URL va trong body khong khop nhau." });

            var existingEquipment = await _unitOfWork.Equipments.GetByIdAsync(id);
            if (existingEquipment == null) return NotFound(new { success = false, message = "Khong tim thay thiet bi." });

            var isUsed = await _unitOfWork.BatchProcessLogs.Query().AnyAsync(x => x.EquipmentId == id)
                || await _unitOfWork.RecipeRoutings.Query().AnyAsync(x => x.DefaultEquipmentId == id && x.OrderId != null);
            if (isUsed)
            {
                return Conflict(new
                {
                    success = false,
                    message = "Thiet bi da duoc su dung trong qua trinh san xuat, khong the chinh sua."
                });
            }

            existingEquipment.EquipmentCode = equipment.EquipmentCode;
            existingEquipment.EquipmentName = equipment.EquipmentName;
            existingEquipment.TechnicalSpecification = equipment.TechnicalSpecification;
            existingEquipment.UsagePurpose = equipment.UsagePurpose;
            existingEquipment.AreaId = equipment.AreaId;

            _unitOfWork.Equipments.Update(existingEquipment);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, message = "Cap nhat thanh cong!", equipmentId = id });
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var existingEquipment = await _unitOfWork.Equipments.GetByIdAsync(id);
            if (existingEquipment == null) return NotFound(new { success = false, message = "Khong tim thay thiet bi." });

            var isUsed = await _unitOfWork.BatchProcessLogs.Query().AnyAsync(x => x.EquipmentId == id)
                || await _unitOfWork.RecipeRoutings.Query().AnyAsync(x => x.DefaultEquipmentId == id && x.OrderId != null);
            if (isUsed)
            {
                return Conflict(new
                {
                    success = false,
                    message = "Thiet bi da duoc su dung trong qua trinh san xuat, khong the xoa."
                });
            }

            _unitOfWork.Equipments.Remove(existingEquipment);
            await _unitOfWork.CompleteAsync();

            return Ok(new { success = true, message = "Xoa thanh cong!", equipmentId = id });
        }
    }
}
