using Microsoft.AspNetCore.Mvc;

namespace Acme.Erp.Purchasing.Api.Controllers;

[ApiController]
[Route("purchasing/api")]
public class ModuleStatusController : ControllerBase
{
    [HttpGet(Name = "GetPurchasingModuleStatus")]
    public IActionResult Get()
    {
        return Ok(new
        {
            module = "Purchasing",
            service = "Purchasing.Api",
            status = "placeholder"
        });
    }
}
