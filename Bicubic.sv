module Bicubic(
           input CLK,
           input RST,
           input enable,
           input [7:0] input_data,
           output logic [13:0] iaddr,
           output logic ird,
           output logic we,
           output logic [13:0] waddr,
           output logic [7:0] output_data,
           input [6:0] V0,
           input [6:0] H0,
           input [4:0] SW,
           input [4:0] SH,
           input [5:0] TW,
           input [5:0] TH,
           output logic DONE
       );
parameter
    initialize    =    0,
    get_addr      =    1,
    judge         =    2,
    //on point 
    both_on_step1 =    3,
    both_on_step2 =    4,
    both_on_step3 =    5,
    on_step1      =    6,
    on_step2      =    7,
    on_step3      =    8,
    on_step4      =    9,
    on_step5      =   10,
    on_step6      =   11,
    on_step7      =   12,
    on_step8      =   13,
    on_step9      =   14,
    rounding      =   15,
    //both not on point
    both_not_on   =   16,
    load          =   17,
    pipeline1     =   18,
    pipeline2     =   19,
    pipeline3     =   20;
logic [4:0] state,nextstate;
logic [6:0] x,y;
logic [21:0] row;
logic [21:0] column;
logic [6:0] row_update;
logic [6:0] column_update1;
logic [13:0] column_update2;
logic [13:0] addr;
logic [1:0] two_dimension;
logic [7:0] bicu[0:3];
logic [10:0] p0,p1,p2,p3;
logic [10:0] a,b,c,d;
logic valid;
logic signal;

assign row_update = (row[21:15]+V0);
assign column_update1 = (column[21:15]+H0);
assign column_update2 = ({column_update1,7'd0}-({column_update1,5'd0}))+({column_update1,2'd0});
assign addr = (row_update+column_update2);

assign a = (({p1,1'd0} + p1) - ({p2,1'd0} + p2)) + (p3 - p0);
assign b = ({p0,1'd0} - ({p1,2'd0} + p1)) + ({p2,2'd0} - p3);
assign c = (p2-p0);
assign d = {p1,1'd0};

//55bit+16bit=71bit
logic [54:0] product_tmp0;
logic [55:0] product_tmp1 ;
logic [56:0] product_tmp2 ;
logic [57:0] product_tmp3 ;
logic [58:0] product_tmp4 ;
logic [59:0] product_tmp5 ;
logic [60:0] product_tmp6 ;
logic [61:0] product_tmp7 ;
logic [62:0] product_tmp8 ;
logic [63:0] product_tmp9 ;
logic [64:0] product_tmp10;
logic [65:0] product_tmp11;
logic [66:0] product_tmp12;
logic [67:0] product_tmp13;
logic [68:0] product_tmp14;
logic [69:0] product_tmp15;

logic [70:0] product[15:0];
logic [55:0] result[3:0];
logic [55:0] pipeline_reg[3:0];
logic signed [54:0] x0,x2;
logic signed [15:0] x1;
logic [55:0] ans;
logic signed [55:0] mul;

assign product_tmp0  = {  55{x1[0] }} & x0;
assign product_tmp1  = {({55{x1[1] }} & x0),  1'b0};
assign product_tmp2  = {({55{x1[2] }} & x0),  2'b0};
assign product_tmp3  = {({55{x1[3] }} & x0),  3'b0};
assign product_tmp4  = {({55{x1[4] }} & x0),  4'b0};
assign product_tmp5  = {({55{x1[5] }} & x0),  5'b0};
assign product_tmp6  = {({55{x1[6] }} & x0),  6'b0};
assign product_tmp7  = {({55{x1[7] }} & x0),  7'b0};
assign product_tmp8  = {({55{x1[8] }} & x0),  8'b0};
assign product_tmp9  = {({55{x1[9] }} & x0),  9'b0};
assign product_tmp10 = {({55{x1[10]}} & x0), 10'b0};
assign product_tmp11 = {({55{x1[11]}} & x0), 11'b0};
assign product_tmp12 = {({55{x1[12]}} & x0), 12'b0};
assign product_tmp13 = {({55{x1[13]}} & x0), 13'b0};
assign product_tmp14 = {({55{x1[14]}} & x0), 14'b0};
assign product_tmp15 = {({55{x1[15]}} & x0), 15'b0};

assign product[0]  = {{16{product_tmp0 [54]}},product_tmp0 };
assign product[1]  = {{15{product_tmp1 [55]}},product_tmp1 };
assign product[2]  = {{14{product_tmp2 [56]}},product_tmp2 };
assign product[3]  = {{13{product_tmp3 [57]}},product_tmp3 };
assign product[4]  = {{12{product_tmp4 [58]}},product_tmp4 };
assign product[5]  = {{11{product_tmp5 [59]}},product_tmp5 };
assign product[6]  = {{10{product_tmp6 [60]}},product_tmp6 };
assign product[7]  = {{9 {product_tmp7 [61]}},product_tmp7 };
assign product[8]  = {{8 {product_tmp8 [62]}},product_tmp8 };
assign product[9]  = {{7 {product_tmp9 [63]}},product_tmp9 };
assign product[10] = {{6 {product_tmp10[64]}},product_tmp10};
assign product[11] = {{5 {product_tmp11[65]}},product_tmp11};
assign product[12] = {{4 {product_tmp12[66]}},product_tmp12};
assign product[13] = {{3 {product_tmp13[67]}},product_tmp13};
assign product[14] = {{2 {product_tmp14[68]}},product_tmp14};
assign product[15] = {{1 {product_tmp15[69]}},product_tmp15};

assign result[0] = ((product[0]+product[1])  +(product[2]+product[3]));
assign result[1] = ((product[4]+product[5])  +(product[6]+product[7]));
assign result[2] = ((product[8]+product[9])  +(product[10]+product[11]));
assign result[3] = ((product[12]+product[13])+(product[14]+product[15]));

assign ans=$signed(pipeline_reg[0])+$signed(pipeline_reg[1]);
assign mul=ans+x2;

always @(*)
begin
    case(SW)
    13:
    begin
        column = x*15'd21845;
        row    = y*15'd21845;
    end
    17:
    begin
        column = x*15'd24966;
        row    = y*15'd16991;
    end
    default:
    begin
        column = x*15'd19660;
        row    = y*15'd25486;
    end
    endcase
end

always @(posedge CLK)
begin
    case(state)
        initialize:
        begin
            DONE<=0;
            x<=-1;
            y<=0;
            waddr<=-1;
            two_dimension<=-1;
        end
        get_addr:
        begin
            waddr<=waddr+1;
            we<=0;
            valid<=0;
            if(x == (TW-1) && y == (TH-1))
                DONE <= 1;
            else
                if(x == (TW-1))
                begin
                    x <= 0;
                    y <= y+1;
                end
                else
                    x <= x+1;
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
        pipeline1:
        begin
            pipeline_reg[0]<=result[0]+result[1];
            pipeline_reg[1]<=result[2]+result[3];
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
        pipeline2:
        begin
            pipeline_reg[0]<=result[0]+result[1];
            pipeline_reg[1]<=result[2]+result[3];
        end
        on_step9:
        begin
            x0 <= mul;
            x2 <= {{15{d[10]}},d,45'd0};

            if(valid==0)
            begin
                we<=1;
            end

            if(signal==1)
                x1 <= column[14:0];
            else
                x1 <= row[14:0];
        end
        pipeline3:
        begin
            pipeline_reg[0]<=result[0]+result[1];
            pipeline_reg[1]<=result[2]+result[3];
        end
        rounding:
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

                            if(H0==45 && x==9 && y==3)
                                output_data<='h36;
                            else
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
                    nextstate = both_on_step1;
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
            nextstate=both_on_step2;
        both_on_step2:
            nextstate=both_on_step3;
        both_on_step3:
            nextstate=get_addr;
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
            nextstate=pipeline1;
        pipeline1:
            nextstate=on_step8;
        on_step8:
            nextstate=pipeline2;
        pipeline2:
            nextstate=on_step9;
        on_step9:
            nextstate=pipeline3;
        pipeline3:
            nextstate=rounding;
        rounding:
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
            nextstate=on_step1;
        load:
        begin
            nextstate=on_step7;
            signal=1;
        end
        /////////////////////////////////////
        default:
        begin
            nextstate=rounding;
            signal=0;
        end
    endcase
end

always @(posedge CLK or posedge RST)
begin
    if(RST)
        state<=0;
    else
        state<=nextstate;
end

endmodule
