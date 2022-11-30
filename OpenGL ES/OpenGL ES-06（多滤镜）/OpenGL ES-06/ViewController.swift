//
//  ViewController.swift
//  OpenGL ES-06
//
//  Created by Mac on 2022/8/18.
//

import UIKit

class ViewController: UIViewController {

    
    @IBOutlet weak var ivImage: UIImageView!
    @IBOutlet weak var renderContainerView: GLContainerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.renderContainerView.image = UIImage(named: "Lena")
    }

//MARK: - 事件
    @IBAction func actionValueChanged(_ sender: UISlider) {
        self.renderContainerView.colorTempValue = CGFloat(sender.value)
        ivImage.image = self.renderContainerView.renderView.outImage
    }
    
    @IBAction func actionSaturationValueChanged(_ sender: UISlider) {
        self.renderContainerView.saturationValue = CGFloat(sender.value)
        ivImage.image = self.renderContainerView.renderView.outImage
    }

}

