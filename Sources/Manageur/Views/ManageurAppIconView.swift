import SwiftUI
import AppKit

public struct ManageurAppIconView: View {
    public var size: CGFloat
    
    public init(size: CGFloat = 20) {
        self.size = size
    }
    
    private static let templateImage: NSImage? = {
        let svgString = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="64" height="64">
          <path d="M0 0h16v16H0z" fill="none" />
          <path fill="#000000" d="M13.854 2.854a.5.5 0 0 0-.708-.708l-4.5 4.5a.5.5 0 0 0 0 .708l4.5 4.5a.5.5 0 0 0 .708-.708L9.707 7zm-11 1.292a.5.5 0 1 0-.708.708L6.293 9l-4.147 4.146a.5.5 0 0 0 .708.708l4.5-4.5a.5.5 0 0 0 0-.708z" />
        </svg>
        """
        guard let data = svgString.data(using: .utf8), let img = NSImage(data: data) else {
            return nil
        }
        img.isTemplate = true
        return img
    }()
    
    public var body: some View {
        if let img = Self.templateImage {
            Image(nsImage: img)
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        } else {
            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: size * 0.9, weight: .medium))
        }
    }
}
