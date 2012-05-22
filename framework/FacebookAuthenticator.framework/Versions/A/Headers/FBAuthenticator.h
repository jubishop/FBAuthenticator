#import <Foundation/Foundation.h>

#import <WebKit/WebKit.h>

@protocol FBAuthenticatorDelegate
@optional

- (void)fbAuthWindowWillShow:(id)sender;

@end

@interface FBAuthenticator : NSObject <NSWindowDelegate> {
  @private id _delegate;
  @private NSInteger _appID;
  @private NSString* _accessToken;

  @private NSSet* _grantedPerms;

  @private WebView* _webView;
  @private NSWindow* _window;

  @private void (^_callback)(NSString*);
}

- (id)initWithAppID:(NSInteger)appID;

- (void)getAccessTokenWithPerms:(NSSet*)permissions andCallback:(void(^)(NSString*))callback;
- (void)fetchGrantedPermissions:(void(^)(NSSet*))callback;

- (void)invalidateAccessToken;

@property (readonly) NSString* accessToken;
@property (readonly) NSSet* grantedPerms;
@property (assign) id <FBAuthenticatorDelegate> delegate;

@end
