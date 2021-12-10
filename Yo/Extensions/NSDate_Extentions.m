
#import "NSDate_Extentions.h"

static NSArray *periods1  = nil;
static NSArray *periodsn  = nil;
static NSArray *intervals = nil;

@implementation NSDate (Extensions)

+ (NSDate *)dateWithUTCString:(NSString *)utc {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss"];
    NSDate *date = [dateFormatter dateFromString:utc];
    return date;
}

- (NSString *)getUTCFormat {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss"];
    NSString *dateString = [dateFormatter stringFromDate:self];
    return dateString;
}

+ (NSDate *)dateFromServerStringFormat:(NSString *)utc {
    static NSDateFormatter *dateFormatter = nil;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    }
    NSDate *date = [dateFormatter dateFromString:utc];
    return date;
}

- (NSString *)agoStringWithTimeOfDatEmoji {
    NSString *agoString = [self agoString];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitHour
                                                                   fromDate:self];
    NSArray *timeOfDayEmojis = @[@" ☀️",@" ⛅️",@" 🌙"];
    NSInteger hour = [components valueForComponent:NSCalendarUnitHour];
    NSInteger emojiIndex = 0;
    if (hour >= 6 && hour < 11) {
        emojiIndex = 0;
    }
    else if (hour >= 11 && hour < 19) {
        emojiIndex = 1;
    }
    else {
        emojiIndex = 2;
    }
    return [agoString stringByAppendingString:timeOfDayEmojis[emojiIndex]];
}

- (NSString *)agoString {
    if (periods1 == nil) {
          
		periods1 = [NSArray arrayWithObjects:
                   @"Second",
                   @"Minute",
                   @"Hour",
                   @"Day",
                   @"Week",
                   @"Month",
                   @"Year",
                   @"Decade",
                    nil];
		periodsn = [NSArray arrayWithObjects:
                    @"Seconds",
                    @"Minutes",
                    @"Hours",
                    @"Days",
                    @"Weeks",
                    @"Months",
                    @"Years",
                    @"Decades",
                    nil];
		intervals = [NSArray arrayWithObjects:
					 [NSNumber numberWithUnsignedInt:1],
					 [NSNumber numberWithUnsignedInt:60],
					 [NSNumber numberWithUnsignedInt:3600],
					 [NSNumber numberWithUnsignedInt:86400],
					 [NSNumber numberWithUnsignedInt:604800],
					 [NSNumber numberWithUnsignedInt:2630880],
					 [NSNumber numberWithUnsignedInt:31570560],
					 [NSNumber numberWithUnsignedInt:315705600],
					 nil];
	}
	NSTimeInterval diff = ABS([self timeIntervalSinceNow]);
	NSInteger numOfPeriods = 0, index;
	for (index = [intervals count] - 1; index >= 0; index--) {
		numOfPeriods = (diff / [[intervals objectAtIndex:index] unsignedIntValue]);
		if (numOfPeriods >= 1) {
			break;
		}
	}
	if (index < 0) {
		index = 0;
	}
	if (numOfPeriods == 0) {
		return @"Just now";
	}
    if (diff < 60.0) {
		return @"Just now";
    }
	NSArray *periods = (numOfPeriods > 1 ? periodsn : periods1);
	return [NSString stringWithFormat:@"%ld %@ %@",
            (long)numOfPeriods,
            [periods objectAtIndex:index],
            @"Ago"];
}

- (NSInteger)age {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    NSDateComponents *dateComponentsNow = [calendar components:unitFlags fromDate:[NSDate date]];
    NSDateComponents *dateComponentsBirth = [calendar components:unitFlags fromDate:self];
    
    if (([dateComponentsNow month] < [dateComponentsBirth month]) ||
        (([dateComponentsNow month] == [dateComponentsBirth month]) && ([dateComponentsNow day] < [dateComponentsBirth day]))) {
        return [dateComponentsNow year] - [dateComponentsBirth year] - 1;
    } else {
        return [dateComponentsNow year] - [dateComponentsBirth year];
    }
}

- (NSString *)messageTimeString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm"];
    NSString *dateString = [dateFormatter stringFromDate:self];
    return dateString;
}

- (NSString *)mediumDateString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    return [dateFormatter stringFromDate:self];
}

- (NSDate *)sameDateOnMidnight {
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *dayStartComponents = [gregorian components:(NSYearCalendarUnit |
                                                                  NSMonthCalendarUnit |
                                                                  NSDayCalendarUnit |
                                                                  NSWeekdayCalendarUnit |
                                                                  NSHourCalendarUnit |
                                                                  NSMinuteCalendarUnit |
                                                                  NSSecondCalendarUnit) fromDate:self];
    
    dayStartComponents.hour = 0;
    dayStartComponents.minute = 0;
    dayStartComponents.second = 0;
    return [gregorian dateFromComponents:dayStartComponents];
}

#pragma mark - UTC / Local time

- (NSString *)agoStringForUTCTime {
    return [[self toLocalTime] agoString];
}

- (NSString *)messageTimeStringForUTCTime {
    return [[self toLocalTime] messageTimeString];
}

- (NSDate *)toLocalTime
{
    NSTimeZone *timezone = [NSTimeZone systemTimeZone];
    NSInteger secondsTimeZoneDiff = [timezone secondsFromGMTForDate:self];
    return [NSDate dateWithTimeInterval:secondsTimeZoneDiff sinceDate:self];
}

- (NSDate *)toUTCTime
{
    NSTimeZone *timezone = [NSTimeZone systemTimeZone];
    NSInteger secondsTimeZoneDiff = -[timezone secondsFromGMTForDate:self];
    return [NSDate dateWithTimeInterval:secondsTimeZoneDiff sinceDate:self];
}


@end
