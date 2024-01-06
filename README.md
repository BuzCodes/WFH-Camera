# WFH Camera
> Protect your privacy during video calls! WFH Camera is a virtual camera plugin for MacOS that automatically shuts down your camera feed when a person walks into the frame, ensuring you're never caught off guard.

## Features

- [x] Protective Camera Shutdown: Automatically pauses the camera feed when human presence is detected, safeguarding your privacy.
- [x] Real-Time Human Detection: Leverages Apple's Vision framework for accurate and efficient human detection.
- [x] Seamless Integration: Works with any app that uses your camera, including Zoom, FaceTime, Skype, and more.
- [x] Native Performance: Built with Swift and Objective-C, using CoreMediaIO DAL and Vision for optimal performance.
- [x] Zero External Dependencies: Functions entirely with Apple's native frameworks, ensuring reliability and security.

#### 🔨 Technologies: Swift, Objective-C, Vision, CoreMediaIO, No Third Party libraries.
####  🚀Platform: 🖥️ MacOS

## Getting Started

1. Build the Project: Open the project in Xcode and build it.
2. Locate the Plugin: Right-click on Products/WFHCam.plugin in Xcode and select "Show in Finder."
3. Install the Plugin: Copy WFHCam.plugin into /Library/CoreMediaIO/Plug-Ins/DAL.
4. Choose WFH Camera: Open any app that uses your camera and select "WFHCam" as the input source.

## Credits
Based on the excellent work of johnboiles/coremediaio-dal-minimal-example.

##  Contributing
We welcome contributions! Feel free to submit pull requests or open issues for feedback and suggestions.

## Thanks for stopping by!
