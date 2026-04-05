using GMP_System.Entities;
using GMP_System.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace GMP_System.Controllers
{
    [Route("api/auth")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IConfiguration _config;

        public AuthController(IUnitOfWork unitOfWork, IConfiguration config)
        {
            _unitOfWork = unitOfWork;
            _config = config;
        }

        // POST: /api/auth/login
        [AllowAnonymous]
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Username) || string.IsNullOrWhiteSpace(request.Password))
                return BadRequest(new { success = false, message = "Vui lòng nhập tên đăng nhập và mật khẩu." });

            // Tìm user theo username
            var users = await _unitOfWork.AppUsers.GetAllAsync();
            var user = users.FirstOrDefault(u =>
                u.Username!.Equals(request.Username.Trim(), StringComparison.OrdinalIgnoreCase));

            if (user == null)
                return Unauthorized(new { success = false, message = "Tên đăng nhập hoặc mật khẩu không đúng." });

            if (user.IsActive != true)
                return Unauthorized(new { success = false, message = "Tài khoản đã bị khóa. Liên hệ quản trị viên." });

            // Kiểm tra phân quyền truy cập nền tảng
            if (request.Platform?.Equals("Web", StringComparison.OrdinalIgnoreCase) == true)
            {
                if (!user.Role!.Equals("Admin", StringComparison.OrdinalIgnoreCase))
                {
                    return Unauthorized(new { success = false, message = "Tài khoản này chỉ được phép đăng nhập trên ứng dụng Mobile." });
                }
            }

            // Kiểm tra password hash
            if (string.IsNullOrEmpty(user.PasswordHash) || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
                return Unauthorized(new { success = false, message = "Tên đăng nhập hoặc mật khẩu không đúng." });

            // Tạo JWT token
            var token = GenerateJwtToken(user);

            return Ok(new
            {
                success = true,
                message = "Đăng nhập thành công!",
                data = new
                {
                    token = token,
                    user = new
                    {
                        userId = user.UserId,
                        username = user.Username,
                        fullName = user.FullName,
                        role = user.Role,
                        isActive = user.IsActive
                    }
                }
            });
        }

        // GET: /api/auth/me
        [Authorize]
        [HttpGet("me")]
        public async Task<IActionResult> Me()
        {
            // Lấy UserId từ JWT Claims
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdClaim, out var userId))
                return Unauthorized(new { success = false, message = "Token không hợp lệ." });

            var user = await _unitOfWork.AppUsers.GetByIdAsync(userId);
            if (user == null)
                return NotFound(new { success = false, message = "Không tìm thấy người dùng." });

            return Ok(new
            {
                success = true,
                data = new
                {
                    userId = user.UserId,
                    username = user.Username,
                    fullName = user.FullName,
                    role = user.Role,
                    isActive = user.IsActive,
                    createdAt = user.CreatedAt
                }
            });
        }

        private string GenerateJwtToken(AppUser user)
        {
            var jwtKey = _config["Jwt:Key"] ?? "GMP_WHO_Default_Secret_Key_Minimum_32_Characters_Long_123456789";
            var jwtIssuer = _config["Jwt:Issuer"] ?? "gmp-api";
            var jwtAudience = _config["Jwt:Audience"] ?? "gmp-frontend";
            var expireMinutes = int.TryParse(_config["Jwt:ExpireMinutes"], out var m) ? m : 480;

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var claims = new[]
            {
                new Claim(ClaimTypes.NameIdentifier, user.UserId.ToString()),
                new Claim(ClaimTypes.Name, user.Username),
                new Claim("fullName", user.FullName),
                new Claim(ClaimTypes.Role, user.Role ?? "Operator"),
            };

            var token = new JwtSecurityToken(
                issuer: jwtIssuer,
                audience: jwtAudience,
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(expireMinutes),
                signingCredentials: creds
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }

    // Request DTO
    public class LoginRequest
    {
        public string Username { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string? Platform { get; set; } // "Web" or "Mobile"
    }
}
