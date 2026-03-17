using GMP_System.Entities;
using GMP_System.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace GMP_System.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UnitOfMeasuresController : ControllerBase
    {
        private readonly IUnitOfWork _unitOfWork;

        public UnitOfMeasuresController(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var uoms = await _unitOfWork.UnitOfMeasures.GetAllAsync();
            return Ok(uoms);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var uom = await _unitOfWork.UnitOfMeasures.GetByIdAsync(id);
            if (uom == null)
            {
                return NotFound($"Không tìm thấy Unit Of Measure có ID = {id}");
            }
            return Ok(uom);
        }

        [HttpPost]
        public async Task<IActionResult> Create(UnitOfMeasure uom)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            await _unitOfWork.UnitOfMeasures.AddAsync(uom);
            await _unitOfWork.CompleteAsync();

            return CreatedAtAction(nameof(GetById), new { id = uom.UomId }, uom);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, UnitOfMeasure uom)
        {
            if (id != uom.UomId)
                return BadRequest("ID trên URL và trong Body không khớp nhau.");

            var existingUom = await _unitOfWork.UnitOfMeasures.GetByIdAsync(id);
            if (existingUom == null) return NotFound("Không tìm thấy Unit Of Measure này.");

            existingUom.UomName = uom.UomName;
            existingUom.Description = uom.Description;

            _unitOfWork.UnitOfMeasures.Update(existingUom);
            await _unitOfWork.CompleteAsync();

            return Ok(new { Message = "Cập nhật thành công!", UomId = id });
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var existingUom = await _unitOfWork.UnitOfMeasures.GetByIdAsync(id);
            if (existingUom == null) return NotFound("Không tìm thấy Unit Of Measure này.");

            _unitOfWork.UnitOfMeasures.Remove(existingUom);
            await _unitOfWork.CompleteAsync();

            return Ok(new { Message = "Xóa thành công!", UomId = id });
        }
    }
}
