---
name: cloudfront-cookie-caching
description: How our application authentication and session management works, including rolling cookie-based sessions, and how our CloudFront CDN is configured to cache static assets while keeping authenticated API traffic uncached. Relevant for changes to CloudFront distributions, cache behaviors, cache policies, origin request policies, or any infrastructure sitting between users and our application servers.
---

# Application Authentication & CDN Architecture

## How Our Sessions Work

We use cookie-based rolling sessions for authentication. When a user logs in they receive a session cookie. Every time the application sees a valid session cookie on any request, it extends the session expiry and sends back an updated `Set-Cookie` header. This keeps users logged in as long as they're actively using the product.

Importantly, the session extension happens on **every route the application serves**, not just API endpoints. If a request hits the application server and includes a session cookie, the response will include a `Set-Cookie` header — even if the request is for a JavaScript file or a CSS stylesheet. The application doesn't distinguish between "needs auth" and "doesn't need auth" at the session layer; the session middleware runs on all routes.

## CDN Architecture

We use AWS CloudFront in front of our application. The CloudFront distribution has different cache behaviors for different types of traffic:

- **API routes** (`/api/*`): Not cached. All cookies and headers are forwarded to the origin so that authentication and request-specific logic works correctly.
- **Static assets** (JS, CSS): Cached with a short TTL. Cookies are **not** forwarded to the origin for these routes. This is important because of how our session middleware works — if the application server receives a cookie on a static asset request, it will return a `Set-Cookie` header in the response, which we do not want cached and served to other users.
- **Default behavior**: Uncached, all traffic forwarded to the origin.

## Why Static Assets Don't Forward Cookies

The static asset cache behavior is deliberately configured to not forward cookies to the origin. This serves two purposes:

1. **Performance**: Without cookies in the request, static assets can be efficiently cached and shared across all users.
2. **Security**: Because our application returns `Set-Cookie` on any request that includes a session cookie, forwarding cookies on cached routes would mean one user's session cookie could end up in a cached response and be served to another user.

If you're working on CloudFront configuration, be aware that the caching behavior for static assets depends on cookies NOT reaching the application server. Any change that causes cookies to be forwarded to the origin on cached routes could have security implications.
