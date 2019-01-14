import Vapor

public func routes(_ router: Router) throws {
    struct LogData: Content {
        let data: String
    }

    router.post(LogData.self, at: "logs") { (req, content) -> HTTPStatus in
        print("Received logs:")
        print("========================================================================================")
        print(content.data, terminator: "")
        print("========================================================================================")
        print()

        return HTTPStatus.ok
    }
}
