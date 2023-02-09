//
//  File.swift
//  
//
//  Created by Secret Asian Man Dev on 9/2/23.
//

import Foundation

struct ImageBuffer {
    public let ptr: UnsafeMutableRawPointer
    public let width: Int
    public let height: Int
    public static let Channels = 4 // BGRA
    
    subscript(_ point: Point) -> Int8 {
        get {
            let offset = ((width * point.y) + point.x) * ImageBuffer.Channels
            return ptr.load(fromByteOffset: offset, as: Int8.self)
        }
        set {
            let offset = ((width * point.y) + point.x) * ImageBuffer.Channels
            ptr.storeBytes(of: newValue, toByteOffset: offset, as: Int8.self)
        }
    }
}

enum Direction {
    case up, down, left, right, topLeft, topRight, bottomLeft, bottomRight

    var clockwise: Direction {
        switch self {
        case .up: return .topRight
        case .topRight: return .right
        case .right: return .bottomRight
        case .bottomRight: return .down
        case .down: return .bottomLeft
        case .bottomLeft: return .left
        case .left: return .topLeft
        case .topLeft: return .up
        }
    }

    var counterClockwise: Direction {
        switch self {
        case .up: return .topLeft
        case .topLeft: return .left
        case .left: return .bottomLeft
        case .bottomLeft: return .down
        case .down: return .bottomRight
        case .bottomRight: return .right
        case .right: return .topRight
        case .topRight: return .up
        }
    }
}

struct Point: Hashable, Equatable, Codable {
    let x: Int
    let y: Int

    func direction(relativeTo other: Point) -> Direction {
        if y < other.y {
            if x < other.x {
                return .topLeft
            } else if x == other.x {
                return .up
            } else {
                return .topRight
            }
        } else if y == other.y {
            if x < other.x {
                return .left
            } else if x == other.x {
                fatalError("Cannot get direction of point relative to itself")
            } else {
                return .right
            }
        } else {
            if x < other.x {
                return .bottomLeft
            } else if x == other.x {
                return .down
            } else {
                return .bottomRight
            }
        }
    }

    subscript(_ direction: Direction) -> Point {
        switch direction {
        case .up:          return Point(x: x, y: y-1)
        case .down:        return Point(x: x, y: y+1)
        case .left:        return Point(x: x-1, y: y)
        case .right:       return Point(x: x+1, y: y)
        case .topLeft:     return Point(x: x-1, y: y-1)
        case .topRight:    return Point(x: x+1, y: y-1)
        case .bottomLeft:  return Point(x: x-1, y: y+1)
        case .bottomRight: return Point(x: x+1, y: y+1)
        }
    }
}

enum BorderType { case outer, hole }

func border(img: inout ImageBuffer) -> Void {
    var NBD: Int8 = 1
    var parent: [Int8: Int8] = [1: 1]
    var borderTypes: [Int8: BorderType] = [1: .outer]
    var borderPoints: [Int8: [Point]] = [:]

    // Fill border with 0's
    for x in 0..<img.width {
        img[Point(x: x, y: 0)] = 0
        img[Point(x: x, y: img.height - 1)] = 0
    }
    for y in 0..<img.height {
        img[Point(x: 0, y: y)] = 0
        img[Point(x: img.width - 1, y: y)] = 0
    }

    func searchClockwise(around pivot: Point, start: Point) -> Point? {
        var dxn = start.direction(relativeTo: pivot)
        for _ in 0..<7 {
            dxn = dxn.clockwise
            if img[pivot[dxn]] != 0 {
                return pivot[dxn]
            }
        }
        return nil
    }

    func searchCounterclockwise(around pivot: Point, start: Point) -> (Point, Bool) {
        var dxn = start.direction(relativeTo: pivot)
        var rightZero = false
        for _ in 0..<8 {
            dxn = dxn.counterClockwise
            let pixel = pivot[dxn]
            if dxn == .right && img[pixel] == 0 {
                rightZero = true
            }
            if img[pixel] != 0 {
                return (pixel, rightZero)
            }
        }
        fatalError("Unreachable code")
    }

    func follow(borderStart: Point, zeroPixel: Point) -> Void {
        let clockwisePixel = searchClockwise(around: borderStart, start: zeroPixel)
        guard let clockwisePixel else {
            img[borderStart] = -NBD
            borderPoints[NBD, default: []].append(borderStart)
            return
        }

        var prevPixel = clockwisePixel
        var target = borderStart

        /// For fear of an infinite loop, replace `while True:`.
        /// Since there must be fewer border pixels than image pixels, this loop won't terminate early.
        for _ in 0..<(img.width * img.height) {
            let (nextPixel, rightZero) = searchCounterclockwise(around: target, start: prevPixel)
            if rightZero {
                img[target] = -NBD
                borderPoints[NBD, default: []].append(target)
            } else if !rightZero && img[target] == 1 {
                img[target] = +NBD
                borderPoints[NBD, default: []].append(target)
            }

            if nextPixel == borderStart && target == clockwisePixel {
                return
            } else {
                prevPixel = target
                target = nextPixel
            }
        }

        assert(false, "Infinite loop detected")
    }

    for row in 1..<(img.height-1) {
        var LNBD: Int8 = 1
        for col in 1..<(img.width-1) {
            if (img[Point(x: col, y: row)] == 1) && (img[Point(x: col-1, y: row)] == 0) {
                NBD += 1
                borderTypes[NBD] = .outer
                let zeroPixel = Point(x: col-1, y: row)
                
                if borderTypes[parent[LNBD]!] == .outer {
                    parent[NBD] = parent[LNBD]
                } else {
                    parent[NBD] = LNBD
                }

                follow(borderStart: Point(x: col, y: row), zeroPixel: zeroPixel)
            } else if (img[Point(x: col, y: row)] >= 1) && (img[Point(x: col+1, y: row)] == 0) {
                NBD += 1
                borderTypes[NBD] = .hole
                let zeroPixel = Point(x: col+1, y: row)
                if img[Point(x: col, y: row)] > 1 {
                    LNBD = img[Point(x: col, y: row)]
                }
                
                if borderTypes[parent[LNBD]!] == .outer {
                    parent[NBD] = LNBD
                } else {
                    parent[NBD] = parent[LNBD]
                }

                follow(borderStart: Point(x: col, y: row), zeroPixel: zeroPixel)
            } else {
                continue
            }

            if img[Point(x: col, y: row)] != 1 {
                LNBD = abs(img[Point(x: col, y: row)])
            }
        }
    }

    /// Print out the border points
    for (NBD, points) in borderPoints {
        print("NBD \(NBD): \(points)")
    }
}
