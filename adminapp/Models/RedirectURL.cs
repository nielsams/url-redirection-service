using Azure;
using Azure.Data.Tables;
using System;

namespace RedirectAdmin.Models
{
    public class RedirectURL : ITableEntity
    {
        public string PartitionKey { get; set; }
        public string RowKey { get; set; }
        public string RedirectUrl { get; set; }

        public DateTimeOffset? Timestamp { get; set; }
        public ETag ETag { get; set; }
    }
}
