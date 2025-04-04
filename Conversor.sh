#!/bin/bash
# Definir rutas locales
TEMP_DIR="/home/usuario/temp"
OUTPUT_DIR="/home/usuario/output"
ERROR_LOG_DIR="/home/usuario/error_log"
COMPLETED="/home/usuario/completed"

# Crear carpetas si no existen
mkdir -p "$TEMP_DIR" "$OUTPUT_DIR" "$ERROR_LOG_DIR" "$COMPLETED"

# Función para procesar archivos
procesar_archivos() {
    echo " Descargando archivos permitidos (PDF, PNG, JPG, JPEG) desde Drive..."
    
    # Descargar solo archivos con extensiones permitidas
    rclone copy dropbox:/proyecto-mercantil/input "$TEMP_DIR" --progress --drive-shared-with-me  --include "*.pdf" --include "*.png" --include "*.jpg" --include "*.jpeg"
    
    # Verificar si hay archivos en TEMP
    FILES=$(find "$TEMP_DIR" -maxdepth 1 -type f \( -iname "*.pdf" -o -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \))
    if [ -z "$FILES" ]; then
        echo " No hay archivos válidos en Dropbox para procesar."
        return
    fi
    
    for FILE in $FILES; do
        [ -f "$FILE" ] || continue  # Saltar si no es un archivo
        echo " Procesando: $(basename "$FILE")"
        
        # Ejecutar OCR y convertir a HTML - genera múltiples archivos en diferentes formatos
        if marker_single --output_dir "$OUTPUT_DIR" --output_format html --force_ocr --strip_existing_ocr --debug --languages es "$FILE"; then
            echo " Procesado correctamente: $(basename "$FILE")"
            
            # Eliminar todos los archivos que NO sean JPEG del directorio de salida
            find "$OUTPUT_DIR" -type f ! \( -iname "*.jpg" -o -iname "*.jpeg" \) -delete
            
            # Mover archivo original a la carpeta de completados
            mv "$FILE" "$COMPLETED/"
            
            # Subir solo los archivos JPEG a Drive
            echo " Subiendo archivos JPEG procesados a Dropbox..."
            rclone copy "$OUTPUT_DIR" dropbox:/proyecto-mercantil/output --progress --drive-shared-with-me --include "*.jpg" --include "*.jpeg"
            
            # Subir archivos originales completados a Drive
            echo " Subiendo archivos completados a Dropbox..."
            rclone copy "$COMPLETED" dropbox:/proyecto-mercantil/completed --progress --drive-shared-with-me 
            
            # Elimina archivos locales después de subirlos
            rm -r "$COMPLETED"/*
            rm -r "$OUTPUT_DIR"/*
        else
            echo " Error en: $(basename "$FILE") - Moviendo a error_log/"
            mv "$FILE" "$ERROR_LOG_DIR/"
        fi
    done
    
    # Eliminar archivos procesados de Drive
    echo " Eliminando archivos procesados en Dropbox..."
    for FILE in $FILES; do
        FILE_NAME=$(basename "$FILE")
        rclone delete "dropbox:/proyecto-mercantil/input/$FILE_NAME" --progress --drive-shared-with-me
    done
}

# Bucle infinito para monitorear Dropbox
while true; do
    echo " Escaneando cambios en Dropbox..."
    
    # Revisar si hay archivos en la carpeta de Drive con extensiones válidas
    if rclone lsf dropbox:/proyecto-mercantil/input --drive-shared-with-me | grep -Ei "\.(pdf|png|jpg|jpeg)$"; then
        procesar_archivos
    else
        echo " No hay archivos PDF o imágenes nuevas en Dropbox. Esperando..."
    fi
    
    # Esperar 30 segundos antes de volver a comprobar
    sleep 30
done
El mié, 2 abr 2025 a las 10:31, Deneb Donoso Duran (<denebdonosoduran@gmail.com>) escribió:
Duro
On Wed, Apr 2, 2025, 10:23 Rafael Vidal Rodríguez-Sabio <rvidrod689@g.educaand.es> wrote:
tú,
El mié, 2 abr 2025 a las 10:18, Deneb Donoso Duran (<denebdonosoduran@gmail.com>) escribió:
Y el script limpio donde está, o lo modifico yo?
On Wed, Apr 2, 2025, 10:11 Rafael Vidal Rodríguez-Sabio <rvidrod689@g.educaand.es> wrote:
Objetivo: Extracción masiva de imágenes a partir de pdfs de prensa histórica.
HW : 
CPU 16 núcleos, RAM 32GB, 20GB almacenamiento, GPU 8GB+ VRAM; Directorio con permisos de subida y descarga. Capacidad 1 GB.

SW: https://github.com/VikParuchuri/markerLicencia:GPL-3.0 license
Script propio para lanzar la extracción de imágenes. (crontab o similar)  Falta el enlace al script limpio, no el de Andrés. Faltan los enlaces a los ejemplos. 1 pdf  y las imágenes extraídas.

El mié, 2 abr 2025 a las 9:47, Deneb Donoso Duran (<denebdonosoduran@gmail.com>) escribió:


El mar, 1 abr 2025 a las 13:18, Rafael Vidal Rodríguez-Sabio (<rvidrod689@g.educaand.es>) escribió:


El mar, 1 abr 2025 a las 13:16, Deneb Donoso Duran (<denebdonosoduran@gmail.com>) escribió:
 


El mar, 1 abr 2025 a las 13:15, Rafael Vidal Rodríguez-Sabio (<rvidrod689@g.educaand.es>) escribió:
$ for file in *_batch_output.txt ;do  cat $file | sed 's/\\n//g' | sed 's/\\/ /g' |grep -o '{.*}' | jq -r . > $(basename "$file" "_batch_output.txt").json; done


El mar, 1 abr 2025 a las 13:11, Rafael Vidal Rodríguez-Sabio (<rvidrod689@g.educaand.es>) escribió:
for file in 1788-01-03_batch_output.txt ;do  cat $file | sed 's/\\n//g' | sed 's/\\/ /g' |grep -o '{.*}' | jq -r '.' >jsdssddasdas.json; done


El mar, 1 abr 2025 a las 13:10, Rafael Vidal Rodríguez-Sabio (<rvidrod689@g.educaand.es>) escribió:
for file in 1788-01-03_batch_output.txt ;do  cat $file | sed 's/\\n//g' | sed 's/\\/ /g' |grep -o '{.*}' >jsdssddasdas.json; done
El mar, 1 abr 2025 a las 12:46, Deneb Donoso Duran (<denebdonosoduran@gmail.com>) escribió:
Los estoy revisando, con el comando que me has mandadado solo me sale el del primer día, el resto no lo intenta
El mar, 1 abr 2025 a las 12:43, Rafael Vidal Rodríguez-Sabio (<rvidrod689@g.educaand.es>) escribió:
mándame los que dan la lata y lo miro
El mar, 1 abr 2025 a las 12:41, Deneb Donoso Duran (<denebdonosoduran@gmail.com>) escribió:
Que le ocurre a estos archivos?

El lun, 31 mar 2025 a las 14:47, Rafael Vidal Rodríguez-Sabio (<rvidrod689@g.educaand.es>) escribió:


El lun, 31 mar 2025 a las 13:40, Rafael Vidal Rodríguez-Sabio (<rvidrod689@g.educaand.es>) escribió:
Hay que renombrarlo correctamente para unir luego todos las salidas pasadas a json, pero el primer pdf devueve algo limpio y útil. Quizás hay que limpiar los \
El lun, 31 mar 2025 a las 13:22, Rafael Vidal Rodríguez-Sabio (<rvidrod689@g.educaand.es>) escribió:
224,12 US$
El lun, 31 mar 2025 a las 11:19, Rafael Vidal Rodríguez-Sabio (<rvidrod689@g.educaand.es>) escribió:
# Instrucciones para Transcripción y Etiquetado de Documentos PDF con OCR Deficiente## ObjetivoGENERAR UN JSON CON NOTICIAS MUSICALES, TRANSCRITAS COMPLETAMENTE. Se le proporciona un documento PDF que puede tener problemas de OCR. Su tarea consiste en:1. TRANSCRIBIR MANUALMENTE el documento PDF sin confiar en ninguna transcripción preexistente que pueda contener el archivo.2. Basarse únicamente en lo que se observa visualmente en las imágenes del documento.3. Devolver exclusivamente un JSON con la transcripción de cada noticia musical completa.## Proceso de Transcripción para Documentos con OCR Deficiente1. Ignore completamente cualquier texto extraído automáticamente del PDF.2. Transcriba el texto observando directamente las imágenes de las páginas.3. Preste especial atención a caracteres problemáticos que suelen confundirse en OCR: - Distinga cuidadosamente entre "rn" y "m" - Verifique las letras "c", "e", "o" que pueden confundirse entre sí - Atienda a signos diacríticos como tildes, diéresis, etc. - Verifique los símbolos y números4. En caso de texto ilegible, marque con [ilegible] y continúe.5. Mantenga la estructura original de párrafos, poemas y otros elementos.6. Para cada noticia, indica el número de página del PDF. Indica también el número de página impreso en el periódico (ej: "PDF": "1", "Periódico": "774"). Si no figuran usa "no consta".7. Considerar como noticias musicales TODAS las entradas relacionadas con: - Óperas, conciertos y representaciones musicales - Cartas o documentos sobre establecimientos de ópera - Listas de actores de compañías teatrales y cómicas - Romancillos, odas y poesías que puedan ser cantadas - Invenciones o innovaciones relacionadas con instrumentos musicales - Cualquier mención a música, representaciones, tonadas o tonadillas - Datos sobre entradas y asistencia a espectáculos musicales## Verificación Final para OCR Deficiente- Compare su transcripción con fragmentos de texto visible para asegurar precisión.- Verifique especialmente nombres propios, fechas y términos técnicos.- Revise minuciosamente los poemas y versos que suelen sufrir más errores de OCR.- Indique claramente cuando un pasaje sea completamente ilegible.- Presta especial atención a estos elementos y asegúrate de incluirlos TODOS: noticias musicales incluyendo índices donde aparecen referencias a eventos musicales, poesía que pueda ser cantada, instrumentos musicales, teatros y óperas, actores de compañías teatrales, y cualquier noticia relacionada con actividades musicales o escénicas del período.- Revisar METICULOSAMENTE todo el índice y las páginas del documento para no omitir ninguna entrada relacionada con música, teatro, poesía cantable o representaciones escénicas.- Incluir como primer campo del JSON la fecha del documento PDF en formato "fecha": y la fecha que figure en el documentoElimina caracteres de escape y comillas anidadas, para que el json sea válido## devuelve solo el json, sin comentarios tuyos.
El lun, 31 mar 2025 a las 11:19, Rafael Vidal Rodríguez-Sabio (<rvidrod689@g.educaand.es>) escribió:
Mejor este, que el anterior no hace bien las fechas
El lun, 31 mar 2025 a las 11:17, Rafael Vidal Rodríguez-Sabio (<rvidrod689@g.educaand.es>) escribió:
# Instrucciones para Transcripción y Etiquetado de Documentos PDF con OCR Deficiente

## Objetivo
GENERAR UN JSON CON NOTICIAS MUSICALES, TRANSCRITAS COMPLETAMENTE. Se le proporciona un documento PDF que puede tener problemas de OCR. Su tarea consiste en:
1. TRANSCRIBIR MANUALMENTE el documento PDF sin confiar en ninguna transcripción preexistente que pueda contener el archivo.
2. Basarse únicamente en lo que se observa visualmente en las imágenes del documento.
3. Devolver exclusivamente un JSON con la transcripción de cada noticia musical completa.

## Proceso de Transcripción para Documentos con OCR Deficiente
1. Ignore completamente cualquier texto extraído automáticamente del PDF.
2. Transcriba el texto observando directamente las imágenes de las páginas.
3. Preste especial atención a caracteres problemáticos que suelen confundirse en OCR:
   - Distinga cuidadosamente entre "rn" y "m"
   - Verifique las letras "c", "e", "o" que pueden confundirse entre sí
   - Atienda a signos diacríticos como tildes, diéresis, etc.
   - Verifique los símbolos y números
4. En caso de texto ilegible, marque con [ilegible] y continúe.
5. Mantenga la estructura original de párrafos, poemas y otros elementos.
6. Para cada noticia, indica el número de página del PDF. Indica también el número de página impreso en el periódico (ej: "PDF": "1", "Periódico": "774"). Si no figuran usa "no consta".
7. Considerar como noticias musicales TODAS las entradas relacionadas con:
   - Óperas, conciertos y representaciones musicales
   - Cartas o documentos sobre establecimientos de ópera
   - Listas de actores de compañías teatrales y cómicas
   - Romancillos, odas y poesías que puedan ser cantadas
   - Invenciones o innovaciones relacionadas con instrumentos musicales
   - Cualquier mención a música, representaciones, tonadas o tonadillas
   - Datos sobre entradas y asistencia a espectáculos musicales

## Verificación Final para OCR Deficiente
- Compare su transcripción con fragmentos de texto visible para asegurar precisión.
- Verifique especialmente nombres propios, fechas y términos técnicos.
- Revise minuciosamente los poemas y versos que suelen sufrir más errores de OCR.
- Indique claramente cuando un pasaje sea completamente ilegible.
- Presta especial atención a estos elementos y asegúrate de incluirlos TODOS: noticias musicales incluyendo índices donde aparecen referencias a eventos musicales, poesía que pueda ser cantada, instrumentos musicales, teatros y óperas, actores de compañías teatrales, y cualquier noticia relacionada con actividades musicales o escénicas del período.
- Revisar METICULOSAMENTE todo el índice y las páginas del documento para no omitir ninguna entrada relacionada con música, teatro, poesía cantable o representaciones escénicas.
- Incluir como primer campo del JSON la fecha del documento PDF en formato "fecha": "1788" (o la fecha que corresponda según el documento).

Elimina caracteres de escape y comillas anidadas, para que el json sea válido

## devuelve solo el json, sin comentarios tuyos.
El lun, 31 mar 2025 a las 10:55, Deneb Donoso Duran (<denebdonosoduran@gmail.com>) escribió:
https://claude.ai/share/70afa285-838c-4731-ae0c-5e839e6f0782
El lun, 31 mar 2025 a las 10:48, Rafael Vidal Rodríguez-Sabio (<rvidrod689@g.educaand.es>) escribió:
Comprueba el promp, vía web. Ajusta para que no tenga comillas simples anidadas, que luego da la lata limpiar los json.una vez hecho, se cambia el prompt en el adjunto.

Empezamos con el primer año. Cuenta las páginas en total, para estimar coste. 

Ahora tenemos 224,17 US$ Remaining Balance
6.2.1. Procesamos  con el musica37 nuevo
Me avisas.
Cuando acabe el bacth 6.2.2. Descargamos la salida de los lotes.
Luego limpiamos6.2.4. Limpiamos la salida descargada de cada id, para resultado bajado con pyth0n y msg_id.
Luego unimos
6.2.5. Unimos los resultados de cada año.Hay que hacer la resta del saldo restante.



El lun, 31 mar 2025 a las 8:33, Deneb Donoso Duran (<denebdonosoduran@gmail.com>) escribió:
Buenos días jefe, hoy toca procesar el primer año para daniel, no?