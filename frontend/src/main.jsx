import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import {
    BrowserRouter,
    Route,
    Routes,
} from 'react-router-dom'
import App from './App.jsx'
import UserForm from './components/UserForm.jsx'
import './index.css'
import UserDetail from './pages/UserDetail.jsx'
import UsersList from './pages/UsersList.jsx'

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
