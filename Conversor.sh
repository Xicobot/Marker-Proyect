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
    echo "📂 Descargando archivos permitidos (PDF, PNG, JPG, JPEG) desde Drive..."
    
    # Descargar solo archivos con extensiones permitidas
    rclone copy dropbox:/proyecto-mercantil/input "$TEMP_DIR" --progress --drive-shared-with-me  --include "*.pdf" --include "*.png" --include "*.jpg" --include "*.jpeg"
    
    # Verificar si hay archivos en TEMP
    FILES=$(find "$TEMP_DIR" -maxdepth 1 -type f \( -iname "*.pdf" -o -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \))
    if [ -z "$FILES" ]; then
        echo "⚠️ No hay archivos válidos en Dropbox para procesar."
        return
    fi
    
    for FILE in $FILES; do
        [ -f "$FILE" ] || continue  # Saltar si no es un archivo
        echo "🛠️ Procesando: $(basename "$FILE")"
        
        # Ejecutar OCR y convertir a HTML - genera múltiples archivos en diferentes formatos
        if marker_single --output_dir "$OUTPUT_DIR" --output_format html --force_ocr --strip_existing_ocr --debug --languages es "$FILE"; then
            echo "✅ Procesado correctamente: $(basename "$FILE")"
            
            # Eliminar todos los archivos que NO sean JPEG del directorio de salida
            find "$OUTPUT_DIR" -type f ! \( -iname "*.jpg" -o -iname "*.jpeg" \) -delete
            
            # Mover archivo original a la carpeta de completados
            mv "$FILE" "$COMPLETED/"
            
            # Subir solo los archivos JPEG a Drive
            echo "🚀 Subiendo archivos JPEG procesados a Dropbox..."
            rclone copy "$OUTPUT_DIR" dropbox:/proyecto-mercantil/output --progress --drive-shared-with-me --include "*.jpg" --include "*.jpeg"
            
            # Subir archivos originales completados a Drive
            echo "📤 Subiendo archivos completados a Dropbox..."
            rclone copy "$COMPLETED" dropbox:/proyecto-mercantil/completed --progress --drive-shared-with-me 
            
            # Elimina archivos locales después de subirlos
            rm -r "$COMPLETED"/*
            rm -r "$OUTPUT_DIR"/*
        else
            echo "❌ Error en: $(basename "$FILE") - Moviendo a error_log/"
            mv "$FILE" "$ERROR_LOG_DIR/"
        fi
    done
    
    # Eliminar archivos procesados de Drive
    echo "🗑️ Eliminando archivos procesados en Dropbox..."
    for FILE in $FILES; do
        FILE_NAME=$(basename "$FILE")
        rclone delete "dropbox:/proyecto-mercantil/input/$FILE_NAME" --progress --drive-shared-with-me
    done
}

# Bucle infinito para monitorear Dropbox
while true; do
    echo "🔄 Escaneando cambios en Dropbox..."
    
    # Revisar si hay archivos en la carpeta de Drive con extensiones válidas
    if rclone lsf dropbox:/proyecto-mercantil/input --drive-shared-with-me | grep -Ei "\.(pdf|png|jpg|jpeg)$"; then
        procesar_archivos
    else
        echo "⏳ No hay archivos PDF o imágenes nuevas en Dropbox. Esperando..."
    fi
    
    # Esperar 30 segundos antes de volver a comprobar
    sleep 30
done