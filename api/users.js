const { sparkRequest } = require('./_lib/spark');

module.exports = async function handler(req, res) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const rows = await sparkRequest('users?select=id,username,created_at&order=created_at.desc');
    
    if (!Array.isArray(rows)) {
      return res.status(200).json({ users: [] });
    }
    
    const users = rows.map(u => ({
      userId: u.id,
      username: u.username,
      joinedAt: u.created_at
    }));
    
    return res.status(200).json({ users, count: users.length });
  } catch (err) {
    console.error('[USERS] Fetch failed:', err.message);
    return res.status(500).json({ error: 'Failed to fetch users' });
  }
};
