//  Copyright © 2018 OsmosisAI, Inc. All rights reserved.

/*
 CONFIDENTIALITY NOTICE:
 This Software and all associated source files are confidential
 and intended only for use by individual or entity to which addressed
 and may contain information that is privileged, confidential and exempt from disclosure under applicable law.
 If you are not the intended recipient, be aware that any use, dissemination or disclosure,
 distribution or copying of communication or attachments is strictly prohibited.
 */

import Foundation


// MARK: - UIViewController

public extension UIViewController {
  
  func dismissPresentedViewControllers() {
    presentedViewController?.dismiss(animated: false) {  // maintain strong ref in case there is more than one, it will return nill when they are all gone
      self.dismissPresentedViewControllers()
    }
  }
  
  func requestAlertText(mainTitle: String, message: String, OkButtonTitle: String, placeHolder: String, existingText: String, result: @escaping (String, Bool) -> Void) {
    let alertController = UIAlertController(title: mainTitle, message: message, preferredStyle: .alert)
    alertController.addTextField { tf in
      tf.placeholder = placeHolder
      tf.font = Constants.Font16System
      tf.text = existingText
      tf.keyboardType = .numberPad
    }
    
    let OKAction = UIAlertAction(title: OkButtonTitle, style: .default) { (action) in
      if let textFields = alertController.textFields, textFields.count > 0 {
        if let textField = textFields.first, let text = textField.text {
          result(text, false)
        }
      }
    }
    
    alertController.addAction(OKAction)
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
      result("", true)
    }
    
    alertController.addAction(cancelAction)
    
    if let title = alertController.title {
      let titleAttributed = NSMutableAttributedString(string: title, attributes: [NSAttributedString.Key.font:Constants.Font17BoldSystem])
      alertController.setValue(titleAttributed, forKey: "attributedTitle")
    }
    
    if let message = alertController.message {
      let messageAttributed = NSMutableAttributedString(string: message, attributes: [NSAttributedString.Key.font:Constants.Font15System])
      alertController.setValue(messageAttributed, forKey: "attributedMessage")
    }
    
    present(alertController, animated: true){}
  }
  
  func displayAlert(title: String?, msg: String?, ok: String? = nil, cancel: String? = nil, autoRemoveDelay: Double? = 0, actionSheet: Bool? = false, okAction: (() -> Void)? = nil, cancelAction: (() -> Void)? = nil) {
    let alertController = UIAlertController(title: title, message: msg, preferredStyle: actionSheet == true ? .actionSheet : .alert)
    
    if let x = cancel {
      let cancelAction = UIAlertAction(title: x, style: .cancel) { (action) in
        if let cancelAction = cancelAction { cancelAction() }
      }
      
      alertController.addAction(cancelAction)
    }
    
    
    if let x = ok {
      let OKAction = UIAlertAction(title: x, style: .default) { (action) in
        if let okAction = okAction { okAction() }
      }
      
      alertController.addAction(OKAction)
    }
    
    present(alertController, animated: true, completion: nil)
  }
}


// MARK: - UIView

public extension UIView {
  
  func opacity(duration: Double, from: Int, to: Int, delegate: CAAnimationDelegate?=nil) {
    let animation = CABasicAnimation(keyPath: "opacity")
    animation.fromValue = from
    animation.toValue = to
    animation.duration = duration
    
    animation.delegate = delegate
    self.layer.add(animation, forKey: nil)
  }
  
  func rotate360Degrees(duration: Double, delegate: CAAnimationDelegate?=nil) {
    let animation = CABasicAnimation(keyPath: "transform.rotation")
    animation.fromValue = 0.0
    animation.toValue = CGFloat(Double.pi * 2.0)
    
    animation.duration = duration
    
    animation.delegate = delegate
    
    self.layer.add(animation, forKey: nil)
  }
  
  func circle() {
    radius(radius: bounds.size.height / 2)
  }
  
  func radius(radius: CGFloat, width: CGFloat?=nil, color: CGColor?=nil) {
    self.layer.cornerRadius = radius
    self.layer.masksToBounds = true
    
    if let width = width, let color = color {
      self.layer.borderWidth = width
      self.layer.borderColor = color
    }
  }
  
  func applyShadow(color: UIColor) {
    layer.cornerRadius = 2
    layer.shadowColor = color.cgColor
    layer.shadowOffset = CGSize(width: 1, height: 1)
    layer.shadowOpacity = 1
    layer.shadowRadius = 4.0
  }
  
  @IBInspectable var cornerRadius: CGFloat {
    get { return layer.cornerRadius }
    set {
      layer.cornerRadius = newValue
      layer.masksToBounds = newValue > 0
    }
  }
  
  @IBInspectable var borderWidth: CGFloat {
    get { return layer.borderWidth }
    set { layer.borderWidth = newValue }
  }
  
  @IBInspectable var borderColor: UIColor {
    get { return UIColor(cgColor: layer.borderColor!) }
    set { layer.borderColor = newValue.cgColor }
  }
  
  @IBInspectable var shadowRadius: CGFloat {
    get { return layer.shadowRadius }
    set { layer.shadowRadius = newValue }
  }
  
  @IBInspectable var shadowOpacity: Float {
    get { return layer.shadowOpacity }
    set { layer.shadowOpacity = newValue }
  }
  
  @IBInspectable var shadowOffset: CGSize {
    get { return layer.shadowOffset }
    set { layer.shadowOffset = newValue }
  }
  
  @IBInspectable  var shadowColor: UIColor? {
    get {
      if let color = layer.shadowColor { return UIColor(cgColor: color) }
      return nil
    }
    set {
      if let color = newValue { layer.shadowColor = color.cgColor }
      else { layer.shadowColor = nil }
    }
  }
}


// MARK: - UIColor

public extension UIColor {
  
  convenience init(red: Int, green: Int, blue: Int, alpha: CGFloat?=1.0) {
    let newRed   = CGFloat(Double(red)   / 255.0)
    let newGreen = CGFloat(Double(green) / 255.0)
    let newBlue  = CGFloat(Double(blue)  / 255.0)
    
    self.init(red:newRed, green:newGreen, blue:newBlue, alpha:alpha ?? 1.0)
  }
  
  class func colorWithHex(hex: Int, alpha: CGFloat?=1.0) -> UIColor {
    let red   = Int((hex >> 16) & 0xFF)
    let green = Int((hex >> 8) & 0xFF)
    let blue  = Int((hex) & 0xFF)
    
    return UIColor(red: red, green: green, blue: blue, alpha: alpha)
  }
  
  class func hexFromColor(color: UIColor) -> Int {
    guard let vals = color.cgColor.components else { return 0 }
    
    let red   = Int(Int(vals[0] * 255.0) & 0xFF)
    let green = Int(Int(vals[1] * 255.0) & 0xFF)
    let blue  = Int(Int(vals[2] * 255.0) & 0xFF)
    
    return red << 16 + green << 8 + blue
  }
}


// MARK: - String

public extension String {
  
  public var length: Int {
    get {
      return self.count
    }
  }
  
  public func fixPhone() -> String {
    let phone = self.components(separatedBy: CharacterSet(charactersIn: "0123456789").inverted).joined()
    
    var inx=0
    var newPhone = ""
    
    for char in phone {
      if inx == 3 { newPhone = newPhone + "-" }
      if inx == 6 { newPhone = newPhone + "-" }
      newPhone = newPhone + "\(char)"
      inx += 1
      
      if inx > 9 { break }
    }
    
    return newPhone.count > 3 ? newPhone : self
  }
  
  public var isNumber : Bool {
    get{
      return !self.isEmpty && self.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
  }
  
  func toJSON() -> Any? {
    guard let data = self.data(using: .utf8, allowLossyConversion: false) else { return nil }
    return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
  }
  
  var trim: String {
    return trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
  }
  
  var isValidEmailAddress : Bool {
    
    if count == 0 { return false }
    
    let regexString = ".+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*"
    
    let predicate = NSPredicate(format: "SELF MATCHES %@", regexString)
    
    return predicate.evaluate(with: self)
  }
  
  var isValidPhoneNumber : Bool {
    if count == 0 { return false }
    
    if count == 10 && isNumber { return true }
    
    let regexString = "^\\d{3}-\\d{3}-\\d{4}$"
    
    let predicate = NSPredicate(format: "SELF MATCHES %@", regexString)
    
    return predicate.evaluate(with: self)
  }
  
  internal func substring(start: Int, offsetBy: Int) -> String? {
    guard let substringStartIndex = self.index(startIndex, offsetBy: start, limitedBy: endIndex) else {
      return nil
    }
    
    guard let substringEndIndex = self.index(startIndex, offsetBy: start + offsetBy, limitedBy: endIndex) else {
      return nil
    }
    
    return String(self[substringStartIndex ..< substringEndIndex])
  }
  
  func contains(find: String) -> Bool{
    return self.range(of: find) != nil
  }
  
  func containsIgnoringCase(find: String) -> Bool{
    return self.range(of: find, options: .caseInsensitive) != nil
  }
}


// MARK: - UITextField

public extension UITextField {
  
  func placeholderWithColor(text:String, color:UIColor) {
    attributedPlaceholder = NSAttributedString(string:text, attributes: [NSAttributedString.Key.foregroundColor: color])
  }
  
  func addPadding() {
    let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: frame.height))
    leftView = paddingView
    leftViewMode = .always
  }
}


// MARK: - UIScrollView

public extension UIScrollView {
  
  func scrollToTop() {
    let desiredOffset = CGPoint(x: 0, y: -contentInset.top)
    setContentOffset(desiredOffset, animated: true)
  }
  
  func scrollToBottom() {
    let desiredOffset = CGPoint(x: 0, y: contentInset.bottom)
    setContentOffset(desiredOffset, animated: true)
  }
}


// MARK: - UIImage

public extension UIImage {
  
  func fixImageOrientation() -> UIImage {
    
    if ( self.imageOrientation == UIImage.Orientation.up ) {
      return self;
    }
    
    var transform: CGAffineTransform = CGAffineTransform.identity
    
    if ( self.imageOrientation == UIImage.Orientation.down || self.imageOrientation == UIImage.Orientation.downMirrored ) {
      transform = transform.translatedBy(x: self.size.width, y: self.size.height)
      transform = transform.rotated(by: CGFloat(Double.pi))
    }
    
    if ( self.imageOrientation == UIImage.Orientation.left || self.imageOrientation == UIImage.Orientation.leftMirrored ) {
      transform = transform.translatedBy(x: self.size.width, y: 0)
      transform = transform.rotated(by: CGFloat(Double.pi / 2.0))
    }
    
    if ( self.imageOrientation == UIImage.Orientation.right || self.imageOrientation == UIImage.Orientation.rightMirrored ) {
      transform = transform.translatedBy(x: 0, y: self.size.height);
      transform = transform.rotated(by: CGFloat(-Double.pi / 2.0));
    }
    
    if ( self.imageOrientation == UIImage.Orientation.upMirrored || self.imageOrientation == UIImage.Orientation.downMirrored ) {
      transform = transform.translatedBy(x: self.size.width, y: 0)
      transform = transform.scaledBy(x: -1, y: 1)
    }
    
    if ( self.imageOrientation == UIImage.Orientation.leftMirrored || self.imageOrientation == UIImage.Orientation.rightMirrored ) {
      transform = transform.translatedBy(x: self.size.height, y: 0);
      transform = transform.scaledBy(x: -1, y: 1);
    }
    
    let ctx: CGContext = CGContext(data: nil, width: Int(self.size.width), height: Int(self.size.height),
                                   bitsPerComponent: self.cgImage!.bitsPerComponent, bytesPerRow: 0,
                                   space: self.cgImage!.colorSpace!,
                                   bitmapInfo: self.cgImage!.bitmapInfo.rawValue)!;
    
    ctx.concatenate(transform)
    
    if ( self.imageOrientation == UIImage.Orientation.left ||
      self.imageOrientation == UIImage.Orientation.leftMirrored ||
      self.imageOrientation == UIImage.Orientation.right ||
      self.imageOrientation == UIImage.Orientation.rightMirrored ) {
      ctx.draw(self.cgImage!, in: CGRect(x: 0,y: 0,width: self.size.height,height: self.size.width))
    } else {
      ctx.draw(self.cgImage!, in: CGRect(x: 0,y: 0,width: self.size.width,height: self.size.height))
    }
    
    return UIImage(cgImage: ctx.makeImage()!)
  }
}


// MARK: - UIAlertAction

public extension UIAlertAction {
  
  public class func okAction() -> UIAlertAction {
    return okActionWithHandler(nil)
  }
  
  public class func okActionWithHandler(_ handler: ((UIAlertAction?) -> Void)?) -> UIAlertAction {
    return UIAlertAction(title:"OK", style: .default, handler: handler)
  }
  
  public class func cancelAction() -> UIAlertAction {
    return cancelActionWithHandler(nil)
  }
  
  public class func cancelActionWithHandler(_ handler: ((UIAlertAction?) -> Void)?) -> UIAlertAction {
    return UIAlertAction(title: "Cancel", style: .cancel, handler: handler)
  }
  
}


// MARK: - UIImageView

extension UIImageView {
  
  func addGradientLayer(frame: CGRect, colors:[UIColor]){
    let gradient = CAGradientLayer()
    gradient.frame = frame
    gradient.colors = colors.map{$0.cgColor}
    self.layer.addSublayer(gradient)
  }
  
}


// MARK: - CIImage

extension CIImage {
  func toUIImage() -> UIImage? {
    let context: CIContext = CIContext.init(options: nil)
    
    if let cgImage: CGImage = context.createCGImage(self, from: self.extent) {
      return UIImage(cgImage: cgImage)
    } else {
      return nil
    }
  }
}
