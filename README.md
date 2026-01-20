# mips32-pipelined-processor
5-stage pipelined MIPS32 processor implemented in Verilog
Pipelined MIPS32 Processor

Project Overview:
Designed and implemented a 5-stage pipelined MIPS32 processor covering Instruction Fetch (IF), Instruction Decode (ID), Execute (EX), Memory Access (MEM), and Write-Back (WB) stages. The processor efficiently handles data hazards (forwarding, stalls) and control hazards (branch prediction).

Features:

5-stage pipelined architecture for improved instruction throughput.

Forwarding and stall mechanisms to resolve data hazards.

Branch prediction to manage control hazards and minimize pipeline stalls.

Modular Verilog design with separate modules for each pipeline stage.

Testbenches developed to validate instruction execution, branching, and timing.

Skills & Learnings:

RTL design and verification in Verilog.

Understanding and handling pipelining hazards.

Performance analysis and optimization in digital design.

Usage:

Run simulations using the provided Verilog testbenches to verify instruction functionality and pipeline behavior.

Compatible with Xilinx Vivado/ISE for simulation and synthesis.
