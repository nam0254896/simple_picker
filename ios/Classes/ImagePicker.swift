import UIKit
import MobileCoreServices
import Flutter
import AVFoundation

public enum CameraPluginLocationString: String {
    /// Decline to proceed with operation
    case cancel = "Cancel"
    
    /// Option to select photo from library
    case chooseFromLibrary = "Choose From Library"
    
    /// Option to select photo from photo roll
    case chooseFromPhotoRoll = "Choose From PhotoRoll"
    
    /// There are no sources available to select a photo
    case noSources = "No Sources"
    
    /// Option to take photo using camera
    case takePhoto = "Take Photo"
    
    /// Option to take video using camera
    case takeVideo = "Take Video"
    
    public func comment() -> String {
        switch self {
        case .cancel:
            return "Decline to proceed with operation"
        case .chooseFromLibrary:
            return "Option to select photo/video from library"
        case .chooseFromPhotoRoll:
            return "Option to select photo from photo roll"
        case .noSources:
            return "There are no sources available to select a photo"
        case .takePhoto:
            return "Option to take photo using camera"
        case .takeVideo:
            return "Option to take video using camera"
        }
    }
}

 class CameraPlugin: NSObject{
    open class func getPhotoWithCallback(getPhotoWithCallback callback: @escaping (_ photo: UIImage, _ info: [AnyHashable: Any]) -> Void) {
        let camPlugin = CameraPlugin()
        camPlugin.allowsVideo = false
        camPlugin.didGetPhoto = callback
        camPlugin.present()
    }

    /// Convenience method for getting a video
    open class func getVideoWithCallback(getVideoWithCallback callback: @escaping (_ video: URL, _ info: [AnyHashable: Any]) -> Void) {
        let camPlugin = CameraPlugin()
        camPlugin.allowsPhoto = false
        camPlugin.didGetVideo = callback
        camPlugin.present()
    }


    // MARK: - Configuration options

    /// Whether to allow selecting a photo
    open var allowsPhoto = true

    /// Whether to allow selecting a video
    open var allowsVideo = true

    /// Whether to allow capturing a photo/video with the camera
    open var allowsTake = true

    ///  That's the width of the image that the image was designed for (e.g. 375.0)
     open var reDesignWidth: Double = 0.0

    ///  That's the height of the image that the image was designed for (e.g. 667.0)
     open var reDesignHeight: Double = 0.0 
     
    /// Whether to allow selecting existing media
    open var allowsSelectFromLibrary = true

    /// Whether to allow editing the media after capturing/selection
    open var allowsEditing = false

    /// Whether to use full screen camera preview on the iPad
    open var iPadUsesFullScreenCamera = false

    /// Enable selfie mode by default
    open var defaultsToFrontCamera = false

    /// The UIBarButtonItem to present from (may be replaced by a overloaded methods)
    open var presentingBarButtonItem: UIBarButtonItem? = nil

    /// The UIView to present from (may be replaced by a overloaded methods)
    open var presentingView: UIView? = nil

    /// The UIRect to present from (may be replaced by a overloaded methods)
    open var presentingRect: CGRect? = nil

    /// The UITabBar to present from (may be replaced by a overloaded methods)
    open var presentingTabBar: UITabBar? = nil

    /// The UIViewController to present from (may be replaced by a overloaded methods)
    open lazy var presentingViewController: UIViewController = {
        return UIApplication.shared.keyWindow!.rootViewController!
    }()


    // MARK: - Callbacks

    /// A photo was selected
    open var didGetPhoto: ((_ photo: UIImage, _ info: [AnyHashable: Any]) -> Void)?

    /// A video was selected
    open var didGetVideo: ((_ video: URL, _ info: [AnyHashable: Any]) -> Void)?

    /// The user did not attempt to select a photo
    open var didDeny: (() -> Void)?

    /// The user started selecting a photo or took a photo and then hit cancel
    open var didCancel: (() -> Void)?

    /// A photo or video was selected but the ImagePicker had NIL for EditedImage and OriginalImage
    open var didFail: (() -> Void)?


    // MARK: - Localization overrides
    
    /// Custom UI text (skips localization)
    open var cancelText: String? = nil
    
    /// Custom UI text (skips localization)
    open var chooseFromLibraryText: String? = nil
    
    /// Custom UI text (skips localization)
    open var chooseFromPhotoRollText: String? = nil
    
    /// Custom UI text (skips localization)
    open var noSourcesText: String? = nil

    /// Custom UI text (skips localization)
    open var takePhotoText: String? = nil

    /// Custom UI text (skips localization)
    open var takeVideoText: String? = nil


    // MARK: - Private

    private lazy var imagePicker: UIImagePickerController = {
        [unowned self] in
        let retval = CustomImagePickerController()
        retval.delegate = self
        retval.allowsEditing = true
        return retval
        }()

    private var alertController: UIAlertController? = nil

    // This is a hack required on iPad if you want to select a photo and you already have a popup on the screen
    // see: https://stackoverflow.com/a/35209728/300224
    private func topViewController(rootViewController: UIViewController) -> UIViewController {
        var rootViewController = UIApplication.shared.keyWindow!.rootViewController!
        repeat {
            guard let presentedViewController = rootViewController.presentedViewController else {
                return rootViewController
            }
            
            if let navigationController = rootViewController.presentedViewController as? UINavigationController {
                rootViewController = navigationController.topViewController ?? navigationController
                
            } else {
                rootViewController = presentedViewController
            }
        } while true
    }

    
    // MARK: - Localization

    private func localizeString(_ string:CameraPluginLocationString) -> String {
        let bundle = Bundle(for: type(of: self))
        //let stringsURL = bundle.resourceURL!.appendingPathComponent("Localizable.strings")
        let bundleLocalization = bundle.localizedString(forKey: string.rawValue, value: nil, table: nil)
        //let a = NSLocal
        //let bundleLocalization = NSLocalizedString(string.rawValue, tableName: nil, bundle: bundle, value: string.rawValue, comment: string.comment())
        
        
        switch string {
        case .cancel:
            return self.cancelText ?? bundleLocalization
        case .chooseFromLibrary:
            return self.chooseFromLibraryText ?? bundleLocalization
        case .chooseFromPhotoRoll:
            return self.chooseFromPhotoRollText ?? bundleLocalization
        case .noSources:
            return self.noSourcesText ?? bundleLocalization
        case .takePhoto:
            return self.takePhotoText ?? bundleLocalization
        case .takeVideo:
            return self.takeVideoText ?? bundleLocalization
        }
    }

    
    /// Presents the user with an option to take a photo or choose a photo from the library
    open func present() {
        //TODO: maybe encapsulate source selection?
        var titleToSource = [(buttonTitle: CameraPluginLocationString, source: UIImagePickerController.SourceType)]()

        if self.allowsTake && UIImagePickerController.isSourceTypeAvailable(.camera) {
            if self.allowsPhoto {
                titleToSource.append((buttonTitle: .takePhoto, source: .camera))
            }
            if self.allowsVideo {
                titleToSource.append((buttonTitle: .takeVideo, source: .camera))
            }
        }
        if self.allowsSelectFromLibrary {
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                titleToSource.append((buttonTitle: .chooseFromLibrary, source: .photoLibrary))
            } else if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
                titleToSource.append((buttonTitle: .chooseFromPhotoRoll, source: .savedPhotosAlbum))
            } else {
                print("name")
            }
        }

        guard titleToSource.count > 0 else {
            let str = localizeString(.noSources)

            //TODO: Encapsulate this
            //TODO: These has got to be a better way to do this
            let alert = UIAlertController(title: nil, message: str, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: localizeString(.cancel), style: .default, handler: nil))

            // http://stackoverflow.com/a/34487871/300224
            let alertWindow = UIWindow(frame: UIScreen.main.bounds)
            alertWindow.rootViewController = UIViewController()
            alertWindow.windowLevel = UIWindow.Level.alert + 1;
            alertWindow.makeKeyAndVisible()
            alertWindow.rootViewController?.present(alert, animated: true, completion: nil)
            return
        }

        var popOverPresentRect : CGRect = self.presentingRect ?? CGRect(x: 0, y: 0, width: 1, height: 1)
        if popOverPresentRect.size.height == 0 || popOverPresentRect.size.width == 0 {
            popOverPresentRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        }
        
        alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        for (title, source) in titleToSource {
            let action = UIAlertAction(title: localizeString(title), style: .default) {
                (UIAlertAction) -> Void in
                self.imagePicker.sourceType = source
                if source == .camera && self.defaultsToFrontCamera && UIImagePickerController.isCameraDeviceAvailable(.front) {
                    self.imagePicker.cameraDevice = .front
                }
                // set the media type: photo or video
                self.imagePicker.allowsEditing = self.allowsEditing
                var mediaTypes = [String]()
                if self.allowsPhoto {
                    mediaTypes.append(String(kUTTypeImage))
                }
                if self.allowsVideo {
                    mediaTypes.append(String(kUTTypeMovie))
                }
                self.imagePicker.mediaTypes = mediaTypes

                //TODO: Need to encapsulate popover code
                var popOverPresentRect: CGRect = self.presentingRect ?? CGRect(x: 0, y: 0, width: 1, height: 1)
                if popOverPresentRect.size.height == 0 || popOverPresentRect.size.width == 0 {
                    popOverPresentRect = CGRect(x: 0, y: 0, width: 1, height: 1)
                }
                let topVC = self.topViewController(rootViewController: self.presentingViewController)

                if UI_USER_INTERFACE_IDIOM() == .phone || (source == .camera && self.iPadUsesFullScreenCamera) {
                    
                    topVC.present(self.imagePicker, animated: true, completion: nil)
                    let initController = FlutterViewController()
                } else {
                    // On iPad use pop-overs.
                    self.imagePicker.modalPresentationStyle = .popover
                    self.imagePicker.popoverPresentationController?.sourceRect = popOverPresentRect
                    topVC.present(self.imagePicker, animated: true, completion: nil)
                }
            }
            alertController!.addAction(action)
        }
        let cancelAction = UIAlertAction(title: localizeString(.cancel), style: .cancel) {
            (UIAlertAction) -> Void in
            self.didCancel?()
        }
        alertController!.addAction(cancelAction)

        let topVC = topViewController(rootViewController: presentingViewController)
        
        alertController?.modalPresentationStyle = .popover
        if let presenter = alertController!.popoverPresentationController {
            presenter.sourceView = presentingView;
            if let presentingRect = self.presentingRect {
                presenter.sourceRect = presentingRect
            }
            //WARNING: on ipad this fails if no SOURCEVIEW AND SOURCE RECT is provided
        }
        topVC.present(alertController!, animated: true, completion: nil)
        print(topVC.presentedViewController)
    }

    /// Dismisses the displayed view. Especially handy if the sheet is displayed while suspending the app,
    open func dismiss() {
        alertController?.dismiss(animated: true, completion: nil)
        imagePicker.dismiss(animated: true, completion: nil)
    }
}

extension CameraPlugin: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        UIApplication.shared.isStatusBarHidden = true
        let mediaType: String = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.mediaType)] as! String
        var imageToSave: UIImage
        // Handle a still image capture
        if mediaType == kUTTypeImage as String {
            if let editedImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.editedImage)] as? UIImage {
                let rotatedImage = editedImage.rotate(radians: .pi * 2)
                imageToSave = rotatedImage
            } else if let originalImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage {
                let rotatedImage = originalImage.rotate(radians: .pi * 2)
                let resizeImage = rotatedImage.imageResize(newSize: CGSize(width: reDesignWidth, height: reDesignHeight))
                imageToSave = resizeImage
            } else {
                self.didCancel?()
                return
            }
            self.didGetPhoto?(imageToSave, info)
            if UI_USER_INTERFACE_IDIOM() == .pad {
                self.imagePicker.dismiss(animated: true)
            }
        } else if mediaType == kUTTypeMovie as String {
            self.didGetVideo?(info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.mediaURL)] as! URL, info)
        }
//        EventHandleChannel.shared.sendEvent(dataSend: true)
        picker.dismiss(animated: true, completion: nil)
    }

    /// Conformance for image picker delegate
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        UIApplication.shared.isStatusBarHidden = true
//        EventHandleChannel.shared.sendEvent(dataSend: true)
        picker.dismiss(animated: true, completion: nil)
        self.didDeny?()
    }
    
    // Helper function inserted by Swift 4.2 migrator.
    private func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
        return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
    }
    
    // Helper function inserted by Swift 4.2 migrator.
    private func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
        return input.rawValue
    }
}

extension UIImage {
    public func rotate(radians: CGFloat) -> UIImage {
        let rotatedSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .integral.size
        UIGraphicsBeginImageContext(rotatedSize)
        if let context = UIGraphicsGetCurrentContext() {
            let origin = CGPoint(x: rotatedSize.width / 2.0, y: rotatedSize.height / 2.0)
            context.translateBy(x: origin.x, y: origin.y)
            context.rotate(by: radians)
            draw(in: CGRect(x: -size.width / 2.0, y: -size.height / 2.0, width: size.width, height: size.height))
            let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return rotatedImage ?? self
        }
        return self
    }
    
    public func imageResize(newSize: CGSize) -> UIImage {
        let size = self.size
        let newSize = calculateNewSize(for: size, maxWidth: 1500, maxHeight: 2000)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    public func calculateNewSize(for size: CGSize, maxWidth: CGFloat, maxHeight: CGFloat) -> CGSize {
        var width = size.width
        var height = size.height
        
        // Check if width exceeds maxWidth
        if width > maxWidth {
            let ratio = maxWidth / width
            width *= ratio
            height *= ratio
        }
        
        // Check if height exceeds maxHeight
        if height > maxHeight {
            let ratio = maxHeight / height
            width *= ratio
            height *= ratio
        }

        return CGSize(width: width, height: height)
    }
}
