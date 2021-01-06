# url-redirection-service

## Running locally

- Clone the repo
- From inside the app folder:

```
docker build -t "redirector" .
docker run -p 8080:8080 -d -e STORAGE_CONNECTION_STRING="[storage connection string]" -e STORAGE_TABLE_NAME=redirecturls redirector
```
