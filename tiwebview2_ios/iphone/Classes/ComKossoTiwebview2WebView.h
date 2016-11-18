// ComKossoTiwebview2WebView.h

#import "TiUIView.h"
#import "TiDimension.h"
#import "TiUtils.h"
#import "TiFile.h"
//#import "TiBlob.h"

#import <WebKit/WebKit.h>

@interface ComKossoTiwebview2WebView : TiUIView <WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler> {
    WKWebView *_webView;
    //WKUserContentController *userContentController;
    TiDimension width;
    TiDimension height;
    CGFloat autoHeight;
    CGFloat autoWidth;
}

- (WKWebView*)webView;

- (NSString*)stringByEvaluatingJavaScriptFromString:(NSString *)script withCompletionHandler:(void (^)(NSString *result, NSError *error))completionHandler;

// -(id)canGoBack;

@end