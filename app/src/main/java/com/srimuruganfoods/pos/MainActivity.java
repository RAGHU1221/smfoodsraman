package com.srimuruganfoods.pos;

import android.annotation.SuppressLint;
import android.app.DownloadManager;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.Base64;
import android.view.View;
import android.webkit.CookieManager;
import android.webkit.JavascriptInterface;
import android.webkit.URLUtil;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.ProgressBar;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.FileProvider;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStream;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class MainActivity extends AppCompatActivity {

    // ══════════════════════════════════════════════════════════
    //  ★★★ CHANGE ONLY THIS LINE — your live InfinityFree URL ★★★
    // ══════════════════════════════════════════════════════════
    private static final String APP_URL = "https://smfoods.site.je/";

    private static final int FILE_CHOOSER_CODE = 101;

    private WebView webView;
    private ProgressBar progressBar;
    private SwipeRefreshLayout swipeRefresh;
    private ValueCallback<Uri[]> filePathCallback;

    @SuppressLint("SetJavaScriptEnabled")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        webView      = findViewById(R.id.webView);
        progressBar  = findViewById(R.id.progressBar);
        swipeRefresh = findViewById(R.id.swipeRefresh);

        WebSettings s = webView.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);          // localStorage → dark mode, IndexedDB offline billing
        s.setDatabaseEnabled(true);
        s.setAllowFileAccess(true);
        s.setCacheMode(WebSettings.LOAD_DEFAULT);
        s.setMixedContentMode(WebSettings.MIXED_CONTENT_ALWAYS_ALLOW);
        s.setUserAgentString(s.getUserAgentString() + " SriMuruganPOS/2.2");

        CookieManager.getInstance().setAcceptCookie(true);
        CookieManager.getInstance().setAcceptThirdPartyCookies(webView, true);

        // Bridge for jsPDF blob: downloads (WebView can't handle blob URLs natively)
        webView.addJavascriptInterface(new BlobDownloader(), "AndroidBlob");

        webView.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest req) {
                String url = req.getUrl().toString();
                // Keep app pages inside WebView; open everything else externally
                if (url.startsWith(APP_URL) || url.startsWith("file://")) return false;
                if (url.startsWith("tel:") || url.startsWith("mailto:") || url.startsWith("whatsapp:")
                        || url.startsWith("upi:") || url.startsWith("intent:")) {
                    try { startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(url))); }
                    catch (Exception ignored) {}
                    return true;
                }
                startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(url)));
                return true;
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                progressBar.setVisibility(View.GONE);
                swipeRefresh.setRefreshing(false);
            }

            @Override
            @SuppressWarnings("deprecation")
            public void onReceivedError(WebView view, int code, String desc, String failingUrl) {
                if (failingUrl != null && failingUrl.equals(view.getUrl())) {
                    view.loadUrl("file:///android_asset/offline.html");
                }
            }
        });

        webView.setWebChromeClient(new WebChromeClient() {
            @Override
            public void onProgressChanged(WebView view, int progress) {
                progressBar.setProgress(progress);
                progressBar.setVisibility(progress < 100 ? View.VISIBLE : View.GONE);
            }

            @Override
            public boolean onShowFileChooser(WebView view, ValueCallback<Uri[]> callback,
                                             FileChooserParams params) {
                if (filePathCallback != null) filePathCallback.onReceiveValue(null);
                filePathCallback = callback;
                try {
                    startActivityForResult(params.createIntent(), FILE_CHOOSER_CODE);
                } catch (Exception e) {
                    filePathCallback = null;
                    return false;
                }
                return true;
            }
        });

        // Normal http/https downloads (HTML-export Excel files, server PDFs)
        webView.setDownloadListener((url, userAgent, contentDisposition, mimeType, length) -> {
            if (url.startsWith("blob:")) {
                // Fetch blob inside the page and hand base64 to Android
                webView.evaluateJavascript(blobFetchJs(url, mimeType), null);
                return;
            }
            try {
                DownloadManager.Request req = new DownloadManager.Request(Uri.parse(url));
                String fileName = URLUtil.guessFileName(url, contentDisposition, mimeType);
                req.setMimeType(mimeType);
                req.addRequestHeader("Cookie", CookieManager.getInstance().getCookie(url));
                req.addRequestHeader("User-Agent", userAgent);
                req.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);
                req.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, fileName);
                ((DownloadManager) getSystemService(Context.DOWNLOAD_SERVICE)).enqueue(req);
                Toast.makeText(this, "Downloading " + fileName + "…", Toast.LENGTH_SHORT).show();
            } catch (Exception e) {
                Toast.makeText(this, "Download failed", Toast.LENGTH_SHORT).show();
            }
        });

        swipeRefresh.setOnRefreshListener(() -> webView.reload());
        swipeRefresh.setColorSchemeColors(0xFF6366F1);

        if (savedInstanceState != null) {
            webView.restoreState(savedInstanceState);
        } else if (isOnline()) {
            webView.loadUrl(APP_URL);
        } else {
            webView.loadUrl("file:///android_asset/offline.html");
        }
    }

    private boolean isOnline() {
        ConnectivityManager cm = (ConnectivityManager) getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo ni = cm != null ? cm.getActiveNetworkInfo() : null;
        return ni != null && ni.isConnected();
    }

    /** JS that fetches a blob: URL and passes base64 to the AndroidBlob bridge. */
    private static String blobFetchJs(String blobUrl, String mimeType) {
        return "(function(){fetch('" + blobUrl + "').then(r=>r.blob()).then(b=>{" +
               "var fr=new FileReader();fr.onload=function(){" +
               "AndroidBlob.save(fr.result.split(',')[1],'" + mimeType + "');};" +
               "fr.readAsDataURL(b);});})();";
    }

    /** JS bridge: save / open / share PDFs and other blob exports. */
    public class BlobDownloader {

        /** Legacy entry — jsPDF blob via DownloadListener. Saves + opens. */
        @JavascriptInterface
        public void save(String base64, String mimeType) {
            String ext = ".bin";
            if (mimeType != null) {
                if (mimeType.contains("pdf")) ext = ".pdf";
                else if (mimeType.contains("sheet") || mimeType.contains("excel")) ext = ".xlsx";
                else if (mimeType.contains("csv")) ext = ".csv";
                else if (mimeType.contains("png")) ext = ".png";
            }
            String name = "SMFoods_" +
                    new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(new Date()) + ext;
            saveAndOpen(base64, name, mimeType == null ? "application/octet-stream" : mimeType);
        }

        /** Save PDF to public Downloads/SMFoods and open it in a PDF viewer. */
        @JavascriptInterface
        public void savePdf(String base64, String fileName) {
            saveAndOpen(base64, safeName(fileName, ".pdf"), "application/pdf");
        }

        /** Open Android share sheet with the actual PDF file attached (WhatsApp etc.). */
        @JavascriptInterface
        public void sharePdf(String base64, String fileName, String message) {
            try {
                File f = writeToCache(base64, safeName(fileName, ".pdf"));
                Uri uri = FileProvider.getUriForFile(MainActivity.this,
                        "com.srimuruganfoods.pos.fileprovider", f);
                Intent send = new Intent(Intent.ACTION_SEND);
                send.setType("application/pdf");
                send.putExtra(Intent.EXTRA_STREAM, uri);
                if (message != null && !message.isEmpty())
                    send.putExtra(Intent.EXTRA_TEXT, message);
                send.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
                startActivity(Intent.createChooser(send, "Share Bill PDF"));
            } catch (Exception e) {
                toast("Share failed");
            }
        }

        /** Lets the web page detect the native bridge version. */
        @JavascriptInterface
        public int version() { return 2; }

        // ── internals ─────────────────────────────────────────

        private String safeName(String n, String ext) {
            if (n == null || n.trim().isEmpty())
                n = "SMFoods_" + new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(new Date());
            n = n.replaceAll("[^A-Za-z0-9._-]", "_");
            if (!n.toLowerCase(Locale.US).endsWith(ext)) n += ext;
            return n;
        }

        private File writeToCache(String base64, String name) throws Exception {
            byte[] data = Base64.decode(base64, Base64.DEFAULT);
            File dir = new File(getCacheDir(), "pdfs");
            if (!dir.exists()) dir.mkdirs();
            File out = new File(dir, name);
            try (FileOutputStream fos = new FileOutputStream(out)) { fos.write(data); }
            return out;
        }

        private void saveAndOpen(String base64, String name, String mime) {
            try {
                byte[] data = Base64.decode(base64, Base64.DEFAULT);
                Uri openUri;

                if (Build.VERSION.SDK_INT >= 29) {
                    // Public Downloads/SMFoods via MediaStore — visible in Files app
                    ContentValues cv = new ContentValues();
                    cv.put(MediaStore.Downloads.DISPLAY_NAME, name);
                    cv.put(MediaStore.Downloads.MIME_TYPE, mime);
                    cv.put(MediaStore.Downloads.RELATIVE_PATH,
                            Environment.DIRECTORY_DOWNLOADS + "/SMFoods");
                    openUri = getContentResolver()
                            .insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, cv);
                    if (openUri == null) throw new Exception("MediaStore insert failed");
                    try (OutputStream os = getContentResolver().openOutputStream(openUri)) {
                        os.write(data);
                    }
                } else {
                    // API 24–28: cache + FileProvider (still opens/shares fine)
                    File f = writeToCache(base64, name);
                    openUri = FileProvider.getUriForFile(MainActivity.this,
                            "com.srimuruganfoods.pos.fileprovider", f);
                }

                toast("Saved: Downloads/SMFoods/" + name);

                Intent view = new Intent(Intent.ACTION_VIEW);
                view.setDataAndType(openUri, mime);
                view.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
                try { startActivity(view); }
                catch (Exception noViewer) { /* no PDF viewer installed — file is still saved */ }
            } catch (Exception e) {
                toast("Save failed");
            }
        }

        private void toast(String msg) {
            runOnUiThread(() ->
                    Toast.makeText(MainActivity.this, msg, Toast.LENGTH_LONG).show());
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == FILE_CHOOSER_CODE && filePathCallback != null) {
            filePathCallback.onReceiveValue(
                    WebChromeClient.FileChooserParams.parseResult(resultCode, data));
            filePathCallback = null;
        }
    }

    @Override
    @SuppressWarnings("deprecation")
    public void onBackPressed() {
        if (webView.canGoBack()) webView.goBack();
        else super.onBackPressed();
    }

    @Override
    protected void onSaveInstanceState(Bundle out) {
        super.onSaveInstanceState(out);
        webView.saveState(out);
    }
}
