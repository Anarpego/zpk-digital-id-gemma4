# Prueba en Motorola G15 fisico - ZPK Digital ID

Esta carpeta contiene el APK ARM64 actual para instalar por cable o con ADB. No uses QR ni tuneles para esta prueba.

## Archivo principal

Instala este APK:

```text
motorola/zpk-litert-persona-institucion-release.apk
```

No instales los otros APKs que puedan aparecer en esta carpeta; son artefactos
anteriores o variantes de prueba. Para el Motorola G15 usa solamente
`zpk-litert-persona-institucion-release.apk`.

Checksum SHA-256 esperado:

```text
d3ab26a09c79a454b68be344df43bd6c58ba95f8aec73a8bd34f547588167e09
```

Archivo de checksum:

```text
motorola/zpk-litert-persona-institucion-release.apk.sha256
```

Antes de copiarlo puedes verificarlo con:

```bash
cd /Users/anibalperez/Code/AI/kaggle
./motorola/verificar-apk.sh
```

## Requisitos del teléfono

- Motorola G15 físico, no emulador.
- CPU `arm64-v8a`.
- Android moderno.
- Para ejecutar Gemma 4 E2B LiteRT-LM dentro de la app se requieren 6 GB+ de RAM fisica.
- El Motorola G15 probado tiene ~3.86 GB RAM; puede instalar el modelo, pero no decodificarlo establemente.
- La app protege este caso y muestra `DEVICE_LOW_MEMORY` en vez de crashear.

## Si el Mac no detecta el Motorola

En macOS, Android normalmente no aparece en Finder como una memoria USB normal. Para copiar por cable necesitas que el teléfono use MTP, o usar ADB.

En el Motorola G15:

1. Desbloquea el teléfono y deja la pantalla encendida.
2. Conecta el cable directo al Mac si puedes, sin hub.
3. Baja la cortina de notificaciones.
4. Toca la notificación USB.
5. Elige:

```text
Transferencia de archivos / Android Auto
```

No elijas solo cargar.

Si sigue sin aparecer, cambia el cable. Muchos cables USB-C solo cargan y no pasan datos.

## Activar ADB en Motorola G15

1. Ve a `Ajustes`.
2. Entra en `Acerca del teléfono`.
3. Toca `Número de compilación` 7 veces si las opciones de desarrollador aún no están activas.
4. Ve a `Ajustes`.
5. Entra en `Sistema`.
6. Entra en `Opciones para desarrolladores`.
7. Activa:

```text
Depuración por USB
```

Si no aparece el permiso en pantalla:

1. En `Opciones para desarrolladores`, toca:

```text
Revocar autorizaciones de depuración USB
```

2. Desconecta y conecta otra vez.
3. Acepta el popup:

```text
¿Permitir depuración USB?
```

Marca permitir siempre si aparece esa opción.

En el Mac, verifica:

```bash
adb kill-server
adb start-server
adb devices -l
```

Resultado bueno:

```text
<serial> device product:... model:...
```

Si sale `unauthorized`, falta aceptar el popup en el teléfono. Si sale vacío, el Mac todavía no ve el teléfono: revisa cable, puerto, hub y modo USB.

## Instalar el APK

Opción A: copiar manualmente por MTP.

1. Conecta el Motorola por USB.
2. Activa modo transferencia de archivos.
3. Copia `motorola/zpk-litert-persona-institucion-release.apk` al telefono, por ejemplo a `Downloads`.
4. En el teléfono, abre el APK desde Archivos/Downloads.
5. Permite instalar apps desconocidas si Android lo pide.
6. Instala ZPK Digital ID.

Opción B: instalar con ADB si el teléfono aparece:

```bash
adb devices -l
adb install -r motorola/zpk-litert-persona-institucion-release.apk
```

## Estado real verificado en Motorola G15

Verificado por ADB en el Motorola G15:

```text
model: moto g15
abi: arm64-v8a
Gemma 4 model: instalado en almacenamiento privado de la app
model_size_bytes: 2583085056
device_ram_bytes: 3869007872
required_ram_bytes: 6000000000
runtime_state: DEVICE_LOW_MEMORY
```

Esto significa: el APK y el modelo estan instalados, pero este telefono no debe ejecutar `Probar Gemma offline` porque Android mata el proceso por memoria. La pantalla `Motor` tambien debe mostrar `Respaldo offline disponible`, `runtime.local_deterministic -> ready` y `runtime.network_required -> false`. Para una demo de generacion Gemma 4 en Android fisico, usa un telefono con 6 GB+ RAM. Para este G15, usa los flujos locales y el diagnostico `DEVICE_LOW_MEMORY` como evidencia honesta de hardware.

## Prueba recomendada en este G15

1. Abre ZPK Digital ID.
2. En `Persona`, prueba los casos:
   - `IGSS`: registro, afiliacion o recuperacion con mesa institucional.
   - `SAT`: recuperacion de acceso, actualizacion o bloqueo preventivo.
   - `Colegio`: inscripcion, beca o constancia con prueba limitada.
   - `Tramite`: recuperacion de tramite publico o registro no reconocido.
   - `Campo`: escuela, salud o ayuda sin internet estable.
   - `Proteccion`: coercion, amenaza o riesgo personal.
3. Usa el CUI sintetico:

```text
1234567890101
```

4. Toca `Ayudarme ahora`.
5. En `Institucion`, confirma que aparece:
   - `Bandeja IGSS`, `Bandeja SAT` o bandeja educativa segun el caso.
   - ruta de atencion de ventanilla.
   - pseudonimo y hash del paquete.
6. En `Acciones`, confirma que aparece:
   - `CUI no sale`
   - `funciona sin red`
   - `paquete firmado`
   - pasos institucionales redactados.
7. En `Motor`, confirma:

```text
DEVICE_LOW_MEMORY
Respaldo offline disponible
litert_gemma.model_size_bytes -> 2583085056
litert_gemma.device_ram_bytes -> 3869007872
litert_gemma.required_ram_bytes -> 6000000000
runtime.local_deterministic -> ready
runtime.network_required -> false
```

## Señal de exito en hardware compatible

En un Android con suficiente RAM, el resultado ideal de `Probar Gemma offline` debe incluir `litert_gemma.generate(...) -> ok` y `agent_contract.safety_review(raw_cui=false) -> ok`. No reclames eso para el Motorola G15 probado.

## CUI para probar el flujo normal

Usa solo datos sintéticos. Para el flujo de prueba puedes usar:

```text
1234567890101
```

No uses CUI real, DPI real, telefono real, correo real ni nombres reales.

## Estado verificado

La APK actual se genero e instalo por ADB:

```text
Performing Streamed Install
Success
```

Instalacion revalidada por USB/ADB con el APK release vigente:

```bash
adb install -r motorola/zpk-litert-persona-institucion-release.apk
```

Tambien se verifico por UIAutomator con:

```bash
./scripts/verify_motorola_physical_flow.sh --no-install
```

Resultado esperado:

```text
PASS: Motorola physical flow verified.
```

Pruebas locales ejecutadas:

```text
flutter analyze
flutter test
uv run python evaluate_dataset.py
```

## Qué enviarme después

Enviame el texto de `Copiar diagnostico` en `Motor`, o una foto clara de la pantalla `DEVICE_LOW_MEMORY`. Para mostrar utilidad, tambien sirve una foto de `Institucion` despues de probar `IGSS`, `SAT` o `Colegio`.
