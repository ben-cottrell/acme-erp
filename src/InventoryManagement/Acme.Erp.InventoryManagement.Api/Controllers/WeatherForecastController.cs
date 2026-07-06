using Microsoft.AspNetCore.Mvc;

namespace Acme.Erp.InventoryManagement.Api.Controllers;

[ApiController]
[Route("inventory/api")]
public class ModuleStatusController : ControllerBase
{
    [HttpGet(Name = "GetInventoryManagementModuleStatus")]
    public IActionResult Get()
    {
        return Ok(new
        {
            module = "Inventory Management",
            service = "InventoryManagement.Api",
            status = "placeholder"
        });
    }
}
