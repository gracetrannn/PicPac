//
//  FBButton.m
//  FlipPad
//
//  Created by Manton Reece on 2/14/14.
//  Copyright (c) 2014 DigiCel, Inc. All rights reserved.
//

#import "FBButton.h"

@implementation FBButton

- (instancetype) initWithTitle:(NSString *)inTitle
{
	CGRect r = CGRectMake (0, 0, 60, 30);
	self = [super initWithFrame:r];
	if (self) {
		self.customTitle = inTitle;
	}
	
	return self;
}

- (instancetype) initWithImage:(UIImage *)image
{
    CGRect r = CGRectMake (0, 0, 60, 30);
    self = [super initWithFrame:r];
    if (self) {
        [self.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [self setImage:image forState:UIControlStateNormal];
    }
    
    return self;
}

- (id) initWithFrame:(CGRect)inFrame
{
	self = [super initWithFrame:inFrame];
	if (self) {
		self.customBackgroundColor = [UIColor darkGrayColor];
		self.customBackgroundAlpha = 0.1;
	}
	
	return self;
}

- (id) initWithCoder:(NSCoder *)inDecoder
{
	self = [super initWithCoder:inDecoder];
	if (self) {
		self.customBackgroundColor = [UIColor darkGrayColor];
		self.customBackgroundAlpha = 0.1;
	}
	
	return self;
}

- (void) drawRect:(CGRect)inVisRect
{
	CGRect r = [self bounds];
		
	[self.customBackgroundColor set];
	UIBezierPath* rounded_path = [UIBezierPath bezierPathWithRoundedRect:r cornerRadius:5];
	[rounded_path fillWithBlendMode:kCGBlendModeNormal alpha:self.customBackgroundAlpha];
	
	if (self.customTitle) {
		r.origin.y += 5;
		NSMutableParagraphStyle* para = [[NSMutableParagraphStyle alloc] init];
		para.alignment = NSTextAlignmentCenter;
		NSDictionary* info = @{
								NSFontAttributeName: [UIFont systemFontOfSize:16],
								NSForegroundColorAttributeName: [UIColor whiteColor],
								NSParagraphStyleAttributeName: para
								};
		NSAttributedString* s = [[NSAttributedString alloc] initWithString:self.customTitle attributes:info];
		[s drawWithRect:r options:NSStringDrawingUsesLineFragmentOrigin context:NULL];
	}
}

@end
