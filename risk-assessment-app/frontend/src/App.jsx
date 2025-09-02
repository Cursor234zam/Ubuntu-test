import React, { useState, useEffect } from 'react';
import PersonalInfoForm from './components/PersonalInfoForm';
import QuestionCard from './components/QuestionCard';
import ResultsSummary from './components/ResultsSummary';
import { Button } from './components/ui/button';
import { Progress } from './components/ui/progress';
import { Card, CardContent, CardHeader, CardTitle } from './components/ui/card';
import { Badge } from './components/ui/badge';
import { ChevronLeft, ChevronRight, Send, ClipboardList, AlertCircle } from 'lucide-react';
import './App.css';

function App() {
  const [questions, setQuestions] = useState({});
  const [currentStep, setCurrentStep] = useState(0);
  const [personalInfo, setPersonalInfo] = useState({
    full_name: '',
    position: '',
    entity: '',
    phone_number: '',
    email: ''
  });
  const [answers, setAnswers] = useState({});
  const [errors, setErrors] = useState({});
  const [submission, setSubmission] = useState(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchQuestions();
  }, []);

  const fetchQuestions = async () => {
    try {
      const response = await fetch('http://localhost:8000/api/questions');
      const data = await response.json();
      setQuestions(data.questions);
    } catch (error) {
      console.error('Error fetching questions:', error);
    }
  };

  const validatePersonalInfo = () => {
    const newErrors = {};
    
    if (!personalInfo.full_name.trim()) {
      newErrors.full_name = 'El nombre completo es requerido';
    }
    if (!personalInfo.position.trim()) {
      newErrors.position = 'El cargo es requerido';
    }
    if (!personalInfo.entity.trim()) {
      newErrors.entity = 'La entidad es requerida';
    }
    if (!personalInfo.phone_number.trim()) {
      newErrors.phone_number = 'El número de celular es requerido';
    }
    if (!personalInfo.email.trim()) {
      newErrors.email = 'El correo electrónico es requerido';
    } else if (!/\S+@\S+\.\S+/.test(personalInfo.email)) {
      newErrors.email = 'El correo electrónico no es válido';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleAnswerChange = (questionId, answerData) => {
    setAnswers(prev => ({
      ...prev,
      [questionId]: answerData
    }));
  };

  const handleNext = () => {
    if (currentStep === 0) {
      if (validatePersonalInfo()) {
        setCurrentStep(currentStep + 1);
      }
    } else {
      setCurrentStep(currentStep + 1);
    }
  };

  const handlePrevious = () => {
    setCurrentStep(currentStep - 1);
  };

  const calculateTotalScore = () => {
    return Object.values(answers).reduce((total, answer) => {
      return total + (answer?.score || 0);
    }, 0);
  };

  const handleSubmit = async () => {
    setLoading(true);
    
    const responses = Object.keys(questions).map(questionId => ({
      question_id: parseInt(questionId),
      answer: answers[questionId]?.text || answers[questionId]?.yesNo || null,
      file_path: answers[questionId]?.filePath || null,
      score: answers[questionId]?.score || 0
    }));

    const submissionData = {
      personal_info: personalInfo,
      responses: responses,
      total_score: calculateTotalScore()
    };

    try {
      const response = await fetch('http://localhost:8000/api/submit', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(submissionData)
      });

      if (response.ok) {
        const result = await response.json();
        setSubmission({
          ...submissionData,
          submission_id: result.submission_id,
          submission_date: new Date().toISOString()
        });
        setCurrentStep(currentStep + 1);
      }
    } catch (error) {
      console.error('Error submitting form:', error);
    } finally {
      setLoading(false);
    }
  };

  const totalSteps = Object.keys(questions).length + 1;
  const progress = ((currentStep) / (totalSteps + 1)) * 100;
  const maxScore = Object.values(questions).reduce((sum, q) => sum + q.score, 0);
  const currentScore = calculateTotalScore();

  if (submission) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 p-4">
        <div className="max-w-4xl mx-auto">
          <ResultsSummary submission={submission} maxScore={maxScore} />
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 p-4">
      <div className="max-w-4xl mx-auto space-y-6">
        {/* Header */}
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <ClipboardList className="h-8 w-8 text-primary" />
                <div>
                  <CardTitle className="text-2xl">
                    Evaluación de Gestión de Riesgos en Salud
                  </CardTitle>
                  <p className="text-sm text-muted-foreground mt-1">
                    Complete todas las secciones del formulario
                  </p>
                </div>
              </div>
              <Badge variant="outline" className="text-lg px-3 py-1">
                {currentScore} / {maxScore} pts
              </Badge>
            </div>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span>Progreso: Paso {currentStep + 1} de {totalSteps + 1}</span>
                <span>{Math.round(progress)}%</span>
              </div>
              <Progress value={progress} className="h-2" />
            </div>
          </CardContent>
        </Card>

        {/* Content */}
        {currentStep === 0 ? (
          <PersonalInfoForm
            personalInfo={personalInfo}
            setPersonalInfo={setPersonalInfo}
            errors={errors}
          />
        ) : currentStep <= Object.keys(questions).length ? (
          <QuestionCard
            question={questions[currentStep]}
            questionNumber={currentStep}
            onAnswerChange={handleAnswerChange}
            answer={answers[currentStep]}
          />
        ) : (
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <AlertCircle className="h-6 w-6 text-yellow-600" />
                Confirmar Envío
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <p>¿Está seguro de que desea enviar el formulario?</p>
              <div className="bg-muted p-4 rounded-lg space-y-2">
                <p className="font-semibold">Resumen:</p>
                <p className="text-sm">Preguntas respondidas: {Object.keys(answers).length} / {Object.keys(questions).length}</p>
                <p className="text-sm">Puntuación actual: {currentScore} / {maxScore} puntos</p>
              </div>
              <p className="text-sm text-muted-foreground">
                Una vez enviado, no podrá modificar sus respuestas.
              </p>
            </CardContent>
          </Card>
        )}

        {/* Navigation */}
        <div className="flex justify-between items-center">
          <Button
            onClick={handlePrevious}
            disabled={currentStep === 0}
            variant="outline"
          >
            <ChevronLeft className="mr-2 h-4 w-4" />
            Anterior
          </Button>

          {currentStep < Object.keys(questions).length ? (
            <Button onClick={handleNext}>
              Siguiente
              <ChevronRight className="ml-2 h-4 w-4" />
            </Button>
          ) : currentStep === Object.keys(questions).length ? (
            <Button onClick={handleNext}>
              Revisar y Enviar
              <ChevronRight className="ml-2 h-4 w-4" />
            </Button>
          ) : (
            <Button 
              onClick={handleSubmit} 
              disabled={loading}
              className="bg-green-600 hover:bg-green-700"
            >
              {loading ? 'Enviando...' : (
                <>
                  <Send className="mr-2 h-4 w-4" />
                  Enviar Formulario
                </>
              )}
            </Button>
          )}
        </div>
      </div>
    </div>
  );
}

export default App;