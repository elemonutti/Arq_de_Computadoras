"""
TP2 - UART + ALU
Script de la PC: manda A, B y OP a la Basys 3 por puerto serie
y muestra el resultado que devuelve la placa.

Uso:
    python uart_alu.py COM5            -> modo interactivo
    python uart_alu.py COM5 --test     -> prueba automatica de las 8 operaciones
"""

import argparse
import random
import sys

import serial

BAUD_RATE = 19200

# Codigos de operacion (los mismos de la ALU del TP1)
OPS = {
    "ADD": 0b100000,
    "SUB": 0b100010,
    "AND": 0b100100,
    "OR":  0b100101,
    "XOR": 0b100110,
    "SRA": 0b000011,
    "SRL": 0b000010,
    "NOR": 0b100111,
}


def modelo(a, b, op):
    """Resultado esperado, igual que la ALU del TP1 (8 bits)."""
    if op == "ADD":
        r = a + b
    elif op == "SUB":
        r = a - b
    elif op == "AND":
        r = a & b
    elif op == "OR":
        r = a | b
    elif op == "XOR":
        r = a ^ b
    elif op == "SRA":
        a_signed = a - 256 if a & 0x80 else a
        r = a_signed >> b if b < 8 else (-1 if a_signed < 0 else 0)
    elif op == "SRL":
        r = a >> b
    elif op == "NOR":
        r = ~(a | b)
    else:
        r = 0
    return r & 0xFF


def operar(puerto, a, b, op):
    """Manda A, B, OP y lee el byte de resultado. Devuelve None si no hubo respuesta."""
    puerto.reset_input_buffer()
    puerto.write(bytes([a, b, OPS[op]]))
    respuesta = puerto.read(1)
    return respuesta[0] if respuesta else None


def leer_numero(texto):
    """Acepta decimal (25), hexa (0x19) o binario (0b11001)."""
    while True:
        valor = input(texto).strip()
        try:
            n = int(valor, 0)
            if 0 <= n <= 255:
                return n
        except ValueError:
            pass
        print("  Numero invalido: tiene que estar entre 0 y 255 (ej: 25, 0x19, 0b11001)")


def mostrar(a, b, op, res):
    esperado = modelo(a, b, op)
    if res is None:
        print(f"  {op}: sin respuesta de la placa (revisar puerto, reset o bitstream)")
        return False
    estado = "OK" if res == esperado else f"ERROR (esperado {esperado})"
    print(f"  A={a:3d} (0b{a:08b})  B={b:3d} (0b{b:08b})  {op:<3} -> "
          f"{res:3d} (0x{res:02X}, 0b{res:08b})  {estado}")
    return res == esperado


def modo_interactivo(puerto):
    print("Operaciones:", ", ".join(OPS))
    print("Ctrl+C para salir.\n")
    while True:
        a = leer_numero("A  = ")
        b = leer_numero("B  = ")
        op = input("OP = ").strip().upper()
        if op not in OPS:
            print("  Operacion invalida\n")
            continue
        mostrar(a, b, op, operar(puerto, a, b, op))
        print()


def modo_test(puerto, por_op=5):
    casos = [(15, 10, "ADD"), (0b10000000, 3, "SRA"), (0b10000000, 3, "SRL")]
    for op in OPS:
        for _ in range(por_op):
            casos.append((random.randint(0, 255), random.randint(0, 255), op))

    errores = 0
    for a, b, op in casos:
        if not mostrar(a, b, op, operar(puerto, a, b, op)):
            errores += 1

    print()
    if errores == 0:
        print(f"PRUEBA EN PLACA OK: {len(casos)} operaciones sin errores")
    else:
        print(f"PRUEBA EN PLACA FALLO: {errores} errores en {len(casos)} operaciones")


def main():
    parser = argparse.ArgumentParser(description="Cliente UART para la ALU del TP2")
    parser.add_argument("puerto", help="Puerto serie de la Basys 3, ej: COM5")
    parser.add_argument("--test", action="store_true", help="Prueba automatica de todas las operaciones")
    args = parser.parse_args()

    try:
        puerto = serial.Serial(args.puerto, BAUD_RATE, bytesize=8, parity="N",
                               stopbits=1, timeout=1)
    except serial.SerialException as e:
        print(f"No se pudo abrir {args.puerto}: {e}")
        sys.exit(1)

    with puerto:
        print(f"Conectado a {args.puerto} a {BAUD_RATE} baudios (8N1)\n")
        try:
            if args.test:
                modo_test(puerto)
            else:
                modo_interactivo(puerto)
        except KeyboardInterrupt:
            print("\nChau!")


if __name__ == "__main__":
    main()