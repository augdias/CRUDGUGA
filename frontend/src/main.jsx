import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter, Route, Routes } from 'react-router-dom'
import App from './App.jsx'
import UserDetail from './components/UserDetail.jsx'
import UserForm from './components/UserForm.jsx'
import UsersList from './components/UsersList.jsx'
import './index.css'

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <BrowserRouter>
      <Routes>
        <Route path='/' element={<App />} />
        <Route path='/usuarios' element={<UsersList />} />
        <Route path='/usuarios/new' element={<UserForm />} />
        <Route path='/usuarios/:id' element={<UserDetail />} />
        <Route path='/usuarios/:id/edit' element={<UserForm />} />
      </Routes>
    </BrowserRouter>
  </StrictMode>,
)

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <BrowserRouter>
      <Routes>
        <Route path='/' element={<App />} />
        <Route path='/usuarios' element={<UsersList />} />
        <Route path='/usuarios/new' element={<UserForm />} />
        <Route path='/usuarios/:id' element={<UserDetail />} />
      </Routes>
    </BrowserRouter>
  </StrictMode>,
)
