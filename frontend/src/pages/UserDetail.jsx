import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { getUsuario } from '../api.js'

export default function UserDetail() {
  const { id } = useParams()
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  // default credentials for now
  const username = 'admin'
  const password = '123456'

  useEffect(() => {
    const load = async () => {
      setLoading(true)
      setError('')
      try {
        const data = await getUsuario(username, password, id)
        setUser(data)
      } catch (err) {
        setError('Erro ao carregar usuário')
      } finally {
        setLoading(false)
      }
    }
    load()
  }, [id])

  if (loading) return <div style={{ padding: 16 }}>Carregando...</div>
  if (error) return <div style={{ padding: 16, color: 'red' }}>{error}</div>
  if (!user) return <div style={{ padding: 16 }}>Usuário não encontrado.</div>

  return (
    <div style={{ maxWidth: 720, margin: '2rem auto', padding: 16 }}>
      <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <h2>Usuário: {user.nome}</h2>
        <div>
          <Link to="/usuarios" style={{ marginRight: 12 }}>Voltar</Link>
        </div>
      </header>

      <div style={{ background: 'var(--bg-card)', padding: 16, borderRadius: 8 }}>
        <p><strong>ID:</strong> {user.id}</p>
        <p><strong>Nome:</strong> {user.nome}</p>
        <p><strong>E-mail:</strong> {user.email || '-'}</p>
      </div>
    </div>
  )
}
