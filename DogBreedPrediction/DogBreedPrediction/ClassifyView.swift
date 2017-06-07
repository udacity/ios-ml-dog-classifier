//
//  ClassifyView.swift
//  DogBreedPrediction
//
//  Created by Jarrod Parkes on 6/6/17.
//  Copyright © 2017 Udacity. All rights reserved.
//

import UIKit

// MARK: - ClassifyViewDelegate

protocol ClassifyViewDelegate {
    func cameraButtonPressed()
    func photoLibraryButtonPressed()
}

// MARK: - ClassifyView: UIView

class ClassifyView: UIView {
    
    // MARK: Properties
    
    var delegate: ClassifyViewDelegate?
    
    let dogStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 30
        return stackView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "Dog Classifier"
        label.font = UIFont.systemFont(ofSize: 27)
        label.textAlignment = .center
        return label
    }()
    
    let imageView: UIImageView = {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "dog"))
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .lightGray
        imageView.alpha = 0.3
        imageView.layer.cornerRadius = 20
        return imageView
    }()
    
    let detailTextView: UITextView = {
        let textView = UITextView(frame: .zero)
        textView.isEditable = false
        textView.text = "Take a picture or select an existing photo to begin classifying!"
        textView.font = UIFont.systemFont(ofSize: 14)
        return textView
    }()
    
    let toolbar: UIToolbar = {
        let toolbar = UIToolbar(frame: .zero)
        return toolbar
    }()
        
    let cameraButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: #imageLiteral(resourceName: "camera"), style: .plain, target: self, action: #selector(cameraButtonPressed))
        button.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        return button
    }()
    
    let photoLibraryButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: #imageLiteral(resourceName: "photos"), style: .plain, target: self, action: #selector(photoLibraryButtonPressed))
        return button
    }()
    
    // MARK: Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        addSubviews()
        setupConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: Actions
    
    @objc func cameraButtonPressed() {
        delegate?.cameraButtonPressed()
    }
    
    @objc func photoLibraryButtonPressed() {
        delegate?.photoLibraryButtonPressed()
    }
    
    // MARK: Setup
    
    func addSubviews() {
        dogStack.addArrangedSubview(titleLabel)
        dogStack.addArrangedSubview(imageView)
        dogStack.addArrangedSubview(detailTextView)
        addSubview(dogStack)
        
        toolbar.items = [
            cameraButton,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            photoLibraryButton
        ]
        addSubview(toolbar)
    }
    
    func setupConstraints() {
        let views: [String: AnyObject] = [
            "dogStack": dogStack,
            "toolbar": toolbar,
            "imageView": imageView
        ]
        
        // NOTE: The autoresizing mask constraints fully specify the view’s size and position; therefore, you cannot add additional constraints to modify this size or position without introducing conflicts [which is why set it to `false`].
        for value in views.values {
            if let view = value as? UIView {
                view.translatesAutoresizingMaskIntoConstraints = false
            }
        }
        
        let visualFormatConstraints = [
            "H:|-32-[dogStack]-32-|",
            "H:|[toolbar]|",
            "V:|-36-[dogStack]-[toolbar(48)]|",
            "V:[imageView(220)]"
        ]
        for visualFormatConstraint in visualFormatConstraints {
            let constaints = NSLayoutConstraint.constraints(withVisualFormat: visualFormatConstraint, options: NSLayoutFormatOptions(), metrics: nil, views: views)
            addConstraints(constaints)
        }
    }
    
    // MARK: Change Image
    
    func changeImage(_ image: UIImage) {
        imageView.alpha = 1.0
        imageView.backgroundColor = nil
        imageView.layer.cornerRadius = 0
        imageView.image = image
    }
}
