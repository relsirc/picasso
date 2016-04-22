//
//  ViewController.swift
//  PicassoApp
//
//  Created by Crisler Chee on 7/10/15.
//  Copyright © 2015 Crisler. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var lastPoint = CGPoint.zero
    var isSwiped = false
    var isSettingsViewActive = false
    
    var red : CGFloat = 0.0
    var green : CGFloat = 0.0
    var blue : CGFloat = 0.0
    var brushWidth : CGFloat = 10.0
    var opacity : CGFloat = 1.0
   
    let colors: [(CGFloat, CGFloat, CGFloat)] =
    [
        (0, 0, 0), //black
        (105.0 / 255.0, 105.0 / 255.0, 105.0 / 255.0), // grey
        (1.0, 0, 0), // red
        (0, 0, 1.0), // blue
        (51.0 / 255.0, 204.0 / 255.0, 1.0), // sky blue
        (1.0, 1.0, 0), //yellow
        (102.0 / 255.0, 1.0, 0), // green
        (160.0 / 255.0, 82.0 / 255.0, 45.0 / 255.0), //brown
        (1.0, 102.0 / 255.0, 0), // orange
        (1.0, 1.0, 1.0), //white
    ]
    
    // For undo function
    var stackOfPreviousImages = Stack<UIImage!>()
    
    @IBOutlet var settingsView: UIView!
    @IBOutlet weak var mainCanvas: UIImageView!
    // Using temp canvas to control line opacity
    @IBOutlet weak var tempCanvas: UIImageView!
    
    // Elements in settings view
    @IBOutlet weak var brushSlider: UISlider!
    @IBOutlet weak var brushPreviewImage: UIImageView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.settingsView.layer.cornerRadius = 5
        self.drawPreview()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
// MARK: - IBActions

    @IBAction func shareMyArt(sender: AnyObject) {
        
        UIGraphicsBeginImageContext(mainCanvas.bounds.size)
        mainCanvas.image?.drawInRect(CGRect(x: 0, y: 0, width: mainCanvas.frame.size.width, height: mainCanvas.frame.height))
        let myImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let activityViewController = UIActivityViewController(activityItems: [myImage], applicationActivities: nil)
        presentViewController(activityViewController, animated: true, completion: nil)
        
    }
    
    @IBAction func resetCanvas(sender: AnyObject) {
        
        let alertController = UIAlertController(title: "Confirmation", message:
            "Do you want to clear the canvas? You can't undo this action.", preferredStyle: UIAlertControllerStyle.Alert)
       
        let yesAction: UIAlertAction = UIAlertAction(title: "Yes", style: .Default) { action -> Void in
            
            // Clears the canvas
            self.mainCanvas.image = nil
            self.stackOfPreviousImages.clearStack()
        }
        
        alertController.addAction(yesAction)
        alertController.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Default,handler: nil))
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
  
    @IBAction func undoLastAction(sender: AnyObject) {
    
        if( !stackOfPreviousImages.isEmpty() )
        {
            let prevImage = stackOfPreviousImages.pop()
            mainCanvas.image = prevImage
        }
    }
    
    @IBAction func pressedSettings(sender: AnyObject) {
        
        self.isSettingsViewActive = true
        
        self.view.addSubview(self.settingsView)
        
        let sourceSize = self.view.frame
        let popupSize = self.settingsView.frame
        
        self.settingsView.frame = CGRectMake((sourceSize.width - popupSize.width)/2, sourceSize.height, popupSize.width, popupSize.height)
        
        let popupEndRect:CGRect = CGRectMake((sourceSize.width - popupSize.width)/2, (sourceSize.height - popupSize.height), popupSize.width, popupSize.height)
        
        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
            
            self.settingsView.frame = popupEndRect
            
            }, completion: { (finished: Bool) -> Void in
        })
    }
    
    @IBAction func removeSettings(sender: AnyObject) {
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            
            let sourceSize = self.view.frame
            let popupSize = self.settingsView.frame
            
            self.settingsView.frame = CGRectMake((sourceSize.width - popupSize.width)/2, sourceSize.height, popupSize.width, popupSize.height)
            
            }, completion: { (finished: Bool) -> Void in
                self.settingsView.removeFromSuperview()
                self.isSettingsViewActive = false
        })
    }
    
    @IBAction func changeBrushColor(sender: AnyObject) {
        
        var index = sender.tag ?? 0
        if index < 0 || index >= colors.count {
            index = 0
        }
        
        (red, green, blue) = colors[index]
        
        if index == colors.count - 1 {
            opacity = 1.0
        }

        self.removeSettings(sender)
    }
    
    // For brush size slider
    @IBAction func sliderChanged(sender: UISlider){
        
        brushWidth = CGFloat(sender.value)
        
        drawPreview()
    }
    
// MARK: - touch overrides and drawing functions
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        isSwiped = false
        
        if isSettingsViewActive
        {
            return
        }
        
        if let touch = touches.first as UITouch! {
            lastPoint = touch.locationInView(self.view)
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        isSwiped = true
        
        if isSettingsViewActive
        {
            return
        }
        
        if let touch = touches.first as UITouch! {
            
            let currentPoint = touch.locationInView(view)
            
            // Check if force touch is available
            if (traitCollection.forceTouchCapability == .Available)
            {
                drawLineFrom(lastPoint, currentPoint, withForce: touch.force)
            }
            else
            {
                drawLineFrom(lastPoint, currentPoint)
            }
            lastPoint = currentPoint
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        if isSettingsViewActive
        {
            return
        }
        
        if !isSwiped
        {
            drawLineFrom(lastPoint, lastPoint)
        }
        
        // Merge temp image canvas into main
        UIGraphicsBeginImageContext(mainCanvas.frame.size)
        mainCanvas.image?.drawInRect(CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height), blendMode: CGBlendMode.Normal, alpha: 1.0)
        tempCanvas.image?.drawInRect(CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height), blendMode: CGBlendMode.Normal, alpha: opacity)
        
        // Push to the stack
        stackOfPreviousImages.push(mainCanvas.image)
        mainCanvas.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Reset the temp canvas
        tempCanvas.image = nil
    }
    
    func drawLineFrom( fromPoint: CGPoint, _ toPoint: CGPoint, withForce force : CGFloat = 1){
        
        UIGraphicsBeginImageContext(view.frame.size)
        let context = UIGraphicsGetCurrentContext()
        tempCanvas.image?.drawInRect(CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        
        CGContextMoveToPoint(context, fromPoint.x, fromPoint.y)
        CGContextAddLineToPoint(context, toPoint.x, toPoint.y)
        
        CGContextSetLineCap(context, CGLineCap.Round)
        CGContextSetLineWidth(context, brushWidth * force)
        CGContextSetRGBStrokeColor(context, red, green, blue, 1.0)
        CGContextSetBlendMode(context, CGBlendMode.Normal)
        
        CGContextStrokePath(context)
        tempCanvas.image = UIGraphicsGetImageFromCurrentImageContext()
        tempCanvas.alpha = opacity
        UIGraphicsEndImageContext()
    }
    
    // Draw the brush size preview in settings
    func drawPreview() {
        UIGraphicsBeginImageContext(brushPreviewImage.frame.size)
        let context = UIGraphicsGetCurrentContext()
        
        CGContextSetLineCap(context, CGLineCap.Round)
        CGContextSetLineWidth(context, brushWidth)
        CGContextSetRGBStrokeColor(context, red, green, blue, 1.0)
        CGContextMoveToPoint(context, 45.0, 45.0)
        CGContextAddLineToPoint(context, 45.0, 45.0)
        CGContextStrokePath(context)
        brushPreviewImage.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
       
    }
    
}


struct Stack<Element> {
    var items = [Element]()
    mutating func push(item: Element) {
        items.append(item)
    }
    mutating func pop() -> Element {
        return items.removeLast()
    }
    
    mutating func isEmpty() -> Bool {
        if (items.count == 0)
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    mutating func clearStack()
    {
        items.removeAll()
    }
}



