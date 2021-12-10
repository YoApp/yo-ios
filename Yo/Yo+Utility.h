//
//  Yo+Utility.h
//  Yo
//
//  Created by Peter Reveles on 8/10/15.
//
//

#import "Yo.h"

@interface Yo (Utility)

- (BOOL)hasAudioURL;

#ifndef IS_APP_EXTENSION
- (void)open;
#endif

@end
