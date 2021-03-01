import python
import semmle.python.ApiGraphs
import semmle.python.dataflow.new.internal.Attributes as Attributes
import TlsLibraryModel

class SSLContextCreation extends ContextCreation {
  override CallNode node;

  SSLContextCreation() { this = API::moduleImport("ssl").getMember("SSLContext").getACall() }

  override DataFlow::CfgNode getProtocol() {
    result.getNode() in [node.getArg(0), node.getArgByName("protocol")]
  }
}

class SSLDefaultContextCreation extends ContextCreation {
  SSLDefaultContextCreation() {
    this = API::moduleImport("ssl").getMember("create_default_context").getACall()
  }

  // Allowed insecure versions are "TLSv1" and "TLSv1_1"
  // see https://docs.python.org/3/library/ssl.html#context-creation
  override DataFlow::CfgNode getProtocol() { none() }
}

class WrapSocketCall extends ConnectionCreation {
  override CallNode node;

  WrapSocketCall() { node.getFunction().(AttrNode).getName() = "wrap_socket" }

  override DataFlow::CfgNode getContext() {
    result.getNode() = node.getFunction().(AttrNode).getObject()
  }
}

class OptionsAugOr extends ProtocolRestriction {
  ProtocolVersion restriction;

  OptionsAugOr() {
    exists(AugAssign aa, AttrNode attr, Expr flag |
      aa.getOperation().getOp() instanceof BitOr and
      aa.getTarget() = attr.getNode() and
      attr.getName() = "options" and
      attr.getObject() = node and
      flag = API::moduleImport("ssl").getMember("OP_NO_" + restriction).getAUse().asExpr() and
      (
        aa.getValue() = flag
        or
        impliesValue(aa.getValue(), flag, false, false)
      )
    )
  }

  override DataFlow::CfgNode getContext() { result = this }

  override ProtocolVersion getRestriction() { result = restriction }
}

/** Whether `part` evaluates to `partIsTrue` if `whole` evaluates to `wholeIsTrue`. */
predicate impliesValue(BinaryExpr whole, Expr part, boolean partIsTrue, boolean wholeIsTrue) {
  whole.getOp() instanceof BitAnd and
  (
    wholeIsTrue = true and partIsTrue = true and part in [whole.getLeft(), whole.getRight()]
    or
    wholeIsTrue = true and
    impliesValue([whole.getLeft(), whole.getRight()], part, partIsTrue, wholeIsTrue)
  )
  or
  whole.getOp() instanceof BitOr and
  (
    wholeIsTrue = false and partIsTrue = false and part in [whole.getLeft(), whole.getRight()]
    or
    wholeIsTrue = false and
    impliesValue([whole.getLeft(), whole.getRight()], part, partIsTrue, wholeIsTrue)
  )
}

class ContextSetVersion extends ProtocolRestriction {
  string restriction;

  ContextSetVersion() {
    exists(Attributes::AttrWrite aw |
      aw.getObject().asCfgNode() = node and
      aw.getAttributeName() = "minimum_version" and
      aw.getValue() =
        API::moduleImport("ssl").getMember("TLSVersion").getMember(restriction).getAUse()
    )
  }

  override DataFlow::CfgNode getContext() { result = this }

  override ProtocolVersion getRestriction() { result.lessThan(restriction) }
}

class Ssl extends TlsLibrary {
  Ssl() { this = "ssl" }

  override string specific_insecure_version_name(ProtocolVersion version) {
    version in ["SSLv2", "SSLv3", "TLSv1", "TLSv1_1"] and
    result = "PROTOCOL_" + version
  }

  override string unspecific_version_name() {
    result =
      "PROTOCOL_" +
        [
          "TLS",
          // This can negotiate a TLS 1.3 connection (!)
          // see https://docs.python.org/3/library/ssl.html#ssl-contexts
          "SSLv23"
        ]
  }

  override API::Node version_constants() { result = API::moduleImport("ssl") }

  override ContextCreation default_context_creation() {
    result instanceof SSLDefaultContextCreation
  }

  override ContextCreation specific_context_creation() { result instanceof SSLContextCreation }

  override DataFlow::CfgNode insecure_connection_creation(ProtocolVersion version) {
    result = API::moduleImport("ssl").getMember("wrap_socket").getACall() and
    insecure_version(version).asCfgNode() =
      result.asCfgNode().(CallNode).getArgByName("ssl_version")
  }

  override ConnectionCreation connection_creation() { result instanceof WrapSocketCall }

  override ProtocolRestriction protocol_restriction() {
    result instanceof OptionsAugOr
    or
    result instanceof ContextSetVersion
  }
}
