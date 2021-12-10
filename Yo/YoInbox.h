//
//  YoInbox.h
//  Yo
//
//  Created by Peter Reveles on 3/13/15.
//
//

#import <Foundation/Foundation.h>
#import "Yo.h"

@protocol YoInboxDelegate <NSObject>

@optional
- (void)yoInbox:(YoInbox *)inbox didUpdateStatusForYo:(Yo *)yo;
- (void)yoInbox:(YoInbox *)inbox didUpdateStatusesForYos:(NSArray *)yos;

@end

/*
 A point of access for all yo notifications. A user has has an inbox, when a notification
 is received, it should delivered here. From here it will be presented accordingly.
 */
@interface YoInbox : NSObject

@property (nonatomic, weak) id <YoInboxDelegate> delegate;

/**
 Pulls most up-to-date yos from server.
 @param success Set to false if an error is encountered while updating.
 */
- (void)updateWithCompletionBlock:(void (^)(BOOL sucess))completionBlock;

#pragma Yo Processing

/**
 Removes all yos in Yo Inbox. Does not save. There's no going back, use wisely.
 */
- (void)clearInbox;

/**
 Adds the yo if needed. Marks the Yo for the given status. Note: A Yo cannot be demoted in status.
 */
- (void)updateOrAddYo:(Yo *)yo withStatus:(YoStatus)status;

- (void)updateYos:(NSArray *)yos withStatus:(YoStatus)status;

#pragma mark Data Retrieving

/**
 Returns all yos in inbox which have the provided stats. 
 Call updateWithCompletionBlock: before to get most up-to-date response.
 Result is formatted in descending order based on creation date.
 */
- (NSArray *)getYosWithStatus:(YoStatus)status; // of kind Yo

- (Yo *)getYoWithID:(NSString *)yoID;

#pragma mark Network

- (void)grantNetworkAccessWithAPIClient:(YoAPIClient *)apiClient;

@end
