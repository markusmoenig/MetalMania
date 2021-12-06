//
//  MathLibrary.swift
//  Zoubar
//
//  Created by Markus Moenig on 4/12/21.
//

import simd

public typealias float2 = SIMD2<Float>
public typealias float3 = SIMD3<Float>
public typealias float4 = SIMD4<Float>

public let π = Float.pi

extension Float {
    var radiansToDegrees: Float {
        (self / π) * 180
    }
    var degreesToRadians: Float {
        (self / 180) * π
    }
}

extension Double {
    var radiansToDegrees: Double {
        (self / Double.pi) * 180
    }
    var degreesToRadians: Double {
        (self / 180) * Double.pi
    }
}
