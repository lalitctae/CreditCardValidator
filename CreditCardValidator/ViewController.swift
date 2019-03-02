//
//  ViewController.swift
//  CreditCardValidator
//
//  Created by Lalit Kumar on 16/02/19.
//  Copyright © 2019 Lalit. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var cardTextField: CreditCardTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        cardTextField.cardDelegate = self
        cardTextField.becomeFirstResponder()
    }
}

extension ViewController: CreditCardDelegate {
    func cardState(_ status: CardNumberState) {
        if status == .wrong {
            messageLabel.text = "Card info not found."
        }
        else {
            messageLabel.text = ""
        }
    }
    
    func cardCompany(_ companyName: String) {
        companyNameLabel.text = companyName
    }
}
