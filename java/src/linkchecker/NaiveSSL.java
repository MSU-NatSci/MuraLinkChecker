// compilation: javac -source 1.7 -target 1.7 linkchecker/NaiveSSL.java
// creating the jar: jar cf naiveSSL.jar 'linkchecker/NaiveSSL$1.class'  'linkchecker/NaiveSSL$2.class'  'linkchecker/NaiveSSL.class'
// then move the jar to dist
package linkchecker;

import java.io.IOException;
import java.net.*;
import javax.net.ssl.*;
import java.security.*;
import java.security.cert.X509Certificate;
import javax.xml.bind.DatatypeConverter;

/**
 * To get a status code from any URL, including SSL without checking certificates.
  * Implementation based on https://stackoverflow.com/questions/875467/java-client-certificates-over-https-ssl
 */
public class NaiveSSL {

    HostnameVerifier naiveHostnameVerifier;
    SSLSocketFactory naiveSSLSocketFactory;

    public static void main(String[] args) throws
            NoSuchAlgorithmException, KeyManagementException, IOException, MalformedURLException {
        // for testing, with a URL
        NaiveSSL naive = new NaiveSSL();
        int code = naive.testURL(args[0], 10000, false, null, 0, null, null); // 10s timeout
        System.out.println("Code: " + code);
    }

    public NaiveSSL() throws NoSuchAlgorithmException, KeyManagementException {
        TrustManager[] trustAllCerts = new TrustManager[] {
            new X509TrustManager() {
                public X509Certificate[] getAcceptedIssuers() {
                    return new X509Certificate[0];
                }
                public void checkClientTrusted(X509Certificate[] certs, String authType) {}
                public void checkServerTrusted(X509Certificate[] certs, String authType) {}
            }
        };

        naiveHostnameVerifier = new HostnameVerifier() {
            public boolean verify(String hostname, SSLSession session) { return true; }
        };

        SSLContext sc = SSLContext.getInstance("SSL");
        sc.init(null, trustAllCerts, new SecureRandom());
        naiveSSLSocketFactory = sc.getSocketFactory();
    }

    public int testURL(String url, int timeout, boolean followRedirects,
            String proxyServer, int proxyPort,
            String proxyUsername, String proxyPassword) throws
            IllegalArgumentException, IOException, MalformedURLException {
        String oldProtocols = System.getProperty("https.protocols");
        System.getProperties().setProperty("https.protocols", "TLSv1.2,TLSv1.1,TLSv1,SSLv3");
        // URL u = new URL(url);
        // will not work in ColdFusion 11, it returns a
        // com.sun.net.ssl.internal.www.protocol.https.HttpsURLConnectionOldImpl
        // instead of a sun.net.www.protocol.https.HttpsURLConnectionImpl
        URL u;
        if (url.startsWith("https"))
            u = new URL(null, url, new sun.net.www.protocol.https.Handler());
        else
            u = new URL(url);
        Proxy proxy;
        boolean usingProxy = (proxyServer != null && !proxyServer.equals(""));
        // NOTE: proxy has not been tested !!!
        if (usingProxy)
            proxy = new Proxy(Proxy.Type.HTTP, new InetSocketAddress(proxyServer, proxyPort));
        else
            proxy = Proxy.NO_PROXY;
        HttpURLConnection connection = (HttpURLConnection)u.openConnection(proxy);
        if (usingProxy && proxyUsername != null && !proxyUsername.equals("")) {
            String encoded = DatatypeConverter.printBase64Binary(
                    new String(proxyUsername + ":" + proxyPassword).getBytes("UTF-8"));
            connection.setRequestProperty("Proxy-Authorization", "Basic " + encoded);
        }
        if (connection instanceof HttpsURLConnection) {
            HttpsURLConnection sslConnection = (HttpsURLConnection)connection;
            sslConnection.setSSLSocketFactory(naiveSSLSocketFactory);
            sslConnection.setHostnameVerifier(naiveHostnameVerifier);
        }
        connection.setConnectTimeout(timeout);
        connection.setRequestMethod("HEAD");
        connection.setFollowRedirects(followRedirects);
        connection.setRequestProperty("User-Agent", "Mozilla/5.0 (MuraLinkChecker)");
        try {
            return connection.getResponseCode();
        } finally {
            if (oldProtocols == null)
                System.clearProperty("https.protocols");
            else
                System.getProperties().setProperty("https.protocols", oldProtocols);
        }
    }
    
}
