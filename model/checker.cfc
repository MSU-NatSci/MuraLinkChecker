/**
 * This component checks a number of URLs.
 */
component {

    public function init($, pluginConfig) {
        variables.$ = $;
        variables.pluginConfig = pluginConfig;
    }

    /**
     * returns an array of (string url, string status)
     */
    public array function check(required array urls, required numeric timeout,
            required boolean followRedirects) {
        var results = [];

        // Using NaiveSSL to avoid cert validation errors
        var naiveSSL = initNaiveSSL();

        var baseURL = $.siteConfig().getWebPath(complete=1);
        for (var aURL in urls) {
            var status = '-1';
            if (aURL.findNoCase('ftp://') == 1) {
                status = "unsupported protocol";
            } else if (aURL.reFind('^/[^/]') > 0 &&
                    aURL.reFind('^(?:/sites)?/[^/]+/(cache|assets)/') == 0) {
                // local link but not cache or assets (should be content)
                // we can check the db for a faster result
                var path = aURL.reReplace('^/|/$', '', 'all');
                path = path.reReplace('##.*', '');
                path = path.reReplace('/category/.*', '');
                var page = $.getBean('content').loadBy(filename=path);
                if (page.getIsNew())
                    status = 'not found';
                else
                    status = '200';
            } else {
                var tURL = aURL;
                if (tURL.reFind('^https?://') == 0) {
                    if (tURL.reFind('^//') == 1) {
                        if ($.siteConfig().getUseSSL())
                            tURL = 'https:' & tURL;
                        else
                            tURL = 'http:' & tURL;
                    } else {
                        tURL = baseURL & tURL;
                    }
                }
                status = testURL(tURL, timeout, followRedirects, naiveSSL);
            }
            results.append({
                'url': aURL,
                'status': status
            });
        }

        return results;
    }

    private string function testURL(required string aURL, required numeric timeout,
            required boolean followRedirects, required any naiveSSL) {
        /* cfhttp does not work well with SSL (some validations fail and we don't get a code)
        if (len(application.configBean.getProxyServer())) {
            cfhttp(url=aURL, method="HEAD", timeout=timeout, result="result",
                    proxyUser="#configBean.getProxyUser()#" ,
                    proxyPassword="#configBean.getProxyPassword()#",
                    proxyServer="#configBean.getProxyServer()#" ,
                    proxyPort="#configBean.getProxyPort()#");
        } else {
            cfhttp(url=aURL, method="HEAD", timeout=timeout, result="result");
        }

        if (result.errorDetail != '' || result.statusCode == '') {
            // sometimes getting
            // I/O Exception: sun.security.validator.ValidatorException: PKIX path building failed: java.security.cert.CertPathBuilderException: Could not build a validated path.
            return -1;
        }
        var code = result.statusCode.reReplace('^(\d+)\s.*$', '\1');

        if (code.reFind('^\d+$') == 1)
            return code;
        else
            return -1;
        */
        try {
            var configBean = $.getConfigBean();
            var proxyServer = configBean.getProxyServer();
            var proxyPort = configBean.getProxyPort();
            var proxyUsername = configBean.getProxyUser();
            var proxyPassword = configBean.getProxyPassword();
            if (proxyPort == '')
                proxyPort = 0;
            var code = naiveSSL.testURL(aURL, timeout * 1000, followRedirects,
                proxyServer, proxyPort, proxyUsername, proxyPassword);
            return '#code#';
        } catch (java.net.SocketTimeoutException e) {
            return "timeout";
        } catch (javax.net.ssl.SSLHandshakeException e) {
            return "SSL issue";
        } catch (javax.net.ssl.SSLException e) {
            return "SSL issue";
        } catch (java.net.UnknownHostException e) {
            return "unknown host";
        } catch (java.net.MalformedURLException e) {
            return "malformed URL";
        } catch (java.net.ProtocolException e) {
            return "protocol error"; // can be a looping redirect
        } catch (java.net.SocketException e) {
            return "connection issue";
        } catch (any e) {
            return e.getClass().getName();
        }
    }

    private any function initNaiveSSL() {
        //var pluginPath = "#$.getConfigBean().getPluginDir()#/#pluginConfig.getDirectory()#";
        //var libFolder = "#pluginPath#/java/dist";
        //var jarArray = [
        //    '#libFolder#/naiveSSL.jar'
        //];
        //var javaLoader = createObject('component', 'mura.javaloader.JavaLoader').init(jarArray);
        //var naive = javaLoader.create('linkchecker.NaiveSSL').init();

        // directly with URLClassLoader (JavaLoader is no longer part of Mura)
        var pluginPath = "#$.getConfigBean().getPluginDir()#/#pluginConfig.getDirectory()#";
        var libFolder = "#pluginPath#/java/dist";
        var naiveJarPath = "#libFolder#/naiveSSL.jar";
        var naiveJarURL = createObject('java', 'java.io.File').init(naiveJarPath).toURI().toURL();
        var classLoader = createObject('java', 'java.net.URLClassLoader').init([naiveJarURL]);
        var naiveClass = classLoader.loadClass('linkchecker.NaiveSSL');
        var naive = naiveClass.newInstance();
        classLoader.close(); // to avoid locking the jar
        return naive;
    }
}
