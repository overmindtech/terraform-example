// Simulates Loom's rolling session behavior:
// - Serves a static JS file
// - If a session cookie is present, extends its expiry and returns Set-Cookie
// - If no session cookie, just returns the JS content without Set-Cookie
//
// This is the application behavior that turns the CloudFront CDN
// misconfiguration into a session hijacking vulnerability.

exports.handler = async (event) => {
  const cookies = event.headers?.cookie || "";
  const sessionMatch = cookies.match(/session=([^;]+)/);

  const headers = {
    "content-type": "application/javascript",
    "cache-control": "public, max-age=1",
  };

  if (sessionMatch) {
    const sessionValue = sessionMatch[1];
    const expires = new Date(Date.now() + 86400000).toUTCString();
    headers["set-cookie"] = `session=${sessionValue}; Path=/; Expires=${expires}; HttpOnly`;
  }

  return {
    statusCode: 200,
    headers: headers,
    body: `// Static JS asset - served at ${new Date().toISOString()}\nconsole.log("hello from the origin");`,
  };
};
