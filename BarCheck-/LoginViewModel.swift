//
//  SwiftUIView.swift
//  BarCheck-
//
//  Created by Isaac Petrella on 10/18/23.
//

import SwiftUI
import Firebase
import CryptoKit
import AuthenticationServices
import GoogleSignIn
import GoogleSignInSwift

class LoginViewModel: ObservableObject {
    // MARK: View Properties
    @Published var mobileNo: String = ""
    @Published var otpCode: String = ""
    
    @Published var CLIENT_CODE: String = ""
    @Published var showOTPField: Bool = false
    
    // MARK: Error Properties
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    // MARK: App Log Status
    @AppStorage("log_status") var logStatus: Bool = false
    
    // MARK: Apple Sign-in Properties
    @Published var nonce: String = ""
    
    // MARK: Firebase API
    func getOTPCode(){
        UIApplication.shared.closeKeyboard()
        Task{
            do{
                // MARK: Disable it when testing Real Device
                Auth.auth().settings?.isAppVerificationDisabledForTesting = true
                
                let code = try await PhoneAuthProvider.provider().verifyPhoneNumber("+\(mobileNo)", uiDelegate: nil)
                await MainActor.run(body: {
                    CLIENT_CODE = code
                    // MARK: Enabling OTP Code When It's Successful
                    withAnimation(.easeInOut){showOTPField = true}
                    
                })
            }catch{
                await handleError(error: error)
            }
        }
    }
    
    // MARK: Apple Sign-in API
    func appleAuthenticate(credential: ASAuthorizationAppleIDCredential){
        // MARK: Getting Token
        guard let token = credential.identityToken else{
            print("Error with Firebase")
            return
        }
        // MARK: Token String
        guard let tokenString = String(data: token, encoding: .utf8) else{
            print("Error with Token")
            return
        }
        let firebaseCredential = OAuthProvider.credential(withProviderID: "apple.com", idToken: 
            tokenString, rawNonce: nonce)
        Auth.auth().signIn(with: firebaseCredential) { (result, err) in
            
            if let error = err{
                print(error.localizedDescription)
                return
            }
            // MARK: User Successfully Logged into Firebase
            print("Logged in Successfully")
            withAnimation(.easeInOut) {self.logStatus = true}
        }
        
    }
    // MARK: Logging Google User into Firebase
    func logGoogleUser(user: GIDGoogleUser){
        Task{
            do{
                guard let idToken = user.authentication.idToken else{return}
                let accessToken = user.authentication.accessToken
                
                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
                
                try await Auth.auth().signIn(with: credential)
                
                print("Success Google!")
                await MainActor.run(body: {
                    withAnimation(.easeInOut){logStatus = true}
                })
            }
        }
    }
    
    func verifyOTPCode(){
        UIApplication.shared.closeKeyboard()
        Task{
            do{
                let credential = PhoneAuthProvider.provider().credential(withVerificationID: CLIENT_CODE, verificationCode: otpCode)
                
                try await Auth.auth().signIn(with: credential)
                
                // MARK: User Logged in Successfully
                print("Success!")
                await MainActor.run(body: {
                    withAnimation(.easeInOut){logStatus = true}
                })
            } catch{
                await handleError(error: error)
            }
        }
    }
    
    // MARK: Handling Error
    func handleError(error: Error)async{
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
        })
    }
}

// MARK: Extensions
extension UIApplication {
    func closeKeyboard(){
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // Root Controller
    func rootController()->UIViewController{
        guard let window = connectedScenes.first as? UIWindowScene else{return .init()}
        guard let viewcontroller = window.windows.last?.rootViewController else{return .init()}
        
        return viewcontroller
    }
}

@ViewBuilder
    func CustomButton(isGoogle: Bool = false)->some View{
        HStack{
            Group{
                if isGoogle{
                    Image("Google.png")
                        .resizable()
                        //.symbolRenderingMode(.template)
                }else{
                    Image(systemName: "applelogo")
                        .resizable()
                }
            }
            .aspectRatio(contentMode: .fit)
            .frame(width: 25, height: 25)
            .frame(height: 45)
            .opacity(1.0)
            
            Text("\(isGoogle ? "Google" : "Apple") Sign In")
                .font(.headline)
                .lineLimit(1)
        }
        .foregroundColor(.colorWhite)
        .padding(.horizontal, 15)
        .background{
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.accent)
                .opacity(500)
        }
    }

// MARK: Apple Sign-in Helpers
func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
        return String(format: "%02x", $0)
    }.joined()
    return hashString
}
func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: Array<Character> =
    Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length
    
    while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus\(errorCode)")
            }
            return random
        }
        randoms.forEach { random in
            if remainingLength == 0 {
                return
            }
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
        return result
}
#Preview {
    ContentView()
}
