//
//  ContentView.swift
//  C2PA
//
//  Created by Christian Chartier on 2024-02-07.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject var cameraViewModel = CameraViewModel()

    var body: some View {
        ZStack {
            // This will be the camera feed layer
            CameraPreview(cameraViewModel: cameraViewModel)
                .ignoresSafeArea(.all, edges: .all)

            VStack {
                Spacer()
                
                // Capture button
                Button(action: {
                    cameraViewModel.capturePhoto()
                }) {
                    Image(systemName: "camera.circle")
                        .font(.system(size: 70))
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.7))
                        .clipShape(Circle())
                }
                .padding(.bottom)
            }
        }
        .onAppear {
            cameraViewModel.setup()
        }
    }
}

// This is a placeholder for the camera preview
struct CameraPreview: UIViewRepresentable {
    @ObservedObject var cameraViewModel: CameraViewModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        cameraViewModel.previewLayer.frame = view.frame
        view.layer.addSublayer(cameraViewModel.previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

class CameraViewModel: NSObject, ObservableObject {
    // AVFoundation properties
    private let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private let queue = DispatchQueue(label: "camera.queue")

    // This will be the camera preview layer
    var previewLayer: AVCaptureVideoPreviewLayer
    
    override init() {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        super.init()
    }

    func setup() {
        // Check and request camera permissions
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.setupCamera()
                }
            }
        default:
            // Permission has been denied previously
            print("Camera access denied")
            return
        }
    }
    
    private func setupCamera() {
        // Configure the session with the output for capturing still photos.
        session.beginConfiguration()
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input),
              session.canAddOutput(output) else {
            print("Failed to set up device input or output")
            return
        }
        session.addInput(input)
        session.addOutput(output)
        session.commitConfiguration()
        
        previewLayer.videoGravity = .resizeAspectFill
        
        // Start the session on a background queue.
        queue.async {
            self.session.startRunning()
        }
    }
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        // Set the photo settings for capturing photos in JPEG format.
        settings.flashMode = .auto
        
        // Use maxPhotoDimensions instead of isHighResolutionPhotoEnabled for iOS 16.0 and later
        if #available(iOS 16.0, *) {
            settings.maxPhotoDimensions = CMVideoDimensions(width: 4032, height: 3024) // Set to your desired resolution
        } else {
            // For iOS versions before 16.0, isHighResolutionPhotoEnabled is still valid
            settings.isHighResolutionPhotoEnabled = true
        }
        
        // Call the capturePhoto method by passing in your settings and a delegate.
        output.capturePhoto(with: settings, delegate: self)
    }

}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            return
        }
        guard let imageData = photo.fileDataRepresentation() else {
            print("Failed to get image data.")
            return
        }
        
        // Print out the size of the image data for debugging purposes
        print("Captured photo with size: \(imageData.count) bytes.")
        
        // Here is where you would integrate with the C2PA framework to embed the metadata
        // This is a placeholder to represent where you would do this.
        // The actual C2PA implementation will depend on the specific SDK or libraries you are using.
        
        // For demonstration, save image to photo library (this needs to run on main thread)
        DispatchQueue.main.async {
            let image = UIImage(data: imageData)
            UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
