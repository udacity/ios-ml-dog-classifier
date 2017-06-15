//
//  ClassifyVideoView.swift
//  DogBreedPrediction
//
//  Created by Jarrod Parkes on 6/15/17.
//  Copyright © 2017 Udacity. All rights reserved.
//

import UIKit

// MARK: - ClassifyVideoViewDelegate

protocol ClassifyVideoViewDelegate {
    func closeButtonPressed()
}

// MARK: - ClassifyVideoView: UIView

class ClassifyVideoView: UIView {
    
    // MARK: Properties
    
    var delegate: ClassifyVideoViewDelegate?
    
    let previewView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .white
        return view
    }()
    
    let closeButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setImage(#imageLiteral(resourceName: "close"), for: .normal)
        button.addTarget(self, action: #selector(close), for: .touchUpInside)
        return button
    }()
    
    let predictionView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        view.backgroundColor = view.backgroundColor?.withAlphaComponent(0.5)
        return view
    }()
    
    let predictionLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = .white
        label.numberOfLines = 100
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        return label
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
            
    @objc private func close() {
        delegate?.closeButtonPressed()        
    }
    
    // MARK: Setup
    
    func addSubviews() {
        previewView.addSubview(closeButton)
        addSubview(previewView)
        
        predictionView.addSubview(predictionLabel)
        addSubview(predictionView)
    }
    
    func setupConstraints() {
        let views: [String: AnyObject] = [
            "previewView": previewView,
            "closeButton": closeButton,
            "predictionView": predictionView,
            "predictionLabel": predictionLabel
        ]
        
        // NOTE: The autoresizing mask constraints fully specify the view’s size and position; therefore, you cannot add additional constraints to modify this size or position without introducing conflicts [which is why set it to `false`].
        for value in views.values {
            if let view = value as? UIView {
                view.translatesAutoresizingMaskIntoConstraints = false
            }
        }
        
        let visualFormatConstraints = [
            "H:|[previewView]|",
            "H:|-4-[predictionView]-4-|",
            "H:[closeButton(48)]-16-|",
            "H:|-16-[predictionLabel]-16-|",
            "V:|[previewView]|",
            "V:[predictionView]-4-|",
            "V:|-32-[closeButton(48)]",
            "V:|-16-[predictionLabel]-16-|"
        ]
        for visualFormatConstraint in visualFormatConstraints {
            let constaints = NSLayoutConstraint.constraints(withVisualFormat: visualFormatConstraint, options: NSLayoutFormatOptions(), metrics: nil, views: views)
            addConstraints(constaints)
        }
    }
    
    // MARK: Modify Contents
    
    func updatePredictionLabel(withText text: String) {
        predictionLabel.text = text
    }
}
