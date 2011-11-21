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

#import <Foundation/Foundation.h>


typedef enum {
    PaperclipImageTypeJpeg,
    PaperclipImageTypePng
} PaperclipImageType;


/*
 * Utilities to help upload an image to an attached image file managed
 * by the Paperclip gem on a Rails server.
 *
 * See https://github.com/thoughtbot/paperclip for details on the Paperclip gem.
 */
@interface PaperclipImageUploader : NSObject

/*
 * Creates an NSMutableURLRequest suitable for uploading the given image
 * as the body of an HTTP POST to the given url.  Returns the autoreleased request
 * upon success which you can then send to the server using NSURLConnection or other means.
 * Returns nil for failure.
 *
 * NOTE: This method does NOT actually upload the image, it just creates the complex
 *       multipart/form-data request needed to do so.  You upload the image yourself
 *       using NSURLConnection methods or some other means.
 *
 * The image can be uploaded as either a JPEG or as a PNG, depending on how you'd like
 * the server to receive the image and which format best supports your particular image.
 *
 * The imageQuality value must be in [0.0, 1.0] and is used only for jpeg and ignored for png.
 * If the imageQuality value is outside [0.0, 1.0] for a jpeg, then 1.0 is used.
 *
 * The image will be uploaded using Ruby on Rails naming conventions.  In other words, if you
 * have a Rails model:
 *
 *   class User < ActiveRecord::Base
 *     has_attached_file :avatar
 *   end
 *
 * then you would pass forAttachedAttributeName:@"avatar" onModelName:@"user".  This will ensure
 * that the image data will be uploaded as the value of a form control named "user[avatar]"
 * just as Rails expects and just as if the image had been uploaded from an HTML form in a browser
 * rendered like:
 *
 *   <%= form_for :user, @user, :url => user_path, :html => { :multipart => true } do |form| %>
 *     <%= form.file_field :avatar %>
 *   <% end %>
 *
 * Since images are usually uploaded in the context of a larger form that submits other fields
 * on the image's model, such other attributes can be specified in the otherAttributes dictionary.
 * For example, if the user form was really:
 *
 *   <%= form_for :user, @user, :url => user_path, :html => { :multipart => true } do |form| %>
 *     <%= form.file_field :avatar %>
 *     <%= form.text_field :name %>
 *     <%= form.text_field :profession %>
 *   <% end %>
 *
 * then you could pass otherAttributes as a dictionary { @"name" => @"Joel", @"profession" => @"Dev" }
 * and it would be submitted as a control named "user[name]" with value "Joel" and a control named
 * "user[profession]" with value "Dev".
 *
 * PUT: The http method on the returned request is POST.  If you instead need a PUT (e.g. for an update
 *      instead of a create) you can modify the method using [request setHTTPMethod:@"PUT"].
 *
 * THREAD-SAFETY: This method is thread-safe.
 *
 * See http://www.w3.org/TR/html4/interact/forms.html#h-17.13.4.2 for more details.
 */
+ (NSMutableURLRequest*)uploadRequestForImage:(UIImage*)image
                           ofImageContentType:(PaperclipImageType)imageContentType
                             withImageQuality:(CGFloat)imageQuality
                    forAttachedAttributeNamed:(NSString*)attachedAttributeName
                                 onModelNamed:(NSString*)modelName
                          withOtherAttributes:(NSDictionary*)otherAttributes
                                        toUrl:(NSURL*)url;

@end
