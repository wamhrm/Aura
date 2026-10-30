//
//  AppleAuthService.swift
//  AuraBackend
//
//  Created by wamhrm on 25.10.2026.
//

import JWTKit
import Vapor

struct AppleAuthService {
    private let baseURL = Environment.get("APPLE_AUTH_BASE_URL") ?? "https://appleid.apple.com"
    private let bundleID = Environment.get("APPLE_BUNDLE_ID")

    func verifyIdentityToken(_ identityToken: String, nonce: String, req: Request) async throws -> AppleIdentityToken {
        guard let bundleID else {
            req.logger.error("Sign in with Apple is not configured: APPLE_BUNDLE_ID is missing")
            throw Abort(.serviceUnavailable, reason: "Вход через Apple временно недоступен")
        }

        let keys = JWTKeyCollection()
        try await keys.add(jwksJSON: fetchPublicKeys(req: req))

        do {
            let token = try await keys.verify(identityToken, as: AppleIdentityToken.self)
            try token.audience.verifyIntendedAudience(includes: bundleID)

            guard token.nonce == SHA256.hash(data: Data(nonce.utf8)).hex else {
                throw Abort(.unauthorized, reason: "Nonce mismatch")
            }

            return token
        } catch {
            req.logger.warning("Apple identity token rejected: \(error)")
            throw Abort(.unauthorized, reason: "Не удалось войти через Apple")
        }
    }

    func refreshToken(for authorizationCode: String, req: Request) async -> String? {
        guard let bundleID, let clientSecret = await makeClientSecret(req: req) else {
            req.logger.warning("Apple refresh token not requested: Sign in with Apple keys are not configured")
            return nil
        }

        do {
            let response = try await req.client.post(URI(string: baseURL + "/auth/token")) { request in
                try request.content.encode(AppleTokenRequest(clientID: bundleID,
                                                             clientSecret: clientSecret,
                                                             code: authorizationCode),
                                           as: .urlEncodedForm)
            }

            guard response.status == .ok else {
                req.logger.warning("Apple code exchange failed with status \(response.status.code)")
                return nil
            }

            return try response.content.decode(AppleTokenResponse.self).refreshToken
        } catch {
            req.logger.warning("Apple code exchange failed: \(error)")
            return nil
        }
    }

    func revoke(refreshToken: String, req: Request) async {
        guard let bundleID, let clientSecret = await makeClientSecret(req: req) else {
            req.logger.warning("Apple token not revoked: Sign in with Apple keys are not configured")
            return
        }

        do {
            let response = try await req.client.post(URI(string: baseURL + "/auth/revoke")) { request in
                try request.content.encode(AppleRevokeRequest(clientID: bundleID,
                                                              clientSecret: clientSecret,
                                                              token: refreshToken),
                                           as: .urlEncodedForm)
            }

            if response.status != .ok {
                req.logger.warning("Apple token revocation failed with status \(response.status.code)")
            }
        } catch {
            req.logger.warning("Apple token revocation failed: \(error)")
        }
    }

    private func fetchPublicKeys(req: Request) async throws -> String {
        let response: ClientResponse

        do {
            response = try await req.client.get(URI(string: baseURL + "/auth/keys"))
        } catch {
            req.logger.error("Apple public keys request failed: \(error)")
            throw Abort(.badGateway, reason: "Не удалось связаться с Apple. Попробуйте позже")
        }

        guard response.status == .ok, let body = response.body else {
            req.logger.error("Apple public keys request failed with status \(response.status.code)")
            throw Abort(.badGateway, reason: "Не удалось связаться с Apple. Попробуйте позже")
        }

        return String(buffer: body)
    }

    private func makeClientSecret(req: Request) async -> String? {
        guard let bundleID,
              let teamID = Environment.get("APPLE_TEAM_ID"),
              let keyID = Environment.get("APPLE_KEY_ID"),
              let privateKey = Environment.get("APPLE_PRIVATE_KEY") else { return nil }

        do {
            let key = try ES256PrivateKey(pem: privateKey.replacingOccurrences(of: "\\n", with: "\n"))
            let kid = JWKIdentifier(string: keyID)
            let keys = await JWTKeyCollection().add(ecdsa: key, kid: kid)
            let now = Date()
            let payload = AppleClientSecret(issuer: IssuerClaim(value: teamID),
                                            issuedAt: IssuedAtClaim(value: now),
                                            expires: ExpirationClaim(value: now.addingTimeInterval(300)),
                                            audience: AudienceClaim(value: ["https://appleid.apple.com"]),
                                            subject: SubjectClaim(value: bundleID))
            return try await keys.sign(payload, kid: kid)
        } catch {
            req.logger.error("Apple client secret could not be created: \(error)")
            return nil
        }
    }
}

private struct AppleClientSecret: JWTPayload {
    enum CodingKeys: String, CodingKey {
        case issuer = "iss"
        case issuedAt = "iat"
        case expires = "exp"
        case audience = "aud"
        case subject = "sub"
    }

    let issuer: IssuerClaim
    let issuedAt: IssuedAtClaim
    let expires: ExpirationClaim
    let audience: AudienceClaim
    let subject: SubjectClaim

    func verify(using algorithm: some JWTAlgorithm) throws {}
}

private struct AppleTokenRequest: Encodable {
    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case clientSecret = "client_secret"
        case code
        case grantType = "grant_type"
    }

    let clientID: String
    let clientSecret: String
    let code: String
    let grantType = "authorization_code"
}

private struct AppleRevokeRequest: Encodable {
    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case clientSecret = "client_secret"
        case token
        case tokenTypeHint = "token_type_hint"
    }

    let clientID: String
    let clientSecret: String
    let token: String
    let tokenTypeHint = "refresh_token"
}

private struct AppleTokenResponse: Decodable {
    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }

    let refreshToken: String?
}
