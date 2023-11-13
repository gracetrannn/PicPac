//
// Stylus.swift
//

import Foundation

@objc class Stylus: NSObject, Codable {
    
    // MARK: -
    
    private enum Key: CodingKey {
        
        case average
        case pressureSensitivity
        case baseHardness
        case lambda
        // TODO: -
    }
    
    // MARK: -
    
    @objc static var shared: Stylus = {
        let data = UserDefaults.standard.data(forKey: .stylusKey) ?? Data()
        return (try? JSONDecoder().decode(Stylus.self, from: data)) ?? .default
    }()
    
    fileprivate static var `default`: Stylus {
#if targetEnvironment(macCatalyst)
        let average: CGFloat = 0.0
        let pressureSensitivity: CGFloat = 5.0
        let baseHardness: CGFloat = 3.0
        let lambda: CGFloat = 0.8
#else
        let average: CGFloat = 1.0
        let pressureSensitivity: CGFloat = 5.0
        let baseHardness: CGFloat = 3.0
        let lambda: CGFloat = 0.8
#endif
        return Stylus(
            average: average,
            basePressureSensitivity: pressureSensitivity,
            baseHardness: baseHardness,
            lambda: lambda
            // TODO: -
        )
    }
    
    // MARK: -
    
    @objc var average: CGFloat {
        didSet {
            try? save()
        }
    }
    
    @objc var basePressureSensitivity: CGFloat {
        didSet {
            try? save()
        }
    }
    
    @objc var baseHardness: CGFloat {
        didSet {
            try? save()
        }
    }
    
    @objc var lambda: CGFloat {
        didSet {
            try? save()
        }
    }
    
    // TODO: -
    
    // MARK: -
    
    init(
        average: CGFloat,
        basePressureSensitivity: CGFloat,
        baseHardness: CGFloat,
        lambda: CGFloat
    ) {
        self.average = average
        self.basePressureSensitivity = basePressureSensitivity
        self.baseHardness = baseHardness
        self.lambda = lambda
        // TODO: -
        super.init()
    }
    
    // MARK: -
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        self.average = try container.decode(CGFloat.self, forKey: .average)
        self.basePressureSensitivity = try container.decode(CGFloat.self, forKey: .pressureSensitivity)
        self.baseHardness = try container.decode(CGFloat.self, forKey: .baseHardness)
        self.lambda = try container.decode(CGFloat.self, forKey: .lambda)
        // TODO: -
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        try container.encode(average, forKey: .average)
        try container.encode(basePressureSensitivity, forKey: .pressureSensitivity)
        try container.encode(baseHardness, forKey: .baseHardness)
        try container.encode(lambda, forKey: .lambda)
        // TODO: -
    }
    
    // MARK: -
    
    private func save() throws {
        let data = try JSONEncoder().encode(self)
        UserDefaults.standard.set(data, forKey: .stylusKey)
    }
}

private extension String {
    
    // MARK: -
    
    static var stylusKey: String {
        return "stylusKey"
    }
}

//
// StylusSettingsView.swift
//

import UIKit

class StylusSettingsView: DraggableView {
    
    @IBOutlet weak var averageTextField: UITextField!
    @IBOutlet weak var baseHardnessTextField: UITextField!
    @IBOutlet weak var lambdaTextField: UITextField!
    
    // TODO: -
    
    override func awakeFromNib() {
        super.awakeFromNib()
        averageTextField.text = "\(Stylus.shared.average)"
        baseHardnessTextField.text = "\(Stylus.shared.baseHardness)"
        lambdaTextField.text = "\(Stylus.shared.lambda)"
        // TODO: -
    }
    
    @IBAction func averageTextFieldHandler(_ sender: UITextField) {
        Stylus.shared.average = .cgFloat(sender.text ?? "") ?? Stylus.default.average
    }
    
    @IBAction func baseHardnessTextFieldHandler(_ sender: UITextField) {
        Stylus.shared.baseHardness = .cgFloat(sender.text ?? "") ?? Stylus.default.baseHardness
    }
    
    @IBAction func lambdaTextFieldHandler(_ sender: UITextField) {
        Stylus.shared.lambda = .cgFloat(sender.text ?? "") ?? Stylus.default.lambda
    }
    
    // TODO: -
}

private extension CGFloat {
    
    static func cgFloat(_ string: String) -> CGFloat? {
        if let float = Float(string) {
            return CGFloat(float)
        }
        return nil
    }
}
