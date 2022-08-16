using Azure;
using Azure.Data.Tables;
using Azure.Data.Tables.Models;
using RedirectAdmin.Models;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using System;

namespace RedirectAdmin.Data
{
    public class RedirectDataTable
    {
        private readonly TableClient tableClient;
        private readonly ILogger<RedirectDataTable> logger;

        public RedirectDataTable(TableConfigOptions config, ILogger<RedirectDataTable> logger)
        {
            tableClient = new TableClient(config.ConnectionString, config.TableName);
            tableClient.CreateIfNotExists();
            this.logger = logger;
            logger.LogInformation("Creating RedirectDataTable");
        }
        public async Task<TableResponse<List<RedirectURL>>> GetAllUrls()
        {
            try
            {
                AsyncPageable<RedirectURL> entities = tableClient.QueryAsync<RedirectURL>();
                List<RedirectURL> res = await entities.ToListAsync<RedirectURL>();
                return new TableResponse<List<RedirectURL>>
                {
                    Success = true,
                    Value = res
                };
            }
            catch(Exception ex)
            {
                return new TableResponse<List<RedirectURL>>
                {
                    Success = false,
                    Message = ex.Message
                };
            }
        }

        public async Task<TableResponse<RedirectURL>> GetUrlDetails(string id)
        {
            try
            {
                AsyncPageable<RedirectURL> queryResults = tableClient.QueryAsync<RedirectURL>(filter: $"RowKey eq '{id}'");
                RedirectURL res = await queryResults.FirstOrDefaultAsync();
                return new TableResponse<RedirectURL>
                {
                    Success = res != null,
                    Value = res
                };
            }
            catch(Exception ex)
            {
                return new TableResponse<RedirectURL>
                {
                    Success = false,
                    Message = ex.Message
                };
            }
        }

        public async Task<TableResponse> SaveUrl(RedirectURL url)
        {
            url.PartitionKey = url.RowKey;
            try
            {
                await tableClient.UpsertEntityAsync<RedirectURL>(url);
                return new TableResponse
                {
                    Success = true
                };
            }
            catch (Exception ex)
            {
                return new TableResponse
                {
                    Success = false,
                    Message = ex.Message
                };
            }
        }

        public async Task<TableResponse> DeleteUrl(RedirectURL url)
        {
            try
            {
                await tableClient.DeleteEntityAsync(url.PartitionKey, url.RowKey);
                return new TableResponse
                {
                    Success = true
                };
            }
            catch (Exception ex)
            {
                return new TableResponse
                {
                    Success = false,
                    Message = ex.Message
                };
            }            
        }
    }
}
