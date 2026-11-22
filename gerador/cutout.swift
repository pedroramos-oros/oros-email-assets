import Foundation
import Vision
import CoreImage
import AppKit

// Uso: swift cutout.swift <entrada> <saida.png> cropX cropY cropW cropH ellCX ellCY ellRX ellRY
// 1) recorta a regiao, 2) mascara de primeiro plano (Vision), 3) limita a uma elipse
// (cabeca + fone), 4) remove o contorno vermelho da miniatura, 5) afina a borda e corta no tamanho da elipse.
let a = CommandLine.arguments
guard a.count >= 13 else { print("uso: cutout in out cx cy cw ch ex ey erx ery"); exit(1) }
let d = a[3...12].compactMap { Double($0) }
guard d.count == 10 else { print("numeros invalidos"); exit(1) }
guard let nsImage = NSImage(contentsOfFile: a[1]),
      var cg = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { print("nao abriu"); exit(1) }
if let c = cg.cropping(to: CGRect(x: d[0], y: d[1], width: d[2], height: d[3])) { cg = c }
let W = cg.width, H = cg.height

let handler = VNImageRequestHandler(cgImage: cg, options: [:])
let req = VNGenerateForegroundInstanceMaskRequest()
try handler.perform([req])
guard let res = req.results?.first else { print("sem mascara"); exit(2) }
let maskBuf = try res.generateScaledMaskForImage(forInstances: res.allInstances, from: handler)

// monta RGBA bruto
let cs = CGColorSpaceCreateDeviceRGB()
var px = [UInt8](repeating: 0, count: W * H * 4)
let ctx = CGContext(data: &px, width: W, height: H, bitsPerComponent: 8, bytesPerRow: W * 4, space: cs,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.draw(cg, in: CGRect(x: 0, y: 0, width: W, height: H))

// mascara do Vision -> array de alpha
let mci = CIImage(cvPixelBuffer: maskBuf)
let cictx = CIContext()
var m = [UInt8](repeating: 0, count: W * H)
let gray = CGColorSpaceCreateDeviceGray()
cictx.render(mci, toBitmap: &m, rowBytes: W, bounds: CGRect(x: 0, y: 0, width: W, height: H), format: .L8, colorSpace: gray)

let ex = d[4], ey = d[5], erx = d[6], ery = d[7], erx2 = d[8], ery2 = d[9]
var alpha = [Float](repeating: 0, count: W * H)
for y in 0..<H {
    for x in 0..<W {
        let i = y * W + x
        // CoreImage tem origem embaixo; a mascara renderizada em bitmap ja vem na ordem de linhas do topo
        var al = Float(m[i]) / 255
        // elipse (suave nas bordas)
        let lower = Double(y) > ey
        let nx = (Double(x) - ex) / (lower ? erx2 : erx), ny = (Double(y) - ey) / (lower ? ery2 : ery)
        let r = nx * nx + ny * ny
        if r > 1 { al = 0 } else if r > 0.97 { al *= Float((1 - r) / 0.03) }
        // vermelho do contorno da miniatura
        let o = i * 4
        let pr = Int(px[o]), pg = Int(px[o + 1]), pb = Int(px[o + 2])
        if pr > 170 && pg < 80 && pb < 100 && pr - pg > 110 { al = 0 }
        alpha[i] = al
    }
}
// erosao de 3 px (min em janela) para tirar o resto da borda branca/vermelha
func erode(_ src: [Float], _ r: Int) -> [Float] {
    var tmp = src, out = src
    for y in 0..<H { for x in 0..<W {
        var mn: Float = 1
        for k in -r...r { let xx = min(max(x + k, 0), W - 1); mn = min(mn, src[y * W + xx]) }
        tmp[y * W + x] = mn } }
    for y in 0..<H { for x in 0..<W {
        var mn: Float = 1
        for k in -r...r { let yy = min(max(y + k, 0), H - 1); mn = min(mn, tmp[yy * W + x]) }
        out[y * W + x] = mn } }
    return out
}
alpha = erode(alpha, 3)
// suaviza a borda (media 3x3)
var sm = alpha
for y in 1..<(H - 1) { for x in 1..<(W - 1) {
    var s: Float = 0
    for dy in -1...1 { for dx in -1...1 { s += alpha[(y + dy) * W + x + dx] } }
    sm[y * W + x] = s / 9 } }
alpha = sm

// aplica alpha (premultiplicado) e corta no bbox da elipse
let bx0 = max(0, Int(ex - erx)), bx1 = min(W, Int(ex + erx)), by0 = max(0, Int(ey - ery)), by1 = min(H, Int(ey + ery2))
let OW = bx1 - bx0, OH = by1 - by0
var outpx = [UInt8](repeating: 0, count: OW * OH * 4)
for y in by0..<by1 { for x in bx0..<bx1 {
    let i = y * W + x, o = i * 4
    let al = alpha[i]
    // px esta premultiplicado pelo alpha=1 (foto opaca), entao RGB e cor cheia
    let oo = ((y - by0) * OW + (x - bx0)) * 4
    outpx[oo] = UInt8(Float(px[o]) * al)
    outpx[oo + 1] = UInt8(Float(px[o + 1]) * al)
    outpx[oo + 2] = UInt8(Float(px[o + 2]) * al)
    outpx[oo + 3] = UInt8(al * 255)
} }
let octx = CGContext(data: &outpx, width: OW, height: OH, bitsPerComponent: 8, bytesPerRow: OW * 4, space: cs,
                     bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
let outImg = octx.makeImage()!
let rep = NSBitmapImageRep(cgImage: outImg)
try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: a[2]))
print("ok", a[2], OW, "x", OH)
