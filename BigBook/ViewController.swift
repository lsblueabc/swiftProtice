//
//  ViewController.swift
//  BigBook
//
//  Created by lushan on 2019/10/24.
//  Copyright © 2019 shanshan. All rights reserved.
//

import UIKit

protocol ExampleProtocol{
    
    var simpledescription:String{get}
    mutating func adjust()
    
}
class SimpleClass:ExampleProtocol{
    var simpledescription: String = "A very simple class"
    var anotherProperty:Int  = 69105
    func  adjust() {
        simpledescription += "Now 100% adjusted"
    }
}

protocol SparkTrajectory {
    var points:[CGPoint] {get set}
    var path:UIBezierPath {get}
}
struct CubicBezierTrajectory:SparkTrajectory {
   var points=[CGPoint]()
    init(_ x0:CGFloat,_ y0:CGFloat,
         _ x1:CGFloat,_ y1:CGFloat,
         _ x2:CGFloat,_ y2:CGFloat,
         _ x3:CGFloat,_ y3:CGFloat){
        self.points.append(CGPoint(x: x0, y: y0));
        self.points.append(CGPoint(x: x1, y: y1));
        self.points.append(CGPoint(x: x2, y: y2));
        self.points.append(CGPoint(x: x3, y: y3));
    }
    var path:UIBezierPath{
        guard self.points.count == 4 else {fatalError("4 points required")}
        let path  = UIBezierPath()
        path.move(to: self.points[0])
        path.addCurve(to: self.points[3], controlPoint1: self.points[1], controlPoint2: self.points[2]);
        return path
    }
  
}

protocol SparkTrajectoryFactory {}
protocol ClassicSparkTrajectoryFactoryProtocol:SparkTrajectoryFactory {
    func randomTopRight() -> SparkTrajectory
    func randomBottomRight() -> SparkTrajectory
}

final class ClassicSparkTrajectoryFactory:ClassicSparkTrajectoryFactoryProtocol{
    private lazy var topRight:[SparkTrajectory] = {
        return [
            CubicBezierTrajectory(0.00,0.00,0.31,-0.46,0.74,-0.29,0.99,0.12),
            CubicBezierTrajectory(0.00,0.00,0.31,-0.46,0.62,-0.49,0.88,-0.19),
            CubicBezierTrajectory(0.00, 0.00, 0.10, -0.54, 0.44, -0.53, 0.66, -0.30),
            CubicBezierTrajectory(0.00, 0.00, 0.19, -0.46, 0.41, -0.53, 0.65, -0.45),
        ]
    }()
    
    private lazy var bottomRight: [SparkTrajectory] = {
        return [
            CubicBezierTrajectory(0.00, 0.00, 0.42, -0.01, 0.68, 0.11, 0.87, 0.44),
            CubicBezierTrajectory(0.00, 0.00, 0.35, 0.00, 0.55, 0.12, 0.62, 0.45),
            CubicBezierTrajectory(0.00, 0.00, 0.21, 0.05, 0.31, 0.19, 0.32, 0.45),
            CubicBezierTrajectory(0.00, 0.00, 0.18, 0.00, 0.31, 0.11, 0.35, 0.25),
        ]
    }()
    
    func randomTopRight() -> SparkTrajectory {
        return self.topRight[Int(arc4random_uniform(UInt32(self.topRight.count)))]
    }
    
    func randomBottomRight() -> SparkTrajectory {
        return self.bottomRight[Int(arc4random_uniform(UInt32(self.bottomRight.count)))]
    }
    
}

class SparkView:UIView{}

final class CircleColorsSparkView:SparkView{
    init(color:UIColor,size:CGSize){
        super.init(frame: CGRect(origin: .zero, size: size))
        self.backgroundColor = color
        self.layer.cornerRadius = self.frame.width/2.0;
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}

extension UIColor {
    static var sparkColorSet1:[UIColor] = {
        return [
            UIColor(red:0.89, green:0.58, blue:0.70, alpha:1.00),
            UIColor(red:0.96, green:0.87, blue:0.62, alpha:1.00),
            UIColor(red:0.67, green:0.82, blue:0.94, alpha:1.00),
            UIColor(red:0.54, green:0.56, blue:0.94, alpha:1.00),
        ]
    }()
}

protocol SparkViewFactoryData {
    var size:CGSize{get}
    var index:Int {get}
}

protocol SparkViewFactory {
    func create(with data:SparkViewFactoryData) -> SparkView
}

public struct DefaultSparkViewFactoryData:SparkViewFactoryData{
    public let size:CGSize
    public let index: Int
}



class CircleColorSparkViewFactory:SparkViewFactory{
    var colors:[UIColor]{
        return UIColor.sparkColorSet1
    }
    func create(with data: SparkViewFactoryData) -> SparkView {
        let color = self.colors[data.index % self.colors.count]
        return CircleColorsSparkView(color: color, size: data.size)
    }
}

typealias FireworkSpark = (sparkView:SparkView,trajectory:SparkTrajectory)

protocol Firework {
    //烟花初始位置
    var origin:CGPoint {get set}
    //展示屏幕前，放大
    var scale:CGFloat {get set}
    //火花的大小
    var sparkSize:CGSize{get set}
    //获取轨迹
    var trajectoryFactory:SparkTrajectoryFactory{get}
    
    func sparkViewFactoryData(at index:Int) -> SparkViewFactoryData
    func sparkView(at index:Int)->SparkView
    func trajectory(at index:Int)-> SparkTrajectory
}

extension Firework {
    func spark(at index:Int)->FireworkSpark{
        return FireworkSpark(self.sparkView(at: index),self.trajectory(at: index))
    }
}

extension CGPoint {
    mutating func add(vector:CGVector){
        self.x += vector.dx
        self.y += vector.dy
        
    }
    
    func adding(vector:CGVector)->CGPoint {
        var copy = self
        copy.add(vector: vector)
        return copy
    }
    
    mutating func multiply(by value:CGFloat){
        self.x *= value
        self.y *= value
    }
    
    
}






extension SparkTrajectory {
    
    /// 缩放轨迹使其符合各种 UI 的要求
    /// 在各种形变和 shift: 之前使用
    func scale(by value: CGFloat) -> SparkTrajectory {
        var copy = self
        (0..<self.points.count).forEach{copy.points[$0].multiply(by: value) }
        return copy
        
    }
    
    /// 水平翻转轨迹
    func flip() -> SparkTrajectory {
        var copy = self
        (0..<self.points.count).forEach { copy.points[$0].x *= -1 }
        return copy
    }
    
    /// 偏移轨迹，在每个点上生效
    /// 在各种形变和 scale: 和之后使用
    func shift(to point: CGPoint) -> SparkTrajectory {
        var copy = self
        let vector = CGVector(dx: point.x, dy: point.y)
        (0..<self.points.count).forEach { copy.points[$0].add(vector: vector) }
        return copy
    }
}

class ClassicFirework:Firework {
    
    private struct FlipOptions:OptionSet {
        let rawValue :Int
        static let horizontally = FlipOptions(rawValue:1<<0)
        static let vertically = FlipOptions(rawValue: 1<<1)
    }
    
    
    private enum Quarter {
        case topRight
        case bottomRight
        case bottomLeft
        case topLeft
    }
    
    var origin: CGPoint
    var scale: CGFloat
    var sparkSize: CGSize
    
    var maxChangeValue:Int {
        return 10
    }
    
    var trajectoryFactory: SparkTrajectoryFactory{
        return ClassicSparkTrajectoryFactory()
    }
    
    var calssicTrajectoryFactory:ClassicSparkTrajectoryFactoryProtocol{
        return self.trajectoryFactory as! ClassicSparkTrajectoryFactoryProtocol
    }
    
    var sparkViewFactory:SparkViewFactory {
        return CircleColorSparkViewFactory()
    }
    
    private var quarters = [Quarter]()
    
    private func flipOptions(`for` quarter: Quarter)->FlipOptions{
        var flipOptions:FlipOptions = []
        if quarter == .bottomLeft || quarter == .topLeft{
            flipOptions.insert(.horizontally)
        }
        if quarter == .bottomLeft || quarter == .bottomRight {
            flipOptions.insert(.vertically)
        }
        return flipOptions
    }
    
    private func shuffledQuarters()->[Quarter]{
        var quarters:[Quarter] = [
            .topRight,.topRight,
            .bottomRight,.bottomRight,
            .bottomLeft,.bottomLeft,
            .topLeft,.topLeft]
        
        var shuffled = [Quarter]()
        for _ in 0..<quarters.count{
            let idx = Int(arc4random_uniform(UInt32(quarters.count)))
            shuffled.append(quarters[idx])
            quarters.remove(at: idx)
        }
        return shuffled
    }
    
    private func randomTrajectory(flipOptions:FlipOptions)->SparkTrajectory{
        var trajectory:SparkTrajectory
        if flipOptions.contains(.vertically){
            trajectory = self.calssicTrajectoryFactory.randomBottomRight()
        }else{
            trajectory = self.calssicTrajectoryFactory.randomTopRight()
        }
        
        return flipOptions.contains(.horizontally) ? trajectory.flip() : trajectory
    }
    private func randomChange(_ maxValue:Int) -> CGFloat {
        return CGFloat(arc4random_uniform(UInt32(maxValue)))
    }
    
    
    private func randowChangeVector(flipOptions:FlipOptions,maxValue:Int) -> CGVector {
         let values = (self.randomChange(maxValue), self.randomChange(maxValue))
               let changeX = flipOptions.contains(.horizontally) ? -values.0 : values.0
               let changeY = flipOptions.contains(.vertically) ? values.1 : -values.0
               return CGVector(dx: changeX, dy: changeY)
    }
    
    
    init(origin:CGPoint,sparkSize:CGSize,scale:CGFloat) {
        self.origin = origin
        self.scale = scale
        self.sparkSize = sparkSize
        self.quarters = self.shuffledQuarters()
    }
    
    func sparkViewFactoryData(at index: Int) -> SparkViewFactoryData {
        return DefaultSparkViewFactoryData(size:self.sparkSize,index:index)
    }
    
    func sparkView(at index: Int) -> SparkView {
        return self.sparkViewFactory.create(with: self.sparkViewFactoryData(at: index))
        
    }
    private func randomChangeVector(flipOptions:FlipOptions,maxValue:Int) ->CGVector {
        let values = (self.randomChange(maxValue),self.randomChange(maxValue))
        let changeX = flipOptions.contains(.horizontally) ? -values.0 : values.0
        let changeY = flipOptions.contains(.vertically) ? values.1:-values.0
        return CGVector(dx:changeX,dy:changeY)
        
    }
    
    func trajectory(at index:Int) ->SparkTrajectory{
        let quarter = self.quarters[index]
        let flipOptions = self.flipOptions(for:quarter)
        let changeVector = self.randomChangeVector(flipOptions: flipOptions, maxValue: self.maxChangeValue)
        let sparkOrigin = self.origin.adding(vector: changeVector)
        return self.randomTrajectory(flipOptions: flipOptions).scale(by:self.scale).shift(to:sparkOrigin)
    }
    
    
}
protocol SparkViewAnimator{
    func animate(spark:FireworkSpark,duration:TimeInterval)
}

struct ClassicFireworkAnimator:SparkViewAnimator {
    func animate(spark: FireworkSpark, duration: TimeInterval) {
        spark.sparkView.isHidden = false
        CATransaction.begin()
         let positionAnim = CAKeyframeAnimation(keyPath: "position")
             positionAnim.path = spark.trajectory.path.cgPath
        positionAnim.calculationMode = CAAnimationCalculationMode.linear
        positionAnim.rotationMode = CAAnimationRotationMode.rotateAuto
        positionAnim.duration = duration
        
        
        let randomMaxScale = 1.0 + CGFloat(arc4random_uniform(7))
        let randomMinScale = 0.5 + CGFloat(arc4random_uniform(3))
        let fromTransform = CATransform3DIdentity
        let byTransform = CATransform3DScale(fromTransform, CGFloat(randomMaxScale), CGFloat(randomMaxScale), CGFloat(randomMaxScale))
        let toTransform = CATransform3DScale(CATransform3DIdentity, randomMinScale, randomMinScale, randomMinScale)
        let transforAnim = CAKeyframeAnimation(keyPath: "transform")
        
        transforAnim.values = [
            NSValue(caTransform3D:fromTransform),
            NSValue(caTransform3D:byTransform),
        NSValue(caTransform3D: toTransform)]
        
        transforAnim.duration = duration
        transforAnim.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        spark.sparkView.layer.transform = toTransform
        
        let opacityAnim = CAKeyframeAnimation(keyPath: "opaccity")
        opacityAnim.values = [1.0,0.0]
        opacityAnim.keyTimes = [0.95,0.98]
        opacityAnim.duration = duration
        spark.sparkView.layer.opacity = 0.0
        
        let groupAnimation = CAAnimationGroup()
        groupAnimation.animations = [positionAnim,transforAnim,opacityAnim]
        groupAnimation.duration = duration
        
        CATransaction.setCompletionBlock {
            spark.sparkView.removeFromSuperview()
        }
        spark.sparkView.layer.add(groupAnimation,forKey: "spark-animation")
        CATransaction.commit()
        
    }
}

class ClassicFireworkController{
    var sparkAnimator:SparkViewAnimator{
        return ClassicFireworkAnimator()
    }
    func createFirework(at orgin:CGPoint,sparkSize:CGSize,scale:CGFloat)->Firework {
        return ClassicFirework(origin: orgin, sparkSize: sparkSize, scale: scale)
    }
    func addFireworks(count fireworksCount:Int=1,sparks sparksCount:Int,around sourceView:UIView,
                      sparkSize:CGSize = CGSize(width: 7, height: 7),scale:CGFloat=45.0,maxVectorChange:CGFloat=15.0,
                      animationDuration:TimeInterval = 0.4,canChangeZIndex:Bool = true){
        guard let superview = sourceView.superview else { fatalError()}
        let origins = [
            CGPoint(x:sourceView.frame.minX,y:sourceView.frame.minY),
            CGPoint(x:sourceView.frame.maxX,y:sourceView.frame.minY),
            CGPoint(x: sourceView.frame.minX, y: sourceView.frame.maxY),
            CGPoint(x: sourceView.frame.maxX, y: sourceView.frame.maxY),]
        
       for _ in 0..<fireworksCount {
                  let idx = Int(arc4random_uniform(UInt32(origins.count)))
                  let origin = origins[idx].adding(vector: self.randomChangeVector(max: maxVectorChange))

                  let firework = self.createFirework(at: origin, sparkSize: sparkSize, scale: scale)

                  for sparkIndex in 0..<sparksCount {
                      let spark = firework.spark(at: sparkIndex)
                      spark.sparkView.isHidden = true
                      superview.addSubview(spark.sparkView)

                      if canChangeZIndex {
                          let zIndexChange: CGFloat = arc4random_uniform(2) == 0 ? -1 : +1
                          spark.sparkView.layer.zPosition = sourceView.layer.zPosition + zIndexChange
                      } else {
                          spark.sparkView.layer.zPosition = sourceView.layer.zPosition
                      }

                      self.sparkAnimator.animate(spark: spark, duration: animationDuration)
                  }
              }
          }

          private func randomChangeVector(max: CGFloat) -> CGVector {
              return CGVector(dx: self.randomChange(max: max), dy: self.randomChange(max: max))
          }

          private func randomChange(max: CGFloat) -> CGFloat {
              return CGFloat(arc4random_uniform(UInt32(max))) - (max / 2.0)
          }
        
    }
    
  
    






class ViewController: UIViewController {
 var fireworkController = ClassicFireworkController()
   @objc func tapClick(sender:UIButton){
           self.fireworkController.addFireworks(sparks: 8, around: sender)
       }
    override func viewDidLoad() {
       
        super.viewDidLoad()
          
       
        
        self.view.backgroundColor = UIColor .orange
        let button = UIButton()
        button.frame = CGRect(x: 100, y: 100, width: 100, height: 100);
        button.backgroundColor = UIColor.blue
        button.addTarget(self, action:#selector(tapClick(sender:)), for: .touchUpInside)
        self.view .addSubview(button);
        
       
    }
    
  
}

