# usbDeviceWatcher
Sample project to illustrate crash issue with USB hubs and possible memory leak.


Upon building and running this project, connecting, then disconnecting some USB hubs will cause the app to crash. While not for certain, hubs with 7 or more ports that use an external power source seem especially problematic.

Appears to be a memory management issue.

Example crash report:

Date/Time: 2018-09-26 18:41:39.833 -0700
OS Version: Mac OS X 10.12.6 (16G1510)
Report Version: 12
Anonymous UUID: 87E75CB8-B8BD-AA42-56E3-0ED60E840A77

Sleep/Wake UUID: CF89845D-A151-40FD-97D6-CC95E4B38071

Time Awake Since Boot: 66000 seconds
Time Since Wake: 19000 seconds

System Integrity Protection: enabled

Crashed Thread: 0 Dispatch queue: com.apple.main-thread

Exception Type: EXC_BAD_ACCESS (SIGSEGV)
Exception Codes: KERN_INVALID_ADDRESS at 0x000021abb79ebec8
Exception Note: EXC_CORPSE_NOTIFY

Termination Signal: Segmentation fault: 11
Termination Reason: Namespace SIGNAL, Code 0xb
Terminating Process: exc handler [0]

VM Regions Near 0x21abb79ebec8:
    mapped file 000000010d6c7000-000000010e961000 [ 18.6M] rw-/rwx SM=COW  
--> 
    MALLOC_NANO 0000600000000000-0000600000600000 [ 6144K] rw-/rwx SM=PRV  

Thread 0 Crashed:: Dispatch queue: com.apple.main-thread
0 libobjc.A.dylib 0x00007fffae760f31 objc_retain + 33
1 com.if.Amphetamine 0x0000000102314de6 0x1022e3000 + 204262
2 com.if.Amphetamine 0x000000010231495b 0x1022e3000 + 203099
3 com.apple.framework.IOKit 0x00007fff9b8116b1 IODispatchCalloutFromCFMessage + 308
4 com.apple.CoreFoundation 0x00007fff998bc213 __CFMachPortPerform + 291
5 com.apple.CoreFoundation 0x00007fff998bc0d9 __CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE1_PERFORM_FUNCTION__ + 41
6 com.apple.CoreFoundation 0x00007fff998bc051 __CFRunLoopDoSource1 + 465
7 com.apple.CoreFoundation 0x00007fff998b3cc5 __CFRunLoopRun + 2389
8 com.apple.CoreFoundation 0x00007fff998b3114 CFRunLoopRunSpecific + 420
9 com.apple.HIToolbox 0x00007fff98e13ebc RunCurrentEventLoopInMode + 240
10 com.apple.HIToolbox 0x00007fff98e13cf1 ReceiveNextEventCommon + 432
11 com.apple.HIToolbox 0x00007fff98e13b26 _BlockUntilNextEventMatchingListInModeWithFilter + 71
12 com.apple.AppKit 0x00007fff973aaa54 _DPSNextEvent + 1120
13 com.apple.AppKit 0x00007fff97b267ee -[NSApplication(NSEvent) _nextEventMatchingEventMask:untilDate:inMode:dequeue:] + 2796
14 com.apple.AppKit 0x00007fff9739f3db -[NSApplication run] + 926
15 com.apple.AppKit 0x00007fff97369e0e NSApplicationMain + 1237
16 libdyld.dylib 0x00007fffaf055235 start + 1

Thread 1:: com.apple.NSEventThread
0 libsystem_kernel.dylib 0x00007fffaf17c34a mach_msg_trap + 10
1 libsystem_kernel.dylib 0x00007fffaf17b797 mach_msg + 55
2 com.apple.CoreFoundation 0x00007fff998b4434 __CFRunLoopServiceMachPort + 212
3 com.apple.CoreFoundation 0x00007fff998b38c1 __CFRunLoopRun + 1361
4 com.apple.CoreFoundation 0x00007fff998b3114 CFRunLoopRunSpecific + 420
5 com.apple.AppKit 0x00007fff974f7f02 _NSEventThread + 205
6 libsystem_pthread.dylib 0x00007fffaf26e93b _pthread_body + 180
7 libsystem_pthread.dylib 0x00007fffaf26e887 _pthread_start + 286
8 libsystem_pthread.dylib 0x00007fffaf26e08d thread_start + 13

Thread 2:
0 libsystem_kernel.dylib 0x00007fffaf18444e __workq_kernreturn + 10
1 libsystem_pthread.dylib 0x00007fffaf26e48e _pthread_wqthread + 1023
2 libsystem_pthread.dylib 0x00007fffaf26e07d start_wqthread + 13

Thread 3:
0 libsystem_kernel.dylib 0x00007fffaf18444e __workq_kernreturn + 10
1 libsystem_pthread.dylib 0x00007fffaf26e621 _pthread_wqthread + 1426
2 libsystem_pthread.dylib 0x00007fffaf26e07d start_wqthread + 13

Thread 0 crashed with X86 Thread State (64-bit):
  rax: 0xbadda1abb79ebead rbx: 0x000060800010ca80 rcx: 0x000021abb79ebea8 rdx: 0x000061800003c060
  rdi: 0x000061800003c060 rsi: 0x000000010239ce94 rbp: 0x00007fff5d91a1a0 rsp: 0x00007fff5d91a1a0
   r8: 0x0000000000000000 r9: 0x0000000000000000 r10: 0x00000001023d3a40 r11: 0x00007f8c6f12bf40
  r12: 0x000061800003c060 r13: 0x00007fff5d91b600 r14: 0x0000000000000000 r15: 0x00007fffae760f10
  rip: 0x00007fffae760f31 rfl: 0x0000000000010202 cr2: 0x000021abb79ebec8
  
Logical CPU: 2
Error Code: 0x00000004
Trap Number: 14

