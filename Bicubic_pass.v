module Bicubic(
           input CLK,
           input RST,
           input enable,
           input [7:0] input_data,
           output reg [13:0] iaddr,
           output reg ird,
           output reg we,
           output reg [13:0] waddr,
           output reg [7:0] output_data,
           input [6:0] V0,
           input [6:0] H0,
           input [4:0] SW,
           input [4:0] SH,
           input [5:0] TW,
           input [5:0] TH,
           output reg DONE
       );
parameter
    initialize    =   0,
    get_addr      =   1,
    judge         =   2,
    //on point
    both_on_step1 =   3,
    both_on_step2 =   4,
    both_on_step3 =   5,
    //horizon
    v_on_step1    =   6,
    v_on_step2    =   7,
    v_on_step3    =   8,
    v_on_step4    =   9,
    v_on_step5    =   10,
    v_on_step6    =   11,
    v_on_step7    =   12,
    v_on_step8    =   13,
    v_on_step9    =   14,
    v_on_rounding =   15,
    //vertical
    h_on_step1    =   16,
    h_on_step2    =   17,
    h_on_step3    =   18,
    h_on_step4    =   19,
    h_on_step5    =   20,
    h_on_step6    =   21,
    h_on_step7    =   22,
    h_on_step8    =   23,
    h_on_step9    =   24,
    h_on_rounding =   25,
    //both not on point
    both_not_on   =   26,
    load          =   27;
reg [4:0] state,nextstate;
reg [6:0] x,y;
reg [21:0] row;
reg [21:0] column;
reg [6:0] row_update;
reg [6:0] column_update1;
reg [13:0] column_update2;
reg [13:0] addr;
reg valid;
reg [1:0] two_dimension;
reg [7:0] bicu[0:3];
reg signed [54:0] x0,x1,x2;
wire signed [55:0] mul = x0*x1+x2;
reg [10:0] p0,p1,p2,p3;
reg [10:0] a,b,c,d;
reg set;
always @(*)
begin
    column    = (({x,15'd0}) * (SW - 1)) / (TW - 1);//h
    row = (({y,15'd0}) * (SH - 1)) / (TH - 1);//v
    row_update = row[21:15]+V0;
    column_update1 = (column[21:15]+H0);
    column_update2 = ({column_update1,7'd0}-({column_update1,5'd0}))+({column_update1,2'd0});
    addr = row_update+column_update2;
    a = ({p1,1'd0} + p1) - ({p2,1'd0} + p2) + (p3) - (p0);
    b = {p0,1'd0} - (({p1,2'd0} + p1)) + ({p2,2'd0}) - (p3);
    c = p2-p0;
    d = {p1,1'd0};
end
always @(posedge CLK)
begin
    case(state)
        initialize:
        begin
            DONE<=0;
            x<=-1;
            y<=0;
            ird<=0;
            waddr<=-1;
            two_dimension<=-1;
            we<=0;
            valid<=0;
        end
        get_addr:
        begin
            waddr<=waddr+1;
            we<=0;
            valid<=0;
            if(x == TW - 1 && y == TH - 1)
                DONE <= 1;
            else
                if(x == TW - 1)
                begin
                    x <= 0;
                    y <= y + 1;
                end
                else
                    x <= x + 1;
        end
        both_on_step1:
        begin
            ird<=1;
            iaddr<=addr;
        end
        both_on_step2:
        begin
            we<=1;
        end
        both_on_step3:
        begin
            output_data<=input_data;
        end
        v_on_step1:
        begin
            ird<=1;
            if(valid)
            begin
                iaddr<=((addr-101)+({two_dimension,2'd0}))+(({two_dimension,7'd0})-({two_dimension,5'd0}));
            end
            else
            begin
                iaddr<=addr-1;
            end
        end
        v_on_step2:
        begin
            iaddr<=iaddr+1;
        end
        v_on_step3:
        begin
            iaddr<=iaddr+1;
            p0<=input_data;
        end
        v_on_step4:
        begin
            iaddr<=iaddr+1;
            p1<=input_data;
        end
        v_on_step5:
        begin
            p2<=input_data;
        end
        v_on_step6:
        begin
            p3<=input_data;
        end
        v_on_step7:
        begin
            x0 <= {{60{a[10]}},a};
            x1 <= row[14:0];
            x2 <= {{45{b[10]}},b,15'd0};
        end
        v_on_step8:
        begin
            x0 <= mul;
            x1 <= row[14:0];
            x2 <= {{30{c[10]}},c,30'd0};
        end
        v_on_step9:
        begin
            x0 <= mul;
            x1 <= row[14:0];
            x2 <= {{15{d[10]}},d,45'd0};
            if(!valid)
            begin
                we<=1;
            end
        end
        v_on_rounding:
        begin
            if(mul[55]==1)
            begin
                bicu[two_dimension]<=0;
                output_data<=0;
            end
            else
            begin
                case (mul[45])
                    0:
                    begin
                        if(mul[55:46]>255)
                        begin
                            bicu[two_dimension]<=255;
                            output_data<=255;
                        end
                        else
                        begin
                            bicu[two_dimension]<=mul[55:46];
                            output_data<=mul[55:46];
                        end
                    end
                    1:
                    begin
                        if(mul[55:46]>254)
                        begin
                            bicu[two_dimension]<=255;
                            output_data<=255;
                        end
                        else
                        begin
                            bicu[two_dimension]<=mul[55:46]+1;
                            output_data<=mul[55:46]+1;
                        end
                    end
                endcase
            end
        end
        h_on_step1:
        begin
            ird<=1;
            iaddr<=addr-100;
        end
        h_on_step2:
        begin
            iaddr<=iaddr+100;
        end
        h_on_step3:
        begin
            iaddr<=iaddr+100;
            p0<=input_data;
        end
        h_on_step4:
        begin
            iaddr<=iaddr+100;
            p1<=input_data;
        end
        h_on_step5:
        begin
            p2<=input_data;
        end
        h_on_step6:
        begin
            p3<=input_data;
        end
        h_on_step7:
        begin
            x0 <= {{60{a[10]}},a};
            x1 <= column[14:0];
            x2 <= {{45{b[10]}},b,15'd0};
        end
        h_on_step8:
        begin
            x0 <= mul;
            x1 <= column[14:0];
            x2 <= {{30{c[10]}},c,30'd0};
        end
        h_on_step9:
        begin
            x0 <= mul;
            x1 <= column[14:0];
            x2 <= {{15{d[10]}},d,45'd0};
            we<=1;
        end
        h_on_rounding:
        begin
            if(mul[55]==1)
            begin
                output_data<=0;
            end
            else
            begin
                case (mul[45])
                    0:
                    begin
                        if(mul[55:46]>255)
                        begin
                            output_data<=255;
                        end
                        else
                        begin
                            output_data<=mul[55:46];
                        end
                    end
                    1:
                    begin
                        if(mul[55:46]>254)
                        begin
                            output_data<=255;
                        end
                        else
                        begin
                            output_data<=mul[55:46]+1;
                        end
                    end
                endcase
            end
        end
        both_not_on:
        begin
            valid<=1;
            two_dimension<=two_dimension+1;
        end
        load:
        begin
            p0<=bicu[0];
            p1<=bicu[1];
            p2<=bicu[2];
            p3<=bicu[3];
        end
    endcase
end

always @(*)
begin
    case(state)
        initialize:
            nextstate=get_addr;
        get_addr:
            nextstate=judge;
        judge:
        begin
            if(DONE)
                nextstate = initialize;
            else
            begin
                if(row[14:0]==0 && column[14:0] == 0)
                    nextstate = both_on_step1;
                else
                begin
                    if(row[14:0] == 0)
                        nextstate = h_on_step1;
                    else
                    begin
                        if(column[14:0] == 0)
                            nextstate = v_on_step1;
                        else
                            nextstate = both_not_on;
                    end
                end
            end
        end
        ///////////////////////////////////////
        both_on_step1:
            nextstate=both_on_step2;
        both_on_step2:
            nextstate=both_on_step3;
        both_on_step3:
            nextstate=get_addr;
        //////////////////////////////////////
        v_on_step1:
            nextstate=v_on_step2;
        v_on_step2:
            nextstate=v_on_step3;
        v_on_step3:
            nextstate=v_on_step4;
        v_on_step4:
            nextstate=v_on_step5;
        v_on_step5:
            nextstate=v_on_step6;
        v_on_step6:
            nextstate=v_on_step7;
        v_on_step7:
            nextstate=v_on_step8;
        v_on_step8:
            nextstate=v_on_step9;
        v_on_step9:
            nextstate=v_on_rounding;
        v_on_rounding:
        begin
            if(valid)
                nextstate=(two_dimension==3)?load:both_not_on;
            else
                nextstate=get_addr;
        end
        ////////////////////////////////////
        h_on_step1:
            nextstate=h_on_step2;
        h_on_step2:
            nextstate=h_on_step3;
        h_on_step3:
            nextstate=h_on_step4;
        h_on_step4:
            nextstate=h_on_step5;
        h_on_step5:
            nextstate=h_on_step6;
        h_on_step6:
            nextstate=h_on_step7;
        h_on_step7:
            nextstate=h_on_step8;
        h_on_step8:
            nextstate=h_on_step9;
        h_on_step9:
            nextstate=h_on_rounding;
        h_on_rounding:
            nextstate=get_addr;
        /////////////////////////////////////
        both_not_on:
            nextstate=v_on_step1;
        load:
            nextstate=h_on_step7;
        /////////////////////////////////////
    endcase
end

always @(posedge CLK)
begin
    if(RST)
    begin
        state<=0;
        set<=0;
    end
    else
    begin
        if(enable)
            set<=1;
        if(set)
            state <= nextstate;
    end
end

endmodule
