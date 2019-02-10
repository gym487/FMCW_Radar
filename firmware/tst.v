`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:16:16 12/03/2018 
// Design Name: 
// Module Name:    tst 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module led(
    input clkk,
    output reg[3:0] ledd
    );
    reg[31:0] LFSR=32'hf080909f;
    reg [31:0] g=32'h532afb54;
    reg [31:0] add=32'd0;
  always@(posedge clkk)
    begin
        add=add+32'd1;
        if(add>=32'd3000000)
        begin
        ledd=LFSR[3:0];
        LFSR=({ledd[0],LFSR[31:1]}^g);
        add=32'd0;
        end
    end
endmodule

module clkdiv(input clkk,output reg[31:0] clkd);
always@(posedge clkk)
begin
clkd=clkd+32'd1;
end
endmodule

module swl(input clkk,output reg[15:0] val);
reg dir;
reg[31:0] n;
always@(posedge clkk)
begin
if(n>=1000000)
begin
n=32'd0;
if(dir==1'b1)
val=val+16'd200;
else
val=val-16'd200;
if(val>=50000)
dir=1'b0;
if(val<=400)
dir=1'b1;
end
else
n=n+32'd1;
end
endmodule

module servo(input clkk,input[15:0] val,output reg serv);
reg[31:0] n=32'd0;
reg[16:0] m;
always@(posedge clkk)
begin
if(n>=500000)
n=32'd0;
else
n=n+32'd1;
if(n>=12500)
m=16'hffff;
if(n>=0&&n<25000)
m=16'h0;
if(n>=25000&&n<125000)
m=((n-25000)>>1);
serv=(val>=m);
end
endmodule

module adf4158(input clkk,input en,output reg aclk,output reg data,output reg le);
reg[7:0] clka=8'd0;
reg[7:0] clkb=8'd0;
reg[31:0] send;
reg ened=1'b0;
always@(posedge clkk)
begin
if(clka==8'd0)
begin
	le=1'b0;
	case(clkb)
	8'd0:send=32'h00000007;
	8'd1:send=32'h00000646;//00000646 for 40MHz Bw,FA6 for 100MHz Bw
	8'd2:send=32'h00800646;//00800646
	8'd3:send=32'h0032221D;
	8'd4:send=32'h00B2221D;//00A2221D
	8'd5:send=32'h00780284;
	8'd6:send=32'h000000C3;
	8'd7:send=32'h1F6080C2;
	8'd8:send=32'h06AC0001;
	8'd9:send=32'hF878D920;
	endcase
	aclk=1'b0;
end
if(clka!=8'd0&&clka[0]==1'b1&&clka<8'd64)
begin
	aclk=1'b0;
	data=send[31];
	send=send<<1;
end
if(clka!=8'd0&&clka[0]==1'b0&&clka<8'd65)
begin
	aclk=1'b1;
end
if(clka==8'd66)
	le=1'b1;
if(clka<70)
	clka=clka+8'd1;
if(clka==8'd68&&clkb<8'd9)
begin
	clka=8'd0;
	//le=1'b0;
	clkb=clkb+8'd1;
end
if(en==1'b1&&clkb>=8'd9&&clka>=68)
begin
	clka=8'd0;
	clkb=8'd0;
end

end 
endmodule 


module delay(input en,input clkk,output reg eno);
reg[7:0] tt;
always@(posedge clkk)
begin
if(en==1'b1&&tt>=8'd200)
	tt=0;
if(tt<200)
	tt=tt+8'd1;
if(tt>0&&tt<200)
	eno=1'b1;
else eno=1'b0;
end
endmodule


module adusb(input clkkk,input mo,input[14:0] addata,output reg adclk,output reg[15:0] udata,output reg uclk,output reg uwr,output reg ucs,output reg upkt);
reg[8:0] tt=8'd0;
reg[8:0] ttt=8'd0;
reg[15:0] data;
//reg pe;
//always@(posedge mo) begin
//pe=1;
//end
always@(posedge clkkk) begin
	ucs=0;
	tt=tt+8'd1;
	if(tt>=8'd5) begin
		tt=8'd0;
		ttt=ttt+8'd1;
	end
	
	if(tt==8'd0) begin
		adclk=1;
		uclk=0;
		udata=data;
		uwr=0;
	end
	if(tt==8'd2) begin
		uclk=1;
	end
	if(tt==8'd3) begin
		uwr=1;
		adclk=0;
		data={mo,addata};
		end
	if(tt>=8'd1&&tt<=8'd3&&ttt==8'd255)
		upkt=0;
	else
		upkt=1;
end
endmodule





module top(input clkk,input ens,input admo,input[14:0] addata,output serv,output[3:0] ledd,output Aclk,output Adata,output Ace,output Ale,output[15:0] usbdata,output usbcs,output usbslwr,output usbifclk,output usbpktend,output adclk,output usbslrd,output usbsloe,output[1:0] usbadr,output iii);
wire[15:0] cw;
wire[31:0] tt;
//wire en;
//assign en=1'b1;
assign Ace=1;
assign usbslrd=1;
assign usbsloe=1;
assign usbadr=2'b10;
assign iii=tt[4];
led a(clkk,ledd);
swl b(clkk,cw);
servo c(clkk,cw,serv);
clkdiv d(clkk,tt);
//delay f(clkk,tt[26],en);
adf4158 e(tt[4],ens,Aclk,Adata,Ale);
adusb f(tt[2],admo,addata,adclk,usbdata,usbifclk,usbslwr,usbcs,usbpktend);
endmodule
/*
module lcd(input clkkk,output reg[15:0] d,
output reg rst,output reg rd,output reg wr,
output reg rs,output reg cs,input en,input[15:0] data,input[15:0] addr,output reg busy);
reg[3:0] state=4'd0;
reg[15:0] addr_r;
reg[15:0] data_r;
always@(posedge clkkk)
begin
if(state!=0)
busy<=1;
else busy<=0;
case(state)
4'd0:
begin
rst<=1'd1;
rd<=1'd1;
cs<=1'd1;
rs<=1'd1;
if(en==1'b1)
begin
state<=4'd1;
addr_r<=addr;
data_r<=data;
end
end
4'd1:
begin
cs<=1'b0;
state<=4'd2;
end
4'd2:
begin
rs<=1'b1;
wr<=1'b0;
state<=4'd3;
end
4'd3:
begin
d<=addr_r;
state<=4'd4;
end
4'd4:
begin
wr<=1'b1;
state<=4'd5;
end
4'd5:
begin
cs<=1'b1;
rs<=1'b0;
state<=4'd6;
end
4'd6:
begin
cs<=1'b0;
state<=4'd7;
end
4'd7:
begin
rs<=1'b0;
wr<=1'b0;
state<=4'd8;
end
4'd8:
begin
d<=data_r;
state<=4'd9;
end
4'd9:
begin
wr<=1'b1;
state<=4'd10;
end
4'd10:
begin
cs<=1'b1;
rs<=1'b1;
state<=4'd0;
end
default:
begin
state<=4'd0;
end
endcase
end

endmodule
*//*
module ADC(input clk,input data,output adclk,output dataclk,output dataout)
reg[3:0] clkkk;
always@(posedge clk)
begin
if(clkkk!=4'd4)
begin
clkkk<=clkkk+4'd1;
adclk<=1'b0;
end
else
begin
clkkk<=4'd0;
adclk<=1'b1;
end
if(clkkk==4b'1)
begin
dataout=data;
end
end
endmodule
*/
/*
module top(input clkk,output[15:0] lcdd,output lcdrst,output lcdrd,output lcdwr,output lcdrs,output lcdcs,output[3:0] ledd);
reg en=1'b1;
wire busy;
wire[31:0] clkd;
reg[15:0] data=16'hffff;
reg[15:0] addr=16'h0002;
clkdiv a(clkk,clkd);
lcd b(clkd[4],lcdd,lcdrst,lcdrd,lcdwr,lcdrs,lcdcs,en,data,addr,busy);
led c(clkk,ledd);
//not d(en,busy);
endmodule
*/
