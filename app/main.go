package main

import (
	"fmt"
	"net/http"
	"net/url"
	"os"
	"regexp"

	"github.com/Azure/azure-sdk-for-go/storage"
)

var (
	table *storage.Table
)

const (
	fullmetadata = "application/json;odata=fullmetadata"
)

func main() {
	// Establish connection to table storage. This part is run only at startup
	connectionString := os.Getenv("STORAGE_CONNECTION_STRING")
	client, err := storage.NewClientFromConnectionString(connectionString)
	if err != nil {
		fmt.Printf("%s: \n", err)
	}

	tableName := os.Getenv("STORAGE_TABLE_NAME")
	tableCli := client.GetTableService()
	table = tableCli.GetTableReference(tableName)

	// Redirect every incoming call to the handleRequest function
	http.HandleFunc("/", handleRequest)
	http.ListenAndServe(":8080", nil)

}

func handleRequest(w http.ResponseWriter, r *http.Request) {
	// This method is run for every incoming http request

	// We want all the characters from the first forward slash up to either '?' or the line end:
	re := regexp.MustCompile(`(^(\/))(([^\?])*)`)

	// The URL we want is in the third regex capture group. URL encode it too.
	urlKey := url.QueryEscape(re.FindStringSubmatch(r.RequestURI)[3])

	// If there is no urlKey, we can't proceed. This can only happen if someone calls the root page ('/')
	if len(urlKey) == 0 {
		fmt.Printf("URL key not found.\n")
		http.NotFound(w, r)
		return
	}

	// Get the redirect url from table storage
	redirectURL := getRedirectURL(urlKey)

	// If the effort to retrieve the url returned an empty string, we're returning NotFound
	if len(redirectURL) == 0 {
		fmt.Printf("No redirect URL found for key %s\n", urlKey)
		http.NotFound(w, r)
		return
	}

	// Verbose output and send the HTTP 302 (Found) redirection header.
	fmt.Printf("Redirecting %s to %s\n", urlKey, redirectURL)
	http.Redirect(w, r, redirectURL, 302)
}

func getRedirectURL(urlKey string) string {
	// Filter options for the query. Rowkey and Partitionkey in table storage should equal urlKey, but we only look for rowkey.
	options := storage.QueryOptions{
		Filter: fmt.Sprintf("RowKey eq '%s'", urlKey),
	}

	result, err := table.QueryEntities(30, fullmetadata, &options)

	// If the query produces an error, return an empty string
	if err != nil {
		fmt.Println(err)
		return ""
	}

	// If no results are found, return an empty string
	if len(result.Entities) == 0 {
		return ""
	}

	// Return the redirecturl property of the first entity.
	// In the strange case there are multiple results, we ignore all but the first.
	returnEntity := result.Entities[0]
	return returnEntity.Properties["redirecturl"].(string)
}
