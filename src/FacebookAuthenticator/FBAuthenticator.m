#import "FBAuthenticator.h"
#import "SBJSON.h"

const NSInteger WINDOW_WIDTH = 640;
const NSInteger WINDOW_HEIGHT = 296;
NSString* const ACCESSTOKEN_KEY = @"FBAuth_accessToken";
NSString* const PERMISSIONS_KEY = @"FBAuth_grantedPerms";

@interface FBAuthenticator ()

- (void)closeWindow;

@end

@implementation FBAuthenticator

@synthesize delegate = _delegate;
@synthesize accessToken = _accessToken, grantedPerms = _grantedPerms;

- (id)initWithAppID:(NSInteger)appID {
    self = [super init];
    if (self) {
      _appID = appID;
      _accessToken = [[[NSUserDefaults standardUserDefaults] stringForKey:ACCESSTOKEN_KEY] retain];
      _grantedPerms = [[NSSet setWithArray:
        [[NSUserDefaults standardUserDefaults] arrayForKey:PERMISSIONS_KEY]] retain];
    }

    return self;
}

- (void)getAccessTokenWithPerms:(NSSet*)permissions andCallback:(void(^)(NSString*))callback {
  if (_webView || _window) {
    @throw [NSException exceptionWithName:@"WebViewOpenException"
                                   reason:@"Calling -getAccessToken: before previous has ended"
                                 userInfo:nil];
  }

  if (_callback) {
    @throw [NSException exceptionWithName:@"NestedCallbackException"
                                   reason:@"Nesting [fbAuthenticator callbacks causes bad access"
                                 userInfo:nil];
  }

  [self invalidateAccessToken];
  _callback = [callback copy];

  NSRect windowRect = NSMakeRect(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT);
  _window = [[NSWindow alloc] initWithContentRect:windowRect
                                        styleMask:NSTitledWindowMask
                                          backing:NSBackingStoreBuffered
                                            defer:YES];
  [_window setDelegate:self];
  _webView = [[WebView alloc] initWithFrame:windowRect
                                  frameName:nil
                                  groupName:nil];
  [_webView setFrameLoadDelegate:self];

  NSString* authURL = [NSString stringWithFormat:
    @"%@?client_id=%lu&redirect_uri=%@&scope=%@&response_type=token&display=popup",
    @"https://www.facebook.com/dialog/oauth",
    _appID,
    @"https://www.facebook.com/connect/login_success.html",
    [[permissions allObjects] componentsJoinedByString:@","]];

  [_webView setMainFrameURL:authURL];
  [_window setContentView:_webView];
}

- (void)fetchGrantedPermissions:(void(^)(NSSet*))callback {
  NSString* permissionsGraphURL = [NSString stringWithFormat:
    @"%@?access_token=%@",
    @"https://graph.facebook.com/me/permissions",
    _accessToken];
  NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:permissionsGraphURL]];

  void (^localCallback)(NSSet*);
  localCallback = [callback copy];

  [NSURLConnection sendAsynchronousRequest:request
                                     queue:[NSOperationQueue mainQueue]
                         completionHandler:
   ^(NSURLResponse* response, NSData* data, NSError* error) {
     NSString* result = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
     SBJsonParser* parser = [[[SBJsonParser alloc] init] autorelease];
     NSDictionary* _permsJSON = [parser objectWithString:result error:nil];
     [_grantedPerms release];
     _grantedPerms = [[NSSet setWithArray:[[[_permsJSON objectForKey:@"data"] objectAtIndex:0] allKeys]] retain];
     [[NSUserDefaults standardUserDefaults] setObject:[_grantedPerms allObjects] forKey:PERMISSIONS_KEY];

     localCallback(_grantedPerms);
     [localCallback release];
   }];
}

- (void)invalidateAccessToken {
  [_accessToken release];
  [_grantedPerms release];
  _accessToken = nil;
  _grantedPerms = nil;
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:ACCESSTOKEN_KEY];
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:PERMISSIONS_KEY];
}

- (void)webView:(WebView*)sender didFinishLoadForFrame:(WebFrame*)frame {
  if ([[_webView mainFrameURL] rangeOfString:@"error="].location != NSNotFound ||
      [[_webView mainFrameURL] rangeOfString:@"home.php"].location != NSNotFound) {
    [self invalidateAccessToken];
    [self closeWindow];

    _callback(nil);
    [_callback release];
    _callback = nil;

    return;
  }

  NSRange range = [[_webView mainFrameURL] rangeOfString:@"access_token=.+?[&$]"
                                                 options:NSRegularExpressionSearch];

  if (range.location != NSNotFound) {
    range.location += 13;
    range.length -= 13;

    [self invalidateAccessToken];
    _accessToken = [[[_webView mainFrameURL] substringWithRange:range] retain];
    [[NSUserDefaults standardUserDefaults] setObject:_accessToken forKey:ACCESSTOKEN_KEY];

    [self closeWindow];

    [self fetchGrantedPermissions:^(NSSet* grantedPermissions) {
      _callback(_accessToken);
      [_callback release];
      _callback = nil;
    }];

  } else {
    if (_delegate && [_delegate respondsToSelector:@selector(fbAuthWindowWillShow:)] && ![_window isVisible]) {
      [_delegate fbAuthWindowWillShow:self];
    }
    
    [_window makeKeyAndOrderFront:self];
    [_window center];
  }
}

- (void)closeWindow {
  [_window close];
  _window = nil;
  [_webView setFrameLoadDelegate:nil];
  [_webView release];
  _webView = nil;
}

- (void)dealloc {
  [_accessToken release];
  [_grantedPerms release];
  [_callback release];

  [_webView release];
  [_window release];

  [super dealloc];
}

@end
