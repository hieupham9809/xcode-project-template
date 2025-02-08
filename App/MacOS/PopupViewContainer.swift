//
//  PopupViewContainer.swift
//  SwiftClean
//
//  Created by Harley Pham on 4/8/24.
//
// A general popup view container that can be used to display any popup view.

import SwiftUI

struct PopupViewContainer<Content: View>: View {
    @Binding var isPresented: Bool
    @State private var contentSize: CGSize = .zero
    let content: Content
    let canTapOutsideToDismiss: Bool = true
    
    init(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isPresented = isPresented
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            if isPresented {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        if canTapOutsideToDismiss {
                            isPresented = false
                        }
                    }
                
                VStack(spacing: 0) {
                    HStack {
                        Spacer()

                        Image(.icPopupClose)
                            .resizable()
                            .frame(width: 20, height: 20)
                            .padding(10)
                            .onTapGesture {
                                isPresented = false
                            }
                    }

                    content
                        .size {
                            contentSize = $0
                        }
                }
                .frame(minWidth: 200, maxWidth: 400, maxHeight: 400)
                .frame(height: contentSize.height + 40)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 4)
            }
        }
    }
}

#Preview {
    PopupViewContainer(isPresented: .constant(true), content: {
        Rectangle().frame(height: 50)
    })
}
