
## 💻 1. Pruebas del Backend (API REST en Ruby on Rails)
Ubicación del archivo: `alquiler_maquinaria_api/test/controllers/articulos_controller_test.rb`

Estas pruebas verifican que las operaciones CRUD obligatorias de la API REST funcionen perfectamente sobre la base de datos:

| Operación | Nombre del Test | Descripción / Objetivo |
| :--- | :--- | :--- |
| **LEER (Read)** | `deberia obtener index de articulos` | Envía una petición `GET` a `/articulos`. Comprueba que responda `200 OK`, que el JSON no esté vacío y que la cantidad de elementos devueltos coincida exactamente con la BD. |
| **CREAR (Create)** | `deberia crear articulo` | Envía una petición `POST` a `/articulos` con parámetros de un nuevo artículo. Comprueba que aumente en `+1` la base de datos, que devuelva `201 Created` y que los datos coincidan. |
| **ACTUALIZAR (Update)** | `deberia actualizar articulo` | Envía una petición `PATCH` a `/articulos/:id`. Comprueba que devuelva `200 OK` y verifica directamente en la BD que el nombre y el precio del artículo se hayan guardado modificados. |
| **BORRAR (Delete)** | `deberia borrar articulo` | Envía una petición `DELETE` a `/articulos/:id`. Comprueba que el número total de artículos disminuya en `-1` en la base de datos y retorne un estado de éxito. |

---

## 📱 2. Pruebas del Frontend (Lógica y Patrones en Flutter)
Ubicación del archivo: `alquiler_maquinaria_app/test/widget_test.dart`

Para simplificar la exposición técnica y centrarse únicamente en la **lógica de negocio pura** requerida por la práctica, las pruebas de Flutter se han simplificado a los **3 tests esenciales de patrones de diseño**:

### Pruebas de Patrones de Diseño (Lógica de Negocio)

1.  **Patrón Decorator (Tractor con Extras):**
    *   *Objetivo:* Validar que al envolver un `TractorBase` con decoradores (`ConRemolque` y `ConGpsAgricola`), el precio de los extras acumulables se sume dinámicamente sobre los días.
    *   *Fórmula probada:* `Base (150€*2dias) + Remolque (40€*2dias) + GPS (15€*2dias) = 410.0€`.
2.  **Patrón Strategy (Envío):**
    *   *Objetivo:* Probar que las tres clases de estrategias de envío calculen correctamente sus costes fijos y variables.
    *   *Estrategias verificadas:*
        *   `EnvioEstandar`: 50€ fijos + 10€ por artículo.
        *   `EnvioUrgente`: 120€ fijos + 15€ por artículo.
        *   `RecogidaEnTienda`: 0€ siempre.
3.  **Patrón Composite (Carrito global / Paquete):**
    *   *Objetivo:* Verificar que la estructura en árbol (`Paquete`) calcule de forma recursiva la suma de múltiples artículos (con y sin decoradores), calcule el envío usando la Strategy inyectada, y permita cambiar de Strategy en tiempo de ejecución de manera transparente.
