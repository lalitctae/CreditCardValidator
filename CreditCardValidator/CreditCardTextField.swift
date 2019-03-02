//
//  CreditCardTextField.swift
//  CreditCardValidator
//
//  Created by Lalit Kumar on 16/02/19.
//  Copyright © 2019 Lalit. All rights reserved.
//

import UIKit

enum CardNumberState {
    case wrong
    case correct
    case notIdentified
}

enum CreditCardCompany: CaseIterable {
    case americanExpress
    case dinersClub
    case discover
    case instaPayment
    case jcb
    case maestro
    case masterCard
    case visa
    case notIdentified
    
    var name: String {
        switch self {
        case .americanExpress:
            return "American Express"
        case .dinersClub:
            return "Diners Club"
        case .discover:
            return "Discover"
        case .instaPayment:
            return "InstaPaymnet"
        case .jcb:
            return "JCB"
        case .maestro:
            return "Maestro"
        case .masterCard:
            return "MasterCard"
        case .visa:
            return "Visa"
        case .notIdentified:
            return ""
        }
    }
    
    var placeholder: String {
        switch self {
        case .americanExpress:
            return "XXXX XXXXXX XXXXX"
        case .dinersClub:
            return "XXXX XXXXXX XXXX"
        case .discover:
            return "XXXX XXXX XXXX XXXX"
        case .instaPayment:
            return "XXXX XXXX XXXX XXXX"
        case .jcb:
            return "XXXX XXXX XXXX XXXX"
        case .maestro:
            return "XXXX XXXX XXXX XXXX"
        case .masterCard:
            return "XXXX XXXX XXXX XXXX"
        case .visa:
            return "XXXX XXXX XXXX XXXX"
        case .notIdentified:
            return "XXXX XXXX XXXX XXXX"
        }
    }

    var prefixSet: Set<String> {
        switch self {
        case .americanExpress:
            return ["34", "37"]
        case .dinersClub:
            return ["300", "301", "302", "303", "304", "305", "36"]
        case .discover:
            var valueSet: Set<String> = ["6011", "644", "645", "646", "647", "648", "649", "65"]
            for value in 622126...622925 {
                valueSet.insert(String(value))
            }
            return valueSet
        case .instaPayment:
            return ["637", "638", "639"]
        case .jcb:
            var valueSet: Set<String> = []
            for value in 3528...3589 {
                valueSet.insert(String(value))
            }
            return valueSet
        case .maestro:
            return ["5018", "5020", "5038", "5893", "6304", "6759", "6761", "6762", "6763"]
        case .masterCard:
            var valueSet: Set<String> = ["51", "52", "53", "54", "55"]
            for value in 222100...272099 {
                valueSet.insert(String(value))
            }
            return valueSet
        case .visa:
            return ["4"]
        case .notIdentified:
            return [""]
        }
    }
}

protocol CreditCardDelegate: NSObjectProtocol {
    func cardState(_ status: CardNumberState)
    func cardCompany(_ companyName: String)
}

@IBDesignable
class CreditCardTextField: UITextField {
    @IBInspectable var placeholderColor: UIColor = UIColor.lightGray
    @IBInspectable var numberColor: UIColor = UIColor.black
    
    var index = 0
    weak var cardDelegate: CreditCardDelegate?
    var identifiedCompany: CreditCardCompany = .notIdentified {
        didSet {
            updatePlaceholderText()
            cardDelegate?.cardCompany(identifiedCompany.name)
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setupTextField()
    }
    
    func setupTextField() {
        tintColor = UIColor.clear
        textAlignment = .center
        keyboardType = .numberPad
        delegate = self
        text = "XXXX XXXX XXXX XXXX"
        textColor = placeholderColor
    }
    
    func updatePlaceholderText() {
        let enteredText = String(text?.prefix(index) ?? "")
        let placeholder = String(identifiedCompany.placeholder.dropFirst(index))
        text = enteredText + placeholder
    }

    func updateText(_ string: String) {
        guard let oldText = text else { return }
        if Int(strcmp(string.cString(using: String.Encoding.utf8), "\u{8}")) == -8 {
            if index == 0 {
                return
            }
            let x = Array(oldText)[index - 1] //Will not crash because we never called on -1
            if x == " " {
                index -= 1
            }
            text = oldText.prefix(index - 1) + "X" + oldText.dropFirst(index)
            index -= 1
            findCreditCardCompany(text ?? "", isBackspace: true)
            cardDelegate?.cardState(.notIdentified)
        }
        else {
            if index >= identifiedCompany.placeholder.count {
                return
            }
            text = oldText.prefix(index) + string + oldText.dropFirst(index + 1)
            index += 1
            
            if index < identifiedCompany.placeholder.count {
                let x = Array(oldText)[index] //Will not crash because will never called when index is equal to placeholder count
                if x == " " {
                    index += 1
                }
            }
            if index == identifiedCompany.placeholder.count {
                let cardNumber = text?.replacingOccurrences(of: " ", with: "") ?? ""
                let cardNumberState: CardNumberState = luhnCheck(cardNumber) ? .correct : .wrong
                cardDelegate?.cardState(cardNumberState)
            }
            else {
                cardDelegate?.cardState(.notIdentified)
            }
            findCreditCardCompany(text ?? "", isBackspace: false)
        }
        let attributedStr = NSMutableAttributedString(string: text ?? "")
        attributedStr.addAttribute(NSAttributedString.Key.foregroundColor, value: numberColor, range: NSRange(location: 0, length: index))
        attributedStr.addAttribute(NSAttributedString.Key.foregroundColor, value: placeholderColor, range: NSRange(location: index, length: identifiedCompany.placeholder.count - index))
        attributedText = attributedStr
    }
    
    /*
     The Luhn Formula:
     Drop the last digit from the number. The last digit is what we want to check against
     Reverse the numbers
     Multiply the digits in odd positions (1, 3, 5, etc.) by 2 and subtract 9 to all any result higher than 9
     Add all the numbers together
     The check digit (the last number of the card) is the amount that you would need to add to get a multiple of 10 (Modulo 10)
    */
    func luhnCheck(_ number: String) -> Bool {
        var sum = 0
        let reverseNumber = number.reversed().dropFirst()
        guard let lastNumber = number.last else {
            return false
        }
        let lastDigit = Int(String(lastNumber))
        let digitStrings = reverseNumber.map { String($0) }
        for (index, value) in digitStrings.enumerated() {
            if let digit = Int(value) {
                let odd = index % 2 == 1
                switch (odd, digit) {
                case (true, 9):
                    sum += 9
                case (true, 0...8):
                    sum += (digit * 2) % 9
                default:
                    sum += digit
                }
            } else {
                return false
            }
        }
        return sum % 10 == lastDigit
    }
    
    func possibleCards(fromStartingDigits value: Int) -> [CreditCardCompany] {
        var companies: [CreditCardCompany] = []
        switch value {
        case 1:
            companies = [.visa]
        case 2:
            companies = [.americanExpress, .dinersClub, .masterCard, .discover]
        case 3:
            companies = [.dinersClub, .discover, .instaPayment]
        case 4:
            companies = [.discover, .jcb]
        case 6:
            companies = [.discover, .masterCard]
        default:
            companies = []
        }
        return companies
    }
    
    func findCreditCardCompany(_ string: String, isBackspace: Bool) {
        if identifiedCompany == .notIdentified && !isBackspace {
            let numberString = String(string.prefix(index)).replacingOccurrences(of: " ", with: "")
            let companies = possibleCards(fromStartingDigits: numberString.count)
            
            for company in companies {
                if company.prefixSet.contains(numberString) {
                    identifiedCompany = company
                    break
                }
            }
        }
        else if identifiedCompany != .notIdentified && isBackspace {
            let numberString = String(string.prefix(index)).replacingOccurrences(of: " ", with: "")
            var flag = false
            for values in identifiedCompany.prefixSet {
                if numberString.contains(values) {
                    flag = true
                }
            }
            if !flag {
                identifiedCompany = .notIdentified
            }
        }
    }
}

extension CreditCardTextField: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        updateText(string)
        return false
    }
}
