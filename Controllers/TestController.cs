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
    public enum Style
    {
        Classic,
        Hybrid,
        Document
    }

    public enum Verb
    {
        Get,
        Post,
        Put,
        Delete,
        Patch
    }

    [ApiController]
    [Route("[controller]")]
    public class TestController : ControllerBase
    {
        private class DatabaseResult
        {
            public string Todo = string.Empty;
            public string Extension = string.Empty;
        }

        private readonly ILogger<TestController> _logger;
        private readonly IConfiguration _config;

        public TestController(IConfiguration config, ILogger<TestController> logger)
        {
            _logger = logger;
            _config = config;
        }            
      
        [HttpGet]
        [Route("/test-classic/{id}")] 
        public async Task<IActionResult> TestClassic(int id)
        {
            object result = null;

            var payload = new JObject { ["id"] = id };

            using (var conn = new SqlConnection(_config.GetConnectionString("AzureSQL")))
            {
                var stringResult = await conn.ExecuteScalarAsync<string>(
                    "web.get_todo_test_classic", 
                    new { @payload = payload.ToString() },
                     commandType: CommandType.StoredProcedure
                );

                if (!string.IsNullOrEmpty(stringResult)) 
                    result = JToken.Parse(stringResult); // or JsonConvert.DeserializeObject<ToDo>(stringResult)
            }

            return new OkObjectResult(result);            
        }

        [HttpGet]
        [Route("/test-hybrid/{id}")] 
        public async Task<IActionResult> TestHybrid(int id)
        {
            object result = null;

            var payload = new JObject { ["id"] = id };

            using (var conn = new SqlConnection(_config.GetConnectionString("AzureSQL")))
            {
                var resultSet = await conn.QueryFirstOrDefaultAsync(
                    "web.get_todo_test_hybrid", 
                    new { @payload = payload.ToString() },
                    commandType: CommandType.StoredProcedure
                );

                if (resultSet != null) {
                    JObject todo = JObject.Parse(resultSet.todo);
                    if (resultSet.extension != null ) {
                        JObject extension = JObject.Parse(resultSet.extension);
                        todo.Merge(extension);
                    }

                    result = todo; 
                    // or result = todo.ToObject<ToDo>();
                }                
            }

            return new OkObjectResult(result);            
        }

        [HttpGet]
        [Route("/test-document/{id}")] 
        public async Task<IActionResult> TestDocument(int id)
        {
            object result = null;

            var payload = new JObject { ["id"] = id };

            using (var conn = new SqlConnection(_config.GetConnectionString("AzureSQL")))
            {
                var stringResult = await conn.ExecuteScalarAsync<string>(
                    "web.get_todo_test_document", 
                    new { @payload = payload.ToString() },
                    commandType: CommandType.StoredProcedure
                );
                if (!string.IsNullOrEmpty(stringResult)) 
                    result = JToken.Parse(stringResult); // or JsonConvert.DeserializeObject<ToDo>(stringResult)
            }

            return new OkObjectResult(result);            
        }
    }
}