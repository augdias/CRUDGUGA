import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { createUsuario } from '../api.js'

export default function UserForm() {
  const [nome, setNome] = useState('')
  const [email, setEmail] = useState('')
  const [senha, setSenha] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const navigate = useNavigate()

  const username = 'admin'
  const password = '123456'

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    if (!nome) { setError('Nome é obrigatório'); return }
    setLoading(true)
    try {
      await createUsuario(username, password, { nome, email, senha })
      navigate('/usuarios')
    } catch (err) {
      setError('Erro ao criar usuário')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div style={{ maxWidth: 640, margin: '2rem auto', padding: 16 }}>
      <h3>Novo Usuário</h3>
      <form onSubmit={handleSubmit} style={{ display: 'grid', gap: 8 }}>
        <input value={nome} onChange={e => setNome(e.target.value)} placeholder="Nome" />
        <input value={email} onChange={e => setEmail(e.target.value)} placeholder="E-mail" />
        <input value={senha} onChange={e => setSenha(e.target.value)} placeholder="Senha" type="password" />
        {error && <div style={{ color: 'red' }}>{error}</div>}
        <div>
          <button type="submit" disabled={loading} style={{ padding: '0.6rem 1rem' }}>{loading ? 'Salvando...' : 'Salvar'}</button>
        </div>
      </form>
    </div>
  )
}
