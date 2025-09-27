/*
it is currently commented out because contentviewagent has its components, it is mainly used for testing out new features without the risk of loss or crash
import SwiftUI
import Foundation

// MARK: - Models (a subset of what the API returns)
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
    
    func fetchRandomShoes(query: String = "", brand: String? = nil, limit: Int = 20) async throws -> [ProductData] {
        guard var urlComponents = URLComponents(string: base) else {
            throw URLError(.badURL)
        }
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "display[variants]", value: "true"),
            URLQueryItem(name: "display[prices]", value: "true"),
            URLQueryItem(name: "market", value: "US"),
            URLQueryItem(name: "currency", value: "USD")
        ]
        
        if !query.isEmpty {
            queryItems.append(URLQueryItem(name: "query", value: query))
        }
        
        if let brand = brand {
            queryItems.append(URLQueryItem(name: "filters", value: "brand = '\(brand)'"))
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }
        
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue(apiKey, forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            if let msg = String(data: data, encoding: .utf8) {
                print("KicksDB error response: \(msg)")
            }
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(ProductListResponse.self, from: data)
        return response.data
    }
}

// MARK: - SwiftUI View
struct StockXProductView: View {
    @StateObject private var vm = VM()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Brand Filter Buttons
                HStack(spacing: 12) {
                    Button("All") {
                        vm.selectedBrand = nil
                        Task { await vm.loadShoes() }
                    }
                    .buttonStyle(BrandButtonStyle(isSelected: vm.selectedBrand == nil))
                    
                    Button("Nike") {
                        vm.selectedBrand = "Nike"
                        Task { await vm.loadShoes() }
                    }
                    .buttonStyle(BrandButtonStyle(isSelected: vm.selectedBrand == "Nike"))
                    
                    Button("Jordan") {
                        vm.selectedBrand = "Jordan"
                        Task { await vm.loadShoes() }
                    }
                    .buttonStyle(BrandButtonStyle(isSelected: vm.selectedBrand == "Jordan"))
                    
                    Button("Adidas") {
                        vm.selectedBrand = "Adidas"
                        Task { await vm.loadShoes() }
                    }
                    .buttonStyle(BrandButtonStyle(isSelected: vm.selectedBrand == "Adidas"))
                }
                .padding(.horizontal)
                
                if vm.isLoading {
                    ProgressView("Loading shoes...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = vm.error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        Text("Error")
                            .font(.title2)
                            .bold()
                        Text(error.localizedDescription)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        Button("Retry") {
                            Task { await vm.loadShoes() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if vm.shoes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No shoes found")
                            .font(.title2)
                            .bold()
                        Text("Try a different brand filter")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(vm.shoes) { shoe in
                                ShoeCardView(shoe: shoe)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Shoesly - Random Shoes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        Task { await vm.loadShoes() }
                    }
                }
            }
        }
        .task { await vm.loadShoes() }
    }
}

// MARK: - Shoe Card View
struct ShoeCardView: View {
    let shoe: ProductData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image
            if let imgURL = shoe.displayImageURL {
                AsyncImage(url: imgURL) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                            .cornerRadius(12)
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                            .overlay(Text("Image failed").foregroundColor(.red))
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
                    .overlay(Text("No image").foregroundColor(.gray))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                // Brand and Title
                HStack {
                    Text(shoe.brand ?? "Unknown Brand")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Spacer()
                    if let rank = shoe.rank {
                        Text("#\(rank)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Text(shoe.title ?? "Unknown Title")
                    .font(.headline)
                    .lineLimit(2)
                
                // Price Information
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        if let avg = shoe.avgPrice {
                            Text("$\(Int(avg))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        
                        if let min = shoe.minPrice, let max = shoe.maxPrice, min != max {
                            Text("$\(Int(min)) - $\(Int(max))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        if let weeklyOrders = shoe.weeklyOrders {
                            Text("\(weeklyOrders) sold")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        if shoe.upcoming == true {
                            Text("Coming Soon")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
                
                // SKU and Category
                HStack {
                    if let sku = shoe.sku {
                        Text("SKU: \(sku)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if let category = shoe.category {
                        Text(category)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Brand Button Style
struct BrandButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

extension StockXProductView {
    @MainActor class VM: ObservableObject {
        @Published var shoes: [ProductData] = []
        @Published var isLoading = false
        @Published var error: Error?
        @Published var selectedBrand: String? = nil
        
        private let api = KicksAPI(apiKey: "sd_8RKtjTyMiMh9qIJ60G5j1UkdHTS0tfUA")
        
        func loadShoes() async {
            isLoading = true
            error = nil
            do {
                let fetchedShoes = try await api.fetchRandomShoes(brand: selectedBrand, limit: 20)
                shoes = fetchedShoes
            } catch {
                self.error = error
                print("fetch error:", error)
            }
            isLoading = false
        }
    }
}

struct StockXProductView_Previews: PreviewProvider {
    static var previews: some View {
        StockXProductView()
    }
}
*/
