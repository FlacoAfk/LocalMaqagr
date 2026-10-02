/**
 * @fileoverview Página de detalle de tractor o máquina agrícola.
 *
 * Muestra la información técnica completa de un equipo (tractor o máquina)
 * organizada en pestañas temáticas. Los datos se cargan de forma simulada
 * (mock) según el ID de la URL; en producción se reemplazará por una llamada
 * a la API REST.
 *
 * Pestañas disponibles:
 *  - Identificación   — datos básicos del equipo (siempre visible)
 *  - Dimensiones      — medidas y peso (siempre visible)
 *  - Motor            — solo para tractores
 *  - Especificaciones — solo para máquinas
 *
 * Responsive:
 *  - Hero: columna única en móvil → dos columnas en md+
 *  - Pestañas: scroll horizontal en móvil con `overflow-x-auto`
 *  - Grilla de datos: 1 columna en móvil → 2 columnas en md+
 *
 * @module pages/TractorMachineDetail
 */

import React, { useState, useEffect } from 'react';
import { useParams, useLocation } from 'react-router-dom';
import Button from '@/components/ui/LegacyButton';
import { getTractorById } from '../../services/tractorApi';
import { getImplementById } from '../../services/implementApi';
import { PiTractorFill as TractorImgFallback } from "react-icons/pi";
import MaquinaImgFallback from '../../assets/icons/plow.webp';

/**
 * Mapeo de claves de campo a etiquetas legibles en español.
 * Cubre los campos de todas las pestañas para evitar lógica de transformación dispersa.
 *
 * @type {Record<string, string>}
 */
const FIELD_LABELS = {
  nombreComercial: 'Nombre Comercial',
  marca: 'Marca',
  modelo: 'Modelo',
  tipo: 'Tipo',
  estado: 'Estado',
  potenciaBruta: 'Potencia de Motor',
  fuerzaTraccion: 'Fuerza de Tracción',
  tipoTraccion: 'Tipo de Tracción',
  peso: 'Peso',
  tipoLlanta: 'Tipo de Llanta',
  anchoLlanta: 'Ancho de Llanta',
  diametroLlanta: 'Diámetro de Llanta',
  presionLlanta: 'Presión de Llanta',
  anchoDeTrabajo: 'Ancho de Trabajo',
  profundidadTrabajo: 'Profundidad de Trabajo',
  requerimientoPotencia: 'Requerimiento de Potencia',
  tipoSuelo: 'Tipo de Suelo Recomendado',
};

/**
 * Nombres de las pestañas de detalle.
 *
 * @type {Record<string, string>}
 */
const TAB_NAMES = {
  identificacion: 'Datos de Identificación',
  motor: 'Especificaciones de Motor',
  dimensiones: 'Dimensiones y Peso',
  especificacionesTecnicas: 'Especificaciones Técnicas',
};

// El API devuelve snake_case (columnas de Postgres); el mock usaba camelCase.
// Se aceptan ambos formatos para que la página funcione con cualquier fuente.
const pick = (obj, ...keys) => {
  for (const k of keys) {
    const v = obj?.[k];
    if (v !== undefined && v !== null) return v;
  }
  return null;
};

const mapTractorToMockFormat = (tractor) => ({
  id: pick(tractor, 'tractorId', 'tractor_id', 'id'),
  title: tractor.name || `${tractor.brand || ''} ${tractor.model || ''}`.trim(),
  category: 'Tractor',
  imageSrc: pick(tractor, 'imageUrl', 'image_url') || TractorImgFallback,
  fichaTecnicaUrl: pick(tractor, 'fichaPdfUrl', 'ficha_pdf_url') || '#',
  identificacion: {
    nombreComercial: tractor.name || `${tractor.brand || ''} ${tractor.model || ''}`.trim(),
    marca: tractor.brand,
    modelo: tractor.model,
    estado: tractor.status === 'available' ? 'Disponible' : (tractor.status === 'maintenance' ? 'En mantenimiento' : tractor.status),
  },
  motor: {
    potenciaBruta: pick(tractor, 'enginePowerHp', 'engine_power_hp') ? `${pick(tractor, 'enginePowerHp', 'engine_power_hp')} HP` : 'N/A',
    fuerzaTraccion: pick(tractor, 'tractionForceKn', 'traction_force_kn') ? `${pick(tractor, 'tractionForceKn', 'traction_force_kn')} kN` : 'N/A',
    tipoTraccion: (pick(tractor, 'tractionType', 'traction_type') || 'N/A').toUpperCase(),
  },
  dimensiones: {
    peso: pick(tractor, 'weightKg', 'weight_kg') ? `${pick(tractor, 'weightKg', 'weight_kg')} kg` : 'N/A',
    tipoLlanta: tractor.tireType || tractor.tire_type || 'N/A',
    anchoLlanta: pick(tractor, 'tireWidthMm', 'tire_width_mm') ? `${pick(tractor, 'tireWidthMm', 'tire_width_mm')} mm` : 'N/A',
    diametroLlanta: pick(tractor, 'tireDiameterMm', 'tire_diameter_mm') ? `${pick(tractor, 'tireDiameterMm', 'tire_diameter_mm')} mm` : 'N/A',
    presionLlanta: pick(tractor, 'tirePressurePsi', 'tire_pressure_psi') ? `${pick(tractor, 'tirePressurePsi', 'tire_pressure_psi')} psi` : 'N/A',
  },
});

const mapImplementToMockFormat = (machine) => ({
  id: pick(machine, 'implementId', 'implement_id', 'id'),
  title: machine.implementName || machine.implement_name,
  category: 'Máquina',
  imageSrc: pick(machine, 'imageUrl', 'image_url') || MaquinaImgFallback,
  fichaTecnicaUrl: pick(machine, 'fichaPdfUrl', 'ficha_pdf_url') || '#',
  identificacion: {
    nombreComercial: machine.implementName || machine.implement_name,
    marca: machine.brand,
    tipo: machine.implementType || machine.implement_type,
    estado: machine.status === 'available' ? 'Disponible' : (machine.status === 'maintenance' ? 'En mantenimiento' : machine.status),
  },
  dimensiones: {
    peso: pick(machine, 'weightKg', 'weight_kg') ? `${pick(machine, 'weightKg', 'weight_kg')} kg` : 'N/A',
  },
  especificacionesTecnicas: {
    anchoDeTrabajo: pick(machine, 'workingWidthM', 'working_width_m') ? `${pick(machine, 'workingWidthM', 'working_width_m')} m` : 'N/A',
    profundidadTrabajo: pick(machine, 'workingDepthCm', 'working_depth_cm') ? `${pick(machine, 'workingDepthCm', 'working_depth_cm')} cm` : 'N/A',
    requerimientoPotencia: pick(machine, 'powerRequirementHp', 'power_requirement_hp') ? `${pick(machine, 'powerRequirementHp', 'power_requirement_hp')} HP` : 'N/A',
    tipoSuelo: machine.soilType || machine.soil_type || 'N/A',
  },
});

// ---------------------------------------------------------------------------
// Sub-componente: tabla de datos de una pestaña
// ---------------------------------------------------------------------------

/**
 * DataTable — Tabla de pares clave-valor para una sección de datos técnicos.
 *
 * Renderiza cada entrada del objeto `data` como una fila con etiqueta y valor.
 * Usa `FIELD_LABELS` para mostrar etiquetas legibles en lugar de las claves raw.
 *
 * @param {Object} props
 * @param {string} props.title  - Título de la sección.
 * @param {Object} props.data   - Objeto con los pares clave-valor a mostrar.
 *
 * @returns {JSX.Element} Sección con título y tabla de datos.
 */
const DataTable = ({ title, data }) => (
  <div className="bg-card rounded border border-border p-4 sm:p-6 shadow-sm">
    <h2 className="text-xl sm:text-2xl font-bold text-foreground mb-4 sm:mb-6">{title}</h2>
    <div className="grid grid-cols-1 gap-y-3 gap-x-8 md:grid-cols-2">
      {Object.entries(data).map(([key, value]) => (
        <div key={key} className="border-b border-border pb-2">
          <div className="flex flex-col sm:flex-row sm:justify-between sm:items-baseline gap-1">
            {/* Etiqueta del campo — legible en español */}
            <span className="font-medium text-muted-foreground text-sm">
              {FIELD_LABELS[key] ?? key.replace(/([A-Z])/g, ' $1').trim()}
            </span>
            {/* Valor del campo */}
            <span className="text-foreground text-sm sm:text-right">{value}</span>
          </div>
        </div>
      ))}
    </div>
  </div>
);

// ---------------------------------------------------------------------------
// Componente principal
// ---------------------------------------------------------------------------

/**
 * TractorDetail — Página de detalle de tractor o máquina agrícola.
 *
 * Lee el parámetro `:id` de la URL para determinar qué equipo mostrar.
 * Las pestañas disponibles varían según la categoría del equipo.
 *
 * @component
 * @returns {JSX.Element} Página de detalle con hero, pestañas y contenido técnico.
 *
 * @example
 * // Registrada en App.jsx para tractores y máquinas
 * <Route path="/tractor/:id"    element={<TractorMachineDetail />} />
 * <Route path="/maquinaria/:id" element={<TractorMachineDetail />} />
 */
const TractorDetail = () => {
  // ── Parámetros de ruta ────────────────────────────────────────────────────

  const { id } = useParams();
  const location = useLocation();

  // ── Estado local ──────────────────────────────────────────────────────────

  const [loading, setLoading] = useState(true);
  const [item, setItem] = useState(null);
  const [activeTab, setActiveTab] = useState('identificacion');
  const [error, setError] = useState(null);

  // ── Carga de datos ────────────────────────────────────────────────────────

  useEffect(() => {
    const fetchItem = async () => {
      setLoading(true);
      setError(null);
      try {
        const isTractor = location.pathname.startsWith('/tractor');
        
        if (isTractor) {
          const res = await getTractorById(id);
          const data = res.data;
          setItem(mapTractorToMockFormat(data));
        } else {
          const res = await getImplementById(id);
          const data = res.data;
          setItem(mapImplementToMockFormat(data));
        }
      } catch (err) {
        setError(err.message || 'Error al cargar el ítem');
      } finally {
        setLoading(false);
      }
    };

    fetchItem();
  }, [id, location.pathname]);

  // ── Estados de carga y error ──────────────────────────────────────────────

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center px-4">
        <div className="text-center">
          {/* Spinner de carga */}
          <div
            className="w-14 h-14 sm:w-16 sm:h-16 border-4 border-primary border-t-transparent
                       rounded-full animate-spin mx-auto"
            role="status"
            aria-label="Cargando información del equipo"
          />
          <p className="mt-4 text-base sm:text-lg text-muted-foreground">Cargando información...</p>
        </div>
      </div>
    );
  }

  if (error || !item) {
    return (
      <div className="container mx-auto px-4 py-12 text-center">
        <h1 className="text-xl sm:text-2xl font-bold text-primary">
          {error || 'Ítem no encontrado'}
        </h1>
        <Button variant="primary" color="#909d00" to="/" className="mt-4">
          Volver al inicio
        </Button>
      </div>
    );
  }

  // ── Derivados ─────────────────────────────────────────────────────────────

  /**
   * Calcula las pestañas disponibles según la categoría del equipo.
   * Los tractores tienen pestaña de motor; las máquinas tienen especificaciones técnicas.
   *
   * @returns {string[]} Array de claves de pestaña disponibles.
   */
  const getTabs = () => {
    const tabs = ['identificacion', 'dimensiones'];
    if (item.category === 'Tractor') tabs.push('motor');
    if (item.category === 'Máquina') tabs.push('especificacionesTecnicas');
    return tabs;
  };

  const tabs = getTabs();

  // ── Render ────────────────────────────────────────────────────────────────

  return (
    <div className="bg-background min-h-screen pb-10 sm:pb-12">

      {/* ── Hero: imagen + título + descripción + CTA ── */}
      <div className="bg-card shadow-sm border-b border-border">
        <div className="container mx-auto px-4 sm:px-6 lg:px-8 py-6 sm:py-8">
          {/*
           * Layout hero:
           *  - móvil  : columna única (texto arriba, imagen abajo)
           *  - md+    : dos columnas (texto izquierda, imagen derecha)
           */}
          <div className="flex flex-col gap-6 md:flex-row md:items-center md:gap-8">

            {/* Bloque de texto */}
            <div className="flex-1">
              <h1 className="text-2xl sm:text-3xl md:text-4xl font-bold text-primary mb-3 sm:mb-4">
                {item.title}
              </h1>
              {/* Línea decorativa */}
              <div className="w-20 sm:w-24 h-1 bg-primary mb-4 sm:mb-6" aria-hidden="true" />

              {/* Descripción dinámica según categoría */}
              <p className="text-muted-foreground mb-4 sm:mb-6 text-sm sm:text-base leading-relaxed">
                {item.category === 'Tractor'
                  ? `Tractor ${item.identificacion.marca} ${item.identificacion.modelo}.`
                  : `${item.identificacion.nombreComercial}, marca ${item.identificacion.marca}.`}
              </p>

              {/* CTA: ficha técnica — informe de la prueba Nebraska (tractores) o
                  página del fabricante (implementos); solo si hay enlace. Abre en
                  pestaña nueva; el PDF se descarga desde el botón "Download" del
                  repositorio de la universidad. */}
              {item.fichaTecnicaUrl && item.fichaTecnicaUrl !== '#' && (
                <Button
                  variant="primary"
                  color="#909d00"
                  href={item.fichaTecnicaUrl}
                  target="_blank"
                  rel="noreferrer"
                  className="w-full sm:w-auto"
                >
                  {item.category === 'Tractor'
                    ? 'Ficha técnica oficial (PDF)'
                    : 'Ver ficha técnica del fabricante'}
                </Button>
              )}
            </div>

            {/* Imagen del equipo */}
            <div className="flex-1">
              <div className="bg-secondary/30 rounded-lg overflow-hidden shadow-sm border border-border/60 flex items-center justify-center p-6 aspect-video text-muted-foreground">
                {typeof item.imageSrc === 'function' || (typeof item.imageSrc === 'object' && item.imageSrc !== null) ? (
                  React.createElement(item.imageSrc, { className: "w-28 h-28 text-primary" })
                ) : (
                  <img
                    src={item.imageSrc}
                    alt={item.title}
                    className="w-full h-auto object-contain mix-blend-multiply"
                    loading="lazy"
                    referrerPolicy="no-referrer"
                    onError={(e) => { e.currentTarget.style.display = 'none'; }}
                  />
                )}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* ── Pestañas de navegación ── */}
      <div className="container mx-auto px-4 sm:px-6 lg:px-8 mt-6 sm:mt-8">

        {/* Barra de pestañas con scroll horizontal en móvil */}
        <div className="border-b border-border overflow-x-auto">
          <nav
            className="flex -mb-px min-w-max"
            role="tablist"
            aria-label="Secciones de información técnica"
          >
            {tabs.map((tab) => (
              <button
                key={tab}
                role="tab"
                aria-selected={activeTab === tab}
                aria-controls={`panel-${tab}`}
                onClick={() => setActiveTab(tab)}
                className={`py-3 sm:py-4 px-4 sm:px-6 text-center border-b-2 font-medium
                            text-xs sm:text-sm whitespace-nowrap transition-colors duration-200 ${
                  activeTab === tab
                    ? 'border-primary text-primary'
                    : 'border-transparent text-muted-foreground hover:text-foreground hover:border-border'
                }`}
              >
                {TAB_NAMES[tab]}
              </button>
            ))}
          </nav>
        </div>

        {/* ── Contenido de la pestaña activa ── */}
        <div className="py-4 sm:py-6">

          {/* Pestaña: Identificación */}
          {activeTab === 'identificacion' && (
            <DataTable title="Datos de Identificación" data={item.identificacion} />
          )}

          {/* Pestaña: Motor (solo tractores) */}
          {activeTab === 'motor' && item.motor && (
            <DataTable title="Especificaciones de Motor" data={item.motor} />
          )}

          {/* Pestaña: Dimensiones */}
          {activeTab === 'dimensiones' && (
            <DataTable title="Dimensiones y Peso" data={item.dimensiones} />
          )}

          {/* Pestaña: Especificaciones Técnicas (solo máquinas) */}
          {activeTab === 'especificacionesTecnicas' && item.especificacionesTecnicas && (
            <DataTable title="Especificaciones Técnicas" data={item.especificacionesTecnicas} />
          )}
        </div>
      </div>
    </div>
  );
};

export default TractorDetail;
