using System.Security.Policy;

namespace RedirectAdmin.Models
{
    public class TableResponse
    {
        public bool Success { get; set; }
        public string Message { get; set; }
    }

    public class TableResponse<T> : TableResponse
    {
        public T Value { get; set; }
    }
}
