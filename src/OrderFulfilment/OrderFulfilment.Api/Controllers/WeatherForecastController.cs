using Microsoft.AspNetCore.Mvc;

namespace OrderFulfilment.Api.Controllers;

[ApiController]
[Route("fulfilment/api")]
public class ModuleStatusController : ControllerBase
{
    [HttpGet(Name = "GetOrderFulfilmentModuleStatus")]
    public IActionResult Get()
    {
        return Ok(new
        {
            module = "Order Fulfilment",
            service = "OrderFulfilment.Api",
            status = "placeholder"
        });
    }
}
