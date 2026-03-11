using Microsoft.AspNetCore.Mvc;
using System.Net.Mime;

namespace GMP_System.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class HealthController : ControllerBase
    {
        [HttpGet]
        [Produces(MediaTypeNames.Application.Json)]
        public IActionResult Get()
        {
            var health = new
            {
                status = "healthy",
                timestamp = DateTime.UtcNow,
                service = "GMP-WHO Pharmaceutical Processing Management System",
                version = "1.0.0"
            };

            return Ok(health);
        }
    }
}
