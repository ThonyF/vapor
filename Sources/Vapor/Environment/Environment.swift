/// The environment the application is running in, i.e., production, dev, etc. All `Container`s will have
/// an `Environment` that can be used to dynamically register and configure services.
///
///     switch env {
///     case .production:
///         app.http.server.configuration = ...
///     default: break
///     }
///
/// The `Environment` can also be used to retrieve variables from the Process' ENV.
///
///     print(Environment.get("DB_PASSWORD"))
///
public struct Environment: Equatable {
    
    // MARK: - Detection
    
    /// Detects the environment from `CommandLine.arguments`. Invokes `detect(from:)`.
    /// - parameters:
    ///     - arguments: Command line arguments to detect environment from.
    /// - returns: The detected environment, or default env.
    public static func detect(arguments: [String] = CommandLine.arguments) throws -> Environment {
        var commandInput = CommandInput(arguments: arguments)
        return try Environment.detect(from: &commandInput)
    }
    
    /// Detects the environment from `CommandInput`. Parses the `--env` flag.
    /// - parameters:
    ///     - arguments: `CommandInput` to parse `--env` flag from.
    /// - returns: The detected environment, or default env.
    public static func detect(from commandInput: inout CommandInput) throws -> Environment {
        struct EnvironmentSignature: CommandSignature {
            @Option(name: "env", short: "e", help: "Change the application's environment")
            var environment: String?
        }

        var env: Environment
        switch try EnvironmentSignature(from: &commandInput).environment ??
               Environment.process.VAPOR_ENV
        {
            case "prod", "production": env = .production
            case "dev", "development", .none: env = .development
            case "test", "testing": env = .testing
            case .some(let name): env = .init(name: name)
        }
        env.commandInput = commandInput
        return env
    }
    
    // MARK: - Presets

    /// An environment for deploying your application to consumers.
    public static var production: Environment { .init(name: "production") }

    /// An environment for developing your application.
    public static var development: Environment { .init(name: "development") }

    /// An environment for testing your application.
    public static var testing: Environment { .init(name: "testing") }

    /// Creates a custom environment.
    public static func custom(name: String) -> Environment { .init(name: name) }

    // MARK: - Env

    /// Gets a key from the process environment
    public static func get(_ key: String) -> String? {
        return ProcessInfo.processInfo.environment[key]
    }

    /// The current process of the environment.
    public static var process: Process {
        return Process()
    }
    
    // MARK: - Equatable

    /// See `Equatable`
    public static func ==(lhs: Environment, rhs: Environment) -> Bool {
        return lhs.name == rhs.name
    }

    // MARK: - Properties

    /// The environment's unique name.
    public let name: String

    /// `true` if this environment is meant for production use cases.
    ///
    /// This usually means reducing logging, disabling debug information, and sometimes
    /// providing warnings about configuration states that are not suitable for production.
    ///
    /// - Warning: This value is determined at compile time by configuration; it is not
    ///   based on the actual environment name. This can lead to unxpected results, such
    ///   as `Environment.production.isRelease == false`. This is done intentionally to
    ///   allow scenarios, such as testing production environment behaviors while retaining
    ///   availability of debug information.
    public var isRelease: Bool { !_isDebugAssertConfiguration() }

    /// The command-line arguments for this `Environment`.
    public var arguments: [String]

    /// Exposes the `Environment`'s `arguments` property as a `CommandInput`.
    public var commandInput: CommandInput {
        get { return CommandInput(arguments: arguments) }
        set { arguments = newValue.executablePath + newValue.arguments }
    }
    
    // MARK: - Init

    /// Create a new `Environment`.
    public init(name: String, arguments: [String] = CommandLine.arguments) {
        self.name = name
        self.arguments = arguments
    }
}
