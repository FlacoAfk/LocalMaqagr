# Guía de prueba del instalador de MaqAgr

Esta guía sirve para validar el instalador de Windows y las funciones principales de la aplicación antes de entregar la versión.

## 1. Preparación

1. Usa Windows de 64 bits. Si es posible, prueba primero en una máquina virtual o en un perfil/PC limpio.
2. Evita probar mientras otro servicio use los puertos `4000` (aplicación) o `5435` (PostgreSQL local de MaqAgr).
3. Guarda el archivo `MaqAgr-Setup.exe` en una carpeta local. La instalación requiere permisos de administrador.
4. **Verifica el paquete antes de instalar.** Build verificado del 2026-10-15:

   - Tamaño: **426.760.044 bytes (407 MB)**
   - Versión embebida: **1.4.1**
   - SHA-256: `74E7B13CE7DBA0F74A954C412C5B9B702318CA43201E8F0E64AB1C3BB0120833`

   Comprueba con PowerShell:
   `Get-FileHash .\MaqAgr-Setup.exe -Algorithm SHA256`
   Si el hash no coincide, el archivo está incompleto o corrupto: no lo instales.
5. Si ya había una instalación, ten presente que la base de datos, los archivos subidos y las claves locales se conservan al desinstalar; una reinstalación puede reutilizar datos anteriores.

## 2. Instalar y arrancar

1. Ejecuta `MaqAgr-Setup.exe` como administrador.
2. Acepta la carpeta sugerida o elige otra. Puedes marcar la creación del acceso directo del escritorio.
3. Al finalizar, deja marcada la opción para iniciar MaqAgr. Se abrirá una consola del lanzador y el navegador.
4. Espera a que la consola indique que el servicio está listo. No cierres esa consola durante la prueba.
5. Abre `http://localhost:4000` si el navegador no se abrió automáticamente.
6. Comprueba la salud del servidor en `http://localhost:4000/health`; debe responder con estado correcto, no con error de conexión.

**Resultado esperado:** la portada carga, las rutas internas funcionan al recargarlas y no aparece una pantalla en blanco ni un error de API persistente.

## 3. Navegación pública y catálogos

1. Recorre Inicio, Calculadora, Sobre nosotros y los catálogos.
2. En Catálogo de tractores y Catálogo de maquinaria, prueba búsqueda, filtros, paginación y abrir el detalle de un resultado.
3. Regresa desde el detalle y comprueba que la navegación sigue funcionando.
4. Verifica que las imágenes carguen o que, cuando falte una imagen, se muestre un reemplazo sin romper la página.

**Resultado esperado:** las listas muestran datos, los controles cambian los resultados y los detalles corresponden al elemento elegido.

## 4. Registro, acceso y perfil

1. Registra un usuario de prueba con un correo nuevo que puedas reconocer; el registro crea un usuario normal, no administrador.
2. Cierra sesión y vuelve a iniciar con ese usuario.
3. En Perfil, cambia nombre/datos permitidos y comprueba que se reflejen al volver a entrar.
4. Si la pantalla lo permite, cambia la contraseña y valida el acceso con la nueva; la antigua debe dejar de funcionar.
5. Revisa el enlace de recuperación de contraseña. No des por hecho que llegará un correo: el envío depende de que haya un servicio de correo configurado.
6. Intenta abrir una ruta administrativa sin sesión y luego con el usuario normal. Debe bloquear el acceso, no mostrar datos de administración.

**Resultado esperado:** registro e inicio de sesión persisten; la autorización distingue usuario normal de administrador.

## 5. Calculadora de tractor — verificar los cuatro tipos de tracción

1. Abre **Calculadora → Tengo tractor**.
2. En el paso de datos del motor, completa los campos obligatorios y cambia **Tipo de tracción**. Deben estar disponibles:
   - Tracción trasera (4x2 / 2WD)
   - Tracción delantera auxiliar (MFWD)
   - Tracción en las cuatro ruedas (4x4 / 4WD)
   - Tracción por orugas
3. Para comparar, conserva iguales potencia, peso, llantas, suelo y condiciones; cambia únicamente la tracción y completa el cálculo para cada opción.
4. En el paso de llantas y suelo, completa los datos requeridos. Comprueba avanzar y volver sin perder lo ya ingresado.
5. En clima y terreno, completa altitud, temperatura, pendiente, patinamiento y velocidad de trabajo (y cualquier otro campo obligatorio que indique la pantalla).
6. Calcula y revisa que aparezcan resultados numéricos y el desglose de pérdidas/eficiencia. Repite el cálculo con cada tipo de tracción y comprueba que la opción elegida se conserve y se use en el resultado.
7. Usa **Volver/Editar** y **Limpiar/Reiniciar** si están disponibles; verifica que volver conserve el borrador y reiniciar lo deje en el estado inicial.
8. Repite dejando vacío un campo obligatorio y con un valor inválido. Debe avisar qué corregir sin bloquear la aplicación.

**Resultado esperado:** se puede seleccionar cada tracción; el flujo llega a resultados y cambiar la tracción afecta los parámetros de eficiencia/resistencia según el cálculo, sin exigir un tractor del catálogo.

## 6. Calculadora de implemento y recomendación

1. Abre **Calculadora → Tengo maquinaria/implemento**.
2. Completa tipo de implemento, ancho/profundidad de trabajo, peso y los demás campos requeridos; elige el suelo/condición solicitados.
3. Calcula la potencia requerida y revisa que se muestren el resultado y sus unidades.
4. Prueba un formulario incompleto y valores fuera de rango: debe señalar el campo y permitir corregirlo.
5. Abre **Busco equipo** (si está habilitado para la sesión), ejecuta una recomendación y confirma que devuelve resultados o un estado vacío explicativo, no una pantalla rota.

## 7. Administración y CRUD — requiere una cuenta administradora

El SQL de instalación contiene cuentas de rol administrador, pero el repositorio no documenta una contraseña válida para esas cuentas. **No adivines ni uses una contraseña supuesta.** Para completar esta sección, pide al responsable del proyecto credenciales de prueba autorizadas. El registro público crea usuarios normales.

Con una cuenta administradora autorizada:

1. Abre el panel, estadísticas y gestión de usuarios; comprueba que carguen.
2. Crea un tractor de prueba con nombre/modelo inequívocos y tipo de tracción. Guárdalo y búscalo en el catálogo.
3. Edita el tractor y confirma que los cambios aparecen tanto en administración como en el detalle público.
4. Sube una imagen, verifica su visualización; luego quítala y confirma que se use el reemplazo.
5. Crea un implemento de prueba, edítalo y comprueba que aparece en el catálogo.
6. Prueba las operaciones de usuarios habilitadas (estado/rol) solo sobre una cuenta de prueba, nunca sobre el administrador principal.
7. Elimina o desactiva únicamente los registros de prueba y verifica el resultado en las listas.

## 8. Persistencia, cierre y reinstalación

1. Registra datos de prueba y, si tienes permiso administrativo, crea un registro de catálogo.
2. Cierra el navegador. Luego cierra la consola del lanzador normalmente y espera a que termine.
3. Inicia de nuevo desde el acceso directo y comprueba que la aplicación arranque y conserve los datos.
4. Desinstala solo después de guardar lo que necesites. El desinstalador conserva intencionalmente la base de datos, imágenes subidas y la clave JWT local en las carpetas de datos; no las borres si necesitas mantener los datos.

## 9. Si algo falla

- **Error 4551 "Una directiva de Control de aplicaciones bloqueó este archivo" (carpeta temporal)**: el equipo destino tiene **Smart App Control** (Windows 11) o una política **AppLocker/ASR** que bloquea ejecutables sin firma digital. Soluciones:
  1. Desactivar Smart App Control en ese equipo: **Configuración → Privacidad y seguridad → Seguridad de Windows → Control de aplicaciones y navegador → Configuración de Control de aplicaciones inteligentes → Desactivar**, y volver a ejecutar el instalador. (Aviso: una vez desactivado, no se puede reactivar sin reinstalar/restablecer Windows.)
  2. Si el equipo es administrado por una organización (AppLocker), pedir a TI una exclusión para `MaqAgr-Setup.exe`.
  3. Si había una versión anterior de MaqAgr instalada, desinstálala primero desde **Configuración → Aplicaciones** (el instalador ejecuta el desinstalador viejo desde la carpeta temporal, que es justo lo que la política bloquea).
  4. Solución definitiva del proyecto: **firmar digitalmente** el instalador con un certificado de firma de código (elimina estos bloqueos y SmartScreen de raíz).
- Si no abre: comprueba que la consola terminó el arranque y que los puertos `4000`/`5435` estén libres.
- Si el backend no arranca con `ERR_MODULE_NOT_FOUND: Cannot find package 'detect-libc' … sharp`: al copiar `node_modules`, Inno Setup rompe los enlaces de pnpm y sharp pierde una dependencia. Arreglo (PowerShell **como administrador**):
  ```powershell
  robocopy "C:\Users\elkaw\Desktop\MaqAgr-Local\backend\node_modules\.pnpm\sharp@0.35.5_@types+node@25.9.3\node_modules" "C:\Program Files\MaqAgr\app\backend\node_modules" /E
  ```
  Luego cierra la consola de MaqAgr y vuelve a arrancarla. (Este paso ya quedó integrado en el workflow de CI para futuros instaladores.)
- Si la API falla: consulta los logs en `%ProgramData%\MaqAgr\logs\` (incluye `postgresql.log` cuando aplique).
- Los mensajes `NOTICE: la columna … ya existe, omitiendo` durante el arranque son normales (migraciones idempotentes); PowerShell los muestra como error porque psql escribe en stderr, pero no detienen nada.
- Los datos locales están en `%ProgramData%\MaqAgr\`; no borres `pgdata` para “arreglar” un error sin una copia de seguridad.
- Al reportar un fallo, anota el paso, hora, resultado esperado/obtenido y adjunta captura; comparte los logs solo con quien esté autorizado.

## Registro de resultados

Marca cada sección como **Correcta**, **Fallida** o **No probada**. Para cada fallo conserva: paso, datos usados (sin contraseñas), hora, mensaje/captura y archivo de log relacionado.
