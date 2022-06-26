//: A UIKit based Playground for presenting user interface

import SwiftUI
import PlaygroundSupport
import AVFoundation

// Present the view controller in the Live View window
PlaygroundPage.current.setLiveView(MainView())

struct MainView: View {
    var body: some View {
        QrCodeScannerView(onCodeFound: { print($0) })
            .frame(width: 390, height: 844)
    }
}

struct QrCodeScannerView: UIViewRepresentable {
    typealias UIViewType = QrCodeScannerUIView

    let onCodeFound: (String) -> Void

    func makeUIView(context: Context) -> UIViewType {
        let view = UIViewType()
        view.metadataOutputDelegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeFound: onCodeFound)
    }
}

extension QrCodeScannerView {
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var onCodeFound: ((String) -> Void)?

        var lastCodeCaptureTime: TimeInterval?
        let codeResultTimeSpan: TimeInterval = 1       // send scanned value after 1s from the last result (to reduce amount of calls)

        init(onCodeFound: ((String) -> Void)?) {
            self.onCodeFound = onCodeFound
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard let qrMetadata = metadataObjects.compactMap({ $0 as? AVMetadataMachineReadableCodeObject }).first else { return }
            guard let value = qrMetadata.stringValue, !value.isEmpty else { return }

            // drop any results in next ``codeResultTimeSpan`` after the last code was found
            let captureTime = Date.timeIntervalSinceReferenceDate
            guard captureTime - (lastCodeCaptureTime ?? 0) >= codeResultTimeSpan else { return }

            lastCodeCaptureTime = captureTime
            DispatchQueue.main.async { [weak self] in
                self?.onCodeFound?(value)
            }
        }
    }
}

class QrCodeScannerUIView: UIView {

    weak var metadataOutputDelegate: AVCaptureMetadataOutputObjectsDelegate?

    let session = AVCaptureSession()
    let metadataOutput = AVCaptureMetadataOutput()

    // A queue for communicating with the session and other session objects on this queue.
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

    deinit {
        sessionQueue.async { [session] in
            session.stopRunning()
        }
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
