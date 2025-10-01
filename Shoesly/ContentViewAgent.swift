import SwiftUI
import Foundation

// MARK: - Data Models
struct ProductListResponse: Codable {
    let data: [ProductData]
    let meta: Meta?
}

struct ProductData: Codable, Identifiable {
    let id: String?
    let title: String?
    let brand: String?
    let model: String?
    let image: String?
    let gallery: [String]?
    let avgPrice: Double?
    let minPrice: Double?
    let maxPrice: Double?
    let link: String?
    let sku: String?
    let slug: String?
    let category: String?
    let productType: String?
    let gender: String?
    let rank: Int?
    let weeklyOrders: Int?
    let upcoming: Bool?
    let description: String?
    
    var displayImageURL: URL? {
        if let g = gallery?.first, let url = URL(string: g) { return url }
        if let i = image, let url = URL(string: i) { return url }
        return nil
    }
}

struct Meta: Codable {
    let total: Int?
    let page: Int?
    let limit: Int?
}

// MARK: - API Service
final class KicksAPI {
    private let apiKey: String
    private let base = "https://api.kicks.dev/v3/stockx/products"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func fetchRandomShoes(query: String = "", brand: String? = nil, limit: Int = 20, page: Int = 1) async throws -> [ProductData] {
        guard var urlComponents = URLComponents(string: base) else {
            throw URLError(.badURL)
        }
        
        // Generate a random page to get different shoes each time (smaller range for reliability)
        let randomPage = Int.random(in: 1...5)
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: String(limit * 2)), // Fetch more to filter out non-shoes
            URLQueryItem(name: "page", value: String(randomPage)), // Random page for variety
            URLQueryItem(name: "display[variants]", value: "true"),
            URLQueryItem(name: "display[prices]", value: "true"),
            URLQueryItem(name: "market", value: "US"),
            URLQueryItem(name: "currency", value: "USD")
        ]
        
        // Add filters only if we have a brand, otherwise let the API return all products
        if let brand = brand {
            queryItems.append(URLQueryItem(name: "filters", value: "brand = '\(brand)'"))
        }
        
        if !query.isEmpty {
            queryItems.append(URLQueryItem(name: "query", value: query))
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }
        
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue(apiKey, forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        
        print("Fetching shoes from page: \(randomPage)")
        print("Brand filter: \(brand ?? "none")")
        print("URL: \(url)")
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            if let msg = String(data: data, encoding: .utf8) {
                print("KicksDB error response: \(msg)")
            }
            if let httpResp = resp as? HTTPURLResponse {
                print("HTTP Status: \(httpResp.statusCode)")
            }
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(ProductListResponse.self, from: data)
        
        // Filter to ensure we only get shoes/sneakers and limit the results
        let shoesOnly = response.data.filter { product in
            // Check multiple fields to identify shoes
            let productType = product.productType?.lowercased() ?? ""
            let category = product.category?.lowercased() ?? ""
            let title = product.title?.lowercased() ?? ""
            
            return productType.contains("sneaker") || 
                   productType.contains("shoe") || 
                   productType.contains("footwear") ||
                   category.contains("sneaker") ||
                   category.contains("shoe") ||
                   title.contains("sneaker") ||
                   title.contains("shoe")
        }
        
        // Shuffle the results for even more randomization
        let shuffledShoes = shoesOnly.shuffled().prefix(limit)
        
        print("Found \(shoesOnly.count) shoes, returning \(shuffledShoes.count)")
        
        // If we don't have enough shoes, return what we have
        if shuffledShoes.isEmpty && !response.data.isEmpty {
            print("No shoes found after filtering, returning first few products")
            return Array(response.data.prefix(limit))
        }
        
        return Array(shuffledShoes)
    }
}

struct ContentViewAgent: View {
    @StateObject private var viewModel = ShoeViewModel()
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
                if viewModel.isLoading {
                    VStack {
                        ProgressView("Loading shoes...")
                            .font(.title2)
                        Text("Fetching the latest sneakers...")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                } else if let error = viewModel.error {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        Text("Error Loading Shoes")
                            .font(.title2)
                            .bold()
                        Text(error.localizedDescription)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        Button("Retry") {
                            Task { await viewModel.loadShoes() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if viewModel.shoes.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No Shoes Found")
                            .font(.title2)
                            .bold()
                        Text("Try refreshing to get new shoes")
                            .foregroundColor(.secondary)
                        Button("Refresh") {
                            Task { await viewModel.loadShoes() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    // Next card behind top card (peek effect, no animation)
                    if topCardIndex + 1 < viewModel.shoes.count {
                        cardViewAgent(
                            shoe: viewModel.shoes[topCardIndex + 1],
                            cardSize: geo.size
                        )
                        .scaleEffect(0.95, anchor: .center)
                        .offset(y: 10)
                        .zIndex(1)
                        .transaction { $0.disablesAnimations = true } // prevents wiggle
                    }
                    
                    // Top card
                    if topCardIndex < viewModel.shoes.count {
                        cardView(
                            shoe: viewModel.shoes[topCardIndex],
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
                                            // Show bottom popup
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                                showCartEffect = true
                                            }
                                            
                                            // Hide after 1 second with fade-out
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                withAnimation(.easeOut(duration: 0.5)) {
                                                    showCartEffect = false
                                                }
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
                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            Text("You've seen all the shoes!")
                                .font(.title2)
                                .bold()
                            Text("Refresh to get new ones")
                                .foregroundColor(.secondary)
                            VStack(spacing: 12) {
                                Button("Get More Shoes") {
                                    topCardIndex = 0
                                    Task { await viewModel.loadShoes() }
                                }
                                .buttonStyle(.borderedProminent)
                                
                                Button("Shuffle Current Shoes") {
                                    viewModel.shuffleShoes()
                                    topCardIndex = 0
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding()
                    }
                    
                    // Bottom popup for "Added to Cart"
                    if showCartEffect {
                        VStack {
                            Spacer()
                            HStack {
                                Text("Added to Cart")
                                    .foregroundColor(.white)
                                    .bold()
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(20)
                            .padding(.horizontal, 20)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        .zIndex(3)
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background(Color(.systemBackground))
        }
        .task {
            await viewModel.loadShoes()
        }
    }
    
    func addToCart() {
        print("Added to cart: \(viewModel.shoes[topCardIndex].title ?? "Unknown")")
    }
    
    func showLater() {
        print("Marked to view later: \(viewModel.shoes[topCardIndex].title ?? "Unknown")")
    }
}

// MARK: - View Model
@MainActor
class ShoeViewModel: ObservableObject {
    @Published var shoes: [ProductData] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let api = KicksAPI(apiKey: "sd_8RKtjTyMiMh9qIJ60G5j1UkdHTS0tfUA")
    
    func loadShoes() async {
        isLoading = true
        error = nil
        do {
            let fetchedShoes = try await api.fetchRandomShoes(limit: 20)
            shoes = fetchedShoes
        } catch {
            self.error = error
            print("fetch error:", error)
        }
        isLoading = false
    }
    
    func shuffleShoes() {
        shoes = shoes.shuffled()
    }
}

// MARK: - Card Views
struct cardView: View {
    let shoe: ProductData
    let cardSize: CGSize
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
            
            VStack {
                // Shoe Image
                if let imgURL = shoe.displayImageURL {
                    AsyncImage(url: imgURL) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: cardSize.width * 0.7, height: cardSize.height * 0.4)
                                .overlay(ProgressView())
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: cardSize.width * 0.7, height: cardSize.height * 0.4)
                                .cornerRadius(20)
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: cardSize.width * 0.7, height: cardSize.height * 0.4)
                                .overlay(Text("Image failed").foregroundColor(.red))
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: cardSize.width * 0.7, height: cardSize.height * 0.4)
                        .overlay(Text("No image").foregroundColor(.gray))
                }
               // .padding(.top, 40)
                
                VStack(spacing: 5) {
                    HStack {
                        Text("$\(Int(shoe.avgPrice ?? 0))")
                            .font(.system(size: cardSize.width * 0.12, weight: .semibold))
                            .foregroundColor(.black)
                        
                        // Trend indicator based on weekly orders
                        let isTrendingUp = (shoe.weeklyOrders ?? 0) > 100
                        Image(systemName: isTrendingUp ? "chart.line.uptrend.xyaxis.circle" : "chart.line.downtrend.xyaxis.circle")
                            .foregroundColor(isTrendingUp ? .red : .green)
                            .font(.system(size: cardSize.width * 0.08, weight: .light))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 25)
                    
                    Text(shoe.title ?? "Unknown Shoe")
                        .font(.system(size: cardSize.width * 0.09, weight: .semibold))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 25)
                    
                    Text(shoe.description ?? "No description available")
                        .font(.system(size: cardSize.width * 0.045, weight: .medium, design: .monospaced))
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
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

struct cardViewAgent: View {
    let shoe: ProductData
    let cardSize: CGSize
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
            
            VStack {
                // Shoe Image
                if let imgURL = shoe.displayImageURL {
                    AsyncImage(url: imgURL) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: cardSize.width * 0.7, height: cardSize.height * 0.4)
                                .overlay(ProgressView())
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: cardSize.width * 0.7, height: cardSize.height * 0.4)
                                .cornerRadius(20)
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: cardSize.width * 0.7, height: cardSize.height * 0.4)
                                .overlay(Text("Image failed").foregroundColor(.red))
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else { 
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: cardSize.width * 0.7, height: cardSize.height * 0.4)
                        .overlay(Text("No image").foregroundColor(.gray))
                }
               // .padding(.top, 40)
                
                VStack(spacing: 5) {
                    HStack {
                        Text("$\(Int(shoe.avgPrice ?? 0))")
                            .font(.system(size: cardSize.width * 0.12, weight: .semibold))
                            .foregroundColor(.black)
                        
                        // Trend indicator based on weekly orders
                        let isTrendingUp = (shoe.weeklyOrders ?? 0) > 100
                        Image(systemName: isTrendingUp ? "chart.line.uptrend.xyaxis.circle" : "chart.line.downtrend.xyaxis.circle")
                            .foregroundColor(isTrendingUp ? .red : .green)
                            .font(.system(size: cardSize.width * 0.08, weight: .light))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 25)
                    
                    Text(shoe.title ?? "Unknown Shoe")
                        .font(.system(size: cardSize.width * 0.09, weight: .semibold))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 25)
                    
                    Text(shoe.description ?? "No description available")
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
    ContentViewAgent()
}
