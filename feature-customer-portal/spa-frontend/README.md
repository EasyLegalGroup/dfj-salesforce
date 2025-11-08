# Customer Portal SPA Frontend

## 📋 Overview

The Customer Portal frontend is a Single Page Application (SPA) that provides Din Familiejurist clients with a secure, user-friendly interface to:
- View their legal journal/case information
- Communicate with legal advisors via chat
- Upload, view, and approve documents
- Track case progress and status

## 🎨 Technology Stack

**Recommended Stack:**
- **Framework**: React 18+ or Vue.js 3+
- **Build Tool**: Vite (fast development & production builds)
- **State Management**: Redux Toolkit (React) or Pinia (Vue)
- **HTTP Client**: Axios or Fetch API
- **UI Library**: Material-UI, Ant Design, or Tailwind CSS
- **Real-time**: WebSocket or Server-Sent Events for chat
- **Authentication**: JWT tokens from Salesforce via API Gateway
- **Deployment**: AWS S3 + CloudFront

## 📁 Project Structure

```
spa-frontend/
├── public/                      # Static assets
│   ├── index.html              # HTML entry point
│   ├── favicon.ico
│   └── assets/
│       ├── images/
│       └── icons/
│
├── src/
│   ├── components/             # Reusable UI components
│   │   ├── common/
│   │   │   ├── Button.jsx
│   │   │   ├── Modal.jsx
│   │   │   └── Loading.jsx
│   │   ├── chat/
│   │   │   ├── ChatWindow.jsx
│   │   │   ├── MessageList.jsx
│   │   │   └── MessageInput.jsx
│   │   ├── documents/
│   │   │   ├── DocumentList.jsx
│   │   │   ├── DocumentViewer.jsx
│   │   │   └── DocumentUpload.jsx
│   │   └── journal/
│   │       ├── JournalHeader.jsx
│   │       ├── JournalDetails.jsx
│   │       └── JournalTimeline.jsx
│   │
│   ├── pages/                  # Page components (routes)
│   │   ├── Login.jsx
│   │   ├── Dashboard.jsx
│   │   ├── JournalDetail.jsx
│   │   ├── Documents.jsx
│   │   └── Chat.jsx
│   │
│   ├── services/               # API service layer
│   │   ├── api.js              # Base API client
│   │   ├── authService.js      # Authentication
│   │   ├── journalService.js   # Journal operations
│   │   ├── chatService.js      # Chat operations
│   │   └── documentService.js  # Document operations
│   │
│   ├── store/                  # State management
│   │   ├── index.js            # Store configuration
│   │   ├── slices/
│   │   │   ├── authSlice.js
│   │   │   ├── journalSlice.js
│   │   │   ├── chatSlice.js
│   │   │   └── documentSlice.js
│   │
│   ├── utils/                  # Utility functions
│   │   ├── formatters.js       # Date, currency, text formatters
│   │   ├── validators.js       # Form validation
│   │   └── constants.js        # App constants
│   │
│   ├── hooks/                  # Custom React hooks
│   │   ├── useAuth.js
│   │   ├── useChat.js
│   │   └── useDocuments.js
│   │
│   ├── styles/                 # Global styles
│   │   ├── globals.css
│   │   ├── variables.css
│   │   └── themes/
│   │
│   ├── App.jsx                 # Root component
│   ├── main.jsx                # Entry point
│   └── routes.jsx              # Route definitions
│
├── dist/                       # Build output (gitignored)
├── .env.development            # Dev environment variables
├── .env.production             # Production environment variables
├── package.json                # Dependencies
├── vite.config.js              # Vite configuration
├── .eslintrc.js                # ESLint configuration
├── .prettierrc                 # Prettier configuration
└── README.md                   # This file
```

## 🚀 Getting Started

### Prerequisites

```bash
# Node.js 18+ and npm
node --version
npm --version
```

### Installation

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

### Environment Variables

Create `.env.development` and `.env.production` files:

```env
# .env.development
VITE_API_BASE_URL=https://dev-api.customer-portal.dinfamiliejurist.dk
VITE_WS_URL=wss://dev-api.customer-portal.dinfamiliejurist.dk/ws
VITE_ENV=development

# .env.production
VITE_API_BASE_URL=https://api.customer-portal.dinfamiliejurist.dk
VITE_WS_URL=wss://api.customer-portal.dinfamiliejurist.dk/ws
VITE_ENV=production
```

## 🔐 Authentication Flow

```javascript
// src/services/authService.js

import api from './api';

export const authService = {
  /**
   * Validate access token from URL parameter
   * @param {string} token - Journal access token
   * @returns {Promise} User session data
   */
  async validateToken(token) {
    const response = await api.post('/api/v1/auth/validate-token', { token });
    
    if (response.data.valid) {
      // Store session token
      localStorage.setItem('sessionToken', response.data.sessionToken);
      localStorage.setItem('journalId', response.data.journalId);
      
      return response.data;
    }
    
    throw new Error('Invalid or expired token');
  },
  
  /**
   * Check if user is authenticated
   * @returns {boolean}
   */
  isAuthenticated() {
    const sessionToken = localStorage.getItem('sessionToken');
    return !!sessionToken;
  },
  
  /**
   * Logout user
   */
  logout() {
    localStorage.removeItem('sessionToken');
    localStorage.removeItem('journalId');
  }
};
```

## 📡 API Service Examples

### Journal Service

```javascript
// src/services/journalService.js

import api from './api';

export const journalService = {
  /**
   * Get journal details
   * @param {string} journalId
   */
  async getJournal(journalId) {
    const response = await api.get(`/api/v1/journals/${journalId}`);
    return response.data;
  },
  
  /**
   * Get journal timeline/activity
   * @param {string} journalId
   */
  async getTimeline(journalId) {
    const response = await api.get(`/api/v1/journals/${journalId}/timeline`);
    return response.data;
  }
};
```

### Chat Service

```javascript
// src/services/chatService.js

import api from './api';

export const chatService = {
  /**
   * Get chat messages for a journal
   * @param {string} journalId
   */
  async getMessages(journalId) {
    const response = await api.get(`/api/v1/journals/${journalId}/messages`);
    return response.data;
  },
  
  /**
   * Send a chat message
   * @param {string} journalId
   * @param {string} message
   */
  async sendMessage(journalId, message) {
    const response = await api.post(`/api/v1/journals/${journalId}/messages`, {
      body: message,
      isInbound: true
    });
    return response.data;
  },
  
  /**
   * Setup WebSocket for real-time messages
   * @param {string} journalId
   * @param {function} onMessage - Callback for new messages
   */
  setupWebSocket(journalId, onMessage) {
    const ws = new WebSocket(
      `${import.meta.env.VITE_WS_URL}/journals/${journalId}/messages`
    );
    
    ws.onmessage = (event) => {
      const message = JSON.parse(event.data);
      onMessage(message);
    };
    
    return ws;
  }
};
```

### Document Service

```javascript
// src/services/documentService.js

import api from './api';

export const documentService = {
  /**
   * Get documents for a journal
   * @param {string} journalId
   */
  async getDocuments(journalId) {
    const response = await api.get(`/api/v1/journals/${journalId}/documents`);
    return response.data;
  },
  
  /**
   * Upload a document
   * @param {string} journalId
   * @param {File} file
   */
  async uploadDocument(journalId, file) {
    const formData = new FormData();
    formData.append('file', file);
    
    const response = await api.post(
      `/api/v1/journals/${journalId}/documents`,
      formData,
      {
        headers: { 'Content-Type': 'multipart/form-data' }
      }
    );
    
    return response.data;
  },
  
  /**
   * Download a document
   * @param {string} documentId
   */
  async downloadDocument(documentId) {
    const response = await api.get(`/api/v1/documents/${documentId}`, {
      responseType: 'blob'
    });
    
    // Create download link
    const url = window.URL.createObjectURL(new Blob([response.data]));
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', `document-${documentId}.pdf`);
    document.body.appendChild(link);
    link.click();
    link.remove();
  }
};
```

## 🎨 Component Examples

### Chat Window Component

```jsx
// src/components/chat/ChatWindow.jsx

import { useState, useEffect, useRef } from 'react';
import { chatService } from '../../services/chatService';

export const ChatWindow = ({ journalId }) => {
  const [messages, setMessages] = useState([]);
  const [newMessage, setNewMessage] = useState('');
  const [loading, setLoading] = useState(true);
  const wsRef = useRef(null);

  useEffect(() => {
    // Load initial messages
    loadMessages();
    
    // Setup WebSocket for real-time updates
    wsRef.current = chatService.setupWebSocket(journalId, (message) => {
      setMessages(prev => [...prev, message]);
    });
    
    return () => {
      if (wsRef.current) {
        wsRef.current.close();
      }
    };
  }, [journalId]);

  const loadMessages = async () => {
    try {
      setLoading(true);
      const data = await chatService.getMessages(journalId);
      setMessages(data);
    } catch (error) {
      console.error('Failed to load messages:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSend = async () => {
    if (!newMessage.trim()) return;
    
    try {
      await chatService.sendMessage(journalId, newMessage);
      setNewMessage('');
    } catch (error) {
      console.error('Failed to send message:', error);
    }
  };

  if (loading) return <div>Loading...</div>;

  return (
    <div className="chat-window">
      <div className="messages">
        {messages.map(msg => (
          <div key={msg.id} className={msg.isInbound ? 'inbound' : 'outbound'}>
            <p>{msg.body}</p>
            <small>{new Date(msg.createdDate).toLocaleString()}</small>
          </div>
        ))}
      </div>
      
      <div className="input-area">
        <input
          value={newMessage}
          onChange={(e) => setNewMessage(e.target.value)}
          onKeyPress={(e) => e.key === 'Enter' && handleSend()}
          placeholder="Type a message..."
        />
        <button onClick={handleSend}>Send</button>
      </div>
    </div>
  );
};
```

## 📦 Deployment

### Build for Production

```bash
# Build the application
npm run build

# Output will be in dist/ directory
```

### Deploy to AWS S3

```bash
# Sync build to S3 bucket
aws s3 sync dist/ s3://customer-portal-prod-frontend/ --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"
```

### Automated Deployment (GitHub Actions)

```yaml
name: Deploy Frontend

on:
  push:
    branches:
      - main
    paths:
      - 'feature-customer-portal/spa-frontend/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install Dependencies
        run: |
          cd feature-customer-portal/spa-frontend
          npm ci
      
      - name: Build
        run: |
          cd feature-customer-portal/spa-frontend
          npm run build
      
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: eu-west-1
      
      - name: Deploy to S3
        run: |
          cd feature-customer-portal/spa-frontend
          aws s3 sync dist/ s3://customer-portal-prod-frontend/ --delete
      
      - name: Invalidate CloudFront
        run: |
          aws cloudfront create-invalidation \
            --distribution-id ${{ secrets.CLOUDFRONT_DISTRIBUTION_ID }} \
            --paths "/*"
```

## 🧪 Testing

```bash
# Run unit tests
npm test

# Run tests with coverage
npm run test:coverage

# Run E2E tests
npm run test:e2e
```

## 📊 Performance Optimization

- **Code Splitting**: Lazy load routes and components
- **Asset Optimization**: Compress images, minify CSS/JS
- **Caching**: Leverage CloudFront caching for static assets
- **Bundle Analysis**: Use `rollup-plugin-visualizer` to analyze bundle size

## 📞 Support

For frontend issues:
- **Frontend Team**: frontend@easylegalgroup.com
- **GitHub Issues**: Create an issue in the repository

## 📚 Additional Resources

- [React Documentation](https://react.dev/)
- [Vite Guide](https://vitejs.dev/guide/)
- [AWS S3 Static Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [CloudFront Distribution](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web.html)
