//
//  ContentView.swift
//  Shoesly
//
//  Created by Islom Shamsiev on 2025/9/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.secondary.opacity(0.08))
                .stroke(Color.black, lineWidth: 0.5)
                .frame(width: 360, height: 600)
            VStack {
                Image("shoe1")
                    .resizable()
                    .frame(width: 250, height: 250)
                    /* .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .frame(width: 300, height: 500)
                    )*/
                    .cornerRadius(20)
                    .padding(.top, 100)
                VStack {
                    HStack {
                        Text("$150")
                            .font(.system(size: 55, weight: .semibold, design: .default))
                            .foregroundColor(.black)
                           
                        
                        Image(systemName: "chart.line.uptrend.xyaxis.circle")
                            .foregroundColor(.red)
                            .font(.system(size: 40, weight: .light))
                    }
                    .hAlign(.leading)
                    .padding(.leading, 25)
                    HStack {
                        Text("Nike Air Force 1")
                            .font(.system(size: 35, weight: .semibold, design: .default))
                            .foregroundColor(.gray)
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.green)
                            .frame(width: 15, height: 15)
                            .bold()
                            .padding(.leading, 5)
                        
                    }
                }
                        .vAlign(.top)
                        .hAlign(.center)
                
                
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}

struct cardView: View {
    @State var shoeImage: String
    @State var shoeName: String
    @State var shoePrice: String
    @State var shoetrendUp: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray)
                .stroke(Color.black, lineWidth: 4)
                .frame(width: 350, height: 500)
            VStack {
                Image("shoe1")
                    .resizable()
                    .frame(width: 250, height: 250)
            }
            .padding()
        }    }
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
