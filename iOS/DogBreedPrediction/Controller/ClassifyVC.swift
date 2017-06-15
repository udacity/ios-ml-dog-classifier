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
    
    private let classifier = Classifier()
    private let classifyView: ClassifyView = {
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
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage, let cgImage = image.cgImage {
            classifyView.changeImage(image)
            classifyView.changeDetailText(toText: "Processing image for classification...")
            classifier.classifyImageWithVision(image: cgImage) { (predictionString, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        self.classifyView.detailTextView.text = error
                    } else {
                        self.classifyView.detailTextView.text = predictionString
                    }
                }
            }
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
}
