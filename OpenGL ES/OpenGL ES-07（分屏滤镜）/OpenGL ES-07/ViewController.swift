//
//  ViewController.swift
//  OpenGL ES-07
//
//  Created by Mac on 2022/8/18.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet var renderView: DDView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func buttonDidClicked(_ sender: UIButton) {
        var frameShader = ""
        switch sender.tag {
        case 1000:
            frameShader = "shader2f.fsh"
        case 1001:
            frameShader = "shader3f.fsh"
        case 1002:
            frameShader = "shader4f.fsh"
        case 1003:
            frameShader = "shader6f.fsh"
        case 1004:
            frameShader = "shader9f.fsh"
        default:
            break
        }
        renderView.compileAndLinkShader(frameShader)
        renderView.renderLayer()
    }
    
}

