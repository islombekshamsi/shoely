//
//  ContentView.swift
//  Shoesly
//
//  Created by Islom Shamsiev on 2025/9/25.
//

import SwiftUI

struct ContentView: View {
    @State private var shoesImages = ["shoe1", "shoe2", "shoe3"]
    @State private var shoesNames = ["Air Jordan 1", "Nike Air Force 1", "Adidas Ultraboost"]
    @State private var shoesDescriptions = [
        "The most iconic sneaker in the world.",
        "The ultimate running shoe.",
        "The most comfortable sneaker."
    ]
    @State private var shoesPrices = [150, 200, 180]
    @State private var shoesTrend = [true, true, false]
    
    @State private var topCardIndex = 0
    @State private var swipeOffset: CGSize = .zero
    @State private var swipeDirection: SwipeDirection? = nil
    @State private var showCartEffect = false
    
    enum SwipeDirection {
        case left, right
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Next card behind top card (peek effect)
                if topCardIndex + 1 < shoesImages.count {
                    cardView(
                        shoeImage: shoesImages[topCardIndex + 1],
                        shoeName: shoesNames[topCardIndex + 1],
                        shoePrice: shoesPrices[topCardIndex + 1],
                        shoetrendUp: shoesTrend[topCardIndex + 1],
                        shoeDescription: shoesDescriptions[topCardIndex + 1],
                        cardSize: geo.size
                    )
                    .scaleEffect(0.95)
                    .offset(y: 10)
                    .zIndex(1)
                    .animation(nil, value: topCardIndex)
                }
                
                // Top card
                if topCardIndex < shoesImages.count {
                    cardView(
                        shoeImage: shoesImages[topCardIndex],
                        shoeName: shoesNames[topCardIndex],
                        shoePrice: shoesPrices[topCardIndex],
                        shoetrendUp: shoesTrend[topCardIndex],
                        shoeDescription: shoesDescriptions[topCardIndex],
                        cardSize: geo.size
                    )
                    .offset(swipeOffset)
                    .rotationEffect(Angle(degrees: Double(swipeOffset.width / 15)))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                swipeOffset = value.translation
                                swipeDirection = swipeOffset.width > 0 ? .right : (swipeOffset.width < 0 ? .left : nil)
                            }
                            .onEnded { value in
                                let swipeThreshold: CGFloat = 120
                                let swipeVelocity = value.predictedEndTranslation.width
                                
                                if abs(swipeOffset.width) > swipeThreshold || abs(swipeVelocity) > 500 {
                                    withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 100, damping: 10, initialVelocity: 20)) {
                                        let flyAwayDistance: CGFloat = 1000
                                        swipeOffset.width = swipeOffset.width > 0 ? flyAwayDistance : -flyAwayDistance
                                        swipeOffset.height = value.translation.height * 0.5
                                    }
                                    
                                    if swipeOffset.width > 0 {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                            showCartEffect = true
                                        }
                                    }
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        if swipeOffset.width > 0 {
                                            addToCart()
                                        } else {
                                            showLater()
                                        }
                                        topCardIndex += 1
                                        swipeOffset = .zero
                                        swipeDirection = nil
                                        showCartEffect = false
                                    }
                                } else {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        swipeOffset = .zero
                                        swipeDirection = nil
                                    }
                                }
                            }
                    )
                    .zIndex(2)
                } else {
                    Text("You have gone through every product!")
                        .font(.title)
                        .foregroundColor(.gray)
                }
                
                // Friendly Cart Effect
                if showCartEffect {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.green)
                        .scaleEffect(showCartEffect ? 1.2 : 0.5)
                        .opacity(showCartEffect ? 1 : 0)
                        .animation(.easeInOut(duration: 0.3), value: showCartEffect)
                        .zIndex(3)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background(Color(.systemBackground))
        }
    }
    
    func addToCart() {
        print("Added to cart")
    }
    
    func showLater() {
        print("Marked to view later")
    }
}

struct cardView: View {
    var shoeImage: String
    var shoeName: String
    var shoePrice: Int
    var shoetrendUp: Bool
    var shoeDescription: String
    var cardSize: CGSize
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
            
            VStack {
                Image(shoeImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: cardSize.width * 0.7, height: cardSize.height * 0.4)
                    .cornerRadius(20)
                    .padding(.top, 40)
                
                VStack(spacing: 5) {
                    HStack {
                        Text("$\(shoePrice)")
                            .font(.system(size: cardSize.width * 0.12, weight: .semibold))
                            .foregroundColor(.black)
                        Image(systemName: shoetrendUp ? "chart.line.uptrend.xyaxis.circle" : "chart.line.downtrend.xyaxis.circle")
                            .foregroundColor(shoetrendUp ? .red : .green)
                            .font(.system(size: cardSize.width * 0.08, weight: .light))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 25)
                    
                    Text(shoeName)
                        .font(.system(size: cardSize.width * 0.09, weight: .semibold))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 25)
                    
                    Text(shoeDescription)
                        .font(.system(size: cardSize.width * 0.045, weight: .medium, design: .monospaced))
                        .multilineTextAlignment(.leading)
                        .lineLimit(5)
                        .padding(.leading, 25)
                        .padding(.trailing, 25)
                        .padding(.top, 10)
                }
            }
            .padding()
        }
        .frame(width: cardSize.width * 0.9, height: cardSize.height * 0.85)
    }
}

#Preview {
    ContentView()
}



extension View{
    // MARK: Disabling with opacity
    func disableWithOpacity(_ condition: Bool)-> some View{
        self
            .disabled(condition)
            .opacity(condition ? 0.5 : 1)
    }
    func hAlign(_ alignment: Alignment)-> some View{
        self.frame(maxWidth: .infinity, alignment: alignment)
    }
    
    func vAlign(_ alignment: Alignment)-> some View{
        self.frame(maxHeight: .infinity, alignment: alignment)
    }
    
    func border(_ width: CGFloat, _ color: Color)-> some View{
        self
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .background{
            RoundedRectangle(cornerRadius: 5, style: . continuous)
                .stroke(color, lineWidth: width)
        }
    }
    
    func fillView(_ color: Color)-> some View{
        self
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .background{
            RoundedRectangle(cornerRadius: 5, style: . continuous)
                .fill(color)
        }
    }
}
