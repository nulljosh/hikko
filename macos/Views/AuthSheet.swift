import AuthenticationServices
import SwiftUI

struct AuthSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var tab = 0
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 20) {
            Text(tab == 0 ? "Sign In" : "Register")
                .font(.title2.bold())

            Picker("Mode", selection: $tab) {
                Text("Sign In").tag(0)
                Text("Register").tag(1)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.email, .fullName]
            } onCompletion: { result in
                Task { await appState.handleAppleSignIn(result: result) }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 40)

            HStack {
                Rectangle().frame(height: 1).foregroundStyle(.quaternary)
                Text("or").font(.caption).foregroundStyle(.secondary)
                Rectangle().frame(height: 1).foregroundStyle(.quaternary)
            }

            VStack(spacing: 12) {
                TextField("Username", text: $username)
                    .textFieldStyle(.roundedBorder)

                if tab == 1 {
                    TextField("Email (optional)", text: $email)
                        .textFieldStyle(.roundedBorder)
                }

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
            }

            if let err = appState.error {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    appState.error = nil
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button(action: submit) {
                    if appState.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text(tab == 0 ? "Sign In" : "Create Account")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .tint(.sparkBlue)
                .disabled(!canSubmit)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(32)
        .frame(width: 360)
    }

    private var canSubmit: Bool {
        !username.isEmpty && !password.isEmpty && !appState.isLoading
    }

    private func submit() {
        Task {
            if tab == 0 {
                await appState.login(username: username, password: password)
            } else {
                await appState.register(username: username, email: email.isEmpty ? nil : email, password: password)
            }
        }
    }
}
