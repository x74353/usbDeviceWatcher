//
//  AppDelegate.h
//  usbDeviceWatcher
//
//

#import <Cocoa/Cocoa.h>
#import <IOKit/usb/IOUSBLib.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (strong) NSMutableDictionary *deviceDictionary;
@property (strong) IBOutlet NSPopUpButton *deviceButton;

@end

