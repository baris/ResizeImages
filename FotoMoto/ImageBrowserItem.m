//
//  ImageBrowserItem.m
//  FotoMoto
//
//  Created by Baris Metin on 2/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ImageBrowserItem.h"

// Comforms to IKImageBrowserItem informal protocol
@implementation ImageBrowserItem

@synthesize image = _image;
@synthesize imageUID = _imageUID;

- (NSString*)imageUID
{
    if (!_imageUID) return @"imageUIDNotSet";
    return _imageUID;
}

- (NSString*)imageRepresentationType
{
    return IKImageBrowserNSImageRepresentationType;
}

- (id)imageRepresentation
{
    return self.image;
}

@end
