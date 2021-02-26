using System;
using Newtonsoft.Json.Linq;
using Microsoft.AspNetCore.Http;

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
    
    public static class Utils
    {
        public static void EnrichJsonResult(HttpRequest request, JToken result, string test)
        {
            var baseUrl = request.Scheme + "://" + request.Host + $"/{test}";

            var InjectUrl = new Action<JObject>(i =>
            {
                if (i != null)
                {
                    var itemId = i["id"]?.Value<int>();
                    if (itemId != null) i["url"] = baseUrl + $"/{itemId}";
                }
            });

            switch (result.Type)
            {
                case JTokenType.Object:
                    InjectUrl(result as JObject);
                    break;

                case JTokenType.Array:
                    foreach (var i in result)
                    {
                        InjectUrl(i as JObject);
                    }
                    break;
            }
        }
    }
}