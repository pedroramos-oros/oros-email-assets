import Foundation
import AppKit
import WebKit

// Uso: swift snap.swift <url> <saida.png> <largura> <altura> [timeoutSegundos]
// Renderiza a pagina em tamanho exato (px CSS = px da imagem) e salva PNG.
// A pagina avisa que terminou setando document.body.dataset.ready = "1".
let a = CommandLine.arguments
guard a.count >= 5, let w = Double(a[3]), let h = Double(a[4]) else {
    print("uso: snap <url> <out.png> <w> <h> [timeout]"); exit(1)
}
let timeout = a.count >= 6 ? (Double(a[5]) ?? 20) : 20

final class Delegate: NSObject, WKNavigationDelegate {
    var loaded = false
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { loaded = true }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { print("falhou:", error); exit(2) }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { print("falhou:", error); exit(2) }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let cfg = WKWebViewConfiguration()
let web = WKWebView(frame: NSRect(x: 0, y: 0, width: w, height: h), configuration: cfg)
let transparent = a.count >= 7 && a[6] == "transparent"
if transparent { web.setValue(false, forKey: "drawsBackground") }
let win = NSWindow(contentRect: NSRect(x: -4000, y: -4000, width: w, height: h), styleMask: [.borderless], backing: .buffered, defer: false)
if transparent { win.isOpaque = false; win.backgroundColor = .clear }
win.contentView = web
win.orderFrontRegardless()
let del = Delegate()
web.navigationDelegate = del
web.load(URLRequest(url: URL(string: a[1])!))

let start = Date()
func finish() {
    let sc = WKSnapshotConfiguration()
    sc.rect = NSRect(x: 0, y: 0, width: w, height: h)
    sc.snapshotWidth = NSNumber(value: w)
    web.takeSnapshot(with: sc) { img, err in
        guard let img = img, let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            print("snapshot falhou:", String(describing: err)); exit(3)
        }
        try? png.write(to: URL(fileURLWithPath: a[2]))
        print("ok", a[2], Int(rep.pixelsWide), "x", Int(rep.pixelsHigh))
        exit(0)
    }
}
Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { t in
    if Date().timeIntervalSince(start) > timeout { print("timeout (sem ready)"); finish(); t.invalidate(); return }
    guard del.loaded else { return }
    web.evaluateJavaScript("document.body && document.body.dataset.ready") { r, _ in
        if let s = r as? String, s == "1" { t.invalidate(); DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { finish() } }
    }
}
app.run()
