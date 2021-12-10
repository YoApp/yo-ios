//
//  YoGroupMemberDisplayView.m
//  Yo
//
//  Created by Peter Reveles on 6/1/15.
//
//

#import "YoGroupMemberDisplayView.h"
#import "YoGroupMememberDisplayCell.h"
#import "YoThemeManager.h"
#import "YoContact.h"

@interface YoGroupMemberDisplayView () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (weak, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) NSOrderedSet *groupMembers; // of YoContact
@end

NSString *const GroupMemberDisplayCollectionViewCellReuseID = @"GroupMemberDisplayCellReuseID";

@implementation YoGroupMemberDisplayView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
    [self setup];
}

- (void)setup {
    UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
    flowLayout.minimumLineSpacing = 0.0f;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.bounds
                                                          collectionViewLayout:flowLayout];
    collectionView.delegate = self;
    collectionView.dataSource = self;
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.alwaysBounceHorizontal = YES;
    collectionView.showsHorizontalScrollIndicator = NO;
    [self addSubview:collectionView];
    
    collectionView.translatesAutoresizingMaskIntoConstraints = YES;
    collectionView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    
    _collectionView = collectionView;
    
    [_collectionView registerNib:[UINib nibWithNibName:@"YoGroupMememberDisplayCell" bundle:nil]
      forCellWithReuseIdentifier:GroupMemberDisplayCollectionViewCellReuseID];
}

#pragma mark - Lazy  Loading

- (NSOrderedSet *)groupMembers {
    if (!_groupMembers) {
        _groupMembers = [NSOrderedSet new];
    }
    return _groupMembers;
}

#pragma mark - Public Utility

- (void)addMember:(YoContact *)member {
    NSInteger indexOfMember = [self.groupMembers indexOfObject:member];
    if (indexOfMember == NSNotFound) {
        NSMutableOrderedSet *mutableMembers = [self.groupMembers mutableCopy];
        [mutableMembers addObject:member];
        self.groupMembers = [mutableMembers copy];
        
        NSIndexPath *newItemIndexPath = [NSIndexPath indexPathForRow:(self.groupMembers.count - 1) inSection:0];
        [self.collectionView insertItemsAtIndexPaths:@[newItemIndexPath]];
        [self.collectionView scrollToItemAtIndexPath:newItemIndexPath
                                    atScrollPosition:UICollectionViewScrollPositionLeft
                                            animated:YES];
    }
    else {
        NSIndexPath *itemIndexPath = [NSIndexPath indexPathForItem:indexOfMember inSection:0];
        [self.collectionView scrollToItemAtIndexPath:itemIndexPath
                                    atScrollPosition:UICollectionViewScrollPositionLeft
                                            animated:YES];
    }
}

- (void)removeMember:(YoContact *)member {
    NSInteger index = [self.groupMembers indexOfObject:member];
    if (index != NSNotFound) {
        NSMutableArray *mutableMembers = [self.groupMembers mutableCopy];
        [mutableMembers removeObjectAtIndex:index];
        _groupMembers = [mutableMembers copy];
        [self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    return self.groupMembers.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    YoGroupMememberDisplayCell *groupMemberCell = [collectionView dequeueReusableCellWithReuseIdentifier:GroupMemberDisplayCollectionViewCellReuseID
                                                                                                          forIndexPath:indexPath];
    [groupMemberCell displayContact:[self.groupMembers objectAtIndex:indexPath.row]];
    groupMemberCell.backgroundColor = [[YoThemeManager sharedInstance] colorForRow:indexPath.row];
    return groupMemberCell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.delegate) {
        [self.delegate yoGroupMemberDisplayView:self
                                didSelectMember:[self.groupMembers objectAtIndex:indexPath.row]];
    }
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = self.height;
    CGFloat aspectRatio = 1.0f/1.0f;
    CGFloat width = height * aspectRatio;
    CGSize size = CGSizeMake(width, height);
    return size;
}

@end
