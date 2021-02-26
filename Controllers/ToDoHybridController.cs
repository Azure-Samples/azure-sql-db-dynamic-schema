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

namespace Azure.SQLDB.Samples.DynamicSchema
{
    [ApiController]
    [Route("[controller]")]
    public class ToDoHybridController : ControllerBase
    {
        private readonly ILogger<ToDoHybridController> _logger;
        private readonly IConfiguration _config;

        public ToDoHybridController(IConfiguration config, ILogger<ToDoHybridController> logger)
        {
            _logger = logger;
            _config = config;
        }
        
        private JToken CreatePayload(JObject sourceDocument)
        {
            JObject d = (JObject)(sourceDocument.DeepClone());

            var payload = new JObject {
                ["id"] = d["id"],
                ["title"] = d["title"],
                ["completed"] = d["completed"]
            };

            d.Property("id")?.Remove();
            d.Property("title")?.Remove();
            d.Property("completed")?.Remove();
            d.Property("url")?.Remove();

            payload.Add("extension", d);

            return payload;
        }

        private async Task<JToken> ExecuteProcedure(string verb, JToken payload)
        {
            JToken result = new JArray();

            using (var conn = new SqlConnection(_config.GetConnectionString("AzureSQL")))
            {
                DynamicParameters parameters = new DynamicParameters();
                if (payload != null) parameters.Add("payload", payload.ToString());                

                var resultSet = await conn.QueryAsync(
                    sql: $"web.{verb}_todo_hybrid",
                    param: parameters,
                    commandType: CommandType.StoredProcedure
                );

                var jr = new JArray();
                resultSet.ToList().ForEach(i =>
                {
                    JObject todo = JObject.Parse(i.todo);
                    if (i.extension != null ) {
                        JObject extension = JObject.Parse(i.extension);
                        todo.Merge(extension);
                    }

                    jr.Add(todo);
                });

                result = (jr.Count() == 1) ? jr[0] : jr;
            }

            return result;            
        }

        private JToken EnrichJsonResult(JToken result)
        {
            var e = result.DeepClone();
            Utils.EnrichJsonResult(HttpContext.Request, e, RouteData.Values["controller"].ToString());
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
        public async Task<JToken> Post([FromBody]JObject body)
        {
            var payload = CreatePayload(body);

            var result = await ExecuteProcedure("post", payload);                                
                        
            return EnrichJsonResult(result);
        }

        [HttpPatch]     
        [Route("{id}")]   
        public async Task<JToken> Patch(int id, [FromBody]JToken body)
        {
            // WARNING! No transaction or optimistic concurrency management here!
            // WARNING! Add it if this is going to be used in production code!
            // WARNING! Use an explicit transaction or an ETAG

            // Load existing document and apply the changes
            var existingJson = (JObject)(await ExecuteProcedure("get", new JObject { ["id"] = id }));
            if (existingJson != null) existingJson.Merge(body);
            var newJson = CreatePayload(existingJson);

            var payload = new JObject
            {
                ["id"] = id,
                ["todo"] = newJson
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
