module lcd_ctrl(clk, reset, datain, cmd, cmd_valid, dataout, output_valid, busy);
input           clk;
input           reset;
input   [7:0]   datain;
input   [2:0]   cmd;
input           cmd_valid;
output  [7:0]   dataout;
output          output_valid;
output          busy;

//Decode
parameter MAX=35;
wire cmd [2:0];
wire origianl_data [0:MAX];
wire output_data [0:8];
reg [2:0] X, Y;  // row,col
reg [5:0] counter;
reg [5:0] counter1;
reg [5:0] position
genvar i;
genvar j;
reg [1:0] current_state;
reg [1:0] state;

always @(*)
begin
  position = (X)+(Y*6);
end

always @(negedge clk)
begin
  if(state!=1)
    begin
      output_valid<=1;
      dataout <= output_data;
      busy<=0;
      counter1 <= counter1 + 1;
    end
     
  if (counter1 == 9) 
    begin
      // 输出完九个数据后将 busy 设为 0
      busy <= 0;
      counter1 <= 0; // 重置计数器
    end
end

always @(posedge clk & posedge reset)
begin
 if(reset)
  begin
    X <= 3d'2;
    Y <= 3d'2;
    dataout <= 0;
    output_valid <= 0;
    busy <= 0;
    counter <= 0;
    counter1 <= 0;
    cmd <= 1;
    current_state<=0;
    state<=0;
  end

 else if(cmd_valid==1 && busy==0)
  begin
  generate
	case(cmd)
    0: //Reflash
        
        busy<=1;
        state<=0;

    1: //Load Data
          
          if(counter == MAX)
          begin
            counter <= 0;
            x<=2;
            Y<=2;
            for(j=0; j<=8; j=j+1)
              begin
                output_data[j]<= origianl_data[position];
              end
          end
          
          else 
          begin
             for(i=0; i<=MAX; i=i+1)
             begin
              origianl_data[i] <= datain;
              counter <= counter + 1;
             end
          end
          state<=1;
          busy<=1;

    2: //Shift Right
      
      if(X<3)
        begin
          X<=X+1
        end
      else
        begin
          X<=3;
        end
      state<=2;

    3: //Shift Left

      if(X>0)
        begin
          X<=X-1
        end
      else
        begin
          X<=0;
        end
      state<=3;
      busy<=1;

    4: //Shift Up

      if(Y>0)
        begin
          Y<=Y-1
        end
      else
        begin
          Y<=0;
        end
      state<=4;
      busy<=1;

    5: //Shift Down

      if(Y<3)
        begin
          Y<=Y+1
        end
      else
        begin
          Y<=3;
        end
      state<=5;
      busy<=1;

	endcase
  endgenerate
  end

end
                                                                                     
endmodule
