/*
 Copyright (c) 2011, Joel Shapiro
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 * Neither the name of the author nor the names of its contributors may be
 used to endorse or promote products derived from this software without
 specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PaperclipImageUploader.h"

#pragma mark Constants

NSString* const kDefaultBoundary = @"AaB03x";
const NSUInteger kDefaultBodySize = 100 * 1024;


@implementation PaperclipImageUploader

#pragma mark Private Utilities

+ (void)appendBoundary:(NSString*)boundary toRequestBody:(NSMutableData*)requestBody
{
    [requestBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSASCIIStringEncoding]];
}

+ (void)appendPartHeader:(NSString*)partHeaderName withValue:(NSString*)partHeaderValue toRequestBody:(NSMutableData*)requestBody
{
    [requestBody appendData:[[NSString stringWithFormat:@"%@: %@\r\n", partHeaderName, partHeaderValue] dataUsingEncoding:NSASCIIStringEncoding]];
}

+ (void)appendCrlfToRequestBody:(NSMutableData*)requestBody
{
    [requestBody appendData:[@"\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
}


#pragma mark Public Utilities

+ (NSMutableURLRequest*)uploadRequestForImage:(UIImage*)image
                           ofImageContentType:(PaperclipImageType)imageContentType
                             withImageQuality:(CGFloat)imageQuality
                    forAttachedAttributeNamed:(NSString*)attachedAttributeName
                                 onModelNamed:(NSString*)modelName
                          withOtherAttributes:(NSDictionary*)otherAttributes
                                        toUrl:(NSURL*)url
{
    if (!image || !attachedAttributeName || !modelName || !url) {
        return nil;
    }

    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", kDefaultBoundary] forHTTPHeaderField:@"Content-Type"];

    // Determine the Content-Type/mime type of the image and the associated filename and data
    NSString* imageMimeType;
    NSString* imageFilename;
    NSData*   imageData;
    switch (imageContentType) {
        case PaperclipImageTypeJpeg:
            imageMimeType = @"image/jpeg";
            imageFilename = @"upload.jpg";
            imageData     = UIImageJPEGRepresentation(image, imageQuality < 0.0f || imageQuality > 1.0f ? 1.0f : imageQuality);
            break;
        case PaperclipImageTypePng:
            imageMimeType = @"image/png";
            imageFilename = @"image.png";
            imageData     = UIImagePNGRepresentation(image);
            break;
        default:
            return nil;
    }

    // Build up the request body
    NSMutableData* requestBody = [NSMutableData dataWithCapacity:kDefaultBodySize];

    // Append other attributes, if any
    for (NSString* attributeName in otherAttributes) {
        [self appendBoundary:kDefaultBoundary toRequestBody:requestBody];
        [self appendPartHeader:@"Content-Disposition"
                     withValue:[NSString stringWithFormat:@"form-data; name=\"%@[%@]\"", modelName, attributeName]
                 toRequestBody:requestBody];
        [self appendCrlfToRequestBody:requestBody];
        [requestBody appendData:[[[otherAttributes objectForKey:attributeName] description] dataUsingEncoding:NSASCIIStringEncoding]];
        [self appendCrlfToRequestBody:requestBody];
    }

    // Append the actual image
    [self appendBoundary:kDefaultBoundary toRequestBody:requestBody];
    [self appendPartHeader:@"Content-Disposition"
                 withValue:[NSString stringWithFormat:@"form-data; name=\"%@[%@]\"; filename=\"%@\"", modelName, attachedAttributeName, imageFilename]
             toRequestBody:requestBody];
    [self appendPartHeader:@"Content-Type" withValue:imageMimeType toRequestBody:requestBody];
    [self appendPartHeader:@"Content-Transfer-Encoding" withValue:@"binary" toRequestBody:requestBody];
    [self appendCrlfToRequestBody:requestBody];
    [requestBody appendData:imageData];
    [self appendCrlfToRequestBody:requestBody];

    // Append the final boundary to denote end-of-body
    [requestBody appendData:[[NSString stringWithFormat:@"--%@--", kDefaultBoundary] dataUsingEncoding:NSASCIIStringEncoding]];

    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:requestBody];

    return request;
}

@end
