using GMP_System.Entities;
using GMP_System.Interfaces;
using Microsoft.AspNetCore.Mvc;

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
            var equipments = await _unitOfWork.Equipments.GetAllAsync();
            return Ok(new { data = equipments, success = true, message = "Success" });
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var equipment = await _unitOfWork.Equipments.GetByIdAsync(id);
            if (equipment == null)
            {
                return NotFound($"Không tìm thấy thiết bị có ID = {id}");
            }
            return Ok(equipment);
        }

        [HttpPost]
        public async Task<IActionResult> Create(Equipment equipment)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            await _unitOfWork.Equipments.AddAsync(equipment);
            await _unitOfWork.CompleteAsync();

            return CreatedAtAction(nameof(GetById), new { id = equipment.EquipmentId }, equipment);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, Equipment equipment)
        {
            if (id != equipment.EquipmentId)
                return BadRequest("ID trên URL và trong Body không khớp nhau.");

            var existingEquipment = await _unitOfWork.Equipments.GetByIdAsync(id);
            if (existingEquipment == null) return NotFound("Không tìm thấy thiết bị này.");

            existingEquipment.EquipmentCode = equipment.EquipmentCode;
            existingEquipment.EquipmentName = equipment.EquipmentName;
            existingEquipment.Status = equipment.Status;
            existingEquipment.LastMaintenanceDate = equipment.LastMaintenanceDate;

            _unitOfWork.Equipments.Update(existingEquipment);
            await _unitOfWork.CompleteAsync();

            return Ok(new { Message = "Cập nhật thành công!", EquipmentId = id });
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var existingEquipment = await _unitOfWork.Equipments.GetByIdAsync(id);
            if (existingEquipment == null) return NotFound("Không tìm thấy thiết bị này.");

            _unitOfWork.Equipments.Remove(existingEquipment);
            await _unitOfWork.CompleteAsync();

            return Ok(new { Message = "Xóa thành công!", EquipmentId = id });
        }
    }
}
