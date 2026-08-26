# HTTP / TLS / DNS

[Back to the curriculum](../../README.md)

## Profile

- **Audience:** Application developers
- **Leads:** 2
- **Duration:** 120 minutes

## Purpose

Construct a high-level explanation of the journey from a URL to an authenticated HTTP response, with emphasis on protocol philosophy and application-relevant HTTP semantics.

Participants should finish with one connected model rather than three disconnected protocol summaries.

## Preparation brief

Choose a representative URL and follow it from the client to the application. Introduce DNS, TLS, and HTTP only when the request reaches the problem each protocol solves.

Keep the session theory-led. Tools may help confirm the sequence, but packet analysis and cryptographic implementation details are outside the intended scope.

## Guiding vectors

### 1. Define the end-to-end request

Create a sequence containing at least:

- The client application
- Local and recursive name resolution
- DNS authority
- Transport establishment
- TLS negotiation
- An HTTP intermediary or gateway
- The destination application

Investigate which steps are always required, which can be cached or reused, and which depend on protocol version or deployment design.

### 2. Investigate DNS as a naming system

Ask:

- Why is naming separate from addressing?
- How is authority distributed and delegated?
- What work belongs to recursive and authoritative participants?
- What is cached, by whom, and for how long?
- Which record types are needed for the chosen request?
- How can stale or inconsistent answers arise?
- Which failures belong to DNS rather than the application?

Keep DNSSEC and resolver implementation internals outside the core session.

### 3. Investigate TLS as a trust protocol

Ask:

- What threats is TLS designed to address?
- How does a client decide which identity it intends to reach?
- How is that identity connected to a certificate and a chain of trust?
- Which information must be negotiated before HTTP begins?
- Why do SNI and ALPN exist?
- What can terminate TLS, and how does termination change responsibility?
- Which failures should be distinguished from transport and HTTP failures?

Explain cryptographic mechanisms only to the degree required to understand the guarantees and trust model.

### 4. Investigate HTTP semantics

Prioritize concepts that affect application behavior:

- Methods and their intended semantics
- Safety and idempotency
- Status codes and redirects
- Headers and representation metadata
- Authentication versus authorization signals
- Caching and validation
- Cookies and browser state
- CORS as a browser security mechanism
- Forwarded information and proxy boundaries

Use examples to test whether an API or application behavior agrees with the protocol semantics.

### 5. Place HTTP versions in context

For HTTP/1.1, HTTP/2, and HTTP/3, investigate:

- Which limitations motivated the next version?
- What changed in connection use and multiplexing?
- Which application semantics remained stable?
- Which differences should an application developer actually notice?

Do not spend the session on frame formats or transport implementation.

### 6. Classify failures

Prepare several request failures and ask participants to assign responsibility:

- Name cannot be resolved.
- The result is stale or points elsewhere.
- A transport connection cannot be established.
- Certificate identity validation fails.
- TLS negotiation fails.
- A gateway rejects or cannot route the request.
- The application returns an error.
- A browser blocks access despite a valid server response.

The goal is a disciplined high-level diagnosis before reaching for lower-level tools.

## Scope boundaries

### Keep

- One URL-to-response narrative
- DNS delegation and caching
- TLS identity, trust chains, SNI, and ALPN
- HTTP methods, status, headers, idempotency, redirects, and caching
- Cookies, CORS, and proxy boundaries
- Motivation-level comparison of HTTP versions
- Failure ownership

### Leave out

- Packet-capture analysis
- TLS cryptographic primitive details
- TLS wire-message memorization
- Detailed HTTP frame formats
- DNSSEC
- Exhaustive DNS record coverage
- Deep HTTP-version benchmarking

## Starting references

- [RFC 9110: HTTP Semantics](https://www.rfc-editor.org/rfc/rfc9110)
- [RFC 9111: HTTP Caching](https://www.rfc-editor.org/rfc/rfc9111)
- [RFC 8446: TLS 1.3](https://www.rfc-editor.org/rfc/rfc8446)
- [RFC 1034: Domain Names — Concepts and Facilities](https://www.rfc-editor.org/rfc/rfc1034)
- [MDN: HTTP](https://developer.mozilla.org/en-US/docs/Web/HTTP)
- [MDN: CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)

## Minimum preparation

- Lead the request-flow and application-semantics discussion.
- Share the references used.
