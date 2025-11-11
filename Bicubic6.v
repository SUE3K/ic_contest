module Bicubic (
           input CLK,
           input RST,
           input [6:0] V0,
           input [6:0] H0,
           input [4:0] SW,
           input [4:0] SH,
           input [5:0] TW,
           input [5:0] TH,
           output reg DONE);

reg  [4:0]  cur,nxt;
reg  [10:0] p_neg1,p0,p1,p2;
reg  [10:0] a,b,c,d;
reg  [6:0]  addr_x,addr_y;
wire [21:0] h_on = ({addr_x,15'd0} * (SW - 1)) / (TW - 1);//15 float
wire [21:0] v_on = ({addr_y,15'd0} * (SH - 1)) / (TH - 1);//15
wire [6:0]  v_addr = (v_on[21:15] + V0);
wire [13:0] v_addr_100 = (v_addr << 6) + (v_addr << 5) + (v_addr << 2);
wire [6:0]  h_addr = h_on[21:15] + H0;
//rom reg
reg  [13:0] rom_addr;
wire [13:0] final_addr = h_addr + v_addr_100;//check
reg rom_cen;
wire [7:0] rom_out;
//rom reg
//sram reg
reg [13:0] sram_addr;
reg [7:0] sram_in;
reg sram_cen;
reg sram_wen;
//sram reg
reg signed [54:0] m0,m1,m2;
reg flag;
reg [7:0] biq_arr[0:3];
reg [1:0] biq_index;
wire signed [55:0] mult = m0 * m1 + m2;
parameter
    reset = 0,
    update_addr = 1,
    hold = 2,
    //on point
    both_on_point1 = 3,
    both_on_point2 = 4,
    both_on_point3 = 5,
    //horizon
    vertical_on_point1  =  6,
    vertical_on_point2  =  7,
    vertical_on_point3  =  8,
    vertical_on_point4  =  9,
    vertical_on_point5  = 10,
    vertical_on_point6  = 11,
    vertical_on_point7  = 12,
    vertical_on_point8  = 13,
    vertical_on_point9  = 14,
    vertical_on_point10 = 15,
    vertical_on_point11 = 16,
    //vertical
    horizon_on_point1  = 17,
    horizon_on_point2  = 18,
    horizon_on_point3  = 19,
    horizon_on_point4  = 20,
    horizon_on_point5  = 21,
    horizon_on_point6  = 22,
    horizon_on_point7  = 23,
    horizon_on_point8  = 24,
    horizon_on_point9  = 25,
    horizon_on_point10 = 26,
    biq1 = 27,
    load = 28;
ImgROM u_ImgROM (.Q(rom_out), .CLK(CLK), .CEN(rom_cen), .A(rom_addr));
ResultSRAM u_ResultSRAM (.Q(), .CLK(CLK), .CEN(sram_cen), .WEN(sram_wen), .A(sram_addr), .D(sram_in));
always @(*)
begin
    a = (((p0 << 1) + p0) ) - (((p1 << 1) + p1) ) + (p2 ) - (p_neg1);//1
    b = {p_neg1,1'd0} - (((p0 << 2) + p0)) + (p1 << 2) - p2 ;//1
    c = p1  - p_neg1 ;//1
    d = p0 << 1;//1
end
always @(*)
begin
    case(cur)
        reset:
            nxt = update_addr;
        update_addr:
            nxt = hold;
        hold:
        begin
            if(DONE)
                nxt = reset;
            else if(h_on[14:0] == 0 && v_on[14:0] == 0)
                nxt = both_on_point1;
            else if(h_on[14:0] == 0)
                nxt = horizon_on_point1;
            else if(v_on[14:0] == 0)
                nxt = vertical_on_point1;
            else
                nxt = load;
        end
        //
        both_on_point1:
            nxt = both_on_point2;
        both_on_point2:
            nxt = both_on_point3;
        both_on_point3:
            nxt = update_addr;
        //
        vertical_on_point1:
            nxt = vertical_on_point2;
        vertical_on_point2:
            nxt = vertical_on_point3;
        vertical_on_point3:
            nxt = vertical_on_point4;
        vertical_on_point4:
            nxt = vertical_on_point5;
        vertical_on_point5:
            nxt = vertical_on_point6;
        vertical_on_point6:
            nxt = vertical_on_point7;
        vertical_on_point7:
            nxt = vertical_on_point8;
        vertical_on_point8:
            nxt = vertical_on_point9;
        vertical_on_point9:
            nxt = vertical_on_point10;
        vertical_on_point10:
            nxt = (flag)?(biq_index==3)?biq1:load:update_addr;//flag : 2 dimension
        //
        horizon_on_point1:
            nxt = horizon_on_point2;
        horizon_on_point2:
            nxt = horizon_on_point3;
        horizon_on_point3:
            nxt = horizon_on_point4;
        horizon_on_point4:
            nxt = horizon_on_point5;
        horizon_on_point5:
            nxt = horizon_on_point6;
        horizon_on_point6:
            nxt = horizon_on_point7;
        horizon_on_point7:
            nxt = horizon_on_point8;
        horizon_on_point8:
            nxt = horizon_on_point9;
        horizon_on_point9:
            nxt = horizon_on_point10;
        horizon_on_point10:
            nxt = update_addr;
        //
        load:
            nxt = vertical_on_point1;
        default:
            nxt = horizon_on_point7;
    endcase
end

always @(posedge CLK or posedge RST)
begin
    if(RST)
        cur <= reset;
    else
        cur <= nxt;
end

always @(posedge CLK)
begin
    case(cur)
        reset:
        begin
            DONE <= 0;
            addr_x <= -1;
            addr_y <= 0;
            rom_cen <= 1;
            sram_cen <= 1;
            sram_wen <= 1;
            sram_addr <= -1;
            flag <= 0;
            biq_index <= -1;
        end
        update_addr:
        begin
            flag <= 0;
            sram_addr <= sram_addr + 1;
            if(addr_x == TW - 1 && addr_y == TH - 1)
            begin
                DONE <= 1;
            end
            else if(addr_x == TW - 1)
            begin
                addr_x <= 0;
                addr_y <= addr_y + 1;
            end
            else
            begin
                addr_x <= addr_x + 1;
            end
            sram_cen <= 1;
            sram_wen <= 1;
        end
        both_on_point1:
        begin
            rom_cen <= 0;
            rom_addr <= final_addr;//1
        end
        both_on_point2:
        begin
            sram_cen <= 0;
            rom_cen <= 1;
            sram_wen <= 0;
        end
        both_on_point3:
        begin
            sram_in <= rom_out;
        end
        load:
        begin
            flag <= 1;
            biq_index <= biq_index + 1;
        end
        vertical_on_point1:
        begin
            rom_cen <= 0;
            rom_addr <= (flag)?(final_addr - 101 + ((biq_index << 6) + (biq_index << 5) + (biq_index << 2)) ):(final_addr - 1);//1
        end
        vertical_on_point2:
        begin
            rom_addr <= rom_addr + 1;//2
        end
        vertical_on_point3:
        begin
            rom_addr <= rom_addr + 1;//3
            p_neg1 <= rom_out;
        end
        vertical_on_point4:
        begin
            rom_addr <= rom_addr + 1;//4
            p0 <= rom_out;
        end
        vertical_on_point5:
        begin
            p1 <= rom_out;
        end
        vertical_on_point6:
        begin
            p2 <= rom_out;
        end
        vertical_on_point7:
        begin
            m0 <= {{60{a[10]}},a};//1
            m1 <= h_on[14:0];//15
            m2 <= {{45{b[10]}},b,15'd0};
        end
        vertical_on_point8:
        begin
            m0 <= mult;//16
            m1 <= h_on[14:0];//15
            m2 <= {{30{c[10]}},c,30'd0};
        end
        vertical_on_point9:
        begin
            m0 <= mult;//31
            m1 <= h_on[14:0];//15
            m2 <= {{15{d[10]}},d,45'd0};//46
            if(!flag)
            begin
                sram_wen <= 0;
                sram_cen <= 0;
            end
        end
        vertical_on_point10:
        begin
            if(mult[55] == 1)
            begin
                biq_arr[biq_index] <= 0;
                sram_in <= 0;
            end
            else
            begin
                if(mult[45] == 1)
                begin
                    if(mult[55:46] > 254)
                    begin
                        biq_arr[biq_index] <= 255;
                        sram_in <= 255;
                    end
                    else
                    begin
                        biq_arr[biq_index] <= mult[55:46] + 1;
                        sram_in <= mult[55:46] + 1;
                    end
                end
                else
                begin
                    if(mult[55:46] > 255)
                    begin
                        biq_arr[biq_index] <= 255;
                        sram_in <= 255;
                    end
                    else
                    begin
                        biq_arr[biq_index] <= mult[55:46];
                        sram_in <= mult[55:46];
                    end
                end
            end
        end

        horizon_on_point1:
        begin
            rom_cen <= 0;
            rom_addr <= final_addr - 100;
        end
        horizon_on_point2:
        begin
            rom_addr <= rom_addr + 100;
        end
        horizon_on_point3:
        begin
            rom_addr <= rom_addr + 100;
            p_neg1 <= rom_out;
        end
        horizon_on_point4:
        begin
            rom_addr <= rom_addr + 100;
            p0 <= rom_out;
        end
        horizon_on_point5:
        begin
            p1 <= rom_out;
        end
        horizon_on_point6:
        begin
            p2 <= rom_out;
        end
        horizon_on_point7:
        begin
            m0 <= {{60{a[10]}},a};//1
            m1 <= v_on[14:0];//15
            m2 <= {{45{b[10]}},b,15'd0};
        end
        horizon_on_point8:
        begin
            m0 <= mult;//16
            m1 <= v_on[14:0];//15
            m2 <= {{30{c[10]}},c,30'd0};
        end
        horizon_on_point9:
        begin
            m0 <= mult;//31
            m1 <= v_on[14:0];//15
            m2 <= {{15{d[10]}},d,45'd0};//46
            sram_wen <= 0;
            sram_cen <= 0;
        end
        horizon_on_point10:
        begin
            if(mult[55] == 1)
            begin
                sram_in <= 0;
            end
            else
            begin
                if(mult[45] == 1)
                begin
                    if(mult[55:46] > 254)
                    begin
                        sram_in <= 255;
                    end
                    else
                    begin
                        sram_in <= mult[55:46] + 1;
                    end
                end
                else
                begin
                    if(mult[55:46] > 255)
                    begin
                        sram_in <= 255;
                    end
                    else
                    begin
                        sram_in <= mult[55:46];
                    end
                end
            end
        end
        biq1:
        begin
            p_neg1 <= biq_arr[0];
            p0 <= biq_arr[1];
            p1 <= biq_arr[2];
            p2 <= biq_arr[3];
        end
    endcase
end
endmodule


