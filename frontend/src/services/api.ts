import axios from 'axios';
import { Question, SurveySubmission, FileUploadResponse } from '@/types/survey';

const API_BASE_URL = 'http://localhost:8000';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

export const surveyApi = {
  // Obtener preguntas del cuestionario
  getQuestions: async (): Promise<{ questions: Question[] }> => {
    const response = await api.get('/questions');
    return response.data;
  },

  // Subir archivo
  uploadFile: async (file: File): Promise<FileUploadResponse> => {
    const formData = new FormData();
    formData.append('file', file);
    
    const response = await api.post('/upload-file', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
    
    return response.data;
  },

  // Enviar cuestionario completo
  submitSurvey: async (submission: SurveySubmission): Promise<any> => {
    const response = await api.post('/submit-survey', submission);
    return response.data;
  },

  // Obtener todas las submisiones (para administración)
  getSubmissions: async (): Promise<any> => {
    const response = await api.get('/submissions');
    return response.data;
  },

  // Obtener una submisión específica
  getSubmission: async (submissionId: string): Promise<any> => {
    const response = await api.get(`/submissions/${submissionId}`);
    return response.data;
  },

  // Descargar PDF de una submisión
  downloadPDF: async (submissionId: string): Promise<Blob> => {
    const response = await api.get(`/download-pdf/${submissionId}`, {
      responseType: 'blob',
    });
    return response.data;
  },

  // Descargar ZIP con archivos adjuntos
  downloadZIP: async (submissionId: string): Promise<Blob> => {
    const response = await api.get(`/download-zip/${submissionId}`, {
      responseType: 'blob',
    });
    return response.data;
  },

  // Descargar paquete completo (PDF + archivos)
  downloadComplete: async (submissionId: string): Promise<Blob> => {
    const response = await api.get(`/download-complete/${submissionId}`, {
      responseType: 'blob',
    });
    return response.data;
  },

  // Obtener estadísticas
  getStatistics: async (): Promise<any> => {
    const response = await api.get('/stats');
    return response.data;
  },
};

export default api;