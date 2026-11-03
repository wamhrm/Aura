//
//  AppleAuthService.swift
//  AuraBackend
//
//  Created by wamhrm on 25.10.2026.
//

import JWTKit
import NIOCore
import Vapor

struct AppleAuthService {
    private static let publicKeysCache = ApplePublicKeysCache()

    private let baseURL = Environment.get("APPLE_AUTH_BASE_URL") ?? "https://appleid.apple.com"
    private let bundleID = Environment.get("APPLE_BUNDLE_ID")
    private let requestTimeout: TimeAmount = .seconds(10)
    private let tokenCipher = AppleTokenCipher()

    func verifyIdentityToken(_ identityToken: String, nonce: String, req: Request) async throws -> AppleIdentityToken {
        guard let bundleID else {
            req.logger.error("Sign in with Apple is not configured: APPLE_BUNDLE_ID is missing")
            throw Abort(.serviceUnavailable, reason: "Вход через Apple временно недоступен")
        }

        let publicKeys = try await cachedPublicKeys(req: req)

        do {
            let token = try await verifiedToken(identityToken, publicKeys: publicKeys, req: req)
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

    // The token gives access to the user's Apple ID, so only its encrypted form may reach the database
    func encryptedRefreshToken(for authorizationCode: String, req: Request) async -> String? {
        guard let bundleID, let clientSecret = await makeClientSecret(req: req) else {
            req.logger.warning("Apple refresh token not requested: Sign in with Apple keys are not configured")
            return nil
        }

        do {
            let response = try await req.client.post(URI(string: baseURL + "/auth/token")) { request in
                request.timeout = requestTimeout
                try request.content.encode(AppleTokenRequest(clientID: bundleID,
                                                             clientSecret: clientSecret,
                                                             code: authorizationCode),
                                           as: .urlEncodedForm)
            }

            guard response.status == .ok else {
                req.logger.warning("Apple code exchange failed with status \(response.status.code)")
                return nil
            }

            return try response.content.decode(AppleTokenResponse.self).refreshToken.map(tokenCipher.encrypt)
        } catch {
            req.logger.warning("Apple code exchange failed: \(error)")
            return nil
        }
    }

    func revoke(encryptedRefreshToken: String, req: Request) async {
        guard let bundleID, let clientSecret = await makeClientSecret(req: req) else {
            req.logger.warning("Apple token not revoked: Sign in with Apple keys are not configured")
            return
        }

        do {
            let refreshToken = try tokenCipher.decrypt(encryptedRefreshToken)
            let response = try await req.client.post(URI(string: baseURL + "/auth/revoke")) { request in
                request.timeout = requestTimeout
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

    private func verifiedToken(_ identityToken: String, publicKeys: String, req: Request) async throws -> AppleIdentityToken {
        do {
            return try await JWTKeyCollection().add(jwksJSON: publicKeys).verify(identityToken, as: AppleIdentityToken.self)
        } catch let error as JWTError where error.errorType == .unknownKID {
            // Apple has changed its keys since they were cached
            let freshKeys = try await fetchPublicKeys(req: req)
            return try await JWTKeyCollection().add(jwksJSON: freshKeys).verify(identityToken, as: AppleIdentityToken.self)
        }
    }

    private func cachedPublicKeys(req: Request) async throws -> String {
        if let cached = await Self.publicKeysCache.keys() {
            return cached
        }

        return try await fetchPublicKeys(req: req)
    }

    private func fetchPublicKeys(req: Request) async throws -> String {
        let response: ClientResponse

        do {
            response = try await req.client.get(URI(string: baseURL + "/auth/keys")) { request in
                request.timeout = requestTimeout
            }
        } catch {
            req.logger.error("Apple public keys request failed: \(error)")
            throw Abort(.badGateway, reason: "Не удалось связаться с Apple. Попробуйте позже")
        }

        guard response.status == .ok, let body = response.body else {
            req.logger.error("Apple public keys request failed with status \(response.status.code)")
            throw Abort(.badGateway, reason: "Не удалось связаться с Apple. Попробуйте позже")
        }

        let keys = String(buffer: body)
        await Self.publicKeysCache.save(keys)
        return keys
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

private actor ApplePublicKeysCache {
    private let lifetime: TimeInterval = 60 * 60
    private var storedKeys: String?
    private var loadedAt = Date.distantPast

    func keys() -> String? {
        Date().timeIntervalSince(loadedAt) < lifetime ? storedKeys : nil
    }

    func save(_ keys: String) {
        storedKeys = keys
        loadedAt = Date()
    }
}

private struct AppleTokenCipher {
    private struct MissingKey: Error {}

    func encrypt(_ token: String) throws -> String {
        guard let sealed = try AES.GCM.seal(Data(token.utf8), using: try key()).combined else { throw MissingKey() }
        return sealed.base64EncodedString()
    }

    func decrypt(_ encrypted: String) throws -> String {
        guard let sealed = Data(base64Encoded: encrypted) else { throw MissingKey() }
        let opened = try AES.GCM.open(AES.GCM.SealedBox(combined: sealed), using: try key())
        return String(decoding: opened, as: UTF8.self)
    }

    // 32 random bytes in base64: openssl rand -base64 32
    private func key() throws -> SymmetricKey {
        guard let value = Environment.get("APPLE_TOKEN_ENCRYPTION_KEY"),
              let data = Data(base64Encoded: value),
              data.count == 32
        else { throw MissingKey() }

        return SymmetricKey(data: data)
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
