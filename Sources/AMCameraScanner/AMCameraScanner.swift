import UIKit

public protocol AMCameraScannerDelegate: AnyObject {
    func userDidCancelSimple(_ scanViewController: AMCameraScanner)
    func userDidScanCardSimple(_ scanViewController: AMCameraScanner, creditCard: CreditCard)
    func userDidScanQR(_ code: String)
}

open class AMCameraScanner: ScanBaseViewController {

    // used by ScanBase
    var previewView: PreviewView = PreviewView()
    var blurView: BlurView = BlurView()
    var roiView: UIView = UIView()
    var cornerView: CornerView?

    // our UI components
    var descriptionText = UILabel()
    var privacyLinkText = UITextView()
    var privacyLinkTextHeightConstraint: NSLayoutConstraint? = nil

    private var roiViewQR: NSLayoutConstraint!
    private var roiViewCard: NSLayoutConstraint!
    private var completedAnimation = true

    var closeButton: UIButton = {
        var button = UIButton(type: .system)
        button.setImage(UIImage.chevronLeft, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.tintColor = .white
        return button
    }()

    var flashButton: UIButton = {
        var button = UIButton(type: .custom)
        button.setImage(UIImage.flashOff, for: .normal)
        return button
    }()

    var galleryButton: UIButton = {
        var button = UIButton(type: .custom)
        button.setImage(UIImage.galleryIcon, for: .normal)
        return button
    }()
    
    private var debugView: UIImageView?
    var enableCameraPermissionsButton = UIButton(type: .system)
    var enableCameraPermissionsText = UILabel()

    // String
    static var enableCameraPermissionString = "String.Localized.enable_camera_access"
    static var enableCameraPermissionsDescriptionString = "String.Localized.update_phone_settings"
    static var privacyLinkString = "String.Localized.scanCardExpectedPrivacyLinkText()"

    public weak var delegate: AMCameraScannerDelegate?
    var scanPerformancePriority: ScanPerformance = .fast
    var maxErrorCorrectionDuration: Double = 4.0

    // MARK: Inits
    public override init() {
        super.init()
        if UIDevice.current.userInterfaceIdiom == .pad {
            // For the iPad you can use the full screen style but you have to select "requires full screen" in
            // the Info.plist to lock it in portrait mode. For iPads, we recommend using a formSheet, which
            // handles all orientations correctly.
            self.modalPresentationStyle = .formSheet
        } else {
            self.modalPresentationStyle = .fullScreen
        }
    }

    required public init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        setupUiComponents()
        setupConstraints()

        setupOnViewDidLoad(
            regionOfInterestLabel: roiView,
            blurView: blurView,
            previewView: previewView,
            cornerView: cornerView,
            debugImageView: debugView,
            torchLevel: 1.0
        )

        if #available(iOS 13.0, *) {
            setUpMainLoop(errorCorrectionDuration: maxErrorCorrectionDuration)
        }

        startCameraPreview()
    }

    //  Removing targets manually since we are allowing custom buttons which retains button reference ->
    //  ARC doesn't automatically decrement its reference count ->
    //  Targets gets added on every setUpUi call.
    //
    //  Figure out a better way of allow custom buttons programmatically instead of whole UI buttons.
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        closeButton.removeTarget(self, action: #selector(cancelButtonPress), for: .touchUpInside)
        flashButton.removeTarget(self, action: #selector(flashButtonPress), for: .touchUpInside)
        galleryButton.removeTarget(self, action: #selector(galleryButtonPress), for: .touchUpInside)
    }

    @available(iOS 13.0, *)
    func setUpMainLoop(errorCorrectionDuration: Double) {
        if scanPerformancePriority == .accurate {
            let mainLoop = self.mainLoop as? OcrMainLoop
            mainLoop?.errorCorrection = ErrorCorrection(
                stateMachine: OcrAccurateMainLoopStateMachine(
                    maxErrorCorrection: maxErrorCorrectionDuration
                )
            )
        }
    }

    // MARK: -Visual and UI event setup for UI components
    func setupUiComponents() {
        view.backgroundColor = .white
        regionOfInterestCornerRadius = 15.0

        let children: [UIView] = [
            previewView,
            blurView,
            roiView,
            descriptionText,
            closeButton,
            flashButton,
            galleryButton,
            enableCameraPermissionsButton,
            enableCameraPermissionsText,
            privacyLinkText,
        ]
        for child in children {
            self.view.addSubview(child)
        }

        setupPreviewViewUi()
        setupBlurViewUi()
        setupRoiViewUi()
        addButtonTargets()
        setupDescriptionTextUi()
        setupDenyUi()
        setupPrivacyLinkTextUi()

        if showDebugImageView {
            setupDebugViewUi()
        }
    }

    func setupPreviewViewUi() {
        // no ui setup
    }

    func setupBlurViewUi() {
        blurView.backgroundColor = #colorLiteral(
            red: 0.2411109507,
            green: 0.271378696,
            blue: 0.3280351758,
            alpha: 0.7020547945
        )
    }

    func setupRoiViewUi() {
        roiView.layer.borderColor = UIColor.white.cgColor
    }

    func addButtonTargets() {
        closeButton.addTarget(self, action: #selector(cancelButtonPress), for: .touchUpInside)
        flashButton.addTarget(self, action: #selector(flashButtonPress), for: .touchUpInside)
        galleryButton.addTarget(self, action: #selector(galleryButtonPress), for: .touchUpInside)
    }

    func setupDescriptionTextUi() {
        descriptionText.textColor = .white
        descriptionText.textAlignment = .center
        descriptionText.font = descriptionText.font.withSize(14)
        descriptionText.numberOfLines = 0
    }

    func setupDenyUi() {
        let text = AMCameraScanner.enableCameraPermissionString
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(
            NSAttributedString.Key.underlineColor,
            value: UIColor.white,
            range: NSRange(location: 0, length: text.count)
        )
        attributedString.addAttribute(
            NSAttributedString.Key.foregroundColor,
            value: UIColor.white,
            range: NSRange(location: 0, length: text.count)
        )
        attributedString.addAttribute(
            NSAttributedString.Key.underlineStyle,
            value: NSUnderlineStyle.single.rawValue,
            range: NSRange(location: 0, length: text.count)
        )
        let font =
            enableCameraPermissionsButton.titleLabel?.font.withSize(20)
            ?? UIFont.systemFont(ofSize: 20.0)
        attributedString.addAttribute(
            NSAttributedString.Key.font,
            value: font,
            range: NSRange(location: 0, length: text.count)
        )
        enableCameraPermissionsButton.setAttributedTitle(attributedString, for: .normal)
        enableCameraPermissionsButton.isHidden = true

        enableCameraPermissionsButton.addTarget(
            self,
            action: #selector(enableCameraPermissionsPress),
            for: .touchUpInside
        )

        enableCameraPermissionsText.text =
        AMCameraScanner.enableCameraPermissionsDescriptionString
        enableCameraPermissionsText.textColor = .white
        enableCameraPermissionsText.textAlignment = .center
        enableCameraPermissionsText.font = enableCameraPermissionsText.font.withSize(17)
        enableCameraPermissionsText.numberOfLines = 3
        enableCameraPermissionsText.isHidden = true
    }

    func setupPrivacyLinkTextUi() {
        privacyLinkText.textColor = .white
        privacyLinkText.textAlignment = .center
        privacyLinkText.font = descriptionText.font.withSize(14)
        privacyLinkText.isEditable = false
        privacyLinkText.dataDetectorTypes = .link
        privacyLinkText.isScrollEnabled = false
        privacyLinkText.backgroundColor = .clear
        privacyLinkText.linkTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        privacyLinkText.accessibilityIdentifier = "Privacy Link Text"
    }

    func setupDebugViewUi() {
        debugView = UIImageView()
        guard let debugView = debugView else { return }
        self.view.addSubview(debugView)
    }

    // MARK: -Autolayout constraints
    func setupConstraints() {
        let children: [UIView] = [
            previewView,
            blurView,
            roiView,
            descriptionText,
            closeButton,
            flashButton,
            galleryButton,
            enableCameraPermissionsButton,
            enableCameraPermissionsText,
            privacyLinkText,
        ]
        for child in children {
            child.translatesAutoresizingMaskIntoConstraints = false
        }

        setupPreviewViewConstraints()
        setupBlurViewConstraints()
        setupRoiViewConstraints()
        setupCloseButtonConstraints()
        setupflashButtonConstraints()
        setupgalleryButtonConstraints()
        setupDescriptionTextConstraints()
        setupDenyConstraints()
        setupPrivacyLinkTextConstraints()

        if showDebugImageView {
            setupDebugViewConstraints()
        }
    }

    func setupPreviewViewConstraints() {
        // make it full screen
        previewView.setAnchorsEqual(to: self.view)
    }

    func setupBlurViewConstraints() {
        blurView.setAnchorsEqual(to: self.previewView)
    }

    func setupRoiViewConstraints() {
        roiView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40).isActive = true
        roiView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40).isActive =
            true
        roiViewCard = roiView.heightAnchor.constraint(equalTo: roiView.widthAnchor, multiplier: 1.0 / 1.586 )
        roiViewQR = roiView.heightAnchor.constraint(equalTo: roiView.widthAnchor, multiplier: 1.0 )
        roiViewQR?.isActive = true
        roiView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }

    func setupCloseButtonConstraints() {
        let margins = view.layoutMarginsGuide
        closeButton.topAnchor.constraint(equalTo: margins.topAnchor, constant: 16.0).isActive = true
        closeButton.leadingAnchor.constraint(equalTo: margins.leadingAnchor).isActive = true
    }

    func setupflashButtonConstraints() {
        let margins = view.layoutMarginsGuide
        flashButton.bottomAnchor.constraint(equalTo: margins.bottomAnchor, constant: -36).isActive =
            true
        flashButton.leadingAnchor.constraint(equalTo: margins.leadingAnchor).isActive = true
        flashButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        flashButton.widthAnchor.constraint(equalToConstant: 48).isActive = true
    }

    func setupgalleryButtonConstraints() {
        let margins = view.layoutMarginsGuide
        galleryButton.bottomAnchor.constraint(equalTo: margins.bottomAnchor, constant: -36).isActive =
            true
        galleryButton.trailingAnchor.constraint(equalTo: margins.trailingAnchor).isActive = true
        galleryButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        galleryButton.widthAnchor.constraint(equalToConstant: 48).isActive = true
    }

    func setupDescriptionTextConstraints() {
        descriptionText.leadingAnchor.constraint(equalTo: roiView.leadingAnchor).isActive =
            true
        descriptionText.trailingAnchor.constraint(equalTo: roiView.trailingAnchor)
            .isActive = true
        descriptionText.topAnchor.constraint(equalTo: roiView.bottomAnchor, constant: 24).isActive =
            true
    }

    func setupDenyConstraints() {
        NSLayoutConstraint.activate([
            enableCameraPermissionsButton.topAnchor.constraint(
                equalTo: privacyLinkText.bottomAnchor,
                constant: 32
            ),
            enableCameraPermissionsButton.centerXAnchor.constraint(equalTo: roiView.centerXAnchor),

            enableCameraPermissionsText.topAnchor.constraint(
                equalTo: enableCameraPermissionsButton.bottomAnchor,
                constant: 32
            ),
            enableCameraPermissionsText.leadingAnchor.constraint(equalTo: roiView.leadingAnchor),
            enableCameraPermissionsText.trailingAnchor.constraint(equalTo: roiView.trailingAnchor),
        ])
    }

    func setupPrivacyLinkTextConstraints() {
        NSLayoutConstraint.activate([
            privacyLinkText.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            privacyLinkText.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            privacyLinkText.topAnchor.constraint(equalTo: roiView.bottomAnchor, constant: 16),
        ])

        privacyLinkTextHeightConstraint = privacyLinkText.heightAnchor.constraint(
            equalToConstant: 0
        )
    }

    func setupDebugViewConstraints() {
        guard let debugView = debugView else { return }
        debugView.translatesAutoresizingMaskIntoConstraints = false

        debugView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        debugView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        debugView.widthAnchor.constraint(equalToConstant: 240).isActive = true
        debugView.heightAnchor.constraint(equalTo: debugView.widthAnchor, multiplier: 1.0).isActive =
            true
    }

    // MARK: -Override some ScanBase functions
    override open func onScannedQR(_ code: String, sourceType: ImageourceType) {
        delegate?.userDidScanQR(code)
    }

    override open func onFailScanImage(_ sourceType: ImageourceType) {}

    override open func onScannedCard(number: String,
                                expiryYear: String?,
                                expiryMonth: String?,
                                scannedImage: UIImage?) {
        let card = CreditCard(number: number)
        card.expiryMonth = expiryMonth
        card.expiryYear = expiryYear
        card.name = predictedName
        card.image = scannedImage

        delegate?.userDidScanCardSimple(self, creditCard: card)
    }

    func updateRoiView(prediction: CreditCardOcrPrediction) {
        guard completedAnimation else { return }

        completedAnimation = false

        roiViewQR.isActive = !prediction.isCard
        roiViewCard.isActive = prediction.isCard

        UIView.animate(withDuration: 0.3,
                       animations: { self.view.layoutIfNeeded() },
                       completion: { (value: Bool) in
            self.completedAnimation = true
        })
    }

    override func prediction(prediction: CreditCardOcrPrediction,
                             imageData: ScannedCardImageData,
                             state: MainLoopState) {
        super.prediction(prediction: prediction, imageData: imageData, state: state)
        updateRoiView(prediction: prediction)
    }

    override func onCameraPermissionDenied(showedPrompt: Bool) {
        descriptionText.isHidden = true
        flashButton.isHidden = true

        enableCameraPermissionsButton.isHidden = false
        enableCameraPermissionsText.isHidden = false
        privacyLinkTextHeightConstraint?.isActive = true
    }

    // MARK: -UI event handlers
    @objc open func cancelButtonPress() {
        delegate?.userDidCancelSimple(self)
        self.cancelScan()
    }

    @objc func flashButtonPress() {
        toggleTorch()

        let flashImage = self.isTorchOn() ? UIImage.flashOn : UIImage.flashOff
        flashButton.setImage(flashImage, for: .normal)
    }

    @objc public func galleryButtonPress() {
        self.pauseScanning()

        let imagePicker = UIImagePickerController()
        imagePicker.modalPresentationStyle = .overFullScreen
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        imagePicker.delegate = self
        self.present(imagePicker, animated: true, completion: nil)
    }

    /// Warning: if the user navigates to settings and updates the setting, it'll suspend your app.
    @objc func enableCameraPermissionsPress() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsUrl) else {
            return
        }

        UIApplication.shared.open(settingsUrl)
    }
}

extension UIView {
    func setAnchorsEqual(to otherView: UIView) {
        self.topAnchor.constraint(equalTo: otherView.topAnchor).isActive = true
        self.leadingAnchor.constraint(equalTo: otherView.leadingAnchor).isActive = true
        self.trailingAnchor.constraint(equalTo: otherView.trailingAnchor).isActive = true
        self.bottomAnchor.constraint(equalTo: otherView.bottomAnchor).isActive = true
    }
}

// MARK: - UIImagePickerControllerDelegate

extension AMCameraScanner: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
        self.resumeScanning()
    }

    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {

        if let image = (info[UIImagePickerController.InfoKey.originalImage] as? UIImage),
           let ciImage = CIImage(image: image),
           let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]),
           let features = detector.features(in: ciImage) as? [CIQRCodeFeature],
           let qrCodeFeature = features.first,
           let qrContent = qrCodeFeature.messageString {
            self.onScannedQR(qrContent, sourceType: .gallery)
            return
        }

        self.onFailScanImage(.gallery)
    }
}
