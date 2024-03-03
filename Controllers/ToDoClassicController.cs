using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System.Data;
using System.Linq;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Dapper;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Azure.SQLDB.Samples.DynamicSchema
{
    [ApiController]
    [Route("todo/classic")]
    public class ToDoClassicController : ControllerBase
    {
        private async Task<JToken> ExecuteProcedure(string verb, JToken payload)
        {
            JToken result = new JArray();

            using (var conn = new SqlConnection(Environment.GetEnvironmentVariable("MSSQL")))
            {
                DynamicParameters parameters = new DynamicParameters();
                if (payload != null) parameters.Add("payload", payload.ToString());                

                string stringResult = await conn.ExecuteScalarAsync<string>(
                    sql: $"web.{verb}_todo_classic",
                    param: parameters,
                    commandType: CommandType.StoredProcedure
                );

                if (!string.IsNullOrEmpty(stringResult)) result = JToken.Parse(stringResult);
            }

            return result;            
        }

        private JToken EnrichJsonResult(JToken result)
        {
            var e = result.DeepClone();            
            Utils.EnrichJsonResult(HttpContext.Request, e, "todo/classic");            
            return e;
        }

        [HttpGet]
        [Route("{id?}")]
        public async Task<JToken> Get(int? id)
        {
            var payload = id.HasValue ? new JObject { ["id"] = id.Value } : null;
            
            var result = await ExecuteProcedure("get", payload);            
            
            return EnrichJsonResult(result);
        }

        [HttpPost]        
        public async Task<JToken> Post([FromBody]JToken payload)
        {
            var result = await ExecuteProcedure("post", payload);                                
                        
            return EnrichJsonResult(result);
        }

        [HttpPatch]     
        [Route("{id}")]   
        public async Task<JToken> Patch(int id, [FromBody]JToken body)
        {
            var payload = new JObject
            {
                ["id"] = id,
                ["todo"] = body
            };

            JToken result = await ExecuteProcedure("patch", payload);                                
                        
            return EnrichJsonResult(result);
        }

        [HttpDelete]     
        [Route("{id?}")]   
        public async Task<JToken> Delete(int? id)
        {            
            var payload = id.HasValue ? new JObject { ["id"] = id.Value } : null;
            
            var result = await ExecuteProcedure("delete", payload);            
            
            return EnrichJsonResult(result);
        }        
    }
}
