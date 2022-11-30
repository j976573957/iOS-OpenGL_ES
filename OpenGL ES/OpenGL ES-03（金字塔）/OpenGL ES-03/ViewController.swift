//
//  ViewController.swift
//  OpenGL ES-03
//
//  Created by Mac on 2022/8/9.
//

import UIKit

class ViewController: UIViewController {

    var myView: DDView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        myView = self.view as? DDView
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //解决模拟器第一次显示有问题
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.myView.resetDidClicked(UIButton())
        }
    }


}


