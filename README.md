# URL Redirection Service on Azure

This is a simple proof of concept app that redirects short URLs to long URLs. As an example, [go.nielsb.net/url-redirect](https://go.nielsb.net/url-redirect) points to this page.

It works by having a lightweight app that processes incoming requests, takes the URL path and matches it against an Azure Table Storage table to get the redirect URL and sends an HTTP 302 header back to the requestor. 

### Further instructions pending...
