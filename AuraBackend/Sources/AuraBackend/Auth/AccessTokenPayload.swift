import JWT

struct AccessTokenPayload: JWTPayload {
    let subject: SubjectClaim
    let expiration: ExpirationClaim
    let email: String

    func verify(using _: some JWTAlgorithm) throws {
        try expiration.verifyNotExpired()
    }
}
