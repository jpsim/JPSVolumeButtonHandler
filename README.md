# JPSVolumeButtonHandler

`JPSVolumeButtonHandler` provides an easy block interface to hardware volume buttons on iOS devices. Perfect for camera apps! Used in [`JPSImagePickerController`](https://github.com/jpsim/JPSImagePickerController).

Features:

* Run blocks whenever a hardware volume button is pressed
* Volume button presses don't affect system audio
* Hide the HUD typically displayed on volume button presses
* Works even when the system audio level is at its maximum or minimum, even when muted

## Installation

### From CocoaPods

Add `pod 'JPSVolumeButtonHandler'` to your Podfile.

### Manually

Drag the `JPSVolumeButtonHandler` folder into your project and link the MediaPlayer and AVFoundation frameworks to your project.

## Usage

Set your blocks to be run when the volume buttons are pressed:

```objective-c
self.volumeButtonHandler = [JPSVolumeButtonHandler volumeButtonHandlerWithUpBlock:^{
	// Volume Up Button Pressed
} downBlock:^{
	// Volume Down Button Pressed
}];
```

## License

This project is under the MIT license.
