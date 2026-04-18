using GMP_System.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GMP_System.Controllers
{
    [Route("api/[controller]")]
    [Route("api/areas")]
    [ApiController]
    public class ProductionAreasController : ControllerBase
    {
        private readonly IUnitOfWork _unitOfWork;

        public ProductionAreasController(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var rows = await _unitOfWork.ProductionAreas.Query()
                .OrderBy(a => a.AreaName)
                .ToListAsync();

            return Ok(new { success = true, data = rows });
        }
    }
}
