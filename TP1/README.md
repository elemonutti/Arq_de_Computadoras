# TP1 — ALU parametrizable en FPGA



Implementación de una Unidad Aritmético-Lógica (ALU) parametrizable en Verilog,

verificada con un testbench autoverificable y desplegada en una placa Basys 3.



## Estructura



- `design_sources/ALU.v` — módulo combinacional de la ALU (8 operaciones, ancho de datos parametrizable)

- `design_sources/Register.v` — registro genérico con enable y reset (retiene A, B y OP)

- `design_sources/TOP.v` — módulo top-level: conecta switches/botones/LEDs a la ALU

- `simulation_sources/tb_ALU.v` — testbench autoverificable de la ALU (entradas aleatorias + modelo de referencia)

- `simulation_sources/tb_Register.v` — testbench del registro

- `simulation_sources/tb_TOP.v` — testbench de integración del sistema completo

- `constraints/config.xdc` — constraints de pines para la Basys 3



## Operaciones soportadas



| Operación | Código (OP) |
|---|---|
| ADD | 100000 |
| SUB | 100010 |
| AND | 100100 |
| OR  | 100101 |
| XOR | 100110 |
| SRA | 000011 |
| SRL | 000010 |
| NOR | 100111 |



## Simular con Icarus Verilog



```bash

# ALU sola

iverilog -o sim_alu.vvp design_sources/ALU.v simulation_sources/tb_ALU.v

vvp sim_alu.vvp



# Sistema completo (TOP)

iverilog -o sim_top.vvp design_sources/ALU.v design_sources/Register.v design_sources/TOP.v simulation_sources/tb_TOP.v

vvp sim_top.vvp

```



## Implementar en la placa (Basys 3)



1\. Crear proyecto en Vivado con part `xc7a35tcpg236-1`.

2\. Agregar los archivos de `design_sources/` como *Design Sources*.

3\. Agregar `constraints/config.xdc` como *Constraints*.

4\. Run Synthesis → Run Implementation → Generate Bitstream.

5\. Conectar la placa por USB y programarla desde el Hardware Manager.



## Mapeo de E/S en la placa



| Señal          | Botón/switch |
|----------------|--------------|
| `switches[7:0]`| SW0–SW7      |
| `btn_a`        | BTNU (carga A) |
| `btn_b`        | BTND (carga B) |
| `btn_op`       | BTNL (carga OP) |
| `rst`          | BTNC         |
| `leds[7:0]`    | LD0–LD7      |

