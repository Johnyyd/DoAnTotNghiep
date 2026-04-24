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

        private string GetMaterialStorageDirectory()
        {
            var configured = _configuration["Certificates:StoragePath"];
            if (!string.IsNullOrWhiteSpace(configured))
            {
                return configured;
            }

            return Path.Combine(_env.ContentRootPath, "certificates");
        }

        private string GetFinishedStorageDirectory()
        {
            var configured = _configuration["Certificates:FinishedStoragePath"];
            if (!string.IsNullOrWhiteSpace(configured))
            {
                return configured;
            }

            return Path.Combine(_env.ContentRootPath, "wwwroot", "certificates");
        }

        private string GetPublicMaterialsDirectory()
        {
            var configured = _configuration["Certificates:PublicMaterialsPath"];
            if (!string.IsNullOrWhiteSpace(configured))
            {
                return configured;
            }

            return Path.Combine(_env.ContentRootPath, "wwwroot", "materials");
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

            var storageDir = GetMaterialStorageDirectory();
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
            return ServeImageByCode(
                new[]
                {
                    GetMaterialStorageDirectory(),
                    GetPublicMaterialsDirectory()
                },
                materialCode
            );
        }

        [HttpGet("finished/{materialCode}")]
        [AllowAnonymous]
        public IActionResult GetFinishedCertificate(string materialCode)
        {
            return ServeImageByCode(new[] { GetFinishedStorageDirectory() }, materialCode);
        }

        [HttpGet("lot/{batchNumber}")]
        [AllowAnonymous]
        public IActionResult GetLotCertificate(string batchNumber)
        {
            return ServeImageByCode(new[] { GetMaterialStorageDirectory() }, batchNumber);
        }

        private string GetBatchStorageDirectory()
        {
            var configured = _configuration["Certificates:BatchStoragePath"];
            if (!string.IsNullOrWhiteSpace(configured))
                return configured;
            return Path.Combine(_env.ContentRootPath, "certificates", "batches");
        }

        [HttpPost("batch/upload")]
        [RequestSizeLimit(20_000_000)]
        public async Task<IActionResult> UploadBatchCertificate([FromForm] string batchNumber, [FromForm] IFormFile file)
        {
            if (string.IsNullOrWhiteSpace(batchNumber))
                return BadRequest(new { success = false, message = "Thiếu mã mẻ sản xuất." });

            if (file == null || file.Length == 0)
                return BadRequest(new { success = false, message = "Thiếu tệp giấy kiểm nghiệm." });

            var ext = Path.GetExtension(file.FileName)?.ToLowerInvariant();
            var allowed = new[] { ".jpg", ".jpeg", ".png", ".webp", ".pdf" };
            if (string.IsNullOrWhiteSpace(ext) || !allowed.Contains(ext))
                return BadRequest(new { success = false, message = "Định dạng không hợp lệ. Chỉ hỗ trợ JPG/PNG/WEBP/PDF." });

            var safeCode = new string(batchNumber.Where(ch => char.IsLetterOrDigit(ch) || ch == '-' || ch == '_').ToArray());
            if (string.IsNullOrWhiteSpace(safeCode))
                return BadRequest(new { success = false, message = "Mã mẻ không hợp lệ." });

            var storageDir = GetBatchStorageDirectory();
            Directory.CreateDirectory(storageDir);

            var fileName = $"{safeCode}{ext}";
            var fullPath = Path.Combine(storageDir, fileName);

            await using (var stream = System.IO.File.Create(fullPath))
            {
                await file.CopyToAsync(stream);
            }

            return Ok(new { success = true, message = "Tải giấy kiểm nghiệm mẻ thành công.", data = new { fileName, filePath = fullPath } });
        }

        [HttpGet("batch/{batchNumber}")]
        [AllowAnonymous]
        public IActionResult GetBatchCertificate(string batchNumber)
        {
            var storageDir = GetBatchStorageDirectory();
            if (string.IsNullOrWhiteSpace(batchNumber))
                return NotFound(new { success = false, message = "Thiếu mã mẻ." });

            var safeCode = new string(batchNumber.Where(ch => char.IsLetterOrDigit(ch) || ch == '-' || ch == '_').ToArray());

            var allowed = new[] { ".jpg", ".jpeg", ".png", ".webp", ".pdf" };
            var found = allowed.Select(ext => Path.Combine(storageDir, $"{safeCode}{ext}"))
                               .FirstOrDefault(System.IO.File.Exists);

            if (found == null)
                return NotFound(new { success = false, message = $"Chưa có giấy kiểm nghiệm cho mẻ {safeCode}." });

            var extension = Path.GetExtension(found).ToLowerInvariant();
            var contentType = extension switch
            {
                ".pdf" => "application/pdf",
                ".png" => "image/png",
                ".webp" => "image/webp",
                _ => "image/jpeg"
            };

            return PhysicalFile(found, contentType);
        }

        private IActionResult ServeImageByCode(IEnumerable<string> storageDirs, string code)
        {
            if (string.IsNullOrWhiteSpace(code))
            {
                return NotFound(new { success = false, message = "Thiếu mã." });
            }

            var safeCode = new string(code.Where(ch => char.IsLetterOrDigit(ch) || ch == '-' || ch == '_').ToArray());
            if (string.IsNullOrWhiteSpace(safeCode))
            {
                return NotFound(new { success = false, message = "Mã không hợp lệ." });
            }

            var candidates = storageDirs
                .Where(d => !string.IsNullOrWhiteSpace(d))
                .SelectMany(storageDir => new[]
                {
                    Path.Combine(storageDir, $"{safeCode}.jpg"),
                    Path.Combine(storageDir, $"{safeCode}.jpeg"),
                    Path.Combine(storageDir, $"{safeCode}.png"),
                    Path.Combine(storageDir, $"{safeCode}.webp"),
                })
                .ToArray();

            var found = candidates.FirstOrDefault(System.IO.File.Exists);
            if (found == null)
            {
                return NotFound(new { success = false, message = $"Không tìm thấy giấy kiểm nghiệm cho mã {safeCode}." });
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
