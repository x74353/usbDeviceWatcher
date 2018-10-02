//
//  AppDelegate.m
//  usbDeviceWatcher
//
//

#import "AppDelegate.h"

typedef struct DeviceData
{
    io_object_t             notification;
    CFStringRef             deviceName;
    CFStringRef             deviceSerialNum;
    
} DeviceData;

static IONotificationPortRef    gNotifyPort;
static io_iterator_t            gAddedIter;
static CFRunLoopRef             gRunLoop;

@interface AppDelegate ()
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self.deviceButton removeAllItems];
    self.deviceDictionary = [[NSMutableDictionary alloc] init];
    [self initIOKitMonitor];
}


-(void) initIOKitMonitor
{
        CFMutableDictionaryRef  matchingDict;
        CFRunLoopSourceRef      runLoopSource;
        kern_return_t           kr;
        
        matchingDict = IOServiceMatching(kIOUSBDeviceClassName);
        
        if (matchingDict == NULL)
        {
            fprintf(stderr, "IOServiceMatching returned NULL.\n");
        }
        
        // Create a notification port and add its run loop event source to our run loop
        // This is how async notifications get set up.
        
        gNotifyPort = IONotificationPortCreate(kIOMasterPortDefault);
        runLoopSource = IONotificationPortGetRunLoopSource(gNotifyPort);
        
        gRunLoop = CFRunLoopGetCurrent();
        CFRunLoopAddSource(gRunLoop, runLoopSource, kCFRunLoopDefaultMode);
        
        // Now set up a notification to be called when a device is first matched by I/O Kit.
        kr = IOServiceAddMatchingNotification(gNotifyPort,                  // notifyPort
                                              kIOFirstMatchNotification,    // notificationType
                                              matchingDict,                 // matching
                                              DeviceAdded,                  // callback
                                              NULL,                         // refCon
                                              &gAddedIter                   // notification
                                              );
        
        // Iterate once to get already-present devices and arm the notification
        DeviceAdded(NULL, gAddedIter);
        
        // Start the run loop. Now we'll receive notifications.
        CFRunLoopRun();
        CFRelease(runLoopSource);
        CFRelease(gRunLoop);
}


void DeviceAdded(void *refCon, io_iterator_t iterator)
{
    kern_return_t   kr;
    io_service_t    usbDevice;
    
    while ((usbDevice = IOIteratorNext(iterator)))
    {
        io_name_t   deviceName;
        CFStringRef deviceNameCF;
        
        DeviceData  *deviceDataRef = NULL;
        
        // Get the USB device's name.
        kr = IORegistryEntryGetName(usbDevice, deviceName);
        if (KERN_SUCCESS != kr)
        {
            deviceName[0] = '\0';
        }
        
        CFMutableDictionaryRef usbProperties = 0;
        if (IORegistryEntryCreateCFProperties(usbDevice, &usbProperties, kCFAllocatorDefault, kNilOptions) != KERN_SUCCESS)
        {
            IOObjectRelease(usbDevice);
            continue;
        }
        
        NSDictionary *properties = CFBridgingRelease(usbProperties);
        
        NSString *deviceSerialNumNS = properties[(__bridge NSString *)CFSTR("USB Serial Number")];
        NSNumber *builtIn = properties[(__bridge NSString *)CFSTR("Built-In")];
        deviceNameCF = CFStringCreateWithCString(kCFAllocatorDefault, deviceName, kCFStringEncodingASCII);
        NSString *deviceNameNS = CFBridgingRelease(deviceNameCF);
        
        if (deviceNameNS)
        {
            deviceNameNS = [deviceNameNS stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            if (deviceSerialNumNS)
            {
                deviceSerialNumNS = [deviceSerialNumNS stringByReplacingOccurrencesOfString:@" " withString:@""];
            }
            else
            {
                deviceSerialNumNS = deviceNameNS;
            }
        }
        
        // If device is not built-in, has a name string that is not equal to ""
        if ((builtIn.integerValue != 1) &&
            (deviceNameNS) && (![deviceNameNS isEqualToString:@""]))
        {
            // Add some app-specific information about this device.
            // Create a buffer to hold the data.
            deviceDataRef = malloc(sizeof(DeviceData));
            bzero(deviceDataRef, sizeof(DeviceData));
            
            // Save the device's name to our private data.
            deviceDataRef->deviceName = (__bridge CFStringRef)(deviceNameNS);
            deviceDataRef->deviceSerialNum = (__bridge CFStringRef)(deviceSerialNumNS);
            
            // Add the name and serial number of this device to our device dictionary
            AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
            [appDelegate updateDeviceDict:deviceSerialNumNS:deviceNameNS:YES];
            
            // Register for an interest notification of this device being removed. Use a reference to our
            // private data as the refCon which will be passed to the notification callback.
            kr = IOServiceAddInterestNotification(gNotifyPort,                      // notifyPort
                                                  usbDevice,                        // service
                                                  kIOGeneralInterest,               // interestType
                                                  DeviceNotification,               // callback
                                                  deviceDataRef,                    // refCon
                                                  &(deviceDataRef->notification)    // notification
                                                  );
        }
        
        // Done with this USB device; release the reference added by IOIteratorNext
        kr = IOObjectRelease(usbDevice);
    }
}

void DeviceNotification(void *refCon, io_service_t service, natural_t messageType, void *messageArgument)
{
    kern_return_t   kr;
    DeviceData   *deviceDataRef = (DeviceData *) refCon;
    
    // device was disconnected
    if (messageType == kIOMessageServiceIsTerminated)
    {
        kr = IOObjectRelease(deviceDataRef->notification);
        
        AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
        [appDelegate updateDeviceDict:(__bridge NSString *)(deviceDataRef->deviceSerialNum) :(__bridge NSString *)(deviceDataRef->deviceName) : NO];

        free(deviceDataRef);
    }
}


-(void) updateDeviceDict: (NSString *) deviceSerial : (NSString *) deviceName : (bool) keepDevice
{
    NSString *key = [NSString stringWithFormat:@"%@%@", deviceName, deviceSerial];
    
    // if the device needs to be added
    if (keepDevice)
    {
        if (![self.deviceDictionary objectForKey:key])
        {
            NSDictionary *keyValue = [NSDictionary dictionaryWithObjectsAndKeys:deviceName, @"Name", deviceSerial, @"Serial", nil];
            [self.deviceDictionary setObject:keyValue forKey:key];
        }
    }
    
    // if the device needs to be removed
    else
    {
        [self.deviceDictionary removeObjectForKey:key];
        //NSLog(@"Device removed: %@", key);
    }
        
    // update the device picker in the trigger config window
    [self.deviceButton removeAllItems];
    
    if (self.deviceDictionary.count != 0)
    {
        for (id key in self.deviceDictionary)
        {
            NSDictionary *subDict = [self.deviceDictionary objectForKey:key];
            
            if (![[subDict objectForKey:@"Serial"] isEqualTo: [subDict objectForKey:@"Name"]])
            {
                [self.deviceButton addItemWithTitle:
                 [NSString stringWithFormat:@"%@ (%@)", [subDict objectForKey:@"Name"], [subDict objectForKey:@"Serial"]]];
                //NSLog(@"Device added: %@", key);
            }
            else
            {
                [self.deviceButton addItemWithTitle:[subDict objectForKey:@"Name"]];
                //NSLog(@"Device added: %@", key);
            }
        }
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    // Insert code here to tear down your application
}

@end
