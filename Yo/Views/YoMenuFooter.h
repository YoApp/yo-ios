//
//  YoMenuFooter.h
//  Yo
//
//  Created by Or Arbel on 5/15/15.
//
//

typedef void (^Block) (void);

@interface YoMenuFooter : UIView

@property(nonatomic, copy) Block downArrowPressedBlock;

- (IBAction)downArrowButtonPressed:(id)sender;

@end
