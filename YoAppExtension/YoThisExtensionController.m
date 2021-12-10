//
//  YoShareSheet.m
//  YoAppExtension
//
//  Created by Peter Reveles on 11/15/14.
//
//

#import "YoThisExtensionController.h"
#import "YOHeaderFooterCell.h"
#import "YoImgUploadClient.h"
#import "YOCell.h"

@interface YoThisExtensionController () <YoSendDelegate>
@property (nonatomic, strong) NSMutableArray *URLWaitingList; // of YoModelObjects
@property (nonatomic, strong) NSMutableDictionary *indexPathForUsername;
@property (nonatomic, strong) YOCell *yoAllCell;
@property (nonatomic, assign) BOOL initailUploadFailed;
@end

@implementation YoThisExtensionController

- (NSMutableArray *)URLWaitingList{
    if (!_URLWaitingList) {
        _URLWaitingList = [NSMutableArray new];
    }
    return _URLWaitingList;
}

- (NSMutableDictionary *)indexPathForUsername{
    if (!_indexPathForUsername) {
        _indexPathForUsername = [NSMutableDictionary new];
    }
    return _indexPathForUsername;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    _yoAllCell = nil;
    
    self.delegate = self;
    [self performPrepWork];
}
- (void)performPrepWork{
    NSExtensionItem *item = self.extensionContext.inputItems.firstObject;
    NSItemProvider *itemProvider = item.attachments.firstObject;
    ////// check for URL ///////
    if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeURL]) {
        [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeURL options:nil completionHandler:^(NSURL *url, NSError *error) {
            self.shareType = YoShareType_URL;
            self.urlToShare = url.absoluteString;
        }];
    }
    ///// check for Image ///////
    if([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeImage]){
        [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeImage options:nil completionHandler:^(UIImage *image, NSError *error) {
            if(image) {
                [self uploadImage:image];
            }
        }];
    }
}

- (void)uploadImage:(UIImage *)image{
    self.shareType = YoShareType_IMG;
    [[YoImgUploadClient sharedClient] uploadOptimizedToS3WithImage:image
                                                   completionBlock:^(NSString *imageURL, NSError *error)
    {
        if (imageURL)
            [self readyToYoWithImgURL:imageURL];
        else
            self.initailUploadFailed = YES;
    }];
}

- (void)readyToYoWithImgURL:(NSString *)imgURL{
    self.urlToShare = imgURL;
    __weak YoThisExtensionController *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [weakSelf clearBackList];
    });
}

- (void)setInitailUploadFailed:(BOOL)initailUploadFailed{
    if (initailUploadFailed && [self.URLWaitingList count]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self clearWaitingListAndClose];
        });
    }
    _initailUploadFailed = initailUploadFailed;
}

- (void)clearWaitingListAndClose{
    // clear loading
    if ([self.URLWaitingList count]) {
        for (YoModelObject *object in self.URLWaitingList) {
            YOCell *cell = (YOCell *)[self.tableView cellForRowAtIndexPath:self.indexPathForUsername[object.username]];
            if (cell) {
                [cell endActivityIndicator];
                [cell.label setText:object.displayName];
            }
        }
    }
    // present alert
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Failed to Upload", nil)
                                                                   message:NSLocalizedString(@"Please check your internet connection and try again soon", nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Close", nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              [self close];
                                                          }];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)noImgURLFor:(YoModelObject *)object cellAtIndexPath:(NSIndexPath *)indexPath {
    [self.URLWaitingList addObject:object];
    self.indexPathForUsername[object.username] = indexPath;
    
    if (self.initailUploadFailed) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self clearWaitingListAndClose];
        });
    }
}

- (void)noImgURLForYoAllCell:(YOCell *)cell{
    self.yoAllCell = cell;
}

- (NSArray *)indexPathsInWaiting{
    return [self.URLWaitingList copy];
}

- (void)clearBackList{
    if (![self.urlToShare length]) return;
    
    if (self.yoAllCell) {
        [self yoAllWithYoAllStatusCell:self.yoAllCell];
    }
    
    for (YoModelObject *object in self.URLWaitingList) {
        [self sendYoTo:object withIndexPath:self.indexPathForUsername[object.username]];
    }
    
    [self.URLWaitingList removeAllObjects];
}

@end
