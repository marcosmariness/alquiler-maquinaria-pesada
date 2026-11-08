
## 1. Introducción y Contexto

El cliente requiere una plataforma móvil moderna (app Flutter) conectada a un servidor de datos centralizado (API REST en Ruby on Rails) que permita a sus clientes reservar tractores, excavadoras y herramientas, configurándolos con diferentes accesorios (extras), y seleccionando diferentes opciones de entrega/recogida. Los clientes también podrán consultar su historial personal de alquileres y cancelar aquellas reservas con fecha de inicio futura. Así mismo, los gestores de la empresa deben poder administrar el catálogo de artículos desde un panel de control dedicado.

---

## 2. Requisitos Funcionales (RF)

### RF-1: Gestión de Sesión y Autenticación
* **RF-1.1:** El sistema permitirá a los usuarios iniciar sesión utilizando sus credenciales (correo electrónico y contraseña).
* **RF-1.2:** El sistema identificará el rol del usuario autenticado (Cliente o Gestor) y lo redirigirá a su interfaz correspondiente.

### RF-2: Panel del Cliente (Catálogo e Interacción)
* **RF-2.1:** El cliente podrá visualizar el catálogo de artículos disponibles en tiempo real con su categoría y precio base por día.
* **RF-2.2:** El catálogo indicará visualmente si un artículo cuenta con alquileres activos o periodos de ocupación en curso.
* **RF-2.3:** Al desplegar un artículo, se listarán detalladamente los periodos y fechas exactas en las que el equipo ya está reservado.

### RF-3: Configuración Avanzada de Alquileres (Patrón Decorator)
* **RF-3.1:** El sistema permitirá personalizar el número de días de alquiler para cada equipo.
* **RF-3.2:** Al alquilar un **Tractor**, el cliente podrá añadir los siguientes extras decorativos acumulables:
  * **Remolque**: incremento de +40€ por día.
  * **GPS Agrícola de Alta Precisión**: incremento de +15€ por día.
* **RF-3.3:** Al alquilar una **Máquina**, el cliente podrá añadir los siguientes extras decorativos acumulables:
  * **Seguro Premium a Todo Riesgo**: incremento de +25€ por día.
  * **Operario Profesional**: incremento de +100€ por día.
* **RF-3.4:** Los accesorios sueltos no admitirán extras adicionales.

### RF-4: Gestión del Carrito de Alquileres (Patrón Composite)
* **RF-4.1:** El cliente podrá agrupar múltiples alquileres de maquinaria en un único paquete o "Carrito de la compra".
* **RF-4.2:** El carrito calculará de forma automática y recursiva el subtotal de alquiler sumando el coste de todos los equipos y sus respectivos extras.
* **RF-4.3:** El cliente podrá visualizar el desglose detallado del carrito, eliminar elementos de él o editarlos (modificar sus fechas, días o extras).

### RF-5: Estrategias de Envío y Despacho (Patrón Strategy)
* **RF-5.1:** El cliente podrá seleccionar una estrategia de entrega/recogida para el carrito completo, calculándose el coste según las siguientes fórmulas:
  * **Envío Estándar**: Coste fijo de 50.00€ + 10.00€ por artículo añadido en el carrito.
  * **Envío Urgente (24h)**: Coste fijo de 120.00€ + 15.00€ por artículo añadido en el carrito.
  * **Recogida en Tienda/Almacén**: Sin coste adicional (0.00€).
* **RF-5.2:** El sistema sumará dinámicamente los costes de envío escogidos al subtotal de alquiler para obtener el gran total.

### RF-6: Gestión de Conflictos y Reserva Segura (BD)
* **RF-6.1:** Al seleccionar la fecha de inicio del alquiler, el calendario bloqueará automáticamente aquellas fechas en las que el artículo ya esté reservado.
* **RF-6.2:** Si el cliente intenta añadir o procesar una reserva en fechas que se solapen con alquileres existentes, la app y la API REST detendrán la operación informando del conflicto.
* **RF-6.3:** Al confirmar el alquiler, el sistema registrará los periodos en la base de datos a través de la API REST, garantizando la persistencia y la consistencia en futuras consultas.

### RF-7: Panel de Control del Gestor (CRUD)
* **RF-7.1:** El gestor podrá realizar operaciones **CRUD completas** sobre los artículos del catálogo:
  * **Crear** nuevos artículos especificando nombre, categoría (Tractor/Maquina/AccesorioSuelto) y precio base diario.
  * **Visualizar (Leer)** el listado completo de artículos de la base de datos.
  * **Actualizar** cualquier campo de un artículo existente.
  * **Borrar** un artículo del catálogo, eliminando en cascada sus periodos históricos asociados.

### RF-8: Historial Personal de Alquileres del Cliente
* **RF-8.1:** El cliente dispondrá de una sección dedicada dentro de su panel donde podrá consultar el listado completo de todos los alquileres que ha realizado, tanto pasados como futuros.
* **RF-8.2:** Cada entrada del historial mostrará el nombre del artículo alquilado, su categoría, y las fechas de inicio y fin del periodo reservado.
* **RF-8.3:** El sistema diferenciará visualmente los alquileres **futuros** (pendientes de inicio) de los alquileres **pasados o en curso**, facilitando su identificación a golpe de vista.
* **RF-8.4:** El historial se actualizará automáticamente tras confirmar un nuevo alquiler o cancelar uno existente, sin necesidad de reiniciar la sesión.

### RF-9: Cancelación de Reservas Futuras
* **RF-9.1:** El cliente podrá cancelar únicamente aquellos alquileres cuya **fecha de inicio sea posterior a la fecha actual**.
* **RF-9.2:** Antes de ejecutar la cancelación, el sistema mostrará un diálogo de confirmación para evitar cancelaciones accidentales.
* **RF-9.3:** Tras una cancelación exitosa, el sistema liberará automáticamente el periodo de fechas en la base de datos, dejando el artículo disponible para nuevas reservas en ese rango.
---

## 3. Requisitos No Funcionales (RNF)

### RNF-1: Usabilidad y Diseño Visual
* La interfaz móvil debe ser intuitiva, moderna y receptiva, utilizando elementos de colores contrastados (p. ej. verde para estado disponible y naranja/rojo para alertas/ocupación) que faciliten la rápida interpretación por parte del usuario.

### RNF-2: Desempeño y Escalabilidad
* La API REST desarrollada en Ruby on Rails debe responder a las consultas de disponibilidad y creación de reservas en menos de 200 ms bajo condiciones normales de red.

### RNF-3: Arquitectura y Modularidad (Patrones de Diseño)
* La aplicación Flutter y el backend Rails deben estar estructurados bajo principios de orientación a objetos y patrones de diseño combinados, permitiendo extender el catálogo o añadir nuevos extras con un mínimo acoplamiento de código.

### RNF-4: Consistencia de Datos y Concurrencia
* La base de datos debe garantizar integridad referencial y prevenir la doble reserva del mismo equipo para rangos de fechas coincidentes mediante transacciones validadas en el controlador.
