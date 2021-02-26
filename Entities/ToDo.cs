using System;
using Newtonsoft.Json;

namespace Azure.SQLDB.Samples.DynamicSchema
{    
    public class ToDo
    {
        [JsonProperty("id")]
        public int Id { get; set; }

        [JsonProperty("title")]
        public string Title { get; set; }

        [JsonProperty("completed")]
        public bool Completed { get; set; }
        
        [JsonProperty("order")]
        public int Order { get; set; }

        [JsonProperty("url")]
        public string Url { get; set; }

        public bool ShouldSerializeUrl() => false;

        public bool ShouldSerializeId() => false;
    }
}
