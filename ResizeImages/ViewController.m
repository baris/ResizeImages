//
//  ViewController.m
//  ResizeImages
//
//  Created by Baris Metin on 2/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import "ImageBrowserItem.h"
#import "NSImage+Extras.h"

@interface ViewController () 
@property (weak) IBOutlet IKImageBrowserView *imageBrowser;
@property (nonatomic,strong) NSMutableArray* browserData;
@property (weak) IBOutlet NSTextField *sizeTextField;

+ (void)addImageFromPath:(NSString*)path toArray:(NSMutableArray*)array;
+ (void)resizeImageUsingImageBrowserItem:(ImageBrowserItem*)item toLongestSide:(CGFloat)longestSide;

@end

@implementation ViewController
@synthesize imageBrowser = _imageBrowser;
@synthesize browserData = _browserData;
@synthesize sizeTextField;

- (IBAction)resizePressed:(NSButton *)sender {
    __block NSMutableArray *__browserData = self.browserData;
    __block IKImageBrowserView *__imageBrowser = self.imageBrowser;
    CGFloat longestSideLength = [self.sizeTextField floatValue];
    
    dispatch_queue_t resizeQueue = dispatch_queue_create("Resize Image Queue", NULL);
    dispatch_async(resizeQueue, ^(void) {
        for (ImageBrowserItem* item in __browserData) {
            [ViewController resizeImageUsingImageBrowserItem:item toLongestSide:longestSideLength];
            
        }
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [__browserData removeAllObjects];
            [__imageBrowser reloadData];
        });

    });
    dispatch_release(resizeQueue);
}

- (NSMutableArray*)browserData
{
    if (!_browserData) _browserData = [[NSMutableArray alloc] init];
    return _browserData;
}

- (NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *)aBrowser
{
    return [self.browserData count];
}

- (id)imageBrowser:(IKImageBrowserView *)aBrowser itemAtIndex:(NSUInteger)index
{
    return [self.browserData objectAtIndex:index];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    if ([sender draggingSource] != self) {
        return NSDragOperationEvery;
    }
    return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    return NSDragOperationEvery;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    __block BOOL ret = YES;
    __block NSMutableArray *__browserData = self.browserData;
    __block IKImageBrowserView *__imageBrowser = self.imageBrowser;
    NSArray* files = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
    
    dispatch_queue_t addImageQueue = dispatch_queue_create("Add Image Queue", NULL);
    dispatch_async(addImageQueue, ^(void){
        for (id file in files) {
            [ViewController addImageFromPath:file toArray:__browserData];
        };
        dispatch_sync(dispatch_get_main_queue(), ^(void){
            if ([__browserData count] > 0) {
                ret = YES;
            }
            [__imageBrowser reloadData];
        });
    });
    dispatch_release(addImageQueue);
    
    return ret;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
    [self.imageBrowser reloadData];
}

+ (void)addImageFromPath:(NSString*)path toArray:(NSMutableArray*)array
{
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL];
    // add files in the directory recursively
    if ([attrs valueForKey:NSFileType] == NSFileTypeDirectory) {
        NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
        for (NSString* content in contents) {
            NSString *contentPath = [path stringByAppendingPathComponent:content];
            [self addImageFromPath:contentPath toArray:array];
        }
        return;
    }
    
    // Allow certain file extensions
    BOOL knownFileType = NO;
    for (NSString* ext in [NSArray arrayWithObjects:@"jpeg", @"jpg", @"png", @"gif", @"bmp", nil]) {
        if ([[path pathExtension] caseInsensitiveCompare:ext] == NSOrderedSame) {
            knownFileType = YES;
            break;
        }
    }
    if (!knownFileType) {
        return;
    }
    NSImage* image = [NSImage thumbnailFromPath:path];
    NSString* imageID = [path lastPathComponent];
    ImageBrowserItem* browserItem = [[ImageBrowserItem alloc] init];
    browserItem.image = image;
    browserItem.imageUID = imageID;
    browserItem.path = path;
    [array addObject:browserItem];    
}

+ (void)resizeImageUsingImageBrowserItem:(ImageBrowserItem *)item toLongestSide:(CGFloat)longestSide
{
    NSBitmapImageRep* imageRep = [NSBitmapImageRep imageRepWithContentsOfFile:item.path];
    // Issues with some PNG files: https://discussions.apple.com/thread/1976694?start=0&tstart=0
    if (!imageRep) return;
    
    NSSize size = [imageRep size];
    CGFloat w,h;
    if (size.width > size.height) {
        w = longestSide;
        h = (w * size.height) / size.width;
    } else {
        h = longestSide;
        w = (h * size.width) / size.height;
    }
    
    NSImage* resized = [[NSImage alloc] initWithSize:NSMakeSize(w, h)];
    [resized lockFocus];
    [imageRep drawInRect:NSMakeRect(0, 0, w, h)];
    [resized unlockFocus];
    
    NSBitmapImageRep* resizedRep = [NSBitmapImageRep imageRepWithData:[resized TIFFRepresentation]];
    NSData *data = [resizedRep representationUsingType:NSJPEGFileType properties:nil];
    [data writeToFile:item.path atomically:YES];    
}

@end
