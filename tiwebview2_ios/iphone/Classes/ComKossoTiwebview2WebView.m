// ComKossoTiwebview2WebView.m

#import "ComKossoTiwebview2WebView.h"
#import "TiApp.h"
#import "TiBase.h"
#import "TiFile.h"
#import "TiFilesystemFileProxy.h" // see below...
#import "SBJSON.h"

@implementation ComKossoTiwebview2WebView

#pragma mark Internal API's

extern NSString * const TI_APPLICATION_ID;

static NSString * const kTitaniumJavascript = @"Ti.App={};Ti.API={};Ti.App._listeners={};Ti.App._listener_id=1;Ti.App.id=Ti.appId;Ti.App._xhr=XMLHttpRequest;"
"Ti._broker=function(module,method,data){try{var url='app://'+Ti.appId+'/_TiA0_'+Ti.pageToken+'/'+module+'/'+method+'?'+Ti.App._JSON(data,1);"
"var xhr=new Ti.App._xhr();xhr.open('GET',url,false);xhr.send()}catch(X){}};"
"Ti._hexish=function(a){var r='';var e=a.length;var c=0;var h;while(c<e){h=a.charCodeAt(c++).toString(16);r+='\\\\u';var l=4-h.length;while(l-->0){r+='0'};r+=h}return r};"
"Ti._bridgeEnc=function(o){return'<'+Ti._hexish(o)+'>'};"
"Ti.App._JSON=function(object,bridge){var type=typeof object;switch(type){case'undefined':case'function':case'unknown':return undefined;case'number':case'boolean':return object;"
"case'string':if(bridge===1)return Ti._bridgeEnc(object);return'\"'+object.replace(/\"/g,'\\\\\"').replace(/\\n/g,'\\\\n').replace(/\\r/g,'\\\\r')+'\"'}"
"if((object===null)||(object.nodeType==1))return'null';if(object.constructor.toString().indexOf('Date')!=-1){return'new Date('+object.getTime()+')'}"
"if(object.constructor.toString().indexOf('Array')!=-1){var res='[';var pre='';var len=object.length;for(var i=0;i<len;i++){var value=object[i];"
"if(value!==undefined)value=Ti.App._JSON(value,bridge);if(value!==undefined){res+=pre+value;pre=', '}}return res+']'}var objects=[];"
"for(var prop in object){var value=object[prop];if(value!==undefined){value=Ti.App._JSON(value,bridge)}"
"if(value!==undefined){objects.push(Ti.App._JSON(prop,bridge)+': '+value)}}return'{'+objects.join(',')+'}'};"
"Ti.App._dispatchEvent=function(type,evtid,evt){var listeners=Ti.App._listeners[type];if(listeners){for(var c=0;c<listeners.length;c++){var entry=listeners[c];if(entry.id==evtid){entry.callback.call(entry.callback,evt)}}}};Ti.App.fireEvent=function(name,evt){Ti._broker('App','fireEvent',{name:name,event:evt})};Ti.API.log=function(a,b){Ti._broker('API','log',{level:a,message:b})};Ti.API.debug=function(e){Ti._broker('API','log',{level:'debug',message:e})};Ti.API.error=function(e){Ti._broker('API','log',{level:'error',message:e})};Ti.API.info=function(e){Ti._broker('API','log',{level:'info',message:e})};Ti.API.fatal=function(e){Ti._broker('API','log',{level:'fatal',message:e})};Ti.API.warn=function(e){Ti._broker('API','log',{level:'warn',message:e})};Ti.App.addEventListener=function(name,fn){var listeners=Ti.App._listeners[name];if(typeof(listeners)=='undefined'){listeners=[];Ti.App._listeners[name]=listeners}var newid=Ti.pageToken+Ti.App._listener_id++;listeners.push({callback:fn,id:newid});Ti._broker('App','addEventListener',{name:name,id:newid})};Ti.App.removeEventListener=function(name,fn){var listeners=Ti.App._listeners[name];if(listeners){for(var c=0;c<listeners.length;c++){var entry=listeners[c];if(entry.callback==fn){listeners.splice(c,1);Ti._broker('App','removeEventListener',{name:name,id:entry.id});break}}}};";

- (WKWebView*)webView
{
    if (_webView == nil) {
        [[TiApp app] attachXHRBridgeIfRequired];
        
        //WKUserContentController *userContentController = [[WKUserContentController alloc] init];
        //[[self userContentController] addScriptMessageHandler:self name:@"hostInbox"];

        _webView = [[WKWebView alloc] initWithFrame:[self bounds] configuration:[self configuration]];
        [_webView setUIDelegate:self];
        [_webView setNavigationDelegate:self];
        [_webView setContentMode:[self contentModeForWebView]];
        [_webView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
        
        [self addSubview:_webView];
    }
    
    return _webView;
}

/*
- (void)initializeState
{
    // Creates and keeps a reference to the view upon initialization
    WKUserContentController *userContentController = [[WKUserContentController alloc] init];

    [userContentController addScriptMessageHandler:self name:@"hostInbox"];
    
    WKPreferences *preference = [[WKPreferences alloc] init];
    preference.javaScriptCanOpenWindowsAutomatically = true;
    preference.javaScriptEnabled = true;

    
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.allowsInlineMediaPlayback = true;
    configuration.mediaPlaybackAllowsAirPlay = true;
    configuration.mediaPlaybackRequiresUserAction = false;
    configuration.preferences = preference;
    configuration.userContentController = userContentController;
    
    webView = [[WKWebView alloc] initWithFrame:[self frame] configuration:configuration];
    
    [webView setNavigationDelegate:self];
    [webView setContentMode:[self contentModeForWebView]];

    [self addSubview:webView];
    
    [userContentController release];
    [preference release];
    [configuration release];
    [super initializeState];
}
*/

-(void)dealloc
{
    // Deallocates the view
    RELEASE_TO_NIL(_webView);
    [super dealloc];
}


#pragma mark Public API's

/*
-(id)canGoBack
{
    NSLog(@"[INFO] FUCK canGoBack?")
    // return [TiUtils boolValue:[[[self webView] webView] canGoBack ]];
}
*/
 
- (void)setUrl_:(id)value
{
    ENSURE_TYPE(value, NSString);
    [[self proxy] replaceValue:value forKey:@"url" notification:NO];
    
    if ([[self webView] isLoading]) {
        [[self webView] stopLoading];
    }
    
    if ([[self proxy] _hasListeners:@"beforeload"]) {
        [[self proxy] fireEvent:@"beforeload" withObject:@{@"url": [TiUtils stringValue:value]}];
    }
    
    // Handle remote URL's
    if ([value hasPrefix:@"http"] || [value hasPrefix:@"https"]) {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[TiUtils stringValue:value]]];
        [[self webView] loadRequest:request];
        
    // Handle local URL's (WiP)
    } else {
        // Inject Titanium event support
        [[[[self webView] configuration] userContentController] addUserScript:[ComKossoTiwebview2WebView userScriptTitaniumGlobalEventSupport]];

        NSString *path = [self pathFromComponents:@[[TiUtils stringValue:value]]];
        [[self webView] loadFileURL:[NSURL URLWithString:path] allowingReadAccessToURL:[NSURL URLWithString:path]];
    }
}

- (void)setData_:(id)value
{
    [[self proxy] replaceValue:value forKey:@"data" notification:NO];
    
    if ([[self webView] isLoading]) {
        [[self webView] stopLoading];
    }
    
    if ([[self proxy] _hasListeners:@"beforeload"]) {
        [[self proxy] fireEvent:@"beforeload" withObject:@{@"url": [TiUtils stringValue:value]}];
    }
    
    NSData *data = nil;
    
    if ([value isKindOfClass:[TiBlob class]]) {
        data = [[(TiBlob*)value data] retain];
    } else if ([value isKindOfClass:[TiFile class]]) {
        // data = [[[(TiFilesystemFileProxy*)value blob] data] retain];
        
        // no idea why this wont build uncommented. error console :
        /*
         Undefined symbols for architecture arm64:
         [TRACE] :    "_OBJC_CLASS_$_TiFilesystemFileProxy", referenced from:
         [TRACE] :        objc-class-ref in libcom.kosso.tiwebview2.a(ComKossoTiwebview2WebView.o)
         [TRACE] :  ld: symbol(s) not found for architecture arm64
        */
        
        // Also see below...
        // I'm not using Files here, so...
        
    } else {
        NSLog(@"[ERROR] Ti.UI.iOS.WebView.data can only be a TiBlob or TiFile object, was %@", [(TiProxy*)value apiName]);
    }
    
    // Inject Titanium event support
    [[[[self webView] configuration] userContentController] addUserScript:[ComKossoTiwebview2WebView userScriptTitaniumGlobalEventSupport]];
    
    [[self webView] loadData:data
                    MIMEType:[ComKossoTiwebview2WebView mimeTypeForData:data]
       characterEncodingName:@"UTF-8" // TODO: Support other character-encodings as well
                     baseURL:[[NSBundle mainBundle] resourceURL]];
    
    RELEASE_TO_NIL(data);
}

- (void)setHtml_:(id)value
{
    ENSURE_TYPE(value, NSString);
    [[self proxy] replaceValue:value forKey:@"html" notification:NO];
   
    if ([[self webView] isLoading]) {
        [[self webView] stopLoading];
    }
    
    if ([[self proxy] _hasListeners:@"beforeload"]) {
        [[self proxy] fireEvent:@"beforeload" withObject:@{@"html": [TiUtils stringValue:value]}];
    }
    
    // Inject Titanium event support
    [[[[self webView] configuration] userContentController] addUserScript:[ComKossoTiwebview2WebView userScriptTitaniumGlobalEventSupport]];
    
    [[self webView] loadHTMLString:[TiUtils stringValue:value] baseURL:nil];
}

- (void)setDisableScrolling_:(id)value
{
    [[self proxy] replaceValue:value forKey:@"disableScrolling" notification:NO];
    [[[self webView] scrollView] setScrollEnabled:[TiUtils boolValue:value]];
}

- (void)setDisableBounce_:(id)value
{
    [[self proxy] replaceValue:value forKey:@"disableBounce" notification:NO];
    [[[self webView] scrollView] setBounces:[TiUtils boolValue:value]];
}

- (void)setScrollsToTop_:(id)value
{
    [[self proxy] replaceValue:value forKey:@"scrollsToTop" notification:NO];
    [[[self webView] scrollView] setScrollsToTop:[TiUtils boolValue:value def:YES]];
}

#pragma mark Delegates

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    // Use own event to notify the user that the web view started
    // to receive content but did not finish, yet
    if ([[self proxy] _hasListeners:@"loadprogress"]) {
        [[self proxy] fireEvent:@"loading" withObject:@{@"url": webView.URL.absoluteString}];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    if ([[self proxy] _hasListeners:@"load"]) {
        [[self proxy] fireEvent:@"load" withObject:@{@"url": webView.URL.absoluteString}];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    if ([[self proxy] _hasListeners:@"error"]) {
        [[self proxy] fireEvent:@"error" withObject:@{@"url": webView.URL.absoluteString, @"error": [error localizedDescription]}];
    }
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation
{
    if ([[self proxy] _hasListeners:@"redirect"]) {
        [[self proxy] fireEvent:@"redirect" withObject:@{@"url": webView.URL.absoluteString}];
    }
}

#pragma mark Utilities

- (WKWebViewConfiguration*)configuration
{
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    WKUserContentController *controller = [self userContentController];
    [controller addScriptMessageHandler:self name:@"hostInbox"];

    WKPreferences *preference = [[WKPreferences alloc] init];
    preference.javaScriptCanOpenWindowsAutomatically = true;
    preference.javaScriptEnabled = true;
    
    config.preferences = preference;
    
    id suppressesIncrementalRendering = [[self proxy] valueForKey:@"suppressesIncrementalRendering"];
    id scalePageToFit = [[self proxy] valueForKey:@"scalePageToFit"];
    id userAgent = [[self proxy] valueForKey:@"userAgent"];
    id allowsInlineMediaPlayback = [[self proxy] valueForKey:@"allowsInlineMediaPlayback"];
    id allowsAirPlayForMediaPlayback = [[self proxy] valueForKey:@"allowsAirPlayForMediaPlayback"];
    id allowsPictureInPictureMediaPlayback = [[self proxy] valueForKey:@"allowsPictureInPictureMediaPlayback"];
    id disableSelection = [[self proxy] valueForKey:@"disableSelection"];
    //id disableScrolling = [[self proxy] valueForKey:@"disableScrolling"];

    //if(disableScrolling){
    //    _webView.scrollView.scrollEnabled = false;
    //}
    
    if (suppressesIncrementalRendering) {
        [config setSuppressesIncrementalRendering:[TiUtils boolValue:suppressesIncrementalRendering def:NO]];
    }
    
    if (disableSelection) {
        [controller addUserScript:[ComKossoTiwebview2WebView userScriptDisableSelection]];
    }
    
    if (scalePageToFit) {
        [controller addUserScript:[ComKossoTiwebview2WebView userScriptScalePageToFit]];
    }
    
    if (userAgent) {
        // _webView.customUserAgent = [TiUtils stringValue:userAgent]; // SINCE iOS 9?
        [config setApplicationNameForUserAgent:[TiUtils stringValue:userAgent]]; // Seems to append to long standard agent string?
    }
    
    if (allowsInlineMediaPlayback) {
        [config setAllowsInlineMediaPlayback:[TiUtils boolValue:allowsInlineMediaPlayback]];
    }
    
    if (allowsAirPlayForMediaPlayback) {
        [config setAllowsAirPlayForMediaPlayback:[TiUtils boolValue:allowsAirPlayForMediaPlayback]];
    }

    if (allowsPictureInPictureMediaPlayback) {
        [config setAllowsPictureInPictureMediaPlayback:[TiUtils boolValue:allowsPictureInPictureMediaPlayback]];
    }
    
    [config setUserContentController:controller];

    [controller release];
    
    return [config autorelease];
}

- (WKUserContentController*)userContentController
{
    WKUserContentController *wkUController = [[WKUserContentController alloc] init];
    
    return [wkUController autorelease];
}

+ (WKUserScript*)userScriptScalePageToFit
{
    NSString *source = @"var meta = document.createElement('meta'); \
                         meta.setAttribute('name', 'viewport'); \
                         meta.setAttribute('content', 'width=device-width'); \
                         document.getElementsByTagName('head')[0].appendChild(meta);";
    
    return [[WKUserScript alloc] initWithSource:source injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
}

+ (WKUserScript*)userScriptDisableSelection
{
    NSString *source = @"var style = document.createElement('style'); \
                         style.type = 'text/css'; \
                         style.innerText = '*:not(input):not(textarea) { -webkit-user-select: none; -webkit-touch-callout: none; }'; \
                         var head = document.getElementsByTagName('head')[0]; \
                         head.appendChild(style);";
    
    return [[WKUserScript alloc] initWithSource:source
                                  injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                               forMainFrameOnly:YES];
}

+ (WKUserScript*)userScriptTitaniumGlobalEventSupport
{
    NSString *pageToken = [NSString stringWithFormat:@"%lu",(unsigned long)[self hash]];
    NSString *ti = [NSString stringWithFormat:@"%@%s",@"Ti","tanium"];
    NSString *config = [NSString stringWithFormat:@"window.%@={};window.Ti=%@;Ti.pageToken=%@;Ti.appId='%@';",ti, ti, pageToken,TI_APPLICATION_ID];
    
    return [[WKUserScript alloc] initWithSource:[NSString stringWithFormat:@"%@ %@", config, kTitaniumJavascript]
                                  injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                               forMainFrameOnly:YES];
}

-(NSString*)pathFromComponents:(NSArray*)args
{
    NSString * newPath;
    id first = [args objectAtIndex:0];
    
    if ([first hasPrefix:@"file://"]) {
        newPath = [[NSURL URLWithString:first] path];
    } else if ([first characterAtIndex:0]!='/') {
        newPath = [[[NSURL URLWithString:[self resourcesDirectory]] path] stringByAppendingPathComponent:[self resolveFile:first]];
    } else {
        newPath = [self resolveFile:first];
    }
    
    if ([args count] > 1) {
        for (int c = 1;c < [args count]; c++) {
            newPath = [newPath stringByAppendingPathComponent:[self resolveFile:[args objectAtIndex:c]]];
        }
    }
    
    return [newPath stringByStandardizingPath];
}

-(id)resolveFile:(id)arg
{
    //if ([arg isKindOfClass:[TiFilesystemFileProxy class]])
    //{
    //    return [(TiFilesystemFileProxy*)arg path];
    //}
    return [TiUtils stringValue:arg];
}

-(NSString*)resourcesDirectory
{
    return [NSString stringWithFormat:@"%@/",[[NSURL fileURLWithPath:[TiHost resourcePath] isDirectory:YES] path]];
}

// http://stackoverflow.com/a/32765708/5537752
+ (NSString *)mimeTypeForData:(NSData *)data
{
    uint8_t c;
    [data getBytes:&c length:1];
    
    switch (c) {
        case 0xFF:
            return @"image/jpeg";
            break;
        case 0x89:
            return @"image/png";
            break;
        case 0x47:
            return @"image/gif";
            break;
        case 0x49:
        case 0x4D:
            return @"image/tiff";
            break;
        case 0x25:
            return @"application/pdf";
            break;
        case 0xD0:
            return @"application/vnd";
            break;
        case 0x46:
            return @"text/plain";
            break;
        default:
            return @"application/octet-stream";
    }
    
    return nil;
}


// Add support for evaluating JS with the WKWebView and return back an evaluated value.
- (NSString*)stringByEvaluatingJavaScriptFromString:(NSString *)script withCompletionHandler:(void (^)(NSString *result, NSError *error))completionHandler
{
    [[self webView] evaluateJavaScript:script completionHandler:^(id result, NSError *error) {
        if (error == nil && result != nil) {
            completionHandler([NSString stringWithFormat:@"%@", result], nil);
        } else {
            NSLog(@"[ERROR] Evaluating JavaScript failed : %@", [error localizedDescription]);
            completionHandler(nil, error);
        }
    }];
}

#pragma mark TiEvaluator

- (void)evalFile:(NSString*)path
{
    NSURL *url_ = [path hasPrefix:@"file:"] ? [NSURL URLWithString:path] : [NSURL fileURLWithPath:path];
    
    if (![path hasPrefix:@"/"] && ![path hasPrefix:@"file:"]) {
        NSURL *root = [[[self proxy] _host] baseURL];
        url_ = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@",root,path]];
    }
    
    NSString *sourceCode = [NSString stringWithContentsOfURL:url_ encoding:NSUTF8StringEncoding error:nil];
    [[[[self webView] configuration] userContentController] addUserScript:[ComKossoTiwebview2WebView userScriptTitaniumJSEvaluationFromString:sourceCode]];
}

- (void)fireEvent:(id)listener withObject:(id)obj remove:(BOOL)yn thisObject:(id)thisObject_
{
    NSLog(@"[INFO] fireEvent");
    // don't bother firing an app event to the webview if we don't have a webview yet created
    if ([self webView] != nil)
    {
        
        NSLog(@"[INFO] fireEvent : webView ok");
        
        NSDictionary *event = (NSDictionary*)obj;
        NSString *name = [event objectForKey:@"type"];
        NSString *sourceCode = [NSString stringWithFormat:@"Ti.App._dispatchEvent('%@',%@,%@);",name,listener,[SBJSON stringify:event]];
        
        [[[[self webView] configuration] userContentController] addUserScript:[ComKossoTiwebview2WebView userScriptTitaniumJSEvaluationFromString:sourceCode]];
    }
}

+ (WKUserScript*)userScriptTitaniumJSEvaluationFromString:(NSString*)string
{
    return [[WKUserScript alloc] initWithSource:string
                                  injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                               forMainFrameOnly:YES];
}

- (void)updateContentMode
{
    if ([self webView] != nil) {
        [[self webView] setContentMode:[self contentModeForWebView]];
    }
}

- (UIViewContentMode)contentModeForWebView
{
    if (TiDimensionIsAuto(width) || TiDimensionIsAutoSize(width) || TiDimensionIsUndefined(width) ||
        TiDimensionIsAuto(height) || TiDimensionIsAutoSize(height) || TiDimensionIsUndefined(height)) {
        return UIViewContentModeScaleAspectFit;
    } else {
        return UIViewContentModeScaleToFill;
    }
}

#pragma mark Layout helper

- (void)setWidth_:(id)width_
{
    width = TiDimensionFromObject(width_);
    [self updateContentMode];
}

- (void)setHeight_:(id)height_
{
    height = TiDimensionFromObject(height_);
    [self updateContentMode];
}

-(void)frameSizeChanged:(CGRect)frame bounds:(CGRect)bounds
{
    // Sets the size and position of the view
    //[TiUtils setView:webview positionRect:bounds];
    for (UIView *child in [self subviews]) {
        [TiUtils setView:child positionRect:bounds];
    }
    
    [super frameSizeChanged:frame bounds:bounds];

}

-(void)loadUrl:(id)value
{
    NSString *urlString = [TiUtils stringValue:[value objectAtIndex:0]];
    NSLog(@"[INFO] loadUrl - %@", urlString);
    [self loadRequest:urlString];
}

-(void)loadRequest:(NSString *)urlString
{
    NSLog(@"[INFO] loadRequest - %@", urlString);
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [_webView loadRequest:request];
}

- (CGFloat)contentWidthForWidth:(CGFloat)suggestedWidth
{
    if (autoWidth > 0) {
        //If height is DIP returned a scaled autowidth to maintain aspect ratio
        if (TiDimensionIsDip(height) && autoHeight > 0) {
            return roundf(autoWidth * height.value / autoHeight);
        }
        return autoWidth;
    }
    
    CGFloat calculatedWidth = TiDimensionCalculateValue(width, autoWidth);
    if (calculatedWidth > 0) {
        return calculatedWidth;
    }
    
    return 0;
}

- (CGFloat)contentHeightForWidth:(CGFloat)width_
{
    if (width_ != autoWidth && autoWidth>0 && autoHeight > 0) {
        return (width_ * autoHeight/autoWidth);
    }
    
    if (autoHeight > 0) {
        return autoHeight;
    }
    
    CGFloat calculatedHeight = TiDimensionCalculateValue(height, autoHeight);
    if (calculatedHeight > 0) {
        return calculatedHeight;
    }
    
    return 0;
}

- (UIViewContentMode)contentMode
{
    if (TiDimensionIsAuto(width) || TiDimensionIsAutoSize(width) || TiDimensionIsUndefined(width) ||
        TiDimensionIsAuto(height) || TiDimensionIsAutoSize(height) || TiDimensionIsUndefined(height)) {
        return UIViewContentModeScaleAspectFit;
    } else {
        return UIViewContentModeScaleToFill;
    }
}


#pragma mark WKWebview Protocol 
- (void)userContentController:(WKUserContentController *)controller didReceiveScriptMessage:(WKScriptMessage *)message
{
    if ([[self proxy] _hasListeners:@"messageFromWebview"]) {
        NSDictionary *dict = [NSMutableDictionary dictionary];
        NSString *body = [TiUtils stringValue:message.body];
        [dict setValue:message.body forKey:@"message"];
        [[self proxy] fireEvent:@"messageFromWebview" withObject:dict];
    }
}

@end