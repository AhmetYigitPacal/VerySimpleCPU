module VSCPU (clk, rst, data_fromRAM, wrEn, addr, data_toRAM);
    input clk, rst;
    output reg wrEn;
    input [31:0] data_fromRAM;
    output reg [31:0] data_toRAM;
    output reg [13:0] addr;
    reg [2:0] st, stN;
    reg [13:0] PC, PCN;
    reg [31:0] IW, IWN;
    reg [31:0] R1, R1N;
    reg [31:0] R2, R2N;
      
    always @(posedge clk) begin
        st <= stN;
        PC <= PCN;
        IW <= IWN;
        R1 <= R1N;
        R2 <= R2N;
    end
      
    always @(*) begin
        if (rst) begin
            stN = 3'd0;
            PCN = 14'd0;
        end
        
        else begin
            wrEn = 1'b0;
            PCN = PC;
            IWN = IW;
            stN = st;
            addr = 14'hX;
            data_toRAM = 32'hX;
            R1N = R1;
            R2N = R2;
            
            case (st)
                3'd0: begin // Fetch
                    addr = PC; // address <- PC
                    stN = 3'd1;
                end
                
                3'd1: begin // Decode
                    IWN = data_fromRAM; // IW <- mem[PC] 
                    stN = 3'd2;      
                    
                    case(data_fromRAM[31:28])
                        default: addr = data_fromRAM[27:14]; // address <- A
                        4'b1000, 4'b1001: addr = 14'hX; // CP, CPi: address <- X
                        4'b1010: addr = data_fromRAM[13:0]; // CPI: address <- B
                    endcase 
                end
                
                3'd2: begin // Load R1/R2
                    if(IW[31:29] != 3'b100) R1N = data_fromRAM; // R1 <- mem[address]
                    
                    if(IW[28] && IW[31:29] != 3'b101) begin // Immidiate except CPIi
                        stN = 3'd4;
                        R2N = IW[13:0]; // R2 <- B
                    end else begin // Non-immidiate and CPIi
                        stN = 3'd3;
                        if(IW[31:28] == 4'b1010) addr = R1N; // CPI: address <- mem[R1]
                        else addr = IW[13:0]; // address <- B
                    end
                end
                
                3'd3: begin // Load R2
                    R2N = data_fromRAM; // R2 <- mem[adress]
                    stN = 3'd4;
                end
                
                3'd4: begin // Execute
                    wrEn = 1'b1;
                    addr = IW[27:14]; // address <- A
                    PCN = PC + 14'd1; // PC <- PC + 1
                    stN = 3'd0; 
                
                    case(IW[31:29])
                        3'b000: begin
                            if(IW[13] == 1) data_toRAM = R1 - (~R2 + 1); // SUB SUBi
                            else data_toRAM = R1 + R2; // ADD ADDi
                        end
                        3'b001: data_toRAM = ~(R1 & R2); // NAND NANDi
                        3'b010: data_toRAM = (R2 < 32) ? (R1 >> R2) : (R1 << (R2 - 32)); // SRL SRLi
                        3'b011: data_toRAM = (R1 < R2) ? 1 : 0; // LT LTi
                        3'b100: data_toRAM = R2; // CP CPi
                        3'b101: begin // CPI, CPIi
                            if(IW[28]) addr = R1; // CPIi: address <- R1
                            data_toRAM = R2;
                        end 
                        3'b110: begin
                            wrEn = 1'b0;
                            if(IW[28]) PCN = (R1 + R2); // BZJi
                            else PCN = (R2 == 0) ? R1 : (PC + 1); // BZJ
                        end
                        3'b111: data_toRAM = R1 * R2; // MUL MULi
                    endcase
                end
            endcase
        end // else
    end // always
endmodule