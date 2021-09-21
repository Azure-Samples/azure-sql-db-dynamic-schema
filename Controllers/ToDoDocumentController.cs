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
using System.Linq;
using System.Collections.Generic;

namespace Azure.SQLDB.Samples.DynamicSchema
{
    [ApiController]
    [Route("todo/document")]
    public class ToDoDocumentController : ControllerBase
    {
        private readonly ILogger<ToDoDocumentController> _logger;
        private readonly IConfiguration _config;

        public ToDoDocumentController(IConfiguration config, ILogger<ToDoDocumentController> logger)
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
                if (payload != null) parameters.Add("payload", payload.ToString(Formatting.None));                

                var resultSet = await conn.QueryAsync(
                    sql: $"web.{verb}_todo_document",
                    param: parameters,
                    commandType: CommandType.StoredProcedure
                );

                var jr = new JArray();
                resultSet.ToList().ForEach(i =>
                {                    
                    jr.Add(JObject.Parse(i.todo));
                });

                result = (jr.Count() == 1) ? jr[0] : jr;
            }

            return result;            
        }

        private JToken EnrichJsonResult(JToken result)
        {
            var e = result.DeepClone();
            Utils.EnrichJsonResult(HttpContext.Request, e, "todo/document");            
            return e;
        }

        [HttpGet]
        [Route("{id?}")]
        public async Task<JToken> Get(int? id)
        {
            var payload = id.HasValue ? new JObject { ["id"] = id.Value } : null;
            
            var result = await ExecuteProcedure("get", payload);            
            
            // If requesting ALL todo, always return an array
            if (id == null && result.Type == JTokenType.Object)
                result = new JArray() { result };

            return EnrichJsonResult(result);
        }

        [HttpPost]        
        public async Task<JToken> Post([FromBody]JToken body) // Or use ToDo instead of JToken if you want to validate the schema
        {
            var payload = JToken.FromObject(body);

            var result = await ExecuteProcedure("post", payload);                                
                        
            return EnrichJsonResult(result);
        }

        [HttpPatch]     
        [Route("{id}")]   
        public async Task<JToken> Patch(int id, [FromBody]JToken body) // Or use ToDo instead of JToken if you want to validate the schema
        {
            // WARNING! No transaction or optimistic concurrency management here!
            // WARNING! Add it if this is going to be used in production code!
            // WARNING! Use an explicit transaction or an ETAG

            // Load existing todo  
            var targetJson = (JObject)(await ExecuteProcedure("get", new JObject { ["id"] = id }));

            // Get new todo
            var sourceJson = JObject.FromObject(body);

            // Patch
            ((JObject)targetJson).Merge(sourceJson);

            // Save back to database
            var payload = new JObject
            {
                ["id"] = id,
                ["todo"] = targetJson
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
