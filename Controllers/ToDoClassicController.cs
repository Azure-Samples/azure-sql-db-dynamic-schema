using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System.Data;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Dapper;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Azure.SQLDB.Samples.DynamicSchema
{
    [ApiController]
    [Route("[controller]")]
    public class ToDoClassicController : ControllerBase
    {
        private readonly ILogger<ToDoClassicController> _logger;
        private readonly IConfiguration _config;

        public ToDoClassicController(IConfiguration config, ILogger<ToDoClassicController> logger)
        {
            _logger = logger;
            _config = config;
        }
        
        private async Task<JToken> ExecuteProcedure(string verb, JToken payload)
        {
            JToken result = new JArray();

            using (var conn = new SqlConnection(_config.GetConnectionString("AzureSQL")))
            {
                DynamicParameters parameters = new DynamicParameters();

                if (payload != null)
                {
                    parameters.Add("payload", payload.ToString());
                }

                string stringResult = await conn.ExecuteScalarAsync<string>(
                    sql: $"web.{verb}_todo_classic",
                    param: parameters,
                    commandType: CommandType.StoredProcedure
                );

                if (!string.IsNullOrEmpty(stringResult)) result = JToken.Parse(stringResult);
            }

            return result;            
        }

        [HttpGet]
        [Route("{id?}")]
        public async Task<JToken> Get(int? id)
        {
            JToken payload = id.HasValue ? new JObject { ["id"] = id.Value } : null;
            
            JToken result = await ExecuteProcedure("get", payload);            
            
            Utils.EnrichJsonResult(HttpContext.Request, result, RouteData.Values["controller"].ToString());

            return result;

        }

    }
}
