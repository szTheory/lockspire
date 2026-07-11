# OAuth/OIDC For Phoenix Adopters

Your Phoenix app already logs users in. OAuth/OIDC is for the next problem:
letting other software use that signed-in identity safely.

That is the whole idea behind Lockspire.

You keep your accounts, sessions, login pages, layouts, brand, tenant rules, and
product policy. Lockspire adds the protocol machinery that lets another app ask
for access, receive tokens, and call your API without ever seeing the user's
password.

This guide uses **Billingo**, the fictional billing SaaS from the adoption demo,
as the running example. Billingo has users, invoices, a dashboard, and a billing
API. A partner app wants to read Alice's billing summary. Billingo wants that to
be safe, understandable, revocable, and standards-based.

After reading, you should be able to decide what Lockspire will do in your app,
what your app still owns, and what all the main OAuth/OIDC words mean when you
see them in the install guide.

## The picture first

OAuth is not "how Alice logs in to Billingo." Billingo already has that.

OAuth is "how another app gets permission to use Billingo on Alice's behalf."

OIDC is the identity layer on top: "and how that other app can know which
Billingo user approved the request."

```text
Alice's browser        Partner app       Billingo Phoenix app        Billingo API
      |                     |                      |                       |
      | clicks Connect      |                      |                       |
      |-------------------->|                      |                       |
      |<--------------------| redirect to          |                       |
      |                     | /lockspire/authorize |                       |
      |------------------------------------------->|                       |
      |                     |                      | Billingo login        |
      |                     |                      | Billingo consent      |
      |<------------------------------------------>|                       |
      |                     |                      |                       |
      |<-------------------------------------------| redirect with code    |
      |-------------------->| callback receives    |                       |
      |                     | code                 |                       |
      |                     |--------------------->| exchange code         |
      |                     |<---------------------| receive tokens        |
      |                     |--------------------------------------------->|
      |                     | call API with access token                  |
```

The important boundary:

| Billingo keeps owning | Lockspire owns |
| --- | --- |
| Users and sessions | OAuth/OIDC protocol state |
| Login and logout UX | Authorization codes and token exchange |
| Consent words and product policy | Stored consent decisions |
| Tenant and billing rules | Client, token, key, and policy records |
| Developer portal and account screens | Discovery, JWKS, userinfo, revocation, introspection |
| Business authorization in APIs | Token verification helpers for Phoenix routes |

If you remember one thing, remember this:

> Lockspire does not replace your Phoenix auth. It turns the identity your app
> already trusts into OAuth/OIDC tokens that other software can trust.

## OAuth vs OIDC

OAuth answers an access question:

> Can this app call this API for this user with these permissions?

OIDC answers an identity question:

> Which user is this, according to the issuer?

In Billingo terms:

| Question | Example | Lockspire artifact |
| --- | --- | --- |
| Access | "Can the dashboard read Alice's billing summary?" | Access token with `read:billing` |
| Identity | "Which Billingo user approved this?" | ID token and userinfo claims with `sub`, `email`, `name` |
| Trust | "How does the partner know Billingo issued this?" | Issuer, discovery, JWKS, signatures |
| Continuity | "How can the app stay connected without asking Alice every hour?" | Refresh token rotation |

OAuth gives the partner app a way to call Billingo. OIDC gives it a standard way
to understand the signed-in user behind that approval.

## The roles

OAuth names are famously abstract. Here is the same vocabulary in Billingo
language.

| OAuth/OIDC word | Billingo translation |
| --- | --- |
| Resource owner | Alice, the Billingo user who can approve access |
| Client | The app asking for access, such as Billingo Dashboard SPA or a partner portal |
| Authorization server | Lockspire mounted inside Billingo |
| Resource server | Billingo's API, such as `/api/billing/summary` |
| Issuer | The public URL identity of Billingo's Lockspire provider |
| User agent | Alice's browser |
| Redirect URI | The exact callback URL where Lockspire may send the browser after approval |

The word **client** does not mean "your customer." It means "the software client
that wants tokens." That might be a browser app, a backend service, a CLI, or a
device.

The word **issuer** does not mean "a company." It means "the stable URL that
identifies this authorization server." Tokens and discovery metadata use it so
clients can verify they are talking to the right provider.

## The normal browser flow

Most adopters start with authorization code + PKCE. It is the normal web and
mobile flow for "send the user to my app, let them approve, then return to the
client."

```text
1. Partner app sends Alice to Billingo's authorization endpoint.

   GET /lockspire/authorize
     client_id=billingo-dashboard-public
     response_type=code
     redirect_uri=https://billingo.example/oauth/callback
     scope=openid email profile read:billing
     state=random-client-value
     nonce=random-oidc-value
     code_challenge=hash-of-secret-verifier
     code_challenge_method=S256

2. Lockspire validates the OAuth request.

   Is the client registered?
   Is this exact redirect URI allowed?
   Is PKCE present?
   Are these scopes allowed?

3. Billingo handles the human parts.

   Is Alice signed in?
   If not, send her through Billingo's login page.
   Show Billingo's consent copy.
   Apply Billingo's tenant and product policy.

4. Lockspire completes the protocol decision.

   If Alice approves, create a short-lived authorization code.
   Redirect the browser back to the registered redirect URI.

5. The client exchanges the code at /lockspire/token.

   It sends the original PKCE verifier.
   Lockspire checks that the verifier matches the challenge.
   Lockspire issues tokens.

6. The client calls Billingo APIs.

   It sends the access token.
   Billingo verifies token facts and still applies business authorization.
```

The authorization code is not the final credential. It is a short-lived,
single-use handoff. The real credential comes from the token endpoint after the
client proves it is the same client that started the request.

Two small parameters protect the round trip:

| Parameter | Plain meaning | Why it exists |
| --- | --- | --- |
| `state` | A random value the client expects to get back | Helps the client reject mixed-up or forged browser callbacks |
| `nonce` | A random value tied to the OIDC identity response | Helps the client reject an ID token from the wrong request |

`response_type=code` means "return an authorization code." The matching token
request uses `grant_type=authorization_code`, which means "exchange that code for
tokens."

## Why PKCE matters

PKCE is pronounced "pixy." It is a proof that protects the authorization code.

At the start, the client creates a secret called a code verifier. It sends only a
hash of that secret, the code challenge, to Lockspire. Later, when exchanging the
authorization code, the client must send the original verifier.

```text
Start request:
  client keeps:  code_verifier
  Lockspire sees: code_challenge = SHA256(code_verifier)

Token request:
  client sends:  authorization_code + code_verifier
  Lockspire checks:
    SHA256(code_verifier) == original code_challenge
```

If a code leaks through browser history, logs, or a bad redirect, the attacker
still cannot exchange it without the verifier.

Lockspire requires S256 PKCE by default. That is one of the defaults you want
from an OAuth/OIDC provider library.

## Scopes are names for requested access

A scope is a short string the client asks for. It is not magic by itself. It is a
shared name your product and your integrators agree on.

Billingo might use:

| Scope | Meaning in Billingo |
| --- | --- |
| `openid` | This is an OIDC request; an ID token may be issued |
| `email` | Include email-related identity claims when allowed |
| `profile` | Include basic profile claims when allowed |
| `read:billing` | Allow reads of billing summary data |
| `write:reports` | Allow report-writing actions if Billingo policy permits |

Scopes answer: "What kind of access is being requested?"

They do not answer every authorization question. Billingo still owns tenant
membership, plan limits, staff/admin status, account suspension, object-level
access, rate limits, and any billing-specific policy. Lockspire can verify that a
token has `read:billing`; Billingo still decides what Alice may read.

## Consent is the human decision

Consent is where the product explains the request in human language.

Lockspire stores and enforces the durable protocol state around consent, but
Billingo owns the words and layout:

```text
Northstar Payables Portal wants access to Billingo.

Requested access:
  - read your billing summary
  - see your name and email

[Approve access] [Deny]
```

Good consent copy is product-specific. "Scope `read:billing`" is useful for a
developer. "Read billing summaries for this workspace" is useful for Alice.

That is why Lockspire keeps consent UX as a host seam instead of pretending one
generic screen can explain every SaaS product.

## Tokens are the output

After approval, Lockspire issues tokens. Each token has a different job.

```text
                 issued by Lockspire
                         |
       ----------------------------------------
       |                 |                    |
  access token        ID token          refresh token
       |                 |                    |
  call Billingo API   tell client who    get fresh tokens
                      Alice is          without re-consent
```

| Token | Who uses it | What it is for | What not to do |
| --- | --- | --- | --- |
| Access token | API/resource server | Authorize API calls | Do not use it as a login session cookie |
| ID token | Client app | Prove identity claims from the issuer | Do not send it as the API bearer token |
| Refresh token | Client app | Rotate into fresh tokens | Do not expose it to browsers unless your client shape allows that safely |

The token names matter because each one has a different audience.

An **access token** is for the API. Billingo's API checks issuer, signature,
expiration, audience, scopes, and sender constraints when configured.

An **ID token** is for the client. It says "Billingo, as issuer, says this is
Alice." It contains identity claims like `sub`, and possibly `email` or `name`
when your host resolver provides them.

A **refresh token** is for continuity. Lockspire rotates refresh tokens and
revokes the family if reuse is detected. That protects against a stolen old
refresh token being replayed quietly.

## Claims are facts in tokens and userinfo

A claim is a named fact.

Common claims:

| Claim | Meaning |
| --- | --- |
| `iss` | Issuer: which authorization server issued this |
| `sub` | Subject: stable identifier for the user |
| `aud` | Audience: who the token is meant for |
| `exp` | Expiration time |
| `iat` | Issued-at time |
| `scope` | Space-separated granted scopes |
| `email` | User email, if the host chooses to expose it |
| `name` | User display name, if the host chooses to expose it |

The most important identity claim is `sub`.

Use a stable internal identifier, not email. Emails change. A Billingo subject
might look like `user:acct_alice`. Your app can choose its own stable subject
format through the account resolver.

Your app decides which business facts become claims. Be conservative. Email and
name are common. Tenant membership, roles, billing plan, and staff/admin status
need more care because downstream apps may treat them as authorization facts.

## Discovery and JWKS make clients trust the issuer

OIDC providers publish a discovery document. It lets clients find the important
endpoints and capabilities from one URL.

```text
Client asks:
  GET /.well-known/openid-configuration

Provider answers:
  issuer
  authorization_endpoint
  token_endpoint
  userinfo_endpoint
  jwks_uri
  supported scopes, grant types, signing algorithms
```

JWKS means JSON Web Key Set. It is the public-key document clients use to verify
signed tokens.

```text
ID token says:
  signed with key id "adoption-demo-rs256"

Client fetches JWKS:
  find public key with that key id
  verify signature
  trust only if issuer, audience, expiration, and signature are valid
```

You do not want every partner guessing your endpoints or copying keys by hand.
Discovery and JWKS make the provider self-describing.

## Userinfo is identity lookup after tokens

OIDC also defines a userinfo endpoint. A client can call it with an access token
to fetch identity claims for the approved user.

```text
Client -> Lockspire /userinfo
  Authorization: Bearer access_token

Lockspire -> client
  {
    "sub": "user:acct_alice",
    "email": "alice@billingo.test",
    "name": "Alice Rivera"
  }
```

Lockspire gets those claims from your host account resolver. That keeps identity
truth in your Phoenix app.

## The host seam

Lockspire needs a small, explicit way to ask your app about accounts.

The generated account resolver answers questions like:

| Lockspire needs to know | Your app answers from |
| --- | --- |
| Who is signed in now? | Your session assigns or current scope |
| If nobody is signed in, where is login? | Your login route |
| What is this subject later? | Your account database |
| Which claims may be exposed? | Your account and product policy |
| How should logout or special approval flows redirect? | Your host UX |

That seam is the center of the embedded-library design.

```text
Billingo session
  current_account: Alice
        |
        v
AccountResolver
  subject: "user:acct_alice"
  id_token claims: email, name
  userinfo claims: email, name, tenant display facts
        |
        v
Lockspire
  signs ID token
  stores token and consent state
  answers userinfo
```

Lockspire does not import your account schema. Your resolver translates your
world into the few facts OAuth/OIDC needs.

## Protecting your Phoenix API

Issuing a token is only half the story. Your API must also verify incoming
tokens.

For Billingo's billing summary API, the route should accept only Lockspire-issued
tokens meant for that API and carrying the right scope.

```text
Partner app -> Billingo API
  Authorization: Bearer access_token

Billingo checks protocol facts:
  issuer is Billingo's Lockspire issuer
  token is signed and unexpired
  audience includes Billingo billing API
  scope includes read:billing
  sender constraint is valid when configured

Billingo still checks product facts:
  Alice can access this tenant
  requested billing object belongs to the tenant
  current plan and rate limits allow the action
```

Lockspire provides the token verification pipeline. Your API still owns business
authorization and response shaping.

## Revocation and introspection

Two more words show up once real integrations exist.

**Revocation** means a token or consent should stop being usable. A user might
disconnect an app. An operator might disable a compromised client. A refresh
token family might be revoked after reuse detection.

**Introspection** means a trusted caller asks the provider about a token's
current status.

```text
Revocation:
  "Stop this token or grant from working."

Introspection:
  "Is this token active, and what does it represent?"
```

Many Phoenix apps can validate Lockspire-issued JWT access tokens locally for
normal API requests. Introspection is still useful for support, gateways, or
confidential server-side checks where live token state matters.

## Public and confidential clients

Clients come in two practical shapes.

| Client type | Example | Secret handling |
| --- | --- | --- |
| Public client | Browser SPA, mobile app, CLI, device | Cannot safely keep a client secret |
| Confidential client | Backend web app, server-side partner integration | Can keep a secret or private key |

Public clients rely heavily on PKCE because they cannot keep a secret.

Confidential clients may authenticate to the token endpoint with a secret,
private-key JWT, mTLS, or another supported method. Lockspire stores client
secrets hashed at rest and shows plaintext only once when created.

## Operator and developer surfaces

There are usually three human surfaces around an OAuth provider:

| Surface | Audience | Owner |
| --- | --- | --- |
| Login and consent | End users | Your Phoenix app |
| Developer portal | Third-party developers or partners | Your Phoenix app |
| Operator admin | Internal staff managing clients, tokens, keys, and incidents | Lockspire UI behind your operator auth |

Lockspire includes operator workflows because OAuth/OIDC state is protocol state.
It does not include your developer portal because developer onboarding is tied to
your pricing, docs, API tiers, branding, review process, and product language.

In Billingo, the developer app page is Billingo-owned. The Lockspire admin is for
operators.

## Words you will meet later

You do not need to master every RFC before installing Lockspire. Use this table
as a map.

| Word | Plain meaning | Care when |
| --- | --- | --- |
| Authorization code | Short-lived handoff returned through the browser | Building the normal web/mobile flow |
| PKCE | Proof that protects the authorization code | Supporting public clients; Lockspire requires S256 by default |
| Redirect URI | Exact callback URL allowed for a client | Registering clients; exact matching prevents token theft |
| Scope | Named requested permission | Designing API access vocabulary |
| Consent grant | Stored approval for a client/user/scope set | Building authorized-apps and revoke UX |
| `state` | Client's callback correlation value | Defending the browser redirect round trip |
| `nonce` | OIDC request correlation value | Defending the ID token response |
| Grant type | The token-endpoint exchange being used | Reading token requests and client configuration |
| Discovery | Metadata document for provider endpoints | Giving partners one stable provider URL |
| JWKS | Public signing keys | Verifying signed tokens |
| Userinfo | OIDC endpoint for identity claims | Letting clients fetch profile facts after approval |
| Refresh rotation | Replace refresh tokens on use | Keeping long-lived integrations safer |
| PAR | Push authorization details before redirecting the browser | Hardening complex or high-security authorization requests |
| JAR | Put authorization request parameters into a signed request object | Clients need tamper-resistant request parameters |
| DCR | Dynamic client registration | Letting clients self-register under policy |
| Device Flow | Code-based approval for CLIs, TVs, terminals, and devices | The client has poor browser/input support |
| DPoP | Bind a token to a client-held key | Reducing value of stolen bearer tokens |
| mTLS | Bind clients or tokens to TLS certificates | High-trust server-to-server deployments |
| FAPI | Financial-grade security profiles | You need stricter security posture and predictable enforcement |
| RAR | Rich authorization request details | Scopes are too coarse for the thing being approved |
| Resource Indicator | The API audience a token is meant for | One authorization server issues tokens for multiple APIs |
| CIBA | Backchannel user approval | Approval starts away from the user's browser |
| JARM | Signed authorization responses | Clients need signed response integrity before token exchange |
| Token Exchange | Trade one token for a narrower downstream token | A gateway calls another service without forwarding the original token |

Start with authorization code + PKCE. Add the advanced pieces only when a real
client, risk, or compliance need pulls them in.

## How to evaluate Lockspire

Ask these questions in order:

1. Do third-party apps need to call my API for my users?
2. Does my Phoenix app already own accounts and login?
3. Do I want to keep that login UX, branding, tenant policy, and account model?
4. Do I need standard OAuth/OIDC endpoints instead of a custom API-token scheme?
5. Do I want secure defaults like PKCE S256, exact redirect matching, hashed
   secrets, single-use codes, refresh rotation, discovery, JWKS, userinfo,
   revocation, and introspection?

If those answers are yes, Lockspire fits the problem.

If the problem is "let users log in to my app with Google," that is inbound auth,
not Lockspire's job. Use your host auth library.

If the problem is "replace my whole identity product with hosted auth," that is a
different product category.

## Next path

1. Run the [Adoption Demo](adoption-demo.html) to see Billingo in a browser.
2. Read [Getting Started](getting-started.html) for the install shape.
3. Follow [Install And Onboard](install-and-onboard.html) when wiring a real app.
4. Use the [SaaS Adoption Recipe](saas-adoption-recipe.html) as the first-client
   checklist.
5. If your API will accept Lockspire-issued tokens, follow
   [Protect Phoenix API Routes](protect-phoenix-api-routes.html).
6. Use [Supported Surface](supported-surface.html) as the exact support contract
   for what Lockspire claims today.

The mental model stays the same through all of those docs:

```text
Your Phoenix app proves who the user is.
Lockspire turns that proof into OAuth/OIDC protocol artifacts.
Other software uses those artifacts to call your app safely.
Your app remains the authority for product policy.
```
