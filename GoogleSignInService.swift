import SwiftUI
import AuthenticationServices

class GoogleSignInService: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = GoogleSignInService()
    
    private let clientID = "1061753109498-js6p8j75lg95m051stn6su5qgn713bo2.apps.googleusercontent.com"
    private let redirectURI = "https://oauth2redirect.com/callback"
    
    struct GoogleUser {
        let email: String
        let name: String
        let avatarURL: String?
    }
    
    func signIn(completion: @escaping (GoogleUser?) -> Void) {
        let scope = "email%20profile%20openid"
        let authURL = "https://accounts.google.com/o/oauth2/v2/auth?client_id=\(clientID)&redirect_uri=\(redirectURI)&response_type=code&scope=\(scope)&access_type=offline&prompt=consent"
        
        guard let url = URL(string: authURL) else {
            completion(nil)
            return
        }
        
        let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "com.emmew.app") { callbackURL, error in
            guard let callbackURL = callbackURL, error == nil,
                  let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                  let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                completion(nil)
                return
            }
            
            self.exchangeCodeForToken(code: code) { token in
                guard let token = token else {
                    completion(nil)
                    return
                }
                self.fetchUserInfo(token: token, completion: completion)
            }
        }
        
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false
        session.start()
    }
    
    private func exchangeCodeForToken(code: String, completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://oauth2.googleapis.com/token")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "code=\(code)&client_id=\(clientID)&redirect_uri=\(redirectURI)&grant_type=authorization_code"
        req.httpBody = body.data(using: .utf8)
        
        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let token = json["access_token"] as? String else {
                completion(nil)
                return
            }
            completion(token)
        }.resume()
    }
    
    private func fetchUserInfo(token: String, completion: @escaping (GoogleUser?) -> Void) {
        let url = URL(string: "https://www.googleapis.com/oauth2/v3/userinfo")!
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                completion(nil)
                return
            }
            
            let email = json["email"] as? String ?? ""
            let name = json["name"] as? String ?? email.components(separatedBy: "@").first ?? ""
            let avatarURL = json["picture"] as? String
            
            let user = GoogleUser(email: email, name: name, avatarURL: avatarURL)
            completion(user)
        }.resume()
    }
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first ?? UIWindow()
    }
}