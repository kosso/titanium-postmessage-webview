// ComKossoTiwebview2WebViewProxy.m

#import "ComKossoTiwebview2WebViewProxy.h"
#import "ComKossoTiwebview2WebView.h"
#import "TiUtils.h"

@implementation ComKossoTiwebview2WebViewProxy

- (ComKossoTiwebview2WebView*)webView
{
    return (ComKossoTiwebview2WebView*)self.view;
}


- (void)stopLoading:(id)args
{
    [[[self webView] webView] stopLoading];
}

- (void)goBack:(id)args
{
    [[[self webView] webView] goBack];
}

- (void)goForward:(id)args
{
    [[[self webView] webView] goForward];
}

-(BOOL)isLoading:(id)args
{
    return [[[self webView] webView] isLoading ];
}

- (BOOL)canGoBack:(id)args
{
    return [[[self webView] webView] canGoBack ];
}

-(BOOL)canGoForward:(id)args
{
    return [[[self webView] webView] canGoForward ];
}

- (BOOL)reload:(id)args
{
    return [[[self webView] webView] reload ];
}

- (void)evalJS:(id)args
{
    NSString *code = nil;
    KrollCallback *callback = nil;
    
    code = [args objectAtIndex:0];
    ENSURE_TYPE(code, NSString);

    if ([args count] > 1) {
        callback = [args objectAtIndex:1];
        ENSURE_TYPE(callback, KrollCallback);
    }
    
    [[self webView] stringByEvaluatingJavaScriptFromString:code withCompletionHandler:^(NSString *result, NSError *error) {
        NSDictionary * propertiesDict = @{
                                          @"result": result ?: [NSNull null],
                                          @"success": NUMBOOL(error == nil),
                                          @"error" : [error localizedDescription] ?: [NSNull null]
                                          };
        
        if ([self _hasListeners:@"evalJSResult"]) {
            [self fireEvent:@"evalJSResult" withObject:propertiesDict];
        }
        
        if(callback){
            NSArray *invocationArray = [[NSArray alloc] initWithObjects:&propertiesDict count:1];
            [callback call:invocationArray thisObject:self];
            [invocationArray release];
        }
        
    }];
}




@end