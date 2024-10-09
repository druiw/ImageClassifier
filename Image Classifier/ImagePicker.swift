// ImagePicker.swift
//
//  Image Classifier
//
//  Created by Drew Igoe on 10/8/24.
//

import SwiftUI
import CoreML
import Vision
import PhotosUI

struct ImagePickerView: View { // Rename this from ContentView to ImagePickerView
    @State private var image: UIImage? = nil
    @State private var showImagePicker: Bool = false
    @State private var classificationLabel: String = "Waiting for classification..."
    
    var body: some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                
                Text(classificationLabel)
                    .font(.headline)
                    .padding()
            } else {
                Text("Select an Image")
                    .font(.headline)
            }
            
            Button("Choose Image") {
                showImagePicker = true
            }
            .padding()
        }
        .sheet(isPresented: $showImagePicker, onDismiss: {
            if let image = image {
                classifyImage(image)
            }
        }) {
            ImagePicker(image: $image)
        }
    }
    
    func classifyImage(_ image: UIImage) {
        guard let ciImage = CIImage(image: image) else {
            fatalError("Couldn't convert UIImage to CIImage")
        }
        
        // Load the CoreML model
        guard let model = try? VNCoreMLModel(for: MobileNetV2().model) else {
            fatalError("Failed to load model")
        }
        
        // Create a request using the model
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Failed to classify image")
            }
            
            if let firstResult = results.first {
                DispatchQueue.main.async {
                    classificationLabel = "Classification: \(firstResult.identifier) - Confidence: \(firstResult.confidence * 100)%"
                }
            }
        }
        
        // Perform the request
        let handler = VNImageRequestHandler(ciImage: ciImage)
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform classification: \(error.localizedDescription)")
            }
        }
    }
}

// ImagePicker struct for selecting images
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            if let result = results.first {
                result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                    if let image = object as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.image = image
                        }
                    }
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
}

#Preview {
    ImagePickerView() // Ensure the preview is updated to use the renamed struct
}

