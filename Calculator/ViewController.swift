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
    
    var displayResults: (result:Double?, error:CalculatorBrain.EvaluationException?) {
        get {
            return (displayValue, nil)
        }
        set {
            if let exception = newValue.error {
                display.text = stringForEvaluationException(exception)
            } else {
                displayValue = newValue.result
            }
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
        updateResult(true)
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
        updateResult(false)
    }
    
    @IBAction func memorySetTouched(sender: UIButton) {
        userIsTyping = false
        brain.variableValues["M"] = displayValue
        updateResult(false)
    }
    
    /****** FUNCTION and CONSTANT button handling ******/
    
    @IBAction func functionTouched(sender: UIButton) {
        if userIsTyping {
            enter()
        }
        if let operation = sender.currentTitle {
            brain.performOperation(operation)
            updateResult(true)
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
    
    @IBAction func enterTouched(sender: UIButton) {
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
            updateResult(shouldUpdateHistory)
        }
        
    }
    
    func updateHistory() {
        history.text! = "\(brain)"
    }
    
    func updateResult(shouldUpdateHistory: Bool) {
        displayResults = brain.evaluateAndReportErrors()
        if shouldUpdateHistory {
            updateHistory()
        }
    }
    
    /****** ERROR handling ******/
    
    func stringForEvaluationException (exception: CalculatorBrain.EvaluationException) -> String {
        switch exception {
        case .DivisionByZero:
            return "Error: Division by 0!"
        case .SquareRootOfNegativeNumber:
            return "Error: Squareroot of a negative value!"
        case .MissingOpperands:
            return "Error: Missing operand!"
        case .MissingVariable:
            return "Error: Variable value not set!"
        case .UnknownEvaluationException:
            return "Error: Unknown evaluation exception!"
        }
    }
}

