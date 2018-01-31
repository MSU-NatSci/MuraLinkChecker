/**
 * This component can extract all links from a site.
 */
component {

	public function init($) {
		variables.$ = $;
	}

	/**
	 * Returns an array with the pages.
     * Each page object has url and links. Each link has element and url.
	 */
	public array function extractLinks() {
        var pages = [];
        var feedBean = $.getFeed('content');
        feedBean.setMaxItems(0);
        feedBean.setItemsPerPage(0);
        feedBean.setIncludeHomePage(true);
        feedBean.setShowNavOnly(false);
        feedBean.setShowExcludeSearch(true);
        //feedBean.setLiveOnly(false);
        iterator = feedBean.getIterator();
        while (iterator.hasNext()) {
            var item = iterator.next();
            var body = item.getBody();
            var summary = item.getSummary();
            var links = [];
            links.append(findLinksInHTML(body), true);
            links.append(findLinksInHTML(summary), true);
            pages.append({
                'url': item.getUrl(),
                'links': links
            });
        }
        return pages;
	}

    /**
     * Returns an array of (string element, string url)
     */
    private array function findLinksInHTML(required string text) {
        var links = [];
        var pos = 1;
        var done = false;
        while (!done) {
            var matches = text.reFind('<(a|img|video|audio|source|track|embed|script|iframe)[^>]*(?:href|src)\s?=\s?["'']([^"''>]*)["'']', pos, true);
            if (matches.len[1] != 0) { // match
                var element = text.mid(matches.pos[2], matches.len[2]);
                var theURL = text.mid(matches.pos[3], matches.len[3]);
                theURL = theURL.replace('&amp;', '&', 'all');
                if (theURL.reFindNoCase('^(mailto:|tel:|data:|javascript:|##|\[mura\]|/Shibboleth\.sso/)') == 0) {
                    links.append({
                        'element': element,
                        'url': theURL
                    });
                }
                pos = matches.pos[1] + matches.len[1];
            } else {
                done = true;
            }
        }
        return links;
    }
}
