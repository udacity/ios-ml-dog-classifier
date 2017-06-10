//
//  ClassifyVC.swift
//  DogBreedPrediction
//
//  Created by Jarrod Parkes on 6/5/17.
//  Copyright © 2017 Udacity. All rights reserved.
//

import UIKit
import Photos

// MARK: - ClassifyVC: UIViewController

class ClassifyVC: UIViewController {
    
    // MARK: Properties
    
    let model = Resnet50()
    
    let classifyView: ClassifyView = {
        let view = ClassifyView(frame: .zero)
        return view
    }()
            
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        classifyView.delegate = self
        classifyView.frame = view.frame
        view.addSubview(classifyView)
    }
    
    // MARK: CoreML
    
    func processImageForPrediction(image: UIImage) {
        
        classifyView.changeDetailText(toText: "Processing image for classification...")
        
        // NOTE: Do pre-processing on background thread
        DispatchQueue.global(qos: .background).async {
            guard let normalizedImage = image
                .subtractMeanRGB(red: 103.939/255.0, green: 116.779/255.0, blue: 123.68/255.0)?
                .resize(newSize: CGSize(width: 224, height: 224))?
                .swapRedBlueChannels(), let imageData = normalizedImage.pixelBuffer(colorspace: .rgb) else {
                print("preprocessing failed")
                return
            }
            
            DispatchQueue.main.async {                
                self.predictUsingCoreML(imageData: imageData)
            }
        }
    }
    
    func predictUsingCoreML(imageData: CVPixelBuffer) {
        // FIXME: Ensure images are flipped upright? Possibly by using the vision framework!
        if let prediction = try? model.prediction(image: imageData) {
            let top5 = top(5, prediction.classLabelProbs)
            show(predictions: top5)
        } else {
            print("prediction failed")
        }
    }
    
    func show(predictions: [Prediction]) {
        var s: [String] = []
        for (i, prediction) in predictions.enumerated() {
            s.append(String(format: "%d: %@ (%3.2f%%)", i + 1, prediction.category, prediction.probability * 100))
        }
        classifyView.detailTextView.text = s.joined(separator: "\n\n")
    }
    
    func top(_ k: Int, _ prob: [String: Double]) -> [Prediction] {
        precondition(k <= prob.count)
        return Array(prob.map { x in Prediction(category: x.key, probability: x.value) }
            .sorted(by: { a, b -> Bool in a.probability > b.probability })
            .prefix(through: k - 1))
    }
}

// MARK: - ClassifyVC: ClassifyViewDelegate

extension ClassifyVC: ClassifyViewDelegate {
    func cameraButtonPressed() {
        openImagePicker(sourceType: .camera)
    }
    
    func photoLibraryButtonPressed() {
        openImagePicker(sourceType: .photoLibrary)
    }
    
    func videoButtonPressed() {
        present(ClassifyVideoVC(), animated: true, completion: nil)
    }
}

// MARK: - ClassifyVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate

extension ClassifyVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            classifyView.changeImage(image)
            processImageForPrediction(image: image)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: Helpers
    
    func openImagePicker(sourceType: UIImagePickerControllerSourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    func requestAccess() {
        PHPhotoLibrary.requestAuthorization { (status) in
            print(status)
        }
    }
}
