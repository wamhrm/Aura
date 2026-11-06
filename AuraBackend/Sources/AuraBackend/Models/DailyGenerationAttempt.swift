import Fluent
import Foundation

final class DailyGenerationAttempt: Model, @unchecked Sendable {
    static let schema = "daily_generation_attempts"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Field(key: "kind")
    var kind: String

    @Field(key: "generated_date")
    var generatedDate: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(userID: User.IDValue, kind: DailyContentKind, generatedDate: String) {
        self.$user.id = userID
        self.kind = kind.rawValue
        self.generatedDate = generatedDate
    }
}
