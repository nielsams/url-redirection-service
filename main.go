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
	connectionString := os.Getenv("STORAGE_CONNECTION_STRING")
	client, err := storage.NewClientFromConnectionString(connectionString)
	if err != nil {
		fmt.Printf("%s: \n", err)
	}

	tableName := os.Getenv("STORAGE_TABLE_NAME")
	tableCli := client.GetTableService()
	table = tableCli.GetTableReference(tableName)

	http.HandleFunc("/", handleRequest)
	http.ListenAndServe(":8080", nil)

}

func handleRequest(w http.ResponseWriter, r *http.Request) {
	// We want all the characters from the first forward slash up to either '?' or the line end:
	re := regexp.MustCompile(`(^(\/))(([^\?])*)`)

	// The URL we want is in the third regex capture group:
	urlKey := url.QueryEscape(re.FindStringSubmatch(r.RequestURI)[3])

	if len(urlKey) == 0 {
		fmt.Printf("URL key not found.\n")
		http.NotFound(w, r)
		return
	}

	// Get redirectURL from the data provider:
	redirectURL := getRedirectURL(urlKey)

	if len(redirectURL) == 0 {
		fmt.Printf("No redirect URL found for key %s\n", urlKey)
		http.NotFound(w, r)
		return
	}

	fmt.Printf("Redirecting %s to %s\n", urlKey, redirectURL)
	http.Redirect(w, r, redirectURL, 302)
}

func getRedirectURL(urlKey string) string {
	options := storage.QueryOptions{
		Filter: fmt.Sprintf("RowKey eq '%s'", urlKey),
	}

	result, err := table.QueryEntities(30, fullmetadata, &options)

	if err != nil {
		fmt.Println(err)
		return ""
	}

	if len(result.Entities) == 0 {
		return ""
	}

	returnEntity := result.Entities[0]
	return returnEntity.Properties["redirecturl"].(string)
}
