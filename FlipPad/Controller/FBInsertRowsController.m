    //
//  FBInsertRowsController.m
//  FlipBookPad
//
//  Created by Manton Reece on 5/21/11.
//  Copyright 2011 DigiCel. All rights reserved.
//

#import "FBInsertRowsController.h"

@implementation FBInsertRowsController

- (id) init
{
	self = [super initWithNibName:@"InsertRows" bundle:nil];
	if (self) {
		self.preferredContentSize = self.view.bounds.size;
	}
	
	return self;
}

@end
