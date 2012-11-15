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

/*NSLogの代わり*/
#ifdef DEBUG
#define DEBUGLOG(...) NSLog(__VA_ARGS__)
#else
#define DEBUGLOG(...) ;
#endif

/*改行*/
#ifdef DEBUG
#define BREAK() NSLog(@"\n")
#else
#define BREAK()
#endif

#import "CTRVerticalTextView.h"

@interface CTRVerticalTextView ()

@end

@implementation CTRVerticalTextView

- (id)init
{
	self = [super init];
	if (self) [self initLayout];
	return self;
}

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) [self initLayout];
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self) [self initLayout];
	return self;
}

- (void)initLayout
{
	_text              = @"";
	_titleText         = @"";
	_titleSizeRate     = 1.5f;
	_titleForTextSpace = 0;
	_fontSize          = 18.0f;
	_lineSpace         = 12.0f;
	_letterSpace       = 3.0f;
	_fontName          = @"HiraMinProN-W3";

}

//////////////////////////////////////////////////////////////
#pragma mark - Setter
//////////////////////////////////////////////////////////////

- (void)setFontSize:(CGFloat)fontSize
{
	if (fontSize < 1.0f) {
		fontSize = 16.0f;
	}
	_fontSize = fontSize;
	
	[self setNeedsDisplay];
}

- (void)setLineSpace:(CGFloat)lineSpace
{
	if (lineSpace < 1.0f) {
		lineSpace = 5.0f;
	}
	_lineSpace = lineSpace;

	[self setNeedsDisplay];
}

- (void)setLetterSpace:(CGFloat)letterSpace
{
	if (letterSpace < 1.0f) {
		letterSpace = 3.0f;
	}
	_letterSpace = letterSpace;
	
	[self setNeedsDisplay];
}

- (void)setFontName:(NSString *)fontName
{
	if ([_fontName length] < 1) {
		fontName = @"HiraMinProN-W3";
	}
	_fontName = fontName;
	
	[self setNeedsDisplay];
}

//////////////////////////////////////////////////////////////
#pragma mark - CoreText
//////////////////////////////////////////////////////////////

- (void)drawRect:(CGRect)rect
{
	FUNC();
	DEBUGLOG(@"%@",NSStringFromCGRect(rect));
	
//	if ([self.text length] < 1) return;
	
	// CFAttributedString -> CTFramesetter + CGPath -> CTFrame
	// 上記の順でCoreTextを作成
	
	NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] init];

	// 部・章などのタイトルがあれば書く
	if ([self.titleText length] > 0) {
		_titleForTextSpace = 30.0f;
		CGFloat fontSize = [self.text length] < 1 ? 27.0f : self.fontSize * _titleSizeRate; // 書籍タイトルのみの表示時はサイズを固定する
		CTFontRef titleFont = CTFontCreateWithName((__bridge CFStringRef)self.fontName, fontSize, NULL);
		NSMutableDictionary *titleAttrDict = [self getAttributedStringSourceWithString:(CFStringRef)self.titleText andFont:titleFont];
		NSMutableAttributedString *titleAttrString = [[NSMutableAttributedString alloc] initWithString:self.titleText attributes:titleAttrDict];
		[attrString appendAttributedString:titleAttrString];
		_titleForTextSpace = 0;
	}
	
	// 本文の内容部分の属性文字列を加える
	if ([self.text length] > 0) {
		CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)self.fontName, self.fontSize, NULL);
		NSMutableDictionary *textAttrDict = [self getAttributedStringSourceWithString:(CFStringRef)self.text andFont:font];
		NSMutableAttributedString *textAttrString  = [[NSMutableAttributedString alloc] initWithString:self.text attributes:textAttrDict];
		[attrString appendAttributedString:textAttrString];
		CFRelease(font);
	}
		
	CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attrString);
	
	CGMutablePathRef path = CGPathCreateMutable();
	CGSize pathSize = rect.size;
	
	// 縦書きにするため幅と高さが逆転する。逆転するだけだと枠外にいってしまうので、幅と高さの差で引き戻す。(iOS 5)
	// また、原点が左下に変わっている(縦書き準備 3/3のScaleが影響)。このことを頭に入れて↓
	
	// iOS5では幅と高さが逆転するため、それらを入れ替えた際に生じる差を埋める必要があるが、iOS6では逆転が起こらないので不必要
	CGFloat reversingDiff = DEVICE_OS_MAJOR_VERSION <= 5 ? pathSize.height - pathSize.width : 0;
		
	// 幅を高さの値に=>右側へ行きすぎる=>減算 (iOS 5)
	// 高さを幅の値に=>下方へ行きすぎる=>加算 (iOS 5)
	CGPathAddRect(path, NULL, CGRectMake(-reversingDiff, reversingDiff, BELOW_IOS_5_REVERSE_SIZE_WIDTH(pathSize), BELOW_IOS_5_REVERSE_SIZE_HEIGHT(pathSize)));
//	DEBUGLOG(@"path: %@",NSStringFromCGRect(CGPathGetBoundingBox(path)));
	
	CFRange fitRange = CFRangeMake(0, 0);
	/*CGSize debug_size = */
	CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), NULL, CGSizeMake(BELOW_IOS_5_REVERSE_SIZE_WIDTH(pathSize), BELOW_IOS_5_REVERSE_SIZE_HEIGHT(pathSize)), &fitRange);
//	DEBUGLOG(@"frame: %@",NSStringFromCGSize(debug_size));
	
	NSDictionary *frameDict = @{ (id)kCTFrameProgressionAttributeName : @(kCTFrameProgressionRightToLeft) }; // 縦書き準備 2/3
	
	CTFrameRef frame = CTFramesetterCreateFrame(framesetter, fitRange, path, (__bridge CFDictionaryRef)frameDict);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSaveGState(context);
	
	// 縦書き準備 3/3 鏡状態になっているので反転
	CGContextSetTextMatrix(context, CGAffineTransformIdentity);
	CGContextTranslateCTM(context, 0, pathSize.height);
	CGContextScaleCTM(context, 1.0f, -1.0f);
	
	CTFrameDraw(frame, context); // contextに対してCoreTextテキストを書き込む
	
	// デバッグ
//	CFArrayRef lines = CTFrameGetLines(frame);
//	for (int i=0; i < CFArrayGetCount(lines); i++) {
//		CTLineRef line = CFArrayGetValueAtIndex(lines, i);
//		CGRect lineBounds = CTLineGetImageBounds(line, context);
//		DEBUGLOG(@"line %d: %@", i, NSStringFromCGRect(lineBounds));
//	}
//
	
	CFRange factRange = CTFrameGetVisibleStringRange(frame);
	DEBUGLOG(@"fitRange : %ld : %ld", fitRange.location, fitRange.length);
	DEBUGLOG(@"fcatRange: %ld : %ld", factRange.location, factRange.length);
	BREAK();
	
	CGContextRestoreGState(context);
	
	// 掃除
	CGPathRelease(path);
	CFRelease(framesetter);
	CFRelease(frame);
}

//////////////////////////////////////////////////////////////
#pragma mark - Private
//////////////////////////////////////////////////////////////

- (NSMutableDictionary *)getAttributedStringSourceWithString:(CFStringRef)stringRef andFont:(CTFontRef)fontRef
{
	// グリフを日本式に最適化
	CTGlyphInfoRef glyphInfo = CTGlyphInfoCreateWithCharacterIdentifier(kCGFontIndexMax, kCTAdobeJapan1CharacterCollection, stringRef);
		
	// アライメントと自動改行と行間の設定
	CTTextAlignment alignment = kCTJustifiedTextAlignment;
	CTLineBreakMode lineBreakMode = kCTLineBreakByWordWrapping;
	CGFloat lineSpace = self.lineSpace;
	CGFloat paragraphSpace = _titleForTextSpace;
	CTParagraphStyleSetting paragraphStypeSettings[] = {
		{kCTParagraphStyleSpecifierAlignment,          sizeof(CTTextAlignment), &alignment},
		{kCTParagraphStyleSpecifierLineBreakMode,      sizeof(CTLineBreakMode), &lineBreakMode},
		{kCTParagraphStyleSpecifierParagraphSpacing,   sizeof(CGFloat),         &paragraphSpace},
		{kCTParagraphStyleSpecifierMinimumLineSpacing, sizeof(CGFloat),         &lineSpace},
		{kCTParagraphStyleSpecifierMaximumLineSpacing, sizeof(CGFloat),         &lineSpace},
	};
	CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(paragraphStypeSettings, sizeof(paragraphStypeSettings) / sizeof(CTParagraphStyleSetting));
	
	// 各設定を格納
	NSMutableDictionary *attrDict = [@{
		(id)kCTFontAttributeName           : (__bridge id)fontRef,
		(id)kCTGlyphInfoAttributeName      : (__bridge id)glyphInfo,
		(id)kCTParagraphStyleAttributeName : (__bridge id)paragraphStyle,
		(id)kCTKernAttributeName		   : @(self.letterSpace), // 文字間
		(id)kCTLigatureAttributeName       : @(YES),              // 合字
		(id)kCTVerticalFormsAttributeName  : @(YES)               // 縦書き準備 1/3
	} mutableCopy];
	
	
	CFRelease(glyphInfo);
	CFRelease(paragraphStyle);
	
	return attrDict;
}

//////////////////////////////////////////////////////////////
#pragma mark - Public
//////////////////////////////////////////////////////////////

- (void)toggleFontName
{
	if ([self.fontName isEqualToString:@"HiraMinProN-W3"]) {
		self.fontName = @"HiraKakuProN-W3";
	}
	else {
		self.fontName = @"HiraMinProN-W3";
	}
	
	[self setNeedsDisplay];
}


- (NSRange)visibleRangeWithString:(NSString *)aString andFont:(UIFont *)aFont
{
	CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)aFont.fontName, aFont.pointSize, NULL);
	NSMutableDictionary *attrDict = [self getAttributedStringSourceWithString:(__bridge CFStringRef)aString andFont:font];
	NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:aString attributes:attrDict];
	
	CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attrString);
	
	CGMutablePathRef path = CGPathCreateMutable();
	CGSize pathSize = self.bounds.size;
	CGFloat reversingDiff = DEVICE_OS_MAJOR_VERSION <= 5 ? pathSize.height - pathSize.width : 0;
	CGPathAddRect(path, NULL, CGRectMake(-reversingDiff, reversingDiff, BELOW_IOS_5_REVERSE_SIZE_WIDTH(pathSize), BELOW_IOS_5_REVERSE_SIZE_HEIGHT(pathSize)));
	
	CFRange fitRange;
	CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), NULL, CGSizeMake(BELOW_IOS_5_REVERSE_SIZE_WIDTH(pathSize), BELOW_IOS_5_REVERSE_SIZE_HEIGHT(pathSize)), &fitRange);
	
	NSDictionary *frameDict = @{ (id)kCTFrameProgressionAttributeName : @(kCTFrameProgressionRightToLeft) };
	
	CTFrameRef frame = CTFramesetterCreateFrame(framesetter, fitRange, path, (__bridge CFDictionaryRef)frameDict);
	
	CFRange fcatRange = CTFrameGetVisibleStringRange(frame);
	
	CGPathRelease(path);
	CFRelease(font);
	CFRelease(framesetter);
	CFRelease(frame);
	
	return NSMakeRange(fcatRange.location, fcatRange.length);
}

- (NSRange)visibleRangeWithString:(NSString *)text
{
	UIFont *font = [UIFont fontWithName:self.fontName size:self.fontSize];
	return [self visibleRangeWithString:text andFont:font];
}

- (NSRange)visibleRangeWithNormalText:(NSString *)text andTitleText:(NSString *)title
{
	NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] init];

	_titleForTextSpace = 30.0f;
	CTFontRef titleFont = CTFontCreateWithName((__bridge CFStringRef)self.fontName, self.fontSize * _titleSizeRate, NULL);
	NSMutableDictionary *titleAttrDict = [self getAttributedStringSourceWithString:(CFStringRef)title andFont:titleFont];
	NSMutableAttributedString *titleAttrString = [[NSMutableAttributedString alloc] initWithString:title attributes:titleAttrDict];
	[attrString appendAttributedString:titleAttrString];
	_titleForTextSpace = 0;
	
	CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)self.fontName, self.fontSize, NULL);
	NSMutableDictionary *textAttrDict = [self getAttributedStringSourceWithString:(__bridge CFStringRef)text andFont:font];
	NSMutableAttributedString *textAttrString  = [[NSMutableAttributedString alloc] initWithString:text attributes:textAttrDict];
	[attrString appendAttributedString:textAttrString];

	CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attrString);
	
	CGMutablePathRef path = CGPathCreateMutable();
	CGSize pathSize = self.bounds.size;
	CGFloat reversingDiff = DEVICE_OS_MAJOR_VERSION <= 5 ? pathSize.height - pathSize.width : 0;
	CGPathAddRect(path, NULL, CGRectMake(-reversingDiff, reversingDiff, BELOW_IOS_5_REVERSE_SIZE_WIDTH(pathSize), BELOW_IOS_5_REVERSE_SIZE_HEIGHT(pathSize)));
	
	CFRange fitRange = CFRangeMake(0, 0);
	CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), NULL, CGSizeMake(BELOW_IOS_5_REVERSE_SIZE_WIDTH(pathSize), BELOW_IOS_5_REVERSE_SIZE_HEIGHT(pathSize)), &fitRange);
	
	NSDictionary *frameDict = @{ (id)kCTFrameProgressionAttributeName : @(kCTFrameProgressionRightToLeft) };
	
	CTFrameRef frame = CTFramesetterCreateFrame(framesetter, fitRange, path, (__bridge CFDictionaryRef)frameDict);
	
	CFRange cfRange = CTFrameGetVisibleStringRange(frame);
	
	CGPathRelease(path);
	CFRelease(titleFont);
	CFRelease(font);
	CFRelease(framesetter);
	CFRelease(frame);
		
	return NSMakeRange(cfRange.location, cfRange.length);
}

- (NSArray *)clusterVisibleRangesWithString:(NSString *)text startRange:(NSRange)startRange
{
	CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)self.fontName, self.fontSize, NULL);
	NSMutableDictionary *attrDict = [self getAttributedStringSourceWithString:(__bridge CFStringRef)text andFont:font];
	NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:text attributes:attrDict];
	
	CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attrString);
	
	CGMutablePathRef path = CGPathCreateMutable();
	CGSize pathSize = self.bounds.size;
	CGFloat reversingDiff = DEVICE_OS_MAJOR_VERSION <= 5 ? pathSize.height - pathSize.width : 0;
	CGPathAddRect(path, NULL, CGRectMake(-reversingDiff, reversingDiff, BELOW_IOS_5_REVERSE_SIZE_WIDTH(pathSize), BELOW_IOS_5_REVERSE_SIZE_HEIGHT(pathSize)));
	
	NSMutableArray *clusterRanges = [NSMutableArray array];
//	[clusterRanges addObject:[NSValue valueWithRange:startRange]];
	
	CFIndex location = startRange.length;
	CFIndex length   = [text length];
	while (location < length) {
		CFRange stringRange = CFRangeMake(location, length-location);
		CFRange fitRange;
		CTFramesetterSuggestFrameSizeWithConstraints(framesetter, stringRange, NULL, CGSizeMake(BELOW_IOS_5_REVERSE_SIZE_WIDTH(pathSize), BELOW_IOS_5_REVERSE_SIZE_HEIGHT(pathSize)), &fitRange);
		
		NSDictionary *frameDict = @{ (id)kCTFrameProgressionAttributeName : @(kCTFrameProgressionRightToLeft) };
		CTFrameRef frame = CTFramesetterCreateFrame(framesetter, fitRange, path, (__bridge CFDictionaryRef)frameDict);
		
		CFRange factRange = CTFrameGetVisibleStringRange(frame);
		NSRange range = NSMakeRange(location, factRange.length);
		[clusterRanges addObject:[NSValue valueWithRange:range]];
		
		location += factRange.length;
		
		CFRelease(frame);
	}
	
	CGPathRelease(path);
	CFRelease(font);
	CFRelease(framesetter);
	
	return clusterRanges;
}

- (CGSize)linesSizeWithString:(NSString *)aString andFont:(UIFont *)aFont
{
	CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)aFont.fontName, aFont.pointSize, NULL);
	NSMutableDictionary *attrDict = [self getAttributedStringSourceWithString:(CFStringRef)aString andFont:font];
	NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:self.text attributes:attrDict];
	CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attrString);
	
	// 
	CGSize constraints = CGSizeMake(self.bounds.size.height, CGFLOAT_MAX);
	CGSize size = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), NULL, constraints, NULL);
	
	CFRelease(font);
	CFRelease(framesetter);
	
	return size;
}

- (CGSize)linesSizeWithTextString:(NSString *)text
{
	UIFont *font = [UIFont fontWithName:self.fontName size:self.fontSize];
	return [self linesSizeWithString:text andFont:font];
}

- (CGSize)titleLinesSizeWithTitleTextString:(NSString *)titleText
{
	UIFont *font = [UIFont fontWithName:self.fontName size:self.fontSize * _titleSizeRate];
	CGSize size = [self linesSizeWithString:titleText andFont:font];
	size.height -= _titleForTextSpace * 2;
	return size;
}

// 旧式
// タイトルだけ別個で1行だけ書いていたが、全体のframeの大きさや入る文字数の計算が面倒だったので
// 一つのframe内でタイトルも書く方式（上部）に変更
/*
 - (void)drawRect:(CGRect)rect
 {
 CGContextRef context = UIGraphicsGetCurrentContext();
 
 CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)self.fontName, self.fontSize, NULL);
 NSMutableDictionary *attrDict = [self getAttributedStringSourceWithString:(CFStringRef)self.text andFont:font];
 
 // 部・章などのタイトルがあれば書く
 CGRect titleRect = CGRectZero; // タイトルを書いたときに本文をどれだけずらすのかに使う
 if ([self.titleText length] > 0) {
 CTFontRef titleFont = CTFontCreateWithName((__bridge CFStringRef)self.fontName, self.fontSize * _titleSizeRate, NULL);
 [attrDict setObject:(__bridge id)titleFont forKey:(id)kCTFontAttributeName]; // fontを書き換え
 NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:self.titleText attributes:attrDict];
 
 titleRect = DrawTitleLineIntoContext(context, (__bridge CFAttributedStringRef)attrString, 0, rect);
 
 CFRelease(titleFont);
 
 [attrDict setObject:(__bridge id)font forKey:(id)kCTFontAttributeName]; // 書き換えたfontを戻す
 _titleForTextSpace = 30.0f;
 }
 
 
 // CFAttributedString -> CTFramesetter + CGPath -> CTFrame
 // 上記の順でCoreTextを作成
 
 NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:self.text attributes:attrDict];
 
 CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attrString);
 
 CGMutablePathRef path = CGPathCreateMutable();
 CGSize pathSize = rect.size;
 
 // 縦書きにするため幅と高さが逆転する。逆転するだけだと枠外にいってしまうので、幅と高さの差で引き戻す。(iOS 5)
 // また、原点が左下に変わっている(縦書き準備 3/3のScaleが影響)。このことを頭に入れて↓
 
 // iOS5では幅と高さが逆転するため、それらを入れ替えた際に生じる差を埋める必要があるが、iOS6では逆転が起こらないので不必要
 CGFloat reversingDiff = DEVICE_OS_MAJOR_VERSION <= 5 ? pathSize.height - pathSize.width : 0;
 
 CGFloat titleWidth = titleRect.size.height + _titleForTextSpace;
 
 // 幅を高さの値に=>右側へ行きすぎる=>減算 (iOS 5)
 // 高さを幅の値に=>下方へ行きすぎる=>加算 (iOS 5)
 // todo:タイトルが入ってくるとその分左側へずらす。その際、ずれる分だけx座標、widthにマイナスする。(iOS6; iOS5ではまた逆転するかも。。)
 DEBUGLOG(@"space: %f", titleWidth);
 CGPathAddRect(path, NULL, CGRectMake(-reversingDiff, reversingDiff, BELOW_IOS_5_REVERSE_SIZE_WIDTH(pathSize) - titleWidth, BELOW_IOS_5_REVERSE_SIZE_HEIGHT(pathSize)));
 DEBUGLOG(@"path: %@",NSStringFromCGRect(CGPathGetBoundingBox(path)));
 NSDictionary *frameDict = @{ (id)kCTFrameProgressionAttributeName : @(kCTFrameProgressionRightToLeft) }; // 縦書き準備 2/3
 CFRange fitRange;
 CGSize debug_size = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), NULL, CGSizeMake(BELOW_IOS_5_REVERSE_SIZE_WIDTH(pathSize) - titleWidth, BELOW_IOS_5_REVERSE_SIZE_HEIGHT(pathSize)), &fitRange);
 
 DEBUGLOG(@"title: %@",NSStringFromCGRect(titleRect));
 DEBUGLOG(@"frame: %@",NSStringFromCGSize(debug_size));
 
 CTFrameRef frame = CTFramesetterCreateFrame(framesetter, fitRange, path, (__bridge CFDictionaryRef)frameDict);
 
 CGContextSaveGState(context);
 
 // 縦書き準備 3/3 鏡状態になっているので反転
 CGContextSetTextMatrix(context, CGAffineTransformIdentity);
 CGContextTranslateCTM(context, 0, pathSize.height);
 CGContextScaleCTM(context, 1.0f, -1.0f);
 
 CTFrameDraw(frame, context); // contextに対してCoreTextテキストを書き込む
 
 CFRange factRange = CTFrameGetVisibleStringRange(frame);
 DEBUGLOG(@"fitRange : %ld : %ld", fitRange.location, fitRange.length);
 DEBUGLOG(@"fcatRange: %ld : %ld", factRange.location, factRange.length);
 
 //	// デバッグ
 //	CFArrayRef lines = CTFrameGetLines(frame);
 //	for (int i=0; i < CFArrayGetCount(lines); i++) {
 //		CTLineRef line = CFArrayGetValueAtIndex(lines, i);
 //		CGRect lineBounds = CTLineGetImageBounds(line, context);
 //		DEBUGLOG(@"line %d: %@", i, NSStringFromCGRect(lineBounds));
 //	}
 //
 //	CGSize size = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), NULL, CGSizeMake(BELOW_IOS_5_REVERSE_SIZE_WIDTH(pathSize) -titleRect.size.height -titleRect.origin.y - _titleForTextSpace, BELOW_IOS_5_REVERSE_SIZE_HEIGHT(pathSize)), NULL);
 //	DEBUGLOG(@"%@",NSStringFromCGSize(size));
 
 CGContextRestoreGState(context);
 
 // 掃除
 CGPathRelease(path);
 CFRelease(font);
 CFRelease(framesetter);
 CFRelease(frame);
 }
 
 
 // CTFrameを設定できないため、kCTFrameProgressionRightToLeftも設定できない。
 // CGContextをトランスフォーム系の関数で移動・反転・回転させる。
 // kCTFrameProgressionRightToLeftを設定しないためか、iOS6でも幅と高さの逆転現象が起こる
 CGRect DrawTitleLineIntoContext(CGContextRef context, CFAttributedStringRef attrString, CFIndex startIndex, CGRect textRect)
 {
 CTTypesetterRef typesetter = CTTypesetterCreateWithAttributedString(attrString);
 
 // 自動改行を考慮した一行に表示可能な文字数を取得
 CFIndex displayabilityCount = CTTypesetterSuggestLineBreak(typesetter, startIndex, textRect.size.height); // 縦書きなので実引数widthにはheightを仮引数として渡す
 CTLineRef line = CTTypesetterCreateLine(typesetter, CFRangeMake(startIndex, displayabilityCount));
 
 CGFloat flushFactor = CFAttributedStringGetLength(attrString) <= displayabilityCount ? 0.3f : 1.0f; // 一行目なら少しインデントを与え、それ以降の行は下揃えする
 
 //													寄せ		   , 縦書きなので実引数widthにはheightを仮引数として渡す
 double penOffset = CTLineGetPenOffsetForFlush(line, flushFactor, textRect.size.height);
 
 CGContextSaveGState(context);
 CGContextSetTextMatrix(context, CGAffineTransformIdentity);
 
 // テキストを書く位置を調節
 CGContextSetTextPosition(context, penOffset, 0); // x座標上の移動は効かないので0とし、以下の変形部分で行う
 
 // 右寄せするためのx座標を取得(縦書きのため、行のwidth、x座標はheight・y座標で表す)
 CGRect lineRect = CTLineGetImageBounds(line, context);
 //						  幅全体				  - (縦書きのため)幅サイズ	 - (縦書きのため)横へ自動調節された分
 CGFloat rightEdgeOffset = textRect.size.width - lineRect.size.height - lineRect.origin.y;
 
 // 変形
 CGContextTranslateCTM(context, rightEdgeOffset, 0); // x座標の移動
 CGContextScaleCTM(context, -1.0f, 1.0f);
 CGContextRotateCTM(context, 2.0f * M_PI * 90.0f/360.0f);
 
 CTLineDraw(line, context); // contextに対してCoreTextテキストを書き込む
 
 // 掃除
 CFRelease(typesetter);
 CFRelease(line);
 
 CGContextRestoreGState(context);
 
 // 複数行に渡る場合はリカーシブに実行
 static CFIndex totalCount;
 totalCount += displayabilityCount; // いままで表示した文字数を記憶
 if (CFAttributedStringGetLength(attrString) > totalCount) {
 
 // 次の行の位置を設定。いまの幅を、書き込んだ一行分の幅だけ狭める + 行間(てきとー)
 textRect.size.width -= lineRect.size.height + 7.5f;
 
 // リカーシブ。実引数startIndexには、まだ書き込んでない最初の文字indexを設定
 CGRect nextLineRect = DrawTitleLineIntoContext(context, attrString, totalCount, textRect);
 lineRect.size.height += nextLineRect.size.height;
 }
 
 totalCount = 0;
 return lineRect;
 }
 */

@end
