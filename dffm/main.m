//
//  main.m
//  ffm
//
//  Created by shdwprince on 4/20/17.
//  Copyright © 2017 shdwprince. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

int display_n(CGPoint p) {
    int screen_n = 0;
    CGFloat combined_offset = 0.0;
    for (NSScreen *screen in [NSScreen screens]) {
        combined_offset += screen.visibleFrame.size.width;
        if (p.x < combined_offset) {
            break;
        }

        screen_n++;
    }
    return screen_n;
}

void switch_to_display_n_2(int n) {
    CGEventRef null_event = CGEventCreate(NULL);

    CGPoint origLocation = CGEventGetLocation(null_event);
    CGPoint clickLocation = CGPointMake(1920 / 3 * 2 + 1920 * n, 0);

    CGEventRef click_down = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, clickLocation, kCGMouseButtonLeft);
    CGEventRef click_up = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, clickLocation, kCGMouseButtonLeft);
    CGEventRef back_move = CGEventCreateMouseEvent(NULL, kCGEventMouseMoved, origLocation, kCGMouseButtonCenter);

    CGEventPost(kCGHIDEventTap, click_down);
    CGEventPost(kCGHIDEventTap, click_up);
    CGEventPost(kCGHIDEventTap, back_move);

    CFRelease(click_down);
    CFRelease(click_up);
    CFRelease(back_move);
    CFRelease(null_event);
}

CGPoint previousLocation = { x: 0, y: 0 };
CGEventRef tap_callback(CGEventTapProxy proxy, CGEventType type, CGEventRef ref, void *refcon) {
    CGPoint currentLocation = CGEventGetLocation(ref);

    int current_display = -1;
    if ((current_display = display_n(currentLocation)) != display_n(previousLocation)) {
        switch_to_display_n_2(current_display);
    }

    previousLocation = currentLocation;
    return ref;
}

int main(int argc, const char * argv[]) {
    CFMachPortRef tap_ref = CGEventTapCreate(kCGHIDEventTap, kCGHeadInsertEventTap, kCGEventTapOptionListenOnly, CGEventMaskBit(kCGEventMouseMoved), tap_callback, nil);
    CFRunLoopSourceRef tap_source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap_ref, 0);

    CFRunLoopAddSource(CFRunLoopGetCurrent(), tap_source, kCFRunLoopCommonModes);
    CGEventTapEnable(tap_ref, true);

    CGEventRef null_event = CGEventCreate(NULL);
    previousLocation = CGEventGetLocation(null_event);
    CFRelease(null_event);

    CFRunLoopRun();
    return 0;
}
