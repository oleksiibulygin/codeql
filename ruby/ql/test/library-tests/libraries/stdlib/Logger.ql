import codeql.ruby.libraries.stdlib.Logger::Logger
import codeql.ruby.DataFlow

query DataFlow::Node loggerLoggingCallInputs(LoggerLoggingCall c) { result = c.getAnInput() }
