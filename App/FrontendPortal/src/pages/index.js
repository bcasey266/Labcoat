import React from 'react';

import App from './App';
import { PublicClientApplication } from '@azure/msal-browser';
import { MsalProvider } from '@azure/msal-react';
import { msalConfig } from '../components/authConfig';

import Head from 'next/head';

const msalInstance = new PublicClientApplication(msalConfig);

export default function IndexPage() {
  return (
    <div>
      <Head>
        <title>ASAP Portal</title>
      </Head>
      <React.StrictMode>
        <MsalProvider instance={msalInstance}>
          <App />
        </MsalProvider>
      </React.StrictMode>
    </div>
  );
}
