from reportlab.lib.pagesizes import letter, A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_JUSTIFY
from datetime import datetime
import os

class PDFGenerator:
    def __init__(self):
        self.styles = getSampleStyleSheet()
        self.setup_custom_styles()
    
    def setup_custom_styles(self):
        """Configurar estilos personalizados para el PDF"""
        self.styles.add(ParagraphStyle(
            name='CustomTitle',
            parent=self.styles['Heading1'],
            fontSize=18,
            spaceAfter=30,
            alignment=TA_CENTER,
            textColor=colors.darkblue
        ))
        
        self.styles.add(ParagraphStyle(
            name='SectionHeader',
            parent=self.styles['Heading2'],
            fontSize=14,
            spaceAfter=12,
            spaceBefore=20,
            textColor=colors.darkblue
        ))
        
        self.styles.add(ParagraphStyle(
            name='QuestionText',
            parent=self.styles['Normal'],
            fontSize=11,
            spaceAfter=8,
            leftIndent=20
        ))
        
        self.styles.add(ParagraphStyle(
            name='AnswerText',
            parent=self.styles['Normal'],
            fontSize=10,
            spaceAfter=15,
            leftIndent=40,
            textColor=colors.darkgreen
        ))

    def generate_survey_pdf(self, submission_data, output_path):
        """Generar PDF con las respuestas del cuestionario"""
        doc = SimpleDocTemplate(output_path, pagesize=A4, 
                               rightMargin=72, leftMargin=72, 
                               topMargin=72, bottomMargin=18)
        
        # Contenido del PDF
        story = []
        
        # Título principal
        title = Paragraph("CUESTIONARIO DE GESTIÓN DE RIESGOS EN SALUD", self.styles['CustomTitle'])
        story.append(title)
        story.append(Spacer(1, 20))
        
        # Información de la submisión
        submission_info = f"""
        <b>ID de Submisión:</b> {submission_data['id']}<br/>
        <b>Fecha de Envío:</b> {datetime.fromisoformat(submission_data['submission_date']).strftime('%d/%m/%Y %H:%M:%S')}<br/>
        <b>Puntuación Total:</b> {submission_data['total_score']} / {submission_data['max_score']} ({submission_data['percentage']}%)
        """
        story.append(Paragraph(submission_info, self.styles['Normal']))
        story.append(Spacer(1, 20))
        
        # Información personal
        story.append(Paragraph("INFORMACIÓN PERSONAL", self.styles['SectionHeader']))
        
        personal_info = submission_data['personal_info']
        personal_data = [
            ['Campo', 'Información'],
            ['Nombre Completo', personal_info['nombre_completo']],
            ['Cargo', personal_info['cargo']],
            ['Entidad', personal_info['entidad']],
            ['Celular', personal_info['celular']],
            ['Email', personal_info['email']]
        ]
        
        personal_table = Table(personal_data, colWidths=[2*inch, 4*inch])
        personal_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.lightblue),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 12),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        
        story.append(personal_table)
        story.append(Spacer(1, 20))
        
        # Respuestas del cuestionario
        story.append(Paragraph("RESPUESTAS DEL CUESTIONARIO", self.styles['SectionHeader']))
        
        # Crear mapeo de preguntas para obtener el texto completo
        questions_map = self.get_questions_map()
        
        for response in submission_data['responses']:
            question_id = response['question_id']
            question_info = questions_map.get(question_id, {})
            
            # Pregunta
            question_text = f"<b>{question_id}.</b> {question_info.get('text', 'Pregunta no encontrada')}"
            story.append(Paragraph(question_text, self.styles['QuestionText']))
            
            # Respuesta
            answer_text = f"<b>Respuesta:</b> {response['answer']}"
            if response.get('file_path'):
                answer_text += f"<br/><b>Archivo adjunto:</b> {os.path.basename(response['file_path'])}"
            answer_text += f"<br/><b>Puntuación obtenida:</b> {response['score']} / {question_info.get('score', 0)} puntos"
            
            story.append(Paragraph(answer_text, self.styles['AnswerText']))
            story.append(Spacer(1, 10))
        
        # Resumen final
        story.append(PageBreak())
        story.append(Paragraph("RESUMEN DE EVALUACIÓN", self.styles['SectionHeader']))
        
        # Tabla de resumen
        summary_data = [
            ['Concepto', 'Valor'],
            ['Puntuación Total Obtenida', f"{submission_data['total_score']} puntos"],
            ['Puntuación Máxima Posible', f"{submission_data['max_score']} puntos"],
            ['Porcentaje de Cumplimiento', f"{submission_data['percentage']}%"],
            ['Nivel de Preparación', self.get_preparation_level(submission_data['percentage'])]
        ]
        
        summary_table = Table(summary_data, colWidths=[3*inch, 3*inch])
        summary_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.darkblue),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 12),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.lightgrey),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        
        story.append(summary_table)
        story.append(Spacer(1, 20))
        
        # Recomendaciones
        recommendations = self.get_recommendations(submission_data['percentage'])
        story.append(Paragraph("RECOMENDACIONES", self.styles['SectionHeader']))
        story.append(Paragraph(recommendations, self.styles['Normal']))
        
        # Generar PDF
        doc.build(story)
        return output_path
    
    def get_questions_map(self):
        """Mapeo de preguntas con su texto completo"""
        return {
            1: {"text": "¿Cuentan con un Plan de Contingencia o Emergencia por un Evento Adverso En Salud?", "score": 8},
            2: {"text": "¿El presente Plan fue aprobado por su instancia respectiva?", "score": 8},
            3: {"text": "¿Cuenta con Sala de Situación/Crisis?", "score": 4},
            4: {"text": "¿Cuenta con un equipo de respuesta rápida?", "score": 8},
            5: {"text": "¿Cuenta con un vehículo, moto y/o ambulancia para socorrer?", "score": 4},
            6: {"text": "¿Utiliza Formulario de Enfermedades Trazadoras?", "score": 4},
            7: {"text": "¿Utiliza Formulario para Vigilancia de albergues?", "score": 4},
            8: {"text": "¿Conoce el manejo del EDAN Salud?", "score": 4},
            9: {"text": "¿Cuenta con un estadístico o informático que maneja y consolida la información?", "score": 4},
            10: {"text": "¿Conoce cuál es la guía o protocolo a proceder ante eventos adversos?", "score": 4},
            11: {"text": "¿Cuenta con un Epidemiólogo?", "score": 4},
            12: {"text": "¿Tiene contactos con SENAMHI?", "score": 4},
            13: {"text": "¿Tiene contactos con VIDECI?", "score": 4},
            14: {"text": "¿Tiene contactos con MSyD?", "score": 4},
            15: {"text": "¿Conoce el establecimiento de un COEM?", "score": 4},
            16: {"text": "¿Conoce el establecimiento de un SCI?", "score": 4},
            17: {"text": "¿Conoce la Ley 602 de Gestión de Riesgos y su aplicación?", "score": 4},
            18: {"text": "¿Conoce procedimientos para la realización de una declaratoria de emergencias y/o desastres?", "score": 4},
            19: {"text": "¿Cuenta con instructivo de G.R. emitido por el SEDES?", "score": 4},
            20: {"text": "¿Cuenta con un stock de medicamentos, insumos Y EPP ante eventos adversos?", "score": 4},
            21: {"text": "¿Desarrollo ferias de prevención en gestión de riesgo?", "score": 4},
            22: {"text": "¿Coordinación con el Centro Coordinar ante emergencia y/o desastres?", "score": 4},
            23: {"text": "Nombre y cargo de los colaboradores en el llenado del formulario", "score": 0}
        }
    
    def get_preparation_level(self, percentage):
        """Determinar el nivel de preparación basado en el porcentaje"""
        if percentage >= 90:
            return "EXCELENTE - Muy bien preparado"
        elif percentage >= 80:
            return "BUENO - Bien preparado"
        elif percentage >= 60:
            return "REGULAR - Preparación aceptable"
        elif percentage >= 40:
            return "DEFICIENTE - Necesita mejoras"
        else:
            return "CRÍTICO - Requiere atención inmediata"
    
    def get_recommendations(self, percentage):
        """Generar recomendaciones basadas en la puntuación"""
        if percentage >= 90:
            return """Su entidad demuestra un excelente nivel de preparación ante eventos adversos. 
            Continúe manteniendo y actualizando sus protocolos y recursos. Se recomienda realizar 
            simulacros periódicos y mantener actualizada la capacitación del personal."""
        elif percentage >= 80:
            return """Su entidad tiene un buen nivel de preparación. Identifique las áreas con 
            puntuación baja y trabaje en fortalecerlas. Considere revisar y actualizar los 
            documentos y protocolos faltantes."""
        elif percentage >= 60:
            return """Su entidad tiene una preparación regular. Es importante fortalecer las 
            capacidades identificadas como deficientes. Priorice la implementación de planes 
            de contingencia y la capacitación del personal."""
        elif percentage >= 40:
            return """Su entidad presenta deficiencias importantes en la preparación ante eventos 
            adversos. Se requiere atención urgente para desarrollar planes, capacitar personal 
            y adquirir recursos necesarios."""
        else:
            return """Su entidad presenta un nivel crítico de preparación. Se requiere acción 
            inmediata para implementar medidas básicas de preparación ante emergencias. 
            Contacte a las autoridades superiores para solicitar apoyo técnico y recursos."""