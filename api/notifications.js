const { parseToken } = require('./posts');
const { sparkRequest } = require('./_lib/spark');

async function createNotification({ type, postId, postTitle, actorUsername, targetUserId }) {
  if (!targetUserId) return null;
  try {
    const notif = {
      id: 'notif-' + Date.now() + '-' + Math.random().toString(36).slice(2, 8),
      type,
      post_id: postId,
      post_title: postTitle,
      actor_username: actorUsername,
      target_user_id: targetUserId,
      read: false,
      created_at: new Date().toISOString()
    };
    const rows = await sparkRequest('notifications', {
      method: 'POST',
      body: notif
    });
    return Array.isArray(rows) ? rows[0] : rows;
  } catch {
    return null;
  }
}

async function getNotifications(userId) {
  try {
    const rows = await sparkRequest(
      `notifications?target_user_id=eq.${encodeURIComponent(userId)}&select=*&order=created_at.desc&limit=50`
    );
    return Array.isArray(rows) ? rows : [];
  } catch {
    return [];
  }
}

async function markRead(notifId, userId) {
  try {
    await sparkRequest(
      `notifications?id=eq.${encodeURIComponent(notifId)}&target_user_id=eq.${encodeURIComponent(userId)}`,
      { method: 'PATCH', body: { read: true } }
    );
    return true;
  } catch {
    return false;
  }
}

async function markAllRead(userId) {
  try {
    await sparkRequest(
      `notifications?target_user_id=eq.${encodeURIComponent(userId)}&read=eq.false`,
      { method: 'PATCH', body: { read: true } }
    );
    return true;
  } catch {
    return false;
  }
}

module.exports = async function handler(req, res) {
  const user = parseToken(req.headers.authorization, req.headers.cookie);
  if (!user) return res.status(401).json({ error: 'Authentication required' });

  if (req.method === 'GET') {
    const notifications = await getNotifications(user.userId);
    return res.status(200).json({ notifications });
  }

  if (req.method === 'PATCH') {
    const { id, markAll } = req.body || {};
    if (markAll) {
      await markAllRead(user.userId);
    } else if (id) {
      await markRead(id, user.userId);
    }
    return res.status(200).json({ ok: true });
  }

  return res.status(405).json({ error: 'Method not allowed' });
};

module.exports.createNotification = createNotification;
