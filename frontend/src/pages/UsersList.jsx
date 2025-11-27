import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { deleteUsuario, getUsuarios } from '../api.js'

export default function UsersList() {
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  // For now use default credentials; integrate with real auth later
  const username = 'admin'
  const password = '123456'

  const load = async () => {
    setLoading(true)
    setError('')
    try {
      const data = await getUsuarios(username, password)
      setUsers(data)
    } catch (err) {
      setError('Erro ao carregar usuários')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { load() }, [])

  const handleDelete = async (id) => {
    if (!window.confirm('Deseja deletar este usuário?')) return
    try {
      await deleteUsuario(username, password, id)
      load()
    } catch (err) {
      alert('Erro ao deletar usuário')
    }
  }

  return (
    <div style={{ maxWidth: 900, margin: '2rem auto', padding: 16 }}>
      <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <h2>Usuários</h2>
        <div>
          <Link to="/usuarios/new" style={{ marginRight: 12 }}>Novo usuário</Link>
          <Link to="/">Dashboard</Link>
        </div>
      </header>

      {loading && <div>Carregando...</div>}
      {error && <div style={{ color: 'red' }}>{error}</div>}

      <table style={{ width: '100%', borderCollapse: 'collapse', marginTop: 12 }}>
        <thead>
          <tr>
            <th style={{ textAlign: 'left', padding: 8 }}>ID</th>
            <th style={{ textAlign: 'left', padding: 8 }}>Nome</th>
            <th style={{ textAlign: 'left', padding: 8 }}>Ações</th>
          </tr>
        </thead>
        <tbody>
          {users && users.length > 0 ? users.map(u => (
            <tr key={u.id}>
              <td style={{ padding: 8 }}>{u.id}</td>
              <td style={{ padding: 8 }}>{u.nome}</td>
              <td style={{ padding: 8 }}>
                <Link to={`/usuarios/${u.id}`} style={{ marginRight: 8 }}>Detalhes</Link>
                <button onClick={() => handleDelete(u.id)} style={{ background: '#d33', color: '#fff', border: 'none', padding: '6px 10px', borderRadius: 6 }}>Deletar</button>
              </td>
            </tr>
          )) : (
            <tr><td colSpan={3} style={{ padding: 8 }}>Nenhum usuário encontrado.</td></tr>
          )}
        </tbody>
      </table>
    </div>
  )
}
