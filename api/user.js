const { sparkRequest } = require('./_lib/spark');
const { rowToPost } = require('./posts');

module.exports = async function handler(req, res) {
  const { username } = req.query;
  
  if (!username || typeof username !== 'string') {
    return res.status(400).json({ error: 'Username required' });
  }

  try {
    // Fetch user
    let userRows;
    try {
      userRows = await sparkRequest(`users?username=eq.${encodeURIComponent(username)}&select=id,username,created_at,avatar_url`);
    } catch (e) {
      // avatar_url migration (20260428000007) may not be applied yet
      userRows = await sparkRequest(`users?username=eq.${encodeURIComponent(username)}&select=id,username,created_at`);
    }
    if (!Array.isArray(userRows) || userRows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    const user = userRows[0];
    
    // Fetch user's posts
    const postRows = await sparkRequest(`posts?author_username=eq.${encodeURIComponent(username)}&select=*&order=created_at.desc`);
    const posts = Array.isArray(postRows) ? postRows.map(rowToPost) : [];
    
    // Calculate stats
    const totalUpvotes = posts.reduce((sum, p) => sum + (p.score || 0), 0);
    
    return res.status(200).json({
      user: {
        username: user.username,
        userId: user.id,
        joinedAt: user.created_at,
        postCount: posts.length,
        totalUpvotes,
        avatarUrl: user.avatar_url || null,
      },
      posts
    });
  } catch (err) {
    console.error('[USER] Fetch failed:', err.message);
    return res.status(500).json({ error: 'Failed to fetch user' });
  }
};
