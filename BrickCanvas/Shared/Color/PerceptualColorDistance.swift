import Foundation

struct CIELabColor: Hashable, Sendable {
    let lightness: Double
    let a: Double
    let b: Double
}

enum PerceptualColorDistance {
    static func distance(between lhs: RGBColor, and rhs: RGBColor) -> Double {
        let leftLab = labColor(for: lhs)
        let rightLab = labColor(for: rhs)

        let deltaLightness = leftLab.lightness - rightLab.lightness
        let deltaA = leftLab.a - rightLab.a
        let deltaB = leftLab.b - rightLab.b

        return sqrt((deltaLightness * deltaLightness) + (deltaA * deltaA) + (deltaB * deltaB))
    }

    static func naiveRGBDistance(between lhs: RGBColor, and rhs: RGBColor) -> Double {
        let deltaRed = Double(Int(lhs.red) - Int(rhs.red))
        let deltaGreen = Double(Int(lhs.green) - Int(rhs.green))
        let deltaBlue = Double(Int(lhs.blue) - Int(rhs.blue))

        return sqrt((deltaRed * deltaRed) + (deltaGreen * deltaGreen) + (deltaBlue * deltaBlue))
    }

    static func labColor(for color: RGBColor) -> CIELabColor {
        let xyz = xyzColor(for: color)
        let x = pivotXYZComponent(xyz.x / 0.95047)
        let y = pivotXYZComponent(xyz.y / 1.00000)
        let z = pivotXYZComponent(xyz.z / 1.08883)

        return CIELabColor(
            lightness: (116.0 * y) - 16.0,
            a: 500.0 * (x - y),
            b: 200.0 * (y - z)
        )
    }

    private static func xyzColor(for color: RGBColor) -> (x: Double, y: Double, z: Double) {
        let red = linearizedSRGBComponent(color.red)
        let green = linearizedSRGBComponent(color.green)
        let blue = linearizedSRGBComponent(color.blue)

        return (
            x: (red * 0.4124564) + (green * 0.3575761) + (blue * 0.1804375),
            y: (red * 0.2126729) + (green * 0.7151522) + (blue * 0.0721750),
            z: (red * 0.0193339) + (green * 0.1191920) + (blue * 0.9503041)
        )
    }

    private static func linearizedSRGBComponent(_ component: UInt8) -> Double {
        let normalized = Double(component) / 255.0

        if normalized <= 0.04045 {
            return normalized / 12.92
        }

        return pow((normalized + 0.055) / 1.055, 2.4)
    }

    private static func pivotXYZComponent(_ value: Double) -> Double {
        let delta = 6.0 / 29.0
        let threshold = pow(delta, 3.0)

        if value > threshold {
            return pow(value, 1.0 / 3.0)
        }

        return (value / (3.0 * delta * delta)) + (4.0 / 29.0)
    }
}
