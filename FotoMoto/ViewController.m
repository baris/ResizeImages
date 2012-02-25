//
//  ViewController.m
//  FotoMoto
//
//  Created by Baris Metin on 2/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import "ImageBrowserItem.h"

@interface ViewController () 

@end

@implementation ViewController
@synthesize imageBrowser = _imageBrowser;
@synthesize browserData = _browserData;

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

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSArray* files = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
    for (id file in files) {
        NSImage* image = [[NSWorkspace sharedWorkspace] iconForFile:file];
        NSString* imageID = [file lastPathComponent];
        NSLog(@"%@", imageID);
        ImageBrowserItem* browserItem = [[ImageBrowserItem alloc] init];
        browserItem.image = image;
        browserItem.imageUID = imageID;
        [self.browserData addObject:browserItem];
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

@end
