//
//  YoStoreItem.h
//  Yo
//
//  Created by Peter Reveles on 3/19/15.
//
//

#import <Foundation/Foundation.h>

/* Example itemData
 {
 "_id" = 54ff3b6e84391400ce96da7a;
 "added_at" = 1425967200000000;
 "carousel_picture" = "SPOTIFY.png";
 category =     (
 Music
 );
 created = 1426013038262788;
 description = "The best breaking acts from the Spotify House at SXSW, 2015";
 "featured_screenshots" =     (
 "SPOTIFY1.png",
 "SPOTIFY2.png",
 "SPOTIFY3.png",
 "SPOTIFY4.png"
 );
 "in_carousel" = 0;
 "is_official" = 1;
 name = SPOTIFY;
 "needs_location" = 0;
 "profile_picture" = "SPOTIFY.png";
 rank = 1;
 region = World;
 updated = 1426790462024976;
 url = "http://www.spotify.com/";
 username = SPOTIFY;
 }
*/

@interface YoStoreItem : NSObject

- (instancetype)initWithItemData:(id)itemData;

@property (nonatomic, readonly) NSString *name;

@property (nonatomic, readonly) NSString *username;

@property (nonatomic, readonly) NSString *profilePictureFileName;

@property (nonatomic, readonly) NSString *itemDescription;

@property (nonatomic, readonly) NSURL *url;

@property (nonatomic, readonly) NSString *itemID;

@property (nonatomic, readonly) NSInteger rank;

@property (nonatomic, readonly) NSString *carouselPistureFileName;

@property (nonatomic, readonly) NSArray *categories;

@property (nonatomic, readonly) NSArray *screenShotFileNames;

@property (nonatomic, readonly) BOOL needsLocation;

@property (nonatomic, readonly) BOOL isInCarousel;

@property (nonatomic, readonly) BOOL isOfficial;

@property (nonatomic, readonly) id itemData;

#pragma mark - Utility

- (BOOL)isEqualToItem:(YoStoreItem *)item;

@end
