import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import api from '../api'

export default function UserDetail() {
  const { id } = useParams()
  const [user, setUser] = useState(null)
  const navigate = useNavigate()

  useEffect(() => {
    fetchUser()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id])

  async function fetchUser() {
    try {
      const res = await api.get(`/usuarios/${id}`)
      if (res.ok) setUser(await res.json())
      else setUser(null)
    } catch (e) {
      console.error(e)
      setUser(null)
    }
  }

  async function handleDelete() {
    if (!confirm('Confirmar exclusão?')) return
    try {
      const res = await api.delete(`/usuarios/${id}`)
      if (res.ok) navigate('/usuarios')
      else alert('Falha ao excluir')
    } catch (e) {
      console.error(e)
      alert('Erro')
    }
  }

  if (!user) return <div>Carregando...</div>

  return (
    <div>
      <h2>Usuário {user.id}</h2>
      <div><strong>Nome:</strong> {user.nome}</div>
      <div style={{ marginTop: 12 }}>
        <Link to={`/usuarios/${user.id}/edit`}>Editar</Link>
        <button style={{ marginLeft: 8 }} onClick={handleDelete}>Excluir</button>
        <button style={{ marginLeft: 8 }} onClick={() => navigate('/usuarios')}>Voltar</button>
      </div>
    </div>
  )
}
