/**
 * @fileoverview Página de catálogo de tractores de MaqAgr.
 *
 * Presenta un layout de dos columnas en desktop (sidebar de filtros + grilla
 * de tarjetas) que colapsa a una sola columna en móvil. El sidebar se muestra
 * primero en el flujo del documento para facilitar el filtrado antes de ver
 * los resultados.
 *
 * Breakpoints del layout:
 *  - móvil  (< lg) : columna única — sidebar arriba, grilla abajo
 *  - desktop (lg+) : sidebar fijo de 260 px a la izquierda, grilla a la derecha
 *
 * @module pages/CatalogoTractores
 */

import React, { useState, useEffect, useCallback, useRef } from 'react';
import TractorMachineCard from '@/features/tractors/components/TractorMachineCard';
import SkeletonCard from '@/components/ui/SkeletonCard';
import Pagination from '@/components/ui/Pagination';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { PiTractorFill as TractorImg } from "react-icons/pi";
import { getTractors } from '../../services/tractorApi';
import useDebounce from '../../hooks/useDebounce';

// ---------------------------------------------------------------------------
// Datos estáticos
// ---------------------------------------------------------------------------

/**
 * Marcas disponibles para filtrar en el catálogo de tractores.
 * Se renderizan como botones tipo chip/pill seleccionables.
 *
 * @type {string[]}
 */
const BRANDS = ['John Deere', 'New Holland', 'Massey Ferguson', 'Kubota'];

// ---------------------------------------------------------------------------
// Componente principal
// ---------------------------------------------------------------------------

/**
 * CatalogoTractores — Página de listado de tractores con filtros integrados a la API.
 * Carga por páginas desde el API (paginación server-side) para no traer
 * todo el catálogo de una vez.
 */
export default function CatalogoTractores() {
  const [tractors, setTractors] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);

  // Paginación
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(12);
  const [pagination, setPagination] = useState({ total: 0, totalPages: 0 });

  // States for filters
  const [search, setSearch] = useState('');
  const [brand, setBrand] = useState('');
  const [minPower, setMinPower] = useState('');
  const [maxPower, setMaxPower] = useState('');

  const debouncedSearch = useDebounce(search, 500);
  const gridRef = useRef(null);

  const fetchTractors = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const response = await getTractors({
        search: debouncedSearch,
        brand,
        minPower,
        maxPower,
        page,
        limit: pageSize
      });
      setTractors(response.data || []);
      if (response.pagination) {
        setPagination({
          total: response.pagination.total ?? 0,
          totalPages: response.pagination.totalPages ?? 0,
        });
      }
    } catch (err) {
      setError(err.message || 'Error al cargar el catálogo de tractores');
    } finally {
      setIsLoading(false);
    }
  }, [debouncedSearch, brand, minPower, maxPower, page, pageSize]);

  useEffect(() => {
    fetchTractors();
  }, [fetchTractors]);

  // Volver a la página 1 cuando cambia cualquier filtro
  useEffect(() => {
    setPage(1);
  }, [debouncedSearch, brand, minPower, maxPower]);

  const handleChangePage = (newPage) => {
    setPage(newPage);
    // Llevar al usuario al inicio del listado al cambiar de página
    gridRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' });
  };

  const handleChangePageSize = (newSize) => {
    setPageSize(newSize);
    setPage(1);
  };

  const handleClearFilters = () => {
    setSearch('');
    setBrand('');
    setMinPower('');
    setMaxPower('');
    setPage(1);
  };

  return (
    <div className="min-h-screen bg-background">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8 py-8 sm:py-10">
        <div className="flex flex-col gap-8 lg:flex-row lg:gap-8">

          {/* ── Panel de filtros ── */}
          <aside className="flex flex-col gap-5 w-full lg:w-[260px] lg:flex-shrink-0">
            <h2 className="text-base font-semibold text-[#1e2939]">Filtros</h2>

            <div className="flex flex-col gap-5">
              <div className="flex flex-col gap-1.5">
                <label htmlFor="tractor-modelo" className="text-sm font-medium text-foreground">
                  Modelo o Nombre
                </label>
                <Input 
                  id="tractor-modelo" 
                  placeholder="Buscar modelo" 
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                />
              </div>

              <div className="flex flex-col gap-2">
                <span className="text-sm font-medium text-foreground">Marcas</span>
                <div className="flex flex-wrap gap-2">
                  {BRANDS.map((m) => (
                    <button
                      key={m}
                      type="button"
                      onClick={() => setBrand(brand === m ? '' : m)}
                      className={`rounded-full border px-3 py-1 text-xs font-medium transition-colors ${
                        brand === m 
                          ? 'border-[#893d46] bg-[#893d46] text-white' 
                          : 'border-border text-foreground hover:border-[#893d46] hover:text-[#893d46]'
                      }`}
                    >
                      {m}
                    </button>
                  ))}
                </div>
              </div>

              <div className="flex flex-col gap-1.5">
                <label className="text-sm font-medium text-foreground">Potencia de Motor (HP)</label>
                <div className="grid grid-cols-2 gap-2">
                  <Input 
                    type="number" 
                    placeholder="Min" 
                    min="0" 
                    value={minPower}
                    onChange={(e) => setMinPower(e.target.value)}
                  />
                  <Input 
                    type="number" 
                    placeholder="Max" 
                    min="0" 
                    value={maxPower}
                    onChange={(e) => setMaxPower(e.target.value)}
                  />
                </div>
              </div>

              <Button variant="outline" className="w-full" onClick={handleClearFilters}>
                Limpiar filtros
              </Button>
            </div>
          </aside>

          {/* ── Área principal ── */}
          <main className="flex flex-1 flex-col gap-6 min-w-0">
            <div>
              <p className="mb-1 text-xs sm:text-sm font-semibold uppercase tracking-widest text-[#909d00]">
                Catálogo
              </p>
              <h1 className="text-xl sm:text-2xl font-bold text-[#1e2939]">
                Tractores
              </h1>
              <p className="mt-1 text-sm text-muted-foreground">
                Visualiza referencias destacadas con una presentación uniforme.
              </p>
            </div>

            {error && (
              <div className="p-4 bg-destructive/10 text-destructive border border-destructive/20 rounded-md">
                {error}
              </div>
            )}

            <div ref={gridRef} className="grid grid-cols-1 gap-4 sm:gap-5 sm:grid-cols-2 xl:grid-cols-3 scroll-mt-20">
              {isLoading ? (
                // Skeletons de carga
                Array.from({ length: 6 }).map((_, i) => <SkeletonCard key={i} />)
              ) : tractors.length > 0 ? (
                tractors.map((tractor) => (
                  <TractorMachineCard
                    key={tractor.tractorId || tractor.id}
                    imageSrc={tractor.imageUrl || TractorImg}
                    link={`/tractor/${tractor.tractorId || tractor.id}`}
                    title={tractor.name}
                    description={`${tractor.brand} - ${tractor.enginePowerHp} HP. Modelo: ${tractor.model}`}
                  />
                ))
              ) : (
                <div className="col-span-full py-10 text-center text-muted-foreground">
                  No se encontraron tractores con estos filtros.
                </div>
              )}
            </div>

            {/* Paginación server-side */}
            {!isLoading && pagination.totalPages > 1 && (
              <Pagination
                paginaActual={page}
                totalPaginas={pagination.totalPages}
                onCambiarPagina={handleChangePage}
                total={pagination.total}
                limit={pageSize}
                onLimitChange={handleChangePageSize}
                isLoading={isLoading}
              />
            )}
          </main>
        </div>
      </div>
    </div>
  );
}
