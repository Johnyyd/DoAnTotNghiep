using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GMP_System.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class CertificatesController : ControllerBase
    {
        private readonly IWebHostEnvironment _env;
        private readonly IConfiguration _configuration;

        public CertificatesController(IWebHostEnvironment env, IConfiguration configuration)
        {
            _env = env;
            _configuration = configuration;
        }

        private string GetStorageDirectory()
        {
            var configured = _configuration["Certificates:StoragePath"];
            if (!string.IsNullOrWhiteSpace(configured))
            {
                return configured;
            }

            return Path.Combine(_env.ContentRootPath, "certificates");
        }

        [HttpPost("material/upload")]
        [RequestSizeLimit(20_000_000)]
        public async Task<IActionResult> UploadMaterialCertificate([FromForm] string materialCode, [FromForm] IFormFile file)
        {
            if (string.IsNullOrWhiteSpace(materialCode))
            {
                return BadRequest(new { success = false, message = "Thiếu mã nguyên liệu." });
            }

            if (file == null || file.Length == 0)
            {
                return BadRequest(new { success = false, message = "Thiếu tệp giấy kiểm nghiệm." });
            }

            var ext = Path.GetExtension(file.FileName)?.ToLowerInvariant();
            var allowed = new[] { ".jpg", ".jpeg", ".png", ".webp" };
            if (string.IsNullOrWhiteSpace(ext) || !allowed.Contains(ext))
            {
                return BadRequest(new { success = false, message = "Định dạng tệp không hợp lệ. Chỉ hỗ trợ JPG/PNG/WEBP." });
            }

            var safeCode = new string(materialCode.Where(ch => char.IsLetterOrDigit(ch) || ch == '-' || ch == '_').ToArray());
            if (string.IsNullOrWhiteSpace(safeCode))
            {
                return BadRequest(new { success = false, message = "Mã nguyên liệu không hợp lệ." });
            }

            var storageDir = GetStorageDirectory();
            Directory.CreateDirectory(storageDir);

            var fileName = $"{safeCode}{ext}";
            var fullPath = Path.Combine(storageDir, fileName);

            await using (var stream = System.IO.File.Create(fullPath))
            {
                await file.CopyToAsync(stream);
            }

            return Ok(new
            {
                success = true,
                message = "Tải giấy kiểm nghiệm thành công.",
                data = new
                {
                    fileName,
                    filePath = fullPath
                }
            });
        }

        [HttpGet("material/{materialCode}")]
        [AllowAnonymous]
        public IActionResult GetMaterialCertificate(string materialCode)
        {
            if (string.IsNullOrWhiteSpace(materialCode))
            {
                return NotFound();
            }

            var safeCode = new string(materialCode.Where(ch => char.IsLetterOrDigit(ch) || ch == '-' || ch == '_').ToArray());
            if (string.IsNullOrWhiteSpace(safeCode))
            {
                return NotFound();
            }

            var storageDir = GetStorageDirectory();
            var candidates = new[]
            {
                Path.Combine(storageDir, $"{safeCode}.jpg"),
                Path.Combine(storageDir, $"{safeCode}.jpeg"),
                Path.Combine(storageDir, $"{safeCode}.png"),
                Path.Combine(storageDir, $"{safeCode}.webp"),
            };

            var found = candidates.FirstOrDefault(System.IO.File.Exists);
            if (found == null)
            {
                return NotFound();
            }

            var ext = Path.GetExtension(found).ToLowerInvariant();
            var contentType = ext switch
            {
                ".png" => "image/png",
                ".webp" => "image/webp",
                _ => "image/jpeg"
            };

            return PhysicalFile(found, contentType);
        }
    }
}

