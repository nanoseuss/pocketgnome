/*
 * Copyright (c) 2007-2010 Savory Software, LLC, http://pg.savorydeviate.com/
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * $Id$
 *
 */

#import "ScanGridView.h"


@implementation ScanGridView

@synthesize xIncrement = xInc;
@synthesize yIncrement = yInc;
@synthesize scanPoint;
@synthesize origin;


- (void)drawRect:(NSRect)aRect {
	[[NSColor clearColor] set];
	[NSBezierPath fillRect: [self frame]];
    
    
    NSBezierPath *border = [NSBezierPath bezierPath];
    NSBezierPath *done = [NSBezierPath bezierPath];
    NSBezierPath *notDone = [NSBezierPath bezierPath];
    
    // make box around us
    [border moveToPoint: NSZeroPoint];
    [border lineToPoint: NSMakePoint(0, aRect.size.height)];
    [border lineToPoint: NSMakePoint(aRect.size.width, aRect.size.height)];
    [border lineToPoint: NSMakePoint(aRect.size.width, 0)];
    [border lineToPoint: NSZeroPoint];
    
    int i;
    if(self.xIncrement > 0) {
        for(i=0; i<=aRect.size.width; i+=self.xIncrement) {
            
            if(i < self.scanPoint.x) {
                [done moveToPoint: NSMakePoint(i, 0)];
                [done lineToPoint: NSMakePoint(i, aRect.size.height)];
            } else {
                [notDone moveToPoint: NSMakePoint(i, 0)];
                [notDone lineToPoint: NSMakePoint(i, aRect.size.height)];
            }
        }
    }
    if(self.yIncrement > 0) {
        for(i=aRect.size.height; i>=0; i-=self.yIncrement) {
            if(i > self.scanPoint.y) {
                [done moveToPoint: NSMakePoint(0, i)];
                [done lineToPoint: NSMakePoint(aRect.size.width, i)];
            } else {
                [notDone moveToPoint: NSMakePoint(0, i)];
                [notDone lineToPoint: NSMakePoint(aRect.size.width, i)];
            }
        }
    }
    
	NSRect focusBox = NSZeroRect;
	focusBox.origin = NSPointFromCGPoint(self.scanPoint);
    NSBezierPath *mouse = [NSBezierPath bezierPathWithOvalInRect: NSInsetRect(focusBox, -5, -5)];
    
    [[NSColor greenColor] set];
    [done setLineWidth: 1.0];
    [done stroke];
    
    [[NSColor redColor] set];
    [notDone setLineWidth: 1.0];
    [notDone stroke];

    
    [[NSColor orangeColor] set];
    [border setLineWidth: 4.0];
    [border stroke];
    [mouse fill];
    
}

@end
