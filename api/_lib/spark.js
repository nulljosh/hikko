// Storage for hikko: the spark-api Worker (D1 for rows, KV for files) at api.heyitsmejosh.com.
// Every call here is server to server, so it carries the service key and skips the per-user rules;
// the handlers in api/ check who the caller is before they get here.
function clean(val) {
  // Env values set with `echo` end in a literal backslash-n, which trim() does not strip.
  return (val || '').replace(/(?:\\[rn])+$/, '').trim();
}

function getSparkConfig() {
  return {
    url: clean(process.env.SPARK_API_URL) || 'https://api.heyitsmejosh.com',
    key: clean(process.env.SPARK_SERVICE_KEY)
  };
}

async function call(path, { method = 'GET', body, headers = {} } = {}) {
  const { url, key } = getSparkConfig();
  if (!key) throw new Error('spark_not_configured');
  const res = await fetch(`${url}${path}`, {
    method,
    headers: { 'x-service-key': key, ...headers },
    body
  });
  let data = null;
  try { data = await res.json(); } catch { data = null; }
  if (!res.ok) {
    const err = new Error((data && (data.error || data.message)) || `spark_http_${res.status}`);
    err.status = res.status;
    throw err;
  }
  return data;
}

// path is the PostgREST-style table path the handlers already use: `posts?id=eq.1&select=*`.
// The old useServiceRole option is accepted and ignored: every call is a service call now.
function sparkRequest(path, { method = 'GET', body } = {}) {
  return call(`/rest/${path}`, {
    method,
    headers: { 'Content-Type': 'application/json', Prefer: 'return=representation' },
    body: body ? JSON.stringify(body) : undefined
  });
}

function sparkRpc(fnName, params = {}) {
  return call(`/rpc/${fnName}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(params) });
}

// Upload bytes to a public bucket and return the public URL.
async function sparkStorageUpload(bucket, path, body, contentType) {
  const encoded = path.split('/').map(encodeURIComponent).join('/');
  const data = await call(`/storage/${bucket}/${encoded}`, { method: 'PUT', headers: { 'Content-Type': contentType }, body });
  return data.url;
}

module.exports = { getSparkConfig, sparkRequest, sparkRpc, sparkStorageUpload };
