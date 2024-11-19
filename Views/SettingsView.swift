//
//  SettingsView.swift
//  Sam2
//
//  Created by Evgeny Cherpak on 19/11/2024.
//

import SwiftUI
import CryptoKit

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var viewModel: MainAppModel
    
    @State var clientId: String = UserDefaults.standard.clientId ?? ""
    @State var teamId: String = UserDefaults.standard.teamId ?? ""
    @State var keyId: String = UserDefaults.standard.keyId ?? ""
    
    @State var privateKey: String = UserDefaults.standard.privateKey ?? ""
    @State var publicKey: String = UserDefaults.standard.publicKey ?? ""
        
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("You can find those values in SearchAds portal settings after adding an account with API role")
                Link("Help", destination: URL(string: "https://developer.apple.com/documentation/apple_search_ads/implementing_oauth_for_the_apple_search_ads_api")!)
                
                TextField("Client ID", text: $clientId)
                TextField("Team ID", text: $teamId)
                TextField("Key ID", text: $keyId)
                
                Text("Private Key")
                TextEditView(text: $privateKey)
                    .font(.body.monospaced())
                    .disabled(true)
                
                HStack {
                    Text("Public Key")
                    Spacer()
                    Button {
                        #if os(iOS)
                        UIPasteboard.general.string = publicKey
                        #else
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(publicKey, forType: .string)
                        #endif
                    } label: {
                        Text("Copy")
                    }
                }
                TextEditView(text: $publicKey)
                    .font(.body.monospaced())
                    .disabled(true)
                
                
            }
            .onChange(of: clientId) {
                UserDefaults.standard.clientId = clientId
                applySettings()
            }
            .onChange(of: teamId) {
                UserDefaults.standard.teamId = teamId
                applySettings()
            }
            .onChange(of: keyId) {
                UserDefaults.standard.keyId = keyId
                applySettings()
            }
            .padding()
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", role: .cancel) {
                        applySettings()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func applySettings() {
        // Check if we have everything to connect
        // try and if successful - dismiss settings
        
        guard
            let clientId = UserDefaults.standard.clientId,
            let teamId = UserDefaults.standard.teamId,
            let keyId = UserDefaults.standard.keyId,
            let privateKey = UserDefaults.standard.privateKey,
            let _ = UserDefaults.standard.publicKey
        else {
            return
        }
        
        let issued_at_timestamp = Int(Date().timeIntervalSince1970)
        let expiration_timestamp = issued_at_timestamp + 86400*180
        
        struct Header: Encodable {
            let alg: String // "ES256"
            let kid: String // = keyId
        }
        
        struct Payload: Encodable {
            let sub: String // clientId
            let aud: String // https://appleid.apple.com
            let iat: Int // issued_at_timestamp
            let exp: Int // expiration_timestamp
            let iss: String // teamId
        }

        do {
            let privateKey = try P256.Signing.PrivateKey.init(pemRepresentation: privateKey)
            let headerJSONData = try JSONEncoder().encode(Header(alg: "ES256", kid: keyId))
            let headerBase64String = headerJSONData.urlSafeBase64EncodedString()
            
            let payloadJSONData = try JSONEncoder().encode(Payload(sub: clientId, aud: "https://appleid.apple.com", iat: issued_at_timestamp, exp: expiration_timestamp, iss: teamId))
            let payloadBase64String = payloadJSONData.urlSafeBase64EncodedString()
            
            let toSign = Data((headerBase64String + "." + payloadBase64String).utf8)
            let signature = try privateKey.signature(for: toSign)
            let signatureBase64String = signature.rawRepresentation.urlSafeBase64EncodedString()
            
            let token = [headerBase64String, payloadBase64String, signatureBase64String].joined(separator: ".")
            UserDefaults.standard.clientSecret = token
            
            viewModel.clientId = clientId
            viewModel.clientSecret = token
        } catch let error {
            // TODO: show error!
        }
    }
}

extension Data {
    func urlSafeBase64EncodedString() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
