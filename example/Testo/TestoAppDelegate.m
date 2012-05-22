//
//  TestoAppDelegate.m
//  Testo
//
//  Created by Justin Bishop on 5/18/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "TestoAppDelegate.h"

@implementation TestoAppDelegate

@synthesize window, textField;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  fbAuthenticator = [[[FBAuthenticator alloc] initWithAppID:210019096912] retain];
  [fbAuthenticator invalidateAccessToken];
  [fbAuthenticator setDelegate:self];

  [fbAuthenticator getAccessTokenWithPerms:[NSSet setWithArray:[NSArray arrayWithObject:@"email"]]
                               andCallback:^(NSString* accessToken) {
    [textField setStringValue:[NSString stringWithFormat:@"Got original access token: %@ with perms: %@",
      accessToken,
      [fbAuthenticator grantedPerms]]];
  }];
}

- (IBAction)fetchPerms:(id)sender {
  NSSet* extendedPerms = [NSSet setWithArray:
    [NSArray arrayWithObjects:@"email", @"user_hometown", @"publish_checkins", nil]];
  [fbAuthenticator getAccessTokenWithPerms:extendedPerms
                               andCallback:^(NSString* accessToken) {
    [textField setStringValue:[NSString stringWithFormat:@"Got extended access token: %@ with perms: %@",
      accessToken,
     [fbAuthenticator grantedPerms]]];
  }];
}

- (void)fbAuthWindowWillShow:(id)sender {
  [textField setStringValue:@"Now showing window..."];
}

@end
