import Fluent
import Vapor

extension Application {
    func configureMigrations() {
        self.migrations.add(CreateUser())
        self.migrations.add(CreateToken())
        self.migrations.add(CreateUserProfileInfo())
        self.migrations.add(CreateHistory())
    }
}
