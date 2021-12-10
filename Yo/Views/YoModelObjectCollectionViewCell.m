//
//  YoModelObjectCollectionViewCell.m
//  Yo
//
//  Created by Peter Reveles on 6/16/15.
//
//

#import "YoModelObjectCollectionViewCell.h"

static void *YoContext = &YoContext;

@implementation YoModelObjectCollectionViewCell

- (void)dealloc
{
    [self.object removeObserver:self forKeyPath:NSStringFromSelector(@selector(dictionaryRepresentation))];
}

- (void)prepareForReuse
{
    [self.object removeObserver:self forKeyPath:NSStringFromSelector(@selector(dictionaryRepresentation))];
    self.object = nil;
}

- (void)setObject:(YoModelObject *)object
{
    YoModelObject *oldObject = self.object;
    
    _object = object;
    
    [oldObject removeObserver:self
                   forKeyPath:NSStringFromSelector(@selector(dictionaryRepresentation))];
    
    [object addObserver:self
             forKeyPath:NSStringFromSelector(@selector(dictionaryRepresentation))
                options:NSKeyValueObservingOptionNew
                context:YoContext];
    
    [self objectDidChange];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([object isEqual:self.object]) {
        [self objectDidChange];
    }
}

- (void)objectDidChange
{
    DDLogWarn(@"Subclasses of %@ should implement this.", NSStringFromClass([self class]));
    return;
}

@end
