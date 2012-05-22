//
//  TestoAppDelegate.h
//  Testo
//
//  Created by Justin Bishop on 5/18/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <FacebookAuthenticator/FBAuthenticator.h>

@interface TestoAppDelegate : NSObject <NSApplicationDelegate, FBAuthenticatorDelegate> {
  NSWindow *window;
  FBAuthenticator* fbAuthenticator;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextField* textField;

- (IBAction)fetchPerms:(id)sender;

@end
