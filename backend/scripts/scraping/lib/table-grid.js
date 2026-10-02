/**
 * Convierte una tabla HTML (con rowspan/colspan) en una matriz completa,
 * expandiendo las celdas fusionadas — necesario para las tablas de
 * especificaciones de Baldan/WooCommerce (encabezados de 2 niveles).
 */
import { stripTags } from './html.js';

export function tableToGrid(tableHtml) {
  const rows = [...tableHtml.matchAll(/<tr[^>]*>([\s\S]*?)<\/tr>/gi)].map((m) => m[1]);
  const grid = [];

  rows.forEach((rowHtml, r) => {
    grid[r] = grid[r] || [];
    let c = 0;
    const cellRe =
      /<t([hd])([^>]*)>([\s\S]*?)<\/t\1>/gi;
    let m;
    while ((m = cellRe.exec(rowHtml)) !== null) {
      const attrs = m[2] || '';
      const rowspan = parseInt((attrs.match(/rowspan="(\d+)"/i) || [])[1] || '1', 10);
      const colspan = parseInt((attrs.match(/colspan="(\d+)"/i) || [])[1] || '1', 10);
      const text = stripTags(m[3]);
      while (grid[r][c] !== undefined) c++;
      for (let dr = 0; dr < rowspan; dr++) {
        for (let dc = 0; dc < colspan; dc++) {
          grid[r + dr] = grid[r + dr] || [];
          grid[r + dr][c + dc] = text;
        }
      }
      c += colspan;
    }
  });

  // Normaliza ancho de filas
  const width = Math.max(...grid.map((g) => g.length));
  for (const g of grid) for (let i = 0; i < width; i++) if (g[i] === undefined) g[i] = '';
  return grid;
}

/**
 * Une encabezados de 2 niveles: fila 0 con grupos ("Peso Aproximado (kg)") y
 * fila 1 con subcolumnas ("26″") → "Peso Aproximado (kg) 26″".
 * Devuelve null si la tabla no parece tener encabezado doble.
 */
export function mergeHeaderRows(grid, maxLevels = 2) {
  if (grid.length < 2) return null;
  // La fila 0 es un encabezado agrupado si tiene celdas repetidas adyacentes
  // (p. ej. "Peso Aproximado (kg)" expandido con rowspan sobre 26″/28″/30″)
  const hasGroups = grid[0].some((c, i) => c && c !== '' && grid[0][i + 1] === c);
  if (!hasGroups) return null;
  const headers = [];
  for (let c = 0; c < grid[0].length; c++) {
    const parts = [grid[0][c], grid[1][c]].map((s) => s.trim()).filter(Boolean);
    headers.push([...new Set(parts)].join(' '));
  }
  return { headers, dataRows: grid.slice(2) };
}

export function tablesFromHtml(html) {
  return [...html.matchAll(/<table[\s\S]*?<\/table>/gi)].map((m) => m[0]);
}
