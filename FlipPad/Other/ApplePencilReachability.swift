//
//  ApplePencilReachability.swift
//  FlipPad
//
//  Created by zuzex on 06.12.2022.
//  Copyright © 2022 Alex. All rights reserved.
//

import Foundation
import CoreBluetooth

@objc class ApplePencilReachability: NSObject, CBCentralManagerDelegate {
    
    // MARK: -
    
//    @objc static var shared = ApplePencilReachability()
    
    private let centralManager = CBCentralManager()
    private var pencilAvailabilityDidChangeClosure: ((_ isAvailable: Bool) -> Void)?
    
    private var timer: Timer? {
        didSet {
            if oldValue !== timer { oldValue?.invalidate() }
        }
    }
    
    @objc public var isPencilAvailable = false {
        didSet {
            guard oldValue != isPencilAvailable else { return }
            pencilAvailabilityDidChangeClosure?(isPencilAvailable)
        }
    }
    
    // MARK: -
    
    override init() {
        super.init()
        centralManager.delegate = self
        centralManagerDidUpdateState(centralManager) // can be powered-on already?
    }
    deinit { timer?.invalidate() }
    
    
    // MARK: -
    
    internal func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {
                [weak self] timer in // break retain-cycle
                self?.checkAvailability()
                if self == nil { timer.invalidate() }
            }
        } else {
            timer = nil
            isPencilAvailable = false
        }
    }
    
    private func checkAvailability() {
        let peripherals = centralManager.retrieveConnectedPeripherals(withServices: [CBUUID(string: "180A")])
        let oldPencilAvailability = isPencilAvailable
        isPencilAvailable = peripherals.contains(where: { $0.name == "Apple Pencil" })
        if isPencilAvailable {
            timer = nil // only if you want to stop once detected
        }
    }
    
}
