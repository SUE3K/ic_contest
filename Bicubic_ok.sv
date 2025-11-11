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
    on_step1    =   6,
    on_step2    =   7,
    on_step3    =   8,
    on_step4    =   9,
    on_step5    =   10,
    on_step6    =   11,
    on_step7    =   12,
    on_step8    =   13,
    on_step9    =   14,
    on_rounding =   15,
    //both not on point
    both_not_on   =   16,
    load          =   17;
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
reg signal;
reg re_signal;
always @(*)
begin
    column = (({x,15'd0}) * (SW - 1)) / (TW - 1);//h
    row = (({y,15'd0}) * (SH - 1)) / (TH - 1);//v
    row_update = (row[21:15]+V0);
    column_update1 = (column[21:15]+H0);
    column_update2 = ({column_update1,7'd0}-({column_update1,5'd0}))+({column_update1,2'd0});
    addr = (row_update+column_update2);
    a = (({p1,1'd0} + p1) - ({p2,1'd0} + p2)) + (p3 - p0);
    b = ({p0,1'd0} - ({p1,2'd0} + p1)) + ({p2,2'd0} - p3);
    c = (p2-p0);
    d = {p1,1'd0};
end

always @(posedge CLK )
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
        on_step1:
        begin
            ird<=1;
            if(valid==1)
            begin
                iaddr<=((addr-101)+({two_dimension,2'd0}))+(({two_dimension,7'd0})-({two_dimension,5'd0}));
            end
            else
            begin
                if(signal==1)
                    iaddr<=addr-100;
                else
                    iaddr<=addr-1;
            end
        end
        on_step2:
        begin
            if(signal==1)
                iaddr<=iaddr+100;
            else
                iaddr<=iaddr+1;
        end
        on_step3:
        begin
            p0<=input_data;
            if(signal==1)
                iaddr<=iaddr+100;
            else
                iaddr<=iaddr+1;
        end
        on_step4:
        begin
            p1<=input_data;
            if(signal==1)
                iaddr<=iaddr+100;
            else
                iaddr<=iaddr+1;
        end
        on_step5:
        begin
            p2<=input_data;
        end
        on_step6:
        begin
            p3<=input_data;
        end
        on_step7:
        begin
            x0 <= {{60{a[10]}},a};
            x2 <= {{45{b[10]}},b,15'd0};

            if(signal==1)
                x1 <= column[14:0];
            else
                x1 <= row[14:0];
        end
        on_step8:
        begin
            x0 <= mul;
            x2 <= {{30{c[10]}},c,30'd0};

            if(signal==1)
                x1 <= column[14:0];
            else
                x1 <= row[14:0];
        end
        on_step9:
        begin
            x0 <= mul;
            x2 <= {{15{d[10]}},d,45'd0};

            if(!valid)
            begin
                we<=1;
            end

            if(signal==1)
                x1 <= column[14:0];
            else
                x1 <= row[14:0];
        end
        on_rounding:
        begin
            we<=1;
            if(mul[55]==1)
            begin
                if(signal!=1)
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
                            if(signal!=1)
                                bicu[two_dimension]<=255;

                            output_data<=255;
                        end
                        else
                        begin
                            if(signal!=1)
                                bicu[two_dimension]<=mul[55:46];

                            output_data<=mul[55:46];
                        end
                    end
                    1:
                    begin
                        if(mul[55:46]>254)
                        begin
                            if(signal!=1)
                                bicu[two_dimension]<=255;

                            output_data<=255;
                        end
                        else
                        begin
                            if(signal!=1)
                                bicu[two_dimension]<=mul[55:46]+1;

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
        begin
            nextstate=get_addr;
            signal=0;
        end
        get_addr:
        begin
            nextstate=judge;
        end
        judge:
        begin
            if(DONE)
            begin
                nextstate = initialize;
            end
            else
            begin
                if(row[14:0]==0 && column[14:0] == 0)
                begin
                    nextstate = both_on_step1;
                end
                else
                begin
                    if(row[14:0] == 0)
                    begin
                        nextstate = on_step1;
                        signal=1;
                    end
                    else
                    begin
                        signal=0;
                        if(column[14:0] == 0)
                        begin
                            nextstate = on_step1;
                        end
                        else
                            nextstate = both_not_on;
                    end
                end
            end
        end
        ///////////////////////////////////////
        both_on_step1:
        begin
            nextstate=both_on_step2;
        end
        both_on_step2:
        begin
            nextstate=both_on_step3;
        end
        both_on_step3:
        begin
            nextstate=get_addr;
        end
        //////////////////////////////////////
        on_step1:
            nextstate=on_step2;
        on_step2:
            nextstate=on_step3;
        on_step3:
            nextstate=on_step4;
        on_step4:
            nextstate=on_step5;
        on_step5:
            nextstate=on_step6;
        on_step6:
            nextstate=on_step7;
        on_step7:
            nextstate=on_step8;
        on_step8:
            nextstate=on_step9;
        on_step9:
            nextstate=on_rounding;
        on_rounding:
        begin
            if(signal==1)
                nextstate=get_addr;
            else
            begin
                if(valid)
                    nextstate=(two_dimension==3)?load:both_not_on;
                else
                    nextstate=get_addr;
            end
        end
        /////////////////////////////////////
        both_not_on:
        begin
            nextstate=on_step1;
        end
        load:
        begin
            nextstate=on_step7;
            signal=1;
        end
        /////////////////////////////////////
        default:
        begin
            nextstate=on_rounding;
            signal=0;
        end
    endcase
end

// always @(*)
// begin
//     if(RST)
//         signal<=0;
//     else
//     begin
//         if(state==judge)
//         begin
//             if(row[14:0]==0 && column[14:0] !=0)
//                 signal<=1;
//             else
//                 signal<=0;
//         end
//         else
//             if(state==load)
//                 signal<=1;
//             else
//                 signal<=signal;
//     end
// end

always @(posedge CLK or posedge RST)
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
        else
            if(set)
               state <= nextstate;
    end
end

endmodule
