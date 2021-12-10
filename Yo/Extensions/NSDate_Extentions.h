
#import <Foundation/Foundation.h>


@interface NSDate (Extensions)

+ (NSDate *)dateWithUTCString:(NSString *)utc;
+ (NSDate *)dateFromServerStringFormat:(NSString *)utc;
- (NSString *)messageTimeString;
- (NSString *)mediumDateString;
- (NSString *)getUTCFormat;
- (NSString *)agoString;
- (NSString *)agoStringWithTimeOfDatEmoji;
- (NSInteger)age;
- (NSDate *)sameDateOnMidnight;

- (NSString *)messageTimeStringForUTCTime;
- (NSString *)agoStringForUTCTime;
- (NSDate *)toLocalTime;
- (NSDate *)toUTCTime;

@end
