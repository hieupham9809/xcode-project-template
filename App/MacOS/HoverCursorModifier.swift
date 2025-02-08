//
//  HoverCursorMidifier.swift
//  SwiftClean
//
//  Created by Harley Pham on 27/7/24.
//

import SwiftUI
/// https://stackoverflow.com/a/75310109
public struct HoverCursorModifier: ViewModifier {
    
    @State var isHovered: Bool = false
    
    let pointerImage : NSImage
    
    init(imageName: String){
        self.pointerImage = NSImage(named: imageName) ?? NSImage()
    }
    
    init(systemSymbolName: String){
        self.pointerImage = NSImage(systemSymbolName: systemSymbolName , accessibilityDescription: nil) ?? NSImage()
    }
    
    public func body(content: Content) -> some View {
        
        content
            .onHover { isHovered in
                self.isHovered = isHovered
                
                DispatchQueue.main.async {
                    
                    if self.isHovered {
                        // Looks like ugly hack, but otherwise cursor gets reset to standard arrow.
                        // See https://stackoverflow.com/a/62984079/7964697 for details.
                        NSApp.windows.forEach { $0.disableCursorRects() }
                        NSCursor(image: pointerImage, hotSpot: NSPoint(x: 9, y: 9)).push()
                    } else {
                        NSCursor.pop()
                        NSApp.windows.forEach { $0.enableCursorRects() }
                    }
                    
                }
            } 
    }
}

extension View {
    func applyHoveringCursor() -> some View {
        self.modifier(HoverCursorModifier(systemSymbolName: "hand.point.up.fill"))
    }
}
