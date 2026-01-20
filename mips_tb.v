// Vivado-Compatible Testbench for MIPS32 Pipelined Processor
`timescale 1ns/1ps

module tb_mips32_pipeline;

    // Clock signals
    reg clk1, clk2;
    wire HALTED;
    
    // Test control
    integer i;
    integer errors;
    
    // Instantiate the processor
    MIPS32_TOP processor(
        .clk1(clk1),
        .clk2(clk2),
        .HALTED(HALTED)
    );
    
    // Clock generation (Two-phase non-overlapping clocks)
    initial begin
        clk1 = 0;
        clk2 = 0;
        repeat(200) begin
            #5 clk1 = 1; #5 clk1 = 0;  // clk1 phase
            #5 clk2 = 1; #5 clk2 = 0;  // clk2 phase
        end
    end
    
    // Initialize instruction and data memory
    initial begin
        // Wait a bit for proper initialization
        #2;
        
        // Initialize instruction memory with test program
        load_instruction_memory();
        
        // Initialize data memory
        initialize_data_memory();
        
        // Initialize register file (optional since ID stage does it)
        initialize_registers();
    end
    
    // Task to load instruction memory
    task load_instruction_memory;
        begin
            $display("Loading instruction memory...");
            
            // Test Program: Comprehensive test with hazards
            
            // Test 1: Simple ALU operations
            processor.IF.Mem[0] = 32'h2801000A;  // ADDI R1, R0, 10      | R1 = 10
            processor.IF.Mem[1] = 32'h28020014;  // ADDI R2, R0, 20      | R2 = 20
            processor.IF.Mem[2] = 32'h00222000;  // ADD  R4, R1, R2      | R4 = 30 (RAW hazard)
            processor.IF.Mem[3] = 32'h00442800;  // ADD  R5, R2, R4      | R5 = 50 (RAW hazard)
            processor.IF.Mem[4] = 32'h0C630001;  // OR   R6, R3, R3      | R6 = 0
            
            // Test 2: Load-Use hazard (requires stall)
            processor.IF.Mem[5] = 32'h2003001E;  // LW   R3, 30(R0)      | R3 = Mem[30] = 100
            processor.IF.Mem[6] = 32'h00233800;  // ADD  R7, R1, R3      | R7 = 110 (STALL)
            
            // Test 3: More ALU operations
            processor.IF.Mem[7] = 32'h04A24000;  // SUB  R8, R5, R2      | R8 = 30
            processor.IF.Mem[8] = 32'h14224800;  // SLT  R9, R1, R2      | R9 = 1
            processor.IF.Mem[9] = 32'h14825000;  // SLT  R10, R4, R2     | R10 = 0
            
            // Test 4: Store and Load
            processor.IF.Mem[10] = 32'h24050032; // SW   R5, 50(R0)      | Mem[50] = 50
            processor.IF.Mem[11] = 32'h2005002D; // LW   R5, 45(R0)      | R5 = 200
            
            // Test 5: Branch not equal to zero
            processor.IF.Mem[12] = 32'h28060001; // ADDI R6, R0, 1       | R6 = 1
            processor.IF.Mem[13] = 32'h34C00002; // BNEQZ R6, 2          | Branch taken
            processor.IF.Mem[14] = 32'h280B0064; // ADDI R11, R0, 100    | SKIPPED
            processor.IF.Mem[15] = 32'h280C0064; // ADDI R12, R0, 100    | SKIPPED
            processor.IF.Mem[16] = 32'h280D0001; // ADDI R13, R0, 1      | R13 = 1
            
            // Test 6: Branch equal to zero
            processor.IF.Mem[17] = 32'h28000000; // ADDI R0, R0, 0       | R0 = 0
            processor.IF.Mem[18] = 32'h38000002; // BEQZ R0, 2           | Branch taken
            processor.IF.Mem[19] = 32'h280E0064; // ADDI R14, R0, 100    | SKIPPED
            processor.IF.Mem[20] = 32'h280F0064; // ADDI R15, R0, 100    | SKIPPED
            processor.IF.Mem[21] = 32'h28100001; // ADDI R16, R0, 1      | R16 = 1
            
            // Test 7: Multiplication
            processor.IF.Mem[22] = 32'h14228800; // MUL  R17, R1, R2     | R17 = 200
            
            // Test 8: AND operation
            processor.IF.Mem[23] = 32'h28120015; // ADDI R18, R0, 21     | R18 = 21
            processor.IF.Mem[24] = 32'h2813000F; // ADDI R19, R0, 15     | R19 = 15
            processor.IF.Mem[25] = 32'h0872A000; // AND  R20, R19, R18   | R20 = 5
            
            // Test 9: Final calculations
            processor.IF.Mem[26] = 32'h0044A800; // ADD  R21, R2, R4     | R21 = 50
            processor.IF.Mem[27] = 32'h04A2B000; // SUB  R22, R5, R2     | R22 = 180
            
            // Halt
            processor.IF.Mem[28] = 32'hFC000000; // HLT
            
            // Fill rest with HALT
            for (i = 29; i < 1024; i = i + 1) begin
                processor.IF.Mem[i] = 32'hFC000000;
            end
            
            $display("Instruction memory loaded successfully.");
        end
    endtask
    
    // Task to initialize data memory
    task initialize_data_memory;
        begin
            $display("Initializing data memory...");
            
            processor.MEM.Mem[30] = 32'd100;   // For LW test
            processor.MEM.Mem[45] = 32'd200;   // For LW test
            
            // Initialize rest to zero
            for (i = 0; i < 1024; i = i + 1) begin
                if (i != 30 && i != 45)
                    processor.MEM.Mem[i] = 32'd0;
            end
            
            $display("Data memory initialized.");
        end
    endtask
    
    // Task to initialize register file
    task initialize_registers;
        begin
            $display("Initializing register file...");
            for (i = 0; i < 32; i = i + 1) begin
                processor.ID.RegFile[i] = 32'd0;
            end
            $display("Register file initialized.");
        end
    endtask
    
    // Monitor signals during simulation
    initial begin
        $display("\n================================================================================");
        $display("        MIPS32 5-Stage Pipelined Processor Testbench (Vivado)");
        $display("================================================================================");
        $display("Testing: ALU ops, Load/Store, Hazards, Forwarding, Branches");
        $display("================================================================================\n");
        
        // Monitor key signals
        $monitor("Time=%0t | PC=%0d | HALTED=%b | Stall=%b | FwdA=%b | FwdB=%b | BRANCH=%b", 
                 $time, processor.PC, HALTED, processor.Stall, 
                 processor.ForwardA, processor.ForwardB, processor.TAKEN_BRANCH);
    end
    
    // Display pipeline state at intervals
    initial begin
        #50;
        $display("\n>>> Pipeline execution started...\n");
        
        #100;
        display_pipeline_state();
        
        #100;
        display_pipeline_state();
        
        #150;
        display_pipeline_state();
        
        // Wait for HALT
        wait(HALTED == 1);
        
        #50;  // Allow final writes to complete
        
        $display("\n================================================================================");
        $display("                       SIMULATION COMPLETE - HALTED");
        $display("================================================================================\n");
        
        display_registers();
        display_memory(30, 60);
        verify_results();
        
        $display("\n================================================================================");
        $display("                         END OF TESTBENCH");
        $display("================================================================================\n");
        
        $finish;
    end
    
    // Display pipeline state
    task display_pipeline_state;
        begin
            $display("\n========== Pipeline State at Time %0t ==========", $time);
            $display("IF:  PC=%0d, IR=%h", processor.PC, processor.IF_ID_IR);
            $display("ID:  IR=%h, Type=%b", processor.ID_EX_IR, processor.ID_EX_TYPE);
            $display("     A=%0d, B=%0d, IMM=%0d", processor.ID_EX_A, processor.ID_EX_B, processor.ID_EX_IMM);
            $display("EX:  IR=%h, ALUOUT=%0d", processor.EX_MEM_IR, processor.EX_MEM_ALUOUT);
            $display("MEM: IR=%h, ALUOUT=%0d", processor.MEM_WB_IR, processor.MEM_WB_ALUOUT);
            $display("WB:  RegWr=%b, rd=R%0d, Data=%0d", processor.WB_RegWrite, processor.WB_rd, processor.WB_data);
            $display("Hazards: Stall=%b, FwdA=%b, FwdB=%b", 
                     processor.Stall, processor.ForwardA, processor.ForwardB);
            $display("================================================\n");
        end
    endtask
    
    // Display register file contents
    task display_registers;
        begin
            $display("\n========== Register File Contents ==========");
            for (i = 0; i < 32; i = i + 4) begin
                $display("R%-2d=%0d\t\tR%-2d=%0d\t\tR%-2d=%0d\t\tR%-2d=%0d", 
                         i, processor.ID.RegFile[i],
                         i+1, processor.ID.RegFile[i+1],
                         i+2, processor.ID.RegFile[i+2],
                         i+3, processor.ID.RegFile[i+3]);
            end
            $display("============================================\n");
        end
    endtask
    
    // Display memory contents
    task display_memory;
        input integer start_addr;
        input integer end_addr;
        begin
            $display("\n========== Memory [%0d:%0d] ==========", start_addr, end_addr);
            for (i = start_addr; i <= end_addr; i = i + 1) begin
                if (processor.MEM.Mem[i] != 0)
                    $display("Mem[%0d] = %0d (0x%h)", i, processor.MEM.Mem[i], processor.MEM.Mem[i]);
            end
            $display("====================================\n");
        end
    endtask
    
    // Verify expected results
    task verify_results;
        begin
            errors = 0;
            $display("\n========== Verifying Results ==========");
            
            // R1 = 10
            if (processor.ID.RegFile[1] !== 32'd10) begin
                $display("FAIL: R1=%0d, expected 10", processor.ID.RegFile[1]);
                errors = errors + 1;
            end else
                $display("PASS: R1 = %0d", processor.ID.RegFile[1]);
            
            // R2 = 20
            if (processor.ID.RegFile[2] !== 32'd20) begin
                $display("FAIL: R2=%0d, expected 20", processor.ID.RegFile[2]);
                errors = errors + 1;
            end else
                $display("PASS: R2 = %0d", processor.ID.RegFile[2]);
            
            // R4 = 30
            if (processor.ID.RegFile[4] !== 32'd30) begin
                $display("FAIL: R4=%0d, expected 30", processor.ID.RegFile[4]);
                errors = errors + 1;
            end else
                $display("PASS: R4 = %0d (forwarding)", processor.ID.RegFile[4]);
            
            // R5 = 200 (updated by LW)
            if (processor.ID.RegFile[5] !== 32'd200) begin
                $display("FAIL: R5=%0d, expected 200", processor.ID.RegFile[5]);
                errors = errors + 1;
            end else
                $display("PASS: R5 = %0d (load)", processor.ID.RegFile[5]);
            
            // R3 = 100
            if (processor.ID.RegFile[3] !== 32'd100) begin
                $display("FAIL: R3=%0d, expected 100", processor.ID.RegFile[3]);
                errors = errors + 1;
            end else
                $display("PASS: R3 = %0d (load-use)", processor.ID.RegFile[3]);
            
            // R7 = 110
            if (processor.ID.RegFile[7] !== 32'd110) begin
                $display("FAIL: R7=%0d, expected 110", processor.ID.RegFile[7]);
                errors = errors + 1;
            end else
                $display("PASS: R7 = %0d (after stall)", processor.ID.RegFile[7]);
            
            // R9 = 1
            if (processor.ID.RegFile[9] !== 32'd1) begin
                $display("FAIL: R9=%0d, expected 1", processor.ID.RegFile[9]);
                errors = errors + 1;
            end else
                $display("PASS: R9 = %0d (SLT)", processor.ID.RegFile[9]);
            
            // R10 = 0
            if (processor.ID.RegFile[10] !== 32'd0) begin
                $display("FAIL: R10=%0d, expected 0", processor.ID.RegFile[10]);
                errors = errors + 1;
            end else
                $display("PASS: R10 = %0d (SLT)", processor.ID.RegFile[10]);
            
            // R17 = 200
            if (processor.ID.RegFile[17] !== 32'd200) begin
                $display("FAIL: R17=%0d, expected 200", processor.ID.RegFile[17]);
                errors = errors + 1;
            end else
                $display("PASS: R17 = %0d (MUL)", processor.ID.RegFile[17]);
            
            // Mem[50] = 50
            if (processor.MEM.Mem[50] !== 32'd50) begin
                $display("FAIL: Mem[50]=%0d, expected 50", processor.MEM.Mem[50]);
                errors = errors + 1;
            end else
                $display("PASS: Mem[50] = %0d (store)", processor.MEM.Mem[50]);
            
            // R11, R12 should be 0 (branch skipped)
            if (processor.ID.RegFile[11] !== 32'd0 || processor.ID.RegFile[12] !== 32'd0) begin
                $display("FAIL: Branch - R11=%0d, R12=%0d", 
                         processor.ID.RegFile[11], processor.ID.RegFile[12]);
                errors = errors + 1;
            end else
                $display("PASS: BNEQZ - R11=%0d, R12=%0d (skipped)", 
                         processor.ID.RegFile[11], processor.ID.RegFile[12]);
            
            // R13 = 1
            if (processor.ID.RegFile[13] !== 32'd1) begin
                $display("FAIL: R13=%0d, expected 1", processor.ID.RegFile[13]);
                errors = errors + 1;
            end else
                $display("PASS: R13 = %0d (after branch)", processor.ID.RegFile[13]);
            
            $display("\n========================================");
            if (errors == 0) begin
                $display("     ALL TESTS PASSED!");
                $display("     Total: 12/12 tests passed");
            end else begin
                $display("     SOME TESTS FAILED!");
                $display("     Failed: %0d tests", errors);
            end
            $display("========================================\n");
        end
    endtask
    
    // Timeout watchdog
    initial begin
        #20000;
        $display("\nERROR: Simulation timeout after 20000ns!");
        $display("Check for infinite loops or missing HALT instruction.\n");
        $finish;
    end

endmodule