//
//  ViewController.swift
//  Calculator
//
//  Created by Christopher Puzzo on 4/25/15.
//  Copyright (c) 2015 Christopher Puzzo. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let π = M_PI
    
    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var history: UILabel!
    
    var userIsTyping = false
    var opperandStack = [Double]()
    var opperandHistory = [String]()

    // Handles conversion to/from Double for primary display
    var displayValue: Double {
        get {
            return NSNumberFormatter().numberFromString(display.text!)!.doubleValue
        }
        set {
            display.text = "\(newValue)"
            userIsTyping = false
        }
    }
    
    /****** CLEAR button handling ******/
    
    @IBAction func clearTouched(sender: UIButton) {
        resetData()
        resetView()
    }
    
    func resetData() {
        userIsTyping = false
        opperandStack = [Double]()
        opperandHistory = [String]()
    }
    
    func resetView() {
        display.text! = "0"
        history.text! = " "
    }
    
    /****** BACK button handling ******/

    @IBAction func backTouched(sender: UIButton) {
        if userIsTyping {
            if count(display.text!) > 1 {
                display.text! = dropLast(display.text!)
            } else if count(display.text!) == 1 {
                display.text! = "0"
                userIsTyping = false
            }
        }
    }
    
    
    /****** NUMERIC button handling ******/
    
    @IBAction func numberTouched(sender: UIButton) {
        var number = sender.currentTitle!
        
        if !userIsTyping {
            display.text! = ""
            userIsTyping = true
        }
        display.text! += number

    }
    
    /****** DECIMAL point button handling ******/

    @IBAction func decimalTouched(sender: UIButton) {
        if display.text!.rangeOfString(".") == nil {
            display.text! += "."
            userIsTyping = true
        }
    }
    
    /****** ENTER button and opperand publishing / history handling ******/
    
    @IBAction func enterTouched(sender: AnyObject) {
        enter()
    }
    
    //Convenient overload
    func enter() {
        enter(true)
    }
    
    func enter (shouldUpdateHistory: Bool) {
        userIsTyping = false
        opperandStack.append(displayValue)
        println(opperandStack)
        if shouldUpdateHistory {
            updateHistory(display.text!)
        }
    }
    
    func updateHistory(op: String) {
        opperandHistory.append(op)
        history.text! = "\(opperandHistory)"
    }
    
    /****** FUNCTION and CONSTANT button handling ******/
    
    @IBAction func functionTouched(sender: UIButton) {
        let functionType = sender.currentTitle!
        if userIsTyping {
            enter()
        }

        switch functionType {
        case "✕": performOperation("✕") { $0 * $1 }
        case "÷": performOperation("÷") { $1 / $0 }
        case "-": performOperation("-") { $1 - $0 }
        case "+": performOperation("+") { $0 + $1 }
        case "√": performOperation("√") { sqrt($0) }
        case "sin": performOperation("sin") { sin($0) }
        case "cos": performOperation("cos") { cos($0) }
        case "π": enterConstant(π, withSymbol: "π")
        default: break
        }
        
    }
    
    func performOperation (symbol: String, operation: (Double, Double) -> Double) {
        if (opperandStack.count >= 2) {
            displayValue = operation(opperandStack.removeLast(), opperandStack.removeLast())
            enter(false)
            updateHistory(symbol)
            updateHistory("=")
        }
    }
    
    func performOperation (symbol: String, op: Double -> Double) {
        if (opperandStack.count >= 1) {
            displayValue = op(opperandStack.removeLast())
            enter(false)
            updateHistory(symbol)
            updateHistory("=")
        }
    }
    
    func enterConstant (constant: Double, withSymbol symbol:String) {
        if userIsTyping {
            enter()
        }
        display.text! = "\(constant)"
        updateHistory(symbol)
        enter(false)
    }
    
}

