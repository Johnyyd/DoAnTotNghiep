using GMP_System.Entities;
using GMP_System.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace GMP_System.Controllers
{
    [Route("api/app-users")]
    [ApiController]
    public class AppUsersController : ControllerBase
    {
        private readonly IUnitOfWork _unitOfWork;

        public AppUsersController(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var users = await _unitOfWork.AppUsers.GetAllAsync();
            return Ok(new { data = users, success = true, message = "Success" });
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var user = await _unitOfWork.AppUsers.GetByIdAsync(id);
            if (user == null)
            {
                return NotFound($"Không tìm thấy user có ID = {id}");
            }
            return Ok(user);
        }

        [HttpPost]
        public async Task<IActionResult> Create(AppUser user)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            user.CreatedAt = DateTime.UtcNow;

            await _unitOfWork.AppUsers.AddAsync(user);
            await _unitOfWork.CompleteAsync();

            return CreatedAtAction(nameof(GetById), new { id = user.UserId }, user);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, AppUser user)
        {
            if (id != user.UserId)
                return BadRequest("ID trên URL và trong Body không khớp nhau.");

            var existingUser = await _unitOfWork.AppUsers.GetByIdAsync(id);
            if (existingUser == null) return NotFound("Không tìm thấy user này.");

            existingUser.FullName = user.FullName;
            existingUser.Role = user.Role;
            existingUser.IsActive = user.IsActive;

            _unitOfWork.AppUsers.Update(existingUser);
            await _unitOfWork.CompleteAsync();

            return Ok(new { Message = "Cập nhật thành công!", UserId = id });
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var existingUser = await _unitOfWork.AppUsers.GetByIdAsync(id);
            if (existingUser == null) return NotFound("Không tìm thấy user này.");

            _unitOfWork.AppUsers.Remove(existingUser);
            await _unitOfWork.CompleteAsync();

            return Ok(new { Message = "Xóa thành công!", UserId = id });
        }
    }
}
