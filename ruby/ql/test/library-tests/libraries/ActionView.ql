import codeql.ruby.libraries.ActionController
import codeql.ruby.libraries.ActionView

query predicate htmlSafeCalls(HtmlSafeCall c) { any() }

query predicate rawCalls(RawCall c) { any() }

query predicate renderCalls(RenderCall c) { any() }

query predicate renderToCalls(RenderToCall c) { any() }

query predicate linkToCalls(LinkToCall c) { any() }
