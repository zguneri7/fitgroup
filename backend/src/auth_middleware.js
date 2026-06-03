import jwt from 'jsonwebtoken';

export function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization ?? '';
  const [scheme, token] = authHeader.split(' ');

  if (scheme?.toLowerCase() != 'bearer' || !token) {
    return res.status(401).json({ message: 'missing bearer token' });
  }

  const secret = process.env.JWT_SECRET;
  if (!secret) {
    return res.status(500).json({ message: 'server auth is not configured' });
  }

  try {
    const payload = jwt.verify(token, secret);
    const userId = Number(payload.sub);

    if (!userId) {
      return res.status(401).json({ message: 'invalid token subject' });
    }

    req.auth = {
      userId,
      email: payload.email,
    };

    return next();
  } catch (_error) {
    return res.status(401).json({ message: 'invalid or expired token' });
  }
}
