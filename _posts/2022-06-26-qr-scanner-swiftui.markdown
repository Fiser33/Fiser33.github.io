---
title: "Create QR scanner for SwiftUI"
categories: SwiftUI
---

Back in 2019, SwiftUI was first introduced and this year Apple already announced version 4 on WWDC22. Even though it's been quite some time now, there are still some features missing and the only way is to backport to UIKit. If you have no experience with UIKit, you'll probably rather go with a framework (doing the same backport). Or it could be great opportunity to learn how it works and implement it on your own.

I would like to show you how to implement very simple QR code scanner in UIKit and use it from SwiftUI code.

Before we start with coding, we must set up new iOS project and have a real camera-capable Apple device. If you try to access camera on simulator, it results in app crash. In the existing project, we also need to add NSCameraUsageDescription key to Info.plist file. And now back to code.

# SwiftUI bridging component
To connect your UIKit implementation with SwiftUI, there are two essential protocols - _UIViewRepresentable_ for UIView class and _UIViewControllerRepresentable_ for UIViewController class. You should be often good with the first protocol, unless you are really required to work with controllers, like for image gallery picker or fullscreen video player.

There are two required methods for you to implement, one to create a UIKit object and other one to propagate any updates to it. If you are still unsure about your final implementation, it is usefull to explicitly state typealias for _UIViewType_ (another requirement usually resolved by compiler), it may save you some time in case of any renaming.

```swift
struct QrCodeScannerView: UIViewRepresentable {
    typealias UIViewType = QrCodeScannerUIView

    func makeUIView(context: Context) -> UIViewType {
        let view = UIViewType()
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
    }
}
```

These few lines of code create a component that can be used from SwiftUI code and allow us to instantiate UIKit class under the hood. This is the minimum implementation of _UIViewRepresentable_ protocol that will already allow us to see and test the UIKit class we're about to implement next.

# UIKit implementation
The UIKit implementation is no different from what you would have done in standard UIKit project. There are no special protocols, methods, properties. You just implement the functionlity. This is where one can leverage any prior UIKit experience.

At first, we'll just make the camera working to see something on screen, with no scanning yet.

```swift
class QrCodeScannerUIView: UIView {

    weak var metadataOutputDelegate: AVCaptureMetadataOutputObjectsDelegate?

    let session = AVCaptureSession()
    let metadataOutput = AVCaptureMetadataOutput()
    let sessionQueue = DispatchQueue(label: "session queue")
    let metadataObjectsQueue = DispatchQueue(label: "metadata objects queue")

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer? {
        layer as? AVCaptureVideoPreviewLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        sessionQueue.async {
            self.configure()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure() {
        session.beginConfiguration()

        if let device = AVCaptureDevice.default(for: .video), let deviceInput = try? AVCaptureDeviceInput(device: device), session.canAddInput(deviceInput) {
            session.addInput(deviceInput)
        }

        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(metadataOutputDelegate, queue: metadataObjectsQueue)
            metadataOutput.metadataObjectTypes = [.qr]
        }

        session.commitConfiguration()
        videoPreviewLayer?.session = session
        session.startRunning()
    }
}
```

Most of the code is related to camera initialization that I'm not going to explain here as there already exist many tutorials and it's not my main goal here.

I would only like to mention the _metadataOutputDelegate_ property that will be used to delegate _AVCaptureMetadataOutputObjectsDelegate_ calls. It will be used to handle scanner results and eventually pass them back to SwiftUI.

With this implementation, you should be able to see a camera preview already.

# Communication
So, now we have a SwiftUI component that creates a UIKit class to start and show camera. The only missing part is to establish communication between those two frameworks.

First, to get results from scanner, we have to implement _AVCaptureMetadataOutputObjectsDelegate_ protocol. As it extends from _NSObjectProtocol_, it can't be implemented by _QrCodeScannerView_ struct directly. It has to be a class.

Typically, we use _UIViewRepresentable.Coordinator_ to create a delegate object available for entire life cycle of the view. This coordinator will also propagate scanning result to SwiftUI. As this is just a one-way communication, we can use simple callback passing in a String value. We could use a Binding property otherwise.

Coordinator has to be defined as inner type of our _UIViewRepresentable_ implementation.

```swift
extension QrCodeScannerView {
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var onCodeFound: ((String) -> Void)?

        init(onCodeFound: ((String) -> Void)?) {
            self.onCodeFound = onCodeFound
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard let qrMetadata = metadataObjects.compactMap({ $0 as? AVMetadataMachineReadableCodeObject }).first else { return }
            guard let value = qrMetadata.stringValue, !value.isEmpty else { return }

            DispatchQueue.main.async { [weak self] in
                self?.onCodeFound?(value)
            }
        }
    }
}
```

Then, to create our Coordinator object, we implement a special method from _UIViewRepresentable_ protocol. This method is called automatically for us and our Coordinator object is then available from Context that is passed to other methods as parameter.

To connect all these pieces together, we just assign the Coordinator to metadataOutputDelegate on UIKit object creation.

```swift
struct QrCodeScannerView: UIViewRepresentable {
    var onCodeFound: ((String) -> Void)?

    func makeUIView(context: Context) -> UIViewType {
        let view = UIViewType()
        view.metadataOutputDelegate = context.coordinator
        return view
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeFound: onCodeFound)
    }
}
```

# Usage
At this point, everything is ready to be used from SwiftUI code. It is super easy, just like if you would use any other SwiftUI component.

```swift
struct MainView: View {
    var body: some View {
        QrCodeScannerView(onCodeFound: { print($0) })
            .frame(width: 390, height: 844)
    }
}
```

And the best part is that you can use SwiftUI view modifiers as usual, for example to set frame or add an overlay.

# Summary
That's it! We have created very simple QR code scanner in just about 100 lines. And it may be much less when iOS 16 is released with the new _DataScannerViewController_. So even though there are still some features missing in SwiftUI, it's not that difficult to combine it with UIKit.

And it's event easier if you have any prior experience with UIKit just like me. As for me personally, adding a framework for such a small implementation does not really pay off.

All code is available in the [repository](https://github.com/Fiser33/Fiser33.github.io/tree/main/examples/swiftui/qr_scanner).