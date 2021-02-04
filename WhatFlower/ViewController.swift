//
//  ViewController.swift
//  WhatFlower
//
//  Created by Victor Lee on 1/11/21.
//

import UIKit
import CoreML
import Vision
import SwiftyJSON
import Alamofire
import SDWebImage

class ViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet weak var flowerLabel: UILabel!
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    
    
    @IBOutlet weak var imageView: UIImageView!
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
    }
    
    
    @IBAction func photoButtonTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil    )
    }
}

extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            guard let ciImaeg = CIImage(image: userPickedImage) else {
                fatalError("Could not convert an Image")
            }
            detect(image: ciImaeg)
            
   
        }
        imagePicker.dismiss(animated: true, completion: nil )
        
    }
    
    func requestInfo(flowerName: String) {
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize": "500"
        ]
        
        AF.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            debugPrint(response)
            
            let flowerJSON: JSON = JSON(response.value!)
            
            let pageid = flowerJSON["query"]["pageids"][0].stringValue
            
            let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
            let flowerImageUrl = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
            
            self.imageView.sd_setImage(with: URL(string: flowerImageUrl), completed: nil)
            
            self.flowerLabel.text = flowerDescription
        }
    }
    
    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("cannot import a model")
        }
        let request = VNCoreMLRequest(model: model) { (request, error) in
            let classification = request.results?.first as? VNClassificationObservation
            
            self.navigationItem.title = classification?.identifier.capitalized
            self.requestInfo(flowerName: classification!.identifier)
            
        }
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        }catch {
            print(error)
        }
    }
}
