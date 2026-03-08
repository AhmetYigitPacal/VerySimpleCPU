module VSCPU_tb;
    reg clk;
    reg rst;
    wire wrEn;
    wire [31:0] data_fromRAM;
    wire [31:0] data_toRAM;
    wire [13:0] addr;

    // Instantiate the RAM
    blram ram (
        .clk(clk),
        .rst(rst),
        .we(wrEn),
        .addr(addr),
        .din(data_toRAM),
        .dout(data_fromRAM)
    );

    // Instantiate the CPU
    VSCPU cpu (
        .clk(clk),
        .rst(rst),
        .data_fromRAM(data_fromRAM),
        .wrEn(wrEn),
        .addr(addr),
        .data_toRAM(data_toRAM)
    );

    // Generate Clock
    always #5 clk = ~clk;

    // Load the Program and Run
    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        
        // Load program into RAM
        ram.mem[0]  = 32'h901b8003; ram.mem[1]  = 32'h00190065; ram.mem[2]  = 32'he0190066;
        ram.mem[3]  = 32'h50198001; ram.mem[4]  = 32'h801a0064; ram.mem[5]  = 32'h101a0005;
        ram.mem[6]  = 32'h201a006c; ram.mem[7]  = 32'h301a0005; ram.mem[8]  = 32'h401b0066;
        ram.mem[9]  = 32'hf01b0003; ram.mem[10] = 32'h001b8067; ram.mem[11] = 32'h801c006e;
        ram.mem[12] = 32'h601c006f; ram.mem[13] = 32'hc01bc070; ram.mem[14] = 32'hd019400b;
        ram.mem[19] = 32'hf0194003; ram.mem[20] = 32'h801a4066; ram.mem[21] = 32'h701a4002;
        ram.mem[22] = 32'hc01c4069; ram.mem[35] = 32'hd01bc035; ram.mem[54] = 32'hb01c806f;
        ram.mem[55] = 32'ha01e4066;
        
        // Load data into RAM
        ram.mem[100] = 32'h5;        ram.mem[101] = 32'h8;        ram.mem[102] = 32'h10;
        ram.mem[103] = 32'hffffffff; ram.mem[108] = 32'h10007;    ram.mem[111] = 32'h1;
        ram.mem[113] = 32'h23;       ram.mem[114] = 32'h78;

        #20 rst = 0; // Release reset

        // Wait for simulation to finish
        #2400;
        $display("Simulation Finished.");
        $finish;
    end

    reg [31:0] before_val_A, before_val_B, before_val_CPI, before_val_CPIi;
    integer target_addr_A, target_addr_B;
    
    always @(posedge clk) begin
        if (cpu.st == 3'd4) begin
            // Target the destination address from the instruction register
            target_addr_A = cpu.IW[27:14];
            target_addr_B = cpu.IW[13:0];
    
            // Capture value before the clock edge completes the write
            before_val_A = ram.mem[target_addr_A];
            before_val_B = ram.mem[target_addr_B];
            before_val_CPI = ram.mem[before_val_B];
            before_val_CPIi = ram.mem[before_val_A];
            
            // Wait for the write to finish in the simulation
            #2; 
            
            $display("* * * * * * * * * * * * * * * * * * * * * * * * *");
            case(cpu.IW[31:28])
                4'b0000: $write("    current_instruction: ADD   %d %d", cpu.IW[27:14], cpu.IW[13:0]);
                4'b0001: $write("    current_instruction: ADDi  %d %d", cpu.IW[27:14], cpu.IW[13:0]);
                4'b0010: $write("    current_instruction: NAND  %d %d", cpu.IW[27:14], cpu.IW[13:0]);
                4'b0011: $write("    current_instruction: NANDi %d %d", cpu.IW[27:14], cpu.IW[13:0]);
                4'b0100: $write("    current_instruction: SRL   %d %d", cpu.IW[27:14], cpu.IW[13:0]);
                4'b0101: $write("    current_instruction: SRLi  %d %d", cpu.IW[27:14], cpu.IW[13:0]);
                4'b0110: $write("    current_instruction: LT    %d %d", cpu.IW[27:14], cpu.IW[13:0]);
                4'b0111: $write("    current_instruction: LTi   %d %d", cpu.IW[27:14], cpu.IW[13:0]);
                4'b1000: $write("    current_instruction: CP    %d %d", cpu.IW[27:14], cpu.IW[13:0]);
                4'b1001: $write("    current_instruction: CPi   %d %d", cpu.IW[27:14], cpu.IW[13:0]);
                4'b1010: $write("    current_instruction: CPI   %d %d", cpu.IW[27:14], cpu.IW[13:0]);
                4'b1011: $write("    current_instruction: CPIi  %d %d", cpu.IW[27:14], cpu.IW[13:0]);
                4'b1100: $write("    current_instruction: BZJ   %d %d", cpu.IW[27:14], cpu.IW[13:0]);
                4'b1101: $write("    current_instruction: BZJi  %d %d", cpu.IW[27:14], cpu.IW[13:0]);
                4'b1110: $write("    current_instruction: MUL   %d %d", cpu.IW[27:14], cpu.IW[13:0]);
                4'b1111: $write("    current_instruction: MULi  %d %d", cpu.IW[27:14], cpu.IW[13:0]);
            endcase
            
            $display("\n    next program counter     : %d", cpu.PC);
            $display("    Memory content before executing instruction");
            $display("    mem[ %d ]          : %d", target_addr_A, before_val_A);
            if(!cpu.IW[28] || cpu.IW[31:29] == 3'b101)
                $display("    mem[ %d ]          : %d", target_addr_B, before_val_B);
            if(cpu.IW[31:29] == 3'b101)
                if(cpu.IW[28]) $display("    mem[ %d ]          : %d", before_val_A, before_val_CPIi);
                else $display("    mem[ %d ]          : %d", before_val_B, before_val_CPI);
            
                
            $display("    Memory content after executing instruction");
            $display("    mem[ %d ]          : %d", target_addr_A, ram.mem[target_addr_A]);
            if(!cpu.IW[28] || cpu.IW[31:29] == 3'b101)
                $display("    mem[ %d ]          : %d", target_addr_B, ram.mem[target_addr_B]);
            if(cpu.IW[31:29] == 3'b101)
                if(cpu.IW[28]) $display("    mem[ %d ]          : %d", before_val_A, ram.mem[before_val_A]);
                else $display("    mem[ %d ]          : %d", before_val_B, ram.mem[before_val_B]);
            $display("* * * * * * * * * * * * * * * * * * * * * * * * * \n");
        end
    end

endmodule