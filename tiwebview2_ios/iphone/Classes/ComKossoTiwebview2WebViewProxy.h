// ComKossoTiwebview2WebViewProxy.h

#import "TiViewProxy.h"

@interface ComKossoTiwebview2WebViewProxy : TiViewProxy {
    BOOL inKJSThread;
    NSString *evalResult;
}

@end