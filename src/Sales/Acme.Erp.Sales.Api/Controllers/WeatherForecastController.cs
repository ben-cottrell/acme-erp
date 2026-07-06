using Microsoft.AspNetCore.Mvc;

namespace Acme.Erp.Sales.Api.Controllers;

[ApiController]
[Route("sales/api")]
public class ModuleStatusController : ControllerBase
{
    [HttpGet(Name = "GetSalesModuleStatus")]
    public IActionResult Get()
    {
        return Ok(new
        {
            module = "Sales",
            service = "Sales.Api",
            status = "placeholder"
        });
    }
}
