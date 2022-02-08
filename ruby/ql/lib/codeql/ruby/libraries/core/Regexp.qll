private import codeql.ruby.ApiGraphs
private import codeql.ruby.dataflow.FlowSummary

module Regexp {
  /** Flow summary for `Regexp.escape` and its alias, `Regexp.quote`. */
  class RegexpEscapeSummary extends SummarizedCallable {
    RegexpEscapeSummary() { this = "Regexp.escape" }

    override MethodCall getACall() {
      result =
        API::getTopLevelMember("Regexp").getAMethodCall(["escape", "quote"]).asExpr().getExpr()
    }

    override predicate propagatesFlowExt(string input, string output, boolean preservesValue) {
      input = "Argument[0]" and
      output = "ReturnValue" and
      preservesValue = false
    }
  }
}
