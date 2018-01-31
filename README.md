# Mura Link Checker
A Mura 7 plugin looking for all broken and redirected links in a Mura site.

## Usage
Running the check for all the links is just a matter of clicking on the "Start checking the site" button.

Timeout can be increased to reduce the risk of timeouts, or reduced to make the check faster.

Redirects can be ignored, which means that URLs returning 301 codes will not be reported. In this case, the link checker will follow redirects to see if the redirection returns an error code.

## Results

Each issue is reported with the page containing the link, the status, the HTML element the link is on (the link checker checks `a`, `img`, `video`, `audio`, `source`, `track`, `embed`, `script` and `iframe`), and the link.

The status is usually the returned status code, but it can be a string for internal links or if the link checker has problems when connecting. For instance, if a Mura page is not found for an internal link, the status will be "not found", but the link checker does not actually try an HTTP connection in this case, it just looks in the Mura database to see if the page exists (which is much faster).

## Known Issues

- Some SSL issues are simply caused by Java Virtual Machine limitations in handling SSL certificates and can be disregarded. Replacing the Java Cryptography Extension policy files as [suggested here](https://stackoverflow.com/questions/38203971/javax-net-ssl-sslhandshakeexception-received-fatal-alert-handshake-failure) can fix some of these issues.

- Some sites do not support the HEAD method used by the link checker, and will report a 405 status code.

