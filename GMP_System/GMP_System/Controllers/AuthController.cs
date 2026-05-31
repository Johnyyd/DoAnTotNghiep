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
        private readonly IWebHostEnvironment _environment;

        public AuthController(IUnitOfWork unitOfWork, IConfiguration config, IWebHostEnvironment environment)
        {
            _unitOfWork = unitOfWork;
            _config = config;
            _environment = environment;
        }

        // POST: /api/auth/login
        [AllowAnonymous]
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest? request)
        {
            if (request == null)
                return BadRequest(new { success = false, message = "Dữ liệu đăng nhập không hợp lệ." });

            if (string.IsNullOrWhiteSpace(request.Username) || string.IsNullOrWhiteSpace(request.Password))
                return BadRequest(new { success = false, message = "Vui lòng nhập tên đăng nhập và mật khẩu." });

            var username = request.Username.Trim();
            var users = await _unitOfWork.AppUsers.GetAllAsync();
            var user = users.FirstOrDefault(u =>
                string.Equals(u.Username, username, StringComparison.OrdinalIgnoreCase));

            if (user == null)
                return Unauthorized(new { success = false, message = "Tên đăng nhập hoặc mật khẩu không đúng." });

            if (user.IsActive != true)
                return Unauthorized(new { success = false, message = "Tài khoản đã bị khóa. Liên hệ quản trị viên." });

            if (request.Platform?.Equals("Web", StringComparison.OrdinalIgnoreCase) == true && !CanAccessWeb(user.Role))
                return Unauthorized(new { success = false, message = "Tài khoản này chỉ được phép đăng nhập trên ứng dụng Mobile." });

            bool isPasswordCorrect = !string.IsNullOrEmpty(user.PasswordHash)
                && BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash);

            if (!isPasswordCorrect)
                return Unauthorized(new { success = false, message = "Tên đăng nhập hoặc mật khẩu không đúng." });

            user.LastLogin = DateTime.UtcNow;
            _unitOfWork.AppUsers.Update(user);
            await _unitOfWork.CompleteAsync();

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

        [AllowAnonymous]
        [HttpGet("gen-hash/{password}")]
        public IActionResult GenHash(string password)
        {
            if (!_environment.IsDevelopment())
                return NotFound();

            return Ok(new { password = password, hash = BCrypt.Net.BCrypt.HashPassword(password) });
        }

        // GET: /api/auth/me
        [Authorize]
        [HttpGet("me")]
        public async Task<IActionResult> Me()
        {
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

        private static bool CanAccessWeb(string? role)
        {
            return string.Equals(role, "Admin", StringComparison.OrdinalIgnoreCase)
                || string.Equals(role, "ProductionManager", StringComparison.OrdinalIgnoreCase);
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
                new Claim(ClaimTypes.Name, user.Username ?? string.Empty),
                new Claim("fullName", user.FullName ?? string.Empty),
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

    public class LoginRequest
    {
        public string Username { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string? Platform { get; set; }
    }
}
