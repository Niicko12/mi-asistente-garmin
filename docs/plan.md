# Mi Asistente --- Garmin fēnix 8

## Documento de visión, arquitectura y plan de desarrollo

**Versión:** 0.2\
**Fecha:** 2026-10-21\
**Estado:** Propuesta revisada contra el mockup «Garmin Fenix 8 UI Showcase»\
**Plataforma objetivo:** Garmin fēnix 8 mediante Garmin Connect IQ\
**Proyecto relacionado:** Asistente personal existente en Anbernic
RG353V\
**Principio de diseño:** ampliar el reloj con asistencia personal
contextual, no duplicar funciones que Garmin ya ofrece.

### Cambios respecto a v0.1

-   Nueva sección 3: revisión del mockup pantalla por pantalla, con
    decisión y fase asignada.
-   Nueva sección 5: restricciones técnicas de Connect IQ que afectan
    al diseño (voz, tipos de app, red, fuentes, almacenamiento, entrada
    de texto).
-   La voz deja de ser entrada principal; pasa a ser una hipótesis que
    se valida en la Fase 1.
-   La pantalla en reposo (watch face) se separa como proyecto
    opcional posterior.
-   Se corrigen textos del mockup que contradicen la regla de no
    inferir estados emocionales.
-   Se añade la opción de app complementaria en el iPhone como capa de
    integración.
-   Se añaden pantallas «Japonés» y «Tareas» al alcance, en fases
    posteriores al MVP.

------------------------------------------------------------------------

## 1. Visión del producto

Crear una extensión de muñeca para el asistente personal que ya funciona
en la Anbernic RG353V. El Garmin será una interfaz compacta para
consultar el estado del asistente, capturar ideas, acceder a memoria de
proyectos y recibir respuestas breves. La lógica existente se
reutilizará cuando sea viable; la interfaz del reloj se desarrollará
específicamente para Connect IQ.

El producto no debe ser otra colección de widgets genéricos. Su valor
diferencial será la combinación de:

1.  **Memoria personal y de proyectos:** recordar notas y el siguiente
    paso de proyectos registrados.
2.  **Interacción con IA:** enviar preguntas cortas y mostrar respuestas
    resumidas.
3.  **Estado del asistente:** un personaje visual con ojos y estados
    expresivos, elegido según el estado operativo o una preferencia
    explícita del usuario.
4.  **Captura rápida:** guardar ideas y tareas para sincronizarlas con
    el asistente principal.
5.  **Asistencia contextual y configurable:** ofrecer un resumen breve a
    partir de tareas y contexto que el usuario haya registrado, sin
    inundar de notificaciones.
6.  **Continuidad entre dispositivos:** compartir memoria y datos con el
    asistente de la Anbernic mediante un servicio común, si la
    arquitectura actual lo permite.
7.  **Práctica de japonés (posterior al MVP):** tarjetas breves de
    frases y vocabulario N5 sincronizadas con el asistente.

### Fuera del objetivo inicial

-   Reemplazar Garmin Connect, Garmin Coach, el calendario, el clima,
    las alarmas, los temporizadores o las métricas nativas.
-   Crear un asistente de voz completo ejecutándose íntegramente en el
    reloj.
-   Depender de entrada de voz antes de confirmar que Connect IQ la
    permite.
-   Garantizar funcionamiento de IA sin conexión.
-   Interpretar el estado emocional, la energía, el estrés o la salud
    mental del usuario a partir de sensores. Los estados de ánimo serán
    expresivos, configurables o derivados de estados explícitos del
    asistente; no diagnósticos.
-   Generar rutinas de entrenamiento «según tu estado».

------------------------------------------------------------------------

## 2. Experiencia de usuario

### Pantalla principal

-   Avatar/ojos del asistente como elemento central.
-   Estado breve: «Estoy aquí», «Pensando», «Sin conexión» o «Necesito
    sincronizar».
-   Accesos a **Preguntar**, **Nota rápida**, **Proyectos** y
    **Resumen**.
-   Indicador de conexión y de datos pendientes de sincronización.
-   **Sin** hora, clima ni batería grandes: ya los muestra la esfera
    nativa. Como mucho, un indicador pequeño de conexión.

### Estados visuales del asistente

  -----------------------------------------------------------------------
  Estado                  Significado             Comportamiento visual
  ----------------------- ----------------------- -----------------------
  Disponible              Puede recibir una       Ojos abiertos,
                          acción                  animación discreta

  Escuchando              Entrada de voz iniciada Ojos atentos /
                          por el usuario. Solo si indicador de escucha
                          la Fase 1 confirma una  
                          API compatible          

  Pensando                Petición en proceso     Ojos concentrados /
                                                  animación breve

  Respondiendo            Hay una respuesta lista Ojos activos y texto
                                                  resumido

  Contento                Estado cosmético        Ojos curvos / brillo
                          seleccionado o evento   suave
                          positivo explícito      

  Tranquilo               Estado neutral o        Ojos relajados
                          preferencia del usuario 

  Ocupado                 Hay una tarea en        Ojos enfocados
                          proceso                 

  Sin conexión            No se puede llegar al   Ojos apagados o icono
                          servicio                de desconexión

  Error                   Falló una petición      Ojos de alerta,
                                                  explicación corta y
                                                  opción de reintentar
  -----------------------------------------------------------------------

**Regla de producto:** los ojos expresan el estado del asistente, no
afirman conocer automáticamente las emociones reales de la persona.

**Regla de texto:** ninguna pantalla dirá «analizo tu energía», «tu
estrés», «tu estado en tiempo real» ni frases equivalentes. Las
sugerencias se basan en tareas y contexto que el usuario registró.

### Pantallas previstas (revisadas)

1.  Inicio / avatar.
2.  Preguntar a la IA.
3.  Respuesta breve / chat de un turno.
4.  Nota rápida.
5.  Memoria de proyectos.
6.  Resumen del día.
7.  Tareas guardadas.
8.  Estado de conexión y sincronización.
9.  Ajustes, expresión del asistente y privacidad.
10. Japonés (posterior al MVP).

Las pantallas exactas se reducirán según el tamaño de pantalla, la
navegación física y los límites reales del fēnix 8.

------------------------------------------------------------------------

## 3. Revisión del mockup pantalla por pantalla

Referencia: imagen «Mi Asistente: Garmin Fenix 8 UI Showcase» (15
pantallas).

  -----------------------------------------------------------------------
  \#   Pantalla del mockup  Decisión        Cambios necesarios       Fase
  ---- -------------------- --------------- ------------------------ -----
  1    Pantalla principal   Modificar       Quitar hora grande,      0.1
                                            clima y ciudad. El       
                                            avatar pasa al centro.   
                                            Botón de micrófono solo  
                                            si se valida voz.        

  2    Asistente de voz     Modificar       Renombrar a «Preguntar». 0.1 /
                                            Entrada inicial: lista   0.4
                                            de preguntas sugeridas   
                                            o `TextPicker`. Onda de  
                                            audio solo si hay voz.   

  3    Estado de ánimo      Modificar       Renombrar a «Estado del  0.5
                                            asistente». Eliminar el  
                                            texto «analiza tu        
                                            energía, estrés». Las    
                                            sugerencias salen de     
                                            tareas registradas.      

  4    Resumen del día      Mantener        Datos del backend, no    0.4
                                            del calendario nativo.   
                                            «Entrenamiento 21:00»    
                                            solo si el usuario lo    
                                            registró como tarea.     

  5    Tareas y             Mantener        «Nueva tarea» con        0.2
       recordatorios                        plantillas o             
                                            `TextPicker`. Sin        
                                            alarmas propias: los     
                                            recordatorios llegan     
                                            como notificación del    
                                            teléfono.                

  6    Japonés              Posponer        Requiere fuente          0.6
                                            personalizada con kana   
                                            y kanji. «Escuchar»      
                                            depende de audio, que    
                                            no está validado.        

  7    Memoria de proyectos Mantener        Núcleo diferencial.      0.2
                                            Datos de ejemplo en      
                                            0.2, reales en 0.4.      

  8    Notas rápidas        Mantener        Micrófono solo si se     0.2
                                            valida. Alternativa:     
                                            plantillas, `TextPicker` 
                                            o dictado desde el       
                                            iPhone.                  

  9    Estado del sistema   Modificar       Quitar «Espacio 8.4 GB / 0.1
                                            16 GB»: una app no ve    
                                            el almacenamiento total. 
                                            Mostrar: conexión con    
                                            teléfono, último sync,   
                                            pendientes y cuota       
                                            propia.                  

  10   Entrenamiento        Descartar       Duplica Garmin Coach e   ---
                                            insinúa inferencia por   
                                            sensores.                

  11   Conversación con IA  Mantener        Un turno por pantalla.   0.4
                                            Respuesta resumida en    
                                            el backend (límite de    
                                            caracteres).             

  12   Conexión con         Modificar       El reloj no ve la        0.3
       Anbernic                             Anbernic. El estado de   
                                            cada dispositivo lo      
                                            informa el backend. Sin  
                                            «Configurar» en el       
                                            reloj: se hace en el     
                                            teléfono.                

  13   Acciones rápidas     Modificar       Quitar «Temporizador» y  0.2
                                            «Ver clima». Dejar       
                                            «Nota», «Preguntar»,     
                                            «Proyecto actual».       

  14   Clima                Descartar       Duplica la función       ---
                                            nativa.                  

  15   Pantalla en reposo   Posponer        Es una watch face, otro  0.7
                                            tipo de app. Proyecto    (opc.)
                                            separado y opcional.     
  -----------------------------------------------------------------------

Resumen: 5 se mantienen, 6 se modifican, 2 se posponen y 2 se
descartan.

### Encabezado del mockup

-   «Conversación con IA: Habla, escribe o usa la voz» pasa a «Pregunta
    y recibe respuestas breves».
-   «Estado de ánimo: Tu estado, en tiempo real» pasa a «Estado del
    asistente: expresiones que tú eliges».
-   «Más que un reloj, por un asistente que te entiende» se revisa para
    no sugerir comprensión emocional.

------------------------------------------------------------------------

## 4. Qué aporta frente a Garmin

  -----------------------------------------------------------------------
  Función                 Garmin ya ofrece        Valor añadido de Mi
                          funciones similares     Asistente
  ----------------------- ----------------------- -----------------------
  Hora, clima, alarmas y  Sí                      Ninguno. No se
  temporizadores                                  incluyen en la app

  Datos de actividad y    Sí, según función y     Usarlos solo si hay una
  salud                   configuración           API y permisos
                                                  adecuados; nunca para
                                                  inferir emociones

  Entrenamiento           Sí (Garmin Coach,       Ninguno. Fuera de
                          sugerencias diarias)    alcance

  Tareas/notas personales Parcialmente mediante   Una memoria unificada
                          apps y ecosistema       con los proyectos del
                                                  usuario

  IA conversacional       No equivale a un        Preguntas sobre notas,
                          asistente personal con  proyectos y contexto
                          la memoria propia del   guardado
                          proyecto                

  Memoria de proyectos    No es el objetivo       Recuperar estado,
                          principal de Garmin     decisiones y próximo
                                                  paso

  Avatar con ojos y       No es la experiencia    Identidad visual
  estados                 central del reloj       persistente del
                                                  asistente

  Práctica de japonés     No                      Tarjetas breves
                                                  sincronizadas con el
                                                  asistente

  Continuidad             No es una función       Sincronización mediante
  Anbernic--Garmin        nativa garantizada      backend o puente
                                                  compatible
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## 5. Restricciones técnicas de Connect IQ

Cada punto debe confirmarse en la Fase 1 con el SDK vigente y el modelo
exacto. Hasta entonces se tratan como hipótesis de diseño.

> **Actualización 2026-10-21 (SDK 9.3.0):** la hipótesis de voz queda
> descartada. `Toybox.Audio.Capture` (API 6.0.3, permiso `AudioInput`)
> permite capturar audio en device apps en primer plano. Las fuentes
> del sistema probablemente incluyen glifos japoneses. Detalle e
> impacto en `docs/capability-validation.md`.

  -----------------------------------------------------------------------
  Tema                Restricción esperada        Consecuencia de diseño
  ------------------- --------------------------- -----------------------
  Voz / micrófono     No se conoce una API        La voz no es entrada
                      pública de Connect IQ que   principal. Se diseña
                      dé acceso al micrófono a    primero con toques,
                      apps de terceros. El        botones y texto
                      micrófono del fēnix 8 lo    predefinido
                      usan funciones nativas      

  Tipos de app        Device app, widget/glance,  La app principal es
                      data field y watch face son una device app (con
                      proyectos distintos con     glance opcional). La
                      permisos distintos          pantalla en reposo es
                                                  otro proyecto

  Red                 `makeWebRequest` sale por   Sin teléfono cercano
                      la app Garmin Connect del   no hay IA. Estado «Sin
                      teléfono vía Bluetooth.     conexión» obligatorio.
                      Solo HTTPS y respuestas     Respuestas cortas en
                      JSON de tamaño limitado     JSON

  Segundo plano       Los servicios en segundo    Sincronización bajo
                      plano tienen intervalo      demanda; nada de
                      mínimo (eventos temporales  polling frecuente
                      de ~5 min) y memoria        
                      reducida                    

  Almacenamiento      `Application.Storage` tiene Guardar solo notas
                      cuota propia limitada; la   recientes y caché de
                      app no ve el almacenamiento proyectos. Medir la
                      total del reloj             cuota real

  Entrada de texto    `TextPicker` existe pero es Plantillas, respuestas
                      lento en la muñeca          sugeridas y captura
                                                  larga desde el iPhone

  Fuentes             Las fuentes del sistema     Fuente personalizada
                      probablemente no incluyen   con subconjunto de
                      kana/kanji                  caracteres, o
                                                  imágenes. Medir memoria

  Memoria de app      Límite de memoria por tipo  Animaciones de ojos
                      de app y modelo             con primitivas de
                                                  dibujo, no con muchos
                                                  bitmaps

  Autenticación       Sin secretos en el `.prg`.  Token por dispositivo
                      Existen `makeOAuthRequest`  emitido por el
                      y ajustes de app en         backend; claves de IA
                      Garmin Connect              solo en el servidor

  Audio de salida     Capacidad de reproducir     «Escuchar» en japonés
                      audio desde Connect IQ por  queda fuera hasta
                      confirmar                   validar
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## 6. Arquitectura propuesta

``` text
┌──────────────────────────────┐
│ Garmin fēnix 8               │
│ Device app Connect IQ        │
│ (Monkey C)                   │
│ - Avatar y estados           │
│ - Menús y vistas compactas   │
│ - Cola local limitada        │
│ - Peticiones/respuestas JSON │
└──────────────┬───────────────┘
               │ Bluetooth
┌──────────────▼───────────────┐
│ iPhone                       │
│ Opción A: Garmin Connect     │
│   (proxy de makeWebRequest)  │
│ Opción B: app complementaria │
│   con Connect IQ Mobile SDK  │
│   (dictado, texto largo)     │
└──────────────┬───────────────┘
               │ HTTPS
┌──────────────▼───────────────┐
│ Servicio de integración      │
│ - API para el reloj          │
│ - Autenticación por token    │
│ - Resumen de respuestas      │
│ - Estado de dispositivos     │
└──────────────┬───────────────┘
               │
┌──────────────▼───────────────┐
│ Asistente existente          │
│ Anbernic RG353V              │
│ - Lógica que se pueda reusar │
│ - Memoria y herramientas     │
│ - Adaptador para nuevas UI   │
└──────────────┬───────────────┘
               │
┌──────────────▼───────────────┐
│ APIs / IA / almacenamiento   │
│ - Solo lo que ya se utilice  │
│ - Secretos fuera del reloj   │
└──────────────────────────────┘
```

**Opción A** es la más simple y no requiere app de iPhone. **Opción B**
añade dictado y captura de texto largo, pero suma un proyecto iOS. Se
empieza con A y se evalúa B después del MVP 0.4.

La Anbernic no es accesible desde el reloj ni necesariamente desde
internet. El servicio de integración debe ser alcanzable por HTTPS; si
el asistente vive solo en la Anbernic, hará falta sincronizarlo con un
servicio remoto o exponerlo de forma segura. Se decide tras la Fase 0.

### Principios técnicos

-   La app de Garmin será una interfaz nativa desarrollada con Connect
    IQ y Monkey C.
-   No se intentará ejecutar sin cambios el código de la Anbernic en el
    reloj.
-   Se reutilizarán lógica, prompts, modelos de datos y API cuando sean
    compatibles.
-   Las claves de IA y otros secretos no se incluirán en el archivo de
    la app del reloj.
-   El reloj deberá seguir ofreciendo una pantalla de estado y acceso a
    datos locales aunque no haya conexión.
-   El backend resume las respuestas; el reloj no recibe
    conversaciones largas.
-   Se limitarán tamaño de mensajes, tiempo de espera y cantidad de
    datos enviados.
-   El estado de sincronización será visible: actualizado, pendiente,
    desconectado o error.

------------------------------------------------------------------------

## 7. Alcance del MVP

La primera versión funcional será deliberadamente pequeña.

### MVP 0.1 --- App instalada y navegable

-   [ ] Proyecto Connect IQ creado y compilado para el modelo exacto.
-   [ ] Pantalla principal con avatar de ojos (mockup 1, modificada).
-   [ ] Estados visuales: disponible, pensando, desconectado y error.
-   [ ] Menú con Preguntar, Nota rápida, Proyectos y Estado.
-   [ ] Pantalla de estado sin datos falsos de almacenamiento (mockup
    9, modificada).
-   [ ] Datos de demostración claramente identificados como locales.
-   [ ] Navegación usable con botones y pantalla táctil.
-   [ ] Instalación y prueba en reloj real.
-   [ ] Informe de validación: micrófono, audio, fuentes CJK, cuota de
    almacenamiento y memoria disponible.

### MVP 0.2 --- Memoria local, notas y tareas

-   [ ] Crear una nota corta con plantillas o `TextPicker`.
-   [ ] Mostrar notas recientes guardadas localmente.
-   [ ] Lista de tareas con marcar como hecha (mockup 5).
-   [ ] Proyectos de ejemplo con «último avance» y «siguiente paso»
    (mockup 7).
-   [ ] Acciones rápidas sin funciones nativas duplicadas (mockup 13).
-   [ ] Manejar límite de caracteres y errores de almacenamiento.
-   [ ] Definir exportación/sincronización antes de prometer respaldo
    permanente.

### MVP 0.3 --- Integración con el asistente existente

-   [ ] Auditar el repositorio de la Anbernic.
-   [ ] Identificar lenguaje, punto de entrada, API, memoria y
    dependencias.
-   [ ] Decidir dónde vive el servicio de integración.
-   [ ] Definir un contrato de API estable para preguntas, notas,
    tareas y proyectos.
-   [ ] Implementar el adaptador de comunicación (opción A).
-   [ ] Pantalla de dispositivos con estado informado por el backend
    (mockup 12).
-   [ ] Mostrar estado de conexión, carga, timeout y reintento.
-   [ ] Verificar seguridad y autenticación.

### MVP 0.4 --- IA y memoria de proyectos

-   [ ] Enviar una pregunta breve (sugerida o escrita).
-   [ ] Recibir una respuesta resumida adecuada a la pantalla (mockup
    11).
-   [ ] Resumen del día desde el backend (mockup 4).
-   [ ] Consultar proyecto y siguiente paso con datos reales.
-   [ ] Evitar que el reloj reciba conversaciones extensas.
-   [ ] Medir latencia, consumo y tasa de error.
-   [ ] Evaluar la app complementaria de iPhone (opción B).

### MVP 0.5 --- Personalidad y contexto

-   [ ] Diseñar animaciones de ojos ligeras y estados coherentes.
-   [ ] Pantalla «Estado del asistente» con expresión seleccionable
    (mockup 3, modificada).
-   [ ] Añadir un resumen diario configurable.
-   [ ] Añadir recomendaciones solo con contexto registrado y si el
    usuario las habilitó.
-   [ ] No inferir estados emocionales sensibles a partir de métricas
    físicas.

### 0.6 --- Japonés (posterior al MVP)

-   [ ] Generar fuente con el subconjunto de caracteres necesario.
-   [ ] Tarjetas: japonés, romaji y traducción (mockup 6).
-   [ ] Mazo sincronizado desde el asistente.
-   [ ] Audio solo si la validación de 0.1 lo permite.

### 0.7 --- Watch face (opcional)

-   [ ] Proyecto separado con avatar en reposo (mockup 15).
-   [ ] Datos solo de caché; sin peticiones frecuentes.
-   [ ] Medir impacto en batería antes de publicar.

------------------------------------------------------------------------

## 8. Plan de desarrollo paso a paso

### Fase 0 --- Auditoría del proyecto actual

**Objetivo:** comprender el asistente que ya existe antes de elegir
arquitectura.

Entregables:

-   Inventario del repositorio y sus carpetas.
-   Lenguaje, framework y sistema operativo.
-   Diagrama de flujo de una petición.
-   APIs, servicios y almacenamiento que utiliza.
-   Dependencias que podrían impedir reutilizar la lógica.
-   Lista de funciones que ya están implementadas.
-   Dónde se ejecuta y si es accesible desde internet.

Criterio de salida: poder explicar cómo se inicia el asistente, cómo
recibe una petición y cómo genera una respuesta.

### Fase 1 --- Definición técnica y validación de capacidades

**Objetivo:** confirmar el camino compatible con el fēnix 8 y
convertir las hipótesis de la sección 5 en hechos.

Tareas:

1.  Confirmar variante exacta del fēnix 8 y versión de firmware.
2.  Instalar Garmin Connect IQ SDK y la extensión Monkey C.
3.  Configurar el simulador para el dispositivo objetivo.
4.  Crear una app mínima que abra y muestre texto.
5.  Verificar el método de despliegue y depuración en el dispositivo.
6.  Comprobar en la documentación del SDK vigente: acceso a micrófono,
    reproducción de audio, `TextPicker`, cuota de `Application.Storage`
    y memoria disponible para device apps.
7.  Probar una fuente personalizada con caracteres japoneses.
8.  Probar un `makeWebRequest` a un endpoint HTTPS de prueba.

Criterio de salida: app mínima en simulador y reloj, e informe de
validación con cada hipótesis marcada como confirmada o descartada.

### Fase 2 --- Prototipo visual

**Objetivo:** validar la interfaz antes de añadir IA.

Tareas:

1.  Implementar el avatar de ojos en varios estados.
2.  Construir navegación compacta.
3.  Probar contraste, legibilidad y accesibilidad.
4.  Evitar animaciones costosas y pantallas saturadas.
5.  Validar todas las vistas en el simulador y en el dispositivo.

Criterio de salida: navegación fluida y todos los estados visuales
funcionando sin red.

### Fase 3 --- Datos y persistencia

**Objetivo:** gestionar notas, tareas y proyectos sin depender todavía
de IA.

Tareas:

1.  Definir esquemas de `Note`, `Task`, `Project`, `ProjectUpdate` y
    `AssistantState`.
2.  Establecer límites de longitud y versión del formato.
3.  Implementar almacenamiento local donde esté soportado.
4.  Preparar datos de ejemplo para pruebas.
5.  Diseñar qué ocurre cuando se llena el almacenamiento o falla una
    escritura.

Criterio de salida: las notas, tareas y proyectos de prueba se pueden
consultar de forma fiable.

### Fase 4 --- Integración y conectividad

**Objetivo:** conectar la app del reloj con el sistema existente.

Tareas:

1.  Crear contrato de API documentado.
2.  Añadir un adaptador en el backend existente o un servicio separado.
3.  Configurar autenticación, límites de peticiones y validación de
    entradas.
4.  Implementar estados de conexión y reintentos controlados.
5.  Probar desconexión, timeout, respuesta malformada y servicio no
    disponible.
6.  Probar con el teléfono lejos, con Bluetooth apagado y con Garmin
    Connect cerrado.

Criterio de salida: una petición de prueba viaja desde el reloj al
servicio y vuelve con una respuesta controlada.

### Fase 5 --- IA y memoria contextual

**Objetivo:** obtener respuestas útiles con poco texto.

Tareas:

1.  Reutilizar la integración de IA actual si es segura y mantenible.
2.  Consultar solo el contexto necesario para cada pregunta.
3.  Resumir la respuesta en el backend para la pantalla pequeña.
4.  Proteger claves, datos personales y registros.
5.  Mostrar al usuario cuándo la respuesta es antigua o no se pudo
    actualizar.

Criterio de salida: consultas de prueba sobre proyectos producen
respuestas pertinentes y manejan fallos de conexión.

### Fase 6 --- Pruebas, documentación y entrega

**Objetivo:** dejar un proyecto mantenible.

Pruebas mínimas:

-   [ ] Instalación limpia.
-   [ ] Navegación completa.
-   [ ] Sin conexión y reconexión.
-   [ ] Servicio lento y timeout.
-   [ ] Datos vacíos o demasiado largos.
-   [ ] Almacenamiento lleno o fallido.
-   [ ] Consumo y estabilidad en uso real.
-   [ ] Secretos excluidos del repositorio.
-   [ ] Ningún texto de la app afirma inferir emociones o estrés.
-   [ ] Instrucciones de compilación e instalación verificadas.

Entregables:

-   Código fuente versionado.
-   README con requisitos y comandos reales.
-   Documento de arquitectura.
-   Contrato de API.
-   Registro de decisiones técnicas.
-   Informe de validación de capacidades (Fase 1).
-   Lista de problemas conocidos.
-   Guía de instalación y pruebas.

------------------------------------------------------------------------

## 9. Modelo de datos inicial

Ejemplo conceptual; no es todavía un contrato definitivo de API.

``` json
{
  "assistant_state": {
    "status": "available",
    "expression": "calm",
    "expression_source": "user",
    "last_sync": null
  },
  "projects": [
    {
      "id": "garmin-assistant",
      "title": "Mi Asistente Garmin",
      "last_update": "Plan v0.2 revisado contra el mockup",
      "next_step": "Auditar el asistente de la Anbernic"
    }
  ],
  "tasks": [
    {
      "id": "t1",
      "title": "Revisar código - app",
      "due": null,
      "done": false
    }
  ],
  "notes": [],
  "devices": [
    { "id": "anbernic", "status": "unknown", "reported_by": "backend" }
  ],
  "sync": {
    "status": "offline",
    "pending_items": 0
  }
}
```

`expression_source` indica si la expresión la eligió el usuario
(`user`) o la deriva un estado operativo (`system`). Nunca se deriva de
sensores.

Los datos reales se definirán después de revisar el sistema actual y
elegir el mecanismo de sincronización.

------------------------------------------------------------------------

## 10. Riesgos y decisiones que deben resolverse

  -----------------------------------------------------------------------
  Tema                    Riesgo                  Acción
  ----------------------- ----------------------- -----------------------
  Código de la Anbernic   No sabemos aún lenguaje Auditar repositorio
                          ni arquitectura         antes de diseñar
                                                  integración

  Alcance del backend     La Anbernic puede no    Decidir en Fase 0 si el
                          ser accesible desde     servicio vive en la
                          internet                nube o se expone de
                                                  forma segura

  Conectividad            Todo pasa por el        Probar un flujo mínimo
                          teléfono; sin él no hay en el modelo exacto
                          red                     

  Voz                     El mockup depende de    Validar en Fase 1;
                          voz y puede no haber    diseñar sin voz
                          API                     primero

  Expectativas del mockup El mockup muestra       Usar la sección 3 como
                          funciones descartadas   referencia; actualizar
                          o no validadas          el mockup

  Japonés                 Fuentes CJK pesan y     Subconjunto mínimo de
                          consumen memoria        caracteres; posponer a
                                                  0.6

  Instalación por USB     El despliegue y         Confirmar procedimiento
                          depuración dependen del oficial vigente antes
                          SDK y dispositivo       de distribuir

  IA                      Latencia, costes y      Respuestas breves,
                          falta de red            timeout y modo sin
                                                  conexión limitado

  Privacidad              Notas y contexto pueden Minimización de datos,
                          ser sensibles           autenticación y
                                                  secretos fuera del
                                                  reloj

  Estado de ánimo         No debe presentarse una Estados explícitos,
                          inferencia como un      cosméticos o
                          hecho                   controlados por el
                                                  usuario

  Autonomía               Las peticiones          Sincronizar bajo
                          frecuentes consumen     demanda y limitar
                          batería                 procesos
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## 11. Organización del repositorio sugerida

La estructura final dependerá de la auditoría. Como punto de partida:

``` text
mi-asistente-garmin/
├── README.md
├── docs/
│   ├── vision.md
│   ├── architecture.md
│   ├── api-contract.md
│   ├── capability-validation.md
│   ├── decisions.md
│   └── testing.md
├── garmin-connect-iq/
│   ├── manifest.xml
│   ├── source/
│   └── resources/
├── garmin-watchface/          # opcional, fase 0.7
├── integration-service/
│   └── README.md
├── tests/
└── .gitignore
```

No es necesario crear todas las carpetas desde el primer día. El
servicio de integración puede vivir dentro del asistente actual si su
arquitectura lo permite.

------------------------------------------------------------------------

## 12. Primeros pasos concretos

1.  **Respaldar el proyecto actual de la Anbernic.**
2.  Compartir el repositorio o un ZIP sin claves API, contraseñas ni
    tokens.
3.  Documentar las funciones que ya están operativas y cómo se ejecuta
    el asistente.
4.  Confirmar la variante exacta del fēnix 8 y preparar Connect IQ.
5.  Crear una app mínima y el informe de validación de capacidades.
6.  Actualizar el mockup según la sección 3.
7.  Implementar el avatar y los estados visuales.
8.  Solo después decidir la conectividad y empezar con la integración de
    IA.

### Definición de éxito

La primera versión se considerará útil cuando pueda mostrar el avatar y
sus estados, consultar una nota o proyecto de prueba, indicar claramente
si está desconectada y funcionar sin duplicar las funciones nativas de
Garmin.

**Decisión inmediata:** no desarrollar todo de golpe. Primero auditar el
asistente de la Anbernic, validar capacidades del fēnix 8 y lograr una
app mínima en el reloj; después añadir capacidades en incrementos
verificables.
