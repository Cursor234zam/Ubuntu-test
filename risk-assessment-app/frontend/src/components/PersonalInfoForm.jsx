import React from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Input } from './ui/input';
import { Label } from './ui/label';

const PersonalInfoForm = ({ personalInfo, setPersonalInfo, errors }) => {
  const handleChange = (e) => {
    const { name, value } = e.target;
    setPersonalInfo(prev => ({
      ...prev,
      [name]: value
    }));
  };

  return (
    <Card className="w-full">
      <CardHeader>
        <CardTitle>Información Personal</CardTitle>
        <CardDescription>
          Por favor complete todos los campos con su información personal
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="full_name">Nombre Completo *</Label>
          <Input
            id="full_name"
            name="full_name"
            value={personalInfo.full_name}
            onChange={handleChange}
            placeholder="Ingrese su nombre completo"
            className={errors?.full_name ? 'border-red-500' : ''}
          />
          {errors?.full_name && (
            <p className="text-sm text-red-500">{errors.full_name}</p>
          )}
        </div>

        <div className="space-y-2">
          <Label htmlFor="position">Cargo *</Label>
          <Input
            id="position"
            name="position"
            value={personalInfo.position}
            onChange={handleChange}
            placeholder="Ingrese su cargo"
            className={errors?.position ? 'border-red-500' : ''}
          />
          {errors?.position && (
            <p className="text-sm text-red-500">{errors.position}</p>
          )}
        </div>

        <div className="space-y-2">
          <Label htmlFor="entity">Entidad Perteneciente *</Label>
          <Input
            id="entity"
            name="entity"
            value={personalInfo.entity}
            onChange={handleChange}
            placeholder="Ingrese la entidad a la que pertenece"
            className={errors?.entity ? 'border-red-500' : ''}
          />
          {errors?.entity && (
            <p className="text-sm text-red-500">{errors.entity}</p>
          )}
        </div>

        <div className="space-y-2">
          <Label htmlFor="phone_number">Número de Celular *</Label>
          <Input
            id="phone_number"
            name="phone_number"
            type="tel"
            value={personalInfo.phone_number}
            onChange={handleChange}
            placeholder="Ej: +591 70000000"
            className={errors?.phone_number ? 'border-red-500' : ''}
          />
          {errors?.phone_number && (
            <p className="text-sm text-red-500">{errors.phone_number}</p>
          )}
        </div>

        <div className="space-y-2">
          <Label htmlFor="email">Correo Electrónico *</Label>
          <Input
            id="email"
            name="email"
            type="email"
            value={personalInfo.email}
            onChange={handleChange}
            placeholder="correo@ejemplo.com"
            className={errors?.email ? 'border-red-500' : ''}
          />
          {errors?.email && (
            <p className="text-sm text-red-500">{errors.email}</p>
          )}
        </div>
      </CardContent>
    </Card>
  );
};

export default PersonalInfoForm;