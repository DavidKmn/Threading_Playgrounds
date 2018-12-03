import UIKit

struct AccessToken {
    let token: String
    var expiryDate: Date = Date().addingTimeInterval(TimeInterval(60))
    let isValid: Bool
}

enum Result<T> {
    case value(T)
    case error(Error)
    
    var value: T? {
        switch self {
        case .value(let val):
            return val
        case .error(_):
            return nil
        }
    }
}

struct AccessTokenLoaderResult {
    var value: AccessToken
}

protocol AccessTokenLoader {
    func load(_ closure: @escaping (Result<AccessToken>) -> Void)
}

class AccessTokenService {
    typealias Handler = (Result<AccessToken>) -> Void
    
    private let loader: AccessTokenLoader
    private var token: AccessToken?
    private let queue: DispatchQueue
    private var pendingHandlers = [Handler]()
    
    init(loader: AccessTokenLoader, queue: DispatchQueue = .init(label: "AccessToken")) {
        self.loader = loader
        self.queue = queue
    }
    
    func retrieveToken(then handler: @escaping Handler) {
        
        queue.async { [weak self] in
            self?.performRetrieval(with: handler)
        }
        
    }
}

private extension AccessTokenService {
    
    func performRetrieval(with handler: @escaping Handler) {
        if let token = token, token.isValid {
            return handler(.value(token))
        }
        
        pendingHandlers.append(handler)
        
        // Well only start loading if the current handler is alone in the array after being inserted
        guard pendingHandlers.count == 1 else { return }
        
        loader.load { [weak self] result in
            // Whenever we are mutating our class' internal
            // state, we always dispatch onto our queue. That
            // way, we can be sure that no concurrent mutations
            // will occur.
            self?.queue.async {
                self?.handle(result)
            }
        }
    }
    
    
    func handle(_ result: Result<AccessToken>) {
        token = result.value
        
        let handlers = pendingHandlers
        pendingHandlers = []
        handlers.forEach { $0(result) }
    }
}
