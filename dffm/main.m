//
//  main.m
//  ffm
//
//  Created by shdwprince on 4/20/17.
//  Copyright © 2017 shdwprince. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

static CGRect MAIN_DISPLAY;
static CGRect DISPLAYS[6];
static NSUInteger DISPLAYS_N = 0;

CGPoint display_click_location(NSRect rect) {
    // should point to nothing on menubar
    CGFloat magicX = rect.origin.x + rect.size.width / 3 * 1.7;

    // convert from NS to CG
    CGFloat cgY = MAIN_DISPLAY.size.height - rect.origin.y - rect.size.height;
    
    return CGPointMake(magicX, cgY);
}

void setup() {
    MAIN_DISPLAY = NSRectToCGRect([NSScreen mainScreen].frame);

    int i = 0;
    for (NSScreen *screen in [NSScreen screens]) {
        DISPLAYS[i++] = NSRectToCGRect(screen.frame);
        DISPLAYS_N++;
    }
}

int display_n(CGPoint p) {
    for (int i = 0; i < DISPLAYS_N; i++) {
        // we can ignore CG-NS coordinates mess up cause we only need to check X
        if (NSPointInRect(p, DISPLAYS[i])) {
            return i;
        }
    }

    return 0;
}

void switch_to_display_n(int n) {
    CGEventRef null_event = CGEventCreate(NULL);

    CGPoint orig_location = CGEventGetLocation(null_event);
    CGPoint click_location = display_click_location(DISPLAYS[n]);

    CGEventRef click_down = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, click_location, kCGMouseButtonLeft);
    CGEventRef click_up = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, click_location, kCGMouseButtonLeft);
    CGEventRef back_move = CGEventCreateMouseEvent(NULL, kCGEventMouseMoved, orig_location, kCGMouseButtonCenter);

    CGEventPost(kCGHIDEventTap, click_down);
    CGEventPost(kCGHIDEventTap, click_up);
    CGEventPost(kCGHIDEventTap, back_move);

    CFRelease(click_down);
    CFRelease(click_up);
    CFRelease(back_move);
    CFRelease(null_event);
}

CGEventRef tap_callback(CGEventTapProxy proxy, CGEventType type, CGEventRef ref, void *ctx) {
    CGPoint current_location = CGEventGetLocation(ref);
    CGPoint *previous_location = (CGPoint *) ctx;

    int current_display = -1;
    if ((current_display = display_n(current_location)) != display_n(*previous_location)) {
        switch_to_display_n(current_display);
    }

    *previous_location = current_location;
    return ref;
}

int main(int argc, const char * argv[]) {
    CGPoint previous_location = CGEventGetLocation(CGEventCreate(NULL));
    CFMachPortRef tap_ref = CGEventTapCreate(kCGHIDEventTap, kCGHeadInsertEventTap, kCGEventTapOptionListenOnly, CGEventMaskBit(kCGEventMouseMoved), tap_callback, &previous_location);
    CFRunLoopSourceRef tap_source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap_ref, 0);

    CFRunLoopAddSource(CFRunLoopGetCurrent(), tap_source, kCFRunLoopCommonModes);
    CGEventTapEnable(tap_ref, true);

    setup();
    CFRunLoopRun();
    return 0;
}
