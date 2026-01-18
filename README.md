# 16-bit FPGA Calculator (SystemVerilog)

A hardware-based 16-bit calculator implemented in SystemVerilog for Xilinx Artix-7 FPGAs. This project features a custom Finite State Machine (FSM) for operation sequencing, a hybrid clock architecture to meet timing constraints, and a multiplexed 7-segment display driver with real-time Binary-to-BCD conversion.

![Project Demo](https://via.placeholder.com/800x400?text=Place+Your+FPGA+Board+Photo+Here)
*(Add a photo or GIF of your board working here)*

## 🚀 Features

* **Operations:** Addition, Subtraction, Multiplication, Division.
* **Input:** 16-bit signed integers via physical switches (`SW[15:0]`).
* **Output:** 8-digit Multiplexed 7-Segment Display (Decimal format).
* **Logic:**
    * Handling of negative numbers (Absolute value display with sign logic).
    * Debounced button inputs for operation selection.
    * Zero-division protection.

## 🛠 Hardware Architecture

The design uses a **Hybrid Clock Domain** strategy to solve timing violations (Negative Slack) caused by complex combinational paths (like 32-bit division) while maintaining visual stability.

### 1. The Clock Domains
* **Logic Domain (5 MHz):** A `clock_divider` reduces the main 100MHz system clock to 5MHz. The heavy arithmetic logic (FSM, ALU) runs here to allow signal propagation through long combinational chains without violating setup times.
* **Display Domain (100 MHz):** The 7-segment multiplexing runs on the native 100MHz clock to ensure a refresh rate of ~95Hz, preventing visible flicker (Persistence of Vision).

### 2. Module Hierarchy
* `calculator.sv` (Top Module): Hybrid clock management, FSM, and datapath integration.
* `clock_divider.sv`: Generates the 5MHz slow clock.
* `bin32_to_bcd.sv`: Implements the "Double Dabble" algorithm to convert 32-bit binary totals to BCD for the display.
* `seven_segment.sv`: Hex-to-7-segment decoder.

### 3. State Machine (FSM)
The control logic follows a 3-state Mealy machine:
1.  **IDLE:** Waits for Operand A input.
2.  **BTN_PRESS:** Latches Operand A and waits for Operand B + Calculate command.
3.  **RESULT:** Displays the total until reset.

## 🔌 Pinout Mapping (Example: Basys3 / Nexys A7)

| Port Name | Physical Component | Function |
| :--- | :--- | :--- |
| `CLK100MHZ` | W5 (System Clock) | Main Clock Source |
| `SW[15:0]` | Switches 0-15 | Binary Input (Operand A/B) |
| `BTNU` | Button Up | **Add (+)** |
| `BTND` | Button Down | **Subtract (-)** |
| `BTNL` | Button Left | **Multiply (*)** |
| `BTNR` | Button Right | **Divide (/)** |
| `BTNC` | Button Center | **Calculate (=)** |
| `AN[7:0]` | 7-Seg Anodes | Digit Selection |
| `out[7:0]` | 7-Seg Cathodes | Segment Activation |

## 💻 Simulation & Synthesis

This project was developed and synthesized using **Xilinx Vivado**.

### Timing Report
* **WNS (Worst Negative Slack):** > 0ns (PASSED)
* **TNS (Total Negative Slack):** 0ns (PASSED)
* *Note: Timing closure was achieved by relaxing the ALU clock to 5MHz.*

## 🚀 How to Run

1.  Clone the repository:
    ```bash
    git clone [https://github.com/Osmanyasal/fpga-calculator.git](https://github.com/Osmanyasal/fpga-calculator.git)
    ```
2.  Open **Vivado** and create a new RTL project.
3.  Add the SystemVerilog files (`.sv`) from the `src/` folder.
4.  Add the Constraints file (`.xdc`) for your specific board.
5.  Run **Synthesis** -> **Implementation** -> **Generate Bitstream**.
6.  Program your device via Hardware Manager.

## 📝 Author

**Osman Yasal**
* [LinkedIn](https://www.linkedin.com/in/osmanyasal/)
* [GitHub](https://github.com/Osmanyasal)

---
*If you find this project helpful, please give it a star! ⭐*
