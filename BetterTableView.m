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
 
#import "BetterTableView.h"

@implementation BetterTableView

//- (BOOL)canDragRowsWithIndexes:(NSIndexSet *)rowIndexes atPoint:(NSPoint)mouseDownPoint {
//    PGLog(@"canDragRowsWithIndexes");
//    return YES;
//}

- (void)keyDown:(NSEvent *)theEvent {
    NSString* characters;
    int character, characterCount, characterIndex;
    
    characters = [theEvent charactersIgnoringModifiers];
    characterCount = [characters length];
    for (characterIndex = 0; characterIndex < characterCount; characterIndex++)
    {
        character = [characters characterAtIndex:characterIndex];
        if(character == 127) {  // delete
            if( [self delegate] && [[self delegate] respondsToSelector: @selector(tableView:deleteKeyPressedOnRowIndexes:)] ) {
                [[self delegate] tableView: self deleteKeyPressedOnRowIndexes: [self selectedRowIndexes]];
                return;
            }
        }/*
        if(character == NSUpArrowFunctionKey) {
            [self selectRow:[self selectedRow]-1 byExtendingSelection:NO];
            return;
        }
        if(character == NSDownArrowFunctionKey) {
            [self selectRow:[self selectedRow]+1 byExtendingSelection:NO];
            return;
        }*/
    }
    
    [super keyDown:theEvent];
}

- (void)copy: (id)sender { 
    if( ([self selectedRow] != -1) && [self delegate] && [[self delegate] respondsToSelector: @selector(tableViewCopy:)] ) {
        // PGLog(@"Table view copy!");
        if([[self delegate] tableViewCopy: self])   return;
    }
    NSBeep();
}

- (void)paste: (id)sender { 
    if( [self delegate] && [[self delegate] respondsToSelector: @selector(tableViewPaste:)] ) {
        // PGLog(@"Table view paste!");
        if([[self delegate] tableViewPaste: self])   return;
    }
    NSBeep();
}

- (void)cut: (id)sender { 
    if( ([self selectedRow] != -1) && [self delegate] && [[self delegate] respondsToSelector: @selector(tableViewCut:)] ) {
        // PGLog(@"Table view copy!");
        if([[self delegate] tableViewCut: self])   return;
    }
    NSBeep();
}

@end
