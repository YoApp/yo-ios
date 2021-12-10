//
//  YoAlert.h
//  Yo
//
//  Created by Peter Reveles on 2/3/15.
//
//

#import <Foundation/Foundation.h>
#import "YoAlertAction.h"

@interface YoAlert : NSObject

@property (readonly, nonatomic) NSString *title;
@property (readonly, nonatomic) NSAttributedString *descriptionText;
@property (readonly, nonatomic) UIImage *image;
@property (readonly, nonatomic) NSMutableArray *actions;
@property (nonatomic, assign) BOOL userActionRequired;

- (instancetype)initWithTitle:(NSString *)title
                   desciption:(NSString *)description;

- (instancetype)initWithTitle:(NSString *)tile
        attributedDesciption:(NSAttributedString *)attributedDesciption;

- (instancetype)initWithTitle:(NSString *)title
                        image:(UIImage *)image
                   desciption:(NSString *)description;

- (instancetype)initWithTitle:(NSString *)title
                        image:(UIImage *)image
         attributedDesciption:(NSAttributedString *)attributedDesciption;

- (void)addAction:(YoAlertAction *)action;

@end
