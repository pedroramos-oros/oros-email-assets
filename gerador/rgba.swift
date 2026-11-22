import Foundation
import AppKit
// Uso: rgba <in.png> <out.raw>  -> 4 bytes w, 4 bytes h (LE) + RGBA nao premultiplicado
let a = CommandLine.arguments
guard a.count >= 3, let img = NSImage(contentsOfFile: a[1]), let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else { print("erro"); exit(1) }
let w = cg.width, h = cg.height
var px = [UInt8](repeating: 0, count: w*h*4)
let ctx = CGContext(data: &px, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w*4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
for i in 0..<(w*h) { let o=i*4; let al=Int(px[o+3]); if al>0 && al<255 { for c in 0..<3 { px[o+c]=UInt8(min(255, Int(px[o+c])*255/al)) } } }
var out = Data()
var ww = UInt32(w).littleEndian, hh = UInt32(h).littleEndian
out.append(Data(bytes: &ww, count: 4)); out.append(Data(bytes: &hh, count: 4)); out.append(Data(px))
try out.write(to: URL(fileURLWithPath: a[2]))
print(w, h)
