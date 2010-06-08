//
//  ThreadInfoCell.m
//  ManualBindings
//
//  Created by Alessandro Volz on 2/16/10.
//  Copyright 2010 Ingroppalgrillo. All rights reserved.
//

#import "ThreadCell.h"
#import "ThreadsManager.h"
#import "ThreadsWindowController.h"
#import "ThreadCellCancelButton.h"
#import "NSString+DiscPublisher.h"
#import "NSThread+N2.h"


@implementation ThreadCell

@synthesize progressIndicator = _progressIndicator;
@synthesize cancelButton = _cancelButton;
@synthesize thread = _thread;
@synthesize manager = _manager;
@synthesize view = _view;

-(id)initWithThread:(NSThread*)thread manager:(ThreadsManager*)manager view:(NSTableView*)view {
	self = [super init];
	
	_view = [view retain];
	_manager = [manager retain];
	
	ThreadsWindowController* threadsController = (id)view.delegate;
	[self setTextColor:threadsController.statusLabel.textColor];
	
	_progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSZeroRect];
	[_progressIndicator setUsesThreadedAnimation:YES];
	[_progressIndicator setMinValue:0];
	[_progressIndicator setMaxValue:1];
	
	_cancelButton = [[ThreadCellCancelButton alloc] initWithFrame:NSZeroRect]; // TODO: the button is ugly, make it look better
	_cancelButton.target = self;
	_cancelButton.action = @selector(cancelThreadAction:);

	self.thread = thread;

	return self;
}

-(void)dealloc {
	[self.progressIndicator removeFromSuperview];
	self.progressIndicator = NULL;
	[self.cancelButton removeFromSuperview];
	self.cancelButton = NULL;
	self.thread = NULL;
	[_view release];
	[super dealloc];
}

-(void)setThread:(NSThread*)thread {
	@try {
		[self.thread removeObserver:self forKeyPath:NSThreadSupportsCancelKey];
		[self.thread removeObserver:self forKeyPath:NSThreadProgressKey];
		[self.thread removeObserver:self forKeyPath:NSThreadStatusKey];
	} @catch (...) {
	}
	
	[_thread release];
	_thread = [thread retain];
	
	[self.thread addObserver:self forKeyPath:NSThreadStatusKey options:NSKeyValueObservingOptionInitial context:NULL];
	[self.thread addObserver:self forKeyPath:NSThreadProgressKey options:NSKeyValueObservingOptionInitial context:NULL];
	[self.thread addObserver:self forKeyPath:NSThreadSupportsCancelKey options:NSKeyValueObservingOptionInitial context:NULL];
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)obj change:(NSDictionary*)change context:(void*)context {
	if (obj == self.thread)
		if ([keyPath isEqual:NSThreadStatusKey]) {
			[self.view setNeedsDisplayInRect:[self statusFrame]];
			return;
		} else if ([keyPath isEqual:NSThreadProgressKey]) {
			[self.progressIndicator setDoubleValue:self.thread.progress];
			[self.progressIndicator setIndeterminate: self.thread.progress < 0];	
			return;
		} else if ([keyPath isEqual:NSThreadSupportsCancelKey]) {
			[self.cancelButton setHidden:!self.thread.supportsCancel];
			[self.cancelButton setEnabled:self.thread.supportsCancel];
			return;
		}
	
	[super observeValueForKeyPath:keyPath ofObject:obj change:change context:context];
}

-(void)cancelThreadAction:(id)source {
	[self.thread setIsCancelled:YES];
}

-(void)drawInteriorWithFrame:(NSRect)frame inView:(NSView*)view {
	NSMutableParagraphStyle* paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
	NSMutableDictionary* textAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys: [self textColor], NSForegroundColorAttributeName, [NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]], NSFontAttributeName, paragraphStyle, NSParagraphStyleAttributeName, NULL];

	[NSGraphicsContext saveGraphicsState];
	
	NSRect nameFrame = NSMakeRect(frame.origin.x+3, frame.origin.y, frame.size.width-23, frame.size.height);
	NSString* name = self.thread.name;
	if (!name) name = @"Untitled Thread";
	[name drawWithRect:nameFrame options:NSStringDrawingUsesLineFragmentOrigin attributes:textAttributes];
	
	NSRect statusFrame = [self statusFrame];
	[textAttributes setObject:[NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]] forKey:NSFontAttributeName];
	[(self.thread.status? self.thread.status : @"No activity information was provided for this thread.") drawWithRect:statusFrame options:NSStringDrawingUsesLineFragmentOrigin attributes:textAttributes];
	
	NSRect cancelFrame = NSMakeRect(frame.origin.x+frame.size.width-15-5, frame.origin.y+6, 15, 15);
	if (![self.cancelButton superview])
		[view addSubview:self.cancelButton];
	if (!NSEqualRects(self.cancelButton.frame, cancelFrame)) [self.cancelButton setFrame:cancelFrame];
	
	NSRect progressFrame = NSMakeRect(frame.origin.x+1, frame.origin.y+28, frame.size.width-2, frame.size.height-29);
	if (![self.progressIndicator superview]) {
		[view addSubview:self.progressIndicator];
		[self.progressIndicator startAnimation:self];
	} if (!NSEqualRects(self.progressIndicator.frame, progressFrame)) [self.progressIndicator setFrame:progressFrame];
	
	[NSGraphicsContext restoreGraphicsState];
}

static NSPoint operator+(const NSPoint& p, const NSSize& s)
{ return NSMakePoint(p.x+s.width, p.y+s.height); }

-(void)drawWithFrame:(NSRect)frame inView:(NSView*)view {
	[self drawInteriorWithFrame:frame inView:view];
	
	[NSGraphicsContext saveGraphicsState];
	
	[[[NSColor grayColor] colorWithAlphaComponent:0.5] set];
	[NSBezierPath strokeLineFromPoint:frame.origin+NSMakeSize(-2, frame.size.height) toPoint:frame.origin+frame.size+NSMakeSize(2,0)];
	
	[NSGraphicsContext restoreGraphicsState];
}

-(NSRect)statusFrame {
	NSRect frame = [self.view rectOfRow:[self.manager.threads indexOfObject:self.thread]];
	return NSMakeRect(frame.origin.x+3, frame.origin.y+14, frame.size.width-23, frame.size.height-13);
}

@end