using GMP_System.Entities;
using GMP_System.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GMP_System.Controllers
{
    [Route("api/production-batches")]
    [ApiController]
    public class ProductionBatchesController : ControllerBase
    {
        private readonly IUnitOfWork _unitOfWork;

        public ProductionBatchesController(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        // GET: api/production-batches
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var batches = await _unitOfWork.ProductionBatches
                .Query()
                .Include(b => b.Order)
                    .ThenInclude(o => o!.Recipe)
                        .ThenInclude(r => r!.Material)
                .Include(b => b.MaterialUsages)
                    .ThenInclude(u => u.InventoryLot)
                        .ThenInclude(l => l!.Material)
                .ToListAsync();

            return Ok(new { data = batches, success = true, message = "Success" });
        }

        // GET: api/production-batches/5
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var batch = await _unitOfWork.ProductionBatches
                .Query()
                .Include(b => b.Order)
                    .ThenInclude(o => o!.Recipe)
                        .ThenInclude(r => r!.Material)
                .Include(b => b.MaterialUsages)
                    .ThenInclude(u => u.InventoryLot)
                        .ThenInclude(l => l!.Material)
                .Include(b => b.BatchProcessLogs)
                .FirstOrDefaultAsync(b => b.BatchId == id);

            if (batch == null) return NotFound(new { success = false, message = "Không tìm thấy mẻ sản xuất." });
            return Ok(new { data = batch, success = true, message = "Success" });
        }

        // POST: api/production-batches — Tạo mẻ sản xuất mới
        [HttpPost]
        public async Task<IActionResult> Create(ProductionBatch batch)
        {
            if (batch.OrderId == null)
                return BadRequest(new { success = false, message = "Phải gắn với một Lệnh sản xuất (OrderId)." });

            var order = await _unitOfWork.ProductionOrders.GetByIdAsync(batch.OrderId.Value);
            if (order == null)
                return BadRequest(new { success = false, message = "Không tìm thấy Lệnh sản xuất." });

            if (string.IsNullOrEmpty(batch.BatchNumber))
                batch.BatchNumber = $"BATCH-{DateTime.Now:yyyyMMdd}-{batch.OrderId}";

            batch.ManufactureDate = DateTime.Now;
            batch.Status = "In-Process";
            batch.CurrentStep = 0;

            await _unitOfWork.ProductionBatches.AddAsync(batch);

            // Cập nhật trạng thái Order cha thành In-Process
            if (order.Status != "In-Process" && order.Status != "Completed")
            {
                order.Status = "In-Process";
                _unitOfWork.ProductionOrders.Update(order);
            }

            await _unitOfWork.CompleteAsync();

            return Ok(new
            {
                success = true,
                message = "Khởi động mẻ sản xuất thành công!",
                data = new { batchId = batch.BatchId, batchNumber = batch.BatchNumber, status = batch.Status }
            });
        }

        // POST: api/production-batches/{id}/finish — Kết thúc mẻ
        [HttpPost("{id}/finish")]
        public async Task<IActionResult> FinishBatch(int id)
        {
            var batch = await _unitOfWork.ProductionBatches.GetByIdAsync(id);
            if (batch == null) return NotFound(new { success = false, message = "Không tìm thấy mẻ sản xuất." });
            if (batch.Status == "Completed") return BadRequest(new { success = false, message = "Mẻ này đã kết thúc rồi." });

            batch.Status = "Completed";
            batch.EndTime = DateTime.Now;
            _unitOfWork.ProductionBatches.Update(batch);

            // Cập nhật trạng thái Order cha nếu tất cả batches đã completed
            if (batch.OrderId.HasValue)
            {
                var allBatches = await _unitOfWork.ProductionBatches
                    .Query()
                    .Where(b => b.OrderId == batch.OrderId && b.BatchId != id)
                    .ToListAsync();

                var allDone = allBatches.All(b => b.Status == "Completed");
                if (allDone)
                {
                    var order = await _unitOfWork.ProductionOrders.GetByIdAsync(batch.OrderId.Value);
                    if (order != null)
                    {
                        order.Status = "Completed";
                        _unitOfWork.ProductionOrders.Update(order);
                    }
                }
            }

            await _unitOfWork.CompleteAsync();

            return Ok(new
            {
                success = true,
                message = "Đóng mẻ sản xuất thành công!",
                data = new { batchNumber = batch.BatchNumber, endTime = batch.EndTime }
            });
        }
    }
}