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
@property (nonatomic, assign) NSUInteger size;
@property (nonatomic, assign) Media_Type type;

@end

@implementation DENMediaItem

@end

@interface DENMediaManager ()

@property (nonatomic, strong) NSMutableDictionary *files;
@property (nonatomic, strong) NSMutableArray *filesToDownload;
@property (nonatomic, strong) DENMediaItem *currentDownloadedItem;

@end

@implementation DENMediaManager

- (instancetype)init
{
    if (self = [super init]) {
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
        newItem.size = [itemSize unsignedIntegerValue];
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
    
    [self.filesToDownload removeObjectAtIndex:0];
    [self startDownloadingItems];
}

- (void)downloadNextItem:(DENMediaItem *)item
{
    self.currentDownloadedItem = item;
    [self.client startDownloadingFile:self.currentDownloadedItem.name withSize:self.currentDownloadedItem.size];
}

#pragma mark - File Downloading

// Utilities

+ (NSString *)getFilePathForFile:(NSString *)fileName
{
    NSString *appSupportDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
    //If there isn't an App Support Directory yet ...
    if (![[NSFileManager defaultManager] fileExistsAtPath:appSupportDir isDirectory:NULL]) {
        NSError *error = nil;
        //Create one
        if (![[NSFileManager defaultManager] createDirectoryAtPath:appSupportDir withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"%@", error.localizedDescription);
        }
        else {
            // *** OPTIONAL *** Mark the directory as excluded from iCloud backups
            NSURL *url = [NSURL fileURLWithPath:appSupportDir];
            if (![url setResourceValue:@YES
                                forKey:NSURLIsExcludedFromBackupKey
                                 error:&error])
            {
                NSLog(@"Error excluding %@ from backup %@", [url lastPathComponent], error.localizedDescription);
            }
        }
    }
    
    
    NSString *path = [appSupportDir stringByAppendingPathComponent:fileName];
    
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
    
    [file writeToFile:filePath atomically:YES];
    
    NSLog(@"Saving file to %@", filePath);
    
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

+ (NSURL *)getAudioFileWithFileName:(NSString *)fileName
{
    NSString *filePath = [DENMediaManager getFilePathForFile:fileName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return [NSURL URLWithString:filePath];

    }
    
    return NULL;
}

@end
