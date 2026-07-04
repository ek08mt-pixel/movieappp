import SwiftUI

struct DirectorSearchView: View {
    @State private var directorName = ""
    @State private var selectedDirector: String?
    
    let famousDirectors = [
        "Christopher Nolan", "Quentin Tarantino", "Martin Scorsese",
        "Steven Spielberg", "Bong Joon-ho", "Hayao Miyazaki",
        "Park Chan-wook", "Wong Kar-wai", "Denis Villeneuve",
        "Greta Gerwig", "Jordan Peele", "Taika Waititi"
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Đạo diễn nổi tiếng")
                        .font(.headline).foregroundColor(.white).padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(famousDirectors, id: \.self) { director in
                            NavigationLink(destination: DirectorView(directorName: director)) {
                                Text(director)
                                    .font(.caption).fontWeight(.medium).foregroundColor(.white)
                                    .frame(maxWidth: .infinity).padding()
                                    .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
                            }
                        }
                    }.padding(.horizontal)
                }
            }
        }
        .navigationTitle("Đạo diễn")
    }
}