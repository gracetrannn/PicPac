//
//  AsyncOperation.swift
//

import Foundation

open class AsyncOperation: Operation {
    
    // MARK: - Public enum
    
    public enum State: String {
        
        case isReady = "isReady"
        case isExecuting = "isExecuting"
        case isFinished = "isFinished"
    }
    
    // MARK: - Public var
    
    public var state = State.isReady {
        willSet {
            willChangeValue(forKey: newValue.rawValue)
            willChangeValue(forKey: state.rawValue)
        }
        didSet {
            didChangeValue(forKey: oldValue.rawValue)
            didChangeValue(forKey: state.rawValue)
        }
    }
    
    // MARK: - Public override var
    
    public override var isReady: Bool {
        return super.isReady && state == .isReady
    }
    
    public override var isExecuting: Bool {
        return state == .isExecuting
    }
    
    public override var isFinished: Bool {
        return state == .isFinished
    }
    
    public override var isAsynchronous: Bool {
        return true
    }
    
    // MARK: - Public override func
    
    public override func start() {
        if isCancelled {
            state = .isFinished
            return
        }
        main()
        state = .isExecuting
    }
    
    public override func cancel() {
        super.cancel()
        state = .isFinished
    }
}
