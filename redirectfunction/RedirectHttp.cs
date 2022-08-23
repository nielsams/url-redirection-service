using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;

namespace func
{
    public static class RedirectHttp
    {
        public class Url {
            public string RowKey {get; set;}
            public string RedirectUrl {get; set;}
        }

        [FunctionName("RedirectHttp")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = "RedirectHttp/{url}")] HttpRequest req,
            [Table("redirectionurls", "redirect", "{url}", Connection = "StorageConnection")] Url entity,
            string url,
            ILogger log)            
        {
            if(entity == null) {
                log.LogWarning("No url found for shortname: "+url);
                return new NotFoundResult();
            }
            log.LogInformation("Redirecting " + entity.RowKey + " to " + entity.RedirectUrl);
            return new OkObjectResult(entity.RedirectUrl);
        }
    }
}
