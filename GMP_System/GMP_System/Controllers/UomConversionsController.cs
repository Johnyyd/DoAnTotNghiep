using GMP_System.Entities;
using GMP_System.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace GMP_System.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UomConversionsController : ControllerBase
    {
        private readonly IUnitOfWork _unitOfWork;

        public UomConversionsController(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var conversions = await _unitOfWork.UomConversions.GetAllAsync();
            return Ok(conversions);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var conversion = await _unitOfWork.UomConversions.GetByIdAsync(id);
            if (conversion == null)
            {
                return NotFound($"Không tìm thấy Uom Conversion có ID = {id}");
            }
            return Ok(conversion);
        }

        [HttpPost]
        public async Task<IActionResult> Create(UomConversion conversion)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            await _unitOfWork.UomConversions.AddAsync(conversion);
            await _unitOfWork.CompleteAsync();

            return CreatedAtAction(nameof(GetById), new { id = conversion.ConversionId }, conversion);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, UomConversion conversion)
        {
            if (id != conversion.ConversionId)
                return BadRequest("ID trên URL và trong Body không khớp nhau.");

            var existingConversion = await _unitOfWork.UomConversions.GetByIdAsync(id);
            if (existingConversion == null) return NotFound("Không tìm thấy Uom Conversion này.");

            existingConversion.FromUomId = conversion.FromUomId;
            existingConversion.ToUomId = conversion.ToUomId;
            existingConversion.Factor = conversion.Factor;

            _unitOfWork.UomConversions.Update(existingConversion);
            await _unitOfWork.CompleteAsync();

            return Ok(new { Message = "Cập nhật thành công!", ConversionId = id });
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var existingConversion = await _unitOfWork.UomConversions.GetByIdAsync(id);
            if (existingConversion == null) return NotFound("Không tìm thấy Uom Conversion này.");

            _unitOfWork.UomConversions.Remove(existingConversion);
            await _unitOfWork.CompleteAsync();

            return Ok(new { Message = "Xóa thành công!", ConversionId = id });
        }
    }
}
