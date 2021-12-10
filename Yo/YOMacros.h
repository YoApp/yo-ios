//
//  YOMacros.h
//  Yo
//
//  Created by Tomer on 7/24/14.
//
//

// Calling to END_BACKGROUND_TASK must be from same scope of START_BACKGROUND_TASK (Convinient for completion blocks)
#define START_BACKGROUND_TASK       __block UIBackgroundTaskIdentifier mobliMacroBgTaskId = UIBackgroundTaskInvalid; \
DDLogVerbose(@"Starting bg task"); \
mobliMacroBgTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{ \
[[UIApplication sharedApplication] endBackgroundTask:mobliMacroBgTaskId]; \
mobliMacroBgTaskId = UIBackgroundTaskInvalid; \
DDLogVerbose(@"Expiration handler called for bg task"); \
}];

#define END_BACKGROUND_TASK         [[UIApplication sharedApplication] endBackgroundTask:mobliMacroBgTaskId]; \
DDLogVerbose(@"Ending bg task");