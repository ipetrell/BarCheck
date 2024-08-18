//
//  View2.swift
//  BarCheck_
//
//  Created by Isaac Petrella on 10/17/23.
//

import SwiftUI
import AuthenticationServices
import GoogleSignIn
import GoogleSignInSwift
import Firebase

struct Login: View {
    
    @StateObject var loginModel: LoginViewModel = .init()
    var body: some View {
        ZStack{
            Color(.backgroundCyan)
                .ignoresSafeArea()
            ScrollView(.vertical, showsIndicators: false){
                VStack(alignment: .center, spacing: 15) {
                    Text("BarCheck")
                        .foregroundStyle(.colorWhite)
                        .font(.system(size:72,weight: .heavy, design: .monospaced))
                    Spacer()
                    Text("Login to continue")
                    //  .font(.title)
                        .font(.title2)
                        .foregroundStyle(.accent)
                        .font(.system(size:30,weight: .bold))
                    
                    // MARK: Custom TextField
                    CustomTextField(hint: "+1 6505551234", text: $loginModel.mobileNo)
                        .disabled(loginModel.showOTPField)
                        .opacity(loginModel.showOTPField ? 0.4 : 1)
                        .overlay(alignment: .trailing, content: {
                            Button("Change"){
                                withAnimation(.easeInOut){
                                    loginModel.showOTPField = false
                                    loginModel.otpCode = ""
                                    loginModel.CLIENT_CODE = ""
                                }
                            }
                            .font(.caption)
                            .padding(.trailing, 10)
                            .opacity(loginModel.showOTPField ? 1 : 0)
                        })
                    
                        .padding(.leading, 50)
                        .padding(.top, 50)
                    CustomTextField(hint: "Verfication Code", text: $loginModel.otpCode)
                        .disabled(!loginModel.showOTPField)
                        .opacity(!loginModel.showOTPField ? 0.4 : 1)
                        .padding(.leading, 50)
                    
                    Button(action: loginModel.showOTPField ? loginModel.verifyOTPCode : loginModel.getOTPCode) {
                        HStack(spacing: 15){
                            Text(loginModel.showOTPField ? "Verify Code" : "Get Code")
                                .fontWeight(.semibold)
                                .contentTransition(.identity)
                            Image(systemName: "line.diagonal.arrow")
                                .font(.title3)
                                .rotationEffect(.init(degrees: 45))
                        }
                        .padding(.horizontal,25)
                        .padding(.vertical)
                        .background {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(.colorWhite)
                        }
                    }
                    Text("or")
                        .foregroundStyle(.accent)
                    //HStack (spacing: 8){
                        // MARK: Custom Apple Sign-in Button
                        CustomButton()
                            .overlay{
                                SignInWithAppleButton { (request) in
                                    // MARK: Requesting Parameters from Apple Login}
                                    loginModel.nonce = randomNonceString()
                                    request.requestedScopes = [.email,.fullName]
                                    request.nonce = sha256(loginModel.nonce)
                                } onCompletion: { (result) in
                                    // MARK: Getting Success or Error
                                    switch result{
                                    case .success(let user):
                                        print("Success!")
                                        // MARK: Do Login with Firebase
                                        guard let credential = user.credential as?
                                                ASAuthorizationAppleIDCredential else {
                                            print("Error with Firebase")
                                            return
                                        }
                                        loginModel.appleAuthenticate(credential: credential)
                                    case.failure(let error):
                                        print(error.localizedDescription)
                                    }
                                }
                                .signInWithAppleButtonStyle(.white)
                                .frame(height: 55)
                                .blendMode(.destinationOver)
                            }
                            .clipped()
                        
                        
                        // MARK: Custom Google Sign-in Button
                        CustomButton(isGoogle: true)
                            .overlay{
                                if let clientID = FirebaseApp.app()?.options.clientID{
                                    GoogleSignInButton{
                                        GIDSignIn.sharedInstance.signIn(with:
                                                .init(clientID: clientID), presenting:
                                                                            UIApplication.shared.rootController()){user, error in
                                            if let error = error{
                                                print(error.localizedDescription)
                                                return
                                            }
                                            // MARK: Logging Google User into Firebase
                                            if let user{
                                                loginModel.logGoogleUser(user: user)
                                            }
                                        }
                                            
                                    }
                                    .frame(height: 55)
                                    .blendMode(.destinationOver)
                                }
                                 // .clipped()
                            }
                           // .padding(.leading,-60)
                            .frame(maxWidth: .infinity)
                    //}
                }
            }
            .alert(loginModel.errorMessage, isPresented: $loginModel.showError){
            }
        }
        
    }
    
   var body3: some View {
        CustomButton()
    }
}
struct Login_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(BookmarkViewModel()) // Inject here
    }
}
