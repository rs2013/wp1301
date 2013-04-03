package com.harryphoto.api;

import java.io.ByteArrayOutputStream;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.Socket;
import java.net.UnknownHostException;
import java.security.KeyManagementException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.UnrecoverableKeyException;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.util.zip.GZIPInputStream;

import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;

import org.apache.http.Header;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.HttpVersion;
import org.apache.http.StatusLine;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpDelete;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.client.methods.HttpUriRequest;
import org.apache.http.conn.ClientConnectionManager;
import org.apache.http.conn.params.ConnRoutePNames;
import org.apache.http.conn.scheme.PlainSocketFactory;
import org.apache.http.conn.scheme.Scheme;
import org.apache.http.conn.scheme.SchemeRegistry;
import org.apache.http.conn.ssl.SSLSocketFactory;
import org.apache.http.entity.ByteArrayEntity;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.impl.conn.tsccm.ThreadSafeClientConnManager;
import org.apache.http.params.BasicHttpParams;
import org.apache.http.params.HttpConnectionParams;
import org.apache.http.params.HttpParams;
import org.apache.http.params.HttpProtocolParams;
import org.apache.http.protocol.HTTP;

import android.text.TextUtils;
import android.util.Log;

public class HttpManager {

    // private static final String BOUNDARY = "7cd4a6d158c";
    private static final String BOUNDARY = getBoundry();
    private static final String MP_BOUNDARY = "--" + BOUNDARY;
    private static final String END_MP_BOUNDARY = "--" + BOUNDARY + "--";
    private static final String MULTIPART_FORM_DATA = "multipart/form-data";

    private static final String HTTPMETHOD_POST = "POST";
    public static final String HTTPMETHOD_GET = "GET";

    private static final int SET_CONNECTION_TIMEOUT = 5 * 1000;
    private static final int SET_SOCKET_TIMEOUT = 20 * 1000;

    /**
     * 
     * @param url
     *            服务器地址
     * @param method
     *            "GET"or “POST”
     * @param params
     *            存放参数的容器
     * @param file
     *            文件路径，如果 是发送带有照片的微博的话，此参数为图片在sdcard里的绝对路径
     * @return 响应结果
     * @throws HpException
     */
    public static String openUrl(String url, String method, HpParameters params)
            throws HpException {
        String result = "";
        try {
            HttpClient client = getNewHttpClient();
            HttpUriRequest request = null;
            ByteArrayOutputStream bos = null;
            client.getParams().setParameter(ConnRoutePNames.DEFAULT_PROXY,
                    NetStateManager.getAPN());
            if (method.equals(HTTPMETHOD_GET)) {
                url = url + "?" + Utility.encodeParameters(params);
                Log.i("HttpManager", "url=" + url);
                HttpGet get = new HttpGet(url);
                request = get;
            } else if (method.equals(HTTPMETHOD_POST)) {
                HttpPost post = new HttpPost(url);
                request = post;
                byte[] data = null;

                bos = new ByteArrayOutputStream();
                post.setHeader("Content-Type", MULTIPART_FORM_DATA + "; boundary=" + BOUNDARY);
                for (int i = 0, n = params.size(); i < n; i++) {
                    String k = params.getKey(i);
                    String v = params.getValue(i);
                    if (TextUtils.isEmpty(v)) v = "";
                    if (params.isFile(i)) {
                        imageContentToUpload(bos, k, v);
                    } else {
                        paramToUpload(bos, k, v);
                    }
                }
                bos.write((END_MP_BOUNDARY + "\r\n").getBytes());
                bos.close();
                data = bos.toByteArray();
                ByteArrayEntity formEntity = new ByteArrayEntity(data);
                post.setEntity(formEntity);
            } else if (method.equals("DELETE")) {
                request = new HttpDelete(url);
            }
            HttpResponse response = client.execute(request);
            StatusLine status = response.getStatusLine();
            int statusCode = status.getStatusCode();

            if (statusCode != 200) {
                result = readHttpResponse(response);
                throw new HpException(result, statusCode);
            }
            result = readHttpResponse(response);
            return result;
        } catch (IOException e) {
            throw new HpException(e);
        }
    }

    private static HttpClient getNewHttpClient() {
        try {
            KeyStore trustStore = KeyStore.getInstance(KeyStore
                    .getDefaultType());
            trustStore.load(null, null);

            SSLSocketFactory sf = new MySSLSocketFactory(trustStore);
            sf.setHostnameVerifier(SSLSocketFactory.ALLOW_ALL_HOSTNAME_VERIFIER);

            HttpParams params = new BasicHttpParams();

            HttpConnectionParams.setConnectionTimeout(params, 10000);
            HttpConnectionParams.setSoTimeout(params, 10000);

            HttpProtocolParams.setVersion(params, HttpVersion.HTTP_1_1);
            HttpProtocolParams.setContentCharset(params, HTTP.UTF_8);

            SchemeRegistry registry = new SchemeRegistry();
            registry.register(new Scheme("http", PlainSocketFactory
                    .getSocketFactory(), 80));
            registry.register(new Scheme("https", sf, 443));

            ClientConnectionManager ccm = new ThreadSafeClientConnManager(
                    params, registry);

            HttpConnectionParams.setConnectionTimeout(params,
                    SET_CONNECTION_TIMEOUT);
            HttpConnectionParams.setSoTimeout(params, SET_SOCKET_TIMEOUT);
            HttpClient client = new DefaultHttpClient(ccm, params);
            // if (NetState.Mobile == NetStateManager.CUR_NETSTATE) {
            // // 获取当前正在使用的APN接入点
            // HttpHost proxy = NetStateManager.getAPN();
            // if (null != proxy) {
            // client.getParams().setParameter(ConnRouteParams.DEFAULT_PROXY,
            // proxy);
            // }
            // }
            return client;
        } catch (Exception e) {
            return new DefaultHttpClient();
        }
    }

    private static class MySSLSocketFactory extends SSLSocketFactory {
        SSLContext sslContext = SSLContext.getInstance("TLS");

        public MySSLSocketFactory(KeyStore truststore)
                throws NoSuchAlgorithmException, KeyManagementException,
                KeyStoreException, UnrecoverableKeyException {
            super(truststore);

            TrustManager tm = new X509TrustManager() {
                public void checkClientTrusted(X509Certificate[] chain,
                        String authType) throws CertificateException {
                }

                public void checkServerTrusted(X509Certificate[] chain,
                        String authType) throws CertificateException {
                }

                public X509Certificate[] getAcceptedIssuers() {
                    return null;
                }
            };

            sslContext.init(null, new TrustManager[] { tm }, null);
        }

        @Override
        public Socket createSocket(Socket socket, String host, int port,
                boolean autoClose) throws IOException, UnknownHostException {
            return sslContext.getSocketFactory().createSocket(socket, host,
                    port, autoClose);
        }

        @Override
        public Socket createSocket() throws IOException {
            return sslContext.getSocketFactory().createSocket();
        }
    }

    private static void paramToUpload(OutputStream baos, String key, String value)
            throws HpException {
        StringBuilder temp = new StringBuilder();
        temp.append(MP_BOUNDARY).append("\r\n");
        temp.append("Content-Disposition: form-data; name=\"").append(key)
                .append("\"\r\n\r\n");
        temp.append(value).append("\r\n");
        try {
            baos.write(temp.toString().getBytes("UTF-8"));
        } catch (Exception e) {
            throw new HpException(e);
        }
    }

    private static void imageContentToUpload(OutputStream out, String key, String path)
            throws HpException {
        StringBuilder head = new StringBuilder();
        head.append(MP_BOUNDARY).append("\r\n");
        byte[] data = null;
        if (TextUtils.isEmpty(path)) {
            head.append("Content-Disposition: form-data; name=\"").append(key)
                .append("\"; filename=\"\"\r\n");
            head.append("Content-Type: application/octet-stream").append("\r\n\r\n");
            data = new byte[0];
        } else {
            String filename = Utility.getFileName(path);
            String ext = Utility.getFileExt(path);
            head.append("Content-Disposition: form-data; name=\"").append(key)
                .append("\"; filename=\"").append(filename).append("\"\r\n");
            head.append("Content-Type: ")
                .append(Utility.getMimeType(ext)).append("\r\n\r\n");
            ByteArrayOutputStream bos = new ByteArrayOutputStream();
            try {
                FileInputStream input = new FileInputStream(path);
                byte[] buffer = new byte[1024 * 50];
                while (true) {
                    int count = input.read(buffer);
                    if (count == -1) break;
                    bos.write(buffer, 0, count);
                }
                input.close();
                bos.close();
            } catch (IOException e) {
                throw new HpException(e);
            }
            data = bos.toByteArray();
        }
        try {
            out.write(head.toString().getBytes("UTF-8"));
            out.write(data);
            out.write("\r\n".getBytes());
        } catch (IOException e) {
            throw new HpException(e);
        }
    }

    /**
     * 读取HttpResponse数据
     * 
     * @param response
     * @return
     */
    private static String readHttpResponse(HttpResponse response) {
        String result = "";
        HttpEntity entity = response.getEntity();
        InputStream inputStream;
        try {
            inputStream = entity.getContent();
            ByteArrayOutputStream content = new ByteArrayOutputStream();

            Header header = response.getFirstHeader("Content-Encoding");
            if (header != null
                    && header.getValue().toLowerCase().indexOf("gzip") > -1) {
                inputStream = new GZIPInputStream(inputStream);
            }

            int readBytes = 0;
            byte[] sBuffer = new byte[4000];
            while ((readBytes = inputStream.read(sBuffer)) > 0) {
                content.write(sBuffer, 0, readBytes);
            }
            result = new String(content.toByteArray());
            return result;
        } catch (IllegalStateException e) {
        } catch (IOException e) {
        }
        return result;
    }

    /**
     * 产生11位的boundary
     */
    static String getBoundry() {
        StringBuffer _sb = new StringBuffer();
        for (int t = 1; t < 12; t++) {
            long time = System.currentTimeMillis() + t;
            if (time % 3 == 0) {
                _sb.append((char) time % 9);
            } else if (time % 3 == 1) {
                _sb.append((char) (65 + time % 26));
            } else {
                _sb.append((char) (97 + time % 26));
            }
        }
        return _sb.toString();
    }

}
