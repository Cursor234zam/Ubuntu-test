import React, { useState } from 'react';
import { SurveyForm } from '@/components/SurveyForm';
import { AdminDashboard } from '@/components/AdminDashboard';
import { Toaster } from '@/components/ui/toaster';
import { Button } from '@/components/ui/button';
import { FileText, BarChart3 } from 'lucide-react';
import './App.css';

function App() {
  const [currentView, setCurrentView] = useState<'survey' | 'admin'>('survey');

  return (
    <div className="min-h-screen bg-background">
      {/* Navigation */}
      <nav className="bg-white border-b border-border shadow-sm">
        <div className="container mx-auto px-4 py-3">
          <div className="flex items-center justify-between">
            <h1 className="text-xl font-bold text-primary">
              Gestión de Riesgos en Salud
            </h1>
            
            <div className="flex space-x-2">
              <Button
                variant={currentView === 'survey' ? 'default' : 'outline'}
                onClick={() => setCurrentView('survey')}
                size="sm"
              >
                <FileText className="h-4 w-4 mr-2" />
                Cuestionario
              </Button>
              
              <Button
                variant={currentView === 'admin' ? 'default' : 'outline'}
                onClick={() => setCurrentView('admin')}
                size="sm"
              >
                <BarChart3 className="h-4 w-4 mr-2" />
                Dashboard
              </Button>
            </div>
          </div>
        </div>
      </nav>

      {/* Content */}
      <main>
        {currentView === 'survey' ? <SurveyForm /> : <AdminDashboard />}
      </main>
      
      <Toaster />
    </div>
  );
}

export default App;