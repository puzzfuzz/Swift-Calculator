//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Christopher Puzzo on 4/26/15.
//  Copyright (c) 2015 Christopher Puzzo. All rights reserved.
//

import Foundation

class CalculatorBrain: Printable {
    
    private enum Op: Printable {
        
        case Consant(String, Double)
        case Operand(Double)
        case Variable(String)
        case UnaryOperation(String, Double -> Double)
        case BinaryOperation(String, Int, (Double, Double) -> Double)
        
        var description: String {
            get {
                switch self {
                case .Consant(let symbol, _):
                    return symbol
                case .Operand(let operand):
                    return "\(operand)"
                case .Variable(let symbol):
                    return symbol
                case .UnaryOperation(let symbol, _):
                    return symbol
                case .BinaryOperation(let symbol, _, _):
                    return symbol
                }
            }
        }
    }
    
    private var opStack = [Op]()
    
    private var knownOps = [String:Op]()
    
    var variableValues = [String:Double]()
    
    init() {
        func learnOp(op: Op) {
            knownOps[op.description] = op
        }
        learnOp(Op.Consant("π", M_PI))
        learnOp(Op.BinaryOperation("✕", 1, *))
        learnOp(Op.BinaryOperation("÷", 1) { $1 / $0 })
        learnOp(Op.BinaryOperation("-", 0) { $1 - $0 })
        learnOp(Op.BinaryOperation("+", 0, +))
        learnOp(Op.UnaryOperation("√", sqrt))
        learnOp(Op.UnaryOperation("sin", sin))
        learnOp(Op.UnaryOperation("cos", cos))
    }

    /*************** Primary Operation API ***************/
    
    func pushOperand(operand: Double) -> Double? {
        opStack.append(Op.Operand(operand))
        return evaluate()
    }
    
    func pushOperand(symbol: String) -> Double? {
        opStack.append(Op.Variable(symbol))
        return evaluate()
    }
    
    func performOperation(symbol: String) -> Double? {
        if let operation = knownOps[symbol] {
            opStack.append(operation)
        }
        return evaluate()
    }
    
    func evaluate() -> Double? {
        let (result, remainder) = evaluate(opStack)
        println("\(opStack) = \(result) with \(remainder) left over")
        return result
    }
    
    private func evaluate(ops: [Op]) -> (result: Double?, remainingOps: [Op]) {
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            
            switch op {
            case .Consant(_, let operand):
                return (operand, remainingOps)
            case .Operand(let operand):
                return (operand, remainingOps)
            case .Variable(let symbol):
                if let variable = variableValues[symbol] {
                    return (variable, remainingOps)
                }
            case .UnaryOperation(_, let operation):
                let operandEvaluation = evaluate(remainingOps)
                if let op1 = operandEvaluation.result {
                    return (operation(op1), operandEvaluation.remainingOps)
                }
            case .BinaryOperation(_, _, let operation):
                let operandEvaluation1 = evaluate(remainingOps)
                if let op1 = operandEvaluation1.result {
                    let operandEvaluation2 = evaluate(operandEvaluation1.remainingOps)
                    if let op2 = operandEvaluation2.result {
                        return (operation(op1, op2), operandEvaluation2.remainingOps)
                    }
                }
            }
        }
        
        
        return (nil, ops)
    }
    
    /*************** Model state maintenance ***************/
    
    func reset() {
        clearOpStack()
        cearVariables()
    }
    
    func clearOpStack() {
        opStack = [Op]()
    }
    
    func cearVariables() {
        variableValues = [String:Double]()
    }
    
    func undoOp() {
        if !opStack.isEmpty {
            opStack.removeLast()
        }
    }
    
    // *************** CalculatorBrain Description ***************
    
    var description: String {
        get {
            return describe(opStack) + " ="
        }
    }
    
    private func describe(ops: [Op]) -> String {
        var expressions = [String]()
        var remainingOps = ops
        while !remainingOps.isEmpty {
            let op = remainingOps.removeLast()
            
            var (result, remaining) = describe(op, opStack: remainingOps)
            if result != nil {
                expressions.append(result!)
            }
            remainingOps = remaining
        }
        
        return "\(expressions)".stringByReplacingOccurrencesOfString("[", withString: "").stringByReplacingOccurrencesOfString("]", withString: "")
    }
    
    private func describe(op: Op, opStack: [Op]) -> (description: String?, remainingOps: [Op]) {
        var remainingOps = opStack
        switch op {
        case .Consant(let symbol, _):
            return (symbol, remainingOps)
        case .Variable(let symbol):
            return (symbol, remainingOps)
        case .Operand(let value):
            return ("\(value)", remainingOps)
        case .UnaryOperation(let symbol, _):
            if !remainingOps.isEmpty {
                let term = remainingOps.removeLast()
                let termDescriptionResult = describe(term, opStack: remainingOps)
                if let description = termDescriptionResult.description {
                    return ("\(op)(\(description))", termDescriptionResult.remainingOps)
                }
            }
            //fallthrough for empty opstack or no valid description on remaining stack
            return ("\(op)(?)", remainingOps)
        case .BinaryOperation(let opSymbol, let opWeight, _):
            //used to output terms in the correct order
            var term1Str = "", term2Str = ""

            // To describe a binary opperation, we need to know what the two terms are
            //  to determine if either term needs perens around it to solve order-of-operation ambiguity
            if !remainingOps.isEmpty {
                let term1 = remainingOps.removeLast()
                let term1DescriptionResult = describe(term1, opStack: remainingOps)
                if let description1 = term1DescriptionResult.description {
                    //default
                    term1Str = description1
                    term2Str = "?"
                    
                    remainingOps = term1DescriptionResult.remainingOps

                    if !remainingOps.isEmpty {
                        let term2 = remainingOps.removeLast()
                        let term2DescriptionResult = describe(term2, opStack: remainingOps)
                        
                        if let description2 = term2DescriptionResult.description {
                            remainingOps = term2DescriptionResult.remainingOps
                        
                            //have both terms, check if we should add perens around either term
                            switch term1 {
                            case .Consant, .Variable, .Operand, .UnaryOperation:
                                // ex: π + ?, x * ?, ? - 2.5, ? / cos(90)
                                // no perens needed
                                term1Str = description1
                            case .BinaryOperation(let term1Symbol, let term1Weight, _):
                                // ex: (4+3) + ?, (4-3) * ?, etc.
                                // if operation weights are equiv, no perens needed.

                                if opWeight != term1Weight {
                                    term1Str = "(\(description1))"
                                } else {
                                    term1Str = description1
                                }
                            }
                            
                            switch term2 {
                            case .Consant, .Variable, .Operand, .UnaryOperation:
                                // ex: ? + π, ? * cos(90), etc
                                // no perens needed
                                term2Str = description2
                            case .BinaryOperation(let term2Symbol, let term2Weight, _):
                                // ex: ? * (4+3), ? + (4-3)
                                // if operation weights are equiv, no perens needed.
                                if opWeight != term2Weight {
                                    term2Str = "(\(description2))"
                                } else {
                                    term2Str = description2
                                }
                            }
                        }
                    }
                    
                    return ("\(term2Str)\(op)\(term1Str)", remainingOps)
                } // no term 1, didn't bother checking term 2
            }
            //fallthrough for empty opstack or no valid description on remaining stack
            return ("?\(op)?", remainingOps)
        }
    }
}