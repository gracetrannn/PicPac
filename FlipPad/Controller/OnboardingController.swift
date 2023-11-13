//
//  OnboardingController.swift
//  FlipPad
//
//  Created by Alex Vihlayew on 12/7/20.
//  Copyright © 2020 Alex. All rights reserved.
//

import UIKit
import PDFKit

@objc protocol OnboardingDelegate {
    @objc func onboardingDidHide()
}

@objc class OnboardingController: UIViewController {

    @objc weak var delegate: OnboardingDelegate?
    
    private var images: [UIImage] = []
    private var selectedIndex: Int = 0
    
    private let containerView = { () -> UIView in
        let container = UIView()
        container.layer.cornerRadius = 8.0
        container.layer.masksToBounds = true
        return container
    }()
    private let exitButton = UIButton()
    private let imageScrollView = UIScrollView()
    private let previousButton = UIButton()
    private let nextButton = UIButton()
    private let closeButton = UIButton()
    
    private var circleStackView: UIStackView?
    private var circleViews: [UIView] = []
    
    let WIDTH: CGFloat = {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return UIScreen.main.bounds.width * 0.5
        }
        return UIScreen.main.bounds.width * 0.66
    }()
    lazy var HEIGHT: CGFloat = WIDTH * 3 / 4
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.clear
        containerView.backgroundColor = UIColor.white
        
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(exitButton)
        exitButton.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        exitButton.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        exitButton.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        exitButton.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        exitButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        containerView.widthAnchor.constraint(equalToConstant: WIDTH).isActive = true
        containerView.heightAnchor.constraint(equalToConstant: HEIGHT).isActive = true
        
        previousButton.setImage(UIImage(named: "previous"), for: .normal)
        nextButton.setImage(UIImage(named: "next"), for: .normal)
        closeButton.setImage(UIImage(named: "close"), for: .normal)
        
        previousButton.addTarget(self, action: #selector(previousSlide), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextSlide), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        
        imageScrollView.delegate = self
        imageScrollView.isPagingEnabled = true
        imageScrollView.translatesAutoresizingMaskIntoConstraints = false
        previousButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(imageScrollView)
        containerView.leftAnchor.constraint(equalTo: imageScrollView.leftAnchor).isActive = true
        containerView.rightAnchor.constraint(equalTo: imageScrollView.rightAnchor).isActive = true
        containerView.topAnchor.constraint(equalTo: imageScrollView.topAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: imageScrollView.bottomAnchor).isActive = true
        
        containerView.addSubview(previousButton)
        containerView.leftAnchor.constraint(equalTo: previousButton.leftAnchor).isActive = true
        
        containerView.addSubview(nextButton)
        containerView.rightAnchor.constraint(equalTo: nextButton.rightAnchor).isActive = true
        
        view.addSubview(closeButton)
        containerView.rightAnchor.constraint(equalTo: closeButton.centerXAnchor).isActive = true
        containerView.topAnchor.constraint(equalTo: closeButton.centerYAnchor).isActive = true
        
        for button in [previousButton, nextButton] {
            button.widthAnchor.constraint(equalToConstant: 100).isActive = true
            button.heightAnchor.constraint(equalToConstant: 100).isActive = true
            button.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        }
        
        
        guard let onboardingUrl = URL.localDocStorage?.appendingPathComponent("Onboarding") else {
            return
        }
        let contents = (try? FileManager.default.contentsOfDirectory(at: onboardingUrl, includingPropertiesForKeys: nil, options: [])) ?? []
        let pdfFiles = contents.filter({ (url) in
            return url.pathExtension.lowercased() == "pdf"
        }).sorted(by: { (lhs, rhs) -> Bool in
            return lhs.lastPathComponent < rhs.lastPathComponent
        })
        
        self.loadCachedOnboarding()
        self.loadNewOnboarding(index: 0) { (success, lastIndex) in
            if success {
                // Delete all files starting from lastIndex
                for file in pdfFiles {
                    if let number = Int(file.deletingPathExtension().lastPathComponent), number >= lastIndex {
                        try? FileManager.default.removeItem(atPath: file.path)
                    }
                }
            }
            DispatchQueue.main.async {
                self.loadCachedOnboarding()
            }
        }
    }
    
    @objc func close() {
        self.willMove(toParent: nil)
        self.view.removeFromSuperview()
        removeFromParent()
        delegate?.onboardingDidHide()
    }
    
    // MARK: - Load onboarding
    
    private func loadNewOnboarding(index: Int, completion: @escaping (Bool, Int) -> Void) {
        print("loadNewOnboarding", index)
        loadOnboarding(index: index) { (data, error) in
            if let data = data {
                // Save and load next page
                self.saveOnboardingPDF(index: index, data: data)
                self.loadNewOnboarding(index: index + 1, completion: completion)
            } else {
                // Finish loading
                completion(index != 0, index)
            }
        }
    }
    
    private func loadCachedOnboarding() {
        print("loadCachedOnboarding")
        guard let onboardingUrl = URL.localDocStorage?.appendingPathComponent("Onboarding") else {
            return
        }
        
        let contents = (try? FileManager.default.contentsOfDirectory(at: onboardingUrl, includingPropertiesForKeys: nil, options: [])) ?? []
        let pdfFiles = contents.filter({ (url) in
            return url.pathExtension.lowercased() == "pdf"
        }).sorted(by: { (lhs, rhs) -> Bool in
            let left = Int(lhs.deletingPathExtension().lastPathComponent) ?? 0
            let right = Int(rhs.deletingPathExtension().lastPathComponent) ?? 0
            return left < right
        })
        
        self.images = pdfFiles.compactMap({ (url) in
            return PDFimageFromLocalURL(url: url)
        })
        
        // Scroll view & image stack
        
        imageScrollView.subviews.forEach({ $0.removeFromSuperview() })
        
        let stackView = UIStackView(arrangedSubviews: images.map({ (image) -> UIImageView in
            let imageView = UIImageView()
            imageView.image = image
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.widthAnchor.constraint(equalToConstant: WIDTH).isActive = true
            imageView.heightAnchor.constraint(equalToConstant: HEIGHT).isActive = true
            return imageView
        }))
        stackView.axis = .horizontal
        stackView.spacing = 0.0
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        imageScrollView.addSubview(stackView)
        
        imageScrollView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor).isActive = true
        imageScrollView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor).isActive = true
        imageScrollView.topAnchor.constraint(equalTo: stackView.topAnchor).isActive = true
        imageScrollView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor).isActive = true
        
        imageScrollView.heightAnchor.constraint(equalTo: stackView.heightAnchor, constant: 1).isActive = true
        let constraint = imageScrollView.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        constraint.priority = UILayoutPriority(rawValue: 250.0)
        constraint.isActive = true
        
        // Page control
        
        circleViews = Array(0..<images.count).map({ (image) -> UIView in
            let circleView = UIView()
            circleView.widthAnchor.constraint(equalToConstant: 12.0).isActive = true
            circleView.heightAnchor.constraint(equalToConstant: 12.0).isActive = true
            circleView.layer.cornerRadius = 6.0
            circleView.layer.masksToBounds = true
            circleView.backgroundColor = UIColor.darkGray
            return circleView
        })
        let circleStackView = UIStackView(arrangedSubviews: circleViews)
        circleStackView.axis = .horizontal
        circleStackView.spacing = 12.0
        circleStackView.distribution = .fill
        circleStackView.translatesAutoresizingMaskIntoConstraints = false
        self.circleStackView = circleStackView
        
        containerView.addSubview(circleStackView)
        containerView.bottomAnchor.constraint(equalTo: circleStackView.bottomAnchor, constant: 6.0).isActive = true
        containerView.centerXAnchor.constraint(equalTo: circleStackView.centerXAnchor).isActive = true
        
        showImage(at: 0)
    }
    
    private func loadOnboarding(index: Int, completion: @escaping (Data?, Error?) -> Void) {
        print("loadOnboarding task resumed")
        let url = URL(string: "https://digicel.net/flippad/\(index + 1).pdf")!
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse,
               let contentType = httpResponse.allHeaderFields["Content-Type"] as? String,
               contentType == "application/pdf",
               let data = data {
                print("success")
                completion(data, nil)
            } else if let error = error {
                print("error")
                completion(nil, error)
            } else {
                print("undefined")
                completion(nil, nil)
            }
        }.resume()
    }
    
    private func saveOnboardingPDF(index: Int, data: Data) {
        guard let onboardingUrl = URL.localDocStorage?.appendingPathComponent("Onboarding") else {
            return
        }
        let pdfPath = onboardingUrl.appendingPathComponent("\(index).pdf").path
        
        if FileManager.default.fileExists(atPath: pdfPath) {
            try? FileManager.default.removeItem(atPath: pdfPath)
        }
        FileManager.default.createFile(atPath: pdfPath, contents: data, attributes: nil)
    }
    
    private func PDFimageFromLocalURL(url: URL) -> UIImage? {
        guard let document = CGPDFDocument(url as CFURL) else { return nil }
        guard let page = document.page(at: 1) else { return nil }

        let pageRect = page.getBoxRect(.mediaBox)
        
        UIGraphicsBeginImageContext(pageRect.size)
        let ctx = UIGraphicsGetCurrentContext()!
        
        UIColor.white.set()
        ctx.fill(pageRect)
        ctx.translateBy(x: 0.0, y: pageRect.size.height)
        ctx.scaleBy(x: 1.0, y: -1.0)
        ctx.drawPDFPage(page)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }
    
    // MARK: - Slide control
    
    @objc func previousSlide() {
        selectedIndex = min(max(0, selectedIndex - 1), self.images.count - 1)
        showImage(at: selectedIndex)
    }
    
    @objc func nextSlide() {
        selectedIndex = min(max(0, selectedIndex + 1), self.images.count - 1)
        showImage(at: selectedIndex)
    }
    
    func showImage(at index: Int) {
        guard (0..<images.count).contains(index) else {
            return
        }
        imageScrollView.setContentOffset(CGPoint(x: imageScrollView.bounds.width * CGFloat(index), y: 0.0), animated: true)
        circleViews.enumerated().forEach { (circleIndex, circleView) in
            circleView.backgroundColor = (index == circleIndex) ? UIColor.darkGray : UIColor.gray
        }
    }

}

extension OnboardingController: UIScrollViewDelegate {

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let offsetX = scrollView.contentOffset.x
        let fraction = offsetX / scrollView.contentSize.width
        let index = Int((CGFloat(images.count) * fraction).rounded(.toNearestOrEven))
        self.selectedIndex = index
        showImage(at: index)
    }
    
}
