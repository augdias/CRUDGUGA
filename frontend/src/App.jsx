import { useEffect, useState } from 'react';
import { createUsuario, deleteUsuario, getUsuarios, validateAuth } from './api.js';

function App() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [isLogged, setIsLogged] = useState(false);
  const [users, setUsers] = useState([]);
  const [fetchingUsers, setFetchingUsers] = useState(false);
  const [fetchError, setFetchError] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [formNome, setFormNome] = useState('');
  const [formEmail, setFormEmail] = useState('');
  const [formSenha, setFormSenha] = useState('');
  const [formError, setFormError] = useState('');
  const [formLoading, setFormLoading] = useState(false);

  const fetchUsers = async () => {
    setFetchingUsers(true);
    setFetchError('');
    try {
      const data = await getUsuarios(username, password);
      setUsers(data);
    } catch (err) {
      setFetchError('Erro ao buscar usuários.');
    } finally {
      setFetchingUsers(false);
    }
  };

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      const ok = await validateAuth(username, password);
      if (ok) setIsLogged(true);
      else setError('Usuário ou senha inválidos.');
    } catch (err) {
      setError('Erro de conexão com o backend.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (isLogged) {
      fetchUsers();
    }
    // eslint-disable-next-line
  }, [isLogged, username, password]);

  const handleAddUser = async (e) => {
    e.preventDefault();
    setFormError('');
    setFormLoading(true);
    if (!formNome || !formEmail || !formSenha) {
      setFormError('Preencha todos os campos.');
      setFormLoading(false);
      return;
    }
    try {
      await createUsuario(username, password, { nome: formNome, email: formEmail, senha: formSenha });
      setShowForm(false);
      setFormNome(''); setFormEmail(''); setFormSenha('');
      fetchUsers();
    } catch {
      setFormError('Erro ao cadastrar usuário.');
    } finally {
      setFormLoading(false);
    }
  };

  const handleDeleteUser = async (id) => {
    if (!window.confirm('Deseja realmente deletar este usuário?')) return;
    try {
      await deleteUsuario(username, password, id);
      fetchUsers();
    } catch {
      alert('Erro ao deletar usuário.');
    }
  };

  if (isLogged) {
    return (
      <div style={{ maxWidth: 480, margin: '3rem auto', background: 'var(--bg-card)', borderRadius: 12, padding: 24, boxShadow: '0 2px 16px #0004' }}>
        <h2 style={{ marginBottom: 16 }}>Dashboard</h2>
        <p>Bem-vindo, <b>{username}</b>.</p>
        <button style={{ margin: '16px 0 24px 0' }} onClick={() => setIsLogged(false)}>Sair</button>

        <button
          style={{ marginBottom: 18, background: 'var(--primary)', color: '#fff', border: 'none', borderRadius: 8, padding: '0.7rem 1.2rem', fontWeight: 600, cursor: 'pointer' }}
          onClick={() => setShowForm(v => !v)}
        >
          {showForm ? 'Cancelar' : 'Novo Usuário'}
        </button>

        {showForm && (
          <form onSubmit={handleAddUser} style={{ background: 'var(--bg-main)', borderRadius: 8, padding: 16, marginBottom: 18 }}>
            <h4 style={{ margin: '0 0 12px 0' }}>Cadastrar Usuário</h4>
            <input
              type="text"
              placeholder="Nome"
              value={formNome}
              onChange={e => setFormNome(e.target.value)}
              style={{ width: '100%', marginBottom: 8, padding: 8, borderRadius: 6, border: '1px solid var(--border)', background: 'var(--bg-card)', color: 'var(--text-main)' }}
            />
            <input
              type="email"
              placeholder="E-mail"
              value={formEmail}
              onChange={e => setFormEmail(e.target.value)}
              style={{ width: '100%', marginBottom: 8, padding: 8, borderRadius: 6, border: '1px solid var(--border)', background: 'var(--bg-card)', color: 'var(--text-main)' }}
            />
            <input
              type="password"
              placeholder="Senha"
              value={formSenha}
              onChange={e => setFormSenha(e.target.value)}
              style={{ width: '100%', marginBottom: 8, padding: 8, borderRadius: 6, border: '1px solid var(--border)', background: 'var(--bg-card)', color: 'var(--text-main)' }}
            />
            {formError && <div style={{ color: 'var(--error)', marginBottom: 8 }}>{formError}</div>}
            <button type="submit" disabled={formLoading} style={{ background: 'var(--primary)', color: '#fff', border: 'none', borderRadius: 6, padding: '0.7rem 1.2rem', fontWeight: 600, cursor: formLoading ? 'not-allowed' : 'pointer', opacity: formLoading ? 0.7 : 1 }}>
              {formLoading ? 'Salvando...' : 'Salvar'}
            </button>
          </form>
        )}

        <h3 style={{ margin: '16px 0 8px 0' }}>Usuários</h3>
        {fetchingUsers && <div>Carregando usuários...</div>}
        {fetchError && <div style={{ color: 'var(--error)' }}>{fetchError}</div>}
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', background: 'var(--bg-main)' }}>
            <thead>
              <tr style={{ color: 'var(--text-muted)' }}>
                <th style={{ textAlign: 'left', padding: 8, borderBottom: '1px solid var(--border)' }}>ID</th>
                <th style={{ textAlign: 'left', padding: 8, borderBottom: '1px solid var(--border)' }}>Nome</th>
                <th style={{ textAlign: 'left', padding: 8, borderBottom: '1px solid var(--border)' }}>E-mail</th>
                <th style={{ textAlign: 'left', padding: 8, borderBottom: '1px solid var(--border)' }}>Ações</th>
              </tr>
            </thead>
            <tbody>
              {users && users.length > 0 ? (
                users.map((u) => (
                  <tr key={u.id}>
                    <td style={{ padding: 8, borderBottom: '1px solid var(--border)' }}>{u.id}</td>
                    <td style={{ padding: 8, borderBottom: '1px solid var(--border)' }}>{u.nome || u.name}</td>
                    <td style={{ padding: 8, borderBottom: '1px solid var(--border)' }}>{u.email}</td>
                    <td style={{ padding: 8, borderBottom: '1px solid var(--border)' }}>
                      <button onClick={() => handleDeleteUser(u.id)} style={{ background: 'var(--error)', color: '#fff', border: 'none', borderRadius: 6, padding: '0.4rem 0.8rem', fontWeight: 600, cursor: 'pointer' }}>Deletar</button>
                    </td>
                  </tr>
                ))
              ) : (
                <tr><td colSpan={4} style={{ padding: 8, color: 'var(--text-muted)' }}>Nenhum usuário encontrado.</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    );
  }

  return (
    <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <form onSubmit={handleLogin} style={{ background: 'var(--bg-card)', borderRadius: 12, padding: 32, boxShadow: '0 2px 16px #0004', width: '100%', maxWidth: 360 }}>
        <h2 style={{ marginBottom: 24, textAlign: 'center' }}>Login</h2>
        <label htmlFor="username">Usuário</label>
        <input
          id="username"
          type="text"
          value={username}
          onChange={e => setUsername(e.target.value)}
          style={{
            width: '100%',
            padding: '0.7rem',
            margin: '8px 0 18px 0',
            borderRadius: 8,
            border: '1px solid var(--border)',
            background: 'var(--bg-main)',
            color: 'var(--text-main)'
          }}
          autoFocus
        />
        <label htmlFor="password">Senha</label>
        <input
          id="password"
          type="password"
          value={password}
          onChange={e => setPassword(e.target.value)}
          style={{
            width: '100%',
            padding: '0.7rem',
            margin: '8px 0 18px 0',
            borderRadius: 8,
            border: '1px solid var(--border)',
            background: 'var(--bg-main)',
            color: 'var(--text-main)'
          }}
        />
        {error && <div style={{ color: 'var(--error)', marginBottom: 12 }}>{error}</div>}
        <button
          type="submit"
          style={{
            width: '100%',
            padding: '0.9rem',
            borderRadius: 8,
            border: 'none',
            background: 'var(--primary)',
            color: '#fff',
            fontWeight: 600,
            fontSize: '1.1rem',
            marginTop: 8,
            cursor: loading ? 'not-allowed' : 'pointer',
            opacity: loading ? 0.7 : 1
          }}
          disabled={loading}
        >
          {loading ? 'Entrando...' : 'Entrar'}
        </button>
      </form>
    </div>
  );
}

export default App;
