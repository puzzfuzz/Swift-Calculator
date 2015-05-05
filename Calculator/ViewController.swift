//
//  ViewController.swift
//  Calculator
//
//  Created by Christopher Puzzo on 4/25/15.
//  Copyright (c) 2015 Christopher Puzzo. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var history: UILabel!

    var brain = CalculatorBrain()
    
    var userIsTyping = false

    // Handles conversion to/from Double for primary display
    var displayValue: Double? {
        get {
            if let num = NSNumberFormatter().numberFromString(display.text!) {
                return num.doubleValue
            }
            return nil
        }
        set {
            if newValue == nil {
                display.text = " "
            } else {
                display.text = "\(newValue!)"
            }
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
        brain.reset()
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
                userIsTyping = false
                display.text! = "0"
            }
        } else {
            undoOp()
        }
    }
    
    func undoOp() {
        brain.undoOp()
        displayValue = brain.evaluate()
        updateHistory()
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
    
    /****** NEGATION button handling ******/
    
    @IBAction func negationTouched(sender: UIButton) {
        //shortcircuit attempting to negate a 0
        if display.text! == "0" {
            return
        }
        
        if !userIsTyping {
            if let double = displayValue {
                displayValue = -double
                enter()
            }
        } else {
            if let idx = display.text!.rangeOfString("-") {
                display.text!.removeRange(idx)
            } else {
                display.text! = "-" + display.text!
            }
        }
    }
    
    @IBAction func memoryGetTouched(sender: UIButton) {
        if userIsTyping {
            enter()
        }
        brain.pushOperand("M")
        displayValue = brain.evaluate()
    }
    
    @IBAction func memorySetTouched(sender: UIButton) {
        userIsTyping = false
        brain.variableValues["M"] = displayValue
        displayValue = brain.evaluate()
    }
    
    /****** FUNCTION and CONSTANT button handling ******/
    
    @IBAction func functionTouched(sender: UIButton) {
        if userIsTyping {
            enter()
        }
        if let operation = sender.currentTitle {
            displayValue = brain.performOperation(operation)
            updateHistory()
        }
        
    }
    
    func enterConstant (constant: Double, withSymbol symbol:String) {
        if userIsTyping {
            enter()
        }
        display.text! = "\(constant)"
        updateHistory()
        enter(false)
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
        if let num = displayValue {
            displayValue = brain.pushOperand(num)

            if shouldUpdateHistory {
                updateHistory()
            }
        }
        
    }
    
    func updateHistory() {
        history.text! = "\(brain)"
    }
}

