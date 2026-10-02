/**
 * @fileoverview Componente de paginación reutilizable para listados de datos.
 *
 * Barra de navegación moderna con botones previo/siguiente (chevrons),
 * numeración con elipsis para catálogos grandes, contador de resultados
 * ("Mostrando X–Y de Z") y selector opcional de tamaño de página.
 *
 * Diseñado para listados que cargan por página desde el API (cientos o miles
 * de registros) para no traer todo de una vez y mantener la app rápida.
 *
 * Compatibilidad: mantiene las props históricas en español
 * (paginaActual, totalPaginas, onCambiarPagina) usadas por los formularios
 * de administración; las props nuevas (total, limit, onLimitChange,
 * isLoading) son opcionales y añaden el contador y el selector.
 *
 * @module components/ui/Pagination
 */

import React from 'react';
import { Button } from '@/components/ui/button';
import { ChevronLeft, ChevronRight } from 'lucide-react';

// ---------------------------------------------------------------------------
// Componente principal
// ---------------------------------------------------------------------------

/**
 * Calcula las páginas a mostrar con elipsis: siempre 1 y la última, ventana
 * de ±1 alrededor de la página actual.
 *
 * @param {number} page Página actual
 * @param {number} totalPages Total de páginas
 * @returns {Array<number|string>} Números de página y '…' como separador
 */
export function getPageItems(page, totalPages) {
  if (totalPages <= 7) {
    return Array.from({ length: totalPages }, (_, i) => i + 1);
  }
  const items = [1];
  const start = Math.max(2, page - 1);
  const end = Math.min(totalPages - 1, page + 1);
  if (start > 2) items.push('…');
  for (let p = start; p <= end; p++) items.push(p);
  if (end < totalPages - 1) items.push('…');
  items.push(totalPages);
  return items;
}

/**
 * Pagination — Navegación de páginas para listados paginados.
 *
 * @component
 * @param {number}  props.paginaActual      Página actual (1-based)
 * @param {number}  props.totalPaginas      Total de páginas
 * @param {Function} props.onCambiarPagina  Callback (nuevaPagina) => void
 * @param {number}  [props.total]           Total de registros (muestra contador)
 * @param {number}  [props.limit]           Registros por página (para el contador)
 * @param {Function} [props.onLimitChange]  Callback (nuevoLimite) => void (muestra selector)
 * @param {boolean} [props.isLoading]       Deshabilita controles durante la carga
 *
 * @example
 * <Pagination
 *   paginaActual={page}
 *   totalPaginas={totalPages}
 *   onCambiarPagina={setPage}
 *   total={total}
 *   limit={pageSize}
 *   onLimitChange={setPageSize}
 *   isLoading={isLoading}
 * />
 */
const Pagination = ({
  paginaActual,
  totalPaginas,
  onCambiarPagina,
  total,
  limit,
  onLimitChange,
  isLoading = false,
}) => {
  // No renderizar si solo hay una página o ninguna
  if (!totalPaginas || totalPaginas <= 1) {
    return null;
  }

  const page = paginaActual;
  const showCounter = Number.isFinite(total) && Number.isFinite(limit) && total > 0;
  const items = getPageItems(page, totalPaginas);
  const from = (page - 1) * limit + 1;
  const to = Math.min(page * limit, total);

  const baseBtn =
    'inline-flex h-9 min-w-9 items-center justify-center rounded-md border px-2 text-sm font-medium transition-colors disabled:cursor-not-allowed disabled:opacity-40';

  return (
    <nav
      aria-label="Paginación"
      role="navigation"
      className="flex flex-col items-center justify-between gap-4 border-t border-border pt-5 mt-6 sm:flex-row"
    >
      {/* Contador de resultados */}
      {showCounter && (
        <p className="text-sm text-muted-foreground">
          Mostrando{' '}
          <span className="font-semibold text-foreground">
            {from}–{to}
          </span>{' '}
          de{' '}
          <span className="font-semibold text-foreground">{total}</span>{' '}
          resultados
        </p>
      )}

      <div className="flex items-center gap-3">
        {/* Selector de tamaño de página */}
        {onLimitChange && (
          <label className="hidden items-center gap-2 text-sm text-muted-foreground sm:flex">
            Por página
            <select
              value={limit}
              disabled={isLoading}
              onChange={(e) => onLimitChange(Number(e.target.value))}
              className="h-9 rounded-md border border-border bg-card px-2 text-sm text-foreground outline-none focus:border-[#893d46]"
            >
              {[12, 24, 48].map((n) => (
                <option key={n} value={n}>
                  {n}
                </option>
              ))}
            </select>
          </label>
        )}

        <div className="flex flex-wrap items-center justify-center gap-1">
          {/* Anterior */}
          <Button
            variant="outline"
            size="sm"
            onClick={() => onCambiarPagina(page - 1)}
            disabled={isLoading || page <= 1}
            aria-label="Página anterior"
            className="px-2"
          >
            <ChevronLeft className="h-4 w-4" />
          </Button>

          {/* Números de página con elipsis */}
          {items.map((item, idx) =>
            item === '…' ? (
              <span key={`ellipsis-${idx}`} className="px-1 text-sm text-muted-foreground">
                …
              </span>
            ) : (
              <Button
                key={item}
                variant={item === page ? 'default' : 'outline'}
                size="sm"
                onClick={() => onCambiarPagina(item)}
                disabled={isLoading || item === page}
                aria-label={`Ir a página ${item}`}
                aria-current={item === page ? 'page' : undefined}
                className={`min-w-9 px-2 ${item === page ? '' : 'hover:border-[#893d46] hover:text-[#893d46]'}`}
              >
                {item}
              </Button>
            ),
          )}

          {/* Siguiente */}
          <Button
            variant="outline"
            size="sm"
            onClick={() => onCambiarPagina(page + 1)}
            disabled={isLoading || page >= totalPaginas}
            aria-label="Página siguiente"
            className="px-2"
          >
            <ChevronRight className="h-4 w-4" />
          </Button>
        </div>
      </div>
    </nav>
  );
};

export default Pagination;
