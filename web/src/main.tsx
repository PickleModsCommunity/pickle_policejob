import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'
import { ConfigProvider } from './providers/config.tsx'
import { PlayerProvider } from './providers/player/player.tsx'

createRoot(document.getElementById('root')!).render(
    <ConfigProvider>
      <PlayerProvider>
        <App />
      </PlayerProvider>
    </ConfigProvider>
  ,
)
