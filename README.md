# Turno Handling

PWA personal, offline-first y sin servidor para fichar jornadas y organizar trabajo de handling. Todos los datos se guardan en IndexedDB dentro del dispositivo. No hay login, base de datos online ni llamadas a APIs externas.

## Funciones

- Fichar entrada y salida, corregir horas y calcular totales.
- Seis paneles de trabajo: Logística, Equipo y Muelle, cada uno con NET y Satélite.
- Añadir parking, vuelo, LIMAS, número de remolques y notas de maquinaria con estado Pendiente/Hecho.
- Cierre automático al fichar salida y cierre manual.
- Historial por año, mes y día con buscador.
- Horario de próximos turnos y avisos dentro de la app.
- Apartado de mapas del aeropuerto con imágenes guardadas offline.
- Estadísticas mensuales y anuales.
- Exportación/restauración JSON y exportación mensual CSV.
- Service worker, caché de todos los recursos e IndexedDB.

## Estructura

```text
turno-handling/
├── icons/
│   ├── apple-touch-icon.png
│   ├── icon-192.png
│   ├── icon-512.png
│   └── icon.svg
├── js/
│   ├── app.js
│   └── db.js
├── Abrir-Turno-Handling-Windows.bat
├── index.html
├── manifest.webmanifest
├── servidor-local.ps1
├── styles.css
├── sw.js
└── README.md
```

## Probar en Windows

No abras `index.html` con doble clic. El navegador puede mostrar la pantalla, pero bloquea partes de JavaScript y los botones no responden.

La forma sencilla:

1. Entra en la carpeta `turno-handling`.
2. Haz doble clic en `Abrir-Turno-Handling-Windows.bat`.
3. Se abrirá una ventana negra con un servidor local.
4. El navegador abrirá `http://127.0.0.1:8787/`.
5. No cierres la ventana negra mientras uses la app en Windows.

Forma manual, si prefieres usar Python:

Con Python instalado:

```powershell
cd "C:\ruta\a\turno-handling"
py -m http.server 8080
```

Si el comando `py` no existe:

```powershell
python -m http.server 8080
```

Abre `http://localhost:8080`. En Edge o Chrome, abre las herramientas de desarrollo, entra en `Application > Service Workers` y comprueba que `sw.js` aparece activado.

Para probar sin internet en el ordenador:

1. Abre la app una vez con el servidor funcionando.
2. En DevTools, entra en `Network` y activa `Offline`.
3. Recarga la página.
4. Añade un vuelo, cambia su estado y recarga otra vez. Los datos deben seguir ahí.

## Abrir e instalar en iPhone

Los service workers necesitan HTTPS en el iPhone. Una dirección como `http://192.168.x.x:8080` sirve para ver la interfaz en la red local, pero no es suficiente para una instalación offline fiable.

La opción sencilla desde Windows es publicar esta carpeta como sitio estático con HTTPS, por ejemplo en GitHub Pages. En el plan gratuito, lo habitual es usar un repositorio público: el código será visible, pero la app no incluye tus fichajes ni tu historial porque esos datos se quedan en el iPhone.

1. Crea un repositorio y sube el contenido de `turno-handling`.
2. Activa GitHub Pages para la rama donde estén los archivos.
3. Espera a que aparezca la dirección `https://...github.io/...`.
4. Abre esa dirección en Safari en el iPhone.
5. Toca `Compartir`.
6. Toca `Añadir a pantalla de inicio`.
7. Confirma `Turno Handling` y abre la app desde su nuevo icono.
8. Mantén la app abierta unos segundos la primera vez para completar la caché.

El alojamiento solo entrega los archivos de la aplicación. Los fichajes, vuelos e historial permanecen en IndexedDB en el iPhone y no se suben a ese alojamiento.

Documentación oficial:

- [Crear un sitio de GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/creating-a-github-pages-site)
- [Configurar la rama de publicación](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site)
- [Convertir un sitio web en app desde Safari](https://support.apple.com/guide/iphone/open-as-web-app-iphea86e5236/ios)

## Comprobar el modo offline en iPhone

1. Instala y abre la app desde la pantalla de inicio al menos una vez con internet.
2. Añade un registro de prueba.
3. Activa el modo avión y desactiva también Wi-Fi.
4. Cierra y vuelve a abrir Turno Handling desde su icono.
5. Debe aparecer `Sin conexión · trabajando en modo offline`.
6. Comprueba que puedes fichar, añadir vuelos, cambiar estados y consultar el historial.

## Copias de seguridad

En `Más > Copias de seguridad`:

- `Exportar copia JSON` guarda todos los datos, incluidos los mapas importados.
- `Importar o restaurar JSON` reemplaza los datos locales por una copia.
- `Exportar historial mensual` crea un CSV para Excel.

Guarda periódicamente el JSON en Archivos, iCloud Drive u otra ubicación personal. Si Safari borra los datos del sitio o cambias de iPhone, restaura ese archivo desde la propia app.

## Mapas del aeropuerto

En la pestaña `Mapas` puedes guardar fotos o capturas de mapas del aeropuerto:

1. Toca `Mapas`.
2. Toca `Añadir mapa`.
3. Escribe un nombre, por ejemplo `Parkings T4` o `Muelle`.
4. Selecciona una imagen desde Fotos o Archivos.
5. Toca `Guardar mapa`.

Los mapas se guardan dentro de IndexedDB, igual que los fichajes. Después de importarlos podrás abrirlos sin internet desde la pestaña `Mapas` o desde el acceso rápido de Inicio.

## Modificar categorías o nombres

Las categorías están al principio de `js/app.js`, en la constante `CATEGORIES`:

```js
const CATEGORIES = [
  { id: "logistica", name: "Logística", sections: ["NET", "SATÉLITE"] },
  { id: "equipo", name: "Equipo", sections: ["NET", "SATÉLITE"] },
  { id: "muelle", name: "Muelle", sections: ["NET", "SATÉLITE"] }
];
```

Puedes cambiar los textos `name` y `sections`. Mantén estables los valores `id` si ya tienes historial, porque se usan para identificar cada categoría guardada.

Los colores están en `styles.css`, dentro de `:root` y de las reglas `.category-card.logistica`, `.category-card.equipo` y `.category-card.muelle`.

Después de modificar archivos cambia `CACHE_NAME` en `sw.js` (por ejemplo, de `v1.2.0` a `v1.2.1`) para que los dispositivos descarguen la nueva versión.

## Límites de las notificaciones

Los avisos dentro de la aplicación funcionan siempre. iOS no permite programar notificaciones futuras puramente locales con una PWA cerrada sin usar un servicio push. El botón `Activar avisos` muestra notificaciones compatibles mientras la aplicación está activa; la operativa offline y los datos no dependen de ellas.
