import Foundation

struct ProfileInfoModel: Codable {
    var dateOfBirth = ""
    var birthTime = ""
    var gender: String?
    var socialType: String?
    var conflictStyle: String?
    var emotionalCore: String?
    var decisionStyle: String?
    var coreFocus: String?
    
    init() { }
    
    init(user: UserModel) {
        self.dateOfBirth = user.dateOfBirth ?? ""
        self.birthTime = user.birthTime ?? ""
        self.gender = user.gender
        self.socialType = user.socialType
        self.conflictStyle = user.conflictStyle
        self.emotionalCore = user.emotionalCore
        self.decisionStyle = user.decisionStyle
        self.coreFocus = user.coreFocus
    }
}

enum ProfileInfoError: LocalizedError {
    case invalidDateOfBirth
    case incompleteProfileInfo

    var errorDescription: String {
        switch self {
            case .invalidDateOfBirth:
                return "Укажите дату рождения в формате ДД.ММ.ГГГГ"
            case .incompleteProfileInfo:
                return "Заполните все обязательные поля профиля"
        }
    }
}
