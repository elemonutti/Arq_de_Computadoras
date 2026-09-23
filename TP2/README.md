\# TP2 — UART con Máquinas de Estado Finitas



Implementación de una \*\*UART\*\* (Universal Asynchronous Receiver and Transmitter) en Verilog,

diseñada con máquinas de estado finitas y conectada a la ALU del TP1. La PC envía los

operandos y el código de operación por puerto serie, y la placa Basys 3 devuelve el resultado.



\## Arquitectura





\## Estructura



\- `design\_sources/baud\_rate\_gen.v` — genera un tick 16 veces por bit (contador módulo 326 a 100 MHz / 19200 baudios)

\- `design\_sources/uart\_rx.v` — receptor: FSM `IDLE → START → DATA → STOP`, muestrea en la mitad de cada bit

\- `design\_sources/uart\_tx.v` — transmisor: FSM `IDLE → START → DATA → STOP`, salida registrada

\- `design\_sources/alu\_interface.v` — FSM propia: recibe A, B y OP, dispara la ALU y envía el resultado

\- `design\_sources/ALU.v` — ALU del TP1, sin modificaciones

\- `design\_sources/uart\_top.v` — módulo top: conecta todos los bloques

\- `simulation\_sources/tb\_baud\_rate\_gen.v` — verifica que el tick salga cada 326 ciclos

\- `simulation\_sources/tb\_uart\_loopback.v` — conecta Tx con Rx y verifica bytes de ida y vuelta

\- `simulation\_sources/tb\_uart\_top.v` — simula a la PC: envía A, B, OP por serie y verifica el resultado

\- `constraints/uart\_top.xdc` — pines de la Basys 3 (clock, reset, USB-UART y LEDs)

\- `pc/uart\_alu.py` — script de la PC para operar la ALU por puerto serie



\## Protocolo



Configuración serie: \*\*19200 baudios, 8 bits de datos, sin paridad, 1 stop bit (8N1)\*\*.



| Orden | Dirección | Contenido |

|---|---|---|

| 1 | PC → placa | Operando A (8 bits) |

| 2 | PC → placa | Operando B (8 bits) |

| 3 | PC → placa | Código de operación (6 bits bajos del byte) |

| 4 | placa → PC | Resultado (8 bits) |



Además, los LEDs LD0–LD7 muestran el último resultado.



\## Operaciones soportadas



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



\## Simular



En Vivado: elegir el testbench con \*Set as Top\* → \*Run Behavioral Simulation\* → en la Tcl Console, `run all`.



Con Icarus Verilog:



```bash

iverilog -o sim.vvp -s tb\_uart\_top design\_sources/\*.v simulation\_sources/\*.v

vvp sim.vvp

```



\## Implementar en la placa (Basys 3)



1\. Crear proyecto en Vivado con part `xc7a35tcpg236-1`.

2\. Agregar `design\_sources/` como \*Design Sources\*, `simulation\_sources/` como \*Simulation Sources\* y `constraints/uart\_top.xdc` como \*Constraints\*.

3\. Generate Bitstream y programar la placa desde el Hardware Manager.



\## Probar desde la PC



```powershell

py -m pip install pyserial

py -m serial.tools.list\_ports -v              # buscar el puerto de la Basys 3 (VID:PID 0403:6010)

py pc/uart\_alu.py COM5                        # modo interactivo

py pc/uart\_alu.py COM5 --test                 # prueba automática de las 8 operaciones

```



\## Resultados



| Prueba | Resultado |

|---|---|

| `tb\_baud\_rate\_gen` | 20/20 intervalos de 326 ciclos |

| `tb\_uart\_loopback` | 14/14 bytes sin errores |

| `tb\_uart\_top` | 19/19 operaciones sin errores |

| Placa (`uart\_alu.py --test`) | 43/43 operaciones sin errores |

| Utilización | 132 LUT, 81 FF |

| Timing | WNS = 4,353 ns, WHS = 0,178 ns (cumple a 100 MHz) |



\## Mapeo de E/S en la placa



| Señal | Recurso |

|---|---|

| `clk` | Oscilador de 100 MHz (W5) |

| `reset` | BTNC (U18) |

| `rx` | USB-UART, PC → FPGA (B18) |

| `tx` | USB-UART, FPGA → PC (A18) |

| `leds\[7:0]` | LD0–LD7 |

