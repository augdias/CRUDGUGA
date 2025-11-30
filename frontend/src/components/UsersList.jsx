import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import api from '../api'

export default function UsersList() {
  const [users, setUsers] = useState([])
  const [page, setPage] = useState(0)
  const [size] = useState(10)

  useEffect(() => {
    fetchPage()
  }, [page])

  async function fetchPage() {
    try {
      const res = await api.get(`/usuarios?page=${page}&size=${size}`)
      const data = await res.json()
      setUsers(data.content || data)
    } catch (e) {
      console.error(e)
      setUsers([])
    }
  }

  return (
    <div>
      <h2>Usuários</h2>
      <div style={{ marginBottom: 12 }}>
        <Link to="/usuarios/new">Novo usuário</Link>
      </div>
      <table style={{ width: '100%', borderCollapse: 'collapse' }}>
        <thead>
          <tr>
            <th style={{ textAlign: 'left' }}>ID</th>
            <th style={{ textAlign: 'left' }}>Nome</th>
            <th style={{ textAlign: 'left' }}>Ações</th>
          </tr>
        </thead>
        <tbody>
          {users.map(u => (
            <tr key={u.id}>
              <td>{u.id}</td>
              <td>{u.nome}</td>
              <td>
                <Link to={`/usuarios/${u.id}`}>Ver</Link>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      <div style={{ marginTop: 12 }}>
        <button onClick={() => setPage(p => Math.max(0, p - 1))}>Anterior</button>
        <span style={{ margin: '0 8px' }}>Página {page + 1}</span>
        <button onClick={() => setPage(p => p + 1)}>Próxima</button>
      </div>
    </div>
  )
}
