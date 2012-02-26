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

- (void)addImageFromPath:(NSString*)path toArray:(NSMutableArray*)array;

@end

@implementation ViewController
@synthesize imageBrowser = _imageBrowser;
@synthesize browserData = _browserData;
@synthesize sizeTextField;

- (IBAction)resizePressed:(NSButton *)sender {
    for (ImageBrowserItem* item in self.browserData) {
        NSBitmapImageRep* imageRep = [NSBitmapImageRep imageRepWithContentsOfFile:item.path];
        
        NSSize size = [imageRep size];
        CGFloat w,h;
        if (size.width > size.height) {
            w = [self.sizeTextField floatValue];
            h = (w * size.height) / size.width;
        } else {
            h = [self.sizeTextField floatValue];
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
    [self.browserData removeAllObjects];
    [self.imageBrowser reloadData];
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
    NSArray* files = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
    for (id file in files) {
        [self addImageFromPath:file toArray:self.browserData];
    }
    if ([self.browserData count] > 0) {
        return YES;
    }
    return NO;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
    [self.imageBrowser reloadData];
}

- (void)addImageFromPath:(NSString*)path toArray:(NSMutableArray*)array
{
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL];
    if ([attrs valueForKey:NSFileType] == NSFileTypeDirectory) {
        // add files in the directory recursively
        NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
        for (NSString* content in contents) {
            NSString *contentPath = [path stringByAppendingPathComponent:content];
            [self addImageFromPath:contentPath toArray:array];
        }
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

@end
