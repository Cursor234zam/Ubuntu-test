export interface PersonalInfo {
  nombre_completo: string;
  cargo: string;
  entidad: string;
  celular: string;
  email: string;
}

export interface Question {
  id: number;
  text: string;
  score: number;
  requires_file: boolean;
  file_description: string;
}

export interface QuestionResponse {
  question_id: number;
  answer: string;
  score: number;
  file_path?: string;
}

export interface SurveySubmission {
  personal_info: PersonalInfo;
  responses: QuestionResponse[];
  total_score: number;
  submission_date: Date;
}

export interface FileUploadResponse {
  filename: string;
  file_path: string;
  size: number;
  message: string;
}