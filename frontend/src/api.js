const API_URL = import.meta.env.VITE_API_URL ?? 'http://192.168.100.44:8081';

function authHeader(username, password) {
  return { 'Authorization': 'Basic ' + btoa((username ?? '') + ':' + (password ?? '')) };
}

export async function validateAuth(username, password) {
  const res = await fetch(`${API_URL}/api/usuarios`, { method: 'GET', headers: authHeader(username, password) });
  return res.ok;
}

export async function getUsuarios(username, password) {
  const res = await fetch(`${API_URL}/api/usuarios`, { headers: authHeader(username, password) });
  if (!res.ok) throw new Error('Erro ao buscar usuários');
  const data = await res.json();
  return Array.isArray(data.content) ? data.content : data;
}

export async function getUsuario(username, password, id) {
  const res = await fetch(`${API_URL}/api/usuarios/${id}`, { headers: authHeader(username, password) });
  if (!res.ok) throw new Error('Erro ao buscar usuário');
  return await res.json();
}

export async function createUsuario(username, password, payload) {
  const res = await fetch(`${API_URL}/api/usuarios`, {
    method: 'POST',
    headers: Object.assign({ 'Content-Type': 'application/json' }, authHeader(username, password)),
    body: JSON.stringify(payload),
  });
  if (!res.ok) throw new Error('Erro ao criar usuário');
  return await res.json();
}

export async function deleteUsuario(username, password, id) {
  const res = await fetch(`${API_URL}/api/usuarios/${id}`, {
    method: 'DELETE',
    headers: authHeader(username, password),
  });
  if (!res.ok) throw new Error('Erro ao deletar usuário');
  return true;
}

export default { validateAuth, getUsuarios, createUsuario, deleteUsuario };
