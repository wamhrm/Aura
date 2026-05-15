import Vapor

extension Application {
    func configureMigrations() {
        self.migrations.add(CreateUser())
        self.migrations.add(AddUserProfileInfo())
        self.migrations.add(CreateToken())
    }
}
