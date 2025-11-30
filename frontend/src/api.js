const API_URL = import.meta.env.VITE_API_URL ?? 'http://127.0.0.1:8081'
const API_USER = import.meta.env.VITE_API_USER ?? 'admin'
const API_PASS = import.meta.env.VITE_API_PASS ?? '123456'

function authHeader(user = API_USER, pass = API_PASS) {
  return { 'Authorization': 'Basic ' + btoa((user ?? '') + ':' + (pass ?? '')) }
}

async function request(method, path, body = null, user = API_USER, pass = API_PASS) {
  const headers = Object.assign({}, authHeader(user, pass))
  if (body !== null) headers['Content-Type'] = 'application/json'
  const res = await fetch(`${API_URL}/api${path}`, {
    method,
    headers,
    body: body !== null ? JSON.stringify(body) : undefined,
  })
  return res
}

export async function validateAuth(user, pass) {
  const res = await request('GET', '/usuarios', null, user, pass)
  return res.ok
}

export async function get(path, user = API_USER, pass = API_PASS) { return request('GET', path, null, user, pass) }
export async function post(path, payload, user = API_USER, pass = API_PASS) { return request('POST', path, payload, user, pass) }
export async function put(path, payload, user = API_USER, pass = API_PASS) { return request('PUT', path, payload, user, pass) }
export async function del(path, user = API_USER, pass = API_PASS) { return request('DELETE', path, null, user, pass) }

// convenience functions
export async function getUsuarios(user, pass) {
  const res = await get('/usuarios', user, pass)
  if (!res.ok) throw new Error('Erro ao buscar usuários')
  const data = await res.json()
  return Array.isArray(data.content) ? data.content : data
}

export async function getUsuario(user, pass, id) {
  const res = await get(`/usuarios/${id}`, user, pass)
  if (!res.ok) throw new Error('Erro ao buscar usuário')
  return await res.json()
}

export async function createUsuario(user, pass, payload) {
  const res = await post('/usuarios', payload, user, pass)
  if (!res.ok) throw new Error('Erro ao criar usuário')
  return await res.json()
}

export async function updateUsuario(user, pass, id, payload) {
  const res = await put(`/usuarios/${id}`, payload, user, pass)
  if (!res.ok) throw new Error('Erro ao atualizar usuário')
  return await res.json()
}

export async function deleteUsuario(user, pass, id) {
  const res = await del(`/usuarios/${id}`, user, pass)
  if (!res.ok) throw new Error('Erro ao deletar usuário')
  return true
}

export default { validateAuth, getUsuarios, getUsuario, createUsuario, updateUsuario, deleteUsuario, get, post, put, del }
