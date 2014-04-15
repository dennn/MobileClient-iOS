//
//  DENMediaManager.m
//  Client
//
//  Created by Denis Ogun on 14/04/2014.
//  Copyright (c) 2014 Mulan. All rights reserved.
//

#import "DENMediaManager.h"
#import "DENClient.h"

typedef NS_ENUM(NSInteger, Media_Type) {
    IMAGE = 0,
    AUDIO = 1
};

@interface DENMediaItem : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) NSInteger size;
@property (nonatomic, assign) Media_Type type;

@end

@implementation DENMediaItem

@end

@interface DENMediaManager ()

@property (nonatomic, strong) DENClient *client;
@property (nonatomic, strong) NSMutableDictionary *files;
@property (nonatomic, strong) NSMutableArray *filesToDownload;
@property (nonatomic, strong) DENMediaItem *currentDownloadedItem;

@end

@implementation DENMediaManager

- (instancetype)init
{
    if (self = [super init]) {
        _client = [DENClient sharedManager];
        _files = [NSMutableDictionary new];
        _filesToDownload = [NSMutableArray new];
    }
    return self;
}

- (void)processMediaData:(NSArray *)media
{
    
    for (NSDictionary *mediaItem in media) {
        NSString *itemName = mediaItem[@"Name"];
        NSNumber *itemSize = mediaItem[@"Size"];
        NSNumber *itemType = mediaItem[@"Type"];

        DENMediaItem *newItem = [DENMediaItem new];
        newItem.name = itemName;
        newItem.size = [itemSize integerValue];
        newItem.type = (Media_Type)[itemType integerValue];
        
        self.files[itemName] = newItem;
        
        if ([DENMediaManager mediaFileExists:itemName] == NO) {
            [self.filesToDownload addObject:newItem];
        }
    }
    
    [self startDownloadingItems];
}

- (void)startDownloadingItems
{
    if ([self.filesToDownload count] == 0) {
        [self.client completedDownloadingMedia];
    } else {
        [self downloadNextItem:self.filesToDownload[0]];
    }
}

- (void)downloadedFile:(NSData *)data
{
    [DENMediaManager writeData:data withFileName:self.currentDownloadedItem.name];
    
    [self startDownloadingItems];
}

- (void)downloadNextItem:(DENMediaItem *)item
{
    self.currentDownloadedItem = item;
    [self.filesToDownload removeObjectAtIndex:0];
    [self.client startDownloadingFile:self.currentDownloadedItem.name];
}

#pragma mark - File Downloading

// Utilities

+ (NSString *)getFilePathForFile:(NSString *)fileName
{
    NSString *path = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support"] stringByAppendingPathComponent:fileName];
    
    return path;
}

+ (BOOL)mediaFileExists:(NSString *)fileName
{
    
    NSString *filePath = [DENMediaManager getFilePathForFile:fileName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return YES;
    }
    
    return NO;
}

// Saving

+ (void)writeData:(NSData *)file withFileName:(NSString *)fileName
{
    
    // If the media file already exists don't bother writing again
    if ([DENMediaManager mediaFileExists:fileName]) {
        return;
    }
    
    NSString *filePath = [DENMediaManager getFilePathForFile:fileName];
    
    // Save in PNG format as JPEG is lossy
    [file writeToFile:filePath atomically:YES];
    
    // Make sure we don't back this up to iCloud
    NSError *error = nil;
    [[NSURL URLWithString:filePath] setResourceValue:[NSNumber numberWithBool:YES]
                                  forKey:NSURLIsExcludedFromBackupKey error:&error];
    if(error){
        NSLog(@"Error excluding %@ from backup %@", filePath, error);
    }
}

// Getting

+ (UIImage *)getImageWithFileName:(NSString *)fileName
{
    
    NSString *filePath = [DENMediaManager getFilePathForFile:fileName];

    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return [UIImage imageWithContentsOfFile:filePath];
    }
    
    return NULL;
}

+ (NSData *)getAudioFileWithFileName:(NSString *)fileName
{
    NSString *filePath = [DENMediaManager getFilePathForFile:fileName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return [NSData dataWithContentsOfFile:filePath];
    }
    
    return NULL;
}

@end
