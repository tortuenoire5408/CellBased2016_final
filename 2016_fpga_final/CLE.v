`timescale 1ns/10ps
module CLE ( clk, reset, rom_q, rom_a, sram_q, sram_a, sram_d, sram_wen, finish);
input         clk;
input         reset;
input  [7:0]  rom_q;
output [6:0]  rom_a;
input  [7:0]  sram_q;
output [9:0]  sram_a;
output [7:0]  sram_d;
output        sram_wen;
output        finish;

reg sram_wen, finish;
reg [6:0] rom_a;
reg [9:0] sram_a;
reg [7:0] sram_d;

reg [2:0] state;
reg [7:0] value, compare1, compare2;
reg [7:0] markValue [255:0];
reg [7:0] csram [1023:0];
reg [8:0] i;
reg [9:0] csram_a;
reg [31:0] mem [31:0];
reg [4:0] y_count;
reg [4:0] x_count;
reg memState;

parameter rr=3'b000, mcs0=3'b001, mcsx=3'b010, wrs=3'b011, fn=3'b100, rstate=3'b101;


always@(posedge clk or posedge reset)
begin
    if(reset)
    begin
        state = rstate;
    end
    else begin
        case(state)
            rstate:begin
                rom_a = 1; state = rr; x_count = 0; y_count = 0; finish = 0;
                csram_a = 0; value = 0; i = 0;
                markValue[0] = 0; memState = 0;
            end
            rr:begin
                mem[x_count][y_count] = rom_q[7];
                mem[x_count][y_count+1] = rom_q[6];
                mem[x_count][y_count+2] = rom_q[5];
                mem[x_count][y_count+3] = rom_q[4];
                mem[x_count][y_count+4] = rom_q[3];
                mem[x_count][y_count+5] = rom_q[2];
                mem[x_count][y_count+6] = rom_q[1];
                mem[x_count][y_count+7] = rom_q[0];
                if(y_count == 24) begin
                    x_count = x_count + 1;
                    y_count = 0;
                end
                else  y_count = y_count + 8;
                rom_a = rom_a + 1;
                state = (rom_a == 1) ? mcs0 : rr;
            end
            mcs0:begin
                if(mem[x_count][y_count]) begin
                    if(y_count == 0) begin
                        value = value + mem[x_count][y_count];
                        markValue[value] = value;
                        csram[csram_a] = value;
                    end
                    else begin
                        if(mem[x_count][y_count-1]) begin
                            csram[csram_a] = csram[csram_a - 1];
                        end
                        else begin
                            value = value + mem[x_count][y_count];
                            markValue[value] = value;
                            csram[csram_a] = value;
                        end
                    end
                end
                else begin
                    csram[csram_a] = 8'hFF;
                end
                if(y_count < 31) begin
                    state =  mcs0;
                end
                else begin
                    x_count = x_count + 1;
                    state = mcsx;
                end
                y_count = y_count + 1;
                csram_a = x_count * 32 + y_count;
            end
            mcsx:begin
                if(mem[x_count][y_count]) begin
                    if(y_count == 0) begin
                        if(csram[csram_a - 32] <= csram[csram_a - 31]) begin
                            if(csram[csram_a - 32] == 8'hFF) begin
                                value = value + mem[x_count][y_count];
                                markValue[value] = value;
                                csram[csram_a] = value;
                            end
                            else begin
                                csram[csram_a] = csram[csram_a - 32];
                                for( i = 0; i <= 255; i = i +1 )
                                begin
                                    if(markValue[i] == markValue[csram[csram_a - 31]])
                                    markValue[i] = markValue[csram[csram_a - 32]];
                                end
                            end
                        end
                        else begin
                            csram[csram_a] = csram[csram_a - 31];
                            for( i = 0; i <= 255; i = i +1 )
                            begin
                                if(markValue[i] == markValue[csram[csram_a - 32]])
                                markValue[i] = markValue[csram[csram_a - 31]];
                            end
                        end
                    end
                    else if(y_count == 31) begin
                        if(csram[csram_a - 33] <= csram[csram_a - 32]) begin
                            if(csram[csram_a - 33] == 8'hFF) begin
                                value = value + mem[x_count][y_count];
                                markValue[value] = value;
                                csram[csram_a] = value;
                            end
                            else begin
                                csram[csram_a] = csram[csram_a - 33];
                                for( i = 0; i <= 255; i = i +1 )
                                begin
                                    if(markValue[i] == markValue[csram[csram_a - 32]])
                                    markValue[i] = markValue[csram[csram_a - 33]];
                                end
                            end
                        end
                        else begin
                            csram[csram_a] = csram[csram_a - 32];
                            for( i = 0; i <= 255; i = i +1 )
                            begin
                                if(markValue[i] == markValue[csram[csram_a - 33]])
                                markValue[i] = markValue[csram[csram_a - 32]];
                            end
                        end
                    end
                    else begin
                        if(csram[csram_a - 1] <= csram[csram_a - 33]) compare1 = csram[csram_a - 1];
                        else compare1 = csram[csram_a - 33];
                        if(csram[csram_a - 32] <= csram[csram_a - 31]) compare2 = csram[csram_a - 32];
                        else compare2 = csram[csram_a - 31];
                        if(compare1 <= compare2) compare1 = compare1;
                        else compare1 = compare2;
                        if(compare1 == 8'hFF) begin
                            value = value + mem[x_count][y_count];
                            markValue[value] = value;
                            csram[csram_a] = value;
                        end
                        else begin
                            if(compare1 == csram[csram_a - 1]) begin
                                csram[csram_a] = csram[csram_a - 1];
                                for( i = 0; i <= 255; i = i +1 )
                                begin
                                    if(markValue[i] == markValue[csram[csram_a - 33]] || markValue[i] == markValue[csram[csram_a - 32]] || markValue[i] == markValue[csram[csram_a - 31]])
                                    markValue[i] = markValue[csram[csram_a - 1]];
                                end
                            end
                            else if(compare1 == csram[csram_a - 33]) begin
                                csram[csram_a] = csram[csram_a - 33];
                                for( i = 0; i <= 255; i = i +1 )
                                begin
                                    if(markValue[i] == markValue[csram[csram_a - 1]] || markValue[i] == markValue[csram[csram_a - 32]] || markValue[i] == markValue[csram[csram_a - 31]])
                                    markValue[i] = markValue[csram[csram_a - 33]];
                                end
                            end
                            else if(compare1 == csram[csram_a - 32]) begin
                                csram[csram_a] = csram[csram_a - 32];
                                for( i = 0; i <= 255; i = i +1 )
                                begin
                                    if(markValue[i] == markValue[csram[csram_a - 33]] || markValue[i] == markValue[csram[csram_a - 1]] || markValue[i] == markValue[csram[csram_a - 31]])
                                    markValue[i] = markValue[csram[csram_a - 32]];
                                end
                            end
                            else if(compare1 == csram[csram_a - 31]) begin
                                csram[csram_a] = csram[csram_a - 31];
                                for( i = 0; i <= 255; i = i +1 )
                                begin
                                    if(markValue[i] == markValue[csram[csram_a - 33]] || markValue[i] == markValue[csram[csram_a - 32]] || markValue[i] == markValue[csram[csram_a - 1]])
                                    markValue[i] = markValue[csram[csram_a - 31]];
                                end
                            end
                        end
                    end
                end
                else begin
                    csram[csram_a] = 8'hFF;
                end
                y_count = y_count + 1;
                if(y_count == 0) begin
                    x_count = x_count + 1;
                end
                else x_count = x_count;
                csram_a = x_count * 32 + y_count;
                state = (x_count == 0 && y_count == 0) ? wrs : mcsx;
            end
            wrs:begin
                sram_wen = 0;
                sram_a = csram_a;
                sram_d = (csram[csram_a] == 8'hFF) ? 8'h00 : markValue[csram[csram_a]];
                csram_a = csram_a + 1;
                if(csram_a == 0) begin
                    state = fn;
                end
            end
            fn:begin
                sram_wen = 1;
                finish = 1;
            end
        endcase
    end
end

endmodule