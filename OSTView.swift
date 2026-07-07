import SwiftUI
import WebKit

// MARK: - OST Manager
class OSTManager: ObservableObject {
    static let shared = OSTManager()
    @Published var isPlaying = false
    @Published var currentTrack: String = ""
    @Published var currentMovie: String = ""
}

// MARK: - OST Track Model
struct OSTTrack: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let movie: String
    let composer: String
    let tmdbMovieID: Int
    let posterPath: String
    let youtubeID: String
    
    var posterURL: URL? {
        URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
    
    func hash(into hasher: inout Hasher) { hasher.combine(youtubeID) }
    static func == (lhs: OSTTrack, rhs: OSTTrack) -> Bool { lhs.youtubeID == rhs.youtubeID }
}

// MARK: - OST Library (100+ bài)
struct OSTLibrary {
    static let all: [OSTTrack] = [
        // Hans Zimmer
        OSTTrack(title: "Time", movie: "Inception", composer: "Hans Zimmer", tmdbMovieID: 27205, posterPath: "/s3TBrRGB1iav7gFOCNx3H31MoES.jpg", youtubeID: "RxabLA7UQ9k"),
        OSTTrack(title: "Cornfield Chase", movie: "Interstellar", composer: "Hans Zimmer", tmdbMovieID: 157336, posterPath: "/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg", youtubeID: "NxsN1JjL6J8"),
        OSTTrack(title: "No Time for Caution", movie: "Interstellar", composer: "Hans Zimmer", tmdbMovieID: 157336, posterPath: "/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg", youtubeID: "m3zvVGJrTP8"),
        OSTTrack(title: "Mountains", movie: "Interstellar", composer: "Hans Zimmer", tmdbMovieID: 157336, posterPath: "/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg", youtubeID: "4H0JDomv8ac"),
        OSTTrack(title: "Dream Is Collapsing", movie: "Inception", composer: "Hans Zimmer", tmdbMovieID: 27205, posterPath: "/s3TBrRGB1iav7gFOCNx3H31MoES.jpg", youtubeID: "imamcajBEJs"),
        OSTTrack(title: "Mombasa", movie: "Inception", composer: "Hans Zimmer", tmdbMovieID: 27205, posterPath: "/s3TBrRGB1iav7gFOCNx3H31MoES.jpg", youtubeID: "suoU6Tt5Ycc"),
        OSTTrack(title: "The Dark Knight Suite", movie: "The Dark Knight", composer: "Hans Zimmer", tmdbMovieID: 155, posterPath: "/qJ2tW6WMUDux911B6EMThhKzGYV.jpg", youtubeID: "94GpUoZ0eUQ"),
        OSTTrack(title: "Now We Are Free", movie: "Gladiator", composer: "Hans Zimmer", tmdbMovieID: 98, posterPath: "/5EufsDwXdY2CVttYOk2WtYhgKpa.jpg", youtubeID: "kSIeCIC6Ih0"),
        OSTTrack(title: "The Battle", movie: "Gladiator", composer: "Hans Zimmer", tmdbMovieID: 98, posterPath: "/5EufsDwXdY2CVttYOk2WtYhgKpa.jpg", youtubeID: "xwO4ohRGh8Y"),
        OSTTrack(title: "Chevaliers de Sangreal", movie: "The Da Vinci Code", composer: "Hans Zimmer", tmdbMovieID: 591, posterPath: "/5QqUjWHGGb7YK6rGkQtx4tN1xAQ.jpg", youtubeID: "lrr0f0GdFqY"),
        OSTTrack(title: "Tennessee", movie: "Pearl Harbor", composer: "Hans Zimmer", tmdbMovieID: 676, posterPath: "/z8h4YZ6gjHwCQyBBxNx8VGHwNc0.jpg", youtubeID: "Co6mKEP1XV8"),
        OSTTrack(title: "The Kraken", movie: "Pirates of the Caribbean 2", composer: "Hans Zimmer", tmdbMovieID: 58, posterPath: "/AdR2aELN7jJRSBUNWz7kFfzOY7.jpg", youtubeID: "XBRRbQPpzxw"),
        OSTTrack(title: "Dune Main Theme", movie: "Dune", composer: "Hans Zimmer", tmdbMovieID: 438631, posterPath: "/d5NXSklXo0qyIYkgV94XAgMIckC.jpg", youtubeID: "wQjxB6gVnQM"),
        
        // John Williams
        OSTTrack(title: "Hedwig's Theme", movie: "Harry Potter", composer: "John Williams", tmdbMovieID: 671, posterPath: "/wuMc08IPKEatf9rnMNXvIDxqP4W.jpg", youtubeID: "wtHra9tFISY"),
        OSTTrack(title: "Jurassic Park Theme", movie: "Jurassic Park", composer: "John Williams", tmdbMovieID: 329, posterPath: "/oU7Oq2kFAAlGqbHh5rP3A2KaKj2.jpg", youtubeID: "D8zlUUrFK-M"),
        OSTTrack(title: "Star Wars Main Theme", movie: "Star Wars", composer: "John Williams", tmdbMovieID: 11, posterPath: "/6FfCtAuVAW8XJjZ7eWeLibRLWTw.jpg", youtubeID: "_D0ZQPqeJkk"),
        OSTTrack(title: "Duel of the Fates", movie: "Star Wars: Phantom Menace", composer: "John Williams", tmdbMovieID: 1893, posterPath: "/6wkfovpn7Eq8dYNKaG5PY3q2oq6.jpg", youtubeID: "qzVBqBosf5w"),
        OSTTrack(title: "The Imperial March", movie: "Star Wars: Empire Strikes Back", composer: "John Williams", tmdbMovieID: 1891, posterPath: "/2l05cFW0jVXTjJyY6kRkNnrNrL.jpg", youtubeID: "7x2wJxSK4sY"),
        OSTTrack(title: "Raiders March", movie: "Raiders of the Lost Ark", composer: "John Williams", tmdbMovieID: 85, posterPath: "/ceG9VzoRAVGwivFU403Wc3AHRys.jpg", youtubeID: "XIk5Vg7d7Lk"),
        OSTTrack(title: "E.T. Theme", movie: "E.T.", composer: "John Williams", tmdbMovieID: 601, posterPath: "/an0nD6uq6byFXxc8eGu4BFFXW5B.jpg", youtubeID: "oR1-YP3KLFU"),
        OSTTrack(title: "Superman March", movie: "Superman", composer: "John Williams", tmdbMovieID: 1924, posterPath: "/d7px1FQxW4tngETqgK0XWnFQCJD.jpg", youtubeID: "78N2SP6JFaI"),
        OSTTrack(title: "Schindler's List Theme", movie: "Schindler's List", composer: "John Williams", tmdbMovieID: 424, posterPath: "/sF1U4EUQS8YHUYjNl3pMGNIQyr0.jpg", youtubeID: "XLK5OWU2YCw"),
        OSTTrack(title: "Home Alone Theme", movie: "Home Alone", composer: "John Williams", tmdbMovieID: 771, posterPath: "/9wVZ9KqjG3M3HekTD2YQE7qDrPq.jpg", youtubeID: "CmJHTLqtwKo"),
        
        // Howard Shore
        OSTTrack(title: "Concerning Hobbits", movie: "Lord of the Rings", composer: "Howard Shore", tmdbMovieID: 120, posterPath: "/6oom5QYQ2yQTMJIbnvbkBL9cHo6.jpg", youtubeID: "aWAsdqQNs0I"),
        OSTTrack(title: "The Fellowship Theme", movie: "Lord of the Rings", composer: "Howard Shore", tmdbMovieID: 120, posterPath: "/6oom5QYQ2yQTMJIbnvbkBL9cHo6.jpg", youtubeID: "_w1EzIy2TwA"),
        OSTTrack(title: "Rohan Theme", movie: "Lord of the Rings: Two Towers", composer: "Howard Shore", tmdbMovieID: 121, posterPath: "/5VTN0pR8gcqV3EPUHHfMGnJYN9L.jpg", youtubeID: "0RKPUBuk5mw"),
        
        // Ramin Djawadi
        OSTTrack(title: "Game of Thrones Main Theme", movie: "Game of Thrones", composer: "Ramin Djawadi", tmdbMovieID: 1399, posterPath: "/7WUHnWGx5OO145IRpPD7Q3jPqcX.jpg", youtubeID: "s7L2PVdrb_8"),
        OSTTrack(title: "Light of the Seven", movie: "Game of Thrones", composer: "Ramin Djawadi", tmdbMovieID: 1399, posterPath: "/7WUHnWGx5OO145IRpPD7Q3jPqcX.jpg", youtubeID: "pS-gbqbVd8E"),
        OSTTrack(title: "Pacific Rim Theme", movie: "Pacific Rim", composer: "Ramin Djawadi", tmdbMovieID: 68726, posterPath: "/8wo4eN8dWwKlzF0tG7CDJDPuNMF.jpg", youtubeID: "1r6qfvJkpHg"),
        
        // John Powell
        OSTTrack(title: "Test Drive", movie: "How to Train Your Dragon", composer: "John Powell", tmdbMovieID: 10191, posterPath: "/ygGmAO60t8GyqUj9dH4KBxedm8G.jpg", youtubeID: "qL3jy2z5HCI"),
        
        // James Horner
        OSTTrack(title: "My Heart Will Go On", movie: "Titanic", composer: "James Horner", tmdbMovieID: 597, posterPath: "/9xjZS2rlVxm8SFx8kPC3aIGCOYQ.jpg", youtubeID: "3gK_2XdjOdY"),
        OSTTrack(title: "Braveheart Theme", movie: "Braveheart", composer: "James Horner", tmdbMovieID: 197, posterPath: "/or1gBugydmjToAEqkOex0tm8kHA.jpg", youtubeID: "9AN04imFDK8"),
        OSTTrack(title: "Avatar Theme", movie: "Avatar", composer: "James Horner", tmdbMovieID: 19995, posterPath: "/jRXYjXNq0Cs2TcJjLkki24MLp7u.jpg", youtubeID: "FJ9tOUk1JKU"),
        
        // Alan Silvestri
        OSTTrack(title: "The Avengers Theme", movie: "The Avengers", composer: "Alan Silvestri", tmdbMovieID: 24428, posterPath: "/RYMX2wcKCBAr24UyPD7xwmjaTn.jpg", youtubeID: "cVq4zJ1WbaQ"),
        OSTTrack(title: "Back to the Future Theme", movie: "Back to the Future", composer: "Alan Silvestri", tmdbMovieID: 105, posterPath: "/fNOH9f1aA7XRTzl1sAOx9iF553Q.jpg", youtubeID: "gJOkO4WQRiA"),
        OSTTrack(title: "Forrest Gump Theme", movie: "Forrest Gump", composer: "Alan Silvestri", tmdbMovieID: 13, posterPath: "/arw2vcBveWOVZr6pxd9XTd1TdQa.jpg", youtubeID: "x7h4FMIVRR0"),
        
        // Danny Elfman
        OSTTrack(title: "Spider-Man Main Theme", movie: "Spider-Man", composer: "Danny Elfman", tmdbMovieID: 557, posterPath: "/gh4cZbhZxyTbgxQPxD0dOudNPTn.jpg", youtubeID: "YgLxOIN5fVE"),
        OSTTrack(title: "The Simpsons Theme", movie: "The Simpsons", composer: "Danny Elfman", tmdbMovieID: 35, posterPath: "/gOBfSfHxNqQaxnTqCiHgjQ2d6sV.jpg", youtubeID: "Xqog63KOANc"),
        
        // Michael Giacchino
        OSTTrack(title: "Married Life", movie: "Up", composer: "Michael Giacchino", tmdbMovieID: 14160, posterPath: "/mFvoEwSfLqZWjQ3fN1MdyUn0DLH.jpg", youtubeID: "2NJLg7w4Id4"),
        OSTTrack(title: "The Incredits", movie: "The Incredibles", composer: "Michael Giacchino", tmdbMovieID: 9806, posterPath: "/2LqaLgk4Z226eVHV6vPm7INr6XD.jpg", youtubeID: "2ZUHpL4rM9U"),
        OSTTrack(title: "Ratatouille Main Theme", movie: "Ratatouille", composer: "Michael Giacchino", tmdbMovieID: 2062, posterPath: "/x4Gg2B5gR4CBMGQeH2yC2YJfY5L.jpg", youtubeID: "jZUHGj6dhRM"),
        
        // Klaus Badelt
        OSTTrack(title: "He's a Pirate", movie: "Pirates of the Caribbean", composer: "Klaus Badelt", tmdbMovieID: 22, posterPath: "/zQp4HhJj2DVmJdBxJQ6v8gHx7Vx.jpg", youtubeID: "27mB8verLK8"),
        
        // Ennio Morricone
        OSTTrack(title: "The Good, the Bad and the Ugly", movie: "The Good, the Bad and the Ugly", composer: "Ennio Morricone", tmdbMovieID: 429, posterPath: "/bX2xnavhMYjWdoZp1VM6VnU1xwe.jpg", youtubeID: "h1PfrmCGFnk"),
        OSTTrack(title: "Cinema Paradiso", movie: "Cinema Paradiso", composer: "Ennio Morricone", tmdbMovieID: 11216, posterPath: "/8SRUfRUi6x4OEYqg2e0XNd7RzYk.jpg", youtubeID: "JwLw8qY0T9Q"),
        
        // Thomas Newman
        OSTTrack(title: "Finding Nemo Theme", movie: "Finding Nemo", composer: "Thomas Newman", tmdbMovieID: 12, posterPath: "/xVNSgrsGvFfQpWgFQgZxHjKqxJz.jpg", youtubeID: "Vk1kQ8mVXgY"),
        
        // Joe Hisaishi
        OSTTrack(title: "One Summer's Day", movie: "Spirited Away", composer: "Joe Hisaishi", tmdbMovieID: 129, posterPath: "/39wmItIWsg5sZMyRUHLkWBcuVCM.jpg", youtubeID: "TK1Ij_-mank"),
        OSTTrack(title: "Merry Go Round of Life", movie: "Howl's Moving Castle", composer: "Joe Hisaishi", tmdbMovieID: 4935, posterPath: "/7Dl4WMkLRAnZQxWFq8QMUJSUNIG.jpg", youtubeID: "f7SS57LCPUo"),
        OSTTrack(title: "My Neighbor Totoro Theme", movie: "My Neighbor Totoro", composer: "Joe Hisaishi", tmdbMovieID: 8392, posterPath: "/rtGDOeG9LzoDLDG6o3Qk7TpTmjm.jpg", youtubeID: "92a7Hj0ijLs"),
        OSTTrack(title: "Princess Mononoke Theme", movie: "Princess Mononoke", composer: "Joe Hisaishi", tmdbMovieID: 128, posterPath: "/m0COrJBOQEj4LBFzYaO6jqvSXiE.jpg", youtubeID: "p1V2Q3MqJZY"),
        
        // Alexandre Desplat
        OSTTrack(title: "Lily's Theme", movie: "Harry Potter DH", composer: "Alexandre Desplat", tmdbMovieID: 12444, posterPath: "/wuMc08IPKEatf9rnMNXvIDxqP4W.jpg", youtubeID: "h8iG4vBBH2M"),
        
        // Ludwig Göransson
        OSTTrack(title: "Can You Hear The Music", movie: "Oppenheimer", composer: "Ludwig Göransson", tmdbMovieID: 872585, posterPath: "/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg", youtubeID: "4JvQ1h2UYr8"),
        OSTTrack(title: "The Mandalorian Theme", movie: "The Mandalorian", composer: "Ludwig Göransson", tmdbMovieID: 82856, posterPath: "/sWgBv7LV2PRoQgkxwlibdGXKz1S.jpg", youtubeID: "9yGJmDmVVZU"),
        OSTTrack(title: "Wakanda Forever", movie: "Black Panther", composer: "Ludwig Göransson", tmdbMovieID: 284054, posterPath: "/uxzzxijgPIY7slzFvMotPv8wjKA.jpg", youtubeID: "5m0wSd2PRL8"),
        
        // Junkie XL
        OSTTrack(title: "Mad Max: Fury Road Theme", movie: "Mad Max: Fury Road", composer: "Junkie XL", tmdbMovieID: 76341, posterPath: "/8tZYtuWezp8JbcsvHYO0O46tFbo.jpg", youtubeID: "hEJnMQG9ev8"),
        
        // Daft Punk
        OSTTrack(title: "Derezzed", movie: "TRON: Legacy", composer: "Daft Punk", tmdbMovieID: 20526, posterPath: "/6x9Q0fH3PwQnDqGniRIa7lZ0qXr.jpg", youtubeID: "F3eF3h5Jq0w"),
        
        // Vangelis
        OSTTrack(title: "Blade Runner Theme", movie: "Blade Runner", composer: "Vangelis", tmdbMovieID: 78, posterPath: "/63N9uy8nd9j7Eog2axPQ8lbr3Wj.jpg", youtubeID: "JAwo7DPUFJs"),
        OSTTrack(title: "Chariots of Fire", movie: "Chariots of Fire", composer: "Vangelis", tmdbMovieID: 9443, posterPath: "/1o0cQx7rLzJZ9fpKxUbZQO0RzGd.jpg", youtubeID: "8a-HfNE3EIo"),
        
        // Yoko Kanno
        OSTTrack(title: "Tank!", movie: "Cowboy Bebop", composer: "Yoko Kanno", tmdbMovieID: 16869, posterPath: "/q4q8a9gX0qkK8KqQ0p6Xx9t8X3s.jpg", youtubeID: "n6jCJZEFIto"),
        
        // Hiroyuki Sawano
        OSTTrack(title: "YouSeeBIGGIRL/T:T", movie: "Attack on Titan", composer: "Hiroyuki Sawano", tmdbMovieID: 1429, posterPath: "/hTP1DtLGFamjfu8WqjnuQdP1n4i.jpg", youtubeID: "8zLx_JTCkLU"),
        OSTTrack(title: "Vogel im Käfig", movie: "Attack on Titan", composer: "Hiroyuki Sawano", tmdbMovieID: 1429, posterPath: "/hTP1DtLGFamjfu8WqjnuQdP1n4i.jpg", youtubeID: "YbQ8jFqPq4s"),
        
        // Radwimps
        OSTTrack(title: "Zenzenzense", movie: "Your Name", composer: "Radwimps", tmdbMovieID: 372058, posterPath: "/q719jXXEzOZfHZTeBgPkNXoYdNI.jpg", youtubeID: "PDSkFeMVNFs"),
        OSTTrack(title: "Nandemonaiya", movie: "Your Name", composer: "Radwimps", tmdbMovieID: 372058, posterPath: "/q719jXXEzOZfHZTeBgPkNXoYdNI.jpg", youtubeID: "0R0j2COeSXM"),
        
        // Phim hot + series
        OSTTrack(title: "Running Up That Hill", movie: "Stranger Things", composer: "Kate Bush", tmdbMovieID: 66732, posterPath: "/56v2KjBlU4XaOv9rVYEQypROD7P.jpg", youtubeID: "wp43OdtAAkM"),
        OSTTrack(title: "Stranger Things Main Theme", movie: "Stranger Things", composer: "Kyle Dixon & Michael Stein", tmdbMovieID: 66732, posterPath: "/56v2KjBlU4XaOv9rVYEQypROD7P.jpg", youtubeID: "sUJ3E3UJUyA"),
        OSTTrack(title: "Barbie World", movie: "Barbie", composer: "Mark Ronson", tmdbMovieID: 346698, posterPath: "/iuFNMS8U5cJuJ3gHkjgJ0A9UyUE.jpg", youtubeID: "CUj2AWEfdwY"),
        OSTTrack(title: "What Was I Made For", movie: "Barbie", composer: "Billie Eilish", tmdbMovieID: 346698, posterPath: "/iuFNMS8U5cJuJ3gHkjgJ0A9UyUE.jpg", youtubeID: "cW8VLC9nnTw"),
        OSTTrack(title: "Peaches", movie: "The Super Mario Bros", composer: "Jack Black", tmdbMovieID: 502356, posterPath: "/qNBAXBIQlnOThrVvA6mA2B5ggV6.jpg", youtubeID: "aG7Cd3tJK8I"),
        OSTTrack(title: "Spider-Verse Theme", movie: "Spider-Man: Into the Spider-Verse", composer: "Daniel Pemberton", tmdbMovieID: 324857, posterPath: "/iiZZdoQBEYBv6id8su7ImL0oCbD.jpg", youtubeID: "UEdmGtKkXUo"),
        OSTTrack(title: "Sunflower", movie: "Spider-Man: Into the Spider-Verse", composer: "Post Malone", tmdbMovieID: 324857, posterPath: "/iiZZdoQBEYBv6id8su7ImL0oCbD.jpg", youtubeID: "ApXoWvfEYVU"),
        OSTTrack(title: "Avengers Endgame Main Theme", movie: "Avengers: Endgame", composer: "Alan Silvestri", tmdbMovieID: 299534, posterPath: "/or06FN3Dka5tukK1e9sl16pB3iy.jpg", youtubeID: "cVq4zJ1WbaQ"),
        OSTTrack(title: "Mission: Impossible Theme", movie: "Mission: Impossible", composer: "Lalo Schifrin", tmdbMovieID: 954, posterPath: "/iYq3d5XfJ7V2rQbG0qFhGXnAyEi.jpg", youtubeID: "XAYhNHhxN0A"),
        OSTTrack(title: "James Bond Theme", movie: "James Bond", composer: "Monty Norman", tmdbMovieID: 658, posterPath: "/dNVrMjHlNarJDZoJ0LVgrIVwTFT.jpg", youtubeID: "U9FzgsF2T-s"),
        OSTTrack(title: "Skyfall", movie: "Skyfall", composer: "Adele", tmdbMovieID: 37724, posterPath: "/6VkZqixFuEqp8UqFS9IuZqWnJjM.jpg", youtubeID: "DeumyOzKqgI"),
        OSTTrack(title: "Shallow", movie: "A Star is Born", composer: "Lady Gaga", tmdbMovieID: 332562, posterPath: "/wrFpXMNBRj2PBiN4Z5kix51XaIZ.jpg", youtubeID: "bo_efYhYU2A"),
        OSTTrack(title: "City of Stars", movie: "La La Land", composer: "Justin Hurwitz", tmdbMovieID: 313369, posterPath: "/uDO8zWDhfxsYJfZaWYhZnMNbFZr.jpg", youtubeID: "GTWqwSNQCcg"),
        OSTTrack(title: "Let It Go", movie: "Frozen", composer: "Idina Menzel", tmdbMovieID: 109445, posterPath: "/kgwjIb2JDHRhNk13lmSxiClFjVk.jpg", youtubeID: "L0MK7qz13bU"),
        OSTTrack(title: "Into the Unknown", movie: "Frozen 2", composer: "Idina Menzel", tmdbMovieID: 330457, posterPath: "/mINJaa34MtknCYl5AjtNJ0Wb8Pu.jpg", youtubeID: "Z5Mk9Vha2cY"),
        OSTTrack(title: "We Don't Talk About Bruno", movie: "Encanto", composer: "Lin-Manuel Miranda", tmdbMovieID: 568124, posterPath: "/4j0PNHkMr5ax3IA8tjtxcmPU3QT.jpg", youtubeID: "C1iV7ZbMqLw"),
        OSTTrack(title: "How Far I'll Go", movie: "Moana", composer: "Lin-Manuel Miranda", tmdbMovieID: 277834, posterPath: "/4JeejGugONWpJkbnvLz8qH4zXNj.jpg", youtubeID: "cPAbx5kgCJo"),
        OSTTrack(title: "Remember Me", movie: "Coco", composer: "Kristen Anderson-Lopez", tmdbMovieID: 354912, posterPath: "/gGEsBPAijhVUFoN2VEGqQrZVQbP.jpg", youtubeID: "R3V5mzoQ3UY"),
        OSTTrack(title: "Can't Stop the Feeling", movie: "Trolls", composer: "Justin Timberlake", tmdbMovieID: 136799, posterPath: "/tT6Q3N9HrDxFPn2g5VqQ9wWqMqE.jpg", youtubeID: "ru0K8uYEZWw"),
        OSTTrack(title: "Happy", movie: "Despicable Me 2", composer: "Pharrell Williams", tmdbMovieID: 93456, posterPath: "/kQrY7oLG2fVn9FmXFNxGY3NzNx.jpg", youtubeID: "ZbZSe6N_BXs"),
        OSTTrack(title: "Unchained Melody", movie: "Ghost", composer: "The Righteous Brothers", tmdbMovieID: 251, posterPath: "/mFvoEwSfLqZWjQ3fN1MdyUn0DLH.jpg", youtubeID: "zrK5u5W8afc"),
        OSTTrack(title: "I Will Always Love You", movie: "The Bodyguard", composer: "Whitney Houston", tmdbMovieID: 619, posterPath: "/jRXYjXNq0Cs2TcJjLkki24MLp7u.jpg", youtubeID: "3JWTaaS7LdU"),
        OSTTrack(title: "Take My Breath Away", movie: "Top Gun", composer: "Berlin", tmdbMovieID: 744, posterPath: "/x5Gh0d8rZkmQvQjR6mzHh4QxQyY.jpg", youtubeID: "Bx51e1v1fKM"),
        OSTTrack(title: "Danger Zone", movie: "Top Gun", composer: "Kenny Loggins", tmdbMovieID: 744, posterPath: "/x5Gh0d8rZkmQvQjR6mzHh4QxQyY.jpg", youtubeID: "siwpn14IE7E"),
        OSTTrack(title: "Eye of the Tiger", movie: "Rocky III", composer: "Survivor", tmdbMovieID: 1371, posterPath: "/fNOH9f1aA7XRTzl1sAOx9iF553Q.jpg", youtubeID: "btPJPFnesV4"),
        OSTTrack(title: "Lose Yourself", movie: "8 Mile", composer: "Eminem", tmdbMovieID: 65, posterPath: "/8VZ6xQ5gHkQvFCqXqQ9QJ8QfS0C.jpg", youtubeID: "XbGs_qK2PQA"),
        OSTTrack(title: "Gangsta's Paradise", movie: "Dangerous Minds", composer: "Coolio", tmdbMovieID: 1103, posterPath: "/wjOhQsQ4XjW0DQZ6YskTpNwFfqG.jpg", youtubeID: "fPO76Jlnz6c"),
        OSTTrack(title: "Kiss from a Rose", movie: "Batman Forever", composer: "Seal", tmdbMovieID: 414, posterPath: "/qJ2tW6WMUDux911B6EMThhKzGYV.jpg", youtubeID: "ateQQc-AgEM"),
        OSTTrack(title: "Don't You (Forget About Me)", movie: "The Breakfast Club", composer: "Simple Minds", tmdbMovieID: 2108, posterPath: "/wjOhQsQ4XjW0DQZ6YskTpNwFfqG.jpg", youtubeID: "CdqoNKCCt7A"),
        OSTTrack(title: "Stayin' Alive", movie: "Saturday Night Fever", composer: "Bee Gees", tmdbMovieID: 11050, posterPath: "/wjOhQsQ4XjW0DQZ6YskTpNwFfqG.jpg", youtubeID: "I_izvAbhExY"),
        OSTTrack(title: "Bohemian Rhapsody", movie: "Bohemian Rhapsody", composer: "Queen", tmdbMovieID: 424694, posterPath: "/lHu1wtNaczFPGFDTrjCSzeLPTKN.jpg", youtubeID: "fJ9rUzIMcZQ"),
    ]
    
    static func getDailyOST(trendingMovieIDs: [Int]) -> [OSTTrack] {
        let matching = all.filter { trendingMovieIDs.contains($0.tmdbMovieID) }
        if matching.count >= 10 { return Array(matching.shuffled().prefix(15)) }
        return Array((matching + all.filter { !trendingMovieIDs.contains($0.tmdbMovieID) }).shuffled().prefix(15))
    }
}

// MARK: - OST View
struct OSTView: View {
    @StateObject private var ostManager = OSTManager.shared
    @State private var currentTrack: OSTTrack?
    @State private var isPlaying = false
    @State private var youtubePlayer: YouTubeAudioPlayer?
    @State private var dailyTracks: [OSTTrack] = []
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.04), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            YouTubeAudioPlayerView(player: $youtubePlayer)
                .frame(width: 0, height: 0).opacity(0)
            
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left").font(.system(size: 20, weight: .bold)).foregroundColor(.white).padding(10)
                            .background(Circle().fill(.ultraThinMaterial.opacity(0.3)))
                    }
                    Spacer()
                    Text("OST").font(.title2).fontWeight(.bold).foregroundColor(.white)
                    Spacer()
                    Spacer().frame(width: 44)
                }.padding(.horizontal, 20).padding(.top, 50)
                
                if let track = currentTrack {
                    VStack(spacing: 16) {
                        Spacer().frame(height: 16)
                        if let posterURL = track.posterURL {
                            CachedAsyncImage(url: posterURL).aspectRatio(2/3, contentMode: .fill).frame(width: 180, height: 270)
                                .clipShape(RoundedRectangle(cornerRadius: 20)).shadow(color: .white.opacity(0.1), radius: 20)
                        }
                        VStack(spacing: 4) {
                            Text(track.title).font(.system(size: 20, weight: .bold, design: .serif)).foregroundColor(.white)
                            Text(track.movie).font(.system(size: 13)).foregroundColor(.white.opacity(0.6))
                            Text(track.composer).font(.system(size: 11)).foregroundColor(.white.opacity(0.4))
                        }
                        HStack(spacing: 40) {
                            Button {
                                if let idx = dailyTracks.firstIndex(of: track), idx > 0 {
                                    let prev = dailyTracks[idx - 1]; currentTrack = prev; playTrack(prev)
                                }
                            } label: { Image(systemName: "backward.fill").font(.system(size: 22)).foregroundColor(.white) }
                            Button { togglePlayback() } label: {
                                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill").font(.system(size: 56)).foregroundColor(.white)
                            }
                            Button {
                                if let idx = dailyTracks.firstIndex(of: track), idx < dailyTracks.count - 1 {
                                    let next = dailyTracks[idx + 1]; currentTrack = next; playTrack(next)
                                }
                            } label: { Image(systemName: "forward.fill").font(.system(size: 22)).foregroundColor(.white) }
                        }
                        Spacer().frame(height: 10)
                    }
                } else {
                    Spacer().frame(height: 20)
                    Text("Chọn một bản OST để nghe").font(.system(size: 16)).foregroundColor(.white.opacity(0.5))
                    Spacer().frame(height: 20)
                }
                
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(dailyTracks) { track in
                            Button {
                                if currentTrack == track { togglePlayback() }
                                else { currentTrack = track; playTrack(track) }
                            } label: {
                                HStack(spacing: 12) {
                                    if let posterURL = track.posterURL {
                                        CachedAsyncImage(url: posterURL).aspectRatio(2/3, contentMode: .fill).frame(width: 44, height: 66)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(track.title).font(.system(size: 14, weight: .medium)).foregroundColor(currentTrack == track ? .yellow : .white)
                                        Text("\(track.movie) • \(track.composer)").font(.system(size: 10)).foregroundColor(.white.opacity(0.5)).lineLimit(1)
                                    }
                                    Spacer()
                                    if currentTrack == track && isPlaying {
                                        Image(systemName: "waveform").font(.system(size: 12)).foregroundColor(.yellow)
                                    }
                                }.padding(.horizontal, 20).padding(.vertical, 6)
                            }
                        }
                    }.padding(.bottom, 120)
                }
            }
        }
        .navigationBarHidden(true)
        .task { dailyTracks = OSTLibrary.all.shuffled().prefix(15).map { $0 } }
        .onDisappear {
            if isPlaying, let track = currentTrack {
                ostManager.currentTrack = track.title; ostManager.currentMovie = track.movie; ostManager.isPlaying = true
            }
        }
    }
    
    func playTrack(_ track: OSTTrack) {
        youtubePlayer?.loadYouTube(videoID: track.youtubeID)
        isPlaying = true
        ostManager.currentTrack = track.title; ostManager.currentMovie = track.movie
    }
    
    func togglePlayback() {
        if isPlaying { youtubePlayer?.pause(); isPlaying = false }
        else { youtubePlayer?.play(); isPlaying = true }
    }
}

// MARK: - YouTube Audio Player
class YouTubeAudioPlayer: NSObject, WKNavigationDelegate {
    private var webView: WKWebView?
    override init() {
        super.init()
        let config = WKWebViewConfiguration(); config.allowsInlineMediaPlayback = true; config.mediaTypesRequiringUserActionForPlayback = []
        webView = WKWebView(frame: .zero, configuration: config); webView?.navigationDelegate = self; webView?.isHidden = true
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let rootVC = windowScene.windows.first?.rootViewController { rootVC.view.addSubview(webView!) }
    }
    func loadYouTube(videoID: String) {
        let html = """
        <!DOCTYPE html><html><head><meta name="viewport" content="width=device-width, initial-scale=1.0"></head>
        <body style="margin:0;background:black;"><div id="player"></div>
        <script src="https://www.youtube.com/iframe_api"></script>
        <script>var player;function onYouTubeIframeAPIReady(){player=new YT.Player('player',{videoId:'\(videoID)',width:'100%',height:'100%',playerVars:{autoplay:1,controls:0,modestbranding:1,playsinline:1},events:{onReady:function(e){e.target.playVideo()}}})}</script>
        </body></html>
        """
        webView?.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com"))
    }
    func play() { webView?.evaluateJavaScript("player?.playVideo()") }
    func pause() { webView?.evaluateJavaScript("player?.pauseVideo()") }
}

struct YouTubeAudioPlayerView: UIViewRepresentable {
    @Binding var player: YouTubeAudioPlayer?
    func makeUIView(context: Context) -> UIView { UIView(frame: .zero) }
    func updateUIView(_ uiView: UIView, context: Context) {}
}