; Descripción: Un simple juego de adivinanza de números para Linux x86-64.
;              El programa genera un número pseudoaleatorio entre 1 y 10
;              y solicita al usuario que adivine el número hasta que acierte.
;
; Instrucciones de compilación (usando NASM y ld):
; nasm -f elf64 guessing_game.asm -o guessing_game.o
; ld guessing_game.o -o guessing_game

; ==============================================================================
; Sección de Datos
; ==============================================================================
; Contiene datos inicializados (constantes, cadenas).
section .data
    ; --- Cadenas de Interfaz de Usuario ---
    prompt          db "Adivina un número (1-10): ", 0   ; Mensaje de solicitud (terminado en nulo por conveniencia, aunque no es estrictamente necesario para write)
    prompt_len      equ $ - prompt                      ; Calcula automáticamente la longitud de la cadena de solicitud

    low_msg         db "Demasiado bajo!", 10             ; Mensaje para adivinanza demasiado baja (incluye salto de línea)
    low_msg_len     equ $ - low_msg                     ; Calcula la longitud del mensaje 'demasiado bajo'

    high_msg        db "Demasiado alto!", 10            ; Mensaje para adivinanza demasiado alta (incluye salto de línea)
    high_msg_len    equ $ - high_msg                    ; Calcula la longitud del mensaje 'demasiado alto'

    correct_msg     db "Correcto!", 10                  ; Mensaje para adivinanza correcta (incluye salto de línea)
    correct_msg_len equ $ - correct_msg                 ; Calcula la longitud del mensaje 'correcto'

    invalid_msg     db "Entrada inválida! ", 10         ; Mensaje para entrada inválida (incluye salto de línea)
    invalid_msg_len equ $ - invalid_msg                 ; Calcula la longitud del mensaje 'entrada inválida'

; ==============================================================================
; Sección de Texto
; ==============================================================================
; Contiene el código del programa (instrucciones).
section .text
    global _start                               ; Hace que la etiqueta _start sea visible globalmente (punto de entrada para el enlazador)

; ------------------------------------------------------------------------------
; Punto de Entrada del Programa
; ------------------------------------------------------------------------------
_start:
    ; --- Sembrar y Generar Número Objetivo (Pseudoaleatorio) ---
    ; Usa el Contador de Marca de Tiempo (TSC) de la CPU como una semilla básica. Nota: Esto no es
    ; aleatoriedad criptográficamente segura.
    rdtsc                                       ; Lee el Contador de Marca de Tiempo en EDX:EAX (alto:bajo 64 bits)
    mov ecx, 10                                 ; Establece el divisor en 10 para la operación de módulo
    xor edx, edx                                ; Limpia EDX (parte alta del dividendo) para división de 32 bits
                                                ; Solo usamos los 32 bits inferiores (EAX) del TSC por simplicidad.
    div ecx                                     ; Divide EDX:EAX por ECX (10). Cociente en EAX, Resto en EDX.
                                                ; El resto (EDX) será 0-9.
    add edx, 1                                  ; Suma 1 al resto para obtener un rango de 1-10.
    mov ebx, edx                                ; Almacena el número objetivo (1-10) en EBX para comparación posterior.
                                                ; Usando EBX ya que es un registro guardado por la función llamada (aunque no es crítico aquí).

; ------------------------------------------------------------------------------
; Bucle Principal del Juego
; ------------------------------------------------------------------------------
game_loop:
    ; --- Solicitar Entrada al Usuario ---
    ; Usa la llamada al sistema sys_write para mostrar el mensaje de solicitud.
    mov rax, 1                                  ; Número de llamada al sistema para sys_write
    mov rdi, 1                                  ; Descriptor de archivo 1: stdout (salida estándar)
    mov rsi, prompt                             ; Dirección de la cadena a escribir (mensaje de solicitud)
    mov rdx, prompt_len                         ; Número de bytes a escribir (longitud de la solicitud)
    syscall                                     ; Invoca al kernel para realizar la operación de escritura

    ; --- Leer Entrada del Usuario ---
    ; Usa la llamada al sistema sys_read para leer desde la entrada estándar.
    sub rsp, 16                                 ; Asigna 16 bytes en la pila para el búfer de entrada.
                                                ; Esto proporciona espacio para entradas como "10\n" más relleno.
    mov rsi, rsp                                ; Apunta RSI al inicio del búfer asignado.
    mov rax, 0                                  ; Número de llamada al sistema para sys_read
    mov rdi, 0                                  ; Descriptor de archivo 0: stdin (entrada estándar)
    mov rdx, 16                                 ; Número máximo de bytes a leer en el búfer (RSI)
    syscall                                     ; Invoca al kernel para realizar la operación de lectura.
                                                ; RAX contendrá el número de bytes realmente leídos.

    ; --- Validación de Entrada (Verificación de Longitud) ---
    ; Verifica el número de bytes leídos (devuelto en RAX) para determinar si la entrada
    ; podría ser un dígito único válido (ej., "5\n" -> 2 bytes) o
    ; el número diez ("10\n" -> 3 bytes). Incluye el carácter de salto de línea.
    cmp rax, 2                                  ; ¿La entrada tiene exactamente 2 bytes de longitud? (ej., '1' + salto de línea)
    je check_single_digit                       ; Si es así, salta para manejar la entrada de un solo dígito.
    cmp rax, 3                                  ; ¿La entrada tiene exactamente 3 bytes de longitud? (ej., '10' + salto de línea)
    je check_ten                                ; Si es así, salta para verificar si es específicamente "10".
    jmp invalid_input                           ; Si no son ni 2 ni 3 bytes, el formato de entrada es inválido.

; ------------------------------------------------------------------------------
; Manejo de Entrada: Verificar "10"
; ------------------------------------------------------------------------------
check_ten:
    ; La longitud de la entrada fue de 3 bytes. Verifica que sea exactamente "10\n".
    movzx eax, byte [rsp]                       ; Carga el primer byte del búfer en EAX (extendido con ceros).
                                                ; Usar movzx asegura que los bits superiores de EAX sean cero.
    cmp eax, '1'                                ; ¿Es el primer carácter '1'?
    jne invalid_input                           ; Si no es '1', salta al manejo de entrada inválida.

    movzx eax, byte [rsp+1]                     ; Carga el segundo byte del búfer en EAX (extendido con ceros).
    cmp eax, '0'                                ; ¿Es el segundo carácter '0'?
    jne invalid_input                           ; Si no es '0', salta al manejo de entrada inválida.

    ; Si llegamos aquí, la entrada es "10\n".
    mov edi, 10                                 ; Establece EDI al valor entero 10. EDI contendrá la adivinanza del usuario.
    jmp valid_input                             ; Salta a la lógica común de validación/comparación.

; ------------------------------------------------------------------------------
; Manejo de Entrada: Verificar un Solo Dígito ('1'-'9')
; ------------------------------------------------------------------------------
check_single_digit:
    ; La longitud de la entrada fue de 2 bytes. Verifica que sea un dígito '1'-'9' seguido de salto de línea.
    movzx eax, byte [rsp]                       ; Carga el primer byte (el dígito) en EAX (extendido con ceros).
    cmp eax, '1'                                ; Compara el valor ASCII con '1'.
    jl invalid_input                            ; Si es menor que '1', es inválido (también maneja el caso '0').
    cmp eax, '9'                                ; Compara el valor ASCII con '9'.
    jg invalid_input                            ; Si es mayor que '9', es inválido.

    ; Si llegamos aquí, el carácter es un dígito válido del '1' al '9'.
    sub eax, '0'                                ; Convierte el carácter de dígito ASCII a su equivalente entero
                                                ; (ej., '5' (0x35) - '0' (0x30) = 5 (0x05)).
    mov edi, eax                                ; Mueve el valor entero resultante a EDI.
    jmp valid_input                             ; Salta a la lógica común de validación/comparación.

; ------------------------------------------------------------------------------
; Manejo de Entrada: Entrada Inválida
; ------------------------------------------------------------------------------
invalid_input:
    ; Muestra el mensaje "¡Entrada inválida!".
    mov rax, 1                                  ; llamada al sistema sys_write
    mov rdi, 1                                  ; stdout
    mov rsi, invalid_msg                        ; Dirección de la cadena del mensaje inválido
    mov rdx, invalid_msg_len                    ; Longitud del mensaje
    syscall                                     ; Invoca al kernel

    ; Limpia la pila de este intento antes de volver al bucle.
    add rsp, 16                                 ; Desasigna el búfer de 16 bytes de la pila.

    jmp game_loop                               ; Salta de vuelta al inicio del bucle del juego para solicitar de nuevo.

; ------------------------------------------------------------------------------
; Manejo de Entrada: Procesamiento de Entrada Válida
; ------------------------------------------------------------------------------
valid_input:
    ; Limpia la pila ahora que la entrada ha sido parseada.
    add rsp, 16                                 ; Desasigna el búfer de 16 bytes de la pila.

    ; --- Validar Rango de Número (Verificación Redundante) ---
    ; Aunque check_single_digit y check_ten manejan implícitamente el rango 1-10,
    ; esto proporciona una salvaguarda explícita. EDI contiene la adivinanza entera parseada.
    cmp edi, 1                                  ; Compara la adivinanza del usuario (EDI) con 1.
    jl invalid_input                            ; Si es menor que 1 (no debería ocurrir con la lógica actual, pero es seguro).
    cmp edi, 10                                 ; Compara la adivinanza del usuario (EDI) con 10.
    jg invalid_input                            ; Si es mayor que 10 (no debería ocurrir).

    ; --- Comparar Adivinanza con Número Objetivo ---
    ; EBX contiene el número aleatorio objetivo generado al inicio.
    ; EDI contiene la adivinanza entera válida del usuario (1-10).
    cmp edi, ebx                                ; Compara la adivinanza (EDI) con el objetivo (EBX).
    je correct                                  ; Si es igual, salta al manejador 'correct'.
    jl too_low                                  ; Si la adivinanza < objetivo (Saltar si es Menor), salta a 'too_low'.
    ; Si no es igual ni menor, debe ser mayor. Continúa hacia 'too_high'.

; ------------------------------------------------------------------------------
; Retroalimentación de Adivinanza: Demasiado Alto
; ------------------------------------------------------------------------------
too_high:
    ; Muestra el mensaje "¡Demasiado alto!".
    mov rax, 1                                  ; llamada al sistema sys_write
    mov rdi, 1                                  ; stdout
    mov rsi, high_msg                           ; Dirección de la cadena del mensaje 'demasiado alto'
    mov rdx, high_msg_len                       ; Longitud del mensaje
    syscall                                     ; Invoca al kernel
    jmp game_loop                               ; Vuelve para otra adivinanza.

; ------------------------------------------------------------------------------
; Retroalimentación de Adivinanza: Demasiado Bajo
; ------------------------------------------------------------------------------
too_low:
    ; Muestra el mensaje "¡Demasiado bajo!".
    mov rax, 1                                  ; llamada al sistema sys_write
    mov rdi, 1                                  ; stdout
    mov rsi, low_msg                            ; Dirección de la cadena del mensaje 'demasiado bajo'
    mov rdx, low_msg_len                        ; Longitud del mensaje
    syscall                                     ; Invoca al kernel
    jmp game_loop                               ; Vuelve para otra adivinanza.

; ------------------------------------------------------------------------------
; Retroalimentación de Adivinanza: Correcta
; ------------------------------------------------------------------------------
correct:
    ; Muestra el mensaje "¡Correcto!".
    mov rax, 1                                  ; llamada al sistema sys_write
    mov rdi, 1                                  ; stdout
    mov rsi, correct_msg                        ; Dirección de la cadena del mensaje 'correcto'
    mov rdx, correct_msg_len                    ; Longitud del mensaje
    syscall                                     ; Invoca al kernel

    ; --- Salir del Programa ---
    ; Usa la llamada al sistema sys_exit para terminar el programa limpiamente.
    mov rax, 60                                 ; Número de llamada al sistema para sys_exit
    xor rdi, rdi                                ; Código de salida 0 (éxito). Hacer XOR de un registro consigo mismo lo pone a cero.
    syscall                                     ; Invoca al kernel para terminar el proceso.

; ==============================================================================
; Fin del Código
; ==============================================================================


