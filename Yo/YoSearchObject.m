//
//  YoSearchDelegate.m
//  Yo
//
//  Created by Peter Reveles on 11/26/14.
//
//

#import "YoSearchObject.h"

typedef NS_ENUM(NSUInteger, YoDataSourceNotification) {
    YoDataSourceNotification_dataUpdate,
};

@interface YoSearchObject ()
@property (nonatomic, strong) NSArray *filteredData;
@property (nonatomic, strong) NSArray *originalData;
@end

@implementation YoSearchObject

#pragma mark - Lazy Loading

- (NSArray *)filteredData{
    if (!_filteredData){
        _filteredData = [NSArray new];
    }
    return _filteredData;
}

- (NSArray *)originalData{
    if (!_originalData){
        _originalData = [NSArray new];
    }
    return _originalData;
}

#pragma mark - Life

- (instancetype)initWithData:(NSArray *)data{
    self = [super init];
    if (self) {
        _originalData = data;
        _filteredData = data;
    }
    return self;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        _originalData = nil;
        _filteredData = nil;
    }
    return self;
}

- (void)setData:(NSArray *)data{
    _originalData = data;
    _filteredData = data;
}

- (void)clearFilteredData{
    _filteredData = self.originalData;
}

#pragma mark - Search

-(void)filterDataForSearchText:(NSString*)searchText {
    // Update the filtered array based on the search text and scope.
    // Remove all objects from the filtered search array
    
    if (![self.propertyToFilterBy length]) {
        DDLogWarn(@"propertyToFilterBy not set for datasource");
        return; // cant filter if this isnt set
    }
    
    if (![searchText length]) {
        self.filteredData = self.originalData;
        [self updateDelegateWithNotification:YoDataSourceNotification_dataUpdate];
        return;
    }
    
    NSMutableArray *filteredData = [[NSMutableArray alloc] initWithCapacity:[self.originalData count]];
    
    // Filter the array using NSPredicate
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.%@ BEGINSWITH[c] %@", self.propertyToFilterBy ,searchText];
    filteredData = [NSMutableArray arrayWithArray:[self.originalData filteredArrayUsingPredicate:predicate]];
    self.filteredData = filteredData;
    [self updateDelegateWithNotification:YoDataSourceNotification_dataUpdate];
}

#pragma mark - Delegate

- (void)updateDelegateWithNotification:(YoDataSourceNotification)note{
    if (!self.delegate) return;
    
    switch (note) {
        case YoDataSourceNotification_dataUpdate:
            if ([self.delegate respondsToSelector:@selector(dataWasUpdated)])
                [self.delegate dataWasUpdated];
            break;
            
        default:
            break;
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    [searchBar resignFirstResponder];
    searchBar.text = @"";
    [self searchBar:searchBar textDidChange:@""];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    [searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    [self filterDataForSearchText:searchText];
}

@end
