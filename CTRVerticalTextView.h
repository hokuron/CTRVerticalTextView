//
// Copyright (c) 2012 Takuma Shimizu
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

#define DEVICE_OS_MAJOR_VERSION [[[[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."] objectAtIndex:0] intValue]

#define BELOW_IOS_5_REVERSE_SIZE_WIDTH(SIZE)  ({ DEVICE_OS_MAJOR_VERSION <= 5 ? SIZE.height : SIZE.width; })

#define BELOW_IOS_5_REVERSE_SIZE_HEIGHT(SIZE) ({ DEVICE_OS_MAJOR_VERSION <= 5 ? SIZE.width : SIZE.height; })

@interface CTRVerticalTextView : UIView {
	CGFloat _titleSizeRate;     // e.g. self.titleText = self.text * _titleSizeRate;
	CGFloat _titleForTextSpace; // Space between titleText and text.
}

// Required
@property (copy, nonatomic)   NSString *text; // Setting is no range (location and length are 0).
@property (strong, nonatomic) NSString *titleText;

// Optional
@property (assign, nonatomic) CGFloat fontSize;    // default value is 16.0f
@property (assign, nonatomic) CGFloat lineSpace;   // default value is 5.0f
@property (assign, nonatomic) CGFloat letterSpace; // default value is 3.0f

// TODO: 定数を用意する
@property (strong, nonatomic) NSString *fontName;  // default value is HiraMinProN-W3
- (void)toggleFontName; // HiraKakuProN-W3, HiraMinProN-W3

- (NSRange)visibleRangeWithString:(NSString *)aString andFont:(UIFont *)aFont; // Returns the range of characters that actually fit in the rectangle.
- (NSRange)visibleRangeWithString:(NSString *)text; // Call -visibleRangeWithString:andFont: based on font properties.
- (NSRange)visibleRangeWithNormalText:(NSString *)text andTitleText:(NSString *)title; // Call -visibleRangeWithString:andFont: twice.
- (NSArray *)clusterVisibleRangesWithString:(NSString *)text startRange:(NSRange)startRange; // Recursive version of -visibleRangeWithString:andFont: method.

- (CGSize)linesSizeWithString:(NSString *)aString andFont:(UIFont *)aFont;
- (CGSize)linesSizeWithTextString:(NSString *)text; // Calling -lineSizeWithString:andFont: based on font properties.
- (CGSize)titleLinesSizeWithTitleTextString:(NSString *)titleText; // Calling -lineSizeWithString:andFont: based on adjusted font properties.

@end
