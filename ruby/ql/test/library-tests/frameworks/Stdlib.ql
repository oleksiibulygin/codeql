import codeql.ruby.frameworks.Stdlib
import codeql.ruby.DataFlow

query predicate subshellLiteralExecutions(SubshellLiteralExecution e) { any() }

query predicate subshellHeredocExecutions(SubshellHeredocExecution e) { any() }
