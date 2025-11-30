import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import api, { createUsuario } from '../api'

export default function UserForm() {
  const { id } = useParams()
  const isNew = id === 'new' || !id
  const [nome, setNome] = useState('')
  const [email, setEmail] = useState('')
  const [senha, setSenha] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const navigate = useNavigate()

  useEffect(() => {
    if (!isNew) load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id])

  async function load() {
    try {
      const res = await api.get(`/usuarios/${id}`)
      if (res.ok) {
        const data = await res.json()
        setNome(data.nome || '')
        setEmail(data.email || '')
      }
    } catch (e) { console.error(e) }
  }

  async function handleSubmit(e) {
    e.preventDefault()
    setError('')
    if (!nome) { setError('Nome é obrigatório'); return }
    setLoading(true)
    try {
      if (isNew) {
        await createUsuario('admin', '123456', { nome, email, senha })
      } else {
        const payload = { nome }
        await api.put(`/usuarios/${id}`, payload)
      }
      navigate('/usuarios')
    } catch (err) {
      console.error(err)
      setError('Erro ao salvar usuário')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div style={{ maxWidth: 640, margin: '2rem auto', padding: 16 }}>
      <h3>{isNew ? 'Novo Usuário' : `Editar Usuário ${id}`}</h3>
      <form onSubmit={handleSubmit} style={{ display: 'grid', gap: 8 }}>
        <input value={nome} onChange={e => setNome(e.target.value)} placeholder="Nome" required />
        {isNew && <input value={email} onChange={e => setEmail(e.target.value)} placeholder="E-mail" />}
        {isNew && <input value={senha} onChange={e => setSenha(e.target.value)} placeholder="Senha" type="password" />}
        {error && <div style={{ color: 'red' }}>{error}</div>}
        <div>
          <button type="submit" disabled={loading} style={{ padding: '0.6rem 1rem' }}>{loading ? 'Salvando...' : 'Salvar'}</button>
        </div>
      </form>
    </div>
  )
}
