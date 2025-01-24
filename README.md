Verilog Code for FPGA on 6809 Microprocessor Training Lab from Cleveland Institute of Electronics
Uses LCMXO2-1200HC-4TG100C Lattice FPGA

+----------------------------+
|        Host PC             |
|  +----------------------+  |
|  | Program Upload Tool   |<--> USB (to FPGA)
|  +----------------------+  |
+----------------------------+
          |
          |
+----------------------------+
|        FPGA Controller     |
|  +----------------------+  |
|  | Address Decoding       |<-- 6809 Address Bus (A0–A15)
|  | SRAM Control Logic     |<--> SRAM (temporary storage)
|  | SPI Flash Control      |<--> SPI Flash (permanent storage)
|  | USB Communication      |<--> USB
|  | Bus Arbitration        |<--> 6809 Data Bus (D0–D7)
|  +----------------------+  |
+----------------------------+
          |               |
          |               |
+---------+-----+   +-----+---------+
|       SRAM    |   |     SPI Flash |
+---------------+   +---------------+
          |
  +------------------+
  | Edge Connector   |
  +------------------+
          |
+--------------------+
|    6809 CPU        |
+--------------------+

