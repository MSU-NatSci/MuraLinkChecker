
<cfscript>
    include 'plugin/config.cfm';

    import model.Extractor;
    import model.Checker;

    action($, pluginConfig);

    function action($, pluginConfig) {
        var action = $.event('action');
        var result = {};

        var result = {};
        if (action == 'extract_links') {
            var extractor = new model.Extractor($);
            var pages = extractor.extractLinks();
            cfcontent(type="application/json");
            writeOutput(serializeJSON(pages));
        } else if (action == 'check_links') {
            var checker = new model.Checker($, pluginConfig);
            var urls = deserializeJSON($.event('urls'));
            var timeout = val($.event('timeout'));
            var followRedirects = ($.event('followRedirects') == 'yes');
            var results = checker.check(urls, timeout, followRedirects);
            cfcontent(type="application/json");
            writeOutput(serializeJSON(results));
        } else {
            include 'views/default.cfm';
        }
    }
</cfscript>
