
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	17010113          	addi	sp,sp,368 # 80009170 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fde70713          	addi	a4,a4,-34 # 80009030 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	fec78793          	addi	a5,a5,-20 # 80006050 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd37d7>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	1ac78793          	addi	a5,a5,428 # 8000125a <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
    80000106:	8a2a                	mv	s4,a0
    80000108:	84ae                	mv	s1,a1
    8000010a:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    8000010c:	00011517          	auipc	a0,0x11
    80000110:	06450513          	addi	a0,a0,100 # 80011170 <cons>
    80000114:	00001097          	auipc	ra,0x1
    80000118:	bb8080e7          	jalr	-1096(ra) # 80000ccc <acquire>
  for(i = 0; i < n; i++){
    8000011c:	05305b63          	blez	s3,80000172 <consolewrite+0x7e>
    80000120:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000122:	5afd                	li	s5,-1
    80000124:	4685                	li	a3,1
    80000126:	8626                	mv	a2,s1
    80000128:	85d2                	mv	a1,s4
    8000012a:	fbf40513          	addi	a0,s0,-65
    8000012e:	00002097          	auipc	ra,0x2
    80000132:	6a8080e7          	jalr	1704(ra) # 800027d6 <either_copyin>
    80000136:	01550c63          	beq	a0,s5,8000014e <consolewrite+0x5a>
      break;
    uartputc(c);
    8000013a:	fbf44503          	lbu	a0,-65(s0)
    8000013e:	00000097          	auipc	ra,0x0
    80000142:	796080e7          	jalr	1942(ra) # 800008d4 <uartputc>
  for(i = 0; i < n; i++){
    80000146:	2905                	addiw	s2,s2,1
    80000148:	0485                	addi	s1,s1,1
    8000014a:	fd299de3          	bne	s3,s2,80000124 <consolewrite+0x30>
  }
  release(&cons.lock);
    8000014e:	00011517          	auipc	a0,0x11
    80000152:	02250513          	addi	a0,a0,34 # 80011170 <cons>
    80000156:	00001097          	auipc	ra,0x1
    8000015a:	c46080e7          	jalr	-954(ra) # 80000d9c <release>

  return i;
}
    8000015e:	854a                	mv	a0,s2
    80000160:	60a6                	ld	ra,72(sp)
    80000162:	6406                	ld	s0,64(sp)
    80000164:	74e2                	ld	s1,56(sp)
    80000166:	7942                	ld	s2,48(sp)
    80000168:	79a2                	ld	s3,40(sp)
    8000016a:	7a02                	ld	s4,32(sp)
    8000016c:	6ae2                	ld	s5,24(sp)
    8000016e:	6161                	addi	sp,sp,80
    80000170:	8082                	ret
  for(i = 0; i < n; i++){
    80000172:	4901                	li	s2,0
    80000174:	bfe9                	j	8000014e <consolewrite+0x5a>

0000000080000176 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000176:	7159                	addi	sp,sp,-112
    80000178:	f486                	sd	ra,104(sp)
    8000017a:	f0a2                	sd	s0,96(sp)
    8000017c:	eca6                	sd	s1,88(sp)
    8000017e:	e8ca                	sd	s2,80(sp)
    80000180:	e4ce                	sd	s3,72(sp)
    80000182:	e0d2                	sd	s4,64(sp)
    80000184:	fc56                	sd	s5,56(sp)
    80000186:	f85a                	sd	s6,48(sp)
    80000188:	f45e                	sd	s7,40(sp)
    8000018a:	f062                	sd	s8,32(sp)
    8000018c:	ec66                	sd	s9,24(sp)
    8000018e:	e86a                	sd	s10,16(sp)
    80000190:	1880                	addi	s0,sp,112
    80000192:	8aaa                	mv	s5,a0
    80000194:	8a2e                	mv	s4,a1
    80000196:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000198:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000019c:	00011517          	auipc	a0,0x11
    800001a0:	fd450513          	addi	a0,a0,-44 # 80011170 <cons>
    800001a4:	00001097          	auipc	ra,0x1
    800001a8:	b28080e7          	jalr	-1240(ra) # 80000ccc <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001ac:	00011497          	auipc	s1,0x11
    800001b0:	fc448493          	addi	s1,s1,-60 # 80011170 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001b4:	00011917          	auipc	s2,0x11
    800001b8:	05c90913          	addi	s2,s2,92 # 80011210 <cons+0xa0>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001bc:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001be:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001c0:	4ca9                	li	s9,10
  while(n > 0){
    800001c2:	07305863          	blez	s3,80000232 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001c6:	0a04a783          	lw	a5,160(s1)
    800001ca:	0a44a703          	lw	a4,164(s1)
    800001ce:	02f71463          	bne	a4,a5,800001f6 <consoleread+0x80>
      if(myproc()->killed){
    800001d2:	00002097          	auipc	ra,0x2
    800001d6:	b40080e7          	jalr	-1216(ra) # 80001d12 <myproc>
    800001da:	5d1c                	lw	a5,56(a0)
    800001dc:	e7b5                	bnez	a5,80000248 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001de:	85a6                	mv	a1,s1
    800001e0:	854a                	mv	a0,s2
    800001e2:	00002097          	auipc	ra,0x2
    800001e6:	344080e7          	jalr	836(ra) # 80002526 <sleep>
    while(cons.r == cons.w){
    800001ea:	0a04a783          	lw	a5,160(s1)
    800001ee:	0a44a703          	lw	a4,164(s1)
    800001f2:	fef700e3          	beq	a4,a5,800001d2 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001f6:	0017871b          	addiw	a4,a5,1
    800001fa:	0ae4a023          	sw	a4,160(s1)
    800001fe:	07f7f713          	andi	a4,a5,127
    80000202:	9726                	add	a4,a4,s1
    80000204:	02074703          	lbu	a4,32(a4)
    80000208:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    8000020c:	077d0563          	beq	s10,s7,80000276 <consoleread+0x100>
    cbuf = c;
    80000210:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000214:	4685                	li	a3,1
    80000216:	f9f40613          	addi	a2,s0,-97
    8000021a:	85d2                	mv	a1,s4
    8000021c:	8556                	mv	a0,s5
    8000021e:	00002097          	auipc	ra,0x2
    80000222:	562080e7          	jalr	1378(ra) # 80002780 <either_copyout>
    80000226:	01850663          	beq	a0,s8,80000232 <consoleread+0xbc>
    dst++;
    8000022a:	0a05                	addi	s4,s4,1
    --n;
    8000022c:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000022e:	f99d1ae3          	bne	s10,s9,800001c2 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000232:	00011517          	auipc	a0,0x11
    80000236:	f3e50513          	addi	a0,a0,-194 # 80011170 <cons>
    8000023a:	00001097          	auipc	ra,0x1
    8000023e:	b62080e7          	jalr	-1182(ra) # 80000d9c <release>

  return target - n;
    80000242:	413b053b          	subw	a0,s6,s3
    80000246:	a811                	j	8000025a <consoleread+0xe4>
        release(&cons.lock);
    80000248:	00011517          	auipc	a0,0x11
    8000024c:	f2850513          	addi	a0,a0,-216 # 80011170 <cons>
    80000250:	00001097          	auipc	ra,0x1
    80000254:	b4c080e7          	jalr	-1204(ra) # 80000d9c <release>
        return -1;
    80000258:	557d                	li	a0,-1
}
    8000025a:	70a6                	ld	ra,104(sp)
    8000025c:	7406                	ld	s0,96(sp)
    8000025e:	64e6                	ld	s1,88(sp)
    80000260:	6946                	ld	s2,80(sp)
    80000262:	69a6                	ld	s3,72(sp)
    80000264:	6a06                	ld	s4,64(sp)
    80000266:	7ae2                	ld	s5,56(sp)
    80000268:	7b42                	ld	s6,48(sp)
    8000026a:	7ba2                	ld	s7,40(sp)
    8000026c:	7c02                	ld	s8,32(sp)
    8000026e:	6ce2                	ld	s9,24(sp)
    80000270:	6d42                	ld	s10,16(sp)
    80000272:	6165                	addi	sp,sp,112
    80000274:	8082                	ret
      if(n < target){
    80000276:	0009871b          	sext.w	a4,s3
    8000027a:	fb677ce3          	bgeu	a4,s6,80000232 <consoleread+0xbc>
        cons.r--;
    8000027e:	00011717          	auipc	a4,0x11
    80000282:	f8f72923          	sw	a5,-110(a4) # 80011210 <cons+0xa0>
    80000286:	b775                	j	80000232 <consoleread+0xbc>

0000000080000288 <consputc>:
{
    80000288:	1141                	addi	sp,sp,-16
    8000028a:	e406                	sd	ra,8(sp)
    8000028c:	e022                	sd	s0,0(sp)
    8000028e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000290:	10000793          	li	a5,256
    80000294:	00f50a63          	beq	a0,a5,800002a8 <consputc+0x20>
    uartputc_sync(c);
    80000298:	00000097          	auipc	ra,0x0
    8000029c:	55e080e7          	jalr	1374(ra) # 800007f6 <uartputc_sync>
}
    800002a0:	60a2                	ld	ra,8(sp)
    800002a2:	6402                	ld	s0,0(sp)
    800002a4:	0141                	addi	sp,sp,16
    800002a6:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a8:	4521                	li	a0,8
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	54c080e7          	jalr	1356(ra) # 800007f6 <uartputc_sync>
    800002b2:	02000513          	li	a0,32
    800002b6:	00000097          	auipc	ra,0x0
    800002ba:	540080e7          	jalr	1344(ra) # 800007f6 <uartputc_sync>
    800002be:	4521                	li	a0,8
    800002c0:	00000097          	auipc	ra,0x0
    800002c4:	536080e7          	jalr	1334(ra) # 800007f6 <uartputc_sync>
    800002c8:	bfe1                	j	800002a0 <consputc+0x18>

00000000800002ca <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002ca:	1101                	addi	sp,sp,-32
    800002cc:	ec06                	sd	ra,24(sp)
    800002ce:	e822                	sd	s0,16(sp)
    800002d0:	e426                	sd	s1,8(sp)
    800002d2:	e04a                	sd	s2,0(sp)
    800002d4:	1000                	addi	s0,sp,32
    800002d6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d8:	00011517          	auipc	a0,0x11
    800002dc:	e9850513          	addi	a0,a0,-360 # 80011170 <cons>
    800002e0:	00001097          	auipc	ra,0x1
    800002e4:	9ec080e7          	jalr	-1556(ra) # 80000ccc <acquire>

  switch(c){
    800002e8:	47d5                	li	a5,21
    800002ea:	0af48663          	beq	s1,a5,80000396 <consoleintr+0xcc>
    800002ee:	0297ca63          	blt	a5,s1,80000322 <consoleintr+0x58>
    800002f2:	47a1                	li	a5,8
    800002f4:	0ef48763          	beq	s1,a5,800003e2 <consoleintr+0x118>
    800002f8:	47c1                	li	a5,16
    800002fa:	10f49a63          	bne	s1,a5,8000040e <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002fe:	00002097          	auipc	ra,0x2
    80000302:	52e080e7          	jalr	1326(ra) # 8000282c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000306:	00011517          	auipc	a0,0x11
    8000030a:	e6a50513          	addi	a0,a0,-406 # 80011170 <cons>
    8000030e:	00001097          	auipc	ra,0x1
    80000312:	a8e080e7          	jalr	-1394(ra) # 80000d9c <release>
}
    80000316:	60e2                	ld	ra,24(sp)
    80000318:	6442                	ld	s0,16(sp)
    8000031a:	64a2                	ld	s1,8(sp)
    8000031c:	6902                	ld	s2,0(sp)
    8000031e:	6105                	addi	sp,sp,32
    80000320:	8082                	ret
  switch(c){
    80000322:	07f00793          	li	a5,127
    80000326:	0af48e63          	beq	s1,a5,800003e2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000032a:	00011717          	auipc	a4,0x11
    8000032e:	e4670713          	addi	a4,a4,-442 # 80011170 <cons>
    80000332:	0a872783          	lw	a5,168(a4)
    80000336:	0a072703          	lw	a4,160(a4)
    8000033a:	9f99                	subw	a5,a5,a4
    8000033c:	07f00713          	li	a4,127
    80000340:	fcf763e3          	bltu	a4,a5,80000306 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000344:	47b5                	li	a5,13
    80000346:	0cf48763          	beq	s1,a5,80000414 <consoleintr+0x14a>
      consputc(c);
    8000034a:	8526                	mv	a0,s1
    8000034c:	00000097          	auipc	ra,0x0
    80000350:	f3c080e7          	jalr	-196(ra) # 80000288 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000354:	00011797          	auipc	a5,0x11
    80000358:	e1c78793          	addi	a5,a5,-484 # 80011170 <cons>
    8000035c:	0a87a703          	lw	a4,168(a5)
    80000360:	0017069b          	addiw	a3,a4,1
    80000364:	0006861b          	sext.w	a2,a3
    80000368:	0ad7a423          	sw	a3,168(a5)
    8000036c:	07f77713          	andi	a4,a4,127
    80000370:	97ba                	add	a5,a5,a4
    80000372:	02978023          	sb	s1,32(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000376:	47a9                	li	a5,10
    80000378:	0cf48563          	beq	s1,a5,80000442 <consoleintr+0x178>
    8000037c:	4791                	li	a5,4
    8000037e:	0cf48263          	beq	s1,a5,80000442 <consoleintr+0x178>
    80000382:	00011797          	auipc	a5,0x11
    80000386:	e8e7a783          	lw	a5,-370(a5) # 80011210 <cons+0xa0>
    8000038a:	0807879b          	addiw	a5,a5,128
    8000038e:	f6f61ce3          	bne	a2,a5,80000306 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000392:	863e                	mv	a2,a5
    80000394:	a07d                	j	80000442 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000396:	00011717          	auipc	a4,0x11
    8000039a:	dda70713          	addi	a4,a4,-550 # 80011170 <cons>
    8000039e:	0a872783          	lw	a5,168(a4)
    800003a2:	0a472703          	lw	a4,164(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a6:	00011497          	auipc	s1,0x11
    800003aa:	dca48493          	addi	s1,s1,-566 # 80011170 <cons>
    while(cons.e != cons.w &&
    800003ae:	4929                	li	s2,10
    800003b0:	f4f70be3          	beq	a4,a5,80000306 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b4:	37fd                	addiw	a5,a5,-1
    800003b6:	07f7f713          	andi	a4,a5,127
    800003ba:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003bc:	02074703          	lbu	a4,32(a4)
    800003c0:	f52703e3          	beq	a4,s2,80000306 <consoleintr+0x3c>
      cons.e--;
    800003c4:	0af4a423          	sw	a5,168(s1)
      consputc(BACKSPACE);
    800003c8:	10000513          	li	a0,256
    800003cc:	00000097          	auipc	ra,0x0
    800003d0:	ebc080e7          	jalr	-324(ra) # 80000288 <consputc>
    while(cons.e != cons.w &&
    800003d4:	0a84a783          	lw	a5,168(s1)
    800003d8:	0a44a703          	lw	a4,164(s1)
    800003dc:	fcf71ce3          	bne	a4,a5,800003b4 <consoleintr+0xea>
    800003e0:	b71d                	j	80000306 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e2:	00011717          	auipc	a4,0x11
    800003e6:	d8e70713          	addi	a4,a4,-626 # 80011170 <cons>
    800003ea:	0a872783          	lw	a5,168(a4)
    800003ee:	0a472703          	lw	a4,164(a4)
    800003f2:	f0f70ae3          	beq	a4,a5,80000306 <consoleintr+0x3c>
      cons.e--;
    800003f6:	37fd                	addiw	a5,a5,-1
    800003f8:	00011717          	auipc	a4,0x11
    800003fc:	e2f72023          	sw	a5,-480(a4) # 80011218 <cons+0xa8>
      consputc(BACKSPACE);
    80000400:	10000513          	li	a0,256
    80000404:	00000097          	auipc	ra,0x0
    80000408:	e84080e7          	jalr	-380(ra) # 80000288 <consputc>
    8000040c:	bded                	j	80000306 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000040e:	ee048ce3          	beqz	s1,80000306 <consoleintr+0x3c>
    80000412:	bf21                	j	8000032a <consoleintr+0x60>
      consputc(c);
    80000414:	4529                	li	a0,10
    80000416:	00000097          	auipc	ra,0x0
    8000041a:	e72080e7          	jalr	-398(ra) # 80000288 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000041e:	00011797          	auipc	a5,0x11
    80000422:	d5278793          	addi	a5,a5,-686 # 80011170 <cons>
    80000426:	0a87a703          	lw	a4,168(a5)
    8000042a:	0017069b          	addiw	a3,a4,1
    8000042e:	0006861b          	sext.w	a2,a3
    80000432:	0ad7a423          	sw	a3,168(a5)
    80000436:	07f77713          	andi	a4,a4,127
    8000043a:	97ba                	add	a5,a5,a4
    8000043c:	4729                	li	a4,10
    8000043e:	02e78023          	sb	a4,32(a5)
        cons.w = cons.e;
    80000442:	00011797          	auipc	a5,0x11
    80000446:	dcc7a923          	sw	a2,-558(a5) # 80011214 <cons+0xa4>
        wakeup(&cons.r);
    8000044a:	00011517          	auipc	a0,0x11
    8000044e:	dc650513          	addi	a0,a0,-570 # 80011210 <cons+0xa0>
    80000452:	00002097          	auipc	ra,0x2
    80000456:	254080e7          	jalr	596(ra) # 800026a6 <wakeup>
    8000045a:	b575                	j	80000306 <consoleintr+0x3c>

000000008000045c <consoleinit>:

void
consoleinit(void)
{
    8000045c:	1141                	addi	sp,sp,-16
    8000045e:	e406                	sd	ra,8(sp)
    80000460:	e022                	sd	s0,0(sp)
    80000462:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000464:	00008597          	auipc	a1,0x8
    80000468:	bac58593          	addi	a1,a1,-1108 # 80008010 <etext+0x10>
    8000046c:	00011517          	auipc	a0,0x11
    80000470:	d0450513          	addi	a0,a0,-764 # 80011170 <cons>
    80000474:	00001097          	auipc	ra,0x1
    80000478:	9d4080e7          	jalr	-1580(ra) # 80000e48 <initlock>

  uartinit();
    8000047c:	00000097          	auipc	ra,0x0
    80000480:	32a080e7          	jalr	810(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000484:	00026797          	auipc	a5,0x26
    80000488:	8bc78793          	addi	a5,a5,-1860 # 80025d40 <devsw>
    8000048c:	00000717          	auipc	a4,0x0
    80000490:	cea70713          	addi	a4,a4,-790 # 80000176 <consoleread>
    80000494:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000496:	00000717          	auipc	a4,0x0
    8000049a:	c5e70713          	addi	a4,a4,-930 # 800000f4 <consolewrite>
    8000049e:	ef98                	sd	a4,24(a5)
}
    800004a0:	60a2                	ld	ra,8(sp)
    800004a2:	6402                	ld	s0,0(sp)
    800004a4:	0141                	addi	sp,sp,16
    800004a6:	8082                	ret

00000000800004a8 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a8:	7179                	addi	sp,sp,-48
    800004aa:	f406                	sd	ra,40(sp)
    800004ac:	f022                	sd	s0,32(sp)
    800004ae:	ec26                	sd	s1,24(sp)
    800004b0:	e84a                	sd	s2,16(sp)
    800004b2:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004b4:	c219                	beqz	a2,800004ba <printint+0x12>
    800004b6:	08054663          	bltz	a0,80000542 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ba:	2501                	sext.w	a0,a0
    800004bc:	4881                	li	a7,0
    800004be:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004c4:	2581                	sext.w	a1,a1
    800004c6:	00008617          	auipc	a2,0x8
    800004ca:	b7a60613          	addi	a2,a2,-1158 # 80008040 <digits>
    800004ce:	883a                	mv	a6,a4
    800004d0:	2705                	addiw	a4,a4,1
    800004d2:	02b577bb          	remuw	a5,a0,a1
    800004d6:	1782                	slli	a5,a5,0x20
    800004d8:	9381                	srli	a5,a5,0x20
    800004da:	97b2                	add	a5,a5,a2
    800004dc:	0007c783          	lbu	a5,0(a5)
    800004e0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004e4:	0005079b          	sext.w	a5,a0
    800004e8:	02b5553b          	divuw	a0,a0,a1
    800004ec:	0685                	addi	a3,a3,1
    800004ee:	feb7f0e3          	bgeu	a5,a1,800004ce <printint+0x26>

  if(sign)
    800004f2:	00088b63          	beqz	a7,80000508 <printint+0x60>
    buf[i++] = '-';
    800004f6:	fe040793          	addi	a5,s0,-32
    800004fa:	973e                	add	a4,a4,a5
    800004fc:	02d00793          	li	a5,45
    80000500:	fef70823          	sb	a5,-16(a4)
    80000504:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000508:	02e05763          	blez	a4,80000536 <printint+0x8e>
    8000050c:	fd040793          	addi	a5,s0,-48
    80000510:	00e784b3          	add	s1,a5,a4
    80000514:	fff78913          	addi	s2,a5,-1
    80000518:	993a                	add	s2,s2,a4
    8000051a:	377d                	addiw	a4,a4,-1
    8000051c:	1702                	slli	a4,a4,0x20
    8000051e:	9301                	srli	a4,a4,0x20
    80000520:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000524:	fff4c503          	lbu	a0,-1(s1)
    80000528:	00000097          	auipc	ra,0x0
    8000052c:	d60080e7          	jalr	-672(ra) # 80000288 <consputc>
  while(--i >= 0)
    80000530:	14fd                	addi	s1,s1,-1
    80000532:	ff2499e3          	bne	s1,s2,80000524 <printint+0x7c>
}
    80000536:	70a2                	ld	ra,40(sp)
    80000538:	7402                	ld	s0,32(sp)
    8000053a:	64e2                	ld	s1,24(sp)
    8000053c:	6942                	ld	s2,16(sp)
    8000053e:	6145                	addi	sp,sp,48
    80000540:	8082                	ret
    x = -xx;
    80000542:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000546:	4885                	li	a7,1
    x = -xx;
    80000548:	bf9d                	j	800004be <printint+0x16>

000000008000054a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000054a:	1101                	addi	sp,sp,-32
    8000054c:	ec06                	sd	ra,24(sp)
    8000054e:	e822                	sd	s0,16(sp)
    80000550:	e426                	sd	s1,8(sp)
    80000552:	1000                	addi	s0,sp,32
    80000554:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000556:	00011797          	auipc	a5,0x11
    8000055a:	ce07a523          	sw	zero,-790(a5) # 80011240 <pr+0x20>
  printf("panic: ");
    8000055e:	00008517          	auipc	a0,0x8
    80000562:	aba50513          	addi	a0,a0,-1350 # 80008018 <etext+0x18>
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	02e080e7          	jalr	46(ra) # 80000594 <printf>
  printf(s);
    8000056e:	8526                	mv	a0,s1
    80000570:	00000097          	auipc	ra,0x0
    80000574:	024080e7          	jalr	36(ra) # 80000594 <printf>
  printf("\n");
    80000578:	00008517          	auipc	a0,0x8
    8000057c:	be850513          	addi	a0,a0,-1048 # 80008160 <digits+0x120>
    80000580:	00000097          	auipc	ra,0x0
    80000584:	014080e7          	jalr	20(ra) # 80000594 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000588:	4785                	li	a5,1
    8000058a:	00009717          	auipc	a4,0x9
    8000058e:	a6f72b23          	sw	a5,-1418(a4) # 80009000 <panicked>
  for(;;)
    80000592:	a001                	j	80000592 <panic+0x48>

0000000080000594 <printf>:
{
    80000594:	7131                	addi	sp,sp,-192
    80000596:	fc86                	sd	ra,120(sp)
    80000598:	f8a2                	sd	s0,112(sp)
    8000059a:	f4a6                	sd	s1,104(sp)
    8000059c:	f0ca                	sd	s2,96(sp)
    8000059e:	ecce                	sd	s3,88(sp)
    800005a0:	e8d2                	sd	s4,80(sp)
    800005a2:	e4d6                	sd	s5,72(sp)
    800005a4:	e0da                	sd	s6,64(sp)
    800005a6:	fc5e                	sd	s7,56(sp)
    800005a8:	f862                	sd	s8,48(sp)
    800005aa:	f466                	sd	s9,40(sp)
    800005ac:	f06a                	sd	s10,32(sp)
    800005ae:	ec6e                	sd	s11,24(sp)
    800005b0:	0100                	addi	s0,sp,128
    800005b2:	8a2a                	mv	s4,a0
    800005b4:	e40c                	sd	a1,8(s0)
    800005b6:	e810                	sd	a2,16(s0)
    800005b8:	ec14                	sd	a3,24(s0)
    800005ba:	f018                	sd	a4,32(s0)
    800005bc:	f41c                	sd	a5,40(s0)
    800005be:	03043823          	sd	a6,48(s0)
    800005c2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c6:	00011d97          	auipc	s11,0x11
    800005ca:	c7adad83          	lw	s11,-902(s11) # 80011240 <pr+0x20>
  if(locking)
    800005ce:	020d9b63          	bnez	s11,80000604 <printf+0x70>
  if (fmt == 0)
    800005d2:	040a0263          	beqz	s4,80000616 <printf+0x82>
  va_start(ap, fmt);
    800005d6:	00840793          	addi	a5,s0,8
    800005da:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005de:	000a4503          	lbu	a0,0(s4)
    800005e2:	14050f63          	beqz	a0,80000740 <printf+0x1ac>
    800005e6:	4981                	li	s3,0
    if(c != '%'){
    800005e8:	02500a93          	li	s5,37
    switch(c){
    800005ec:	07000b93          	li	s7,112
  consputc('x');
    800005f0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f2:	00008b17          	auipc	s6,0x8
    800005f6:	a4eb0b13          	addi	s6,s6,-1458 # 80008040 <digits>
    switch(c){
    800005fa:	07300c93          	li	s9,115
    800005fe:	06400c13          	li	s8,100
    80000602:	a82d                	j	8000063c <printf+0xa8>
    acquire(&pr.lock);
    80000604:	00011517          	auipc	a0,0x11
    80000608:	c1c50513          	addi	a0,a0,-996 # 80011220 <pr>
    8000060c:	00000097          	auipc	ra,0x0
    80000610:	6c0080e7          	jalr	1728(ra) # 80000ccc <acquire>
    80000614:	bf7d                	j	800005d2 <printf+0x3e>
    panic("null fmt");
    80000616:	00008517          	auipc	a0,0x8
    8000061a:	a1250513          	addi	a0,a0,-1518 # 80008028 <etext+0x28>
    8000061e:	00000097          	auipc	ra,0x0
    80000622:	f2c080e7          	jalr	-212(ra) # 8000054a <panic>
      consputc(c);
    80000626:	00000097          	auipc	ra,0x0
    8000062a:	c62080e7          	jalr	-926(ra) # 80000288 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000062e:	2985                	addiw	s3,s3,1
    80000630:	013a07b3          	add	a5,s4,s3
    80000634:	0007c503          	lbu	a0,0(a5)
    80000638:	10050463          	beqz	a0,80000740 <printf+0x1ac>
    if(c != '%'){
    8000063c:	ff5515e3          	bne	a0,s5,80000626 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000640:	2985                	addiw	s3,s3,1
    80000642:	013a07b3          	add	a5,s4,s3
    80000646:	0007c783          	lbu	a5,0(a5)
    8000064a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000064e:	cbed                	beqz	a5,80000740 <printf+0x1ac>
    switch(c){
    80000650:	05778a63          	beq	a5,s7,800006a4 <printf+0x110>
    80000654:	02fbf663          	bgeu	s7,a5,80000680 <printf+0xec>
    80000658:	09978863          	beq	a5,s9,800006e8 <printf+0x154>
    8000065c:	07800713          	li	a4,120
    80000660:	0ce79563          	bne	a5,a4,8000072a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000664:	f8843783          	ld	a5,-120(s0)
    80000668:	00878713          	addi	a4,a5,8
    8000066c:	f8e43423          	sd	a4,-120(s0)
    80000670:	4605                	li	a2,1
    80000672:	85ea                	mv	a1,s10
    80000674:	4388                	lw	a0,0(a5)
    80000676:	00000097          	auipc	ra,0x0
    8000067a:	e32080e7          	jalr	-462(ra) # 800004a8 <printint>
      break;
    8000067e:	bf45                	j	8000062e <printf+0x9a>
    switch(c){
    80000680:	09578f63          	beq	a5,s5,8000071e <printf+0x18a>
    80000684:	0b879363          	bne	a5,s8,8000072a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000688:	f8843783          	ld	a5,-120(s0)
    8000068c:	00878713          	addi	a4,a5,8
    80000690:	f8e43423          	sd	a4,-120(s0)
    80000694:	4605                	li	a2,1
    80000696:	45a9                	li	a1,10
    80000698:	4388                	lw	a0,0(a5)
    8000069a:	00000097          	auipc	ra,0x0
    8000069e:	e0e080e7          	jalr	-498(ra) # 800004a8 <printint>
      break;
    800006a2:	b771                	j	8000062e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006a4:	f8843783          	ld	a5,-120(s0)
    800006a8:	00878713          	addi	a4,a5,8
    800006ac:	f8e43423          	sd	a4,-120(s0)
    800006b0:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006b4:	03000513          	li	a0,48
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bd0080e7          	jalr	-1072(ra) # 80000288 <consputc>
  consputc('x');
    800006c0:	07800513          	li	a0,120
    800006c4:	00000097          	auipc	ra,0x0
    800006c8:	bc4080e7          	jalr	-1084(ra) # 80000288 <consputc>
    800006cc:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006ce:	03c95793          	srli	a5,s2,0x3c
    800006d2:	97da                	add	a5,a5,s6
    800006d4:	0007c503          	lbu	a0,0(a5)
    800006d8:	00000097          	auipc	ra,0x0
    800006dc:	bb0080e7          	jalr	-1104(ra) # 80000288 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006e0:	0912                	slli	s2,s2,0x4
    800006e2:	34fd                	addiw	s1,s1,-1
    800006e4:	f4ed                	bnez	s1,800006ce <printf+0x13a>
    800006e6:	b7a1                	j	8000062e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	6384                	ld	s1,0(a5)
    800006f6:	cc89                	beqz	s1,80000710 <printf+0x17c>
      for(; *s; s++)
    800006f8:	0004c503          	lbu	a0,0(s1)
    800006fc:	d90d                	beqz	a0,8000062e <printf+0x9a>
        consputc(*s);
    800006fe:	00000097          	auipc	ra,0x0
    80000702:	b8a080e7          	jalr	-1142(ra) # 80000288 <consputc>
      for(; *s; s++)
    80000706:	0485                	addi	s1,s1,1
    80000708:	0004c503          	lbu	a0,0(s1)
    8000070c:	f96d                	bnez	a0,800006fe <printf+0x16a>
    8000070e:	b705                	j	8000062e <printf+0x9a>
        s = "(null)";
    80000710:	00008497          	auipc	s1,0x8
    80000714:	91048493          	addi	s1,s1,-1776 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000718:	02800513          	li	a0,40
    8000071c:	b7cd                	j	800006fe <printf+0x16a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b68080e7          	jalr	-1176(ra) # 80000288 <consputc>
      break;
    80000728:	b719                	j	8000062e <printf+0x9a>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b5c080e7          	jalr	-1188(ra) # 80000288 <consputc>
      consputc(c);
    80000734:	8526                	mv	a0,s1
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	b52080e7          	jalr	-1198(ra) # 80000288 <consputc>
      break;
    8000073e:	bdc5                	j	8000062e <printf+0x9a>
  if(locking)
    80000740:	020d9163          	bnez	s11,80000762 <printf+0x1ce>
}
    80000744:	70e6                	ld	ra,120(sp)
    80000746:	7446                	ld	s0,112(sp)
    80000748:	74a6                	ld	s1,104(sp)
    8000074a:	7906                	ld	s2,96(sp)
    8000074c:	69e6                	ld	s3,88(sp)
    8000074e:	6a46                	ld	s4,80(sp)
    80000750:	6aa6                	ld	s5,72(sp)
    80000752:	6b06                	ld	s6,64(sp)
    80000754:	7be2                	ld	s7,56(sp)
    80000756:	7c42                	ld	s8,48(sp)
    80000758:	7ca2                	ld	s9,40(sp)
    8000075a:	7d02                	ld	s10,32(sp)
    8000075c:	6de2                	ld	s11,24(sp)
    8000075e:	6129                	addi	sp,sp,192
    80000760:	8082                	ret
    release(&pr.lock);
    80000762:	00011517          	auipc	a0,0x11
    80000766:	abe50513          	addi	a0,a0,-1346 # 80011220 <pr>
    8000076a:	00000097          	auipc	ra,0x0
    8000076e:	632080e7          	jalr	1586(ra) # 80000d9c <release>
}
    80000772:	bfc9                	j	80000744 <printf+0x1b0>

0000000080000774 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000774:	1101                	addi	sp,sp,-32
    80000776:	ec06                	sd	ra,24(sp)
    80000778:	e822                	sd	s0,16(sp)
    8000077a:	e426                	sd	s1,8(sp)
    8000077c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000077e:	00011497          	auipc	s1,0x11
    80000782:	aa248493          	addi	s1,s1,-1374 # 80011220 <pr>
    80000786:	00008597          	auipc	a1,0x8
    8000078a:	8b258593          	addi	a1,a1,-1870 # 80008038 <etext+0x38>
    8000078e:	8526                	mv	a0,s1
    80000790:	00000097          	auipc	ra,0x0
    80000794:	6b8080e7          	jalr	1720(ra) # 80000e48 <initlock>
  pr.locking = 1;
    80000798:	4785                	li	a5,1
    8000079a:	d09c                	sw	a5,32(s1)
}
    8000079c:	60e2                	ld	ra,24(sp)
    8000079e:	6442                	ld	s0,16(sp)
    800007a0:	64a2                	ld	s1,8(sp)
    800007a2:	6105                	addi	sp,sp,32
    800007a4:	8082                	ret

00000000800007a6 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a6:	1141                	addi	sp,sp,-16
    800007a8:	e406                	sd	ra,8(sp)
    800007aa:	e022                	sd	s0,0(sp)
    800007ac:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ae:	100007b7          	lui	a5,0x10000
    800007b2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b6:	f8000713          	li	a4,-128
    800007ba:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007be:	470d                	li	a4,3
    800007c0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007cc:	469d                	li	a3,7
    800007ce:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d6:	00008597          	auipc	a1,0x8
    800007da:	88258593          	addi	a1,a1,-1918 # 80008058 <digits+0x18>
    800007de:	00011517          	auipc	a0,0x11
    800007e2:	a6a50513          	addi	a0,a0,-1430 # 80011248 <uart_tx_lock>
    800007e6:	00000097          	auipc	ra,0x0
    800007ea:	662080e7          	jalr	1634(ra) # 80000e48 <initlock>
}
    800007ee:	60a2                	ld	ra,8(sp)
    800007f0:	6402                	ld	s0,0(sp)
    800007f2:	0141                	addi	sp,sp,16
    800007f4:	8082                	ret

00000000800007f6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f6:	1101                	addi	sp,sp,-32
    800007f8:	ec06                	sd	ra,24(sp)
    800007fa:	e822                	sd	s0,16(sp)
    800007fc:	e426                	sd	s1,8(sp)
    800007fe:	1000                	addi	s0,sp,32
    80000800:	84aa                	mv	s1,a0
  push_off();
    80000802:	00000097          	auipc	ra,0x0
    80000806:	47e080e7          	jalr	1150(ra) # 80000c80 <push_off>

  if(panicked){
    8000080a:	00008797          	auipc	a5,0x8
    8000080e:	7f67a783          	lw	a5,2038(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	10000737          	lui	a4,0x10000
  if(panicked){
    80000816:	c391                	beqz	a5,8000081a <uartputc_sync+0x24>
    for(;;)
    80000818:	a001                	j	80000818 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000081e:	0207f793          	andi	a5,a5,32
    80000822:	dfe5                	beqz	a5,8000081a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000824:	0ff4f513          	andi	a0,s1,255
    80000828:	100007b7          	lui	a5,0x10000
    8000082c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000830:	00000097          	auipc	ra,0x0
    80000834:	50c080e7          	jalr	1292(ra) # 80000d3c <pop_off>
}
    80000838:	60e2                	ld	ra,24(sp)
    8000083a:	6442                	ld	s0,16(sp)
    8000083c:	64a2                	ld	s1,8(sp)
    8000083e:	6105                	addi	sp,sp,32
    80000840:	8082                	ret

0000000080000842 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000842:	00008797          	auipc	a5,0x8
    80000846:	7c27a783          	lw	a5,1986(a5) # 80009004 <uart_tx_r>
    8000084a:	00008717          	auipc	a4,0x8
    8000084e:	7be72703          	lw	a4,1982(a4) # 80009008 <uart_tx_w>
    80000852:	08f70063          	beq	a4,a5,800008d2 <uartstart+0x90>
{
    80000856:	7139                	addi	sp,sp,-64
    80000858:	fc06                	sd	ra,56(sp)
    8000085a:	f822                	sd	s0,48(sp)
    8000085c:	f426                	sd	s1,40(sp)
    8000085e:	f04a                	sd	s2,32(sp)
    80000860:	ec4e                	sd	s3,24(sp)
    80000862:	e852                	sd	s4,16(sp)
    80000864:	e456                	sd	s5,8(sp)
    80000866:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000868:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    8000086c:	00011a97          	auipc	s5,0x11
    80000870:	9dca8a93          	addi	s5,s5,-1572 # 80011248 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    80000874:	00008497          	auipc	s1,0x8
    80000878:	79048493          	addi	s1,s1,1936 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087c:	00008a17          	auipc	s4,0x8
    80000880:	78ca0a13          	addi	s4,s4,1932 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000884:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000888:	02077713          	andi	a4,a4,32
    8000088c:	cb15                	beqz	a4,800008c0 <uartstart+0x7e>
    int c = uart_tx_buf[uart_tx_r];
    8000088e:	00fa8733          	add	a4,s5,a5
    80000892:	02074983          	lbu	s3,32(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    80000896:	2785                	addiw	a5,a5,1
    80000898:	41f7d71b          	sraiw	a4,a5,0x1f
    8000089c:	01b7571b          	srliw	a4,a4,0x1b
    800008a0:	9fb9                	addw	a5,a5,a4
    800008a2:	8bfd                	andi	a5,a5,31
    800008a4:	9f99                	subw	a5,a5,a4
    800008a6:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a8:	8526                	mv	a0,s1
    800008aa:	00002097          	auipc	ra,0x2
    800008ae:	dfc080e7          	jalr	-516(ra) # 800026a6 <wakeup>
    
    WriteReg(THR, c);
    800008b2:	01390023          	sb	s3,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b6:	409c                	lw	a5,0(s1)
    800008b8:	000a2703          	lw	a4,0(s4)
    800008bc:	fcf714e3          	bne	a4,a5,80000884 <uartstart+0x42>
  }
}
    800008c0:	70e2                	ld	ra,56(sp)
    800008c2:	7442                	ld	s0,48(sp)
    800008c4:	74a2                	ld	s1,40(sp)
    800008c6:	7902                	ld	s2,32(sp)
    800008c8:	69e2                	ld	s3,24(sp)
    800008ca:	6a42                	ld	s4,16(sp)
    800008cc:	6aa2                	ld	s5,8(sp)
    800008ce:	6121                	addi	sp,sp,64
    800008d0:	8082                	ret
    800008d2:	8082                	ret

00000000800008d4 <uartputc>:
{
    800008d4:	7179                	addi	sp,sp,-48
    800008d6:	f406                	sd	ra,40(sp)
    800008d8:	f022                	sd	s0,32(sp)
    800008da:	ec26                	sd	s1,24(sp)
    800008dc:	e84a                	sd	s2,16(sp)
    800008de:	e44e                	sd	s3,8(sp)
    800008e0:	e052                	sd	s4,0(sp)
    800008e2:	1800                	addi	s0,sp,48
    800008e4:	84aa                	mv	s1,a0
  acquire(&uart_tx_lock);
    800008e6:	00011517          	auipc	a0,0x11
    800008ea:	96250513          	addi	a0,a0,-1694 # 80011248 <uart_tx_lock>
    800008ee:	00000097          	auipc	ra,0x0
    800008f2:	3de080e7          	jalr	990(ra) # 80000ccc <acquire>
  if(panicked){
    800008f6:	00008797          	auipc	a5,0x8
    800008fa:	70a7a783          	lw	a5,1802(a5) # 80009000 <panicked>
    800008fe:	c391                	beqz	a5,80000902 <uartputc+0x2e>
    for(;;)
    80000900:	a001                	j	80000900 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000902:	00008697          	auipc	a3,0x8
    80000906:	7066a683          	lw	a3,1798(a3) # 80009008 <uart_tx_w>
    8000090a:	0016879b          	addiw	a5,a3,1
    8000090e:	41f7d71b          	sraiw	a4,a5,0x1f
    80000912:	01b7571b          	srliw	a4,a4,0x1b
    80000916:	9fb9                	addw	a5,a5,a4
    80000918:	8bfd                	andi	a5,a5,31
    8000091a:	9f99                	subw	a5,a5,a4
    8000091c:	00008717          	auipc	a4,0x8
    80000920:	6e872703          	lw	a4,1768(a4) # 80009004 <uart_tx_r>
    80000924:	04f71363          	bne	a4,a5,8000096a <uartputc+0x96>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	00011a17          	auipc	s4,0x11
    8000092c:	920a0a13          	addi	s4,s4,-1760 # 80011248 <uart_tx_lock>
    80000930:	00008917          	auipc	s2,0x8
    80000934:	6d490913          	addi	s2,s2,1748 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000938:	00008997          	auipc	s3,0x8
    8000093c:	6d098993          	addi	s3,s3,1744 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000940:	85d2                	mv	a1,s4
    80000942:	854a                	mv	a0,s2
    80000944:	00002097          	auipc	ra,0x2
    80000948:	be2080e7          	jalr	-1054(ra) # 80002526 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000094c:	0009a683          	lw	a3,0(s3)
    80000950:	0016879b          	addiw	a5,a3,1
    80000954:	41f7d71b          	sraiw	a4,a5,0x1f
    80000958:	01b7571b          	srliw	a4,a4,0x1b
    8000095c:	9fb9                	addw	a5,a5,a4
    8000095e:	8bfd                	andi	a5,a5,31
    80000960:	9f99                	subw	a5,a5,a4
    80000962:	00092703          	lw	a4,0(s2)
    80000966:	fcf70de3          	beq	a4,a5,80000940 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    8000096a:	00011917          	auipc	s2,0x11
    8000096e:	8de90913          	addi	s2,s2,-1826 # 80011248 <uart_tx_lock>
    80000972:	96ca                	add	a3,a3,s2
    80000974:	02968023          	sb	s1,32(a3)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000978:	00008717          	auipc	a4,0x8
    8000097c:	68f72823          	sw	a5,1680(a4) # 80009008 <uart_tx_w>
      uartstart();
    80000980:	00000097          	auipc	ra,0x0
    80000984:	ec2080e7          	jalr	-318(ra) # 80000842 <uartstart>
      release(&uart_tx_lock);
    80000988:	854a                	mv	a0,s2
    8000098a:	00000097          	auipc	ra,0x0
    8000098e:	412080e7          	jalr	1042(ra) # 80000d9c <release>
}
    80000992:	70a2                	ld	ra,40(sp)
    80000994:	7402                	ld	s0,32(sp)
    80000996:	64e2                	ld	s1,24(sp)
    80000998:	6942                	ld	s2,16(sp)
    8000099a:	69a2                	ld	s3,8(sp)
    8000099c:	6a02                	ld	s4,0(sp)
    8000099e:	6145                	addi	sp,sp,48
    800009a0:	8082                	ret

00000000800009a2 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009a2:	1141                	addi	sp,sp,-16
    800009a4:	e422                	sd	s0,8(sp)
    800009a6:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009a8:	100007b7          	lui	a5,0x10000
    800009ac:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009b0:	8b85                	andi	a5,a5,1
    800009b2:	cb91                	beqz	a5,800009c6 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009b4:	100007b7          	lui	a5,0x10000
    800009b8:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009bc:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009c0:	6422                	ld	s0,8(sp)
    800009c2:	0141                	addi	sp,sp,16
    800009c4:	8082                	ret
    return -1;
    800009c6:	557d                	li	a0,-1
    800009c8:	bfe5                	j	800009c0 <uartgetc+0x1e>

00000000800009ca <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009ca:	1101                	addi	sp,sp,-32
    800009cc:	ec06                	sd	ra,24(sp)
    800009ce:	e822                	sd	s0,16(sp)
    800009d0:	e426                	sd	s1,8(sp)
    800009d2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009d4:	54fd                	li	s1,-1
    800009d6:	a029                	j	800009e0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	8f2080e7          	jalr	-1806(ra) # 800002ca <consoleintr>
    int c = uartgetc();
    800009e0:	00000097          	auipc	ra,0x0
    800009e4:	fc2080e7          	jalr	-62(ra) # 800009a2 <uartgetc>
    if(c == -1)
    800009e8:	fe9518e3          	bne	a0,s1,800009d8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ec:	00011497          	auipc	s1,0x11
    800009f0:	85c48493          	addi	s1,s1,-1956 # 80011248 <uart_tx_lock>
    800009f4:	8526                	mv	a0,s1
    800009f6:	00000097          	auipc	ra,0x0
    800009fa:	2d6080e7          	jalr	726(ra) # 80000ccc <acquire>
  uartstart();
    800009fe:	00000097          	auipc	ra,0x0
    80000a02:	e44080e7          	jalr	-444(ra) # 80000842 <uartstart>
  release(&uart_tx_lock);
    80000a06:	8526                	mv	a0,s1
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	394080e7          	jalr	916(ra) # 80000d9c <release>
}
    80000a10:	60e2                	ld	ra,24(sp)
    80000a12:	6442                	ld	s0,16(sp)
    80000a14:	64a2                	ld	s1,8(sp)
    80000a16:	6105                	addi	sp,sp,32
    80000a18:	8082                	ret

0000000080000a1a <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a1a:	7139                	addi	sp,sp,-64
    80000a1c:	fc06                	sd	ra,56(sp)
    80000a1e:	f822                	sd	s0,48(sp)
    80000a20:	f426                	sd	s1,40(sp)
    80000a22:	f04a                	sd	s2,32(sp)
    80000a24:	ec4e                	sd	s3,24(sp)
    80000a26:	e852                	sd	s4,16(sp)
    80000a28:	e456                	sd	s5,8(sp)
    80000a2a:	0080                	addi	s0,sp,64
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a2c:	03451793          	slli	a5,a0,0x34
    80000a30:	e3d1                	bnez	a5,80000ab4 <kfree+0x9a>
    80000a32:	84aa                	mv	s1,a0
    80000a34:	0002a797          	auipc	a5,0x2a
    80000a38:	5f478793          	addi	a5,a5,1524 # 8002b028 <end>
    80000a3c:	06f56c63          	bltu	a0,a5,80000ab4 <kfree+0x9a>
    80000a40:	47c5                	li	a5,17
    80000a42:	07ee                	slli	a5,a5,0x1b
    80000a44:	06f57863          	bgeu	a0,a5,80000ab4 <kfree+0x9a>
    panic("kfree");
  push_off();
    80000a48:	00000097          	auipc	ra,0x0
    80000a4c:	238080e7          	jalr	568(ra) # 80000c80 <push_off>
  int id=cpuid();
    80000a50:	00001097          	auipc	ra,0x1
    80000a54:	296080e7          	jalr	662(ra) # 80001ce6 <cpuid>
    80000a58:	8a2a                	mv	s4,a0
  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a5a:	6605                	lui	a2,0x1
    80000a5c:	4585                	li	a1,1
    80000a5e:	8526                	mv	a0,s1
    80000a60:	00000097          	auipc	ra,0x0
    80000a64:	64c080e7          	jalr	1612(ra) # 800010ac <memset>

  r = (struct run*)pa;
  acquire(&kmem[id].lock);
    80000a68:	00011a97          	auipc	s5,0x11
    80000a6c:	820a8a93          	addi	s5,s5,-2016 # 80011288 <kmem>
    80000a70:	002a1993          	slli	s3,s4,0x2
    80000a74:	01498933          	add	s2,s3,s4
    80000a78:	090e                	slli	s2,s2,0x3
    80000a7a:	9956                	add	s2,s2,s5
    80000a7c:	854a                	mv	a0,s2
    80000a7e:	00000097          	auipc	ra,0x0
    80000a82:	24e080e7          	jalr	590(ra) # 80000ccc <acquire>
  r->next = kmem[id].freelist;
    80000a86:	02093783          	ld	a5,32(s2)
    80000a8a:	e09c                	sd	a5,0(s1)
  kmem[id].freelist = r;
    80000a8c:	02993023          	sd	s1,32(s2)
  release(&kmem[id].lock);
    80000a90:	854a                	mv	a0,s2
    80000a92:	00000097          	auipc	ra,0x0
    80000a96:	30a080e7          	jalr	778(ra) # 80000d9c <release>
  pop_off();
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	2a2080e7          	jalr	674(ra) # 80000d3c <pop_off>
}
    80000aa2:	70e2                	ld	ra,56(sp)
    80000aa4:	7442                	ld	s0,48(sp)
    80000aa6:	74a2                	ld	s1,40(sp)
    80000aa8:	7902                	ld	s2,32(sp)
    80000aaa:	69e2                	ld	s3,24(sp)
    80000aac:	6a42                	ld	s4,16(sp)
    80000aae:	6aa2                	ld	s5,8(sp)
    80000ab0:	6121                	addi	sp,sp,64
    80000ab2:	8082                	ret
    panic("kfree");
    80000ab4:	00007517          	auipc	a0,0x7
    80000ab8:	5ac50513          	addi	a0,a0,1452 # 80008060 <digits+0x20>
    80000abc:	00000097          	auipc	ra,0x0
    80000ac0:	a8e080e7          	jalr	-1394(ra) # 8000054a <panic>

0000000080000ac4 <freerange>:
{
    80000ac4:	7179                	addi	sp,sp,-48
    80000ac6:	f406                	sd	ra,40(sp)
    80000ac8:	f022                	sd	s0,32(sp)
    80000aca:	ec26                	sd	s1,24(sp)
    80000acc:	e84a                	sd	s2,16(sp)
    80000ace:	e44e                	sd	s3,8(sp)
    80000ad0:	e052                	sd	s4,0(sp)
    80000ad2:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000ad4:	6785                	lui	a5,0x1
    80000ad6:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000ada:	94aa                	add	s1,s1,a0
    80000adc:	757d                	lui	a0,0xfffff
    80000ade:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ae0:	94be                	add	s1,s1,a5
    80000ae2:	0095ee63          	bltu	a1,s1,80000afe <freerange+0x3a>
    80000ae6:	892e                	mv	s2,a1
    kfree(p);
    80000ae8:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aea:	6985                	lui	s3,0x1
    kfree(p);
    80000aec:	01448533          	add	a0,s1,s4
    80000af0:	00000097          	auipc	ra,0x0
    80000af4:	f2a080e7          	jalr	-214(ra) # 80000a1a <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000af8:	94ce                	add	s1,s1,s3
    80000afa:	fe9979e3          	bgeu	s2,s1,80000aec <freerange+0x28>
}
    80000afe:	70a2                	ld	ra,40(sp)
    80000b00:	7402                	ld	s0,32(sp)
    80000b02:	64e2                	ld	s1,24(sp)
    80000b04:	6942                	ld	s2,16(sp)
    80000b06:	69a2                	ld	s3,8(sp)
    80000b08:	6a02                	ld	s4,0(sp)
    80000b0a:	6145                	addi	sp,sp,48
    80000b0c:	8082                	ret

0000000080000b0e <kinit>:
{
    80000b0e:	7179                	addi	sp,sp,-48
    80000b10:	f406                	sd	ra,40(sp)
    80000b12:	f022                	sd	s0,32(sp)
    80000b14:	ec26                	sd	s1,24(sp)
    80000b16:	e84a                	sd	s2,16(sp)
    80000b18:	e44e                	sd	s3,8(sp)
    80000b1a:	1800                	addi	s0,sp,48
  for(int i=0;i<NCPU;i++)
    80000b1c:	00010497          	auipc	s1,0x10
    80000b20:	76c48493          	addi	s1,s1,1900 # 80011288 <kmem>
    80000b24:	00011997          	auipc	s3,0x11
    80000b28:	8a498993          	addi	s3,s3,-1884 # 800113c8 <lock_locks>
     initlock(&kmem[i].lock, "kmem");
    80000b2c:	00007917          	auipc	s2,0x7
    80000b30:	53c90913          	addi	s2,s2,1340 # 80008068 <digits+0x28>
    80000b34:	85ca                	mv	a1,s2
    80000b36:	8526                	mv	a0,s1
    80000b38:	00000097          	auipc	ra,0x0
    80000b3c:	310080e7          	jalr	784(ra) # 80000e48 <initlock>
  for(int i=0;i<NCPU;i++)
    80000b40:	02848493          	addi	s1,s1,40
    80000b44:	ff3498e3          	bne	s1,s3,80000b34 <kinit+0x26>
  freerange(end, (void*)PHYSTOP);
    80000b48:	45c5                	li	a1,17
    80000b4a:	05ee                	slli	a1,a1,0x1b
    80000b4c:	0002a517          	auipc	a0,0x2a
    80000b50:	4dc50513          	addi	a0,a0,1244 # 8002b028 <end>
    80000b54:	00000097          	auipc	ra,0x0
    80000b58:	f70080e7          	jalr	-144(ra) # 80000ac4 <freerange>
}
    80000b5c:	70a2                	ld	ra,40(sp)
    80000b5e:	7402                	ld	s0,32(sp)
    80000b60:	64e2                	ld	s1,24(sp)
    80000b62:	6942                	ld	s2,16(sp)
    80000b64:	69a2                	ld	s3,8(sp)
    80000b66:	6145                	addi	sp,sp,48
    80000b68:	8082                	ret

0000000080000b6a <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b6a:	7139                	addi	sp,sp,-64
    80000b6c:	fc06                	sd	ra,56(sp)
    80000b6e:	f822                	sd	s0,48(sp)
    80000b70:	f426                	sd	s1,40(sp)
    80000b72:	f04a                	sd	s2,32(sp)
    80000b74:	ec4e                	sd	s3,24(sp)
    80000b76:	e852                	sd	s4,16(sp)
    80000b78:	e456                	sd	s5,8(sp)
    80000b7a:	0080                	addi	s0,sp,64
  struct run *r;
  push_off();
    80000b7c:	00000097          	auipc	ra,0x0
    80000b80:	104080e7          	jalr	260(ra) # 80000c80 <push_off>
  int id=cpuid();
    80000b84:	00001097          	auipc	ra,0x1
    80000b88:	162080e7          	jalr	354(ra) # 80001ce6 <cpuid>
  acquire(&kmem[id].lock);
    80000b8c:	00251993          	slli	s3,a0,0x2
    80000b90:	99aa                	add	s3,s3,a0
    80000b92:	00399793          	slli	a5,s3,0x3
    80000b96:	00010997          	auipc	s3,0x10
    80000b9a:	6f298993          	addi	s3,s3,1778 # 80011288 <kmem>
    80000b9e:	99be                	add	s3,s3,a5
    80000ba0:	854e                	mv	a0,s3
    80000ba2:	00000097          	auipc	ra,0x0
    80000ba6:	12a080e7          	jalr	298(ra) # 80000ccc <acquire>
  r = kmem[id].freelist;
    80000baa:	0209b903          	ld	s2,32(s3)
  //freelist is not empty
  if(r)
    80000bae:	06090363          	beqz	s2,80000c14 <kalloc+0xaa>
    kmem[id].freelist = r->next;
    80000bb2:	00093703          	ld	a4,0(s2)
    80000bb6:	02e9b023          	sd	a4,32(s3)
  release(&kmem[id].lock);
    80000bba:	854e                	mv	a0,s3
    80000bbc:	00000097          	auipc	ra,0x0
    80000bc0:	1e0080e7          	jalr	480(ra) # 80000d9c <release>
      }
      release(&kmem[i].lock);
    }
  }
  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000bc4:	6605                	lui	a2,0x1
    80000bc6:	4595                	li	a1,5
    80000bc8:	854a                	mv	a0,s2
    80000bca:	00000097          	auipc	ra,0x0
    80000bce:	4e2080e7          	jalr	1250(ra) # 800010ac <memset>
  pop_off();
    80000bd2:	00000097          	auipc	ra,0x0
    80000bd6:	16a080e7          	jalr	362(ra) # 80000d3c <pop_off>
  return (void*)r;
}
    80000bda:	854a                	mv	a0,s2
    80000bdc:	70e2                	ld	ra,56(sp)
    80000bde:	7442                	ld	s0,48(sp)
    80000be0:	74a2                	ld	s1,40(sp)
    80000be2:	7902                	ld	s2,32(sp)
    80000be4:	69e2                	ld	s3,24(sp)
    80000be6:	6a42                	ld	s4,16(sp)
    80000be8:	6aa2                	ld	s5,8(sp)
    80000bea:	6121                	addi	sp,sp,64
    80000bec:	8082                	ret
        kmem[i].freelist=r->next;
    80000bee:	00093703          	ld	a4,0(s2)
    80000bf2:	00299793          	slli	a5,s3,0x2
    80000bf6:	99be                	add	s3,s3,a5
    80000bf8:	098e                	slli	s3,s3,0x3
    80000bfa:	00010797          	auipc	a5,0x10
    80000bfe:	68e78793          	addi	a5,a5,1678 # 80011288 <kmem>
    80000c02:	99be                	add	s3,s3,a5
    80000c04:	02e9b023          	sd	a4,32(s3)
	release(&kmem[i].lock);
    80000c08:	8526                	mv	a0,s1
    80000c0a:	00000097          	auipc	ra,0x0
    80000c0e:	192080e7          	jalr	402(ra) # 80000d9c <release>
	break;
    80000c12:	bf4d                	j	80000bc4 <kalloc+0x5a>
  release(&kmem[id].lock);
    80000c14:	854e                	mv	a0,s3
    80000c16:	00000097          	auipc	ra,0x0
    80000c1a:	186080e7          	jalr	390(ra) # 80000d9c <release>
    for(int i=0;i<NCPU;i++)
    80000c1e:	00010497          	auipc	s1,0x10
    80000c22:	66a48493          	addi	s1,s1,1642 # 80011288 <kmem>
    80000c26:	4981                	li	s3,0
    80000c28:	4a21                	li	s4,8
      acquire(&kmem[i].lock);
    80000c2a:	8526                	mv	a0,s1
    80000c2c:	00000097          	auipc	ra,0x0
    80000c30:	0a0080e7          	jalr	160(ra) # 80000ccc <acquire>
      r=kmem[i].freelist;
    80000c34:	0204b903          	ld	s2,32(s1)
      if(r)
    80000c38:	fa091be3          	bnez	s2,80000bee <kalloc+0x84>
      release(&kmem[i].lock);
    80000c3c:	8526                	mv	a0,s1
    80000c3e:	00000097          	auipc	ra,0x0
    80000c42:	15e080e7          	jalr	350(ra) # 80000d9c <release>
    for(int i=0;i<NCPU;i++)
    80000c46:	2985                	addiw	s3,s3,1
    80000c48:	02848493          	addi	s1,s1,40
    80000c4c:	fd499fe3          	bne	s3,s4,80000c2a <kalloc+0xc0>
    80000c50:	b749                	j	80000bd2 <kalloc+0x68>

0000000080000c52 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c52:	411c                	lw	a5,0(a0)
    80000c54:	e399                	bnez	a5,80000c5a <holding+0x8>
    80000c56:	4501                	li	a0,0
  return r;
}
    80000c58:	8082                	ret
{
    80000c5a:	1101                	addi	sp,sp,-32
    80000c5c:	ec06                	sd	ra,24(sp)
    80000c5e:	e822                	sd	s0,16(sp)
    80000c60:	e426                	sd	s1,8(sp)
    80000c62:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c64:	6904                	ld	s1,16(a0)
    80000c66:	00001097          	auipc	ra,0x1
    80000c6a:	090080e7          	jalr	144(ra) # 80001cf6 <mycpu>
    80000c6e:	40a48533          	sub	a0,s1,a0
    80000c72:	00153513          	seqz	a0,a0
}
    80000c76:	60e2                	ld	ra,24(sp)
    80000c78:	6442                	ld	s0,16(sp)
    80000c7a:	64a2                	ld	s1,8(sp)
    80000c7c:	6105                	addi	sp,sp,32
    80000c7e:	8082                	ret

0000000080000c80 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c80:	1101                	addi	sp,sp,-32
    80000c82:	ec06                	sd	ra,24(sp)
    80000c84:	e822                	sd	s0,16(sp)
    80000c86:	e426                	sd	s1,8(sp)
    80000c88:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c8a:	100024f3          	csrr	s1,sstatus
    80000c8e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c92:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c94:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c98:	00001097          	auipc	ra,0x1
    80000c9c:	05e080e7          	jalr	94(ra) # 80001cf6 <mycpu>
    80000ca0:	5d3c                	lw	a5,120(a0)
    80000ca2:	cf89                	beqz	a5,80000cbc <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000ca4:	00001097          	auipc	ra,0x1
    80000ca8:	052080e7          	jalr	82(ra) # 80001cf6 <mycpu>
    80000cac:	5d3c                	lw	a5,120(a0)
    80000cae:	2785                	addiw	a5,a5,1
    80000cb0:	dd3c                	sw	a5,120(a0)
}
    80000cb2:	60e2                	ld	ra,24(sp)
    80000cb4:	6442                	ld	s0,16(sp)
    80000cb6:	64a2                	ld	s1,8(sp)
    80000cb8:	6105                	addi	sp,sp,32
    80000cba:	8082                	ret
    mycpu()->intena = old;
    80000cbc:	00001097          	auipc	ra,0x1
    80000cc0:	03a080e7          	jalr	58(ra) # 80001cf6 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000cc4:	8085                	srli	s1,s1,0x1
    80000cc6:	8885                	andi	s1,s1,1
    80000cc8:	dd64                	sw	s1,124(a0)
    80000cca:	bfe9                	j	80000ca4 <push_off+0x24>

0000000080000ccc <acquire>:
{
    80000ccc:	1101                	addi	sp,sp,-32
    80000cce:	ec06                	sd	ra,24(sp)
    80000cd0:	e822                	sd	s0,16(sp)
    80000cd2:	e426                	sd	s1,8(sp)
    80000cd4:	1000                	addi	s0,sp,32
    80000cd6:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	fa8080e7          	jalr	-88(ra) # 80000c80 <push_off>
  if(holding(lk))
    80000ce0:	8526                	mv	a0,s1
    80000ce2:	00000097          	auipc	ra,0x0
    80000ce6:	f70080e7          	jalr	-144(ra) # 80000c52 <holding>
    80000cea:	e911                	bnez	a0,80000cfe <acquire+0x32>
    __sync_fetch_and_add(&(lk->n), 1);
    80000cec:	4785                	li	a5,1
    80000cee:	01c48713          	addi	a4,s1,28
    80000cf2:	0f50000f          	fence	iorw,ow
    80000cf6:	04f7202f          	amoadd.w.aq	zero,a5,(a4)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000cfa:	4705                	li	a4,1
    80000cfc:	a839                	j	80000d1a <acquire+0x4e>
    panic("acquire");
    80000cfe:	00007517          	auipc	a0,0x7
    80000d02:	37250513          	addi	a0,a0,882 # 80008070 <digits+0x30>
    80000d06:	00000097          	auipc	ra,0x0
    80000d0a:	844080e7          	jalr	-1980(ra) # 8000054a <panic>
    __sync_fetch_and_add(&(lk->nts), 1);
    80000d0e:	01848793          	addi	a5,s1,24
    80000d12:	0f50000f          	fence	iorw,ow
    80000d16:	04e7a02f          	amoadd.w.aq	zero,a4,(a5)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000d1a:	87ba                	mv	a5,a4
    80000d1c:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d20:	2781                	sext.w	a5,a5
    80000d22:	f7f5                	bnez	a5,80000d0e <acquire+0x42>
  __sync_synchronize();
    80000d24:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d28:	00001097          	auipc	ra,0x1
    80000d2c:	fce080e7          	jalr	-50(ra) # 80001cf6 <mycpu>
    80000d30:	e888                	sd	a0,16(s1)
}
    80000d32:	60e2                	ld	ra,24(sp)
    80000d34:	6442                	ld	s0,16(sp)
    80000d36:	64a2                	ld	s1,8(sp)
    80000d38:	6105                	addi	sp,sp,32
    80000d3a:	8082                	ret

0000000080000d3c <pop_off>:

void
pop_off(void)
{
    80000d3c:	1141                	addi	sp,sp,-16
    80000d3e:	e406                	sd	ra,8(sp)
    80000d40:	e022                	sd	s0,0(sp)
    80000d42:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d44:	00001097          	auipc	ra,0x1
    80000d48:	fb2080e7          	jalr	-78(ra) # 80001cf6 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d4c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d50:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d52:	e78d                	bnez	a5,80000d7c <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d54:	5d3c                	lw	a5,120(a0)
    80000d56:	02f05b63          	blez	a5,80000d8c <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d5a:	37fd                	addiw	a5,a5,-1
    80000d5c:	0007871b          	sext.w	a4,a5
    80000d60:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d62:	eb09                	bnez	a4,80000d74 <pop_off+0x38>
    80000d64:	5d7c                	lw	a5,124(a0)
    80000d66:	c799                	beqz	a5,80000d74 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d68:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d6c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d70:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d74:	60a2                	ld	ra,8(sp)
    80000d76:	6402                	ld	s0,0(sp)
    80000d78:	0141                	addi	sp,sp,16
    80000d7a:	8082                	ret
    panic("pop_off - interruptible");
    80000d7c:	00007517          	auipc	a0,0x7
    80000d80:	2fc50513          	addi	a0,a0,764 # 80008078 <digits+0x38>
    80000d84:	fffff097          	auipc	ra,0xfffff
    80000d88:	7c6080e7          	jalr	1990(ra) # 8000054a <panic>
    panic("pop_off");
    80000d8c:	00007517          	auipc	a0,0x7
    80000d90:	30450513          	addi	a0,a0,772 # 80008090 <digits+0x50>
    80000d94:	fffff097          	auipc	ra,0xfffff
    80000d98:	7b6080e7          	jalr	1974(ra) # 8000054a <panic>

0000000080000d9c <release>:
{
    80000d9c:	1101                	addi	sp,sp,-32
    80000d9e:	ec06                	sd	ra,24(sp)
    80000da0:	e822                	sd	s0,16(sp)
    80000da2:	e426                	sd	s1,8(sp)
    80000da4:	1000                	addi	s0,sp,32
    80000da6:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	eaa080e7          	jalr	-342(ra) # 80000c52 <holding>
    80000db0:	c115                	beqz	a0,80000dd4 <release+0x38>
  lk->cpu = 0;
    80000db2:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000db6:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000dba:	0f50000f          	fence	iorw,ow
    80000dbe:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000dc2:	00000097          	auipc	ra,0x0
    80000dc6:	f7a080e7          	jalr	-134(ra) # 80000d3c <pop_off>
}
    80000dca:	60e2                	ld	ra,24(sp)
    80000dcc:	6442                	ld	s0,16(sp)
    80000dce:	64a2                	ld	s1,8(sp)
    80000dd0:	6105                	addi	sp,sp,32
    80000dd2:	8082                	ret
    panic("release");
    80000dd4:	00007517          	auipc	a0,0x7
    80000dd8:	2c450513          	addi	a0,a0,708 # 80008098 <digits+0x58>
    80000ddc:	fffff097          	auipc	ra,0xfffff
    80000de0:	76e080e7          	jalr	1902(ra) # 8000054a <panic>

0000000080000de4 <freelock>:
{
    80000de4:	1101                	addi	sp,sp,-32
    80000de6:	ec06                	sd	ra,24(sp)
    80000de8:	e822                	sd	s0,16(sp)
    80000dea:	e426                	sd	s1,8(sp)
    80000dec:	1000                	addi	s0,sp,32
    80000dee:	84aa                	mv	s1,a0
  acquire(&lock_locks);
    80000df0:	00010517          	auipc	a0,0x10
    80000df4:	5d850513          	addi	a0,a0,1496 # 800113c8 <lock_locks>
    80000df8:	00000097          	auipc	ra,0x0
    80000dfc:	ed4080e7          	jalr	-300(ra) # 80000ccc <acquire>
  for (i = 0; i < NLOCK; i++) {
    80000e00:	00010717          	auipc	a4,0x10
    80000e04:	5e870713          	addi	a4,a4,1512 # 800113e8 <locks>
    80000e08:	4781                	li	a5,0
    80000e0a:	1f400613          	li	a2,500
    if(locks[i] == lk) {
    80000e0e:	6314                	ld	a3,0(a4)
    80000e10:	00968763          	beq	a3,s1,80000e1e <freelock+0x3a>
  for (i = 0; i < NLOCK; i++) {
    80000e14:	2785                	addiw	a5,a5,1
    80000e16:	0721                	addi	a4,a4,8
    80000e18:	fec79be3          	bne	a5,a2,80000e0e <freelock+0x2a>
    80000e1c:	a809                	j	80000e2e <freelock+0x4a>
      locks[i] = 0;
    80000e1e:	078e                	slli	a5,a5,0x3
    80000e20:	00010717          	auipc	a4,0x10
    80000e24:	5c870713          	addi	a4,a4,1480 # 800113e8 <locks>
    80000e28:	97ba                	add	a5,a5,a4
    80000e2a:	0007b023          	sd	zero,0(a5)
  release(&lock_locks);
    80000e2e:	00010517          	auipc	a0,0x10
    80000e32:	59a50513          	addi	a0,a0,1434 # 800113c8 <lock_locks>
    80000e36:	00000097          	auipc	ra,0x0
    80000e3a:	f66080e7          	jalr	-154(ra) # 80000d9c <release>
}
    80000e3e:	60e2                	ld	ra,24(sp)
    80000e40:	6442                	ld	s0,16(sp)
    80000e42:	64a2                	ld	s1,8(sp)
    80000e44:	6105                	addi	sp,sp,32
    80000e46:	8082                	ret

0000000080000e48 <initlock>:
{
    80000e48:	1101                	addi	sp,sp,-32
    80000e4a:	ec06                	sd	ra,24(sp)
    80000e4c:	e822                	sd	s0,16(sp)
    80000e4e:	e426                	sd	s1,8(sp)
    80000e50:	1000                	addi	s0,sp,32
    80000e52:	84aa                	mv	s1,a0
  lk->name = name;
    80000e54:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000e56:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000e5a:	00053823          	sd	zero,16(a0)
  lk->nts = 0;
    80000e5e:	00052c23          	sw	zero,24(a0)
  lk->n = 0;
    80000e62:	00052e23          	sw	zero,28(a0)
  acquire(&lock_locks);
    80000e66:	00010517          	auipc	a0,0x10
    80000e6a:	56250513          	addi	a0,a0,1378 # 800113c8 <lock_locks>
    80000e6e:	00000097          	auipc	ra,0x0
    80000e72:	e5e080e7          	jalr	-418(ra) # 80000ccc <acquire>
  for (i = 0; i < NLOCK; i++) {
    80000e76:	00010717          	auipc	a4,0x10
    80000e7a:	57270713          	addi	a4,a4,1394 # 800113e8 <locks>
    80000e7e:	4781                	li	a5,0
    80000e80:	1f400613          	li	a2,500
    if(locks[i] == 0) {
    80000e84:	6314                	ld	a3,0(a4)
    80000e86:	ce89                	beqz	a3,80000ea0 <initlock+0x58>
  for (i = 0; i < NLOCK; i++) {
    80000e88:	2785                	addiw	a5,a5,1
    80000e8a:	0721                	addi	a4,a4,8
    80000e8c:	fec79ce3          	bne	a5,a2,80000e84 <initlock+0x3c>
  panic("findslot");
    80000e90:	00007517          	auipc	a0,0x7
    80000e94:	21050513          	addi	a0,a0,528 # 800080a0 <digits+0x60>
    80000e98:	fffff097          	auipc	ra,0xfffff
    80000e9c:	6b2080e7          	jalr	1714(ra) # 8000054a <panic>
      locks[i] = lk;
    80000ea0:	078e                	slli	a5,a5,0x3
    80000ea2:	00010717          	auipc	a4,0x10
    80000ea6:	54670713          	addi	a4,a4,1350 # 800113e8 <locks>
    80000eaa:	97ba                	add	a5,a5,a4
    80000eac:	e384                	sd	s1,0(a5)
      release(&lock_locks);
    80000eae:	00010517          	auipc	a0,0x10
    80000eb2:	51a50513          	addi	a0,a0,1306 # 800113c8 <lock_locks>
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	ee6080e7          	jalr	-282(ra) # 80000d9c <release>
}
    80000ebe:	60e2                	ld	ra,24(sp)
    80000ec0:	6442                	ld	s0,16(sp)
    80000ec2:	64a2                	ld	s1,8(sp)
    80000ec4:	6105                	addi	sp,sp,32
    80000ec6:	8082                	ret

0000000080000ec8 <snprint_lock>:
#ifdef LAB_LOCK
int
snprint_lock(char *buf, int sz, struct spinlock *lk)
{
  int n = 0;
  if(lk->n > 0) {
    80000ec8:	4e5c                	lw	a5,28(a2)
    80000eca:	00f04463          	bgtz	a5,80000ed2 <snprint_lock+0xa>
  int n = 0;
    80000ece:	4501                	li	a0,0
    n = snprintf(buf, sz, "lock: %s: #fetch-and-add %d #acquire() %d\n",
                 lk->name, lk->nts, lk->n);
  }
  return n;
}
    80000ed0:	8082                	ret
{
    80000ed2:	1141                	addi	sp,sp,-16
    80000ed4:	e406                	sd	ra,8(sp)
    80000ed6:	e022                	sd	s0,0(sp)
    80000ed8:	0800                	addi	s0,sp,16
    n = snprintf(buf, sz, "lock: %s: #fetch-and-add %d #acquire() %d\n",
    80000eda:	4e18                	lw	a4,24(a2)
    80000edc:	6614                	ld	a3,8(a2)
    80000ede:	00007617          	auipc	a2,0x7
    80000ee2:	1d260613          	addi	a2,a2,466 # 800080b0 <digits+0x70>
    80000ee6:	00006097          	auipc	ra,0x6
    80000eea:	91e080e7          	jalr	-1762(ra) # 80006804 <snprintf>
}
    80000eee:	60a2                	ld	ra,8(sp)
    80000ef0:	6402                	ld	s0,0(sp)
    80000ef2:	0141                	addi	sp,sp,16
    80000ef4:	8082                	ret

0000000080000ef6 <statslock>:

int
statslock(char *buf, int sz) {
    80000ef6:	7159                	addi	sp,sp,-112
    80000ef8:	f486                	sd	ra,104(sp)
    80000efa:	f0a2                	sd	s0,96(sp)
    80000efc:	eca6                	sd	s1,88(sp)
    80000efe:	e8ca                	sd	s2,80(sp)
    80000f00:	e4ce                	sd	s3,72(sp)
    80000f02:	e0d2                	sd	s4,64(sp)
    80000f04:	fc56                	sd	s5,56(sp)
    80000f06:	f85a                	sd	s6,48(sp)
    80000f08:	f45e                	sd	s7,40(sp)
    80000f0a:	f062                	sd	s8,32(sp)
    80000f0c:	ec66                	sd	s9,24(sp)
    80000f0e:	e86a                	sd	s10,16(sp)
    80000f10:	e46e                	sd	s11,8(sp)
    80000f12:	1880                	addi	s0,sp,112
    80000f14:	8aaa                	mv	s5,a0
    80000f16:	8b2e                	mv	s6,a1
  int n;
  int tot = 0;

  acquire(&lock_locks);
    80000f18:	00010517          	auipc	a0,0x10
    80000f1c:	4b050513          	addi	a0,a0,1200 # 800113c8 <lock_locks>
    80000f20:	00000097          	auipc	ra,0x0
    80000f24:	dac080e7          	jalr	-596(ra) # 80000ccc <acquire>
  n = snprintf(buf, sz, "--- lock kmem/bcache stats\n");
    80000f28:	00007617          	auipc	a2,0x7
    80000f2c:	1b860613          	addi	a2,a2,440 # 800080e0 <digits+0xa0>
    80000f30:	85da                	mv	a1,s6
    80000f32:	8556                	mv	a0,s5
    80000f34:	00006097          	auipc	ra,0x6
    80000f38:	8d0080e7          	jalr	-1840(ra) # 80006804 <snprintf>
    80000f3c:	892a                	mv	s2,a0
  for(int i = 0; i < NLOCK; i++) {
    80000f3e:	00010c97          	auipc	s9,0x10
    80000f42:	4aac8c93          	addi	s9,s9,1194 # 800113e8 <locks>
    80000f46:	00011c17          	auipc	s8,0x11
    80000f4a:	442c0c13          	addi	s8,s8,1090 # 80012388 <pid_lock>
  n = snprintf(buf, sz, "--- lock kmem/bcache stats\n");
    80000f4e:	84e6                	mv	s1,s9
  int tot = 0;
    80000f50:	4a01                	li	s4,0
    if(locks[i] == 0)
      break;
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000f52:	00007b97          	auipc	s7,0x7
    80000f56:	1aeb8b93          	addi	s7,s7,430 # 80008100 <digits+0xc0>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80000f5a:	00007d17          	auipc	s10,0x7
    80000f5e:	10ed0d13          	addi	s10,s10,270 # 80008068 <digits+0x28>
    80000f62:	a01d                	j	80000f88 <statslock+0x92>
      tot += locks[i]->nts;
    80000f64:	0009b603          	ld	a2,0(s3)
    80000f68:	4e1c                	lw	a5,24(a2)
    80000f6a:	01478a3b          	addw	s4,a5,s4
      n += snprint_lock(buf +n, sz-n, locks[i]);
    80000f6e:	412b05bb          	subw	a1,s6,s2
    80000f72:	012a8533          	add	a0,s5,s2
    80000f76:	00000097          	auipc	ra,0x0
    80000f7a:	f52080e7          	jalr	-174(ra) # 80000ec8 <snprint_lock>
    80000f7e:	0125093b          	addw	s2,a0,s2
  for(int i = 0; i < NLOCK; i++) {
    80000f82:	04a1                	addi	s1,s1,8
    80000f84:	05848763          	beq	s1,s8,80000fd2 <statslock+0xdc>
    if(locks[i] == 0)
    80000f88:	89a6                	mv	s3,s1
    80000f8a:	609c                	ld	a5,0(s1)
    80000f8c:	c3b9                	beqz	a5,80000fd2 <statslock+0xdc>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000f8e:	0087bd83          	ld	s11,8(a5)
    80000f92:	855e                	mv	a0,s7
    80000f94:	00000097          	auipc	ra,0x0
    80000f98:	29c080e7          	jalr	668(ra) # 80001230 <strlen>
    80000f9c:	0005061b          	sext.w	a2,a0
    80000fa0:	85de                	mv	a1,s7
    80000fa2:	856e                	mv	a0,s11
    80000fa4:	00000097          	auipc	ra,0x0
    80000fa8:	1e0080e7          	jalr	480(ra) # 80001184 <strncmp>
    80000fac:	dd45                	beqz	a0,80000f64 <statslock+0x6e>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80000fae:	609c                	ld	a5,0(s1)
    80000fb0:	0087bd83          	ld	s11,8(a5)
    80000fb4:	856a                	mv	a0,s10
    80000fb6:	00000097          	auipc	ra,0x0
    80000fba:	27a080e7          	jalr	634(ra) # 80001230 <strlen>
    80000fbe:	0005061b          	sext.w	a2,a0
    80000fc2:	85ea                	mv	a1,s10
    80000fc4:	856e                	mv	a0,s11
    80000fc6:	00000097          	auipc	ra,0x0
    80000fca:	1be080e7          	jalr	446(ra) # 80001184 <strncmp>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000fce:	f955                	bnez	a0,80000f82 <statslock+0x8c>
    80000fd0:	bf51                	j	80000f64 <statslock+0x6e>
    }
  }
  
  n += snprintf(buf+n, sz-n, "--- top 5 contended locks:\n");
    80000fd2:	00007617          	auipc	a2,0x7
    80000fd6:	13660613          	addi	a2,a2,310 # 80008108 <digits+0xc8>
    80000fda:	412b05bb          	subw	a1,s6,s2
    80000fde:	012a8533          	add	a0,s5,s2
    80000fe2:	00006097          	auipc	ra,0x6
    80000fe6:	822080e7          	jalr	-2014(ra) # 80006804 <snprintf>
    80000fea:	012509bb          	addw	s3,a0,s2
    80000fee:	4b95                	li	s7,5
  int last = 100000000;
    80000ff0:	05f5e537          	lui	a0,0x5f5e
    80000ff4:	10050513          	addi	a0,a0,256 # 5f5e100 <_entry-0x7a0a1f00>
  // stupid way to compute top 5 contended locks
  for(int t = 0; t < 5; t++) {
    int top = 0;
    for(int i = 0; i < NLOCK; i++) {
    80000ff8:	4c01                	li	s8,0
      if(locks[i] == 0)
        break;
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    80000ffa:	00010497          	auipc	s1,0x10
    80000ffe:	3ee48493          	addi	s1,s1,1006 # 800113e8 <locks>
    for(int i = 0; i < NLOCK; i++) {
    80001002:	1f400913          	li	s2,500
    80001006:	a881                	j	80001056 <statslock+0x160>
    80001008:	2705                	addiw	a4,a4,1
    8000100a:	06a1                	addi	a3,a3,8
    8000100c:	03270063          	beq	a4,s2,8000102c <statslock+0x136>
      if(locks[i] == 0)
    80001010:	629c                	ld	a5,0(a3)
    80001012:	cf89                	beqz	a5,8000102c <statslock+0x136>
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    80001014:	4f90                	lw	a2,24(a5)
    80001016:	00359793          	slli	a5,a1,0x3
    8000101a:	97a6                	add	a5,a5,s1
    8000101c:	639c                	ld	a5,0(a5)
    8000101e:	4f9c                	lw	a5,24(a5)
    80001020:	fec7d4e3          	bge	a5,a2,80001008 <statslock+0x112>
    80001024:	fea652e3          	bge	a2,a0,80001008 <statslock+0x112>
    80001028:	85ba                	mv	a1,a4
    8000102a:	bff9                	j	80001008 <statslock+0x112>
        top = i;
      }
    }
    n += snprint_lock(buf+n, sz-n, locks[top]);
    8000102c:	058e                	slli	a1,a1,0x3
    8000102e:	00b48d33          	add	s10,s1,a1
    80001032:	000d3603          	ld	a2,0(s10)
    80001036:	413b05bb          	subw	a1,s6,s3
    8000103a:	013a8533          	add	a0,s5,s3
    8000103e:	00000097          	auipc	ra,0x0
    80001042:	e8a080e7          	jalr	-374(ra) # 80000ec8 <snprint_lock>
    80001046:	013509bb          	addw	s3,a0,s3
    last = locks[top]->nts;
    8000104a:	000d3783          	ld	a5,0(s10)
    8000104e:	4f88                	lw	a0,24(a5)
  for(int t = 0; t < 5; t++) {
    80001050:	3bfd                	addiw	s7,s7,-1
    80001052:	000b8663          	beqz	s7,8000105e <statslock+0x168>
  int tot = 0;
    80001056:	86e6                	mv	a3,s9
    for(int i = 0; i < NLOCK; i++) {
    80001058:	8762                	mv	a4,s8
    int top = 0;
    8000105a:	85e2                	mv	a1,s8
    8000105c:	bf55                	j	80001010 <statslock+0x11a>
  }
  n += snprintf(buf+n, sz-n, "tot= %d\n", tot);
    8000105e:	86d2                	mv	a3,s4
    80001060:	00007617          	auipc	a2,0x7
    80001064:	0c860613          	addi	a2,a2,200 # 80008128 <digits+0xe8>
    80001068:	413b05bb          	subw	a1,s6,s3
    8000106c:	013a8533          	add	a0,s5,s3
    80001070:	00005097          	auipc	ra,0x5
    80001074:	794080e7          	jalr	1940(ra) # 80006804 <snprintf>
    80001078:	013509bb          	addw	s3,a0,s3
  release(&lock_locks);  
    8000107c:	00010517          	auipc	a0,0x10
    80001080:	34c50513          	addi	a0,a0,844 # 800113c8 <lock_locks>
    80001084:	00000097          	auipc	ra,0x0
    80001088:	d18080e7          	jalr	-744(ra) # 80000d9c <release>
  return n;
}
    8000108c:	854e                	mv	a0,s3
    8000108e:	70a6                	ld	ra,104(sp)
    80001090:	7406                	ld	s0,96(sp)
    80001092:	64e6                	ld	s1,88(sp)
    80001094:	6946                	ld	s2,80(sp)
    80001096:	69a6                	ld	s3,72(sp)
    80001098:	6a06                	ld	s4,64(sp)
    8000109a:	7ae2                	ld	s5,56(sp)
    8000109c:	7b42                	ld	s6,48(sp)
    8000109e:	7ba2                	ld	s7,40(sp)
    800010a0:	7c02                	ld	s8,32(sp)
    800010a2:	6ce2                	ld	s9,24(sp)
    800010a4:	6d42                	ld	s10,16(sp)
    800010a6:	6da2                	ld	s11,8(sp)
    800010a8:	6165                	addi	sp,sp,112
    800010aa:	8082                	ret

00000000800010ac <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    800010ac:	1141                	addi	sp,sp,-16
    800010ae:	e422                	sd	s0,8(sp)
    800010b0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    800010b2:	ca19                	beqz	a2,800010c8 <memset+0x1c>
    800010b4:	87aa                	mv	a5,a0
    800010b6:	1602                	slli	a2,a2,0x20
    800010b8:	9201                	srli	a2,a2,0x20
    800010ba:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    800010be:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    800010c2:	0785                	addi	a5,a5,1
    800010c4:	fee79de3          	bne	a5,a4,800010be <memset+0x12>
  }
  return dst;
}
    800010c8:	6422                	ld	s0,8(sp)
    800010ca:	0141                	addi	sp,sp,16
    800010cc:	8082                	ret

00000000800010ce <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    800010ce:	1141                	addi	sp,sp,-16
    800010d0:	e422                	sd	s0,8(sp)
    800010d2:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    800010d4:	ca05                	beqz	a2,80001104 <memcmp+0x36>
    800010d6:	fff6069b          	addiw	a3,a2,-1
    800010da:	1682                	slli	a3,a3,0x20
    800010dc:	9281                	srli	a3,a3,0x20
    800010de:	0685                	addi	a3,a3,1
    800010e0:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    800010e2:	00054783          	lbu	a5,0(a0)
    800010e6:	0005c703          	lbu	a4,0(a1)
    800010ea:	00e79863          	bne	a5,a4,800010fa <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    800010ee:	0505                	addi	a0,a0,1
    800010f0:	0585                	addi	a1,a1,1
  while(n-- > 0){
    800010f2:	fed518e3          	bne	a0,a3,800010e2 <memcmp+0x14>
  }

  return 0;
    800010f6:	4501                	li	a0,0
    800010f8:	a019                	j	800010fe <memcmp+0x30>
      return *s1 - *s2;
    800010fa:	40e7853b          	subw	a0,a5,a4
}
    800010fe:	6422                	ld	s0,8(sp)
    80001100:	0141                	addi	sp,sp,16
    80001102:	8082                	ret
  return 0;
    80001104:	4501                	li	a0,0
    80001106:	bfe5                	j	800010fe <memcmp+0x30>

0000000080001108 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80001108:	1141                	addi	sp,sp,-16
    8000110a:	e422                	sd	s0,8(sp)
    8000110c:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    8000110e:	02a5e563          	bltu	a1,a0,80001138 <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80001112:	fff6069b          	addiw	a3,a2,-1
    80001116:	ce11                	beqz	a2,80001132 <memmove+0x2a>
    80001118:	1682                	slli	a3,a3,0x20
    8000111a:	9281                	srli	a3,a3,0x20
    8000111c:	0685                	addi	a3,a3,1
    8000111e:	96ae                	add	a3,a3,a1
    80001120:	87aa                	mv	a5,a0
      *d++ = *s++;
    80001122:	0585                	addi	a1,a1,1
    80001124:	0785                	addi	a5,a5,1
    80001126:	fff5c703          	lbu	a4,-1(a1)
    8000112a:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    8000112e:	fed59ae3          	bne	a1,a3,80001122 <memmove+0x1a>

  return dst;
}
    80001132:	6422                	ld	s0,8(sp)
    80001134:	0141                	addi	sp,sp,16
    80001136:	8082                	ret
  if(s < d && s + n > d){
    80001138:	02061713          	slli	a4,a2,0x20
    8000113c:	9301                	srli	a4,a4,0x20
    8000113e:	00e587b3          	add	a5,a1,a4
    80001142:	fcf578e3          	bgeu	a0,a5,80001112 <memmove+0xa>
    d += n;
    80001146:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80001148:	fff6069b          	addiw	a3,a2,-1
    8000114c:	d27d                	beqz	a2,80001132 <memmove+0x2a>
    8000114e:	02069613          	slli	a2,a3,0x20
    80001152:	9201                	srli	a2,a2,0x20
    80001154:	fff64613          	not	a2,a2
    80001158:	963e                	add	a2,a2,a5
      *--d = *--s;
    8000115a:	17fd                	addi	a5,a5,-1
    8000115c:	177d                	addi	a4,a4,-1
    8000115e:	0007c683          	lbu	a3,0(a5)
    80001162:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80001166:	fef61ae3          	bne	a2,a5,8000115a <memmove+0x52>
    8000116a:	b7e1                	j	80001132 <memmove+0x2a>

000000008000116c <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    8000116c:	1141                	addi	sp,sp,-16
    8000116e:	e406                	sd	ra,8(sp)
    80001170:	e022                	sd	s0,0(sp)
    80001172:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80001174:	00000097          	auipc	ra,0x0
    80001178:	f94080e7          	jalr	-108(ra) # 80001108 <memmove>
}
    8000117c:	60a2                	ld	ra,8(sp)
    8000117e:	6402                	ld	s0,0(sp)
    80001180:	0141                	addi	sp,sp,16
    80001182:	8082                	ret

0000000080001184 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80001184:	1141                	addi	sp,sp,-16
    80001186:	e422                	sd	s0,8(sp)
    80001188:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    8000118a:	ce11                	beqz	a2,800011a6 <strncmp+0x22>
    8000118c:	00054783          	lbu	a5,0(a0)
    80001190:	cf89                	beqz	a5,800011aa <strncmp+0x26>
    80001192:	0005c703          	lbu	a4,0(a1)
    80001196:	00f71a63          	bne	a4,a5,800011aa <strncmp+0x26>
    n--, p++, q++;
    8000119a:	367d                	addiw	a2,a2,-1
    8000119c:	0505                	addi	a0,a0,1
    8000119e:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    800011a0:	f675                	bnez	a2,8000118c <strncmp+0x8>
  if(n == 0)
    return 0;
    800011a2:	4501                	li	a0,0
    800011a4:	a809                	j	800011b6 <strncmp+0x32>
    800011a6:	4501                	li	a0,0
    800011a8:	a039                	j	800011b6 <strncmp+0x32>
  if(n == 0)
    800011aa:	ca09                	beqz	a2,800011bc <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    800011ac:	00054503          	lbu	a0,0(a0)
    800011b0:	0005c783          	lbu	a5,0(a1)
    800011b4:	9d1d                	subw	a0,a0,a5
}
    800011b6:	6422                	ld	s0,8(sp)
    800011b8:	0141                	addi	sp,sp,16
    800011ba:	8082                	ret
    return 0;
    800011bc:	4501                	li	a0,0
    800011be:	bfe5                	j	800011b6 <strncmp+0x32>

00000000800011c0 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    800011c0:	1141                	addi	sp,sp,-16
    800011c2:	e422                	sd	s0,8(sp)
    800011c4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    800011c6:	872a                	mv	a4,a0
    800011c8:	8832                	mv	a6,a2
    800011ca:	367d                	addiw	a2,a2,-1
    800011cc:	01005963          	blez	a6,800011de <strncpy+0x1e>
    800011d0:	0705                	addi	a4,a4,1
    800011d2:	0005c783          	lbu	a5,0(a1)
    800011d6:	fef70fa3          	sb	a5,-1(a4)
    800011da:	0585                	addi	a1,a1,1
    800011dc:	f7f5                	bnez	a5,800011c8 <strncpy+0x8>
    ;
  while(n-- > 0)
    800011de:	86ba                	mv	a3,a4
    800011e0:	00c05c63          	blez	a2,800011f8 <strncpy+0x38>
    *s++ = 0;
    800011e4:	0685                	addi	a3,a3,1
    800011e6:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    800011ea:	fff6c793          	not	a5,a3
    800011ee:	9fb9                	addw	a5,a5,a4
    800011f0:	010787bb          	addw	a5,a5,a6
    800011f4:	fef048e3          	bgtz	a5,800011e4 <strncpy+0x24>
  return os;
}
    800011f8:	6422                	ld	s0,8(sp)
    800011fa:	0141                	addi	sp,sp,16
    800011fc:	8082                	ret

00000000800011fe <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    800011fe:	1141                	addi	sp,sp,-16
    80001200:	e422                	sd	s0,8(sp)
    80001202:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80001204:	02c05363          	blez	a2,8000122a <safestrcpy+0x2c>
    80001208:	fff6069b          	addiw	a3,a2,-1
    8000120c:	1682                	slli	a3,a3,0x20
    8000120e:	9281                	srli	a3,a3,0x20
    80001210:	96ae                	add	a3,a3,a1
    80001212:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80001214:	00d58963          	beq	a1,a3,80001226 <safestrcpy+0x28>
    80001218:	0585                	addi	a1,a1,1
    8000121a:	0785                	addi	a5,a5,1
    8000121c:	fff5c703          	lbu	a4,-1(a1)
    80001220:	fee78fa3          	sb	a4,-1(a5)
    80001224:	fb65                	bnez	a4,80001214 <safestrcpy+0x16>
    ;
  *s = 0;
    80001226:	00078023          	sb	zero,0(a5)
  return os;
}
    8000122a:	6422                	ld	s0,8(sp)
    8000122c:	0141                	addi	sp,sp,16
    8000122e:	8082                	ret

0000000080001230 <strlen>:

int
strlen(const char *s)
{
    80001230:	1141                	addi	sp,sp,-16
    80001232:	e422                	sd	s0,8(sp)
    80001234:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80001236:	00054783          	lbu	a5,0(a0)
    8000123a:	cf91                	beqz	a5,80001256 <strlen+0x26>
    8000123c:	0505                	addi	a0,a0,1
    8000123e:	87aa                	mv	a5,a0
    80001240:	4685                	li	a3,1
    80001242:	9e89                	subw	a3,a3,a0
    80001244:	00f6853b          	addw	a0,a3,a5
    80001248:	0785                	addi	a5,a5,1
    8000124a:	fff7c703          	lbu	a4,-1(a5)
    8000124e:	fb7d                	bnez	a4,80001244 <strlen+0x14>
    ;
  return n;
}
    80001250:	6422                	ld	s0,8(sp)
    80001252:	0141                	addi	sp,sp,16
    80001254:	8082                	ret
  for(n = 0; s[n]; n++)
    80001256:	4501                	li	a0,0
    80001258:	bfe5                	j	80001250 <strlen+0x20>

000000008000125a <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    8000125a:	1141                	addi	sp,sp,-16
    8000125c:	e406                	sd	ra,8(sp)
    8000125e:	e022                	sd	s0,0(sp)
    80001260:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80001262:	00001097          	auipc	ra,0x1
    80001266:	a84080e7          	jalr	-1404(ra) # 80001ce6 <cpuid>
#endif    
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    8000126a:	00008717          	auipc	a4,0x8
    8000126e:	da270713          	addi	a4,a4,-606 # 8000900c <started>
  if(cpuid() == 0){
    80001272:	c139                	beqz	a0,800012b8 <main+0x5e>
    while(started == 0)
    80001274:	431c                	lw	a5,0(a4)
    80001276:	2781                	sext.w	a5,a5
    80001278:	dff5                	beqz	a5,80001274 <main+0x1a>
      ;
    __sync_synchronize();
    8000127a:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    8000127e:	00001097          	auipc	ra,0x1
    80001282:	a68080e7          	jalr	-1432(ra) # 80001ce6 <cpuid>
    80001286:	85aa                	mv	a1,a0
    80001288:	00007517          	auipc	a0,0x7
    8000128c:	ec850513          	addi	a0,a0,-312 # 80008150 <digits+0x110>
    80001290:	fffff097          	auipc	ra,0xfffff
    80001294:	304080e7          	jalr	772(ra) # 80000594 <printf>
    kvminithart();    // turn on paging
    80001298:	00000097          	auipc	ra,0x0
    8000129c:	186080e7          	jalr	390(ra) # 8000141e <kvminithart>
    trapinithart();   // install kernel trap vector
    800012a0:	00001097          	auipc	ra,0x1
    800012a4:	6cc080e7          	jalr	1740(ra) # 8000296c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    800012a8:	00005097          	auipc	ra,0x5
    800012ac:	de8080e7          	jalr	-536(ra) # 80006090 <plicinithart>
  }

  scheduler();        
    800012b0:	00001097          	auipc	ra,0x1
    800012b4:	f96080e7          	jalr	-106(ra) # 80002246 <scheduler>
    consoleinit();
    800012b8:	fffff097          	auipc	ra,0xfffff
    800012bc:	1a4080e7          	jalr	420(ra) # 8000045c <consoleinit>
    statsinit();
    800012c0:	00005097          	auipc	ra,0x5
    800012c4:	468080e7          	jalr	1128(ra) # 80006728 <statsinit>
    printfinit();
    800012c8:	fffff097          	auipc	ra,0xfffff
    800012cc:	4ac080e7          	jalr	1196(ra) # 80000774 <printfinit>
    printf("\n");
    800012d0:	00007517          	auipc	a0,0x7
    800012d4:	e9050513          	addi	a0,a0,-368 # 80008160 <digits+0x120>
    800012d8:	fffff097          	auipc	ra,0xfffff
    800012dc:	2bc080e7          	jalr	700(ra) # 80000594 <printf>
    printf("xv6 kernel is booting\n");
    800012e0:	00007517          	auipc	a0,0x7
    800012e4:	e5850513          	addi	a0,a0,-424 # 80008138 <digits+0xf8>
    800012e8:	fffff097          	auipc	ra,0xfffff
    800012ec:	2ac080e7          	jalr	684(ra) # 80000594 <printf>
    printf("\n");
    800012f0:	00007517          	auipc	a0,0x7
    800012f4:	e7050513          	addi	a0,a0,-400 # 80008160 <digits+0x120>
    800012f8:	fffff097          	auipc	ra,0xfffff
    800012fc:	29c080e7          	jalr	668(ra) # 80000594 <printf>
    kinit();         // physical page allocator
    80001300:	00000097          	auipc	ra,0x0
    80001304:	80e080e7          	jalr	-2034(ra) # 80000b0e <kinit>
    kvminit();       // create kernel page table
    80001308:	00000097          	auipc	ra,0x0
    8000130c:	242080e7          	jalr	578(ra) # 8000154a <kvminit>
    kvminithart();   // turn on paging
    80001310:	00000097          	auipc	ra,0x0
    80001314:	10e080e7          	jalr	270(ra) # 8000141e <kvminithart>
    procinit();      // process table
    80001318:	00001097          	auipc	ra,0x1
    8000131c:	8fe080e7          	jalr	-1794(ra) # 80001c16 <procinit>
    trapinit();      // trap vectors
    80001320:	00001097          	auipc	ra,0x1
    80001324:	624080e7          	jalr	1572(ra) # 80002944 <trapinit>
    trapinithart();  // install kernel trap vector
    80001328:	00001097          	auipc	ra,0x1
    8000132c:	644080e7          	jalr	1604(ra) # 8000296c <trapinithart>
    plicinit();      // set up interrupt controller
    80001330:	00005097          	auipc	ra,0x5
    80001334:	d4a080e7          	jalr	-694(ra) # 8000607a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001338:	00005097          	auipc	ra,0x5
    8000133c:	d58080e7          	jalr	-680(ra) # 80006090 <plicinithart>
    binit();         // buffer cache
    80001340:	00002097          	auipc	ra,0x2
    80001344:	d6c080e7          	jalr	-660(ra) # 800030ac <binit>
    iinit();         // inode cache
    80001348:	00002097          	auipc	ra,0x2
    8000134c:	57a080e7          	jalr	1402(ra) # 800038c2 <iinit>
    fileinit();      // file table
    80001350:	00003097          	auipc	ra,0x3
    80001354:	52a080e7          	jalr	1322(ra) # 8000487a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001358:	00005097          	auipc	ra,0x5
    8000135c:	e5a080e7          	jalr	-422(ra) # 800061b2 <virtio_disk_init>
    userinit();      // first user process
    80001360:	00001097          	auipc	ra,0x1
    80001364:	c7c080e7          	jalr	-900(ra) # 80001fdc <userinit>
    __sync_synchronize();
    80001368:	0ff0000f          	fence
    started = 1;
    8000136c:	4785                	li	a5,1
    8000136e:	00008717          	auipc	a4,0x8
    80001372:	c8f72f23          	sw	a5,-866(a4) # 8000900c <started>
    80001376:	bf2d                	j	800012b0 <main+0x56>

0000000080001378 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
static pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001378:	7139                	addi	sp,sp,-64
    8000137a:	fc06                	sd	ra,56(sp)
    8000137c:	f822                	sd	s0,48(sp)
    8000137e:	f426                	sd	s1,40(sp)
    80001380:	f04a                	sd	s2,32(sp)
    80001382:	ec4e                	sd	s3,24(sp)
    80001384:	e852                	sd	s4,16(sp)
    80001386:	e456                	sd	s5,8(sp)
    80001388:	e05a                	sd	s6,0(sp)
    8000138a:	0080                	addi	s0,sp,64
    8000138c:	84aa                	mv	s1,a0
    8000138e:	89ae                	mv	s3,a1
    80001390:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001392:	57fd                	li	a5,-1
    80001394:	83e9                	srli	a5,a5,0x1a
    80001396:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001398:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000139a:	04b7f263          	bgeu	a5,a1,800013de <walk+0x66>
    panic("walk");
    8000139e:	00007517          	auipc	a0,0x7
    800013a2:	dca50513          	addi	a0,a0,-566 # 80008168 <digits+0x128>
    800013a6:	fffff097          	auipc	ra,0xfffff
    800013aa:	1a4080e7          	jalr	420(ra) # 8000054a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800013ae:	060a8663          	beqz	s5,8000141a <walk+0xa2>
    800013b2:	fffff097          	auipc	ra,0xfffff
    800013b6:	7b8080e7          	jalr	1976(ra) # 80000b6a <kalloc>
    800013ba:	84aa                	mv	s1,a0
    800013bc:	c529                	beqz	a0,80001406 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800013be:	6605                	lui	a2,0x1
    800013c0:	4581                	li	a1,0
    800013c2:	00000097          	auipc	ra,0x0
    800013c6:	cea080e7          	jalr	-790(ra) # 800010ac <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800013ca:	00c4d793          	srli	a5,s1,0xc
    800013ce:	07aa                	slli	a5,a5,0xa
    800013d0:	0017e793          	ori	a5,a5,1
    800013d4:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800013d8:	3a5d                	addiw	s4,s4,-9
    800013da:	036a0063          	beq	s4,s6,800013fa <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800013de:	0149d933          	srl	s2,s3,s4
    800013e2:	1ff97913          	andi	s2,s2,511
    800013e6:	090e                	slli	s2,s2,0x3
    800013e8:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800013ea:	00093483          	ld	s1,0(s2)
    800013ee:	0014f793          	andi	a5,s1,1
    800013f2:	dfd5                	beqz	a5,800013ae <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800013f4:	80a9                	srli	s1,s1,0xa
    800013f6:	04b2                	slli	s1,s1,0xc
    800013f8:	b7c5                	j	800013d8 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800013fa:	00c9d513          	srli	a0,s3,0xc
    800013fe:	1ff57513          	andi	a0,a0,511
    80001402:	050e                	slli	a0,a0,0x3
    80001404:	9526                	add	a0,a0,s1
}
    80001406:	70e2                	ld	ra,56(sp)
    80001408:	7442                	ld	s0,48(sp)
    8000140a:	74a2                	ld	s1,40(sp)
    8000140c:	7902                	ld	s2,32(sp)
    8000140e:	69e2                	ld	s3,24(sp)
    80001410:	6a42                	ld	s4,16(sp)
    80001412:	6aa2                	ld	s5,8(sp)
    80001414:	6b02                	ld	s6,0(sp)
    80001416:	6121                	addi	sp,sp,64
    80001418:	8082                	ret
        return 0;
    8000141a:	4501                	li	a0,0
    8000141c:	b7ed                	j	80001406 <walk+0x8e>

000000008000141e <kvminithart>:
{
    8000141e:	1141                	addi	sp,sp,-16
    80001420:	e422                	sd	s0,8(sp)
    80001422:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001424:	00008797          	auipc	a5,0x8
    80001428:	bec7b783          	ld	a5,-1044(a5) # 80009010 <kernel_pagetable>
    8000142c:	83b1                	srli	a5,a5,0xc
    8000142e:	577d                	li	a4,-1
    80001430:	177e                	slli	a4,a4,0x3f
    80001432:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001434:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001438:	12000073          	sfence.vma
}
    8000143c:	6422                	ld	s0,8(sp)
    8000143e:	0141                	addi	sp,sp,16
    80001440:	8082                	ret

0000000080001442 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001442:	57fd                	li	a5,-1
    80001444:	83e9                	srli	a5,a5,0x1a
    80001446:	00b7f463          	bgeu	a5,a1,8000144e <walkaddr+0xc>
    return 0;
    8000144a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000144c:	8082                	ret
{
    8000144e:	1141                	addi	sp,sp,-16
    80001450:	e406                	sd	ra,8(sp)
    80001452:	e022                	sd	s0,0(sp)
    80001454:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001456:	4601                	li	a2,0
    80001458:	00000097          	auipc	ra,0x0
    8000145c:	f20080e7          	jalr	-224(ra) # 80001378 <walk>
  if(pte == 0)
    80001460:	c105                	beqz	a0,80001480 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001462:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001464:	0117f693          	andi	a3,a5,17
    80001468:	4745                	li	a4,17
    return 0;
    8000146a:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000146c:	00e68663          	beq	a3,a4,80001478 <walkaddr+0x36>
}
    80001470:	60a2                	ld	ra,8(sp)
    80001472:	6402                	ld	s0,0(sp)
    80001474:	0141                	addi	sp,sp,16
    80001476:	8082                	ret
  pa = PTE2PA(*pte);
    80001478:	00a7d513          	srli	a0,a5,0xa
    8000147c:	0532                	slli	a0,a0,0xc
  return pa;
    8000147e:	bfcd                	j	80001470 <walkaddr+0x2e>
    return 0;
    80001480:	4501                	li	a0,0
    80001482:	b7fd                	j	80001470 <walkaddr+0x2e>

0000000080001484 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001484:	715d                	addi	sp,sp,-80
    80001486:	e486                	sd	ra,72(sp)
    80001488:	e0a2                	sd	s0,64(sp)
    8000148a:	fc26                	sd	s1,56(sp)
    8000148c:	f84a                	sd	s2,48(sp)
    8000148e:	f44e                	sd	s3,40(sp)
    80001490:	f052                	sd	s4,32(sp)
    80001492:	ec56                	sd	s5,24(sp)
    80001494:	e85a                	sd	s6,16(sp)
    80001496:	e45e                	sd	s7,8(sp)
    80001498:	0880                	addi	s0,sp,80
    8000149a:	8aaa                	mv	s5,a0
    8000149c:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    8000149e:	777d                	lui	a4,0xfffff
    800014a0:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800014a4:	167d                	addi	a2,a2,-1
    800014a6:	00b609b3          	add	s3,a2,a1
    800014aa:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800014ae:	893e                	mv	s2,a5
    800014b0:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800014b4:	6b85                	lui	s7,0x1
    800014b6:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800014ba:	4605                	li	a2,1
    800014bc:	85ca                	mv	a1,s2
    800014be:	8556                	mv	a0,s5
    800014c0:	00000097          	auipc	ra,0x0
    800014c4:	eb8080e7          	jalr	-328(ra) # 80001378 <walk>
    800014c8:	c51d                	beqz	a0,800014f6 <mappages+0x72>
    if(*pte & PTE_V)
    800014ca:	611c                	ld	a5,0(a0)
    800014cc:	8b85                	andi	a5,a5,1
    800014ce:	ef81                	bnez	a5,800014e6 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800014d0:	80b1                	srli	s1,s1,0xc
    800014d2:	04aa                	slli	s1,s1,0xa
    800014d4:	0164e4b3          	or	s1,s1,s6
    800014d8:	0014e493          	ori	s1,s1,1
    800014dc:	e104                	sd	s1,0(a0)
    if(a == last)
    800014de:	03390863          	beq	s2,s3,8000150e <mappages+0x8a>
    a += PGSIZE;
    800014e2:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800014e4:	bfc9                	j	800014b6 <mappages+0x32>
      panic("remap");
    800014e6:	00007517          	auipc	a0,0x7
    800014ea:	c8a50513          	addi	a0,a0,-886 # 80008170 <digits+0x130>
    800014ee:	fffff097          	auipc	ra,0xfffff
    800014f2:	05c080e7          	jalr	92(ra) # 8000054a <panic>
      return -1;
    800014f6:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800014f8:	60a6                	ld	ra,72(sp)
    800014fa:	6406                	ld	s0,64(sp)
    800014fc:	74e2                	ld	s1,56(sp)
    800014fe:	7942                	ld	s2,48(sp)
    80001500:	79a2                	ld	s3,40(sp)
    80001502:	7a02                	ld	s4,32(sp)
    80001504:	6ae2                	ld	s5,24(sp)
    80001506:	6b42                	ld	s6,16(sp)
    80001508:	6ba2                	ld	s7,8(sp)
    8000150a:	6161                	addi	sp,sp,80
    8000150c:	8082                	ret
  return 0;
    8000150e:	4501                	li	a0,0
    80001510:	b7e5                	j	800014f8 <mappages+0x74>

0000000080001512 <kvmmap>:
{
    80001512:	1141                	addi	sp,sp,-16
    80001514:	e406                	sd	ra,8(sp)
    80001516:	e022                	sd	s0,0(sp)
    80001518:	0800                	addi	s0,sp,16
    8000151a:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    8000151c:	86ae                	mv	a3,a1
    8000151e:	85aa                	mv	a1,a0
    80001520:	00008517          	auipc	a0,0x8
    80001524:	af053503          	ld	a0,-1296(a0) # 80009010 <kernel_pagetable>
    80001528:	00000097          	auipc	ra,0x0
    8000152c:	f5c080e7          	jalr	-164(ra) # 80001484 <mappages>
    80001530:	e509                	bnez	a0,8000153a <kvmmap+0x28>
}
    80001532:	60a2                	ld	ra,8(sp)
    80001534:	6402                	ld	s0,0(sp)
    80001536:	0141                	addi	sp,sp,16
    80001538:	8082                	ret
    panic("kvmmap");
    8000153a:	00007517          	auipc	a0,0x7
    8000153e:	c3e50513          	addi	a0,a0,-962 # 80008178 <digits+0x138>
    80001542:	fffff097          	auipc	ra,0xfffff
    80001546:	008080e7          	jalr	8(ra) # 8000054a <panic>

000000008000154a <kvminit>:
{
    8000154a:	1101                	addi	sp,sp,-32
    8000154c:	ec06                	sd	ra,24(sp)
    8000154e:	e822                	sd	s0,16(sp)
    80001550:	e426                	sd	s1,8(sp)
    80001552:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001554:	fffff097          	auipc	ra,0xfffff
    80001558:	616080e7          	jalr	1558(ra) # 80000b6a <kalloc>
    8000155c:	00008797          	auipc	a5,0x8
    80001560:	aaa7ba23          	sd	a0,-1356(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001564:	6605                	lui	a2,0x1
    80001566:	4581                	li	a1,0
    80001568:	00000097          	auipc	ra,0x0
    8000156c:	b44080e7          	jalr	-1212(ra) # 800010ac <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001570:	4699                	li	a3,6
    80001572:	6605                	lui	a2,0x1
    80001574:	100005b7          	lui	a1,0x10000
    80001578:	10000537          	lui	a0,0x10000
    8000157c:	00000097          	auipc	ra,0x0
    80001580:	f96080e7          	jalr	-106(ra) # 80001512 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001584:	4699                	li	a3,6
    80001586:	6605                	lui	a2,0x1
    80001588:	100015b7          	lui	a1,0x10001
    8000158c:	10001537          	lui	a0,0x10001
    80001590:	00000097          	auipc	ra,0x0
    80001594:	f82080e7          	jalr	-126(ra) # 80001512 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001598:	4699                	li	a3,6
    8000159a:	00400637          	lui	a2,0x400
    8000159e:	0c0005b7          	lui	a1,0xc000
    800015a2:	0c000537          	lui	a0,0xc000
    800015a6:	00000097          	auipc	ra,0x0
    800015aa:	f6c080e7          	jalr	-148(ra) # 80001512 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800015ae:	00007497          	auipc	s1,0x7
    800015b2:	a5248493          	addi	s1,s1,-1454 # 80008000 <etext>
    800015b6:	46a9                	li	a3,10
    800015b8:	80007617          	auipc	a2,0x80007
    800015bc:	a4860613          	addi	a2,a2,-1464 # 8000 <_entry-0x7fff8000>
    800015c0:	4585                	li	a1,1
    800015c2:	05fe                	slli	a1,a1,0x1f
    800015c4:	852e                	mv	a0,a1
    800015c6:	00000097          	auipc	ra,0x0
    800015ca:	f4c080e7          	jalr	-180(ra) # 80001512 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800015ce:	4699                	li	a3,6
    800015d0:	4645                	li	a2,17
    800015d2:	066e                	slli	a2,a2,0x1b
    800015d4:	8e05                	sub	a2,a2,s1
    800015d6:	85a6                	mv	a1,s1
    800015d8:	8526                	mv	a0,s1
    800015da:	00000097          	auipc	ra,0x0
    800015de:	f38080e7          	jalr	-200(ra) # 80001512 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800015e2:	46a9                	li	a3,10
    800015e4:	6605                	lui	a2,0x1
    800015e6:	00006597          	auipc	a1,0x6
    800015ea:	a1a58593          	addi	a1,a1,-1510 # 80007000 <_trampoline>
    800015ee:	04000537          	lui	a0,0x4000
    800015f2:	157d                	addi	a0,a0,-1
    800015f4:	0532                	slli	a0,a0,0xc
    800015f6:	00000097          	auipc	ra,0x0
    800015fa:	f1c080e7          	jalr	-228(ra) # 80001512 <kvmmap>
}
    800015fe:	60e2                	ld	ra,24(sp)
    80001600:	6442                	ld	s0,16(sp)
    80001602:	64a2                	ld	s1,8(sp)
    80001604:	6105                	addi	sp,sp,32
    80001606:	8082                	ret

0000000080001608 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001608:	715d                	addi	sp,sp,-80
    8000160a:	e486                	sd	ra,72(sp)
    8000160c:	e0a2                	sd	s0,64(sp)
    8000160e:	fc26                	sd	s1,56(sp)
    80001610:	f84a                	sd	s2,48(sp)
    80001612:	f44e                	sd	s3,40(sp)
    80001614:	f052                	sd	s4,32(sp)
    80001616:	ec56                	sd	s5,24(sp)
    80001618:	e85a                	sd	s6,16(sp)
    8000161a:	e45e                	sd	s7,8(sp)
    8000161c:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000161e:	03459793          	slli	a5,a1,0x34
    80001622:	e795                	bnez	a5,8000164e <uvmunmap+0x46>
    80001624:	8a2a                	mv	s4,a0
    80001626:	892e                	mv	s2,a1
    80001628:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000162a:	0632                	slli	a2,a2,0xc
    8000162c:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001630:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001632:	6b05                	lui	s6,0x1
    80001634:	0735e263          	bltu	a1,s3,80001698 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001638:	60a6                	ld	ra,72(sp)
    8000163a:	6406                	ld	s0,64(sp)
    8000163c:	74e2                	ld	s1,56(sp)
    8000163e:	7942                	ld	s2,48(sp)
    80001640:	79a2                	ld	s3,40(sp)
    80001642:	7a02                	ld	s4,32(sp)
    80001644:	6ae2                	ld	s5,24(sp)
    80001646:	6b42                	ld	s6,16(sp)
    80001648:	6ba2                	ld	s7,8(sp)
    8000164a:	6161                	addi	sp,sp,80
    8000164c:	8082                	ret
    panic("uvmunmap: not aligned");
    8000164e:	00007517          	auipc	a0,0x7
    80001652:	b3250513          	addi	a0,a0,-1230 # 80008180 <digits+0x140>
    80001656:	fffff097          	auipc	ra,0xfffff
    8000165a:	ef4080e7          	jalr	-268(ra) # 8000054a <panic>
      panic("uvmunmap: walk");
    8000165e:	00007517          	auipc	a0,0x7
    80001662:	b3a50513          	addi	a0,a0,-1222 # 80008198 <digits+0x158>
    80001666:	fffff097          	auipc	ra,0xfffff
    8000166a:	ee4080e7          	jalr	-284(ra) # 8000054a <panic>
      panic("uvmunmap: not mapped");
    8000166e:	00007517          	auipc	a0,0x7
    80001672:	b3a50513          	addi	a0,a0,-1222 # 800081a8 <digits+0x168>
    80001676:	fffff097          	auipc	ra,0xfffff
    8000167a:	ed4080e7          	jalr	-300(ra) # 8000054a <panic>
      panic("uvmunmap: not a leaf");
    8000167e:	00007517          	auipc	a0,0x7
    80001682:	b4250513          	addi	a0,a0,-1214 # 800081c0 <digits+0x180>
    80001686:	fffff097          	auipc	ra,0xfffff
    8000168a:	ec4080e7          	jalr	-316(ra) # 8000054a <panic>
    *pte = 0;
    8000168e:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001692:	995a                	add	s2,s2,s6
    80001694:	fb3972e3          	bgeu	s2,s3,80001638 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001698:	4601                	li	a2,0
    8000169a:	85ca                	mv	a1,s2
    8000169c:	8552                	mv	a0,s4
    8000169e:	00000097          	auipc	ra,0x0
    800016a2:	cda080e7          	jalr	-806(ra) # 80001378 <walk>
    800016a6:	84aa                	mv	s1,a0
    800016a8:	d95d                	beqz	a0,8000165e <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800016aa:	6108                	ld	a0,0(a0)
    800016ac:	00157793          	andi	a5,a0,1
    800016b0:	dfdd                	beqz	a5,8000166e <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800016b2:	3ff57793          	andi	a5,a0,1023
    800016b6:	fd7784e3          	beq	a5,s7,8000167e <uvmunmap+0x76>
    if(do_free){
    800016ba:	fc0a8ae3          	beqz	s5,8000168e <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800016be:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800016c0:	0532                	slli	a0,a0,0xc
    800016c2:	fffff097          	auipc	ra,0xfffff
    800016c6:	358080e7          	jalr	856(ra) # 80000a1a <kfree>
    800016ca:	b7d1                	j	8000168e <uvmunmap+0x86>

00000000800016cc <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800016cc:	1101                	addi	sp,sp,-32
    800016ce:	ec06                	sd	ra,24(sp)
    800016d0:	e822                	sd	s0,16(sp)
    800016d2:	e426                	sd	s1,8(sp)
    800016d4:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800016d6:	fffff097          	auipc	ra,0xfffff
    800016da:	494080e7          	jalr	1172(ra) # 80000b6a <kalloc>
    800016de:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800016e0:	c519                	beqz	a0,800016ee <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800016e2:	6605                	lui	a2,0x1
    800016e4:	4581                	li	a1,0
    800016e6:	00000097          	auipc	ra,0x0
    800016ea:	9c6080e7          	jalr	-1594(ra) # 800010ac <memset>
  return pagetable;
}
    800016ee:	8526                	mv	a0,s1
    800016f0:	60e2                	ld	ra,24(sp)
    800016f2:	6442                	ld	s0,16(sp)
    800016f4:	64a2                	ld	s1,8(sp)
    800016f6:	6105                	addi	sp,sp,32
    800016f8:	8082                	ret

00000000800016fa <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800016fa:	7179                	addi	sp,sp,-48
    800016fc:	f406                	sd	ra,40(sp)
    800016fe:	f022                	sd	s0,32(sp)
    80001700:	ec26                	sd	s1,24(sp)
    80001702:	e84a                	sd	s2,16(sp)
    80001704:	e44e                	sd	s3,8(sp)
    80001706:	e052                	sd	s4,0(sp)
    80001708:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000170a:	6785                	lui	a5,0x1
    8000170c:	04f67863          	bgeu	a2,a5,8000175c <uvminit+0x62>
    80001710:	8a2a                	mv	s4,a0
    80001712:	89ae                	mv	s3,a1
    80001714:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001716:	fffff097          	auipc	ra,0xfffff
    8000171a:	454080e7          	jalr	1108(ra) # 80000b6a <kalloc>
    8000171e:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001720:	6605                	lui	a2,0x1
    80001722:	4581                	li	a1,0
    80001724:	00000097          	auipc	ra,0x0
    80001728:	988080e7          	jalr	-1656(ra) # 800010ac <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000172c:	4779                	li	a4,30
    8000172e:	86ca                	mv	a3,s2
    80001730:	6605                	lui	a2,0x1
    80001732:	4581                	li	a1,0
    80001734:	8552                	mv	a0,s4
    80001736:	00000097          	auipc	ra,0x0
    8000173a:	d4e080e7          	jalr	-690(ra) # 80001484 <mappages>
  memmove(mem, src, sz);
    8000173e:	8626                	mv	a2,s1
    80001740:	85ce                	mv	a1,s3
    80001742:	854a                	mv	a0,s2
    80001744:	00000097          	auipc	ra,0x0
    80001748:	9c4080e7          	jalr	-1596(ra) # 80001108 <memmove>
}
    8000174c:	70a2                	ld	ra,40(sp)
    8000174e:	7402                	ld	s0,32(sp)
    80001750:	64e2                	ld	s1,24(sp)
    80001752:	6942                	ld	s2,16(sp)
    80001754:	69a2                	ld	s3,8(sp)
    80001756:	6a02                	ld	s4,0(sp)
    80001758:	6145                	addi	sp,sp,48
    8000175a:	8082                	ret
    panic("inituvm: more than a page");
    8000175c:	00007517          	auipc	a0,0x7
    80001760:	a7c50513          	addi	a0,a0,-1412 # 800081d8 <digits+0x198>
    80001764:	fffff097          	auipc	ra,0xfffff
    80001768:	de6080e7          	jalr	-538(ra) # 8000054a <panic>

000000008000176c <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000176c:	1101                	addi	sp,sp,-32
    8000176e:	ec06                	sd	ra,24(sp)
    80001770:	e822                	sd	s0,16(sp)
    80001772:	e426                	sd	s1,8(sp)
    80001774:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001776:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001778:	00b67d63          	bgeu	a2,a1,80001792 <uvmdealloc+0x26>
    8000177c:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000177e:	6785                	lui	a5,0x1
    80001780:	17fd                	addi	a5,a5,-1
    80001782:	00f60733          	add	a4,a2,a5
    80001786:	767d                	lui	a2,0xfffff
    80001788:	8f71                	and	a4,a4,a2
    8000178a:	97ae                	add	a5,a5,a1
    8000178c:	8ff1                	and	a5,a5,a2
    8000178e:	00f76863          	bltu	a4,a5,8000179e <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001792:	8526                	mv	a0,s1
    80001794:	60e2                	ld	ra,24(sp)
    80001796:	6442                	ld	s0,16(sp)
    80001798:	64a2                	ld	s1,8(sp)
    8000179a:	6105                	addi	sp,sp,32
    8000179c:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000179e:	8f99                	sub	a5,a5,a4
    800017a0:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800017a2:	4685                	li	a3,1
    800017a4:	0007861b          	sext.w	a2,a5
    800017a8:	85ba                	mv	a1,a4
    800017aa:	00000097          	auipc	ra,0x0
    800017ae:	e5e080e7          	jalr	-418(ra) # 80001608 <uvmunmap>
    800017b2:	b7c5                	j	80001792 <uvmdealloc+0x26>

00000000800017b4 <uvmalloc>:
  if(newsz < oldsz)
    800017b4:	0ab66163          	bltu	a2,a1,80001856 <uvmalloc+0xa2>
{
    800017b8:	7139                	addi	sp,sp,-64
    800017ba:	fc06                	sd	ra,56(sp)
    800017bc:	f822                	sd	s0,48(sp)
    800017be:	f426                	sd	s1,40(sp)
    800017c0:	f04a                	sd	s2,32(sp)
    800017c2:	ec4e                	sd	s3,24(sp)
    800017c4:	e852                	sd	s4,16(sp)
    800017c6:	e456                	sd	s5,8(sp)
    800017c8:	0080                	addi	s0,sp,64
    800017ca:	8aaa                	mv	s5,a0
    800017cc:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800017ce:	6985                	lui	s3,0x1
    800017d0:	19fd                	addi	s3,s3,-1
    800017d2:	95ce                	add	a1,a1,s3
    800017d4:	79fd                	lui	s3,0xfffff
    800017d6:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800017da:	08c9f063          	bgeu	s3,a2,8000185a <uvmalloc+0xa6>
    800017de:	894e                	mv	s2,s3
    mem = kalloc();
    800017e0:	fffff097          	auipc	ra,0xfffff
    800017e4:	38a080e7          	jalr	906(ra) # 80000b6a <kalloc>
    800017e8:	84aa                	mv	s1,a0
    if(mem == 0){
    800017ea:	c51d                	beqz	a0,80001818 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800017ec:	6605                	lui	a2,0x1
    800017ee:	4581                	li	a1,0
    800017f0:	00000097          	auipc	ra,0x0
    800017f4:	8bc080e7          	jalr	-1860(ra) # 800010ac <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800017f8:	4779                	li	a4,30
    800017fa:	86a6                	mv	a3,s1
    800017fc:	6605                	lui	a2,0x1
    800017fe:	85ca                	mv	a1,s2
    80001800:	8556                	mv	a0,s5
    80001802:	00000097          	auipc	ra,0x0
    80001806:	c82080e7          	jalr	-894(ra) # 80001484 <mappages>
    8000180a:	e905                	bnez	a0,8000183a <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000180c:	6785                	lui	a5,0x1
    8000180e:	993e                	add	s2,s2,a5
    80001810:	fd4968e3          	bltu	s2,s4,800017e0 <uvmalloc+0x2c>
  return newsz;
    80001814:	8552                	mv	a0,s4
    80001816:	a809                	j	80001828 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001818:	864e                	mv	a2,s3
    8000181a:	85ca                	mv	a1,s2
    8000181c:	8556                	mv	a0,s5
    8000181e:	00000097          	auipc	ra,0x0
    80001822:	f4e080e7          	jalr	-178(ra) # 8000176c <uvmdealloc>
      return 0;
    80001826:	4501                	li	a0,0
}
    80001828:	70e2                	ld	ra,56(sp)
    8000182a:	7442                	ld	s0,48(sp)
    8000182c:	74a2                	ld	s1,40(sp)
    8000182e:	7902                	ld	s2,32(sp)
    80001830:	69e2                	ld	s3,24(sp)
    80001832:	6a42                	ld	s4,16(sp)
    80001834:	6aa2                	ld	s5,8(sp)
    80001836:	6121                	addi	sp,sp,64
    80001838:	8082                	ret
      kfree(mem);
    8000183a:	8526                	mv	a0,s1
    8000183c:	fffff097          	auipc	ra,0xfffff
    80001840:	1de080e7          	jalr	478(ra) # 80000a1a <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001844:	864e                	mv	a2,s3
    80001846:	85ca                	mv	a1,s2
    80001848:	8556                	mv	a0,s5
    8000184a:	00000097          	auipc	ra,0x0
    8000184e:	f22080e7          	jalr	-222(ra) # 8000176c <uvmdealloc>
      return 0;
    80001852:	4501                	li	a0,0
    80001854:	bfd1                	j	80001828 <uvmalloc+0x74>
    return oldsz;
    80001856:	852e                	mv	a0,a1
}
    80001858:	8082                	ret
  return newsz;
    8000185a:	8532                	mv	a0,a2
    8000185c:	b7f1                	j	80001828 <uvmalloc+0x74>

000000008000185e <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000185e:	7179                	addi	sp,sp,-48
    80001860:	f406                	sd	ra,40(sp)
    80001862:	f022                	sd	s0,32(sp)
    80001864:	ec26                	sd	s1,24(sp)
    80001866:	e84a                	sd	s2,16(sp)
    80001868:	e44e                	sd	s3,8(sp)
    8000186a:	e052                	sd	s4,0(sp)
    8000186c:	1800                	addi	s0,sp,48
    8000186e:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001870:	84aa                	mv	s1,a0
    80001872:	6905                	lui	s2,0x1
    80001874:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001876:	4985                	li	s3,1
    80001878:	a821                	j	80001890 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000187a:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000187c:	0532                	slli	a0,a0,0xc
    8000187e:	00000097          	auipc	ra,0x0
    80001882:	fe0080e7          	jalr	-32(ra) # 8000185e <freewalk>
      pagetable[i] = 0;
    80001886:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000188a:	04a1                	addi	s1,s1,8
    8000188c:	03248163          	beq	s1,s2,800018ae <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001890:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001892:	00f57793          	andi	a5,a0,15
    80001896:	ff3782e3          	beq	a5,s3,8000187a <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000189a:	8905                	andi	a0,a0,1
    8000189c:	d57d                	beqz	a0,8000188a <freewalk+0x2c>
      panic("freewalk: leaf");
    8000189e:	00007517          	auipc	a0,0x7
    800018a2:	95a50513          	addi	a0,a0,-1702 # 800081f8 <digits+0x1b8>
    800018a6:	fffff097          	auipc	ra,0xfffff
    800018aa:	ca4080e7          	jalr	-860(ra) # 8000054a <panic>
    }
  }
  kfree((void*)pagetable);
    800018ae:	8552                	mv	a0,s4
    800018b0:	fffff097          	auipc	ra,0xfffff
    800018b4:	16a080e7          	jalr	362(ra) # 80000a1a <kfree>
}
    800018b8:	70a2                	ld	ra,40(sp)
    800018ba:	7402                	ld	s0,32(sp)
    800018bc:	64e2                	ld	s1,24(sp)
    800018be:	6942                	ld	s2,16(sp)
    800018c0:	69a2                	ld	s3,8(sp)
    800018c2:	6a02                	ld	s4,0(sp)
    800018c4:	6145                	addi	sp,sp,48
    800018c6:	8082                	ret

00000000800018c8 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800018c8:	1101                	addi	sp,sp,-32
    800018ca:	ec06                	sd	ra,24(sp)
    800018cc:	e822                	sd	s0,16(sp)
    800018ce:	e426                	sd	s1,8(sp)
    800018d0:	1000                	addi	s0,sp,32
    800018d2:	84aa                	mv	s1,a0
  if(sz > 0)
    800018d4:	e999                	bnez	a1,800018ea <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800018d6:	8526                	mv	a0,s1
    800018d8:	00000097          	auipc	ra,0x0
    800018dc:	f86080e7          	jalr	-122(ra) # 8000185e <freewalk>
}
    800018e0:	60e2                	ld	ra,24(sp)
    800018e2:	6442                	ld	s0,16(sp)
    800018e4:	64a2                	ld	s1,8(sp)
    800018e6:	6105                	addi	sp,sp,32
    800018e8:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800018ea:	6605                	lui	a2,0x1
    800018ec:	167d                	addi	a2,a2,-1
    800018ee:	962e                	add	a2,a2,a1
    800018f0:	4685                	li	a3,1
    800018f2:	8231                	srli	a2,a2,0xc
    800018f4:	4581                	li	a1,0
    800018f6:	00000097          	auipc	ra,0x0
    800018fa:	d12080e7          	jalr	-750(ra) # 80001608 <uvmunmap>
    800018fe:	bfe1                	j	800018d6 <uvmfree+0xe>

0000000080001900 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001900:	c679                	beqz	a2,800019ce <uvmcopy+0xce>
{
    80001902:	715d                	addi	sp,sp,-80
    80001904:	e486                	sd	ra,72(sp)
    80001906:	e0a2                	sd	s0,64(sp)
    80001908:	fc26                	sd	s1,56(sp)
    8000190a:	f84a                	sd	s2,48(sp)
    8000190c:	f44e                	sd	s3,40(sp)
    8000190e:	f052                	sd	s4,32(sp)
    80001910:	ec56                	sd	s5,24(sp)
    80001912:	e85a                	sd	s6,16(sp)
    80001914:	e45e                	sd	s7,8(sp)
    80001916:	0880                	addi	s0,sp,80
    80001918:	8b2a                	mv	s6,a0
    8000191a:	8aae                	mv	s5,a1
    8000191c:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000191e:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001920:	4601                	li	a2,0
    80001922:	85ce                	mv	a1,s3
    80001924:	855a                	mv	a0,s6
    80001926:	00000097          	auipc	ra,0x0
    8000192a:	a52080e7          	jalr	-1454(ra) # 80001378 <walk>
    8000192e:	c531                	beqz	a0,8000197a <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001930:	6118                	ld	a4,0(a0)
    80001932:	00177793          	andi	a5,a4,1
    80001936:	cbb1                	beqz	a5,8000198a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001938:	00a75593          	srli	a1,a4,0xa
    8000193c:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001940:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001944:	fffff097          	auipc	ra,0xfffff
    80001948:	226080e7          	jalr	550(ra) # 80000b6a <kalloc>
    8000194c:	892a                	mv	s2,a0
    8000194e:	c939                	beqz	a0,800019a4 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001950:	6605                	lui	a2,0x1
    80001952:	85de                	mv	a1,s7
    80001954:	fffff097          	auipc	ra,0xfffff
    80001958:	7b4080e7          	jalr	1972(ra) # 80001108 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000195c:	8726                	mv	a4,s1
    8000195e:	86ca                	mv	a3,s2
    80001960:	6605                	lui	a2,0x1
    80001962:	85ce                	mv	a1,s3
    80001964:	8556                	mv	a0,s5
    80001966:	00000097          	auipc	ra,0x0
    8000196a:	b1e080e7          	jalr	-1250(ra) # 80001484 <mappages>
    8000196e:	e515                	bnez	a0,8000199a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001970:	6785                	lui	a5,0x1
    80001972:	99be                	add	s3,s3,a5
    80001974:	fb49e6e3          	bltu	s3,s4,80001920 <uvmcopy+0x20>
    80001978:	a081                	j	800019b8 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000197a:	00007517          	auipc	a0,0x7
    8000197e:	88e50513          	addi	a0,a0,-1906 # 80008208 <digits+0x1c8>
    80001982:	fffff097          	auipc	ra,0xfffff
    80001986:	bc8080e7          	jalr	-1080(ra) # 8000054a <panic>
      panic("uvmcopy: page not present");
    8000198a:	00007517          	auipc	a0,0x7
    8000198e:	89e50513          	addi	a0,a0,-1890 # 80008228 <digits+0x1e8>
    80001992:	fffff097          	auipc	ra,0xfffff
    80001996:	bb8080e7          	jalr	-1096(ra) # 8000054a <panic>
      kfree(mem);
    8000199a:	854a                	mv	a0,s2
    8000199c:	fffff097          	auipc	ra,0xfffff
    800019a0:	07e080e7          	jalr	126(ra) # 80000a1a <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800019a4:	4685                	li	a3,1
    800019a6:	00c9d613          	srli	a2,s3,0xc
    800019aa:	4581                	li	a1,0
    800019ac:	8556                	mv	a0,s5
    800019ae:	00000097          	auipc	ra,0x0
    800019b2:	c5a080e7          	jalr	-934(ra) # 80001608 <uvmunmap>
  return -1;
    800019b6:	557d                	li	a0,-1
}
    800019b8:	60a6                	ld	ra,72(sp)
    800019ba:	6406                	ld	s0,64(sp)
    800019bc:	74e2                	ld	s1,56(sp)
    800019be:	7942                	ld	s2,48(sp)
    800019c0:	79a2                	ld	s3,40(sp)
    800019c2:	7a02                	ld	s4,32(sp)
    800019c4:	6ae2                	ld	s5,24(sp)
    800019c6:	6b42                	ld	s6,16(sp)
    800019c8:	6ba2                	ld	s7,8(sp)
    800019ca:	6161                	addi	sp,sp,80
    800019cc:	8082                	ret
  return 0;
    800019ce:	4501                	li	a0,0
}
    800019d0:	8082                	ret

00000000800019d2 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800019d2:	1141                	addi	sp,sp,-16
    800019d4:	e406                	sd	ra,8(sp)
    800019d6:	e022                	sd	s0,0(sp)
    800019d8:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800019da:	4601                	li	a2,0
    800019dc:	00000097          	auipc	ra,0x0
    800019e0:	99c080e7          	jalr	-1636(ra) # 80001378 <walk>
  if(pte == 0)
    800019e4:	c901                	beqz	a0,800019f4 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800019e6:	611c                	ld	a5,0(a0)
    800019e8:	9bbd                	andi	a5,a5,-17
    800019ea:	e11c                	sd	a5,0(a0)
}
    800019ec:	60a2                	ld	ra,8(sp)
    800019ee:	6402                	ld	s0,0(sp)
    800019f0:	0141                	addi	sp,sp,16
    800019f2:	8082                	ret
    panic("uvmclear");
    800019f4:	00007517          	auipc	a0,0x7
    800019f8:	85450513          	addi	a0,a0,-1964 # 80008248 <digits+0x208>
    800019fc:	fffff097          	auipc	ra,0xfffff
    80001a00:	b4e080e7          	jalr	-1202(ra) # 8000054a <panic>

0000000080001a04 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001a04:	c6bd                	beqz	a3,80001a72 <copyout+0x6e>
{
    80001a06:	715d                	addi	sp,sp,-80
    80001a08:	e486                	sd	ra,72(sp)
    80001a0a:	e0a2                	sd	s0,64(sp)
    80001a0c:	fc26                	sd	s1,56(sp)
    80001a0e:	f84a                	sd	s2,48(sp)
    80001a10:	f44e                	sd	s3,40(sp)
    80001a12:	f052                	sd	s4,32(sp)
    80001a14:	ec56                	sd	s5,24(sp)
    80001a16:	e85a                	sd	s6,16(sp)
    80001a18:	e45e                	sd	s7,8(sp)
    80001a1a:	e062                	sd	s8,0(sp)
    80001a1c:	0880                	addi	s0,sp,80
    80001a1e:	8b2a                	mv	s6,a0
    80001a20:	8c2e                	mv	s8,a1
    80001a22:	8a32                	mv	s4,a2
    80001a24:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001a26:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001a28:	6a85                	lui	s5,0x1
    80001a2a:	a015                	j	80001a4e <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001a2c:	9562                	add	a0,a0,s8
    80001a2e:	0004861b          	sext.w	a2,s1
    80001a32:	85d2                	mv	a1,s4
    80001a34:	41250533          	sub	a0,a0,s2
    80001a38:	fffff097          	auipc	ra,0xfffff
    80001a3c:	6d0080e7          	jalr	1744(ra) # 80001108 <memmove>

    len -= n;
    80001a40:	409989b3          	sub	s3,s3,s1
    src += n;
    80001a44:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001a46:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001a4a:	02098263          	beqz	s3,80001a6e <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001a4e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001a52:	85ca                	mv	a1,s2
    80001a54:	855a                	mv	a0,s6
    80001a56:	00000097          	auipc	ra,0x0
    80001a5a:	9ec080e7          	jalr	-1556(ra) # 80001442 <walkaddr>
    if(pa0 == 0)
    80001a5e:	cd01                	beqz	a0,80001a76 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001a60:	418904b3          	sub	s1,s2,s8
    80001a64:	94d6                	add	s1,s1,s5
    if(n > len)
    80001a66:	fc99f3e3          	bgeu	s3,s1,80001a2c <copyout+0x28>
    80001a6a:	84ce                	mv	s1,s3
    80001a6c:	b7c1                	j	80001a2c <copyout+0x28>
  }
  return 0;
    80001a6e:	4501                	li	a0,0
    80001a70:	a021                	j	80001a78 <copyout+0x74>
    80001a72:	4501                	li	a0,0
}
    80001a74:	8082                	ret
      return -1;
    80001a76:	557d                	li	a0,-1
}
    80001a78:	60a6                	ld	ra,72(sp)
    80001a7a:	6406                	ld	s0,64(sp)
    80001a7c:	74e2                	ld	s1,56(sp)
    80001a7e:	7942                	ld	s2,48(sp)
    80001a80:	79a2                	ld	s3,40(sp)
    80001a82:	7a02                	ld	s4,32(sp)
    80001a84:	6ae2                	ld	s5,24(sp)
    80001a86:	6b42                	ld	s6,16(sp)
    80001a88:	6ba2                	ld	s7,8(sp)
    80001a8a:	6c02                	ld	s8,0(sp)
    80001a8c:	6161                	addi	sp,sp,80
    80001a8e:	8082                	ret

0000000080001a90 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001a90:	caa5                	beqz	a3,80001b00 <copyin+0x70>
{
    80001a92:	715d                	addi	sp,sp,-80
    80001a94:	e486                	sd	ra,72(sp)
    80001a96:	e0a2                	sd	s0,64(sp)
    80001a98:	fc26                	sd	s1,56(sp)
    80001a9a:	f84a                	sd	s2,48(sp)
    80001a9c:	f44e                	sd	s3,40(sp)
    80001a9e:	f052                	sd	s4,32(sp)
    80001aa0:	ec56                	sd	s5,24(sp)
    80001aa2:	e85a                	sd	s6,16(sp)
    80001aa4:	e45e                	sd	s7,8(sp)
    80001aa6:	e062                	sd	s8,0(sp)
    80001aa8:	0880                	addi	s0,sp,80
    80001aaa:	8b2a                	mv	s6,a0
    80001aac:	8a2e                	mv	s4,a1
    80001aae:	8c32                	mv	s8,a2
    80001ab0:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001ab2:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001ab4:	6a85                	lui	s5,0x1
    80001ab6:	a01d                	j	80001adc <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001ab8:	018505b3          	add	a1,a0,s8
    80001abc:	0004861b          	sext.w	a2,s1
    80001ac0:	412585b3          	sub	a1,a1,s2
    80001ac4:	8552                	mv	a0,s4
    80001ac6:	fffff097          	auipc	ra,0xfffff
    80001aca:	642080e7          	jalr	1602(ra) # 80001108 <memmove>

    len -= n;
    80001ace:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001ad2:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001ad4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001ad8:	02098263          	beqz	s3,80001afc <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001adc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001ae0:	85ca                	mv	a1,s2
    80001ae2:	855a                	mv	a0,s6
    80001ae4:	00000097          	auipc	ra,0x0
    80001ae8:	95e080e7          	jalr	-1698(ra) # 80001442 <walkaddr>
    if(pa0 == 0)
    80001aec:	cd01                	beqz	a0,80001b04 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001aee:	418904b3          	sub	s1,s2,s8
    80001af2:	94d6                	add	s1,s1,s5
    if(n > len)
    80001af4:	fc99f2e3          	bgeu	s3,s1,80001ab8 <copyin+0x28>
    80001af8:	84ce                	mv	s1,s3
    80001afa:	bf7d                	j	80001ab8 <copyin+0x28>
  }
  return 0;
    80001afc:	4501                	li	a0,0
    80001afe:	a021                	j	80001b06 <copyin+0x76>
    80001b00:	4501                	li	a0,0
}
    80001b02:	8082                	ret
      return -1;
    80001b04:	557d                	li	a0,-1
}
    80001b06:	60a6                	ld	ra,72(sp)
    80001b08:	6406                	ld	s0,64(sp)
    80001b0a:	74e2                	ld	s1,56(sp)
    80001b0c:	7942                	ld	s2,48(sp)
    80001b0e:	79a2                	ld	s3,40(sp)
    80001b10:	7a02                	ld	s4,32(sp)
    80001b12:	6ae2                	ld	s5,24(sp)
    80001b14:	6b42                	ld	s6,16(sp)
    80001b16:	6ba2                	ld	s7,8(sp)
    80001b18:	6c02                	ld	s8,0(sp)
    80001b1a:	6161                	addi	sp,sp,80
    80001b1c:	8082                	ret

0000000080001b1e <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001b1e:	c6c5                	beqz	a3,80001bc6 <copyinstr+0xa8>
{
    80001b20:	715d                	addi	sp,sp,-80
    80001b22:	e486                	sd	ra,72(sp)
    80001b24:	e0a2                	sd	s0,64(sp)
    80001b26:	fc26                	sd	s1,56(sp)
    80001b28:	f84a                	sd	s2,48(sp)
    80001b2a:	f44e                	sd	s3,40(sp)
    80001b2c:	f052                	sd	s4,32(sp)
    80001b2e:	ec56                	sd	s5,24(sp)
    80001b30:	e85a                	sd	s6,16(sp)
    80001b32:	e45e                	sd	s7,8(sp)
    80001b34:	0880                	addi	s0,sp,80
    80001b36:	8a2a                	mv	s4,a0
    80001b38:	8b2e                	mv	s6,a1
    80001b3a:	8bb2                	mv	s7,a2
    80001b3c:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001b3e:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001b40:	6985                	lui	s3,0x1
    80001b42:	a035                	j	80001b6e <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001b44:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001b48:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001b4a:	0017b793          	seqz	a5,a5
    80001b4e:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001b52:	60a6                	ld	ra,72(sp)
    80001b54:	6406                	ld	s0,64(sp)
    80001b56:	74e2                	ld	s1,56(sp)
    80001b58:	7942                	ld	s2,48(sp)
    80001b5a:	79a2                	ld	s3,40(sp)
    80001b5c:	7a02                	ld	s4,32(sp)
    80001b5e:	6ae2                	ld	s5,24(sp)
    80001b60:	6b42                	ld	s6,16(sp)
    80001b62:	6ba2                	ld	s7,8(sp)
    80001b64:	6161                	addi	sp,sp,80
    80001b66:	8082                	ret
    srcva = va0 + PGSIZE;
    80001b68:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001b6c:	c8a9                	beqz	s1,80001bbe <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001b6e:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001b72:	85ca                	mv	a1,s2
    80001b74:	8552                	mv	a0,s4
    80001b76:	00000097          	auipc	ra,0x0
    80001b7a:	8cc080e7          	jalr	-1844(ra) # 80001442 <walkaddr>
    if(pa0 == 0)
    80001b7e:	c131                	beqz	a0,80001bc2 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001b80:	41790833          	sub	a6,s2,s7
    80001b84:	984e                	add	a6,a6,s3
    if(n > max)
    80001b86:	0104f363          	bgeu	s1,a6,80001b8c <copyinstr+0x6e>
    80001b8a:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001b8c:	955e                	add	a0,a0,s7
    80001b8e:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001b92:	fc080be3          	beqz	a6,80001b68 <copyinstr+0x4a>
    80001b96:	985a                	add	a6,a6,s6
    80001b98:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001b9a:	41650633          	sub	a2,a0,s6
    80001b9e:	14fd                	addi	s1,s1,-1
    80001ba0:	9b26                	add	s6,s6,s1
    80001ba2:	00f60733          	add	a4,a2,a5
    80001ba6:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd3fd8>
    80001baa:	df49                	beqz	a4,80001b44 <copyinstr+0x26>
        *dst = *p;
    80001bac:	00e78023          	sb	a4,0(a5)
      --max;
    80001bb0:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001bb4:	0785                	addi	a5,a5,1
    while(n > 0){
    80001bb6:	ff0796e3          	bne	a5,a6,80001ba2 <copyinstr+0x84>
      dst++;
    80001bba:	8b42                	mv	s6,a6
    80001bbc:	b775                	j	80001b68 <copyinstr+0x4a>
    80001bbe:	4781                	li	a5,0
    80001bc0:	b769                	j	80001b4a <copyinstr+0x2c>
      return -1;
    80001bc2:	557d                	li	a0,-1
    80001bc4:	b779                	j	80001b52 <copyinstr+0x34>
  int got_null = 0;
    80001bc6:	4781                	li	a5,0
  if(got_null){
    80001bc8:	0017b793          	seqz	a5,a5
    80001bcc:	40f00533          	neg	a0,a5
}
    80001bd0:	8082                	ret

0000000080001bd2 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001bd2:	1101                	addi	sp,sp,-32
    80001bd4:	ec06                	sd	ra,24(sp)
    80001bd6:	e822                	sd	s0,16(sp)
    80001bd8:	e426                	sd	s1,8(sp)
    80001bda:	1000                	addi	s0,sp,32
    80001bdc:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001bde:	fffff097          	auipc	ra,0xfffff
    80001be2:	074080e7          	jalr	116(ra) # 80000c52 <holding>
    80001be6:	c909                	beqz	a0,80001bf8 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001be8:	789c                	ld	a5,48(s1)
    80001bea:	00978f63          	beq	a5,s1,80001c08 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001bee:	60e2                	ld	ra,24(sp)
    80001bf0:	6442                	ld	s0,16(sp)
    80001bf2:	64a2                	ld	s1,8(sp)
    80001bf4:	6105                	addi	sp,sp,32
    80001bf6:	8082                	ret
    panic("wakeup1");
    80001bf8:	00006517          	auipc	a0,0x6
    80001bfc:	66050513          	addi	a0,a0,1632 # 80008258 <digits+0x218>
    80001c00:	fffff097          	auipc	ra,0xfffff
    80001c04:	94a080e7          	jalr	-1718(ra) # 8000054a <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001c08:	5098                	lw	a4,32(s1)
    80001c0a:	4785                	li	a5,1
    80001c0c:	fef711e3          	bne	a4,a5,80001bee <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001c10:	4789                	li	a5,2
    80001c12:	d09c                	sw	a5,32(s1)
}
    80001c14:	bfe9                	j	80001bee <wakeup1+0x1c>

0000000080001c16 <procinit>:
{
    80001c16:	715d                	addi	sp,sp,-80
    80001c18:	e486                	sd	ra,72(sp)
    80001c1a:	e0a2                	sd	s0,64(sp)
    80001c1c:	fc26                	sd	s1,56(sp)
    80001c1e:	f84a                	sd	s2,48(sp)
    80001c20:	f44e                	sd	s3,40(sp)
    80001c22:	f052                	sd	s4,32(sp)
    80001c24:	ec56                	sd	s5,24(sp)
    80001c26:	e85a                	sd	s6,16(sp)
    80001c28:	e45e                	sd	s7,8(sp)
    80001c2a:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001c2c:	00006597          	auipc	a1,0x6
    80001c30:	63458593          	addi	a1,a1,1588 # 80008260 <digits+0x220>
    80001c34:	00010517          	auipc	a0,0x10
    80001c38:	75450513          	addi	a0,a0,1876 # 80012388 <pid_lock>
    80001c3c:	fffff097          	auipc	ra,0xfffff
    80001c40:	20c080e7          	jalr	524(ra) # 80000e48 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c44:	00011917          	auipc	s2,0x11
    80001c48:	b6490913          	addi	s2,s2,-1180 # 800127a8 <proc>
      initlock(&p->lock, "proc");
    80001c4c:	00006b97          	auipc	s7,0x6
    80001c50:	61cb8b93          	addi	s7,s7,1564 # 80008268 <digits+0x228>
      uint64 va = KSTACK((int) (p - proc));
    80001c54:	8b4a                	mv	s6,s2
    80001c56:	00006a97          	auipc	s5,0x6
    80001c5a:	3aaa8a93          	addi	s5,s5,938 # 80008000 <etext>
    80001c5e:	040009b7          	lui	s3,0x4000
    80001c62:	19fd                	addi	s3,s3,-1
    80001c64:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c66:	00016a17          	auipc	s4,0x16
    80001c6a:	742a0a13          	addi	s4,s4,1858 # 800183a8 <tickslock>
      initlock(&p->lock, "proc");
    80001c6e:	85de                	mv	a1,s7
    80001c70:	854a                	mv	a0,s2
    80001c72:	fffff097          	auipc	ra,0xfffff
    80001c76:	1d6080e7          	jalr	470(ra) # 80000e48 <initlock>
      char *pa = kalloc();
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	ef0080e7          	jalr	-272(ra) # 80000b6a <kalloc>
    80001c82:	85aa                	mv	a1,a0
      if(pa == 0)
    80001c84:	c929                	beqz	a0,80001cd6 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001c86:	416904b3          	sub	s1,s2,s6
    80001c8a:	8491                	srai	s1,s1,0x4
    80001c8c:	000ab783          	ld	a5,0(s5)
    80001c90:	02f484b3          	mul	s1,s1,a5
    80001c94:	2485                	addiw	s1,s1,1
    80001c96:	00d4949b          	slliw	s1,s1,0xd
    80001c9a:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001c9e:	4699                	li	a3,6
    80001ca0:	6605                	lui	a2,0x1
    80001ca2:	8526                	mv	a0,s1
    80001ca4:	00000097          	auipc	ra,0x0
    80001ca8:	86e080e7          	jalr	-1938(ra) # 80001512 <kvmmap>
      p->kstack = va;
    80001cac:	04993423          	sd	s1,72(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cb0:	17090913          	addi	s2,s2,368
    80001cb4:	fb491de3          	bne	s2,s4,80001c6e <procinit+0x58>
  kvminithart();
    80001cb8:	fffff097          	auipc	ra,0xfffff
    80001cbc:	766080e7          	jalr	1894(ra) # 8000141e <kvminithart>
}
    80001cc0:	60a6                	ld	ra,72(sp)
    80001cc2:	6406                	ld	s0,64(sp)
    80001cc4:	74e2                	ld	s1,56(sp)
    80001cc6:	7942                	ld	s2,48(sp)
    80001cc8:	79a2                	ld	s3,40(sp)
    80001cca:	7a02                	ld	s4,32(sp)
    80001ccc:	6ae2                	ld	s5,24(sp)
    80001cce:	6b42                	ld	s6,16(sp)
    80001cd0:	6ba2                	ld	s7,8(sp)
    80001cd2:	6161                	addi	sp,sp,80
    80001cd4:	8082                	ret
        panic("kalloc");
    80001cd6:	00006517          	auipc	a0,0x6
    80001cda:	59a50513          	addi	a0,a0,1434 # 80008270 <digits+0x230>
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	86c080e7          	jalr	-1940(ra) # 8000054a <panic>

0000000080001ce6 <cpuid>:
{
    80001ce6:	1141                	addi	sp,sp,-16
    80001ce8:	e422                	sd	s0,8(sp)
    80001cea:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001cec:	8512                	mv	a0,tp
}
    80001cee:	2501                	sext.w	a0,a0
    80001cf0:	6422                	ld	s0,8(sp)
    80001cf2:	0141                	addi	sp,sp,16
    80001cf4:	8082                	ret

0000000080001cf6 <mycpu>:
mycpu(void) {
    80001cf6:	1141                	addi	sp,sp,-16
    80001cf8:	e422                	sd	s0,8(sp)
    80001cfa:	0800                	addi	s0,sp,16
    80001cfc:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001cfe:	2781                	sext.w	a5,a5
    80001d00:	079e                	slli	a5,a5,0x7
}
    80001d02:	00010517          	auipc	a0,0x10
    80001d06:	6a650513          	addi	a0,a0,1702 # 800123a8 <cpus>
    80001d0a:	953e                	add	a0,a0,a5
    80001d0c:	6422                	ld	s0,8(sp)
    80001d0e:	0141                	addi	sp,sp,16
    80001d10:	8082                	ret

0000000080001d12 <myproc>:
myproc(void) {
    80001d12:	1101                	addi	sp,sp,-32
    80001d14:	ec06                	sd	ra,24(sp)
    80001d16:	e822                	sd	s0,16(sp)
    80001d18:	e426                	sd	s1,8(sp)
    80001d1a:	1000                	addi	s0,sp,32
  push_off();
    80001d1c:	fffff097          	auipc	ra,0xfffff
    80001d20:	f64080e7          	jalr	-156(ra) # 80000c80 <push_off>
    80001d24:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001d26:	2781                	sext.w	a5,a5
    80001d28:	079e                	slli	a5,a5,0x7
    80001d2a:	00010717          	auipc	a4,0x10
    80001d2e:	65e70713          	addi	a4,a4,1630 # 80012388 <pid_lock>
    80001d32:	97ba                	add	a5,a5,a4
    80001d34:	7384                	ld	s1,32(a5)
  pop_off();
    80001d36:	fffff097          	auipc	ra,0xfffff
    80001d3a:	006080e7          	jalr	6(ra) # 80000d3c <pop_off>
}
    80001d3e:	8526                	mv	a0,s1
    80001d40:	60e2                	ld	ra,24(sp)
    80001d42:	6442                	ld	s0,16(sp)
    80001d44:	64a2                	ld	s1,8(sp)
    80001d46:	6105                	addi	sp,sp,32
    80001d48:	8082                	ret

0000000080001d4a <forkret>:
{
    80001d4a:	1141                	addi	sp,sp,-16
    80001d4c:	e406                	sd	ra,8(sp)
    80001d4e:	e022                	sd	s0,0(sp)
    80001d50:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001d52:	00000097          	auipc	ra,0x0
    80001d56:	fc0080e7          	jalr	-64(ra) # 80001d12 <myproc>
    80001d5a:	fffff097          	auipc	ra,0xfffff
    80001d5e:	042080e7          	jalr	66(ra) # 80000d9c <release>
  if (first) {
    80001d62:	00007797          	auipc	a5,0x7
    80001d66:	b5e7a783          	lw	a5,-1186(a5) # 800088c0 <first.1>
    80001d6a:	eb89                	bnez	a5,80001d7c <forkret+0x32>
  usertrapret();
    80001d6c:	00001097          	auipc	ra,0x1
    80001d70:	c18080e7          	jalr	-1000(ra) # 80002984 <usertrapret>
}
    80001d74:	60a2                	ld	ra,8(sp)
    80001d76:	6402                	ld	s0,0(sp)
    80001d78:	0141                	addi	sp,sp,16
    80001d7a:	8082                	ret
    first = 0;
    80001d7c:	00007797          	auipc	a5,0x7
    80001d80:	b407a223          	sw	zero,-1212(a5) # 800088c0 <first.1>
    fsinit(ROOTDEV);
    80001d84:	4505                	li	a0,1
    80001d86:	00002097          	auipc	ra,0x2
    80001d8a:	abc080e7          	jalr	-1348(ra) # 80003842 <fsinit>
    80001d8e:	bff9                	j	80001d6c <forkret+0x22>

0000000080001d90 <allocpid>:
allocpid() {
    80001d90:	1101                	addi	sp,sp,-32
    80001d92:	ec06                	sd	ra,24(sp)
    80001d94:	e822                	sd	s0,16(sp)
    80001d96:	e426                	sd	s1,8(sp)
    80001d98:	e04a                	sd	s2,0(sp)
    80001d9a:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001d9c:	00010917          	auipc	s2,0x10
    80001da0:	5ec90913          	addi	s2,s2,1516 # 80012388 <pid_lock>
    80001da4:	854a                	mv	a0,s2
    80001da6:	fffff097          	auipc	ra,0xfffff
    80001daa:	f26080e7          	jalr	-218(ra) # 80000ccc <acquire>
  pid = nextpid;
    80001dae:	00007797          	auipc	a5,0x7
    80001db2:	b1678793          	addi	a5,a5,-1258 # 800088c4 <nextpid>
    80001db6:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001db8:	0014871b          	addiw	a4,s1,1
    80001dbc:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001dbe:	854a                	mv	a0,s2
    80001dc0:	fffff097          	auipc	ra,0xfffff
    80001dc4:	fdc080e7          	jalr	-36(ra) # 80000d9c <release>
}
    80001dc8:	8526                	mv	a0,s1
    80001dca:	60e2                	ld	ra,24(sp)
    80001dcc:	6442                	ld	s0,16(sp)
    80001dce:	64a2                	ld	s1,8(sp)
    80001dd0:	6902                	ld	s2,0(sp)
    80001dd2:	6105                	addi	sp,sp,32
    80001dd4:	8082                	ret

0000000080001dd6 <proc_pagetable>:
{
    80001dd6:	1101                	addi	sp,sp,-32
    80001dd8:	ec06                	sd	ra,24(sp)
    80001dda:	e822                	sd	s0,16(sp)
    80001ddc:	e426                	sd	s1,8(sp)
    80001dde:	e04a                	sd	s2,0(sp)
    80001de0:	1000                	addi	s0,sp,32
    80001de2:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001de4:	00000097          	auipc	ra,0x0
    80001de8:	8e8080e7          	jalr	-1816(ra) # 800016cc <uvmcreate>
    80001dec:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001dee:	c121                	beqz	a0,80001e2e <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001df0:	4729                	li	a4,10
    80001df2:	00005697          	auipc	a3,0x5
    80001df6:	20e68693          	addi	a3,a3,526 # 80007000 <_trampoline>
    80001dfa:	6605                	lui	a2,0x1
    80001dfc:	040005b7          	lui	a1,0x4000
    80001e00:	15fd                	addi	a1,a1,-1
    80001e02:	05b2                	slli	a1,a1,0xc
    80001e04:	fffff097          	auipc	ra,0xfffff
    80001e08:	680080e7          	jalr	1664(ra) # 80001484 <mappages>
    80001e0c:	02054863          	bltz	a0,80001e3c <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001e10:	4719                	li	a4,6
    80001e12:	06093683          	ld	a3,96(s2)
    80001e16:	6605                	lui	a2,0x1
    80001e18:	020005b7          	lui	a1,0x2000
    80001e1c:	15fd                	addi	a1,a1,-1
    80001e1e:	05b6                	slli	a1,a1,0xd
    80001e20:	8526                	mv	a0,s1
    80001e22:	fffff097          	auipc	ra,0xfffff
    80001e26:	662080e7          	jalr	1634(ra) # 80001484 <mappages>
    80001e2a:	02054163          	bltz	a0,80001e4c <proc_pagetable+0x76>
}
    80001e2e:	8526                	mv	a0,s1
    80001e30:	60e2                	ld	ra,24(sp)
    80001e32:	6442                	ld	s0,16(sp)
    80001e34:	64a2                	ld	s1,8(sp)
    80001e36:	6902                	ld	s2,0(sp)
    80001e38:	6105                	addi	sp,sp,32
    80001e3a:	8082                	ret
    uvmfree(pagetable, 0);
    80001e3c:	4581                	li	a1,0
    80001e3e:	8526                	mv	a0,s1
    80001e40:	00000097          	auipc	ra,0x0
    80001e44:	a88080e7          	jalr	-1400(ra) # 800018c8 <uvmfree>
    return 0;
    80001e48:	4481                	li	s1,0
    80001e4a:	b7d5                	j	80001e2e <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e4c:	4681                	li	a3,0
    80001e4e:	4605                	li	a2,1
    80001e50:	040005b7          	lui	a1,0x4000
    80001e54:	15fd                	addi	a1,a1,-1
    80001e56:	05b2                	slli	a1,a1,0xc
    80001e58:	8526                	mv	a0,s1
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	7ae080e7          	jalr	1966(ra) # 80001608 <uvmunmap>
    uvmfree(pagetable, 0);
    80001e62:	4581                	li	a1,0
    80001e64:	8526                	mv	a0,s1
    80001e66:	00000097          	auipc	ra,0x0
    80001e6a:	a62080e7          	jalr	-1438(ra) # 800018c8 <uvmfree>
    return 0;
    80001e6e:	4481                	li	s1,0
    80001e70:	bf7d                	j	80001e2e <proc_pagetable+0x58>

0000000080001e72 <proc_freepagetable>:
{
    80001e72:	1101                	addi	sp,sp,-32
    80001e74:	ec06                	sd	ra,24(sp)
    80001e76:	e822                	sd	s0,16(sp)
    80001e78:	e426                	sd	s1,8(sp)
    80001e7a:	e04a                	sd	s2,0(sp)
    80001e7c:	1000                	addi	s0,sp,32
    80001e7e:	84aa                	mv	s1,a0
    80001e80:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e82:	4681                	li	a3,0
    80001e84:	4605                	li	a2,1
    80001e86:	040005b7          	lui	a1,0x4000
    80001e8a:	15fd                	addi	a1,a1,-1
    80001e8c:	05b2                	slli	a1,a1,0xc
    80001e8e:	fffff097          	auipc	ra,0xfffff
    80001e92:	77a080e7          	jalr	1914(ra) # 80001608 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001e96:	4681                	li	a3,0
    80001e98:	4605                	li	a2,1
    80001e9a:	020005b7          	lui	a1,0x2000
    80001e9e:	15fd                	addi	a1,a1,-1
    80001ea0:	05b6                	slli	a1,a1,0xd
    80001ea2:	8526                	mv	a0,s1
    80001ea4:	fffff097          	auipc	ra,0xfffff
    80001ea8:	764080e7          	jalr	1892(ra) # 80001608 <uvmunmap>
  uvmfree(pagetable, sz);
    80001eac:	85ca                	mv	a1,s2
    80001eae:	8526                	mv	a0,s1
    80001eb0:	00000097          	auipc	ra,0x0
    80001eb4:	a18080e7          	jalr	-1512(ra) # 800018c8 <uvmfree>
}
    80001eb8:	60e2                	ld	ra,24(sp)
    80001eba:	6442                	ld	s0,16(sp)
    80001ebc:	64a2                	ld	s1,8(sp)
    80001ebe:	6902                	ld	s2,0(sp)
    80001ec0:	6105                	addi	sp,sp,32
    80001ec2:	8082                	ret

0000000080001ec4 <freeproc>:
{
    80001ec4:	1101                	addi	sp,sp,-32
    80001ec6:	ec06                	sd	ra,24(sp)
    80001ec8:	e822                	sd	s0,16(sp)
    80001eca:	e426                	sd	s1,8(sp)
    80001ecc:	1000                	addi	s0,sp,32
    80001ece:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001ed0:	7128                	ld	a0,96(a0)
    80001ed2:	c509                	beqz	a0,80001edc <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001ed4:	fffff097          	auipc	ra,0xfffff
    80001ed8:	b46080e7          	jalr	-1210(ra) # 80000a1a <kfree>
  p->trapframe = 0;
    80001edc:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001ee0:	6ca8                	ld	a0,88(s1)
    80001ee2:	c511                	beqz	a0,80001eee <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ee4:	68ac                	ld	a1,80(s1)
    80001ee6:	00000097          	auipc	ra,0x0
    80001eea:	f8c080e7          	jalr	-116(ra) # 80001e72 <proc_freepagetable>
  p->pagetable = 0;
    80001eee:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001ef2:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001ef6:	0404a023          	sw	zero,64(s1)
  p->parent = 0;
    80001efa:	0204b423          	sd	zero,40(s1)
  p->name[0] = 0;
    80001efe:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001f02:	0204b823          	sd	zero,48(s1)
  p->killed = 0;
    80001f06:	0204ac23          	sw	zero,56(s1)
  p->xstate = 0;
    80001f0a:	0204ae23          	sw	zero,60(s1)
  p->state = UNUSED;
    80001f0e:	0204a023          	sw	zero,32(s1)
}
    80001f12:	60e2                	ld	ra,24(sp)
    80001f14:	6442                	ld	s0,16(sp)
    80001f16:	64a2                	ld	s1,8(sp)
    80001f18:	6105                	addi	sp,sp,32
    80001f1a:	8082                	ret

0000000080001f1c <allocproc>:
{
    80001f1c:	1101                	addi	sp,sp,-32
    80001f1e:	ec06                	sd	ra,24(sp)
    80001f20:	e822                	sd	s0,16(sp)
    80001f22:	e426                	sd	s1,8(sp)
    80001f24:	e04a                	sd	s2,0(sp)
    80001f26:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f28:	00011497          	auipc	s1,0x11
    80001f2c:	88048493          	addi	s1,s1,-1920 # 800127a8 <proc>
    80001f30:	00016917          	auipc	s2,0x16
    80001f34:	47890913          	addi	s2,s2,1144 # 800183a8 <tickslock>
    acquire(&p->lock);
    80001f38:	8526                	mv	a0,s1
    80001f3a:	fffff097          	auipc	ra,0xfffff
    80001f3e:	d92080e7          	jalr	-622(ra) # 80000ccc <acquire>
    if(p->state == UNUSED) {
    80001f42:	509c                	lw	a5,32(s1)
    80001f44:	cf81                	beqz	a5,80001f5c <allocproc+0x40>
      release(&p->lock);
    80001f46:	8526                	mv	a0,s1
    80001f48:	fffff097          	auipc	ra,0xfffff
    80001f4c:	e54080e7          	jalr	-428(ra) # 80000d9c <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f50:	17048493          	addi	s1,s1,368
    80001f54:	ff2492e3          	bne	s1,s2,80001f38 <allocproc+0x1c>
  return 0;
    80001f58:	4481                	li	s1,0
    80001f5a:	a0b9                	j	80001fa8 <allocproc+0x8c>
  p->pid = allocpid();
    80001f5c:	00000097          	auipc	ra,0x0
    80001f60:	e34080e7          	jalr	-460(ra) # 80001d90 <allocpid>
    80001f64:	c0a8                	sw	a0,64(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001f66:	fffff097          	auipc	ra,0xfffff
    80001f6a:	c04080e7          	jalr	-1020(ra) # 80000b6a <kalloc>
    80001f6e:	892a                	mv	s2,a0
    80001f70:	f0a8                	sd	a0,96(s1)
    80001f72:	c131                	beqz	a0,80001fb6 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001f74:	8526                	mv	a0,s1
    80001f76:	00000097          	auipc	ra,0x0
    80001f7a:	e60080e7          	jalr	-416(ra) # 80001dd6 <proc_pagetable>
    80001f7e:	892a                	mv	s2,a0
    80001f80:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    80001f82:	c129                	beqz	a0,80001fc4 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001f84:	07000613          	li	a2,112
    80001f88:	4581                	li	a1,0
    80001f8a:	06848513          	addi	a0,s1,104
    80001f8e:	fffff097          	auipc	ra,0xfffff
    80001f92:	11e080e7          	jalr	286(ra) # 800010ac <memset>
  p->context.ra = (uint64)forkret;
    80001f96:	00000797          	auipc	a5,0x0
    80001f9a:	db478793          	addi	a5,a5,-588 # 80001d4a <forkret>
    80001f9e:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001fa0:	64bc                	ld	a5,72(s1)
    80001fa2:	6705                	lui	a4,0x1
    80001fa4:	97ba                	add	a5,a5,a4
    80001fa6:	f8bc                	sd	a5,112(s1)
}
    80001fa8:	8526                	mv	a0,s1
    80001faa:	60e2                	ld	ra,24(sp)
    80001fac:	6442                	ld	s0,16(sp)
    80001fae:	64a2                	ld	s1,8(sp)
    80001fb0:	6902                	ld	s2,0(sp)
    80001fb2:	6105                	addi	sp,sp,32
    80001fb4:	8082                	ret
    release(&p->lock);
    80001fb6:	8526                	mv	a0,s1
    80001fb8:	fffff097          	auipc	ra,0xfffff
    80001fbc:	de4080e7          	jalr	-540(ra) # 80000d9c <release>
    return 0;
    80001fc0:	84ca                	mv	s1,s2
    80001fc2:	b7dd                	j	80001fa8 <allocproc+0x8c>
    freeproc(p);
    80001fc4:	8526                	mv	a0,s1
    80001fc6:	00000097          	auipc	ra,0x0
    80001fca:	efe080e7          	jalr	-258(ra) # 80001ec4 <freeproc>
    release(&p->lock);
    80001fce:	8526                	mv	a0,s1
    80001fd0:	fffff097          	auipc	ra,0xfffff
    80001fd4:	dcc080e7          	jalr	-564(ra) # 80000d9c <release>
    return 0;
    80001fd8:	84ca                	mv	s1,s2
    80001fda:	b7f9                	j	80001fa8 <allocproc+0x8c>

0000000080001fdc <userinit>:
{
    80001fdc:	1101                	addi	sp,sp,-32
    80001fde:	ec06                	sd	ra,24(sp)
    80001fe0:	e822                	sd	s0,16(sp)
    80001fe2:	e426                	sd	s1,8(sp)
    80001fe4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001fe6:	00000097          	auipc	ra,0x0
    80001fea:	f36080e7          	jalr	-202(ra) # 80001f1c <allocproc>
    80001fee:	84aa                	mv	s1,a0
  initproc = p;
    80001ff0:	00007797          	auipc	a5,0x7
    80001ff4:	02a7b423          	sd	a0,40(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ff8:	03400613          	li	a2,52
    80001ffc:	00007597          	auipc	a1,0x7
    80002000:	8d458593          	addi	a1,a1,-1836 # 800088d0 <initcode>
    80002004:	6d28                	ld	a0,88(a0)
    80002006:	fffff097          	auipc	ra,0xfffff
    8000200a:	6f4080e7          	jalr	1780(ra) # 800016fa <uvminit>
  p->sz = PGSIZE;
    8000200e:	6785                	lui	a5,0x1
    80002010:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;      // user program counter
    80002012:	70b8                	ld	a4,96(s1)
    80002014:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002018:	70b8                	ld	a4,96(s1)
    8000201a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    8000201c:	4641                	li	a2,16
    8000201e:	00006597          	auipc	a1,0x6
    80002022:	25a58593          	addi	a1,a1,602 # 80008278 <digits+0x238>
    80002026:	16048513          	addi	a0,s1,352
    8000202a:	fffff097          	auipc	ra,0xfffff
    8000202e:	1d4080e7          	jalr	468(ra) # 800011fe <safestrcpy>
  p->cwd = namei("/");
    80002032:	00006517          	auipc	a0,0x6
    80002036:	25650513          	addi	a0,a0,598 # 80008288 <digits+0x248>
    8000203a:	00002097          	auipc	ra,0x2
    8000203e:	234080e7          	jalr	564(ra) # 8000426e <namei>
    80002042:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80002046:	4789                	li	a5,2
    80002048:	d09c                	sw	a5,32(s1)
  release(&p->lock);
    8000204a:	8526                	mv	a0,s1
    8000204c:	fffff097          	auipc	ra,0xfffff
    80002050:	d50080e7          	jalr	-688(ra) # 80000d9c <release>
}
    80002054:	60e2                	ld	ra,24(sp)
    80002056:	6442                	ld	s0,16(sp)
    80002058:	64a2                	ld	s1,8(sp)
    8000205a:	6105                	addi	sp,sp,32
    8000205c:	8082                	ret

000000008000205e <growproc>:
{
    8000205e:	1101                	addi	sp,sp,-32
    80002060:	ec06                	sd	ra,24(sp)
    80002062:	e822                	sd	s0,16(sp)
    80002064:	e426                	sd	s1,8(sp)
    80002066:	e04a                	sd	s2,0(sp)
    80002068:	1000                	addi	s0,sp,32
    8000206a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000206c:	00000097          	auipc	ra,0x0
    80002070:	ca6080e7          	jalr	-858(ra) # 80001d12 <myproc>
    80002074:	892a                	mv	s2,a0
  sz = p->sz;
    80002076:	692c                	ld	a1,80(a0)
    80002078:	0005861b          	sext.w	a2,a1
  if(n > 0){
    8000207c:	00904f63          	bgtz	s1,8000209a <growproc+0x3c>
  } else if(n < 0){
    80002080:	0204cc63          	bltz	s1,800020b8 <growproc+0x5a>
  p->sz = sz;
    80002084:	1602                	slli	a2,a2,0x20
    80002086:	9201                	srli	a2,a2,0x20
    80002088:	04c93823          	sd	a2,80(s2)
  return 0;
    8000208c:	4501                	li	a0,0
}
    8000208e:	60e2                	ld	ra,24(sp)
    80002090:	6442                	ld	s0,16(sp)
    80002092:	64a2                	ld	s1,8(sp)
    80002094:	6902                	ld	s2,0(sp)
    80002096:	6105                	addi	sp,sp,32
    80002098:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000209a:	9e25                	addw	a2,a2,s1
    8000209c:	1602                	slli	a2,a2,0x20
    8000209e:	9201                	srli	a2,a2,0x20
    800020a0:	1582                	slli	a1,a1,0x20
    800020a2:	9181                	srli	a1,a1,0x20
    800020a4:	6d28                	ld	a0,88(a0)
    800020a6:	fffff097          	auipc	ra,0xfffff
    800020aa:	70e080e7          	jalr	1806(ra) # 800017b4 <uvmalloc>
    800020ae:	0005061b          	sext.w	a2,a0
    800020b2:	fa69                	bnez	a2,80002084 <growproc+0x26>
      return -1;
    800020b4:	557d                	li	a0,-1
    800020b6:	bfe1                	j	8000208e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800020b8:	9e25                	addw	a2,a2,s1
    800020ba:	1602                	slli	a2,a2,0x20
    800020bc:	9201                	srli	a2,a2,0x20
    800020be:	1582                	slli	a1,a1,0x20
    800020c0:	9181                	srli	a1,a1,0x20
    800020c2:	6d28                	ld	a0,88(a0)
    800020c4:	fffff097          	auipc	ra,0xfffff
    800020c8:	6a8080e7          	jalr	1704(ra) # 8000176c <uvmdealloc>
    800020cc:	0005061b          	sext.w	a2,a0
    800020d0:	bf55                	j	80002084 <growproc+0x26>

00000000800020d2 <fork>:
{
    800020d2:	7139                	addi	sp,sp,-64
    800020d4:	fc06                	sd	ra,56(sp)
    800020d6:	f822                	sd	s0,48(sp)
    800020d8:	f426                	sd	s1,40(sp)
    800020da:	f04a                	sd	s2,32(sp)
    800020dc:	ec4e                	sd	s3,24(sp)
    800020de:	e852                	sd	s4,16(sp)
    800020e0:	e456                	sd	s5,8(sp)
    800020e2:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    800020e4:	00000097          	auipc	ra,0x0
    800020e8:	c2e080e7          	jalr	-978(ra) # 80001d12 <myproc>
    800020ec:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    800020ee:	00000097          	auipc	ra,0x0
    800020f2:	e2e080e7          	jalr	-466(ra) # 80001f1c <allocproc>
    800020f6:	c17d                	beqz	a0,800021dc <fork+0x10a>
    800020f8:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800020fa:	050ab603          	ld	a2,80(s5)
    800020fe:	6d2c                	ld	a1,88(a0)
    80002100:	058ab503          	ld	a0,88(s5)
    80002104:	fffff097          	auipc	ra,0xfffff
    80002108:	7fc080e7          	jalr	2044(ra) # 80001900 <uvmcopy>
    8000210c:	04054a63          	bltz	a0,80002160 <fork+0x8e>
  np->sz = p->sz;
    80002110:	050ab783          	ld	a5,80(s5)
    80002114:	04fa3823          	sd	a5,80(s4)
  np->parent = p;
    80002118:	035a3423          	sd	s5,40(s4)
  *(np->trapframe) = *(p->trapframe);
    8000211c:	060ab683          	ld	a3,96(s5)
    80002120:	87b6                	mv	a5,a3
    80002122:	060a3703          	ld	a4,96(s4)
    80002126:	12068693          	addi	a3,a3,288
    8000212a:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    8000212e:	6788                	ld	a0,8(a5)
    80002130:	6b8c                	ld	a1,16(a5)
    80002132:	6f90                	ld	a2,24(a5)
    80002134:	01073023          	sd	a6,0(a4)
    80002138:	e708                	sd	a0,8(a4)
    8000213a:	eb0c                	sd	a1,16(a4)
    8000213c:	ef10                	sd	a2,24(a4)
    8000213e:	02078793          	addi	a5,a5,32
    80002142:	02070713          	addi	a4,a4,32
    80002146:	fed792e3          	bne	a5,a3,8000212a <fork+0x58>
  np->trapframe->a0 = 0;
    8000214a:	060a3783          	ld	a5,96(s4)
    8000214e:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80002152:	0d8a8493          	addi	s1,s5,216
    80002156:	0d8a0913          	addi	s2,s4,216
    8000215a:	158a8993          	addi	s3,s5,344
    8000215e:	a00d                	j	80002180 <fork+0xae>
    freeproc(np);
    80002160:	8552                	mv	a0,s4
    80002162:	00000097          	auipc	ra,0x0
    80002166:	d62080e7          	jalr	-670(ra) # 80001ec4 <freeproc>
    release(&np->lock);
    8000216a:	8552                	mv	a0,s4
    8000216c:	fffff097          	auipc	ra,0xfffff
    80002170:	c30080e7          	jalr	-976(ra) # 80000d9c <release>
    return -1;
    80002174:	54fd                	li	s1,-1
    80002176:	a889                	j	800021c8 <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
    80002178:	04a1                	addi	s1,s1,8
    8000217a:	0921                	addi	s2,s2,8
    8000217c:	01348b63          	beq	s1,s3,80002192 <fork+0xc0>
    if(p->ofile[i])
    80002180:	6088                	ld	a0,0(s1)
    80002182:	d97d                	beqz	a0,80002178 <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    80002184:	00002097          	auipc	ra,0x2
    80002188:	788080e7          	jalr	1928(ra) # 8000490c <filedup>
    8000218c:	00a93023          	sd	a0,0(s2)
    80002190:	b7e5                	j	80002178 <fork+0xa6>
  np->cwd = idup(p->cwd);
    80002192:	158ab503          	ld	a0,344(s5)
    80002196:	00002097          	auipc	ra,0x2
    8000219a:	8e6080e7          	jalr	-1818(ra) # 80003a7c <idup>
    8000219e:	14aa3c23          	sd	a0,344(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800021a2:	4641                	li	a2,16
    800021a4:	160a8593          	addi	a1,s5,352
    800021a8:	160a0513          	addi	a0,s4,352
    800021ac:	fffff097          	auipc	ra,0xfffff
    800021b0:	052080e7          	jalr	82(ra) # 800011fe <safestrcpy>
  pid = np->pid;
    800021b4:	040a2483          	lw	s1,64(s4)
  np->state = RUNNABLE;
    800021b8:	4789                	li	a5,2
    800021ba:	02fa2023          	sw	a5,32(s4)
  release(&np->lock);
    800021be:	8552                	mv	a0,s4
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	bdc080e7          	jalr	-1060(ra) # 80000d9c <release>
}
    800021c8:	8526                	mv	a0,s1
    800021ca:	70e2                	ld	ra,56(sp)
    800021cc:	7442                	ld	s0,48(sp)
    800021ce:	74a2                	ld	s1,40(sp)
    800021d0:	7902                	ld	s2,32(sp)
    800021d2:	69e2                	ld	s3,24(sp)
    800021d4:	6a42                	ld	s4,16(sp)
    800021d6:	6aa2                	ld	s5,8(sp)
    800021d8:	6121                	addi	sp,sp,64
    800021da:	8082                	ret
    return -1;
    800021dc:	54fd                	li	s1,-1
    800021de:	b7ed                	j	800021c8 <fork+0xf6>

00000000800021e0 <reparent>:
{
    800021e0:	7179                	addi	sp,sp,-48
    800021e2:	f406                	sd	ra,40(sp)
    800021e4:	f022                	sd	s0,32(sp)
    800021e6:	ec26                	sd	s1,24(sp)
    800021e8:	e84a                	sd	s2,16(sp)
    800021ea:	e44e                	sd	s3,8(sp)
    800021ec:	e052                	sd	s4,0(sp)
    800021ee:	1800                	addi	s0,sp,48
    800021f0:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021f2:	00010497          	auipc	s1,0x10
    800021f6:	5b648493          	addi	s1,s1,1462 # 800127a8 <proc>
      pp->parent = initproc;
    800021fa:	00007a17          	auipc	s4,0x7
    800021fe:	e1ea0a13          	addi	s4,s4,-482 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002202:	00016997          	auipc	s3,0x16
    80002206:	1a698993          	addi	s3,s3,422 # 800183a8 <tickslock>
    8000220a:	a029                	j	80002214 <reparent+0x34>
    8000220c:	17048493          	addi	s1,s1,368
    80002210:	03348363          	beq	s1,s3,80002236 <reparent+0x56>
    if(pp->parent == p){
    80002214:	749c                	ld	a5,40(s1)
    80002216:	ff279be3          	bne	a5,s2,8000220c <reparent+0x2c>
      acquire(&pp->lock);
    8000221a:	8526                	mv	a0,s1
    8000221c:	fffff097          	auipc	ra,0xfffff
    80002220:	ab0080e7          	jalr	-1360(ra) # 80000ccc <acquire>
      pp->parent = initproc;
    80002224:	000a3783          	ld	a5,0(s4)
    80002228:	f49c                	sd	a5,40(s1)
      release(&pp->lock);
    8000222a:	8526                	mv	a0,s1
    8000222c:	fffff097          	auipc	ra,0xfffff
    80002230:	b70080e7          	jalr	-1168(ra) # 80000d9c <release>
    80002234:	bfe1                	j	8000220c <reparent+0x2c>
}
    80002236:	70a2                	ld	ra,40(sp)
    80002238:	7402                	ld	s0,32(sp)
    8000223a:	64e2                	ld	s1,24(sp)
    8000223c:	6942                	ld	s2,16(sp)
    8000223e:	69a2                	ld	s3,8(sp)
    80002240:	6a02                	ld	s4,0(sp)
    80002242:	6145                	addi	sp,sp,48
    80002244:	8082                	ret

0000000080002246 <scheduler>:
{
    80002246:	711d                	addi	sp,sp,-96
    80002248:	ec86                	sd	ra,88(sp)
    8000224a:	e8a2                	sd	s0,80(sp)
    8000224c:	e4a6                	sd	s1,72(sp)
    8000224e:	e0ca                	sd	s2,64(sp)
    80002250:	fc4e                	sd	s3,56(sp)
    80002252:	f852                	sd	s4,48(sp)
    80002254:	f456                	sd	s5,40(sp)
    80002256:	f05a                	sd	s6,32(sp)
    80002258:	ec5e                	sd	s7,24(sp)
    8000225a:	e862                	sd	s8,16(sp)
    8000225c:	e466                	sd	s9,8(sp)
    8000225e:	1080                	addi	s0,sp,96
    80002260:	8792                	mv	a5,tp
  int id = r_tp();
    80002262:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002264:	00779c13          	slli	s8,a5,0x7
    80002268:	00010717          	auipc	a4,0x10
    8000226c:	12070713          	addi	a4,a4,288 # 80012388 <pid_lock>
    80002270:	9762                	add	a4,a4,s8
    80002272:	02073023          	sd	zero,32(a4)
        swtch(&c->context, &p->context);
    80002276:	00010717          	auipc	a4,0x10
    8000227a:	13a70713          	addi	a4,a4,314 # 800123b0 <cpus+0x8>
    8000227e:	9c3a                	add	s8,s8,a4
    int nproc = 0;
    80002280:	4c81                	li	s9,0
      if(p->state == RUNNABLE) {
    80002282:	4a89                	li	s5,2
        c->proc = p;
    80002284:	079e                	slli	a5,a5,0x7
    80002286:	00010b17          	auipc	s6,0x10
    8000228a:	102b0b13          	addi	s6,s6,258 # 80012388 <pid_lock>
    8000228e:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002290:	00016a17          	auipc	s4,0x16
    80002294:	118a0a13          	addi	s4,s4,280 # 800183a8 <tickslock>
    80002298:	a8a1                	j	800022f0 <scheduler+0xaa>
      release(&p->lock);
    8000229a:	8526                	mv	a0,s1
    8000229c:	fffff097          	auipc	ra,0xfffff
    800022a0:	b00080e7          	jalr	-1280(ra) # 80000d9c <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800022a4:	17048493          	addi	s1,s1,368
    800022a8:	03448a63          	beq	s1,s4,800022dc <scheduler+0x96>
      acquire(&p->lock);
    800022ac:	8526                	mv	a0,s1
    800022ae:	fffff097          	auipc	ra,0xfffff
    800022b2:	a1e080e7          	jalr	-1506(ra) # 80000ccc <acquire>
      if(p->state != UNUSED) {
    800022b6:	509c                	lw	a5,32(s1)
    800022b8:	d3ed                	beqz	a5,8000229a <scheduler+0x54>
        nproc++;
    800022ba:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    800022bc:	fd579fe3          	bne	a5,s5,8000229a <scheduler+0x54>
        p->state = RUNNING;
    800022c0:	0374a023          	sw	s7,32(s1)
        c->proc = p;
    800022c4:	029b3023          	sd	s1,32(s6)
        swtch(&c->context, &p->context);
    800022c8:	06848593          	addi	a1,s1,104
    800022cc:	8562                	mv	a0,s8
    800022ce:	00000097          	auipc	ra,0x0
    800022d2:	60c080e7          	jalr	1548(ra) # 800028da <swtch>
        c->proc = 0;
    800022d6:	020b3023          	sd	zero,32(s6)
    800022da:	b7c1                	j	8000229a <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    800022dc:	013aca63          	blt	s5,s3,800022f0 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022e0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800022e4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800022e8:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    800022ec:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022f0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800022f4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800022f8:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    800022fc:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    800022fe:	00010497          	auipc	s1,0x10
    80002302:	4aa48493          	addi	s1,s1,1194 # 800127a8 <proc>
        p->state = RUNNING;
    80002306:	4b8d                	li	s7,3
    80002308:	b755                	j	800022ac <scheduler+0x66>

000000008000230a <sched>:
{
    8000230a:	7179                	addi	sp,sp,-48
    8000230c:	f406                	sd	ra,40(sp)
    8000230e:	f022                	sd	s0,32(sp)
    80002310:	ec26                	sd	s1,24(sp)
    80002312:	e84a                	sd	s2,16(sp)
    80002314:	e44e                	sd	s3,8(sp)
    80002316:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002318:	00000097          	auipc	ra,0x0
    8000231c:	9fa080e7          	jalr	-1542(ra) # 80001d12 <myproc>
    80002320:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002322:	fffff097          	auipc	ra,0xfffff
    80002326:	930080e7          	jalr	-1744(ra) # 80000c52 <holding>
    8000232a:	c93d                	beqz	a0,800023a0 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000232c:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000232e:	2781                	sext.w	a5,a5
    80002330:	079e                	slli	a5,a5,0x7
    80002332:	00010717          	auipc	a4,0x10
    80002336:	05670713          	addi	a4,a4,86 # 80012388 <pid_lock>
    8000233a:	97ba                	add	a5,a5,a4
    8000233c:	0987a703          	lw	a4,152(a5)
    80002340:	4785                	li	a5,1
    80002342:	06f71763          	bne	a4,a5,800023b0 <sched+0xa6>
  if(p->state == RUNNING)
    80002346:	5098                	lw	a4,32(s1)
    80002348:	478d                	li	a5,3
    8000234a:	06f70b63          	beq	a4,a5,800023c0 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000234e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002352:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002354:	efb5                	bnez	a5,800023d0 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002356:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002358:	00010917          	auipc	s2,0x10
    8000235c:	03090913          	addi	s2,s2,48 # 80012388 <pid_lock>
    80002360:	2781                	sext.w	a5,a5
    80002362:	079e                	slli	a5,a5,0x7
    80002364:	97ca                	add	a5,a5,s2
    80002366:	09c7a983          	lw	s3,156(a5)
    8000236a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000236c:	2781                	sext.w	a5,a5
    8000236e:	079e                	slli	a5,a5,0x7
    80002370:	00010597          	auipc	a1,0x10
    80002374:	04058593          	addi	a1,a1,64 # 800123b0 <cpus+0x8>
    80002378:	95be                	add	a1,a1,a5
    8000237a:	06848513          	addi	a0,s1,104
    8000237e:	00000097          	auipc	ra,0x0
    80002382:	55c080e7          	jalr	1372(ra) # 800028da <swtch>
    80002386:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002388:	2781                	sext.w	a5,a5
    8000238a:	079e                	slli	a5,a5,0x7
    8000238c:	97ca                	add	a5,a5,s2
    8000238e:	0937ae23          	sw	s3,156(a5)
}
    80002392:	70a2                	ld	ra,40(sp)
    80002394:	7402                	ld	s0,32(sp)
    80002396:	64e2                	ld	s1,24(sp)
    80002398:	6942                	ld	s2,16(sp)
    8000239a:	69a2                	ld	s3,8(sp)
    8000239c:	6145                	addi	sp,sp,48
    8000239e:	8082                	ret
    panic("sched p->lock");
    800023a0:	00006517          	auipc	a0,0x6
    800023a4:	ef050513          	addi	a0,a0,-272 # 80008290 <digits+0x250>
    800023a8:	ffffe097          	auipc	ra,0xffffe
    800023ac:	1a2080e7          	jalr	418(ra) # 8000054a <panic>
    panic("sched locks");
    800023b0:	00006517          	auipc	a0,0x6
    800023b4:	ef050513          	addi	a0,a0,-272 # 800082a0 <digits+0x260>
    800023b8:	ffffe097          	auipc	ra,0xffffe
    800023bc:	192080e7          	jalr	402(ra) # 8000054a <panic>
    panic("sched running");
    800023c0:	00006517          	auipc	a0,0x6
    800023c4:	ef050513          	addi	a0,a0,-272 # 800082b0 <digits+0x270>
    800023c8:	ffffe097          	auipc	ra,0xffffe
    800023cc:	182080e7          	jalr	386(ra) # 8000054a <panic>
    panic("sched interruptible");
    800023d0:	00006517          	auipc	a0,0x6
    800023d4:	ef050513          	addi	a0,a0,-272 # 800082c0 <digits+0x280>
    800023d8:	ffffe097          	auipc	ra,0xffffe
    800023dc:	172080e7          	jalr	370(ra) # 8000054a <panic>

00000000800023e0 <exit>:
{
    800023e0:	7179                	addi	sp,sp,-48
    800023e2:	f406                	sd	ra,40(sp)
    800023e4:	f022                	sd	s0,32(sp)
    800023e6:	ec26                	sd	s1,24(sp)
    800023e8:	e84a                	sd	s2,16(sp)
    800023ea:	e44e                	sd	s3,8(sp)
    800023ec:	e052                	sd	s4,0(sp)
    800023ee:	1800                	addi	s0,sp,48
    800023f0:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800023f2:	00000097          	auipc	ra,0x0
    800023f6:	920080e7          	jalr	-1760(ra) # 80001d12 <myproc>
    800023fa:	89aa                	mv	s3,a0
  if(p == initproc)
    800023fc:	00007797          	auipc	a5,0x7
    80002400:	c1c7b783          	ld	a5,-996(a5) # 80009018 <initproc>
    80002404:	0d850493          	addi	s1,a0,216
    80002408:	15850913          	addi	s2,a0,344
    8000240c:	02a79363          	bne	a5,a0,80002432 <exit+0x52>
    panic("init exiting");
    80002410:	00006517          	auipc	a0,0x6
    80002414:	ec850513          	addi	a0,a0,-312 # 800082d8 <digits+0x298>
    80002418:	ffffe097          	auipc	ra,0xffffe
    8000241c:	132080e7          	jalr	306(ra) # 8000054a <panic>
      fileclose(f);
    80002420:	00002097          	auipc	ra,0x2
    80002424:	53e080e7          	jalr	1342(ra) # 8000495e <fileclose>
      p->ofile[fd] = 0;
    80002428:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000242c:	04a1                	addi	s1,s1,8
    8000242e:	01248563          	beq	s1,s2,80002438 <exit+0x58>
    if(p->ofile[fd]){
    80002432:	6088                	ld	a0,0(s1)
    80002434:	f575                	bnez	a0,80002420 <exit+0x40>
    80002436:	bfdd                	j	8000242c <exit+0x4c>
  begin_op();
    80002438:	00002097          	auipc	ra,0x2
    8000243c:	052080e7          	jalr	82(ra) # 8000448a <begin_op>
  iput(p->cwd);
    80002440:	1589b503          	ld	a0,344(s3)
    80002444:	00002097          	auipc	ra,0x2
    80002448:	830080e7          	jalr	-2000(ra) # 80003c74 <iput>
  end_op();
    8000244c:	00002097          	auipc	ra,0x2
    80002450:	0be080e7          	jalr	190(ra) # 8000450a <end_op>
  p->cwd = 0;
    80002454:	1409bc23          	sd	zero,344(s3)
  acquire(&initproc->lock);
    80002458:	00007497          	auipc	s1,0x7
    8000245c:	bc048493          	addi	s1,s1,-1088 # 80009018 <initproc>
    80002460:	6088                	ld	a0,0(s1)
    80002462:	fffff097          	auipc	ra,0xfffff
    80002466:	86a080e7          	jalr	-1942(ra) # 80000ccc <acquire>
  wakeup1(initproc);
    8000246a:	6088                	ld	a0,0(s1)
    8000246c:	fffff097          	auipc	ra,0xfffff
    80002470:	766080e7          	jalr	1894(ra) # 80001bd2 <wakeup1>
  release(&initproc->lock);
    80002474:	6088                	ld	a0,0(s1)
    80002476:	fffff097          	auipc	ra,0xfffff
    8000247a:	926080e7          	jalr	-1754(ra) # 80000d9c <release>
  acquire(&p->lock);
    8000247e:	854e                	mv	a0,s3
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	84c080e7          	jalr	-1972(ra) # 80000ccc <acquire>
  struct proc *original_parent = p->parent;
    80002488:	0289b483          	ld	s1,40(s3)
  release(&p->lock);
    8000248c:	854e                	mv	a0,s3
    8000248e:	fffff097          	auipc	ra,0xfffff
    80002492:	90e080e7          	jalr	-1778(ra) # 80000d9c <release>
  acquire(&original_parent->lock);
    80002496:	8526                	mv	a0,s1
    80002498:	fffff097          	auipc	ra,0xfffff
    8000249c:	834080e7          	jalr	-1996(ra) # 80000ccc <acquire>
  acquire(&p->lock);
    800024a0:	854e                	mv	a0,s3
    800024a2:	fffff097          	auipc	ra,0xfffff
    800024a6:	82a080e7          	jalr	-2006(ra) # 80000ccc <acquire>
  reparent(p);
    800024aa:	854e                	mv	a0,s3
    800024ac:	00000097          	auipc	ra,0x0
    800024b0:	d34080e7          	jalr	-716(ra) # 800021e0 <reparent>
  wakeup1(original_parent);
    800024b4:	8526                	mv	a0,s1
    800024b6:	fffff097          	auipc	ra,0xfffff
    800024ba:	71c080e7          	jalr	1820(ra) # 80001bd2 <wakeup1>
  p->xstate = status;
    800024be:	0349ae23          	sw	s4,60(s3)
  p->state = ZOMBIE;
    800024c2:	4791                	li	a5,4
    800024c4:	02f9a023          	sw	a5,32(s3)
  release(&original_parent->lock);
    800024c8:	8526                	mv	a0,s1
    800024ca:	fffff097          	auipc	ra,0xfffff
    800024ce:	8d2080e7          	jalr	-1838(ra) # 80000d9c <release>
  sched();
    800024d2:	00000097          	auipc	ra,0x0
    800024d6:	e38080e7          	jalr	-456(ra) # 8000230a <sched>
  panic("zombie exit");
    800024da:	00006517          	auipc	a0,0x6
    800024de:	e0e50513          	addi	a0,a0,-498 # 800082e8 <digits+0x2a8>
    800024e2:	ffffe097          	auipc	ra,0xffffe
    800024e6:	068080e7          	jalr	104(ra) # 8000054a <panic>

00000000800024ea <yield>:
{
    800024ea:	1101                	addi	sp,sp,-32
    800024ec:	ec06                	sd	ra,24(sp)
    800024ee:	e822                	sd	s0,16(sp)
    800024f0:	e426                	sd	s1,8(sp)
    800024f2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800024f4:	00000097          	auipc	ra,0x0
    800024f8:	81e080e7          	jalr	-2018(ra) # 80001d12 <myproc>
    800024fc:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800024fe:	ffffe097          	auipc	ra,0xffffe
    80002502:	7ce080e7          	jalr	1998(ra) # 80000ccc <acquire>
  p->state = RUNNABLE;
    80002506:	4789                	li	a5,2
    80002508:	d09c                	sw	a5,32(s1)
  sched();
    8000250a:	00000097          	auipc	ra,0x0
    8000250e:	e00080e7          	jalr	-512(ra) # 8000230a <sched>
  release(&p->lock);
    80002512:	8526                	mv	a0,s1
    80002514:	fffff097          	auipc	ra,0xfffff
    80002518:	888080e7          	jalr	-1912(ra) # 80000d9c <release>
}
    8000251c:	60e2                	ld	ra,24(sp)
    8000251e:	6442                	ld	s0,16(sp)
    80002520:	64a2                	ld	s1,8(sp)
    80002522:	6105                	addi	sp,sp,32
    80002524:	8082                	ret

0000000080002526 <sleep>:
{
    80002526:	7179                	addi	sp,sp,-48
    80002528:	f406                	sd	ra,40(sp)
    8000252a:	f022                	sd	s0,32(sp)
    8000252c:	ec26                	sd	s1,24(sp)
    8000252e:	e84a                	sd	s2,16(sp)
    80002530:	e44e                	sd	s3,8(sp)
    80002532:	1800                	addi	s0,sp,48
    80002534:	89aa                	mv	s3,a0
    80002536:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002538:	fffff097          	auipc	ra,0xfffff
    8000253c:	7da080e7          	jalr	2010(ra) # 80001d12 <myproc>
    80002540:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002542:	05250663          	beq	a0,s2,8000258e <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002546:	ffffe097          	auipc	ra,0xffffe
    8000254a:	786080e7          	jalr	1926(ra) # 80000ccc <acquire>
    release(lk);
    8000254e:	854a                	mv	a0,s2
    80002550:	fffff097          	auipc	ra,0xfffff
    80002554:	84c080e7          	jalr	-1972(ra) # 80000d9c <release>
  p->chan = chan;
    80002558:	0334b823          	sd	s3,48(s1)
  p->state = SLEEPING;
    8000255c:	4785                	li	a5,1
    8000255e:	d09c                	sw	a5,32(s1)
  sched();
    80002560:	00000097          	auipc	ra,0x0
    80002564:	daa080e7          	jalr	-598(ra) # 8000230a <sched>
  p->chan = 0;
    80002568:	0204b823          	sd	zero,48(s1)
    release(&p->lock);
    8000256c:	8526                	mv	a0,s1
    8000256e:	fffff097          	auipc	ra,0xfffff
    80002572:	82e080e7          	jalr	-2002(ra) # 80000d9c <release>
    acquire(lk);
    80002576:	854a                	mv	a0,s2
    80002578:	ffffe097          	auipc	ra,0xffffe
    8000257c:	754080e7          	jalr	1876(ra) # 80000ccc <acquire>
}
    80002580:	70a2                	ld	ra,40(sp)
    80002582:	7402                	ld	s0,32(sp)
    80002584:	64e2                	ld	s1,24(sp)
    80002586:	6942                	ld	s2,16(sp)
    80002588:	69a2                	ld	s3,8(sp)
    8000258a:	6145                	addi	sp,sp,48
    8000258c:	8082                	ret
  p->chan = chan;
    8000258e:	03353823          	sd	s3,48(a0)
  p->state = SLEEPING;
    80002592:	4785                	li	a5,1
    80002594:	d11c                	sw	a5,32(a0)
  sched();
    80002596:	00000097          	auipc	ra,0x0
    8000259a:	d74080e7          	jalr	-652(ra) # 8000230a <sched>
  p->chan = 0;
    8000259e:	0204b823          	sd	zero,48(s1)
  if(lk != &p->lock){
    800025a2:	bff9                	j	80002580 <sleep+0x5a>

00000000800025a4 <wait>:
{
    800025a4:	715d                	addi	sp,sp,-80
    800025a6:	e486                	sd	ra,72(sp)
    800025a8:	e0a2                	sd	s0,64(sp)
    800025aa:	fc26                	sd	s1,56(sp)
    800025ac:	f84a                	sd	s2,48(sp)
    800025ae:	f44e                	sd	s3,40(sp)
    800025b0:	f052                	sd	s4,32(sp)
    800025b2:	ec56                	sd	s5,24(sp)
    800025b4:	e85a                	sd	s6,16(sp)
    800025b6:	e45e                	sd	s7,8(sp)
    800025b8:	0880                	addi	s0,sp,80
    800025ba:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800025bc:	fffff097          	auipc	ra,0xfffff
    800025c0:	756080e7          	jalr	1878(ra) # 80001d12 <myproc>
    800025c4:	892a                	mv	s2,a0
  acquire(&p->lock);
    800025c6:	ffffe097          	auipc	ra,0xffffe
    800025ca:	706080e7          	jalr	1798(ra) # 80000ccc <acquire>
    havekids = 0;
    800025ce:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800025d0:	4a11                	li	s4,4
        havekids = 1;
    800025d2:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800025d4:	00016997          	auipc	s3,0x16
    800025d8:	dd498993          	addi	s3,s3,-556 # 800183a8 <tickslock>
    havekids = 0;
    800025dc:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800025de:	00010497          	auipc	s1,0x10
    800025e2:	1ca48493          	addi	s1,s1,458 # 800127a8 <proc>
    800025e6:	a08d                	j	80002648 <wait+0xa4>
          pid = np->pid;
    800025e8:	0404a983          	lw	s3,64(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800025ec:	000b0e63          	beqz	s6,80002608 <wait+0x64>
    800025f0:	4691                	li	a3,4
    800025f2:	03c48613          	addi	a2,s1,60
    800025f6:	85da                	mv	a1,s6
    800025f8:	05893503          	ld	a0,88(s2)
    800025fc:	fffff097          	auipc	ra,0xfffff
    80002600:	408080e7          	jalr	1032(ra) # 80001a04 <copyout>
    80002604:	02054263          	bltz	a0,80002628 <wait+0x84>
          freeproc(np);
    80002608:	8526                	mv	a0,s1
    8000260a:	00000097          	auipc	ra,0x0
    8000260e:	8ba080e7          	jalr	-1862(ra) # 80001ec4 <freeproc>
          release(&np->lock);
    80002612:	8526                	mv	a0,s1
    80002614:	ffffe097          	auipc	ra,0xffffe
    80002618:	788080e7          	jalr	1928(ra) # 80000d9c <release>
          release(&p->lock);
    8000261c:	854a                	mv	a0,s2
    8000261e:	ffffe097          	auipc	ra,0xffffe
    80002622:	77e080e7          	jalr	1918(ra) # 80000d9c <release>
          return pid;
    80002626:	a8a9                	j	80002680 <wait+0xdc>
            release(&np->lock);
    80002628:	8526                	mv	a0,s1
    8000262a:	ffffe097          	auipc	ra,0xffffe
    8000262e:	772080e7          	jalr	1906(ra) # 80000d9c <release>
            release(&p->lock);
    80002632:	854a                	mv	a0,s2
    80002634:	ffffe097          	auipc	ra,0xffffe
    80002638:	768080e7          	jalr	1896(ra) # 80000d9c <release>
            return -1;
    8000263c:	59fd                	li	s3,-1
    8000263e:	a089                	j	80002680 <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    80002640:	17048493          	addi	s1,s1,368
    80002644:	03348463          	beq	s1,s3,8000266c <wait+0xc8>
      if(np->parent == p){
    80002648:	749c                	ld	a5,40(s1)
    8000264a:	ff279be3          	bne	a5,s2,80002640 <wait+0x9c>
        acquire(&np->lock);
    8000264e:	8526                	mv	a0,s1
    80002650:	ffffe097          	auipc	ra,0xffffe
    80002654:	67c080e7          	jalr	1660(ra) # 80000ccc <acquire>
        if(np->state == ZOMBIE){
    80002658:	509c                	lw	a5,32(s1)
    8000265a:	f94787e3          	beq	a5,s4,800025e8 <wait+0x44>
        release(&np->lock);
    8000265e:	8526                	mv	a0,s1
    80002660:	ffffe097          	auipc	ra,0xffffe
    80002664:	73c080e7          	jalr	1852(ra) # 80000d9c <release>
        havekids = 1;
    80002668:	8756                	mv	a4,s5
    8000266a:	bfd9                	j	80002640 <wait+0x9c>
    if(!havekids || p->killed){
    8000266c:	c701                	beqz	a4,80002674 <wait+0xd0>
    8000266e:	03892783          	lw	a5,56(s2)
    80002672:	c39d                	beqz	a5,80002698 <wait+0xf4>
      release(&p->lock);
    80002674:	854a                	mv	a0,s2
    80002676:	ffffe097          	auipc	ra,0xffffe
    8000267a:	726080e7          	jalr	1830(ra) # 80000d9c <release>
      return -1;
    8000267e:	59fd                	li	s3,-1
}
    80002680:	854e                	mv	a0,s3
    80002682:	60a6                	ld	ra,72(sp)
    80002684:	6406                	ld	s0,64(sp)
    80002686:	74e2                	ld	s1,56(sp)
    80002688:	7942                	ld	s2,48(sp)
    8000268a:	79a2                	ld	s3,40(sp)
    8000268c:	7a02                	ld	s4,32(sp)
    8000268e:	6ae2                	ld	s5,24(sp)
    80002690:	6b42                	ld	s6,16(sp)
    80002692:	6ba2                	ld	s7,8(sp)
    80002694:	6161                	addi	sp,sp,80
    80002696:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002698:	85ca                	mv	a1,s2
    8000269a:	854a                	mv	a0,s2
    8000269c:	00000097          	auipc	ra,0x0
    800026a0:	e8a080e7          	jalr	-374(ra) # 80002526 <sleep>
    havekids = 0;
    800026a4:	bf25                	j	800025dc <wait+0x38>

00000000800026a6 <wakeup>:
{
    800026a6:	7139                	addi	sp,sp,-64
    800026a8:	fc06                	sd	ra,56(sp)
    800026aa:	f822                	sd	s0,48(sp)
    800026ac:	f426                	sd	s1,40(sp)
    800026ae:	f04a                	sd	s2,32(sp)
    800026b0:	ec4e                	sd	s3,24(sp)
    800026b2:	e852                	sd	s4,16(sp)
    800026b4:	e456                	sd	s5,8(sp)
    800026b6:	0080                	addi	s0,sp,64
    800026b8:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800026ba:	00010497          	auipc	s1,0x10
    800026be:	0ee48493          	addi	s1,s1,238 # 800127a8 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800026c2:	4985                	li	s3,1
      p->state = RUNNABLE;
    800026c4:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800026c6:	00016917          	auipc	s2,0x16
    800026ca:	ce290913          	addi	s2,s2,-798 # 800183a8 <tickslock>
    800026ce:	a811                	j	800026e2 <wakeup+0x3c>
    release(&p->lock);
    800026d0:	8526                	mv	a0,s1
    800026d2:	ffffe097          	auipc	ra,0xffffe
    800026d6:	6ca080e7          	jalr	1738(ra) # 80000d9c <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800026da:	17048493          	addi	s1,s1,368
    800026de:	03248063          	beq	s1,s2,800026fe <wakeup+0x58>
    acquire(&p->lock);
    800026e2:	8526                	mv	a0,s1
    800026e4:	ffffe097          	auipc	ra,0xffffe
    800026e8:	5e8080e7          	jalr	1512(ra) # 80000ccc <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800026ec:	509c                	lw	a5,32(s1)
    800026ee:	ff3791e3          	bne	a5,s3,800026d0 <wakeup+0x2a>
    800026f2:	789c                	ld	a5,48(s1)
    800026f4:	fd479ee3          	bne	a5,s4,800026d0 <wakeup+0x2a>
      p->state = RUNNABLE;
    800026f8:	0354a023          	sw	s5,32(s1)
    800026fc:	bfd1                	j	800026d0 <wakeup+0x2a>
}
    800026fe:	70e2                	ld	ra,56(sp)
    80002700:	7442                	ld	s0,48(sp)
    80002702:	74a2                	ld	s1,40(sp)
    80002704:	7902                	ld	s2,32(sp)
    80002706:	69e2                	ld	s3,24(sp)
    80002708:	6a42                	ld	s4,16(sp)
    8000270a:	6aa2                	ld	s5,8(sp)
    8000270c:	6121                	addi	sp,sp,64
    8000270e:	8082                	ret

0000000080002710 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002710:	7179                	addi	sp,sp,-48
    80002712:	f406                	sd	ra,40(sp)
    80002714:	f022                	sd	s0,32(sp)
    80002716:	ec26                	sd	s1,24(sp)
    80002718:	e84a                	sd	s2,16(sp)
    8000271a:	e44e                	sd	s3,8(sp)
    8000271c:	1800                	addi	s0,sp,48
    8000271e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002720:	00010497          	auipc	s1,0x10
    80002724:	08848493          	addi	s1,s1,136 # 800127a8 <proc>
    80002728:	00016997          	auipc	s3,0x16
    8000272c:	c8098993          	addi	s3,s3,-896 # 800183a8 <tickslock>
    acquire(&p->lock);
    80002730:	8526                	mv	a0,s1
    80002732:	ffffe097          	auipc	ra,0xffffe
    80002736:	59a080e7          	jalr	1434(ra) # 80000ccc <acquire>
    if(p->pid == pid){
    8000273a:	40bc                	lw	a5,64(s1)
    8000273c:	01278d63          	beq	a5,s2,80002756 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002740:	8526                	mv	a0,s1
    80002742:	ffffe097          	auipc	ra,0xffffe
    80002746:	65a080e7          	jalr	1626(ra) # 80000d9c <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000274a:	17048493          	addi	s1,s1,368
    8000274e:	ff3491e3          	bne	s1,s3,80002730 <kill+0x20>
  }
  return -1;
    80002752:	557d                	li	a0,-1
    80002754:	a821                	j	8000276c <kill+0x5c>
      p->killed = 1;
    80002756:	4785                	li	a5,1
    80002758:	dc9c                	sw	a5,56(s1)
      if(p->state == SLEEPING){
    8000275a:	5098                	lw	a4,32(s1)
    8000275c:	00f70f63          	beq	a4,a5,8000277a <kill+0x6a>
      release(&p->lock);
    80002760:	8526                	mv	a0,s1
    80002762:	ffffe097          	auipc	ra,0xffffe
    80002766:	63a080e7          	jalr	1594(ra) # 80000d9c <release>
      return 0;
    8000276a:	4501                	li	a0,0
}
    8000276c:	70a2                	ld	ra,40(sp)
    8000276e:	7402                	ld	s0,32(sp)
    80002770:	64e2                	ld	s1,24(sp)
    80002772:	6942                	ld	s2,16(sp)
    80002774:	69a2                	ld	s3,8(sp)
    80002776:	6145                	addi	sp,sp,48
    80002778:	8082                	ret
        p->state = RUNNABLE;
    8000277a:	4789                	li	a5,2
    8000277c:	d09c                	sw	a5,32(s1)
    8000277e:	b7cd                	j	80002760 <kill+0x50>

0000000080002780 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002780:	7179                	addi	sp,sp,-48
    80002782:	f406                	sd	ra,40(sp)
    80002784:	f022                	sd	s0,32(sp)
    80002786:	ec26                	sd	s1,24(sp)
    80002788:	e84a                	sd	s2,16(sp)
    8000278a:	e44e                	sd	s3,8(sp)
    8000278c:	e052                	sd	s4,0(sp)
    8000278e:	1800                	addi	s0,sp,48
    80002790:	84aa                	mv	s1,a0
    80002792:	892e                	mv	s2,a1
    80002794:	89b2                	mv	s3,a2
    80002796:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002798:	fffff097          	auipc	ra,0xfffff
    8000279c:	57a080e7          	jalr	1402(ra) # 80001d12 <myproc>
  if(user_dst){
    800027a0:	c08d                	beqz	s1,800027c2 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800027a2:	86d2                	mv	a3,s4
    800027a4:	864e                	mv	a2,s3
    800027a6:	85ca                	mv	a1,s2
    800027a8:	6d28                	ld	a0,88(a0)
    800027aa:	fffff097          	auipc	ra,0xfffff
    800027ae:	25a080e7          	jalr	602(ra) # 80001a04 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027b2:	70a2                	ld	ra,40(sp)
    800027b4:	7402                	ld	s0,32(sp)
    800027b6:	64e2                	ld	s1,24(sp)
    800027b8:	6942                	ld	s2,16(sp)
    800027ba:	69a2                	ld	s3,8(sp)
    800027bc:	6a02                	ld	s4,0(sp)
    800027be:	6145                	addi	sp,sp,48
    800027c0:	8082                	ret
    memmove((char *)dst, src, len);
    800027c2:	000a061b          	sext.w	a2,s4
    800027c6:	85ce                	mv	a1,s3
    800027c8:	854a                	mv	a0,s2
    800027ca:	fffff097          	auipc	ra,0xfffff
    800027ce:	93e080e7          	jalr	-1730(ra) # 80001108 <memmove>
    return 0;
    800027d2:	8526                	mv	a0,s1
    800027d4:	bff9                	j	800027b2 <either_copyout+0x32>

00000000800027d6 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027d6:	7179                	addi	sp,sp,-48
    800027d8:	f406                	sd	ra,40(sp)
    800027da:	f022                	sd	s0,32(sp)
    800027dc:	ec26                	sd	s1,24(sp)
    800027de:	e84a                	sd	s2,16(sp)
    800027e0:	e44e                	sd	s3,8(sp)
    800027e2:	e052                	sd	s4,0(sp)
    800027e4:	1800                	addi	s0,sp,48
    800027e6:	892a                	mv	s2,a0
    800027e8:	84ae                	mv	s1,a1
    800027ea:	89b2                	mv	s3,a2
    800027ec:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027ee:	fffff097          	auipc	ra,0xfffff
    800027f2:	524080e7          	jalr	1316(ra) # 80001d12 <myproc>
  if(user_src){
    800027f6:	c08d                	beqz	s1,80002818 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800027f8:	86d2                	mv	a3,s4
    800027fa:	864e                	mv	a2,s3
    800027fc:	85ca                	mv	a1,s2
    800027fe:	6d28                	ld	a0,88(a0)
    80002800:	fffff097          	auipc	ra,0xfffff
    80002804:	290080e7          	jalr	656(ra) # 80001a90 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002808:	70a2                	ld	ra,40(sp)
    8000280a:	7402                	ld	s0,32(sp)
    8000280c:	64e2                	ld	s1,24(sp)
    8000280e:	6942                	ld	s2,16(sp)
    80002810:	69a2                	ld	s3,8(sp)
    80002812:	6a02                	ld	s4,0(sp)
    80002814:	6145                	addi	sp,sp,48
    80002816:	8082                	ret
    memmove(dst, (char*)src, len);
    80002818:	000a061b          	sext.w	a2,s4
    8000281c:	85ce                	mv	a1,s3
    8000281e:	854a                	mv	a0,s2
    80002820:	fffff097          	auipc	ra,0xfffff
    80002824:	8e8080e7          	jalr	-1816(ra) # 80001108 <memmove>
    return 0;
    80002828:	8526                	mv	a0,s1
    8000282a:	bff9                	j	80002808 <either_copyin+0x32>

000000008000282c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000282c:	715d                	addi	sp,sp,-80
    8000282e:	e486                	sd	ra,72(sp)
    80002830:	e0a2                	sd	s0,64(sp)
    80002832:	fc26                	sd	s1,56(sp)
    80002834:	f84a                	sd	s2,48(sp)
    80002836:	f44e                	sd	s3,40(sp)
    80002838:	f052                	sd	s4,32(sp)
    8000283a:	ec56                	sd	s5,24(sp)
    8000283c:	e85a                	sd	s6,16(sp)
    8000283e:	e45e                	sd	s7,8(sp)
    80002840:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002842:	00006517          	auipc	a0,0x6
    80002846:	91e50513          	addi	a0,a0,-1762 # 80008160 <digits+0x120>
    8000284a:	ffffe097          	auipc	ra,0xffffe
    8000284e:	d4a080e7          	jalr	-694(ra) # 80000594 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002852:	00010497          	auipc	s1,0x10
    80002856:	0b648493          	addi	s1,s1,182 # 80012908 <proc+0x160>
    8000285a:	00016917          	auipc	s2,0x16
    8000285e:	cae90913          	addi	s2,s2,-850 # 80018508 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002862:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002864:	00006997          	auipc	s3,0x6
    80002868:	a9498993          	addi	s3,s3,-1388 # 800082f8 <digits+0x2b8>
    printf("%d %s %s", p->pid, state, p->name);
    8000286c:	00006a97          	auipc	s5,0x6
    80002870:	a94a8a93          	addi	s5,s5,-1388 # 80008300 <digits+0x2c0>
    printf("\n");
    80002874:	00006a17          	auipc	s4,0x6
    80002878:	8eca0a13          	addi	s4,s4,-1812 # 80008160 <digits+0x120>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000287c:	00006b97          	auipc	s7,0x6
    80002880:	abcb8b93          	addi	s7,s7,-1348 # 80008338 <states.0>
    80002884:	a00d                	j	800028a6 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002886:	ee06a583          	lw	a1,-288(a3)
    8000288a:	8556                	mv	a0,s5
    8000288c:	ffffe097          	auipc	ra,0xffffe
    80002890:	d08080e7          	jalr	-760(ra) # 80000594 <printf>
    printf("\n");
    80002894:	8552                	mv	a0,s4
    80002896:	ffffe097          	auipc	ra,0xffffe
    8000289a:	cfe080e7          	jalr	-770(ra) # 80000594 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000289e:	17048493          	addi	s1,s1,368
    800028a2:	03248163          	beq	s1,s2,800028c4 <procdump+0x98>
    if(p->state == UNUSED)
    800028a6:	86a6                	mv	a3,s1
    800028a8:	ec04a783          	lw	a5,-320(s1)
    800028ac:	dbed                	beqz	a5,8000289e <procdump+0x72>
      state = "???";
    800028ae:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028b0:	fcfb6be3          	bltu	s6,a5,80002886 <procdump+0x5a>
    800028b4:	1782                	slli	a5,a5,0x20
    800028b6:	9381                	srli	a5,a5,0x20
    800028b8:	078e                	slli	a5,a5,0x3
    800028ba:	97de                	add	a5,a5,s7
    800028bc:	6390                	ld	a2,0(a5)
    800028be:	f661                	bnez	a2,80002886 <procdump+0x5a>
      state = "???";
    800028c0:	864e                	mv	a2,s3
    800028c2:	b7d1                	j	80002886 <procdump+0x5a>
  }
}
    800028c4:	60a6                	ld	ra,72(sp)
    800028c6:	6406                	ld	s0,64(sp)
    800028c8:	74e2                	ld	s1,56(sp)
    800028ca:	7942                	ld	s2,48(sp)
    800028cc:	79a2                	ld	s3,40(sp)
    800028ce:	7a02                	ld	s4,32(sp)
    800028d0:	6ae2                	ld	s5,24(sp)
    800028d2:	6b42                	ld	s6,16(sp)
    800028d4:	6ba2                	ld	s7,8(sp)
    800028d6:	6161                	addi	sp,sp,80
    800028d8:	8082                	ret

00000000800028da <swtch>:
    800028da:	00153023          	sd	ra,0(a0)
    800028de:	00253423          	sd	sp,8(a0)
    800028e2:	e900                	sd	s0,16(a0)
    800028e4:	ed04                	sd	s1,24(a0)
    800028e6:	03253023          	sd	s2,32(a0)
    800028ea:	03353423          	sd	s3,40(a0)
    800028ee:	03453823          	sd	s4,48(a0)
    800028f2:	03553c23          	sd	s5,56(a0)
    800028f6:	05653023          	sd	s6,64(a0)
    800028fa:	05753423          	sd	s7,72(a0)
    800028fe:	05853823          	sd	s8,80(a0)
    80002902:	05953c23          	sd	s9,88(a0)
    80002906:	07a53023          	sd	s10,96(a0)
    8000290a:	07b53423          	sd	s11,104(a0)
    8000290e:	0005b083          	ld	ra,0(a1)
    80002912:	0085b103          	ld	sp,8(a1)
    80002916:	6980                	ld	s0,16(a1)
    80002918:	6d84                	ld	s1,24(a1)
    8000291a:	0205b903          	ld	s2,32(a1)
    8000291e:	0285b983          	ld	s3,40(a1)
    80002922:	0305ba03          	ld	s4,48(a1)
    80002926:	0385ba83          	ld	s5,56(a1)
    8000292a:	0405bb03          	ld	s6,64(a1)
    8000292e:	0485bb83          	ld	s7,72(a1)
    80002932:	0505bc03          	ld	s8,80(a1)
    80002936:	0585bc83          	ld	s9,88(a1)
    8000293a:	0605bd03          	ld	s10,96(a1)
    8000293e:	0685bd83          	ld	s11,104(a1)
    80002942:	8082                	ret

0000000080002944 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002944:	1141                	addi	sp,sp,-16
    80002946:	e406                	sd	ra,8(sp)
    80002948:	e022                	sd	s0,0(sp)
    8000294a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000294c:	00006597          	auipc	a1,0x6
    80002950:	a1458593          	addi	a1,a1,-1516 # 80008360 <states.0+0x28>
    80002954:	00016517          	auipc	a0,0x16
    80002958:	a5450513          	addi	a0,a0,-1452 # 800183a8 <tickslock>
    8000295c:	ffffe097          	auipc	ra,0xffffe
    80002960:	4ec080e7          	jalr	1260(ra) # 80000e48 <initlock>
}
    80002964:	60a2                	ld	ra,8(sp)
    80002966:	6402                	ld	s0,0(sp)
    80002968:	0141                	addi	sp,sp,16
    8000296a:	8082                	ret

000000008000296c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000296c:	1141                	addi	sp,sp,-16
    8000296e:	e422                	sd	s0,8(sp)
    80002970:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002972:	00003797          	auipc	a5,0x3
    80002976:	64e78793          	addi	a5,a5,1614 # 80005fc0 <kernelvec>
    8000297a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000297e:	6422                	ld	s0,8(sp)
    80002980:	0141                	addi	sp,sp,16
    80002982:	8082                	ret

0000000080002984 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002984:	1141                	addi	sp,sp,-16
    80002986:	e406                	sd	ra,8(sp)
    80002988:	e022                	sd	s0,0(sp)
    8000298a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000298c:	fffff097          	auipc	ra,0xfffff
    80002990:	386080e7          	jalr	902(ra) # 80001d12 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002994:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002998:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000299a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000299e:	00004617          	auipc	a2,0x4
    800029a2:	66260613          	addi	a2,a2,1634 # 80007000 <_trampoline>
    800029a6:	00004697          	auipc	a3,0x4
    800029aa:	65a68693          	addi	a3,a3,1626 # 80007000 <_trampoline>
    800029ae:	8e91                	sub	a3,a3,a2
    800029b0:	040007b7          	lui	a5,0x4000
    800029b4:	17fd                	addi	a5,a5,-1
    800029b6:	07b2                	slli	a5,a5,0xc
    800029b8:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029ba:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029be:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029c0:	180026f3          	csrr	a3,satp
    800029c4:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029c6:	7138                	ld	a4,96(a0)
    800029c8:	6534                	ld	a3,72(a0)
    800029ca:	6585                	lui	a1,0x1
    800029cc:	96ae                	add	a3,a3,a1
    800029ce:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029d0:	7138                	ld	a4,96(a0)
    800029d2:	00000697          	auipc	a3,0x0
    800029d6:	13868693          	addi	a3,a3,312 # 80002b0a <usertrap>
    800029da:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029dc:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029de:	8692                	mv	a3,tp
    800029e0:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029e2:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029e6:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029ea:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ee:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029f2:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029f4:	6f18                	ld	a4,24(a4)
    800029f6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029fa:	6d2c                	ld	a1,88(a0)
    800029fc:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800029fe:	00004717          	auipc	a4,0x4
    80002a02:	69270713          	addi	a4,a4,1682 # 80007090 <userret>
    80002a06:	8f11                	sub	a4,a4,a2
    80002a08:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a0a:	577d                	li	a4,-1
    80002a0c:	177e                	slli	a4,a4,0x3f
    80002a0e:	8dd9                	or	a1,a1,a4
    80002a10:	02000537          	lui	a0,0x2000
    80002a14:	157d                	addi	a0,a0,-1
    80002a16:	0536                	slli	a0,a0,0xd
    80002a18:	9782                	jalr	a5
}
    80002a1a:	60a2                	ld	ra,8(sp)
    80002a1c:	6402                	ld	s0,0(sp)
    80002a1e:	0141                	addi	sp,sp,16
    80002a20:	8082                	ret

0000000080002a22 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a22:	1101                	addi	sp,sp,-32
    80002a24:	ec06                	sd	ra,24(sp)
    80002a26:	e822                	sd	s0,16(sp)
    80002a28:	e426                	sd	s1,8(sp)
    80002a2a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a2c:	00016497          	auipc	s1,0x16
    80002a30:	97c48493          	addi	s1,s1,-1668 # 800183a8 <tickslock>
    80002a34:	8526                	mv	a0,s1
    80002a36:	ffffe097          	auipc	ra,0xffffe
    80002a3a:	296080e7          	jalr	662(ra) # 80000ccc <acquire>
  ticks++;
    80002a3e:	00006517          	auipc	a0,0x6
    80002a42:	5e250513          	addi	a0,a0,1506 # 80009020 <ticks>
    80002a46:	411c                	lw	a5,0(a0)
    80002a48:	2785                	addiw	a5,a5,1
    80002a4a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a4c:	00000097          	auipc	ra,0x0
    80002a50:	c5a080e7          	jalr	-934(ra) # 800026a6 <wakeup>
  release(&tickslock);
    80002a54:	8526                	mv	a0,s1
    80002a56:	ffffe097          	auipc	ra,0xffffe
    80002a5a:	346080e7          	jalr	838(ra) # 80000d9c <release>
}
    80002a5e:	60e2                	ld	ra,24(sp)
    80002a60:	6442                	ld	s0,16(sp)
    80002a62:	64a2                	ld	s1,8(sp)
    80002a64:	6105                	addi	sp,sp,32
    80002a66:	8082                	ret

0000000080002a68 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a68:	1101                	addi	sp,sp,-32
    80002a6a:	ec06                	sd	ra,24(sp)
    80002a6c:	e822                	sd	s0,16(sp)
    80002a6e:	e426                	sd	s1,8(sp)
    80002a70:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a72:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a76:	00074d63          	bltz	a4,80002a90 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a7a:	57fd                	li	a5,-1
    80002a7c:	17fe                	slli	a5,a5,0x3f
    80002a7e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a80:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a82:	06f70363          	beq	a4,a5,80002ae8 <devintr+0x80>
  }
}
    80002a86:	60e2                	ld	ra,24(sp)
    80002a88:	6442                	ld	s0,16(sp)
    80002a8a:	64a2                	ld	s1,8(sp)
    80002a8c:	6105                	addi	sp,sp,32
    80002a8e:	8082                	ret
     (scause & 0xff) == 9){
    80002a90:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a94:	46a5                	li	a3,9
    80002a96:	fed792e3          	bne	a5,a3,80002a7a <devintr+0x12>
    int irq = plic_claim();
    80002a9a:	00003097          	auipc	ra,0x3
    80002a9e:	62e080e7          	jalr	1582(ra) # 800060c8 <plic_claim>
    80002aa2:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002aa4:	47a9                	li	a5,10
    80002aa6:	02f50763          	beq	a0,a5,80002ad4 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002aaa:	4785                	li	a5,1
    80002aac:	02f50963          	beq	a0,a5,80002ade <devintr+0x76>
    return 1;
    80002ab0:	4505                	li	a0,1
    } else if(irq){
    80002ab2:	d8f1                	beqz	s1,80002a86 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ab4:	85a6                	mv	a1,s1
    80002ab6:	00006517          	auipc	a0,0x6
    80002aba:	8b250513          	addi	a0,a0,-1870 # 80008368 <states.0+0x30>
    80002abe:	ffffe097          	auipc	ra,0xffffe
    80002ac2:	ad6080e7          	jalr	-1322(ra) # 80000594 <printf>
      plic_complete(irq);
    80002ac6:	8526                	mv	a0,s1
    80002ac8:	00003097          	auipc	ra,0x3
    80002acc:	624080e7          	jalr	1572(ra) # 800060ec <plic_complete>
    return 1;
    80002ad0:	4505                	li	a0,1
    80002ad2:	bf55                	j	80002a86 <devintr+0x1e>
      uartintr();
    80002ad4:	ffffe097          	auipc	ra,0xffffe
    80002ad8:	ef6080e7          	jalr	-266(ra) # 800009ca <uartintr>
    80002adc:	b7ed                	j	80002ac6 <devintr+0x5e>
      virtio_disk_intr();
    80002ade:	00004097          	auipc	ra,0x4
    80002ae2:	aa0080e7          	jalr	-1376(ra) # 8000657e <virtio_disk_intr>
    80002ae6:	b7c5                	j	80002ac6 <devintr+0x5e>
    if(cpuid() == 0){
    80002ae8:	fffff097          	auipc	ra,0xfffff
    80002aec:	1fe080e7          	jalr	510(ra) # 80001ce6 <cpuid>
    80002af0:	c901                	beqz	a0,80002b00 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002af2:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002af6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002af8:	14479073          	csrw	sip,a5
    return 2;
    80002afc:	4509                	li	a0,2
    80002afe:	b761                	j	80002a86 <devintr+0x1e>
      clockintr();
    80002b00:	00000097          	auipc	ra,0x0
    80002b04:	f22080e7          	jalr	-222(ra) # 80002a22 <clockintr>
    80002b08:	b7ed                	j	80002af2 <devintr+0x8a>

0000000080002b0a <usertrap>:
{
    80002b0a:	1101                	addi	sp,sp,-32
    80002b0c:	ec06                	sd	ra,24(sp)
    80002b0e:	e822                	sd	s0,16(sp)
    80002b10:	e426                	sd	s1,8(sp)
    80002b12:	e04a                	sd	s2,0(sp)
    80002b14:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b16:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b1a:	1007f793          	andi	a5,a5,256
    80002b1e:	e3ad                	bnez	a5,80002b80 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b20:	00003797          	auipc	a5,0x3
    80002b24:	4a078793          	addi	a5,a5,1184 # 80005fc0 <kernelvec>
    80002b28:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b2c:	fffff097          	auipc	ra,0xfffff
    80002b30:	1e6080e7          	jalr	486(ra) # 80001d12 <myproc>
    80002b34:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b36:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b38:	14102773          	csrr	a4,sepc
    80002b3c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b3e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b42:	47a1                	li	a5,8
    80002b44:	04f71c63          	bne	a4,a5,80002b9c <usertrap+0x92>
    if(p->killed)
    80002b48:	5d1c                	lw	a5,56(a0)
    80002b4a:	e3b9                	bnez	a5,80002b90 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b4c:	70b8                	ld	a4,96(s1)
    80002b4e:	6f1c                	ld	a5,24(a4)
    80002b50:	0791                	addi	a5,a5,4
    80002b52:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b54:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b58:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b5c:	10079073          	csrw	sstatus,a5
    syscall();
    80002b60:	00000097          	auipc	ra,0x0
    80002b64:	2e0080e7          	jalr	736(ra) # 80002e40 <syscall>
  if(p->killed)
    80002b68:	5c9c                	lw	a5,56(s1)
    80002b6a:	ebc1                	bnez	a5,80002bfa <usertrap+0xf0>
  usertrapret();
    80002b6c:	00000097          	auipc	ra,0x0
    80002b70:	e18080e7          	jalr	-488(ra) # 80002984 <usertrapret>
}
    80002b74:	60e2                	ld	ra,24(sp)
    80002b76:	6442                	ld	s0,16(sp)
    80002b78:	64a2                	ld	s1,8(sp)
    80002b7a:	6902                	ld	s2,0(sp)
    80002b7c:	6105                	addi	sp,sp,32
    80002b7e:	8082                	ret
    panic("usertrap: not from user mode");
    80002b80:	00006517          	auipc	a0,0x6
    80002b84:	80850513          	addi	a0,a0,-2040 # 80008388 <states.0+0x50>
    80002b88:	ffffe097          	auipc	ra,0xffffe
    80002b8c:	9c2080e7          	jalr	-1598(ra) # 8000054a <panic>
      exit(-1);
    80002b90:	557d                	li	a0,-1
    80002b92:	00000097          	auipc	ra,0x0
    80002b96:	84e080e7          	jalr	-1970(ra) # 800023e0 <exit>
    80002b9a:	bf4d                	j	80002b4c <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002b9c:	00000097          	auipc	ra,0x0
    80002ba0:	ecc080e7          	jalr	-308(ra) # 80002a68 <devintr>
    80002ba4:	892a                	mv	s2,a0
    80002ba6:	c501                	beqz	a0,80002bae <usertrap+0xa4>
  if(p->killed)
    80002ba8:	5c9c                	lw	a5,56(s1)
    80002baa:	c3a1                	beqz	a5,80002bea <usertrap+0xe0>
    80002bac:	a815                	j	80002be0 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bae:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002bb2:	40b0                	lw	a2,64(s1)
    80002bb4:	00005517          	auipc	a0,0x5
    80002bb8:	7f450513          	addi	a0,a0,2036 # 800083a8 <states.0+0x70>
    80002bbc:	ffffe097          	auipc	ra,0xffffe
    80002bc0:	9d8080e7          	jalr	-1576(ra) # 80000594 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bc4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bc8:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bcc:	00006517          	auipc	a0,0x6
    80002bd0:	80c50513          	addi	a0,a0,-2036 # 800083d8 <states.0+0xa0>
    80002bd4:	ffffe097          	auipc	ra,0xffffe
    80002bd8:	9c0080e7          	jalr	-1600(ra) # 80000594 <printf>
    p->killed = 1;
    80002bdc:	4785                	li	a5,1
    80002bde:	dc9c                	sw	a5,56(s1)
    exit(-1);
    80002be0:	557d                	li	a0,-1
    80002be2:	fffff097          	auipc	ra,0xfffff
    80002be6:	7fe080e7          	jalr	2046(ra) # 800023e0 <exit>
  if(which_dev == 2)
    80002bea:	4789                	li	a5,2
    80002bec:	f8f910e3          	bne	s2,a5,80002b6c <usertrap+0x62>
    yield();
    80002bf0:	00000097          	auipc	ra,0x0
    80002bf4:	8fa080e7          	jalr	-1798(ra) # 800024ea <yield>
    80002bf8:	bf95                	j	80002b6c <usertrap+0x62>
  int which_dev = 0;
    80002bfa:	4901                	li	s2,0
    80002bfc:	b7d5                	j	80002be0 <usertrap+0xd6>

0000000080002bfe <kerneltrap>:
{
    80002bfe:	7179                	addi	sp,sp,-48
    80002c00:	f406                	sd	ra,40(sp)
    80002c02:	f022                	sd	s0,32(sp)
    80002c04:	ec26                	sd	s1,24(sp)
    80002c06:	e84a                	sd	s2,16(sp)
    80002c08:	e44e                	sd	s3,8(sp)
    80002c0a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c0c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c10:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c14:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c18:	1004f793          	andi	a5,s1,256
    80002c1c:	cb85                	beqz	a5,80002c4c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c1e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c22:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c24:	ef85                	bnez	a5,80002c5c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c26:	00000097          	auipc	ra,0x0
    80002c2a:	e42080e7          	jalr	-446(ra) # 80002a68 <devintr>
    80002c2e:	cd1d                	beqz	a0,80002c6c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c30:	4789                	li	a5,2
    80002c32:	06f50a63          	beq	a0,a5,80002ca6 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c36:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c3a:	10049073          	csrw	sstatus,s1
}
    80002c3e:	70a2                	ld	ra,40(sp)
    80002c40:	7402                	ld	s0,32(sp)
    80002c42:	64e2                	ld	s1,24(sp)
    80002c44:	6942                	ld	s2,16(sp)
    80002c46:	69a2                	ld	s3,8(sp)
    80002c48:	6145                	addi	sp,sp,48
    80002c4a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c4c:	00005517          	auipc	a0,0x5
    80002c50:	7ac50513          	addi	a0,a0,1964 # 800083f8 <states.0+0xc0>
    80002c54:	ffffe097          	auipc	ra,0xffffe
    80002c58:	8f6080e7          	jalr	-1802(ra) # 8000054a <panic>
    panic("kerneltrap: interrupts enabled");
    80002c5c:	00005517          	auipc	a0,0x5
    80002c60:	7c450513          	addi	a0,a0,1988 # 80008420 <states.0+0xe8>
    80002c64:	ffffe097          	auipc	ra,0xffffe
    80002c68:	8e6080e7          	jalr	-1818(ra) # 8000054a <panic>
    printf("scause %p\n", scause);
    80002c6c:	85ce                	mv	a1,s3
    80002c6e:	00005517          	auipc	a0,0x5
    80002c72:	7d250513          	addi	a0,a0,2002 # 80008440 <states.0+0x108>
    80002c76:	ffffe097          	auipc	ra,0xffffe
    80002c7a:	91e080e7          	jalr	-1762(ra) # 80000594 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c7e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c82:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c86:	00005517          	auipc	a0,0x5
    80002c8a:	7ca50513          	addi	a0,a0,1994 # 80008450 <states.0+0x118>
    80002c8e:	ffffe097          	auipc	ra,0xffffe
    80002c92:	906080e7          	jalr	-1786(ra) # 80000594 <printf>
    panic("kerneltrap");
    80002c96:	00005517          	auipc	a0,0x5
    80002c9a:	7d250513          	addi	a0,a0,2002 # 80008468 <states.0+0x130>
    80002c9e:	ffffe097          	auipc	ra,0xffffe
    80002ca2:	8ac080e7          	jalr	-1876(ra) # 8000054a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ca6:	fffff097          	auipc	ra,0xfffff
    80002caa:	06c080e7          	jalr	108(ra) # 80001d12 <myproc>
    80002cae:	d541                	beqz	a0,80002c36 <kerneltrap+0x38>
    80002cb0:	fffff097          	auipc	ra,0xfffff
    80002cb4:	062080e7          	jalr	98(ra) # 80001d12 <myproc>
    80002cb8:	5118                	lw	a4,32(a0)
    80002cba:	478d                	li	a5,3
    80002cbc:	f6f71de3          	bne	a4,a5,80002c36 <kerneltrap+0x38>
    yield();
    80002cc0:	00000097          	auipc	ra,0x0
    80002cc4:	82a080e7          	jalr	-2006(ra) # 800024ea <yield>
    80002cc8:	b7bd                	j	80002c36 <kerneltrap+0x38>

0000000080002cca <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002cca:	1101                	addi	sp,sp,-32
    80002ccc:	ec06                	sd	ra,24(sp)
    80002cce:	e822                	sd	s0,16(sp)
    80002cd0:	e426                	sd	s1,8(sp)
    80002cd2:	1000                	addi	s0,sp,32
    80002cd4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002cd6:	fffff097          	auipc	ra,0xfffff
    80002cda:	03c080e7          	jalr	60(ra) # 80001d12 <myproc>
  switch (n) {
    80002cde:	4795                	li	a5,5
    80002ce0:	0497e163          	bltu	a5,s1,80002d22 <argraw+0x58>
    80002ce4:	048a                	slli	s1,s1,0x2
    80002ce6:	00005717          	auipc	a4,0x5
    80002cea:	7ba70713          	addi	a4,a4,1978 # 800084a0 <states.0+0x168>
    80002cee:	94ba                	add	s1,s1,a4
    80002cf0:	409c                	lw	a5,0(s1)
    80002cf2:	97ba                	add	a5,a5,a4
    80002cf4:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002cf6:	713c                	ld	a5,96(a0)
    80002cf8:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002cfa:	60e2                	ld	ra,24(sp)
    80002cfc:	6442                	ld	s0,16(sp)
    80002cfe:	64a2                	ld	s1,8(sp)
    80002d00:	6105                	addi	sp,sp,32
    80002d02:	8082                	ret
    return p->trapframe->a1;
    80002d04:	713c                	ld	a5,96(a0)
    80002d06:	7fa8                	ld	a0,120(a5)
    80002d08:	bfcd                	j	80002cfa <argraw+0x30>
    return p->trapframe->a2;
    80002d0a:	713c                	ld	a5,96(a0)
    80002d0c:	63c8                	ld	a0,128(a5)
    80002d0e:	b7f5                	j	80002cfa <argraw+0x30>
    return p->trapframe->a3;
    80002d10:	713c                	ld	a5,96(a0)
    80002d12:	67c8                	ld	a0,136(a5)
    80002d14:	b7dd                	j	80002cfa <argraw+0x30>
    return p->trapframe->a4;
    80002d16:	713c                	ld	a5,96(a0)
    80002d18:	6bc8                	ld	a0,144(a5)
    80002d1a:	b7c5                	j	80002cfa <argraw+0x30>
    return p->trapframe->a5;
    80002d1c:	713c                	ld	a5,96(a0)
    80002d1e:	6fc8                	ld	a0,152(a5)
    80002d20:	bfe9                	j	80002cfa <argraw+0x30>
  panic("argraw");
    80002d22:	00005517          	auipc	a0,0x5
    80002d26:	75650513          	addi	a0,a0,1878 # 80008478 <states.0+0x140>
    80002d2a:	ffffe097          	auipc	ra,0xffffe
    80002d2e:	820080e7          	jalr	-2016(ra) # 8000054a <panic>

0000000080002d32 <fetchaddr>:
{
    80002d32:	1101                	addi	sp,sp,-32
    80002d34:	ec06                	sd	ra,24(sp)
    80002d36:	e822                	sd	s0,16(sp)
    80002d38:	e426                	sd	s1,8(sp)
    80002d3a:	e04a                	sd	s2,0(sp)
    80002d3c:	1000                	addi	s0,sp,32
    80002d3e:	84aa                	mv	s1,a0
    80002d40:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d42:	fffff097          	auipc	ra,0xfffff
    80002d46:	fd0080e7          	jalr	-48(ra) # 80001d12 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d4a:	693c                	ld	a5,80(a0)
    80002d4c:	02f4f863          	bgeu	s1,a5,80002d7c <fetchaddr+0x4a>
    80002d50:	00848713          	addi	a4,s1,8
    80002d54:	02e7e663          	bltu	a5,a4,80002d80 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d58:	46a1                	li	a3,8
    80002d5a:	8626                	mv	a2,s1
    80002d5c:	85ca                	mv	a1,s2
    80002d5e:	6d28                	ld	a0,88(a0)
    80002d60:	fffff097          	auipc	ra,0xfffff
    80002d64:	d30080e7          	jalr	-720(ra) # 80001a90 <copyin>
    80002d68:	00a03533          	snez	a0,a0
    80002d6c:	40a00533          	neg	a0,a0
}
    80002d70:	60e2                	ld	ra,24(sp)
    80002d72:	6442                	ld	s0,16(sp)
    80002d74:	64a2                	ld	s1,8(sp)
    80002d76:	6902                	ld	s2,0(sp)
    80002d78:	6105                	addi	sp,sp,32
    80002d7a:	8082                	ret
    return -1;
    80002d7c:	557d                	li	a0,-1
    80002d7e:	bfcd                	j	80002d70 <fetchaddr+0x3e>
    80002d80:	557d                	li	a0,-1
    80002d82:	b7fd                	j	80002d70 <fetchaddr+0x3e>

0000000080002d84 <fetchstr>:
{
    80002d84:	7179                	addi	sp,sp,-48
    80002d86:	f406                	sd	ra,40(sp)
    80002d88:	f022                	sd	s0,32(sp)
    80002d8a:	ec26                	sd	s1,24(sp)
    80002d8c:	e84a                	sd	s2,16(sp)
    80002d8e:	e44e                	sd	s3,8(sp)
    80002d90:	1800                	addi	s0,sp,48
    80002d92:	892a                	mv	s2,a0
    80002d94:	84ae                	mv	s1,a1
    80002d96:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d98:	fffff097          	auipc	ra,0xfffff
    80002d9c:	f7a080e7          	jalr	-134(ra) # 80001d12 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002da0:	86ce                	mv	a3,s3
    80002da2:	864a                	mv	a2,s2
    80002da4:	85a6                	mv	a1,s1
    80002da6:	6d28                	ld	a0,88(a0)
    80002da8:	fffff097          	auipc	ra,0xfffff
    80002dac:	d76080e7          	jalr	-650(ra) # 80001b1e <copyinstr>
  if(err < 0)
    80002db0:	00054763          	bltz	a0,80002dbe <fetchstr+0x3a>
  return strlen(buf);
    80002db4:	8526                	mv	a0,s1
    80002db6:	ffffe097          	auipc	ra,0xffffe
    80002dba:	47a080e7          	jalr	1146(ra) # 80001230 <strlen>
}
    80002dbe:	70a2                	ld	ra,40(sp)
    80002dc0:	7402                	ld	s0,32(sp)
    80002dc2:	64e2                	ld	s1,24(sp)
    80002dc4:	6942                	ld	s2,16(sp)
    80002dc6:	69a2                	ld	s3,8(sp)
    80002dc8:	6145                	addi	sp,sp,48
    80002dca:	8082                	ret

0000000080002dcc <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002dcc:	1101                	addi	sp,sp,-32
    80002dce:	ec06                	sd	ra,24(sp)
    80002dd0:	e822                	sd	s0,16(sp)
    80002dd2:	e426                	sd	s1,8(sp)
    80002dd4:	1000                	addi	s0,sp,32
    80002dd6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dd8:	00000097          	auipc	ra,0x0
    80002ddc:	ef2080e7          	jalr	-270(ra) # 80002cca <argraw>
    80002de0:	c088                	sw	a0,0(s1)
  return 0;
}
    80002de2:	4501                	li	a0,0
    80002de4:	60e2                	ld	ra,24(sp)
    80002de6:	6442                	ld	s0,16(sp)
    80002de8:	64a2                	ld	s1,8(sp)
    80002dea:	6105                	addi	sp,sp,32
    80002dec:	8082                	ret

0000000080002dee <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002dee:	1101                	addi	sp,sp,-32
    80002df0:	ec06                	sd	ra,24(sp)
    80002df2:	e822                	sd	s0,16(sp)
    80002df4:	e426                	sd	s1,8(sp)
    80002df6:	1000                	addi	s0,sp,32
    80002df8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dfa:	00000097          	auipc	ra,0x0
    80002dfe:	ed0080e7          	jalr	-304(ra) # 80002cca <argraw>
    80002e02:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e04:	4501                	li	a0,0
    80002e06:	60e2                	ld	ra,24(sp)
    80002e08:	6442                	ld	s0,16(sp)
    80002e0a:	64a2                	ld	s1,8(sp)
    80002e0c:	6105                	addi	sp,sp,32
    80002e0e:	8082                	ret

0000000080002e10 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e10:	1101                	addi	sp,sp,-32
    80002e12:	ec06                	sd	ra,24(sp)
    80002e14:	e822                	sd	s0,16(sp)
    80002e16:	e426                	sd	s1,8(sp)
    80002e18:	e04a                	sd	s2,0(sp)
    80002e1a:	1000                	addi	s0,sp,32
    80002e1c:	84ae                	mv	s1,a1
    80002e1e:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e20:	00000097          	auipc	ra,0x0
    80002e24:	eaa080e7          	jalr	-342(ra) # 80002cca <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e28:	864a                	mv	a2,s2
    80002e2a:	85a6                	mv	a1,s1
    80002e2c:	00000097          	auipc	ra,0x0
    80002e30:	f58080e7          	jalr	-168(ra) # 80002d84 <fetchstr>
}
    80002e34:	60e2                	ld	ra,24(sp)
    80002e36:	6442                	ld	s0,16(sp)
    80002e38:	64a2                	ld	s1,8(sp)
    80002e3a:	6902                	ld	s2,0(sp)
    80002e3c:	6105                	addi	sp,sp,32
    80002e3e:	8082                	ret

0000000080002e40 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002e40:	1101                	addi	sp,sp,-32
    80002e42:	ec06                	sd	ra,24(sp)
    80002e44:	e822                	sd	s0,16(sp)
    80002e46:	e426                	sd	s1,8(sp)
    80002e48:	e04a                	sd	s2,0(sp)
    80002e4a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e4c:	fffff097          	auipc	ra,0xfffff
    80002e50:	ec6080e7          	jalr	-314(ra) # 80001d12 <myproc>
    80002e54:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e56:	06053903          	ld	s2,96(a0)
    80002e5a:	0a893783          	ld	a5,168(s2)
    80002e5e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e62:	37fd                	addiw	a5,a5,-1
    80002e64:	4751                	li	a4,20
    80002e66:	00f76f63          	bltu	a4,a5,80002e84 <syscall+0x44>
    80002e6a:	00369713          	slli	a4,a3,0x3
    80002e6e:	00005797          	auipc	a5,0x5
    80002e72:	64a78793          	addi	a5,a5,1610 # 800084b8 <syscalls>
    80002e76:	97ba                	add	a5,a5,a4
    80002e78:	639c                	ld	a5,0(a5)
    80002e7a:	c789                	beqz	a5,80002e84 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002e7c:	9782                	jalr	a5
    80002e7e:	06a93823          	sd	a0,112(s2)
    80002e82:	a839                	j	80002ea0 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e84:	16048613          	addi	a2,s1,352
    80002e88:	40ac                	lw	a1,64(s1)
    80002e8a:	00005517          	auipc	a0,0x5
    80002e8e:	5f650513          	addi	a0,a0,1526 # 80008480 <states.0+0x148>
    80002e92:	ffffd097          	auipc	ra,0xffffd
    80002e96:	702080e7          	jalr	1794(ra) # 80000594 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e9a:	70bc                	ld	a5,96(s1)
    80002e9c:	577d                	li	a4,-1
    80002e9e:	fbb8                	sd	a4,112(a5)
  }
}
    80002ea0:	60e2                	ld	ra,24(sp)
    80002ea2:	6442                	ld	s0,16(sp)
    80002ea4:	64a2                	ld	s1,8(sp)
    80002ea6:	6902                	ld	s2,0(sp)
    80002ea8:	6105                	addi	sp,sp,32
    80002eaa:	8082                	ret

0000000080002eac <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002eac:	1101                	addi	sp,sp,-32
    80002eae:	ec06                	sd	ra,24(sp)
    80002eb0:	e822                	sd	s0,16(sp)
    80002eb2:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002eb4:	fec40593          	addi	a1,s0,-20
    80002eb8:	4501                	li	a0,0
    80002eba:	00000097          	auipc	ra,0x0
    80002ebe:	f12080e7          	jalr	-238(ra) # 80002dcc <argint>
    return -1;
    80002ec2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ec4:	00054963          	bltz	a0,80002ed6 <sys_exit+0x2a>
  exit(n);
    80002ec8:	fec42503          	lw	a0,-20(s0)
    80002ecc:	fffff097          	auipc	ra,0xfffff
    80002ed0:	514080e7          	jalr	1300(ra) # 800023e0 <exit>
  return 0;  // not reached
    80002ed4:	4781                	li	a5,0
}
    80002ed6:	853e                	mv	a0,a5
    80002ed8:	60e2                	ld	ra,24(sp)
    80002eda:	6442                	ld	s0,16(sp)
    80002edc:	6105                	addi	sp,sp,32
    80002ede:	8082                	ret

0000000080002ee0 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ee0:	1141                	addi	sp,sp,-16
    80002ee2:	e406                	sd	ra,8(sp)
    80002ee4:	e022                	sd	s0,0(sp)
    80002ee6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ee8:	fffff097          	auipc	ra,0xfffff
    80002eec:	e2a080e7          	jalr	-470(ra) # 80001d12 <myproc>
}
    80002ef0:	4128                	lw	a0,64(a0)
    80002ef2:	60a2                	ld	ra,8(sp)
    80002ef4:	6402                	ld	s0,0(sp)
    80002ef6:	0141                	addi	sp,sp,16
    80002ef8:	8082                	ret

0000000080002efa <sys_fork>:

uint64
sys_fork(void)
{
    80002efa:	1141                	addi	sp,sp,-16
    80002efc:	e406                	sd	ra,8(sp)
    80002efe:	e022                	sd	s0,0(sp)
    80002f00:	0800                	addi	s0,sp,16
  return fork();
    80002f02:	fffff097          	auipc	ra,0xfffff
    80002f06:	1d0080e7          	jalr	464(ra) # 800020d2 <fork>
}
    80002f0a:	60a2                	ld	ra,8(sp)
    80002f0c:	6402                	ld	s0,0(sp)
    80002f0e:	0141                	addi	sp,sp,16
    80002f10:	8082                	ret

0000000080002f12 <sys_wait>:

uint64
sys_wait(void)
{
    80002f12:	1101                	addi	sp,sp,-32
    80002f14:	ec06                	sd	ra,24(sp)
    80002f16:	e822                	sd	s0,16(sp)
    80002f18:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f1a:	fe840593          	addi	a1,s0,-24
    80002f1e:	4501                	li	a0,0
    80002f20:	00000097          	auipc	ra,0x0
    80002f24:	ece080e7          	jalr	-306(ra) # 80002dee <argaddr>
    80002f28:	87aa                	mv	a5,a0
    return -1;
    80002f2a:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f2c:	0007c863          	bltz	a5,80002f3c <sys_wait+0x2a>
  return wait(p);
    80002f30:	fe843503          	ld	a0,-24(s0)
    80002f34:	fffff097          	auipc	ra,0xfffff
    80002f38:	670080e7          	jalr	1648(ra) # 800025a4 <wait>
}
    80002f3c:	60e2                	ld	ra,24(sp)
    80002f3e:	6442                	ld	s0,16(sp)
    80002f40:	6105                	addi	sp,sp,32
    80002f42:	8082                	ret

0000000080002f44 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f44:	7179                	addi	sp,sp,-48
    80002f46:	f406                	sd	ra,40(sp)
    80002f48:	f022                	sd	s0,32(sp)
    80002f4a:	ec26                	sd	s1,24(sp)
    80002f4c:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f4e:	fdc40593          	addi	a1,s0,-36
    80002f52:	4501                	li	a0,0
    80002f54:	00000097          	auipc	ra,0x0
    80002f58:	e78080e7          	jalr	-392(ra) # 80002dcc <argint>
    return -1;
    80002f5c:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002f5e:	00054f63          	bltz	a0,80002f7c <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002f62:	fffff097          	auipc	ra,0xfffff
    80002f66:	db0080e7          	jalr	-592(ra) # 80001d12 <myproc>
    80002f6a:	4924                	lw	s1,80(a0)
  if(growproc(n) < 0)
    80002f6c:	fdc42503          	lw	a0,-36(s0)
    80002f70:	fffff097          	auipc	ra,0xfffff
    80002f74:	0ee080e7          	jalr	238(ra) # 8000205e <growproc>
    80002f78:	00054863          	bltz	a0,80002f88 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002f7c:	8526                	mv	a0,s1
    80002f7e:	70a2                	ld	ra,40(sp)
    80002f80:	7402                	ld	s0,32(sp)
    80002f82:	64e2                	ld	s1,24(sp)
    80002f84:	6145                	addi	sp,sp,48
    80002f86:	8082                	ret
    return -1;
    80002f88:	54fd                	li	s1,-1
    80002f8a:	bfcd                	j	80002f7c <sys_sbrk+0x38>

0000000080002f8c <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f8c:	7139                	addi	sp,sp,-64
    80002f8e:	fc06                	sd	ra,56(sp)
    80002f90:	f822                	sd	s0,48(sp)
    80002f92:	f426                	sd	s1,40(sp)
    80002f94:	f04a                	sd	s2,32(sp)
    80002f96:	ec4e                	sd	s3,24(sp)
    80002f98:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002f9a:	fcc40593          	addi	a1,s0,-52
    80002f9e:	4501                	li	a0,0
    80002fa0:	00000097          	auipc	ra,0x0
    80002fa4:	e2c080e7          	jalr	-468(ra) # 80002dcc <argint>
    return -1;
    80002fa8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002faa:	06054563          	bltz	a0,80003014 <sys_sleep+0x88>
  acquire(&tickslock);
    80002fae:	00015517          	auipc	a0,0x15
    80002fb2:	3fa50513          	addi	a0,a0,1018 # 800183a8 <tickslock>
    80002fb6:	ffffe097          	auipc	ra,0xffffe
    80002fba:	d16080e7          	jalr	-746(ra) # 80000ccc <acquire>
  ticks0 = ticks;
    80002fbe:	00006917          	auipc	s2,0x6
    80002fc2:	06292903          	lw	s2,98(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002fc6:	fcc42783          	lw	a5,-52(s0)
    80002fca:	cf85                	beqz	a5,80003002 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002fcc:	00015997          	auipc	s3,0x15
    80002fd0:	3dc98993          	addi	s3,s3,988 # 800183a8 <tickslock>
    80002fd4:	00006497          	auipc	s1,0x6
    80002fd8:	04c48493          	addi	s1,s1,76 # 80009020 <ticks>
    if(myproc()->killed){
    80002fdc:	fffff097          	auipc	ra,0xfffff
    80002fe0:	d36080e7          	jalr	-714(ra) # 80001d12 <myproc>
    80002fe4:	5d1c                	lw	a5,56(a0)
    80002fe6:	ef9d                	bnez	a5,80003024 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002fe8:	85ce                	mv	a1,s3
    80002fea:	8526                	mv	a0,s1
    80002fec:	fffff097          	auipc	ra,0xfffff
    80002ff0:	53a080e7          	jalr	1338(ra) # 80002526 <sleep>
  while(ticks - ticks0 < n){
    80002ff4:	409c                	lw	a5,0(s1)
    80002ff6:	412787bb          	subw	a5,a5,s2
    80002ffa:	fcc42703          	lw	a4,-52(s0)
    80002ffe:	fce7efe3          	bltu	a5,a4,80002fdc <sys_sleep+0x50>
  }
  release(&tickslock);
    80003002:	00015517          	auipc	a0,0x15
    80003006:	3a650513          	addi	a0,a0,934 # 800183a8 <tickslock>
    8000300a:	ffffe097          	auipc	ra,0xffffe
    8000300e:	d92080e7          	jalr	-622(ra) # 80000d9c <release>
  return 0;
    80003012:	4781                	li	a5,0
}
    80003014:	853e                	mv	a0,a5
    80003016:	70e2                	ld	ra,56(sp)
    80003018:	7442                	ld	s0,48(sp)
    8000301a:	74a2                	ld	s1,40(sp)
    8000301c:	7902                	ld	s2,32(sp)
    8000301e:	69e2                	ld	s3,24(sp)
    80003020:	6121                	addi	sp,sp,64
    80003022:	8082                	ret
      release(&tickslock);
    80003024:	00015517          	auipc	a0,0x15
    80003028:	38450513          	addi	a0,a0,900 # 800183a8 <tickslock>
    8000302c:	ffffe097          	auipc	ra,0xffffe
    80003030:	d70080e7          	jalr	-656(ra) # 80000d9c <release>
      return -1;
    80003034:	57fd                	li	a5,-1
    80003036:	bff9                	j	80003014 <sys_sleep+0x88>

0000000080003038 <sys_kill>:

uint64
sys_kill(void)
{
    80003038:	1101                	addi	sp,sp,-32
    8000303a:	ec06                	sd	ra,24(sp)
    8000303c:	e822                	sd	s0,16(sp)
    8000303e:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003040:	fec40593          	addi	a1,s0,-20
    80003044:	4501                	li	a0,0
    80003046:	00000097          	auipc	ra,0x0
    8000304a:	d86080e7          	jalr	-634(ra) # 80002dcc <argint>
    8000304e:	87aa                	mv	a5,a0
    return -1;
    80003050:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003052:	0007c863          	bltz	a5,80003062 <sys_kill+0x2a>
  return kill(pid);
    80003056:	fec42503          	lw	a0,-20(s0)
    8000305a:	fffff097          	auipc	ra,0xfffff
    8000305e:	6b6080e7          	jalr	1718(ra) # 80002710 <kill>
}
    80003062:	60e2                	ld	ra,24(sp)
    80003064:	6442                	ld	s0,16(sp)
    80003066:	6105                	addi	sp,sp,32
    80003068:	8082                	ret

000000008000306a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000306a:	1101                	addi	sp,sp,-32
    8000306c:	ec06                	sd	ra,24(sp)
    8000306e:	e822                	sd	s0,16(sp)
    80003070:	e426                	sd	s1,8(sp)
    80003072:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003074:	00015517          	auipc	a0,0x15
    80003078:	33450513          	addi	a0,a0,820 # 800183a8 <tickslock>
    8000307c:	ffffe097          	auipc	ra,0xffffe
    80003080:	c50080e7          	jalr	-944(ra) # 80000ccc <acquire>
  xticks = ticks;
    80003084:	00006497          	auipc	s1,0x6
    80003088:	f9c4a483          	lw	s1,-100(s1) # 80009020 <ticks>
  release(&tickslock);
    8000308c:	00015517          	auipc	a0,0x15
    80003090:	31c50513          	addi	a0,a0,796 # 800183a8 <tickslock>
    80003094:	ffffe097          	auipc	ra,0xffffe
    80003098:	d08080e7          	jalr	-760(ra) # 80000d9c <release>
  return xticks;
}
    8000309c:	02049513          	slli	a0,s1,0x20
    800030a0:	9101                	srli	a0,a0,0x20
    800030a2:	60e2                	ld	ra,24(sp)
    800030a4:	6442                	ld	s0,16(sp)
    800030a6:	64a2                	ld	s1,8(sp)
    800030a8:	6105                	addi	sp,sp,32
    800030aa:	8082                	ret

00000000800030ac <binit>:
  //struct buf head;
} bcache;

void
binit(void)
{
    800030ac:	715d                	addi	sp,sp,-80
    800030ae:	e486                	sd	ra,72(sp)
    800030b0:	e0a2                	sd	s0,64(sp)
    800030b2:	fc26                	sd	s1,56(sp)
    800030b4:	f84a                	sd	s2,48(sp)
    800030b6:	f44e                	sd	s3,40(sp)
    800030b8:	f052                	sd	s4,32(sp)
    800030ba:	ec56                	sd	s5,24(sp)
    800030bc:	e85a                	sd	s6,16(sp)
    800030be:	e45e                	sd	s7,8(sp)
    800030c0:	e062                	sd	s8,0(sp)
    800030c2:	0880                	addi	s0,sp,80
    initsleeplock(&b->lock, "buffer");
    //bcache.head.next->prev = b;
    //bcache.head.next = b;
  }*/
  struct buf *b;
  for(int i=0;i<NBUC;i++)
    800030c4:	0001d917          	auipc	s2,0x1d
    800030c8:	55490913          	addi	s2,s2,1364 # 80020618 <bcache+0x8250>
    800030cc:	00015497          	auipc	s1,0x15
    800030d0:	2fc48493          	addi	s1,s1,764 # 800183c8 <bcache>
    800030d4:	00021a17          	auipc	s4,0x21
    800030d8:	f5ca0a13          	addi	s4,s4,-164 # 80024030 <sb>
  {
    bcache.bucket[i].head.next=NULL;
    initlock(&bcache.bucket[i].lock,"bcache.bucket");
    800030dc:	00005997          	auipc	s3,0x5
    800030e0:	48c98993          	addi	s3,s3,1164 # 80008568 <syscalls+0xb0>
    bcache.bucket[i].head.next=NULL;
    800030e4:	06093823          	sd	zero,112(s2)
    initlock(&bcache.bucket[i].lock,"bcache.bucket");
    800030e8:	85ce                	mv	a1,s3
    800030ea:	854a                	mv	a0,s2
    800030ec:	ffffe097          	auipc	ra,0xffffe
    800030f0:	d5c080e7          	jalr	-676(ra) # 80000e48 <initlock>
  for(int i=0;i<NBUC;i++)
    800030f4:	47890913          	addi	s2,s2,1144
    800030f8:	ff4916e3          	bne	s2,s4,800030e4 <binit+0x38>
  }
  int j;
  for(int i=0;i<NBUF;i++)
    800030fc:	4901                	li	s2,0
  {
    j=i%NBUC;
    800030fe:	4c35                	li	s8,13
    b=bcache.buf+i;
    b->next=bcache.bucket[j].head.next;
    80003100:	00015b97          	auipc	s7,0x15
    80003104:	2c8b8b93          	addi	s7,s7,712 # 800183c8 <bcache>
    80003108:	47800b13          	li	s6,1144
    8000310c:	6aa1                	lui	s5,0x8
    bcache.bucket[j].head.next=b;
    initsleeplock(&bcache.buf[i].lock,"buffer");
    8000310e:	00005a17          	auipc	s4,0x5
    80003112:	46aa0a13          	addi	s4,s4,1130 # 80008578 <syscalls+0xc0>
  for(int i=0;i<NBUF;i++)
    80003116:	49f9                	li	s3,30
    j=i%NBUC;
    80003118:	038967bb          	remw	a5,s2,s8
    b->next=bcache.bucket[j].head.next;
    8000311c:	036787b3          	mul	a5,a5,s6
    80003120:	97de                	add	a5,a5,s7
    80003122:	97d6                	add	a5,a5,s5
    80003124:	2c07b703          	ld	a4,704(a5)
    80003128:	e8b8                	sd	a4,80(s1)
    bcache.bucket[j].head.next=b;
    8000312a:	2c97b023          	sd	s1,704(a5)
    initsleeplock(&bcache.buf[i].lock,"buffer");
    8000312e:	85d2                	mv	a1,s4
    80003130:	01048513          	addi	a0,s1,16
    80003134:	00001097          	auipc	ra,0x1
    80003138:	61c080e7          	jalr	1564(ra) # 80004750 <initsleeplock>
  for(int i=0;i<NBUF;i++)
    8000313c:	2905                	addiw	s2,s2,1
    8000313e:	45848493          	addi	s1,s1,1112
    80003142:	fd391be3          	bne	s2,s3,80003118 <binit+0x6c>
  }
}
    80003146:	60a6                	ld	ra,72(sp)
    80003148:	6406                	ld	s0,64(sp)
    8000314a:	74e2                	ld	s1,56(sp)
    8000314c:	7942                	ld	s2,48(sp)
    8000314e:	79a2                	ld	s3,40(sp)
    80003150:	7a02                	ld	s4,32(sp)
    80003152:	6ae2                	ld	s5,24(sp)
    80003154:	6b42                	ld	s6,16(sp)
    80003156:	6ba2                	ld	s7,8(sp)
    80003158:	6c02                	ld	s8,0(sp)
    8000315a:	6161                	addi	sp,sp,80
    8000315c:	8082                	ret

000000008000315e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000315e:	711d                	addi	sp,sp,-96
    80003160:	ec86                	sd	ra,88(sp)
    80003162:	e8a2                	sd	s0,80(sp)
    80003164:	e4a6                	sd	s1,72(sp)
    80003166:	e0ca                	sd	s2,64(sp)
    80003168:	fc4e                	sd	s3,56(sp)
    8000316a:	f852                	sd	s4,48(sp)
    8000316c:	f456                	sd	s5,40(sp)
    8000316e:	f05a                	sd	s6,32(sp)
    80003170:	ec5e                	sd	s7,24(sp)
    80003172:	e862                	sd	s8,16(sp)
    80003174:	e466                	sd	s9,8(sp)
    80003176:	e06a                	sd	s10,0(sp)
    80003178:	1080                	addi	s0,sp,96
    8000317a:	8a2a                	mv	s4,a0
    8000317c:	8b2e                	mv	s6,a1
  int no=blockno%NBUC;
    8000317e:	4ab5                	li	s5,13
    80003180:	0355fabb          	remuw	s5,a1,s5
  acquire(&bcache.bucket[no].lock);
    80003184:	47800913          	li	s2,1144
    80003188:	032a89b3          	mul	s3,s5,s2
    8000318c:	64a1                	lui	s1,0x8
    8000318e:	25048c13          	addi	s8,s1,592 # 8250 <_entry-0x7fff7db0>
    80003192:	9c4e                	add	s8,s8,s3
    80003194:	00015917          	auipc	s2,0x15
    80003198:	23490913          	addi	s2,s2,564 # 800183c8 <bcache>
    8000319c:	9c4a                	add	s8,s8,s2
    8000319e:	8562                	mv	a0,s8
    800031a0:	ffffe097          	auipc	ra,0xffffe
    800031a4:	b2c080e7          	jalr	-1236(ra) # 80000ccc <acquire>
  for(b=bcache.bucket[no].head.next;b;b=b->next)
    800031a8:	994e                	add	s2,s2,s3
    800031aa:	94ca                	add	s1,s1,s2
    800031ac:	2c04b783          	ld	a5,704(s1)
    800031b0:	cfa1                	beqz	a5,80003208 <bread+0xaa>
    800031b2:	84be                	mv	s1,a5
    800031b4:	a019                	j	800031ba <bread+0x5c>
    800031b6:	68a4                	ld	s1,80(s1)
    800031b8:	cc95                	beqz	s1,800031f4 <bread+0x96>
    if(b->dev==dev&&b->blockno==blockno)
    800031ba:	4498                	lw	a4,8(s1)
    800031bc:	ff471de3          	bne	a4,s4,800031b6 <bread+0x58>
    800031c0:	44d8                	lw	a4,12(s1)
    800031c2:	ff671ae3          	bne	a4,s6,800031b6 <bread+0x58>
      b->refcnt++;
    800031c6:	44bc                	lw	a5,72(s1)
    800031c8:	2785                	addiw	a5,a5,1
    800031ca:	c4bc                	sw	a5,72(s1)
      b->timestamp=ticks;
    800031cc:	00006797          	auipc	a5,0x6
    800031d0:	e547a783          	lw	a5,-428(a5) # 80009020 <ticks>
    800031d4:	c4fc                	sw	a5,76(s1)
      release(&bcache.bucket[no].lock);
    800031d6:	8562                	mv	a0,s8
    800031d8:	ffffe097          	auipc	ra,0xffffe
    800031dc:	bc4080e7          	jalr	-1084(ra) # 80000d9c <release>
      acquiresleep(&b->lock);
    800031e0:	01048513          	addi	a0,s1,16
    800031e4:	00001097          	auipc	ra,0x1
    800031e8:	5a6080e7          	jalr	1446(ra) # 8000478a <acquiresleep>
      return b;
    800031ec:	aa3d                	j	8000332a <bread+0x1cc>
    800031ee:	84be                	mv	s1,a5
  for(b=bcache.bucket[no].head.next;b;b=b->next)
    800031f0:	6bbc                	ld	a5,80(a5)
    800031f2:	cb91                	beqz	a5,80003206 <bread+0xa8>
    if(b->refcnt==0)
    800031f4:	47b8                	lw	a4,72(a5)
    800031f6:	ff6d                	bnez	a4,800031f0 <bread+0x92>
      if(!lru)
    800031f8:	d8fd                	beqz	s1,800031ee <bread+0x90>
      else if(lru->timestamp>b->timestamp)
    800031fa:	44f4                	lw	a3,76(s1)
    800031fc:	47f8                	lw	a4,76(a5)
    800031fe:	fed779e3          	bgeu	a4,a3,800031f0 <bread+0x92>
    80003202:	84be                	mv	s1,a5
    80003204:	b7f5                	j	800031f0 <bread+0x92>
  if(lru)
    80003206:	e891                	bnez	s1,8000321a <bread+0xbc>
    80003208:	0001d997          	auipc	s3,0x1d
    8000320c:	41098993          	addi	s3,s3,1040 # 80020618 <bcache+0x8250>
      else if(lru->timestamp>b->timestamp)
    80003210:	5bfd                	li	s7,-1
    80003212:	4481                	li	s1,0
    80003214:	4901                	li	s2,0
  for(int i=0;i<NBUC;i++)
    80003216:	4cb5                	li	s9,13
    80003218:	a095                	j	8000327c <bread+0x11e>
    lru->dev=dev;
    8000321a:	0144a423          	sw	s4,8(s1)
    lru->blockno=blockno;
    8000321e:	0164a623          	sw	s6,12(s1)
    lru->valid=0;
    80003222:	0004a023          	sw	zero,0(s1)
    lru->refcnt=1;
    80003226:	4785                	li	a5,1
    80003228:	c4bc                	sw	a5,72(s1)
    lru->timestamp=ticks;
    8000322a:	00006797          	auipc	a5,0x6
    8000322e:	df67a783          	lw	a5,-522(a5) # 80009020 <ticks>
    80003232:	c4fc                	sw	a5,76(s1)
    release(&bcache.bucket[no].lock);
    80003234:	8562                	mv	a0,s8
    80003236:	ffffe097          	auipc	ra,0xffffe
    8000323a:	b66080e7          	jalr	-1178(ra) # 80000d9c <release>
    acquiresleep(&lru->lock);
    8000323e:	01048513          	addi	a0,s1,16
    80003242:	00001097          	auipc	ra,0x1
    80003246:	548080e7          	jalr	1352(ra) # 8000478a <acquiresleep>
    return lru;
    8000324a:	a0c5                	j	8000332a <bread+0x1cc>
    8000324c:	8bb2                	mv	s7,a2
    8000324e:	84be                	mv	s1,a5
    for(;temp;temp=temp->next)
    80003250:	6bbc                	ld	a5,80(a5)
    80003252:	cb99                	beqz	a5,80003268 <bread+0x10a>
      if(temp->refcnt==0)
    80003254:	47b8                	lw	a4,72(a5)
    80003256:	ff6d                	bnez	a4,80003250 <bread+0xf2>
        if(!lru)
    80003258:	d8f5                	beqz	s1,8000324c <bread+0xee>
	else if(lru->timestamp>temp->timestamp)
    8000325a:	44f4                	lw	a3,76(s1)
    8000325c:	47f8                	lw	a4,76(a5)
    8000325e:	fed779e3          	bgeu	a4,a3,80003250 <bread+0xf2>
    80003262:	8bb2                	mv	s7,a2
    80003264:	84be                	mv	s1,a5
    80003266:	b7ed                	j	80003250 <bread+0xf2>
    release(&bcache.bucket[i].lock);
    80003268:	856a                	mv	a0,s10
    8000326a:	ffffe097          	auipc	ra,0xffffe
    8000326e:	b32080e7          	jalr	-1230(ra) # 80000d9c <release>
  for(int i=0;i<NBUC;i++)
    80003272:	2905                	addiw	s2,s2,1
    80003274:	47898993          	addi	s3,s3,1144
    80003278:	01990f63          	beq	s2,s9,80003296 <bread+0x138>
    if(i==no)
    8000327c:	ff2a8be3          	beq	s5,s2,80003272 <bread+0x114>
    acquire(&bcache.bucket[i].lock);
    80003280:	8d4e                	mv	s10,s3
    80003282:	854e                	mv	a0,s3
    80003284:	ffffe097          	auipc	ra,0xffffe
    80003288:	a48080e7          	jalr	-1464(ra) # 80000ccc <acquire>
    temp=bcache.bucket[i].head.next;
    8000328c:	0709b783          	ld	a5,112(s3)
    for(;temp;temp=temp->next)
    80003290:	dfe1                	beqz	a5,80003268 <bread+0x10a>
    80003292:	864a                	mv	a2,s2
    80003294:	b7c1                	j	80003254 <bread+0xf6>
  if(lru)
    80003296:	ccd5                	beqz	s1,80003352 <bread+0x1f4>
    acquire(&bcache.bucket[new_no].lock);
    80003298:	47800793          	li	a5,1144
    8000329c:	02fb8bb3          	mul	s7,s7,a5
    800032a0:	69a1                	lui	s3,0x8
    800032a2:	25098913          	addi	s2,s3,592 # 8250 <_entry-0x7fff7db0>
    800032a6:	995e                	add	s2,s2,s7
    800032a8:	00015c97          	auipc	s9,0x15
    800032ac:	120c8c93          	addi	s9,s9,288 # 800183c8 <bcache>
    800032b0:	9966                	add	s2,s2,s9
    800032b2:	854a                	mv	a0,s2
    800032b4:	ffffe097          	auipc	ra,0xffffe
    800032b8:	a18080e7          	jalr	-1512(ra) # 80000ccc <acquire>
    for(temp=&bcache.bucket[new_no].head;temp;temp=temp->next)
    800032bc:	27098793          	addi	a5,s3,624
    800032c0:	9bbe                	add	s7,s7,a5
    800032c2:	019b87b3          	add	a5,s7,s9
      if(temp->next==lru)
    800032c6:	873e                	mv	a4,a5
    800032c8:	6bbc                	ld	a5,80(a5)
    800032ca:	08978163          	beq	a5,s1,8000334c <bread+0x1ee>
    for(temp=&bcache.bucket[new_no].head;temp;temp=temp->next)
    800032ce:	ffe5                	bnez	a5,800032c6 <bread+0x168>
    lru->dev=dev;
    800032d0:	0144a423          	sw	s4,8(s1)
    lru->blockno=blockno;
    800032d4:	0164a623          	sw	s6,12(s1)
    lru->valid=0;
    800032d8:	0004a023          	sw	zero,0(s1)
    lru->refcnt=1;
    800032dc:	4785                	li	a5,1
    800032de:	c4bc                	sw	a5,72(s1)
    lru->timestamp=ticks;
    800032e0:	00006797          	auipc	a5,0x6
    800032e4:	d407a783          	lw	a5,-704(a5) # 80009020 <ticks>
    800032e8:	c4fc                	sw	a5,76(s1)
    lru->next=bcache.bucket[no].head.next;
    800032ea:	47800793          	li	a5,1144
    800032ee:	02fa8ab3          	mul	s5,s5,a5
    800032f2:	00015797          	auipc	a5,0x15
    800032f6:	0d678793          	addi	a5,a5,214 # 800183c8 <bcache>
    800032fa:	97d6                	add	a5,a5,s5
    800032fc:	6aa1                	lui	s5,0x8
    800032fe:	9abe                	add	s5,s5,a5
    80003300:	2c0ab783          	ld	a5,704(s5) # 82c0 <_entry-0x7fff7d40>
    80003304:	e8bc                	sd	a5,80(s1)
    bcache.bucket[no].head.next=lru;
    80003306:	2c9ab023          	sd	s1,704(s5)
    release(&bcache.bucket[no].lock);
    8000330a:	8562                	mv	a0,s8
    8000330c:	ffffe097          	auipc	ra,0xffffe
    80003310:	a90080e7          	jalr	-1392(ra) # 80000d9c <release>
    release(&bcache.bucket[new_no].lock);
    80003314:	854a                	mv	a0,s2
    80003316:	ffffe097          	auipc	ra,0xffffe
    8000331a:	a86080e7          	jalr	-1402(ra) # 80000d9c <release>
    acquiresleep(&lru->lock);
    8000331e:	01048513          	addi	a0,s1,16
    80003322:	00001097          	auipc	ra,0x1
    80003326:	468080e7          	jalr	1128(ra) # 8000478a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000332a:	409c                	lw	a5,0(s1)
    8000332c:	cb9d                	beqz	a5,80003362 <bread+0x204>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000332e:	8526                	mv	a0,s1
    80003330:	60e6                	ld	ra,88(sp)
    80003332:	6446                	ld	s0,80(sp)
    80003334:	64a6                	ld	s1,72(sp)
    80003336:	6906                	ld	s2,64(sp)
    80003338:	79e2                	ld	s3,56(sp)
    8000333a:	7a42                	ld	s4,48(sp)
    8000333c:	7aa2                	ld	s5,40(sp)
    8000333e:	7b02                	ld	s6,32(sp)
    80003340:	6be2                	ld	s7,24(sp)
    80003342:	6c42                	ld	s8,16(sp)
    80003344:	6ca2                	ld	s9,8(sp)
    80003346:	6d02                	ld	s10,0(sp)
    80003348:	6125                	addi	sp,sp,96
    8000334a:	8082                	ret
        temp->next=temp->next->next;
    8000334c:	68bc                	ld	a5,80(s1)
    8000334e:	eb3c                	sd	a5,80(a4)
	break;
    80003350:	b741                	j	800032d0 <bread+0x172>
  panic("bget: no buffers");
    80003352:	00005517          	auipc	a0,0x5
    80003356:	22e50513          	addi	a0,a0,558 # 80008580 <syscalls+0xc8>
    8000335a:	ffffd097          	auipc	ra,0xffffd
    8000335e:	1f0080e7          	jalr	496(ra) # 8000054a <panic>
    virtio_disk_rw(b, 0);
    80003362:	4581                	li	a1,0
    80003364:	8526                	mv	a0,s1
    80003366:	00003097          	auipc	ra,0x3
    8000336a:	f90080e7          	jalr	-112(ra) # 800062f6 <virtio_disk_rw>
    b->valid = 1;
    8000336e:	4785                	li	a5,1
    80003370:	c09c                	sw	a5,0(s1)
  return b;
    80003372:	bf75                	j	8000332e <bread+0x1d0>

0000000080003374 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003374:	1101                	addi	sp,sp,-32
    80003376:	ec06                	sd	ra,24(sp)
    80003378:	e822                	sd	s0,16(sp)
    8000337a:	e426                	sd	s1,8(sp)
    8000337c:	1000                	addi	s0,sp,32
    8000337e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003380:	0541                	addi	a0,a0,16
    80003382:	00001097          	auipc	ra,0x1
    80003386:	4a2080e7          	jalr	1186(ra) # 80004824 <holdingsleep>
    8000338a:	cd01                	beqz	a0,800033a2 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000338c:	4585                	li	a1,1
    8000338e:	8526                	mv	a0,s1
    80003390:	00003097          	auipc	ra,0x3
    80003394:	f66080e7          	jalr	-154(ra) # 800062f6 <virtio_disk_rw>
}
    80003398:	60e2                	ld	ra,24(sp)
    8000339a:	6442                	ld	s0,16(sp)
    8000339c:	64a2                	ld	s1,8(sp)
    8000339e:	6105                	addi	sp,sp,32
    800033a0:	8082                	ret
    panic("bwrite");
    800033a2:	00005517          	auipc	a0,0x5
    800033a6:	1f650513          	addi	a0,a0,502 # 80008598 <syscalls+0xe0>
    800033aa:	ffffd097          	auipc	ra,0xffffd
    800033ae:	1a0080e7          	jalr	416(ra) # 8000054a <panic>

00000000800033b2 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800033b2:	1101                	addi	sp,sp,-32
    800033b4:	ec06                	sd	ra,24(sp)
    800033b6:	e822                	sd	s0,16(sp)
    800033b8:	e426                	sd	s1,8(sp)
    800033ba:	e04a                	sd	s2,0(sp)
    800033bc:	1000                	addi	s0,sp,32
    800033be:	892a                	mv	s2,a0
  if(!holdingsleep(&b->lock))
    800033c0:	01050493          	addi	s1,a0,16
    800033c4:	8526                	mv	a0,s1
    800033c6:	00001097          	auipc	ra,0x1
    800033ca:	45e080e7          	jalr	1118(ra) # 80004824 <holdingsleep>
    800033ce:	c535                	beqz	a0,8000343a <brelse+0x88>
    panic("brelse");

  releasesleep(&b->lock);
    800033d0:	8526                	mv	a0,s1
    800033d2:	00001097          	auipc	ra,0x1
    800033d6:	40e080e7          	jalr	1038(ra) # 800047e0 <releasesleep>
  int no=b->blockno%NBUC;
    800033da:	00c92483          	lw	s1,12(s2)
  acquire(&bcache.bucket[no].lock);
    800033de:	47b5                	li	a5,13
    800033e0:	02f4f4bb          	remuw	s1,s1,a5
    800033e4:	47800793          	li	a5,1144
    800033e8:	02f484b3          	mul	s1,s1,a5
    800033ec:	67a1                	lui	a5,0x8
    800033ee:	25078793          	addi	a5,a5,592 # 8250 <_entry-0x7fff7db0>
    800033f2:	94be                	add	s1,s1,a5
    800033f4:	00015797          	auipc	a5,0x15
    800033f8:	fd478793          	addi	a5,a5,-44 # 800183c8 <bcache>
    800033fc:	94be                	add	s1,s1,a5
    800033fe:	8526                	mv	a0,s1
    80003400:	ffffe097          	auipc	ra,0xffffe
    80003404:	8cc080e7          	jalr	-1844(ra) # 80000ccc <acquire>
  b->refcnt--;
    80003408:	04892783          	lw	a5,72(s2)
    8000340c:	37fd                	addiw	a5,a5,-1
    8000340e:	0007871b          	sext.w	a4,a5
    80003412:	04f92423          	sw	a5,72(s2)
  if (b->refcnt == 0) {
    80003416:	e719                	bnez	a4,80003424 <brelse+0x72>
    b->prev->next = b->next;
    b->next = bcache.head.next;
    b->prev = &bcache.head;
    bcache.head.next->prev = b;
    bcache.head.next = b;*/
    b->timestamp=ticks;
    80003418:	00006797          	auipc	a5,0x6
    8000341c:	c087a783          	lw	a5,-1016(a5) # 80009020 <ticks>
    80003420:	04f92623          	sw	a5,76(s2)
  }
  release(&bcache.bucket[no].lock);
    80003424:	8526                	mv	a0,s1
    80003426:	ffffe097          	auipc	ra,0xffffe
    8000342a:	976080e7          	jalr	-1674(ra) # 80000d9c <release>
}
    8000342e:	60e2                	ld	ra,24(sp)
    80003430:	6442                	ld	s0,16(sp)
    80003432:	64a2                	ld	s1,8(sp)
    80003434:	6902                	ld	s2,0(sp)
    80003436:	6105                	addi	sp,sp,32
    80003438:	8082                	ret
    panic("brelse");
    8000343a:	00005517          	auipc	a0,0x5
    8000343e:	16650513          	addi	a0,a0,358 # 800085a0 <syscalls+0xe8>
    80003442:	ffffd097          	auipc	ra,0xffffd
    80003446:	108080e7          	jalr	264(ra) # 8000054a <panic>

000000008000344a <bpin>:

void
bpin(struct buf *b) {
    8000344a:	1101                	addi	sp,sp,-32
    8000344c:	ec06                	sd	ra,24(sp)
    8000344e:	e822                	sd	s0,16(sp)
    80003450:	e426                	sd	s1,8(sp)
    80003452:	e04a                	sd	s2,0(sp)
    80003454:	1000                	addi	s0,sp,32
    80003456:	892a                	mv	s2,a0
  //acquire(&bcache.lock);
  int no=b->blockno%NBUC;
    80003458:	4544                	lw	s1,12(a0)
  acquire(&bcache.bucket[no].lock);
    8000345a:	47b5                	li	a5,13
    8000345c:	02f4f4bb          	remuw	s1,s1,a5
    80003460:	47800793          	li	a5,1144
    80003464:	02f484b3          	mul	s1,s1,a5
    80003468:	67a1                	lui	a5,0x8
    8000346a:	25078793          	addi	a5,a5,592 # 8250 <_entry-0x7fff7db0>
    8000346e:	94be                	add	s1,s1,a5
    80003470:	00015797          	auipc	a5,0x15
    80003474:	f5878793          	addi	a5,a5,-168 # 800183c8 <bcache>
    80003478:	94be                	add	s1,s1,a5
    8000347a:	8526                	mv	a0,s1
    8000347c:	ffffe097          	auipc	ra,0xffffe
    80003480:	850080e7          	jalr	-1968(ra) # 80000ccc <acquire>
  b->refcnt++;
    80003484:	04892783          	lw	a5,72(s2)
    80003488:	2785                	addiw	a5,a5,1
    8000348a:	04f92423          	sw	a5,72(s2)
  release(&bcache.bucket[no].lock);
    8000348e:	8526                	mv	a0,s1
    80003490:	ffffe097          	auipc	ra,0xffffe
    80003494:	90c080e7          	jalr	-1780(ra) # 80000d9c <release>
  //release(&bcache.lock);
}
    80003498:	60e2                	ld	ra,24(sp)
    8000349a:	6442                	ld	s0,16(sp)
    8000349c:	64a2                	ld	s1,8(sp)
    8000349e:	6902                	ld	s2,0(sp)
    800034a0:	6105                	addi	sp,sp,32
    800034a2:	8082                	ret

00000000800034a4 <bunpin>:

void
bunpin(struct buf *b) {
    800034a4:	1101                	addi	sp,sp,-32
    800034a6:	ec06                	sd	ra,24(sp)
    800034a8:	e822                	sd	s0,16(sp)
    800034aa:	e426                	sd	s1,8(sp)
    800034ac:	e04a                	sd	s2,0(sp)
    800034ae:	1000                	addi	s0,sp,32
    800034b0:	892a                	mv	s2,a0
  //acquire(&bcache.lock);
  int no=b->blockno%NBUC;
    800034b2:	4544                	lw	s1,12(a0)
  acquire(&bcache.bucket[no].lock);
    800034b4:	47b5                	li	a5,13
    800034b6:	02f4f4bb          	remuw	s1,s1,a5
    800034ba:	47800793          	li	a5,1144
    800034be:	02f484b3          	mul	s1,s1,a5
    800034c2:	67a1                	lui	a5,0x8
    800034c4:	25078793          	addi	a5,a5,592 # 8250 <_entry-0x7fff7db0>
    800034c8:	94be                	add	s1,s1,a5
    800034ca:	00015797          	auipc	a5,0x15
    800034ce:	efe78793          	addi	a5,a5,-258 # 800183c8 <bcache>
    800034d2:	94be                	add	s1,s1,a5
    800034d4:	8526                	mv	a0,s1
    800034d6:	ffffd097          	auipc	ra,0xffffd
    800034da:	7f6080e7          	jalr	2038(ra) # 80000ccc <acquire>
  b->refcnt--;
    800034de:	04892783          	lw	a5,72(s2)
    800034e2:	37fd                	addiw	a5,a5,-1
    800034e4:	04f92423          	sw	a5,72(s2)
  release(&bcache.bucket[no].lock);
    800034e8:	8526                	mv	a0,s1
    800034ea:	ffffe097          	auipc	ra,0xffffe
    800034ee:	8b2080e7          	jalr	-1870(ra) # 80000d9c <release>
  //release(&bcache.lock);
}
    800034f2:	60e2                	ld	ra,24(sp)
    800034f4:	6442                	ld	s0,16(sp)
    800034f6:	64a2                	ld	s1,8(sp)
    800034f8:	6902                	ld	s2,0(sp)
    800034fa:	6105                	addi	sp,sp,32
    800034fc:	8082                	ret

00000000800034fe <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800034fe:	1101                	addi	sp,sp,-32
    80003500:	ec06                	sd	ra,24(sp)
    80003502:	e822                	sd	s0,16(sp)
    80003504:	e426                	sd	s1,8(sp)
    80003506:	e04a                	sd	s2,0(sp)
    80003508:	1000                	addi	s0,sp,32
    8000350a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000350c:	00d5d59b          	srliw	a1,a1,0xd
    80003510:	00021797          	auipc	a5,0x21
    80003514:	b3c7a783          	lw	a5,-1220(a5) # 8002404c <sb+0x1c>
    80003518:	9dbd                	addw	a1,a1,a5
    8000351a:	00000097          	auipc	ra,0x0
    8000351e:	c44080e7          	jalr	-956(ra) # 8000315e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003522:	0074f713          	andi	a4,s1,7
    80003526:	4785                	li	a5,1
    80003528:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000352c:	14ce                	slli	s1,s1,0x33
    8000352e:	90d9                	srli	s1,s1,0x36
    80003530:	00950733          	add	a4,a0,s1
    80003534:	05874703          	lbu	a4,88(a4)
    80003538:	00e7f6b3          	and	a3,a5,a4
    8000353c:	c69d                	beqz	a3,8000356a <bfree+0x6c>
    8000353e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003540:	94aa                	add	s1,s1,a0
    80003542:	fff7c793          	not	a5,a5
    80003546:	8ff9                	and	a5,a5,a4
    80003548:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000354c:	00001097          	auipc	ra,0x1
    80003550:	116080e7          	jalr	278(ra) # 80004662 <log_write>
  brelse(bp);
    80003554:	854a                	mv	a0,s2
    80003556:	00000097          	auipc	ra,0x0
    8000355a:	e5c080e7          	jalr	-420(ra) # 800033b2 <brelse>
}
    8000355e:	60e2                	ld	ra,24(sp)
    80003560:	6442                	ld	s0,16(sp)
    80003562:	64a2                	ld	s1,8(sp)
    80003564:	6902                	ld	s2,0(sp)
    80003566:	6105                	addi	sp,sp,32
    80003568:	8082                	ret
    panic("freeing free block");
    8000356a:	00005517          	auipc	a0,0x5
    8000356e:	03e50513          	addi	a0,a0,62 # 800085a8 <syscalls+0xf0>
    80003572:	ffffd097          	auipc	ra,0xffffd
    80003576:	fd8080e7          	jalr	-40(ra) # 8000054a <panic>

000000008000357a <balloc>:
{
    8000357a:	711d                	addi	sp,sp,-96
    8000357c:	ec86                	sd	ra,88(sp)
    8000357e:	e8a2                	sd	s0,80(sp)
    80003580:	e4a6                	sd	s1,72(sp)
    80003582:	e0ca                	sd	s2,64(sp)
    80003584:	fc4e                	sd	s3,56(sp)
    80003586:	f852                	sd	s4,48(sp)
    80003588:	f456                	sd	s5,40(sp)
    8000358a:	f05a                	sd	s6,32(sp)
    8000358c:	ec5e                	sd	s7,24(sp)
    8000358e:	e862                	sd	s8,16(sp)
    80003590:	e466                	sd	s9,8(sp)
    80003592:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003594:	00021797          	auipc	a5,0x21
    80003598:	aa07a783          	lw	a5,-1376(a5) # 80024034 <sb+0x4>
    8000359c:	cbd1                	beqz	a5,80003630 <balloc+0xb6>
    8000359e:	8baa                	mv	s7,a0
    800035a0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800035a2:	00021b17          	auipc	s6,0x21
    800035a6:	a8eb0b13          	addi	s6,s6,-1394 # 80024030 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035aa:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800035ac:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035ae:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800035b0:	6c89                	lui	s9,0x2
    800035b2:	a831                	j	800035ce <balloc+0x54>
    brelse(bp);
    800035b4:	854a                	mv	a0,s2
    800035b6:	00000097          	auipc	ra,0x0
    800035ba:	dfc080e7          	jalr	-516(ra) # 800033b2 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800035be:	015c87bb          	addw	a5,s9,s5
    800035c2:	00078a9b          	sext.w	s5,a5
    800035c6:	004b2703          	lw	a4,4(s6)
    800035ca:	06eaf363          	bgeu	s5,a4,80003630 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800035ce:	41fad79b          	sraiw	a5,s5,0x1f
    800035d2:	0137d79b          	srliw	a5,a5,0x13
    800035d6:	015787bb          	addw	a5,a5,s5
    800035da:	40d7d79b          	sraiw	a5,a5,0xd
    800035de:	01cb2583          	lw	a1,28(s6)
    800035e2:	9dbd                	addw	a1,a1,a5
    800035e4:	855e                	mv	a0,s7
    800035e6:	00000097          	auipc	ra,0x0
    800035ea:	b78080e7          	jalr	-1160(ra) # 8000315e <bread>
    800035ee:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035f0:	004b2503          	lw	a0,4(s6)
    800035f4:	000a849b          	sext.w	s1,s5
    800035f8:	8662                	mv	a2,s8
    800035fa:	faa4fde3          	bgeu	s1,a0,800035b4 <balloc+0x3a>
      m = 1 << (bi % 8);
    800035fe:	41f6579b          	sraiw	a5,a2,0x1f
    80003602:	01d7d69b          	srliw	a3,a5,0x1d
    80003606:	00c6873b          	addw	a4,a3,a2
    8000360a:	00777793          	andi	a5,a4,7
    8000360e:	9f95                	subw	a5,a5,a3
    80003610:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003614:	4037571b          	sraiw	a4,a4,0x3
    80003618:	00e906b3          	add	a3,s2,a4
    8000361c:	0586c683          	lbu	a3,88(a3)
    80003620:	00d7f5b3          	and	a1,a5,a3
    80003624:	cd91                	beqz	a1,80003640 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003626:	2605                	addiw	a2,a2,1
    80003628:	2485                	addiw	s1,s1,1
    8000362a:	fd4618e3          	bne	a2,s4,800035fa <balloc+0x80>
    8000362e:	b759                	j	800035b4 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003630:	00005517          	auipc	a0,0x5
    80003634:	f9050513          	addi	a0,a0,-112 # 800085c0 <syscalls+0x108>
    80003638:	ffffd097          	auipc	ra,0xffffd
    8000363c:	f12080e7          	jalr	-238(ra) # 8000054a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003640:	974a                	add	a4,a4,s2
    80003642:	8fd5                	or	a5,a5,a3
    80003644:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003648:	854a                	mv	a0,s2
    8000364a:	00001097          	auipc	ra,0x1
    8000364e:	018080e7          	jalr	24(ra) # 80004662 <log_write>
        brelse(bp);
    80003652:	854a                	mv	a0,s2
    80003654:	00000097          	auipc	ra,0x0
    80003658:	d5e080e7          	jalr	-674(ra) # 800033b2 <brelse>
  bp = bread(dev, bno);
    8000365c:	85a6                	mv	a1,s1
    8000365e:	855e                	mv	a0,s7
    80003660:	00000097          	auipc	ra,0x0
    80003664:	afe080e7          	jalr	-1282(ra) # 8000315e <bread>
    80003668:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000366a:	40000613          	li	a2,1024
    8000366e:	4581                	li	a1,0
    80003670:	05850513          	addi	a0,a0,88
    80003674:	ffffe097          	auipc	ra,0xffffe
    80003678:	a38080e7          	jalr	-1480(ra) # 800010ac <memset>
  log_write(bp);
    8000367c:	854a                	mv	a0,s2
    8000367e:	00001097          	auipc	ra,0x1
    80003682:	fe4080e7          	jalr	-28(ra) # 80004662 <log_write>
  brelse(bp);
    80003686:	854a                	mv	a0,s2
    80003688:	00000097          	auipc	ra,0x0
    8000368c:	d2a080e7          	jalr	-726(ra) # 800033b2 <brelse>
}
    80003690:	8526                	mv	a0,s1
    80003692:	60e6                	ld	ra,88(sp)
    80003694:	6446                	ld	s0,80(sp)
    80003696:	64a6                	ld	s1,72(sp)
    80003698:	6906                	ld	s2,64(sp)
    8000369a:	79e2                	ld	s3,56(sp)
    8000369c:	7a42                	ld	s4,48(sp)
    8000369e:	7aa2                	ld	s5,40(sp)
    800036a0:	7b02                	ld	s6,32(sp)
    800036a2:	6be2                	ld	s7,24(sp)
    800036a4:	6c42                	ld	s8,16(sp)
    800036a6:	6ca2                	ld	s9,8(sp)
    800036a8:	6125                	addi	sp,sp,96
    800036aa:	8082                	ret

00000000800036ac <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800036ac:	7179                	addi	sp,sp,-48
    800036ae:	f406                	sd	ra,40(sp)
    800036b0:	f022                	sd	s0,32(sp)
    800036b2:	ec26                	sd	s1,24(sp)
    800036b4:	e84a                	sd	s2,16(sp)
    800036b6:	e44e                	sd	s3,8(sp)
    800036b8:	e052                	sd	s4,0(sp)
    800036ba:	1800                	addi	s0,sp,48
    800036bc:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800036be:	47ad                	li	a5,11
    800036c0:	04b7fe63          	bgeu	a5,a1,8000371c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800036c4:	ff45849b          	addiw	s1,a1,-12
    800036c8:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800036cc:	0ff00793          	li	a5,255
    800036d0:	0ae7e363          	bltu	a5,a4,80003776 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800036d4:	08852583          	lw	a1,136(a0)
    800036d8:	c5ad                	beqz	a1,80003742 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800036da:	00092503          	lw	a0,0(s2)
    800036de:	00000097          	auipc	ra,0x0
    800036e2:	a80080e7          	jalr	-1408(ra) # 8000315e <bread>
    800036e6:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800036e8:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800036ec:	02049593          	slli	a1,s1,0x20
    800036f0:	9181                	srli	a1,a1,0x20
    800036f2:	058a                	slli	a1,a1,0x2
    800036f4:	00b784b3          	add	s1,a5,a1
    800036f8:	0004a983          	lw	s3,0(s1)
    800036fc:	04098d63          	beqz	s3,80003756 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003700:	8552                	mv	a0,s4
    80003702:	00000097          	auipc	ra,0x0
    80003706:	cb0080e7          	jalr	-848(ra) # 800033b2 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000370a:	854e                	mv	a0,s3
    8000370c:	70a2                	ld	ra,40(sp)
    8000370e:	7402                	ld	s0,32(sp)
    80003710:	64e2                	ld	s1,24(sp)
    80003712:	6942                	ld	s2,16(sp)
    80003714:	69a2                	ld	s3,8(sp)
    80003716:	6a02                	ld	s4,0(sp)
    80003718:	6145                	addi	sp,sp,48
    8000371a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000371c:	02059493          	slli	s1,a1,0x20
    80003720:	9081                	srli	s1,s1,0x20
    80003722:	048a                	slli	s1,s1,0x2
    80003724:	94aa                	add	s1,s1,a0
    80003726:	0584a983          	lw	s3,88(s1)
    8000372a:	fe0990e3          	bnez	s3,8000370a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000372e:	4108                	lw	a0,0(a0)
    80003730:	00000097          	auipc	ra,0x0
    80003734:	e4a080e7          	jalr	-438(ra) # 8000357a <balloc>
    80003738:	0005099b          	sext.w	s3,a0
    8000373c:	0534ac23          	sw	s3,88(s1)
    80003740:	b7e9                	j	8000370a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003742:	4108                	lw	a0,0(a0)
    80003744:	00000097          	auipc	ra,0x0
    80003748:	e36080e7          	jalr	-458(ra) # 8000357a <balloc>
    8000374c:	0005059b          	sext.w	a1,a0
    80003750:	08b92423          	sw	a1,136(s2)
    80003754:	b759                	j	800036da <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003756:	00092503          	lw	a0,0(s2)
    8000375a:	00000097          	auipc	ra,0x0
    8000375e:	e20080e7          	jalr	-480(ra) # 8000357a <balloc>
    80003762:	0005099b          	sext.w	s3,a0
    80003766:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000376a:	8552                	mv	a0,s4
    8000376c:	00001097          	auipc	ra,0x1
    80003770:	ef6080e7          	jalr	-266(ra) # 80004662 <log_write>
    80003774:	b771                	j	80003700 <bmap+0x54>
  panic("bmap: out of range");
    80003776:	00005517          	auipc	a0,0x5
    8000377a:	e6250513          	addi	a0,a0,-414 # 800085d8 <syscalls+0x120>
    8000377e:	ffffd097          	auipc	ra,0xffffd
    80003782:	dcc080e7          	jalr	-564(ra) # 8000054a <panic>

0000000080003786 <iget>:
{
    80003786:	7179                	addi	sp,sp,-48
    80003788:	f406                	sd	ra,40(sp)
    8000378a:	f022                	sd	s0,32(sp)
    8000378c:	ec26                	sd	s1,24(sp)
    8000378e:	e84a                	sd	s2,16(sp)
    80003790:	e44e                	sd	s3,8(sp)
    80003792:	e052                	sd	s4,0(sp)
    80003794:	1800                	addi	s0,sp,48
    80003796:	89aa                	mv	s3,a0
    80003798:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000379a:	00021517          	auipc	a0,0x21
    8000379e:	8b650513          	addi	a0,a0,-1866 # 80024050 <icache>
    800037a2:	ffffd097          	auipc	ra,0xffffd
    800037a6:	52a080e7          	jalr	1322(ra) # 80000ccc <acquire>
  empty = 0;
    800037aa:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800037ac:	00021497          	auipc	s1,0x21
    800037b0:	8c448493          	addi	s1,s1,-1852 # 80024070 <icache+0x20>
    800037b4:	00022697          	auipc	a3,0x22
    800037b8:	4dc68693          	addi	a3,a3,1244 # 80025c90 <log>
    800037bc:	a039                	j	800037ca <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037be:	02090b63          	beqz	s2,800037f4 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800037c2:	09048493          	addi	s1,s1,144
    800037c6:	02d48a63          	beq	s1,a3,800037fa <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800037ca:	449c                	lw	a5,8(s1)
    800037cc:	fef059e3          	blez	a5,800037be <iget+0x38>
    800037d0:	4098                	lw	a4,0(s1)
    800037d2:	ff3716e3          	bne	a4,s3,800037be <iget+0x38>
    800037d6:	40d8                	lw	a4,4(s1)
    800037d8:	ff4713e3          	bne	a4,s4,800037be <iget+0x38>
      ip->ref++;
    800037dc:	2785                	addiw	a5,a5,1
    800037de:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800037e0:	00021517          	auipc	a0,0x21
    800037e4:	87050513          	addi	a0,a0,-1936 # 80024050 <icache>
    800037e8:	ffffd097          	auipc	ra,0xffffd
    800037ec:	5b4080e7          	jalr	1460(ra) # 80000d9c <release>
      return ip;
    800037f0:	8926                	mv	s2,s1
    800037f2:	a03d                	j	80003820 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037f4:	f7f9                	bnez	a5,800037c2 <iget+0x3c>
    800037f6:	8926                	mv	s2,s1
    800037f8:	b7e9                	j	800037c2 <iget+0x3c>
  if(empty == 0)
    800037fa:	02090c63          	beqz	s2,80003832 <iget+0xac>
  ip->dev = dev;
    800037fe:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003802:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003806:	4785                	li	a5,1
    80003808:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000380c:	04092423          	sw	zero,72(s2)
  release(&icache.lock);
    80003810:	00021517          	auipc	a0,0x21
    80003814:	84050513          	addi	a0,a0,-1984 # 80024050 <icache>
    80003818:	ffffd097          	auipc	ra,0xffffd
    8000381c:	584080e7          	jalr	1412(ra) # 80000d9c <release>
}
    80003820:	854a                	mv	a0,s2
    80003822:	70a2                	ld	ra,40(sp)
    80003824:	7402                	ld	s0,32(sp)
    80003826:	64e2                	ld	s1,24(sp)
    80003828:	6942                	ld	s2,16(sp)
    8000382a:	69a2                	ld	s3,8(sp)
    8000382c:	6a02                	ld	s4,0(sp)
    8000382e:	6145                	addi	sp,sp,48
    80003830:	8082                	ret
    panic("iget: no inodes");
    80003832:	00005517          	auipc	a0,0x5
    80003836:	dbe50513          	addi	a0,a0,-578 # 800085f0 <syscalls+0x138>
    8000383a:	ffffd097          	auipc	ra,0xffffd
    8000383e:	d10080e7          	jalr	-752(ra) # 8000054a <panic>

0000000080003842 <fsinit>:
fsinit(int dev) {
    80003842:	7179                	addi	sp,sp,-48
    80003844:	f406                	sd	ra,40(sp)
    80003846:	f022                	sd	s0,32(sp)
    80003848:	ec26                	sd	s1,24(sp)
    8000384a:	e84a                	sd	s2,16(sp)
    8000384c:	e44e                	sd	s3,8(sp)
    8000384e:	1800                	addi	s0,sp,48
    80003850:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003852:	4585                	li	a1,1
    80003854:	00000097          	auipc	ra,0x0
    80003858:	90a080e7          	jalr	-1782(ra) # 8000315e <bread>
    8000385c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000385e:	00020997          	auipc	s3,0x20
    80003862:	7d298993          	addi	s3,s3,2002 # 80024030 <sb>
    80003866:	02000613          	li	a2,32
    8000386a:	05850593          	addi	a1,a0,88
    8000386e:	854e                	mv	a0,s3
    80003870:	ffffe097          	auipc	ra,0xffffe
    80003874:	898080e7          	jalr	-1896(ra) # 80001108 <memmove>
  brelse(bp);
    80003878:	8526                	mv	a0,s1
    8000387a:	00000097          	auipc	ra,0x0
    8000387e:	b38080e7          	jalr	-1224(ra) # 800033b2 <brelse>
  if(sb.magic != FSMAGIC)
    80003882:	0009a703          	lw	a4,0(s3)
    80003886:	102037b7          	lui	a5,0x10203
    8000388a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000388e:	02f71263          	bne	a4,a5,800038b2 <fsinit+0x70>
  initlog(dev, &sb);
    80003892:	00020597          	auipc	a1,0x20
    80003896:	79e58593          	addi	a1,a1,1950 # 80024030 <sb>
    8000389a:	854a                	mv	a0,s2
    8000389c:	00001097          	auipc	ra,0x1
    800038a0:	b4a080e7          	jalr	-1206(ra) # 800043e6 <initlog>
}
    800038a4:	70a2                	ld	ra,40(sp)
    800038a6:	7402                	ld	s0,32(sp)
    800038a8:	64e2                	ld	s1,24(sp)
    800038aa:	6942                	ld	s2,16(sp)
    800038ac:	69a2                	ld	s3,8(sp)
    800038ae:	6145                	addi	sp,sp,48
    800038b0:	8082                	ret
    panic("invalid file system");
    800038b2:	00005517          	auipc	a0,0x5
    800038b6:	d4e50513          	addi	a0,a0,-690 # 80008600 <syscalls+0x148>
    800038ba:	ffffd097          	auipc	ra,0xffffd
    800038be:	c90080e7          	jalr	-880(ra) # 8000054a <panic>

00000000800038c2 <iinit>:
{
    800038c2:	7179                	addi	sp,sp,-48
    800038c4:	f406                	sd	ra,40(sp)
    800038c6:	f022                	sd	s0,32(sp)
    800038c8:	ec26                	sd	s1,24(sp)
    800038ca:	e84a                	sd	s2,16(sp)
    800038cc:	e44e                	sd	s3,8(sp)
    800038ce:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800038d0:	00005597          	auipc	a1,0x5
    800038d4:	d4858593          	addi	a1,a1,-696 # 80008618 <syscalls+0x160>
    800038d8:	00020517          	auipc	a0,0x20
    800038dc:	77850513          	addi	a0,a0,1912 # 80024050 <icache>
    800038e0:	ffffd097          	auipc	ra,0xffffd
    800038e4:	568080e7          	jalr	1384(ra) # 80000e48 <initlock>
  for(i = 0; i < NINODE; i++) {
    800038e8:	00020497          	auipc	s1,0x20
    800038ec:	79848493          	addi	s1,s1,1944 # 80024080 <icache+0x30>
    800038f0:	00022997          	auipc	s3,0x22
    800038f4:	3b098993          	addi	s3,s3,944 # 80025ca0 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800038f8:	00005917          	auipc	s2,0x5
    800038fc:	d2890913          	addi	s2,s2,-728 # 80008620 <syscalls+0x168>
    80003900:	85ca                	mv	a1,s2
    80003902:	8526                	mv	a0,s1
    80003904:	00001097          	auipc	ra,0x1
    80003908:	e4c080e7          	jalr	-436(ra) # 80004750 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000390c:	09048493          	addi	s1,s1,144
    80003910:	ff3498e3          	bne	s1,s3,80003900 <iinit+0x3e>
}
    80003914:	70a2                	ld	ra,40(sp)
    80003916:	7402                	ld	s0,32(sp)
    80003918:	64e2                	ld	s1,24(sp)
    8000391a:	6942                	ld	s2,16(sp)
    8000391c:	69a2                	ld	s3,8(sp)
    8000391e:	6145                	addi	sp,sp,48
    80003920:	8082                	ret

0000000080003922 <ialloc>:
{
    80003922:	715d                	addi	sp,sp,-80
    80003924:	e486                	sd	ra,72(sp)
    80003926:	e0a2                	sd	s0,64(sp)
    80003928:	fc26                	sd	s1,56(sp)
    8000392a:	f84a                	sd	s2,48(sp)
    8000392c:	f44e                	sd	s3,40(sp)
    8000392e:	f052                	sd	s4,32(sp)
    80003930:	ec56                	sd	s5,24(sp)
    80003932:	e85a                	sd	s6,16(sp)
    80003934:	e45e                	sd	s7,8(sp)
    80003936:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003938:	00020717          	auipc	a4,0x20
    8000393c:	70472703          	lw	a4,1796(a4) # 8002403c <sb+0xc>
    80003940:	4785                	li	a5,1
    80003942:	04e7fa63          	bgeu	a5,a4,80003996 <ialloc+0x74>
    80003946:	8aaa                	mv	s5,a0
    80003948:	8bae                	mv	s7,a1
    8000394a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000394c:	00020a17          	auipc	s4,0x20
    80003950:	6e4a0a13          	addi	s4,s4,1764 # 80024030 <sb>
    80003954:	00048b1b          	sext.w	s6,s1
    80003958:	0044d793          	srli	a5,s1,0x4
    8000395c:	018a2583          	lw	a1,24(s4)
    80003960:	9dbd                	addw	a1,a1,a5
    80003962:	8556                	mv	a0,s5
    80003964:	fffff097          	auipc	ra,0xfffff
    80003968:	7fa080e7          	jalr	2042(ra) # 8000315e <bread>
    8000396c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000396e:	05850993          	addi	s3,a0,88
    80003972:	00f4f793          	andi	a5,s1,15
    80003976:	079a                	slli	a5,a5,0x6
    80003978:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000397a:	00099783          	lh	a5,0(s3)
    8000397e:	c785                	beqz	a5,800039a6 <ialloc+0x84>
    brelse(bp);
    80003980:	00000097          	auipc	ra,0x0
    80003984:	a32080e7          	jalr	-1486(ra) # 800033b2 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003988:	0485                	addi	s1,s1,1
    8000398a:	00ca2703          	lw	a4,12(s4)
    8000398e:	0004879b          	sext.w	a5,s1
    80003992:	fce7e1e3          	bltu	a5,a4,80003954 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003996:	00005517          	auipc	a0,0x5
    8000399a:	c9250513          	addi	a0,a0,-878 # 80008628 <syscalls+0x170>
    8000399e:	ffffd097          	auipc	ra,0xffffd
    800039a2:	bac080e7          	jalr	-1108(ra) # 8000054a <panic>
      memset(dip, 0, sizeof(*dip));
    800039a6:	04000613          	li	a2,64
    800039aa:	4581                	li	a1,0
    800039ac:	854e                	mv	a0,s3
    800039ae:	ffffd097          	auipc	ra,0xffffd
    800039b2:	6fe080e7          	jalr	1790(ra) # 800010ac <memset>
      dip->type = type;
    800039b6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800039ba:	854a                	mv	a0,s2
    800039bc:	00001097          	auipc	ra,0x1
    800039c0:	ca6080e7          	jalr	-858(ra) # 80004662 <log_write>
      brelse(bp);
    800039c4:	854a                	mv	a0,s2
    800039c6:	00000097          	auipc	ra,0x0
    800039ca:	9ec080e7          	jalr	-1556(ra) # 800033b2 <brelse>
      return iget(dev, inum);
    800039ce:	85da                	mv	a1,s6
    800039d0:	8556                	mv	a0,s5
    800039d2:	00000097          	auipc	ra,0x0
    800039d6:	db4080e7          	jalr	-588(ra) # 80003786 <iget>
}
    800039da:	60a6                	ld	ra,72(sp)
    800039dc:	6406                	ld	s0,64(sp)
    800039de:	74e2                	ld	s1,56(sp)
    800039e0:	7942                	ld	s2,48(sp)
    800039e2:	79a2                	ld	s3,40(sp)
    800039e4:	7a02                	ld	s4,32(sp)
    800039e6:	6ae2                	ld	s5,24(sp)
    800039e8:	6b42                	ld	s6,16(sp)
    800039ea:	6ba2                	ld	s7,8(sp)
    800039ec:	6161                	addi	sp,sp,80
    800039ee:	8082                	ret

00000000800039f0 <iupdate>:
{
    800039f0:	1101                	addi	sp,sp,-32
    800039f2:	ec06                	sd	ra,24(sp)
    800039f4:	e822                	sd	s0,16(sp)
    800039f6:	e426                	sd	s1,8(sp)
    800039f8:	e04a                	sd	s2,0(sp)
    800039fa:	1000                	addi	s0,sp,32
    800039fc:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039fe:	415c                	lw	a5,4(a0)
    80003a00:	0047d79b          	srliw	a5,a5,0x4
    80003a04:	00020597          	auipc	a1,0x20
    80003a08:	6445a583          	lw	a1,1604(a1) # 80024048 <sb+0x18>
    80003a0c:	9dbd                	addw	a1,a1,a5
    80003a0e:	4108                	lw	a0,0(a0)
    80003a10:	fffff097          	auipc	ra,0xfffff
    80003a14:	74e080e7          	jalr	1870(ra) # 8000315e <bread>
    80003a18:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a1a:	05850793          	addi	a5,a0,88
    80003a1e:	40c8                	lw	a0,4(s1)
    80003a20:	893d                	andi	a0,a0,15
    80003a22:	051a                	slli	a0,a0,0x6
    80003a24:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003a26:	04c49703          	lh	a4,76(s1)
    80003a2a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003a2e:	04e49703          	lh	a4,78(s1)
    80003a32:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003a36:	05049703          	lh	a4,80(s1)
    80003a3a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003a3e:	05249703          	lh	a4,82(s1)
    80003a42:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003a46:	48f8                	lw	a4,84(s1)
    80003a48:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003a4a:	03400613          	li	a2,52
    80003a4e:	05848593          	addi	a1,s1,88
    80003a52:	0531                	addi	a0,a0,12
    80003a54:	ffffd097          	auipc	ra,0xffffd
    80003a58:	6b4080e7          	jalr	1716(ra) # 80001108 <memmove>
  log_write(bp);
    80003a5c:	854a                	mv	a0,s2
    80003a5e:	00001097          	auipc	ra,0x1
    80003a62:	c04080e7          	jalr	-1020(ra) # 80004662 <log_write>
  brelse(bp);
    80003a66:	854a                	mv	a0,s2
    80003a68:	00000097          	auipc	ra,0x0
    80003a6c:	94a080e7          	jalr	-1718(ra) # 800033b2 <brelse>
}
    80003a70:	60e2                	ld	ra,24(sp)
    80003a72:	6442                	ld	s0,16(sp)
    80003a74:	64a2                	ld	s1,8(sp)
    80003a76:	6902                	ld	s2,0(sp)
    80003a78:	6105                	addi	sp,sp,32
    80003a7a:	8082                	ret

0000000080003a7c <idup>:
{
    80003a7c:	1101                	addi	sp,sp,-32
    80003a7e:	ec06                	sd	ra,24(sp)
    80003a80:	e822                	sd	s0,16(sp)
    80003a82:	e426                	sd	s1,8(sp)
    80003a84:	1000                	addi	s0,sp,32
    80003a86:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003a88:	00020517          	auipc	a0,0x20
    80003a8c:	5c850513          	addi	a0,a0,1480 # 80024050 <icache>
    80003a90:	ffffd097          	auipc	ra,0xffffd
    80003a94:	23c080e7          	jalr	572(ra) # 80000ccc <acquire>
  ip->ref++;
    80003a98:	449c                	lw	a5,8(s1)
    80003a9a:	2785                	addiw	a5,a5,1
    80003a9c:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003a9e:	00020517          	auipc	a0,0x20
    80003aa2:	5b250513          	addi	a0,a0,1458 # 80024050 <icache>
    80003aa6:	ffffd097          	auipc	ra,0xffffd
    80003aaa:	2f6080e7          	jalr	758(ra) # 80000d9c <release>
}
    80003aae:	8526                	mv	a0,s1
    80003ab0:	60e2                	ld	ra,24(sp)
    80003ab2:	6442                	ld	s0,16(sp)
    80003ab4:	64a2                	ld	s1,8(sp)
    80003ab6:	6105                	addi	sp,sp,32
    80003ab8:	8082                	ret

0000000080003aba <ilock>:
{
    80003aba:	1101                	addi	sp,sp,-32
    80003abc:	ec06                	sd	ra,24(sp)
    80003abe:	e822                	sd	s0,16(sp)
    80003ac0:	e426                	sd	s1,8(sp)
    80003ac2:	e04a                	sd	s2,0(sp)
    80003ac4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003ac6:	c115                	beqz	a0,80003aea <ilock+0x30>
    80003ac8:	84aa                	mv	s1,a0
    80003aca:	451c                	lw	a5,8(a0)
    80003acc:	00f05f63          	blez	a5,80003aea <ilock+0x30>
  acquiresleep(&ip->lock);
    80003ad0:	0541                	addi	a0,a0,16
    80003ad2:	00001097          	auipc	ra,0x1
    80003ad6:	cb8080e7          	jalr	-840(ra) # 8000478a <acquiresleep>
  if(ip->valid == 0){
    80003ada:	44bc                	lw	a5,72(s1)
    80003adc:	cf99                	beqz	a5,80003afa <ilock+0x40>
}
    80003ade:	60e2                	ld	ra,24(sp)
    80003ae0:	6442                	ld	s0,16(sp)
    80003ae2:	64a2                	ld	s1,8(sp)
    80003ae4:	6902                	ld	s2,0(sp)
    80003ae6:	6105                	addi	sp,sp,32
    80003ae8:	8082                	ret
    panic("ilock");
    80003aea:	00005517          	auipc	a0,0x5
    80003aee:	b5650513          	addi	a0,a0,-1194 # 80008640 <syscalls+0x188>
    80003af2:	ffffd097          	auipc	ra,0xffffd
    80003af6:	a58080e7          	jalr	-1448(ra) # 8000054a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003afa:	40dc                	lw	a5,4(s1)
    80003afc:	0047d79b          	srliw	a5,a5,0x4
    80003b00:	00020597          	auipc	a1,0x20
    80003b04:	5485a583          	lw	a1,1352(a1) # 80024048 <sb+0x18>
    80003b08:	9dbd                	addw	a1,a1,a5
    80003b0a:	4088                	lw	a0,0(s1)
    80003b0c:	fffff097          	auipc	ra,0xfffff
    80003b10:	652080e7          	jalr	1618(ra) # 8000315e <bread>
    80003b14:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b16:	05850593          	addi	a1,a0,88
    80003b1a:	40dc                	lw	a5,4(s1)
    80003b1c:	8bbd                	andi	a5,a5,15
    80003b1e:	079a                	slli	a5,a5,0x6
    80003b20:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003b22:	00059783          	lh	a5,0(a1)
    80003b26:	04f49623          	sh	a5,76(s1)
    ip->major = dip->major;
    80003b2a:	00259783          	lh	a5,2(a1)
    80003b2e:	04f49723          	sh	a5,78(s1)
    ip->minor = dip->minor;
    80003b32:	00459783          	lh	a5,4(a1)
    80003b36:	04f49823          	sh	a5,80(s1)
    ip->nlink = dip->nlink;
    80003b3a:	00659783          	lh	a5,6(a1)
    80003b3e:	04f49923          	sh	a5,82(s1)
    ip->size = dip->size;
    80003b42:	459c                	lw	a5,8(a1)
    80003b44:	c8fc                	sw	a5,84(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003b46:	03400613          	li	a2,52
    80003b4a:	05b1                	addi	a1,a1,12
    80003b4c:	05848513          	addi	a0,s1,88
    80003b50:	ffffd097          	auipc	ra,0xffffd
    80003b54:	5b8080e7          	jalr	1464(ra) # 80001108 <memmove>
    brelse(bp);
    80003b58:	854a                	mv	a0,s2
    80003b5a:	00000097          	auipc	ra,0x0
    80003b5e:	858080e7          	jalr	-1960(ra) # 800033b2 <brelse>
    ip->valid = 1;
    80003b62:	4785                	li	a5,1
    80003b64:	c4bc                	sw	a5,72(s1)
    if(ip->type == 0)
    80003b66:	04c49783          	lh	a5,76(s1)
    80003b6a:	fbb5                	bnez	a5,80003ade <ilock+0x24>
      panic("ilock: no type");
    80003b6c:	00005517          	auipc	a0,0x5
    80003b70:	adc50513          	addi	a0,a0,-1316 # 80008648 <syscalls+0x190>
    80003b74:	ffffd097          	auipc	ra,0xffffd
    80003b78:	9d6080e7          	jalr	-1578(ra) # 8000054a <panic>

0000000080003b7c <iunlock>:
{
    80003b7c:	1101                	addi	sp,sp,-32
    80003b7e:	ec06                	sd	ra,24(sp)
    80003b80:	e822                	sd	s0,16(sp)
    80003b82:	e426                	sd	s1,8(sp)
    80003b84:	e04a                	sd	s2,0(sp)
    80003b86:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003b88:	c905                	beqz	a0,80003bb8 <iunlock+0x3c>
    80003b8a:	84aa                	mv	s1,a0
    80003b8c:	01050913          	addi	s2,a0,16
    80003b90:	854a                	mv	a0,s2
    80003b92:	00001097          	auipc	ra,0x1
    80003b96:	c92080e7          	jalr	-878(ra) # 80004824 <holdingsleep>
    80003b9a:	cd19                	beqz	a0,80003bb8 <iunlock+0x3c>
    80003b9c:	449c                	lw	a5,8(s1)
    80003b9e:	00f05d63          	blez	a5,80003bb8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ba2:	854a                	mv	a0,s2
    80003ba4:	00001097          	auipc	ra,0x1
    80003ba8:	c3c080e7          	jalr	-964(ra) # 800047e0 <releasesleep>
}
    80003bac:	60e2                	ld	ra,24(sp)
    80003bae:	6442                	ld	s0,16(sp)
    80003bb0:	64a2                	ld	s1,8(sp)
    80003bb2:	6902                	ld	s2,0(sp)
    80003bb4:	6105                	addi	sp,sp,32
    80003bb6:	8082                	ret
    panic("iunlock");
    80003bb8:	00005517          	auipc	a0,0x5
    80003bbc:	aa050513          	addi	a0,a0,-1376 # 80008658 <syscalls+0x1a0>
    80003bc0:	ffffd097          	auipc	ra,0xffffd
    80003bc4:	98a080e7          	jalr	-1654(ra) # 8000054a <panic>

0000000080003bc8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003bc8:	7179                	addi	sp,sp,-48
    80003bca:	f406                	sd	ra,40(sp)
    80003bcc:	f022                	sd	s0,32(sp)
    80003bce:	ec26                	sd	s1,24(sp)
    80003bd0:	e84a                	sd	s2,16(sp)
    80003bd2:	e44e                	sd	s3,8(sp)
    80003bd4:	e052                	sd	s4,0(sp)
    80003bd6:	1800                	addi	s0,sp,48
    80003bd8:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003bda:	05850493          	addi	s1,a0,88
    80003bde:	08850913          	addi	s2,a0,136
    80003be2:	a021                	j	80003bea <itrunc+0x22>
    80003be4:	0491                	addi	s1,s1,4
    80003be6:	01248d63          	beq	s1,s2,80003c00 <itrunc+0x38>
    if(ip->addrs[i]){
    80003bea:	408c                	lw	a1,0(s1)
    80003bec:	dde5                	beqz	a1,80003be4 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003bee:	0009a503          	lw	a0,0(s3)
    80003bf2:	00000097          	auipc	ra,0x0
    80003bf6:	90c080e7          	jalr	-1780(ra) # 800034fe <bfree>
      ip->addrs[i] = 0;
    80003bfa:	0004a023          	sw	zero,0(s1)
    80003bfe:	b7dd                	j	80003be4 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003c00:	0889a583          	lw	a1,136(s3)
    80003c04:	e185                	bnez	a1,80003c24 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003c06:	0409aa23          	sw	zero,84(s3)
  iupdate(ip);
    80003c0a:	854e                	mv	a0,s3
    80003c0c:	00000097          	auipc	ra,0x0
    80003c10:	de4080e7          	jalr	-540(ra) # 800039f0 <iupdate>
}
    80003c14:	70a2                	ld	ra,40(sp)
    80003c16:	7402                	ld	s0,32(sp)
    80003c18:	64e2                	ld	s1,24(sp)
    80003c1a:	6942                	ld	s2,16(sp)
    80003c1c:	69a2                	ld	s3,8(sp)
    80003c1e:	6a02                	ld	s4,0(sp)
    80003c20:	6145                	addi	sp,sp,48
    80003c22:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003c24:	0009a503          	lw	a0,0(s3)
    80003c28:	fffff097          	auipc	ra,0xfffff
    80003c2c:	536080e7          	jalr	1334(ra) # 8000315e <bread>
    80003c30:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003c32:	05850493          	addi	s1,a0,88
    80003c36:	45850913          	addi	s2,a0,1112
    80003c3a:	a021                	j	80003c42 <itrunc+0x7a>
    80003c3c:	0491                	addi	s1,s1,4
    80003c3e:	01248b63          	beq	s1,s2,80003c54 <itrunc+0x8c>
      if(a[j])
    80003c42:	408c                	lw	a1,0(s1)
    80003c44:	dde5                	beqz	a1,80003c3c <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003c46:	0009a503          	lw	a0,0(s3)
    80003c4a:	00000097          	auipc	ra,0x0
    80003c4e:	8b4080e7          	jalr	-1868(ra) # 800034fe <bfree>
    80003c52:	b7ed                	j	80003c3c <itrunc+0x74>
    brelse(bp);
    80003c54:	8552                	mv	a0,s4
    80003c56:	fffff097          	auipc	ra,0xfffff
    80003c5a:	75c080e7          	jalr	1884(ra) # 800033b2 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003c5e:	0889a583          	lw	a1,136(s3)
    80003c62:	0009a503          	lw	a0,0(s3)
    80003c66:	00000097          	auipc	ra,0x0
    80003c6a:	898080e7          	jalr	-1896(ra) # 800034fe <bfree>
    ip->addrs[NDIRECT] = 0;
    80003c6e:	0809a423          	sw	zero,136(s3)
    80003c72:	bf51                	j	80003c06 <itrunc+0x3e>

0000000080003c74 <iput>:
{
    80003c74:	1101                	addi	sp,sp,-32
    80003c76:	ec06                	sd	ra,24(sp)
    80003c78:	e822                	sd	s0,16(sp)
    80003c7a:	e426                	sd	s1,8(sp)
    80003c7c:	e04a                	sd	s2,0(sp)
    80003c7e:	1000                	addi	s0,sp,32
    80003c80:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003c82:	00020517          	auipc	a0,0x20
    80003c86:	3ce50513          	addi	a0,a0,974 # 80024050 <icache>
    80003c8a:	ffffd097          	auipc	ra,0xffffd
    80003c8e:	042080e7          	jalr	66(ra) # 80000ccc <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c92:	4498                	lw	a4,8(s1)
    80003c94:	4785                	li	a5,1
    80003c96:	02f70363          	beq	a4,a5,80003cbc <iput+0x48>
  ip->ref--;
    80003c9a:	449c                	lw	a5,8(s1)
    80003c9c:	37fd                	addiw	a5,a5,-1
    80003c9e:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003ca0:	00020517          	auipc	a0,0x20
    80003ca4:	3b050513          	addi	a0,a0,944 # 80024050 <icache>
    80003ca8:	ffffd097          	auipc	ra,0xffffd
    80003cac:	0f4080e7          	jalr	244(ra) # 80000d9c <release>
}
    80003cb0:	60e2                	ld	ra,24(sp)
    80003cb2:	6442                	ld	s0,16(sp)
    80003cb4:	64a2                	ld	s1,8(sp)
    80003cb6:	6902                	ld	s2,0(sp)
    80003cb8:	6105                	addi	sp,sp,32
    80003cba:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003cbc:	44bc                	lw	a5,72(s1)
    80003cbe:	dff1                	beqz	a5,80003c9a <iput+0x26>
    80003cc0:	05249783          	lh	a5,82(s1)
    80003cc4:	fbf9                	bnez	a5,80003c9a <iput+0x26>
    acquiresleep(&ip->lock);
    80003cc6:	01048913          	addi	s2,s1,16
    80003cca:	854a                	mv	a0,s2
    80003ccc:	00001097          	auipc	ra,0x1
    80003cd0:	abe080e7          	jalr	-1346(ra) # 8000478a <acquiresleep>
    release(&icache.lock);
    80003cd4:	00020517          	auipc	a0,0x20
    80003cd8:	37c50513          	addi	a0,a0,892 # 80024050 <icache>
    80003cdc:	ffffd097          	auipc	ra,0xffffd
    80003ce0:	0c0080e7          	jalr	192(ra) # 80000d9c <release>
    itrunc(ip);
    80003ce4:	8526                	mv	a0,s1
    80003ce6:	00000097          	auipc	ra,0x0
    80003cea:	ee2080e7          	jalr	-286(ra) # 80003bc8 <itrunc>
    ip->type = 0;
    80003cee:	04049623          	sh	zero,76(s1)
    iupdate(ip);
    80003cf2:	8526                	mv	a0,s1
    80003cf4:	00000097          	auipc	ra,0x0
    80003cf8:	cfc080e7          	jalr	-772(ra) # 800039f0 <iupdate>
    ip->valid = 0;
    80003cfc:	0404a423          	sw	zero,72(s1)
    releasesleep(&ip->lock);
    80003d00:	854a                	mv	a0,s2
    80003d02:	00001097          	auipc	ra,0x1
    80003d06:	ade080e7          	jalr	-1314(ra) # 800047e0 <releasesleep>
    acquire(&icache.lock);
    80003d0a:	00020517          	auipc	a0,0x20
    80003d0e:	34650513          	addi	a0,a0,838 # 80024050 <icache>
    80003d12:	ffffd097          	auipc	ra,0xffffd
    80003d16:	fba080e7          	jalr	-70(ra) # 80000ccc <acquire>
    80003d1a:	b741                	j	80003c9a <iput+0x26>

0000000080003d1c <iunlockput>:
{
    80003d1c:	1101                	addi	sp,sp,-32
    80003d1e:	ec06                	sd	ra,24(sp)
    80003d20:	e822                	sd	s0,16(sp)
    80003d22:	e426                	sd	s1,8(sp)
    80003d24:	1000                	addi	s0,sp,32
    80003d26:	84aa                	mv	s1,a0
  iunlock(ip);
    80003d28:	00000097          	auipc	ra,0x0
    80003d2c:	e54080e7          	jalr	-428(ra) # 80003b7c <iunlock>
  iput(ip);
    80003d30:	8526                	mv	a0,s1
    80003d32:	00000097          	auipc	ra,0x0
    80003d36:	f42080e7          	jalr	-190(ra) # 80003c74 <iput>
}
    80003d3a:	60e2                	ld	ra,24(sp)
    80003d3c:	6442                	ld	s0,16(sp)
    80003d3e:	64a2                	ld	s1,8(sp)
    80003d40:	6105                	addi	sp,sp,32
    80003d42:	8082                	ret

0000000080003d44 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003d44:	1141                	addi	sp,sp,-16
    80003d46:	e422                	sd	s0,8(sp)
    80003d48:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003d4a:	411c                	lw	a5,0(a0)
    80003d4c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003d4e:	415c                	lw	a5,4(a0)
    80003d50:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003d52:	04c51783          	lh	a5,76(a0)
    80003d56:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003d5a:	05251783          	lh	a5,82(a0)
    80003d5e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003d62:	05456783          	lwu	a5,84(a0)
    80003d66:	e99c                	sd	a5,16(a1)
}
    80003d68:	6422                	ld	s0,8(sp)
    80003d6a:	0141                	addi	sp,sp,16
    80003d6c:	8082                	ret

0000000080003d6e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d6e:	497c                	lw	a5,84(a0)
    80003d70:	0ed7e963          	bltu	a5,a3,80003e62 <readi+0xf4>
{
    80003d74:	7159                	addi	sp,sp,-112
    80003d76:	f486                	sd	ra,104(sp)
    80003d78:	f0a2                	sd	s0,96(sp)
    80003d7a:	eca6                	sd	s1,88(sp)
    80003d7c:	e8ca                	sd	s2,80(sp)
    80003d7e:	e4ce                	sd	s3,72(sp)
    80003d80:	e0d2                	sd	s4,64(sp)
    80003d82:	fc56                	sd	s5,56(sp)
    80003d84:	f85a                	sd	s6,48(sp)
    80003d86:	f45e                	sd	s7,40(sp)
    80003d88:	f062                	sd	s8,32(sp)
    80003d8a:	ec66                	sd	s9,24(sp)
    80003d8c:	e86a                	sd	s10,16(sp)
    80003d8e:	e46e                	sd	s11,8(sp)
    80003d90:	1880                	addi	s0,sp,112
    80003d92:	8baa                	mv	s7,a0
    80003d94:	8c2e                	mv	s8,a1
    80003d96:	8ab2                	mv	s5,a2
    80003d98:	84b6                	mv	s1,a3
    80003d9a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d9c:	9f35                	addw	a4,a4,a3
    return 0;
    80003d9e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003da0:	0ad76063          	bltu	a4,a3,80003e40 <readi+0xd2>
  if(off + n > ip->size)
    80003da4:	00e7f463          	bgeu	a5,a4,80003dac <readi+0x3e>
    n = ip->size - off;
    80003da8:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003dac:	0a0b0963          	beqz	s6,80003e5e <readi+0xf0>
    80003db0:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003db2:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003db6:	5cfd                	li	s9,-1
    80003db8:	a82d                	j	80003df2 <readi+0x84>
    80003dba:	020a1d93          	slli	s11,s4,0x20
    80003dbe:	020ddd93          	srli	s11,s11,0x20
    80003dc2:	05890793          	addi	a5,s2,88
    80003dc6:	86ee                	mv	a3,s11
    80003dc8:	963e                	add	a2,a2,a5
    80003dca:	85d6                	mv	a1,s5
    80003dcc:	8562                	mv	a0,s8
    80003dce:	fffff097          	auipc	ra,0xfffff
    80003dd2:	9b2080e7          	jalr	-1614(ra) # 80002780 <either_copyout>
    80003dd6:	05950d63          	beq	a0,s9,80003e30 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003dda:	854a                	mv	a0,s2
    80003ddc:	fffff097          	auipc	ra,0xfffff
    80003de0:	5d6080e7          	jalr	1494(ra) # 800033b2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003de4:	013a09bb          	addw	s3,s4,s3
    80003de8:	009a04bb          	addw	s1,s4,s1
    80003dec:	9aee                	add	s5,s5,s11
    80003dee:	0569f763          	bgeu	s3,s6,80003e3c <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003df2:	000ba903          	lw	s2,0(s7)
    80003df6:	00a4d59b          	srliw	a1,s1,0xa
    80003dfa:	855e                	mv	a0,s7
    80003dfc:	00000097          	auipc	ra,0x0
    80003e00:	8b0080e7          	jalr	-1872(ra) # 800036ac <bmap>
    80003e04:	0005059b          	sext.w	a1,a0
    80003e08:	854a                	mv	a0,s2
    80003e0a:	fffff097          	auipc	ra,0xfffff
    80003e0e:	354080e7          	jalr	852(ra) # 8000315e <bread>
    80003e12:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e14:	3ff4f613          	andi	a2,s1,1023
    80003e18:	40cd07bb          	subw	a5,s10,a2
    80003e1c:	413b073b          	subw	a4,s6,s3
    80003e20:	8a3e                	mv	s4,a5
    80003e22:	2781                	sext.w	a5,a5
    80003e24:	0007069b          	sext.w	a3,a4
    80003e28:	f8f6f9e3          	bgeu	a3,a5,80003dba <readi+0x4c>
    80003e2c:	8a3a                	mv	s4,a4
    80003e2e:	b771                	j	80003dba <readi+0x4c>
      brelse(bp);
    80003e30:	854a                	mv	a0,s2
    80003e32:	fffff097          	auipc	ra,0xfffff
    80003e36:	580080e7          	jalr	1408(ra) # 800033b2 <brelse>
      tot = -1;
    80003e3a:	59fd                	li	s3,-1
  }
  return tot;
    80003e3c:	0009851b          	sext.w	a0,s3
}
    80003e40:	70a6                	ld	ra,104(sp)
    80003e42:	7406                	ld	s0,96(sp)
    80003e44:	64e6                	ld	s1,88(sp)
    80003e46:	6946                	ld	s2,80(sp)
    80003e48:	69a6                	ld	s3,72(sp)
    80003e4a:	6a06                	ld	s4,64(sp)
    80003e4c:	7ae2                	ld	s5,56(sp)
    80003e4e:	7b42                	ld	s6,48(sp)
    80003e50:	7ba2                	ld	s7,40(sp)
    80003e52:	7c02                	ld	s8,32(sp)
    80003e54:	6ce2                	ld	s9,24(sp)
    80003e56:	6d42                	ld	s10,16(sp)
    80003e58:	6da2                	ld	s11,8(sp)
    80003e5a:	6165                	addi	sp,sp,112
    80003e5c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e5e:	89da                	mv	s3,s6
    80003e60:	bff1                	j	80003e3c <readi+0xce>
    return 0;
    80003e62:	4501                	li	a0,0
}
    80003e64:	8082                	ret

0000000080003e66 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e66:	497c                	lw	a5,84(a0)
    80003e68:	10d7e763          	bltu	a5,a3,80003f76 <writei+0x110>
{
    80003e6c:	7159                	addi	sp,sp,-112
    80003e6e:	f486                	sd	ra,104(sp)
    80003e70:	f0a2                	sd	s0,96(sp)
    80003e72:	eca6                	sd	s1,88(sp)
    80003e74:	e8ca                	sd	s2,80(sp)
    80003e76:	e4ce                	sd	s3,72(sp)
    80003e78:	e0d2                	sd	s4,64(sp)
    80003e7a:	fc56                	sd	s5,56(sp)
    80003e7c:	f85a                	sd	s6,48(sp)
    80003e7e:	f45e                	sd	s7,40(sp)
    80003e80:	f062                	sd	s8,32(sp)
    80003e82:	ec66                	sd	s9,24(sp)
    80003e84:	e86a                	sd	s10,16(sp)
    80003e86:	e46e                	sd	s11,8(sp)
    80003e88:	1880                	addi	s0,sp,112
    80003e8a:	8baa                	mv	s7,a0
    80003e8c:	8c2e                	mv	s8,a1
    80003e8e:	8ab2                	mv	s5,a2
    80003e90:	8936                	mv	s2,a3
    80003e92:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e94:	00e687bb          	addw	a5,a3,a4
    80003e98:	0ed7e163          	bltu	a5,a3,80003f7a <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003e9c:	00043737          	lui	a4,0x43
    80003ea0:	0cf76f63          	bltu	a4,a5,80003f7e <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ea4:	0a0b0863          	beqz	s6,80003f54 <writei+0xee>
    80003ea8:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003eaa:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003eae:	5cfd                	li	s9,-1
    80003eb0:	a091                	j	80003ef4 <writei+0x8e>
    80003eb2:	02099d93          	slli	s11,s3,0x20
    80003eb6:	020ddd93          	srli	s11,s11,0x20
    80003eba:	05848793          	addi	a5,s1,88
    80003ebe:	86ee                	mv	a3,s11
    80003ec0:	8656                	mv	a2,s5
    80003ec2:	85e2                	mv	a1,s8
    80003ec4:	953e                	add	a0,a0,a5
    80003ec6:	fffff097          	auipc	ra,0xfffff
    80003eca:	910080e7          	jalr	-1776(ra) # 800027d6 <either_copyin>
    80003ece:	07950263          	beq	a0,s9,80003f32 <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003ed2:	8526                	mv	a0,s1
    80003ed4:	00000097          	auipc	ra,0x0
    80003ed8:	78e080e7          	jalr	1934(ra) # 80004662 <log_write>
    brelse(bp);
    80003edc:	8526                	mv	a0,s1
    80003ede:	fffff097          	auipc	ra,0xfffff
    80003ee2:	4d4080e7          	jalr	1236(ra) # 800033b2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ee6:	01498a3b          	addw	s4,s3,s4
    80003eea:	0129893b          	addw	s2,s3,s2
    80003eee:	9aee                	add	s5,s5,s11
    80003ef0:	056a7763          	bgeu	s4,s6,80003f3e <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ef4:	000ba483          	lw	s1,0(s7)
    80003ef8:	00a9559b          	srliw	a1,s2,0xa
    80003efc:	855e                	mv	a0,s7
    80003efe:	fffff097          	auipc	ra,0xfffff
    80003f02:	7ae080e7          	jalr	1966(ra) # 800036ac <bmap>
    80003f06:	0005059b          	sext.w	a1,a0
    80003f0a:	8526                	mv	a0,s1
    80003f0c:	fffff097          	auipc	ra,0xfffff
    80003f10:	252080e7          	jalr	594(ra) # 8000315e <bread>
    80003f14:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f16:	3ff97513          	andi	a0,s2,1023
    80003f1a:	40ad07bb          	subw	a5,s10,a0
    80003f1e:	414b073b          	subw	a4,s6,s4
    80003f22:	89be                	mv	s3,a5
    80003f24:	2781                	sext.w	a5,a5
    80003f26:	0007069b          	sext.w	a3,a4
    80003f2a:	f8f6f4e3          	bgeu	a3,a5,80003eb2 <writei+0x4c>
    80003f2e:	89ba                	mv	s3,a4
    80003f30:	b749                	j	80003eb2 <writei+0x4c>
      brelse(bp);
    80003f32:	8526                	mv	a0,s1
    80003f34:	fffff097          	auipc	ra,0xfffff
    80003f38:	47e080e7          	jalr	1150(ra) # 800033b2 <brelse>
      n = -1;
    80003f3c:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003f3e:	054ba783          	lw	a5,84(s7)
    80003f42:	0127f463          	bgeu	a5,s2,80003f4a <writei+0xe4>
      ip->size = off;
    80003f46:	052baa23          	sw	s2,84(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003f4a:	855e                	mv	a0,s7
    80003f4c:	00000097          	auipc	ra,0x0
    80003f50:	aa4080e7          	jalr	-1372(ra) # 800039f0 <iupdate>
  }

  return n;
    80003f54:	000b051b          	sext.w	a0,s6
}
    80003f58:	70a6                	ld	ra,104(sp)
    80003f5a:	7406                	ld	s0,96(sp)
    80003f5c:	64e6                	ld	s1,88(sp)
    80003f5e:	6946                	ld	s2,80(sp)
    80003f60:	69a6                	ld	s3,72(sp)
    80003f62:	6a06                	ld	s4,64(sp)
    80003f64:	7ae2                	ld	s5,56(sp)
    80003f66:	7b42                	ld	s6,48(sp)
    80003f68:	7ba2                	ld	s7,40(sp)
    80003f6a:	7c02                	ld	s8,32(sp)
    80003f6c:	6ce2                	ld	s9,24(sp)
    80003f6e:	6d42                	ld	s10,16(sp)
    80003f70:	6da2                	ld	s11,8(sp)
    80003f72:	6165                	addi	sp,sp,112
    80003f74:	8082                	ret
    return -1;
    80003f76:	557d                	li	a0,-1
}
    80003f78:	8082                	ret
    return -1;
    80003f7a:	557d                	li	a0,-1
    80003f7c:	bff1                	j	80003f58 <writei+0xf2>
    return -1;
    80003f7e:	557d                	li	a0,-1
    80003f80:	bfe1                	j	80003f58 <writei+0xf2>

0000000080003f82 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003f82:	1141                	addi	sp,sp,-16
    80003f84:	e406                	sd	ra,8(sp)
    80003f86:	e022                	sd	s0,0(sp)
    80003f88:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003f8a:	4639                	li	a2,14
    80003f8c:	ffffd097          	auipc	ra,0xffffd
    80003f90:	1f8080e7          	jalr	504(ra) # 80001184 <strncmp>
}
    80003f94:	60a2                	ld	ra,8(sp)
    80003f96:	6402                	ld	s0,0(sp)
    80003f98:	0141                	addi	sp,sp,16
    80003f9a:	8082                	ret

0000000080003f9c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003f9c:	7139                	addi	sp,sp,-64
    80003f9e:	fc06                	sd	ra,56(sp)
    80003fa0:	f822                	sd	s0,48(sp)
    80003fa2:	f426                	sd	s1,40(sp)
    80003fa4:	f04a                	sd	s2,32(sp)
    80003fa6:	ec4e                	sd	s3,24(sp)
    80003fa8:	e852                	sd	s4,16(sp)
    80003faa:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003fac:	04c51703          	lh	a4,76(a0)
    80003fb0:	4785                	li	a5,1
    80003fb2:	00f71a63          	bne	a4,a5,80003fc6 <dirlookup+0x2a>
    80003fb6:	892a                	mv	s2,a0
    80003fb8:	89ae                	mv	s3,a1
    80003fba:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fbc:	497c                	lw	a5,84(a0)
    80003fbe:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003fc0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fc2:	e79d                	bnez	a5,80003ff0 <dirlookup+0x54>
    80003fc4:	a8a5                	j	8000403c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003fc6:	00004517          	auipc	a0,0x4
    80003fca:	69a50513          	addi	a0,a0,1690 # 80008660 <syscalls+0x1a8>
    80003fce:	ffffc097          	auipc	ra,0xffffc
    80003fd2:	57c080e7          	jalr	1404(ra) # 8000054a <panic>
      panic("dirlookup read");
    80003fd6:	00004517          	auipc	a0,0x4
    80003fda:	6a250513          	addi	a0,a0,1698 # 80008678 <syscalls+0x1c0>
    80003fde:	ffffc097          	auipc	ra,0xffffc
    80003fe2:	56c080e7          	jalr	1388(ra) # 8000054a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fe6:	24c1                	addiw	s1,s1,16
    80003fe8:	05492783          	lw	a5,84(s2)
    80003fec:	04f4f763          	bgeu	s1,a5,8000403a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ff0:	4741                	li	a4,16
    80003ff2:	86a6                	mv	a3,s1
    80003ff4:	fc040613          	addi	a2,s0,-64
    80003ff8:	4581                	li	a1,0
    80003ffa:	854a                	mv	a0,s2
    80003ffc:	00000097          	auipc	ra,0x0
    80004000:	d72080e7          	jalr	-654(ra) # 80003d6e <readi>
    80004004:	47c1                	li	a5,16
    80004006:	fcf518e3          	bne	a0,a5,80003fd6 <dirlookup+0x3a>
    if(de.inum == 0)
    8000400a:	fc045783          	lhu	a5,-64(s0)
    8000400e:	dfe1                	beqz	a5,80003fe6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004010:	fc240593          	addi	a1,s0,-62
    80004014:	854e                	mv	a0,s3
    80004016:	00000097          	auipc	ra,0x0
    8000401a:	f6c080e7          	jalr	-148(ra) # 80003f82 <namecmp>
    8000401e:	f561                	bnez	a0,80003fe6 <dirlookup+0x4a>
      if(poff)
    80004020:	000a0463          	beqz	s4,80004028 <dirlookup+0x8c>
        *poff = off;
    80004024:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004028:	fc045583          	lhu	a1,-64(s0)
    8000402c:	00092503          	lw	a0,0(s2)
    80004030:	fffff097          	auipc	ra,0xfffff
    80004034:	756080e7          	jalr	1878(ra) # 80003786 <iget>
    80004038:	a011                	j	8000403c <dirlookup+0xa0>
  return 0;
    8000403a:	4501                	li	a0,0
}
    8000403c:	70e2                	ld	ra,56(sp)
    8000403e:	7442                	ld	s0,48(sp)
    80004040:	74a2                	ld	s1,40(sp)
    80004042:	7902                	ld	s2,32(sp)
    80004044:	69e2                	ld	s3,24(sp)
    80004046:	6a42                	ld	s4,16(sp)
    80004048:	6121                	addi	sp,sp,64
    8000404a:	8082                	ret

000000008000404c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000404c:	711d                	addi	sp,sp,-96
    8000404e:	ec86                	sd	ra,88(sp)
    80004050:	e8a2                	sd	s0,80(sp)
    80004052:	e4a6                	sd	s1,72(sp)
    80004054:	e0ca                	sd	s2,64(sp)
    80004056:	fc4e                	sd	s3,56(sp)
    80004058:	f852                	sd	s4,48(sp)
    8000405a:	f456                	sd	s5,40(sp)
    8000405c:	f05a                	sd	s6,32(sp)
    8000405e:	ec5e                	sd	s7,24(sp)
    80004060:	e862                	sd	s8,16(sp)
    80004062:	e466                	sd	s9,8(sp)
    80004064:	1080                	addi	s0,sp,96
    80004066:	84aa                	mv	s1,a0
    80004068:	8aae                	mv	s5,a1
    8000406a:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000406c:	00054703          	lbu	a4,0(a0)
    80004070:	02f00793          	li	a5,47
    80004074:	02f70363          	beq	a4,a5,8000409a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004078:	ffffe097          	auipc	ra,0xffffe
    8000407c:	c9a080e7          	jalr	-870(ra) # 80001d12 <myproc>
    80004080:	15853503          	ld	a0,344(a0)
    80004084:	00000097          	auipc	ra,0x0
    80004088:	9f8080e7          	jalr	-1544(ra) # 80003a7c <idup>
    8000408c:	89aa                	mv	s3,a0
  while(*path == '/')
    8000408e:	02f00913          	li	s2,47
  len = path - s;
    80004092:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80004094:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004096:	4b85                	li	s7,1
    80004098:	a865                	j	80004150 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000409a:	4585                	li	a1,1
    8000409c:	4505                	li	a0,1
    8000409e:	fffff097          	auipc	ra,0xfffff
    800040a2:	6e8080e7          	jalr	1768(ra) # 80003786 <iget>
    800040a6:	89aa                	mv	s3,a0
    800040a8:	b7dd                	j	8000408e <namex+0x42>
      iunlockput(ip);
    800040aa:	854e                	mv	a0,s3
    800040ac:	00000097          	auipc	ra,0x0
    800040b0:	c70080e7          	jalr	-912(ra) # 80003d1c <iunlockput>
      return 0;
    800040b4:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800040b6:	854e                	mv	a0,s3
    800040b8:	60e6                	ld	ra,88(sp)
    800040ba:	6446                	ld	s0,80(sp)
    800040bc:	64a6                	ld	s1,72(sp)
    800040be:	6906                	ld	s2,64(sp)
    800040c0:	79e2                	ld	s3,56(sp)
    800040c2:	7a42                	ld	s4,48(sp)
    800040c4:	7aa2                	ld	s5,40(sp)
    800040c6:	7b02                	ld	s6,32(sp)
    800040c8:	6be2                	ld	s7,24(sp)
    800040ca:	6c42                	ld	s8,16(sp)
    800040cc:	6ca2                	ld	s9,8(sp)
    800040ce:	6125                	addi	sp,sp,96
    800040d0:	8082                	ret
      iunlock(ip);
    800040d2:	854e                	mv	a0,s3
    800040d4:	00000097          	auipc	ra,0x0
    800040d8:	aa8080e7          	jalr	-1368(ra) # 80003b7c <iunlock>
      return ip;
    800040dc:	bfe9                	j	800040b6 <namex+0x6a>
      iunlockput(ip);
    800040de:	854e                	mv	a0,s3
    800040e0:	00000097          	auipc	ra,0x0
    800040e4:	c3c080e7          	jalr	-964(ra) # 80003d1c <iunlockput>
      return 0;
    800040e8:	89e6                	mv	s3,s9
    800040ea:	b7f1                	j	800040b6 <namex+0x6a>
  len = path - s;
    800040ec:	40b48633          	sub	a2,s1,a1
    800040f0:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800040f4:	099c5463          	bge	s8,s9,8000417c <namex+0x130>
    memmove(name, s, DIRSIZ);
    800040f8:	4639                	li	a2,14
    800040fa:	8552                	mv	a0,s4
    800040fc:	ffffd097          	auipc	ra,0xffffd
    80004100:	00c080e7          	jalr	12(ra) # 80001108 <memmove>
  while(*path == '/')
    80004104:	0004c783          	lbu	a5,0(s1)
    80004108:	01279763          	bne	a5,s2,80004116 <namex+0xca>
    path++;
    8000410c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000410e:	0004c783          	lbu	a5,0(s1)
    80004112:	ff278de3          	beq	a5,s2,8000410c <namex+0xc0>
    ilock(ip);
    80004116:	854e                	mv	a0,s3
    80004118:	00000097          	auipc	ra,0x0
    8000411c:	9a2080e7          	jalr	-1630(ra) # 80003aba <ilock>
    if(ip->type != T_DIR){
    80004120:	04c99783          	lh	a5,76(s3)
    80004124:	f97793e3          	bne	a5,s7,800040aa <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004128:	000a8563          	beqz	s5,80004132 <namex+0xe6>
    8000412c:	0004c783          	lbu	a5,0(s1)
    80004130:	d3cd                	beqz	a5,800040d2 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004132:	865a                	mv	a2,s6
    80004134:	85d2                	mv	a1,s4
    80004136:	854e                	mv	a0,s3
    80004138:	00000097          	auipc	ra,0x0
    8000413c:	e64080e7          	jalr	-412(ra) # 80003f9c <dirlookup>
    80004140:	8caa                	mv	s9,a0
    80004142:	dd51                	beqz	a0,800040de <namex+0x92>
    iunlockput(ip);
    80004144:	854e                	mv	a0,s3
    80004146:	00000097          	auipc	ra,0x0
    8000414a:	bd6080e7          	jalr	-1066(ra) # 80003d1c <iunlockput>
    ip = next;
    8000414e:	89e6                	mv	s3,s9
  while(*path == '/')
    80004150:	0004c783          	lbu	a5,0(s1)
    80004154:	05279763          	bne	a5,s2,800041a2 <namex+0x156>
    path++;
    80004158:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000415a:	0004c783          	lbu	a5,0(s1)
    8000415e:	ff278de3          	beq	a5,s2,80004158 <namex+0x10c>
  if(*path == 0)
    80004162:	c79d                	beqz	a5,80004190 <namex+0x144>
    path++;
    80004164:	85a6                	mv	a1,s1
  len = path - s;
    80004166:	8cda                	mv	s9,s6
    80004168:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    8000416a:	01278963          	beq	a5,s2,8000417c <namex+0x130>
    8000416e:	dfbd                	beqz	a5,800040ec <namex+0xa0>
    path++;
    80004170:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004172:	0004c783          	lbu	a5,0(s1)
    80004176:	ff279ce3          	bne	a5,s2,8000416e <namex+0x122>
    8000417a:	bf8d                	j	800040ec <namex+0xa0>
    memmove(name, s, len);
    8000417c:	2601                	sext.w	a2,a2
    8000417e:	8552                	mv	a0,s4
    80004180:	ffffd097          	auipc	ra,0xffffd
    80004184:	f88080e7          	jalr	-120(ra) # 80001108 <memmove>
    name[len] = 0;
    80004188:	9cd2                	add	s9,s9,s4
    8000418a:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000418e:	bf9d                	j	80004104 <namex+0xb8>
  if(nameiparent){
    80004190:	f20a83e3          	beqz	s5,800040b6 <namex+0x6a>
    iput(ip);
    80004194:	854e                	mv	a0,s3
    80004196:	00000097          	auipc	ra,0x0
    8000419a:	ade080e7          	jalr	-1314(ra) # 80003c74 <iput>
    return 0;
    8000419e:	4981                	li	s3,0
    800041a0:	bf19                	j	800040b6 <namex+0x6a>
  if(*path == 0)
    800041a2:	d7fd                	beqz	a5,80004190 <namex+0x144>
  while(*path != '/' && *path != 0)
    800041a4:	0004c783          	lbu	a5,0(s1)
    800041a8:	85a6                	mv	a1,s1
    800041aa:	b7d1                	j	8000416e <namex+0x122>

00000000800041ac <dirlink>:
{
    800041ac:	7139                	addi	sp,sp,-64
    800041ae:	fc06                	sd	ra,56(sp)
    800041b0:	f822                	sd	s0,48(sp)
    800041b2:	f426                	sd	s1,40(sp)
    800041b4:	f04a                	sd	s2,32(sp)
    800041b6:	ec4e                	sd	s3,24(sp)
    800041b8:	e852                	sd	s4,16(sp)
    800041ba:	0080                	addi	s0,sp,64
    800041bc:	892a                	mv	s2,a0
    800041be:	8a2e                	mv	s4,a1
    800041c0:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800041c2:	4601                	li	a2,0
    800041c4:	00000097          	auipc	ra,0x0
    800041c8:	dd8080e7          	jalr	-552(ra) # 80003f9c <dirlookup>
    800041cc:	e93d                	bnez	a0,80004242 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041ce:	05492483          	lw	s1,84(s2)
    800041d2:	c49d                	beqz	s1,80004200 <dirlink+0x54>
    800041d4:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041d6:	4741                	li	a4,16
    800041d8:	86a6                	mv	a3,s1
    800041da:	fc040613          	addi	a2,s0,-64
    800041de:	4581                	li	a1,0
    800041e0:	854a                	mv	a0,s2
    800041e2:	00000097          	auipc	ra,0x0
    800041e6:	b8c080e7          	jalr	-1140(ra) # 80003d6e <readi>
    800041ea:	47c1                	li	a5,16
    800041ec:	06f51163          	bne	a0,a5,8000424e <dirlink+0xa2>
    if(de.inum == 0)
    800041f0:	fc045783          	lhu	a5,-64(s0)
    800041f4:	c791                	beqz	a5,80004200 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041f6:	24c1                	addiw	s1,s1,16
    800041f8:	05492783          	lw	a5,84(s2)
    800041fc:	fcf4ede3          	bltu	s1,a5,800041d6 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004200:	4639                	li	a2,14
    80004202:	85d2                	mv	a1,s4
    80004204:	fc240513          	addi	a0,s0,-62
    80004208:	ffffd097          	auipc	ra,0xffffd
    8000420c:	fb8080e7          	jalr	-72(ra) # 800011c0 <strncpy>
  de.inum = inum;
    80004210:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004214:	4741                	li	a4,16
    80004216:	86a6                	mv	a3,s1
    80004218:	fc040613          	addi	a2,s0,-64
    8000421c:	4581                	li	a1,0
    8000421e:	854a                	mv	a0,s2
    80004220:	00000097          	auipc	ra,0x0
    80004224:	c46080e7          	jalr	-954(ra) # 80003e66 <writei>
    80004228:	872a                	mv	a4,a0
    8000422a:	47c1                	li	a5,16
  return 0;
    8000422c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000422e:	02f71863          	bne	a4,a5,8000425e <dirlink+0xb2>
}
    80004232:	70e2                	ld	ra,56(sp)
    80004234:	7442                	ld	s0,48(sp)
    80004236:	74a2                	ld	s1,40(sp)
    80004238:	7902                	ld	s2,32(sp)
    8000423a:	69e2                	ld	s3,24(sp)
    8000423c:	6a42                	ld	s4,16(sp)
    8000423e:	6121                	addi	sp,sp,64
    80004240:	8082                	ret
    iput(ip);
    80004242:	00000097          	auipc	ra,0x0
    80004246:	a32080e7          	jalr	-1486(ra) # 80003c74 <iput>
    return -1;
    8000424a:	557d                	li	a0,-1
    8000424c:	b7dd                	j	80004232 <dirlink+0x86>
      panic("dirlink read");
    8000424e:	00004517          	auipc	a0,0x4
    80004252:	43a50513          	addi	a0,a0,1082 # 80008688 <syscalls+0x1d0>
    80004256:	ffffc097          	auipc	ra,0xffffc
    8000425a:	2f4080e7          	jalr	756(ra) # 8000054a <panic>
    panic("dirlink");
    8000425e:	00004517          	auipc	a0,0x4
    80004262:	54a50513          	addi	a0,a0,1354 # 800087a8 <syscalls+0x2f0>
    80004266:	ffffc097          	auipc	ra,0xffffc
    8000426a:	2e4080e7          	jalr	740(ra) # 8000054a <panic>

000000008000426e <namei>:

struct inode*
namei(char *path)
{
    8000426e:	1101                	addi	sp,sp,-32
    80004270:	ec06                	sd	ra,24(sp)
    80004272:	e822                	sd	s0,16(sp)
    80004274:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004276:	fe040613          	addi	a2,s0,-32
    8000427a:	4581                	li	a1,0
    8000427c:	00000097          	auipc	ra,0x0
    80004280:	dd0080e7          	jalr	-560(ra) # 8000404c <namex>
}
    80004284:	60e2                	ld	ra,24(sp)
    80004286:	6442                	ld	s0,16(sp)
    80004288:	6105                	addi	sp,sp,32
    8000428a:	8082                	ret

000000008000428c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000428c:	1141                	addi	sp,sp,-16
    8000428e:	e406                	sd	ra,8(sp)
    80004290:	e022                	sd	s0,0(sp)
    80004292:	0800                	addi	s0,sp,16
    80004294:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004296:	4585                	li	a1,1
    80004298:	00000097          	auipc	ra,0x0
    8000429c:	db4080e7          	jalr	-588(ra) # 8000404c <namex>
}
    800042a0:	60a2                	ld	ra,8(sp)
    800042a2:	6402                	ld	s0,0(sp)
    800042a4:	0141                	addi	sp,sp,16
    800042a6:	8082                	ret

00000000800042a8 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800042a8:	1101                	addi	sp,sp,-32
    800042aa:	ec06                	sd	ra,24(sp)
    800042ac:	e822                	sd	s0,16(sp)
    800042ae:	e426                	sd	s1,8(sp)
    800042b0:	e04a                	sd	s2,0(sp)
    800042b2:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800042b4:	00022917          	auipc	s2,0x22
    800042b8:	9dc90913          	addi	s2,s2,-1572 # 80025c90 <log>
    800042bc:	02092583          	lw	a1,32(s2)
    800042c0:	03092503          	lw	a0,48(s2)
    800042c4:	fffff097          	auipc	ra,0xfffff
    800042c8:	e9a080e7          	jalr	-358(ra) # 8000315e <bread>
    800042cc:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800042ce:	03492683          	lw	a3,52(s2)
    800042d2:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800042d4:	02d05763          	blez	a3,80004302 <write_head+0x5a>
    800042d8:	00022797          	auipc	a5,0x22
    800042dc:	9f078793          	addi	a5,a5,-1552 # 80025cc8 <log+0x38>
    800042e0:	05c50713          	addi	a4,a0,92
    800042e4:	36fd                	addiw	a3,a3,-1
    800042e6:	1682                	slli	a3,a3,0x20
    800042e8:	9281                	srli	a3,a3,0x20
    800042ea:	068a                	slli	a3,a3,0x2
    800042ec:	00022617          	auipc	a2,0x22
    800042f0:	9e060613          	addi	a2,a2,-1568 # 80025ccc <log+0x3c>
    800042f4:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800042f6:	4390                	lw	a2,0(a5)
    800042f8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800042fa:	0791                	addi	a5,a5,4
    800042fc:	0711                	addi	a4,a4,4
    800042fe:	fed79ce3          	bne	a5,a3,800042f6 <write_head+0x4e>
  }
  bwrite(buf);
    80004302:	8526                	mv	a0,s1
    80004304:	fffff097          	auipc	ra,0xfffff
    80004308:	070080e7          	jalr	112(ra) # 80003374 <bwrite>
  brelse(buf);
    8000430c:	8526                	mv	a0,s1
    8000430e:	fffff097          	auipc	ra,0xfffff
    80004312:	0a4080e7          	jalr	164(ra) # 800033b2 <brelse>
}
    80004316:	60e2                	ld	ra,24(sp)
    80004318:	6442                	ld	s0,16(sp)
    8000431a:	64a2                	ld	s1,8(sp)
    8000431c:	6902                	ld	s2,0(sp)
    8000431e:	6105                	addi	sp,sp,32
    80004320:	8082                	ret

0000000080004322 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004322:	00022797          	auipc	a5,0x22
    80004326:	9a27a783          	lw	a5,-1630(a5) # 80025cc4 <log+0x34>
    8000432a:	0af05d63          	blez	a5,800043e4 <install_trans+0xc2>
{
    8000432e:	7139                	addi	sp,sp,-64
    80004330:	fc06                	sd	ra,56(sp)
    80004332:	f822                	sd	s0,48(sp)
    80004334:	f426                	sd	s1,40(sp)
    80004336:	f04a                	sd	s2,32(sp)
    80004338:	ec4e                	sd	s3,24(sp)
    8000433a:	e852                	sd	s4,16(sp)
    8000433c:	e456                	sd	s5,8(sp)
    8000433e:	e05a                	sd	s6,0(sp)
    80004340:	0080                	addi	s0,sp,64
    80004342:	8b2a                	mv	s6,a0
    80004344:	00022a97          	auipc	s5,0x22
    80004348:	984a8a93          	addi	s5,s5,-1660 # 80025cc8 <log+0x38>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000434c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000434e:	00022997          	auipc	s3,0x22
    80004352:	94298993          	addi	s3,s3,-1726 # 80025c90 <log>
    80004356:	a00d                	j	80004378 <install_trans+0x56>
    brelse(lbuf);
    80004358:	854a                	mv	a0,s2
    8000435a:	fffff097          	auipc	ra,0xfffff
    8000435e:	058080e7          	jalr	88(ra) # 800033b2 <brelse>
    brelse(dbuf);
    80004362:	8526                	mv	a0,s1
    80004364:	fffff097          	auipc	ra,0xfffff
    80004368:	04e080e7          	jalr	78(ra) # 800033b2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000436c:	2a05                	addiw	s4,s4,1
    8000436e:	0a91                	addi	s5,s5,4
    80004370:	0349a783          	lw	a5,52(s3)
    80004374:	04fa5e63          	bge	s4,a5,800043d0 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004378:	0209a583          	lw	a1,32(s3)
    8000437c:	014585bb          	addw	a1,a1,s4
    80004380:	2585                	addiw	a1,a1,1
    80004382:	0309a503          	lw	a0,48(s3)
    80004386:	fffff097          	auipc	ra,0xfffff
    8000438a:	dd8080e7          	jalr	-552(ra) # 8000315e <bread>
    8000438e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004390:	000aa583          	lw	a1,0(s5)
    80004394:	0309a503          	lw	a0,48(s3)
    80004398:	fffff097          	auipc	ra,0xfffff
    8000439c:	dc6080e7          	jalr	-570(ra) # 8000315e <bread>
    800043a0:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800043a2:	40000613          	li	a2,1024
    800043a6:	05890593          	addi	a1,s2,88
    800043aa:	05850513          	addi	a0,a0,88
    800043ae:	ffffd097          	auipc	ra,0xffffd
    800043b2:	d5a080e7          	jalr	-678(ra) # 80001108 <memmove>
    bwrite(dbuf);  // write dst to disk
    800043b6:	8526                	mv	a0,s1
    800043b8:	fffff097          	auipc	ra,0xfffff
    800043bc:	fbc080e7          	jalr	-68(ra) # 80003374 <bwrite>
    if(recovering == 0)
    800043c0:	f80b1ce3          	bnez	s6,80004358 <install_trans+0x36>
      bunpin(dbuf);
    800043c4:	8526                	mv	a0,s1
    800043c6:	fffff097          	auipc	ra,0xfffff
    800043ca:	0de080e7          	jalr	222(ra) # 800034a4 <bunpin>
    800043ce:	b769                	j	80004358 <install_trans+0x36>
}
    800043d0:	70e2                	ld	ra,56(sp)
    800043d2:	7442                	ld	s0,48(sp)
    800043d4:	74a2                	ld	s1,40(sp)
    800043d6:	7902                	ld	s2,32(sp)
    800043d8:	69e2                	ld	s3,24(sp)
    800043da:	6a42                	ld	s4,16(sp)
    800043dc:	6aa2                	ld	s5,8(sp)
    800043de:	6b02                	ld	s6,0(sp)
    800043e0:	6121                	addi	sp,sp,64
    800043e2:	8082                	ret
    800043e4:	8082                	ret

00000000800043e6 <initlog>:
{
    800043e6:	7179                	addi	sp,sp,-48
    800043e8:	f406                	sd	ra,40(sp)
    800043ea:	f022                	sd	s0,32(sp)
    800043ec:	ec26                	sd	s1,24(sp)
    800043ee:	e84a                	sd	s2,16(sp)
    800043f0:	e44e                	sd	s3,8(sp)
    800043f2:	1800                	addi	s0,sp,48
    800043f4:	892a                	mv	s2,a0
    800043f6:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800043f8:	00022497          	auipc	s1,0x22
    800043fc:	89848493          	addi	s1,s1,-1896 # 80025c90 <log>
    80004400:	00004597          	auipc	a1,0x4
    80004404:	29858593          	addi	a1,a1,664 # 80008698 <syscalls+0x1e0>
    80004408:	8526                	mv	a0,s1
    8000440a:	ffffd097          	auipc	ra,0xffffd
    8000440e:	a3e080e7          	jalr	-1474(ra) # 80000e48 <initlock>
  log.start = sb->logstart;
    80004412:	0149a583          	lw	a1,20(s3)
    80004416:	d08c                	sw	a1,32(s1)
  log.size = sb->nlog;
    80004418:	0109a783          	lw	a5,16(s3)
    8000441c:	d0dc                	sw	a5,36(s1)
  log.dev = dev;
    8000441e:	0324a823          	sw	s2,48(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004422:	854a                	mv	a0,s2
    80004424:	fffff097          	auipc	ra,0xfffff
    80004428:	d3a080e7          	jalr	-710(ra) # 8000315e <bread>
  log.lh.n = lh->n;
    8000442c:	4d34                	lw	a3,88(a0)
    8000442e:	d8d4                	sw	a3,52(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004430:	02d05563          	blez	a3,8000445a <initlog+0x74>
    80004434:	05c50793          	addi	a5,a0,92
    80004438:	00022717          	auipc	a4,0x22
    8000443c:	89070713          	addi	a4,a4,-1904 # 80025cc8 <log+0x38>
    80004440:	36fd                	addiw	a3,a3,-1
    80004442:	1682                	slli	a3,a3,0x20
    80004444:	9281                	srli	a3,a3,0x20
    80004446:	068a                	slli	a3,a3,0x2
    80004448:	06050613          	addi	a2,a0,96
    8000444c:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000444e:	4390                	lw	a2,0(a5)
    80004450:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004452:	0791                	addi	a5,a5,4
    80004454:	0711                	addi	a4,a4,4
    80004456:	fed79ce3          	bne	a5,a3,8000444e <initlog+0x68>
  brelse(buf);
    8000445a:	fffff097          	auipc	ra,0xfffff
    8000445e:	f58080e7          	jalr	-168(ra) # 800033b2 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004462:	4505                	li	a0,1
    80004464:	00000097          	auipc	ra,0x0
    80004468:	ebe080e7          	jalr	-322(ra) # 80004322 <install_trans>
  log.lh.n = 0;
    8000446c:	00022797          	auipc	a5,0x22
    80004470:	8407ac23          	sw	zero,-1960(a5) # 80025cc4 <log+0x34>
  write_head(); // clear the log
    80004474:	00000097          	auipc	ra,0x0
    80004478:	e34080e7          	jalr	-460(ra) # 800042a8 <write_head>
}
    8000447c:	70a2                	ld	ra,40(sp)
    8000447e:	7402                	ld	s0,32(sp)
    80004480:	64e2                	ld	s1,24(sp)
    80004482:	6942                	ld	s2,16(sp)
    80004484:	69a2                	ld	s3,8(sp)
    80004486:	6145                	addi	sp,sp,48
    80004488:	8082                	ret

000000008000448a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000448a:	1101                	addi	sp,sp,-32
    8000448c:	ec06                	sd	ra,24(sp)
    8000448e:	e822                	sd	s0,16(sp)
    80004490:	e426                	sd	s1,8(sp)
    80004492:	e04a                	sd	s2,0(sp)
    80004494:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004496:	00021517          	auipc	a0,0x21
    8000449a:	7fa50513          	addi	a0,a0,2042 # 80025c90 <log>
    8000449e:	ffffd097          	auipc	ra,0xffffd
    800044a2:	82e080e7          	jalr	-2002(ra) # 80000ccc <acquire>
  while(1){
    if(log.committing){
    800044a6:	00021497          	auipc	s1,0x21
    800044aa:	7ea48493          	addi	s1,s1,2026 # 80025c90 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044ae:	4979                	li	s2,30
    800044b0:	a039                	j	800044be <begin_op+0x34>
      sleep(&log, &log.lock);
    800044b2:	85a6                	mv	a1,s1
    800044b4:	8526                	mv	a0,s1
    800044b6:	ffffe097          	auipc	ra,0xffffe
    800044ba:	070080e7          	jalr	112(ra) # 80002526 <sleep>
    if(log.committing){
    800044be:	54dc                	lw	a5,44(s1)
    800044c0:	fbed                	bnez	a5,800044b2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044c2:	549c                	lw	a5,40(s1)
    800044c4:	0017871b          	addiw	a4,a5,1
    800044c8:	0007069b          	sext.w	a3,a4
    800044cc:	0027179b          	slliw	a5,a4,0x2
    800044d0:	9fb9                	addw	a5,a5,a4
    800044d2:	0017979b          	slliw	a5,a5,0x1
    800044d6:	58d8                	lw	a4,52(s1)
    800044d8:	9fb9                	addw	a5,a5,a4
    800044da:	00f95963          	bge	s2,a5,800044ec <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800044de:	85a6                	mv	a1,s1
    800044e0:	8526                	mv	a0,s1
    800044e2:	ffffe097          	auipc	ra,0xffffe
    800044e6:	044080e7          	jalr	68(ra) # 80002526 <sleep>
    800044ea:	bfd1                	j	800044be <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800044ec:	00021517          	auipc	a0,0x21
    800044f0:	7a450513          	addi	a0,a0,1956 # 80025c90 <log>
    800044f4:	d514                	sw	a3,40(a0)
      release(&log.lock);
    800044f6:	ffffd097          	auipc	ra,0xffffd
    800044fa:	8a6080e7          	jalr	-1882(ra) # 80000d9c <release>
      break;
    }
  }
}
    800044fe:	60e2                	ld	ra,24(sp)
    80004500:	6442                	ld	s0,16(sp)
    80004502:	64a2                	ld	s1,8(sp)
    80004504:	6902                	ld	s2,0(sp)
    80004506:	6105                	addi	sp,sp,32
    80004508:	8082                	ret

000000008000450a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000450a:	7139                	addi	sp,sp,-64
    8000450c:	fc06                	sd	ra,56(sp)
    8000450e:	f822                	sd	s0,48(sp)
    80004510:	f426                	sd	s1,40(sp)
    80004512:	f04a                	sd	s2,32(sp)
    80004514:	ec4e                	sd	s3,24(sp)
    80004516:	e852                	sd	s4,16(sp)
    80004518:	e456                	sd	s5,8(sp)
    8000451a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000451c:	00021497          	auipc	s1,0x21
    80004520:	77448493          	addi	s1,s1,1908 # 80025c90 <log>
    80004524:	8526                	mv	a0,s1
    80004526:	ffffc097          	auipc	ra,0xffffc
    8000452a:	7a6080e7          	jalr	1958(ra) # 80000ccc <acquire>
  log.outstanding -= 1;
    8000452e:	549c                	lw	a5,40(s1)
    80004530:	37fd                	addiw	a5,a5,-1
    80004532:	0007891b          	sext.w	s2,a5
    80004536:	d49c                	sw	a5,40(s1)
  if(log.committing)
    80004538:	54dc                	lw	a5,44(s1)
    8000453a:	e7b9                	bnez	a5,80004588 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000453c:	04091e63          	bnez	s2,80004598 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004540:	00021497          	auipc	s1,0x21
    80004544:	75048493          	addi	s1,s1,1872 # 80025c90 <log>
    80004548:	4785                	li	a5,1
    8000454a:	d4dc                	sw	a5,44(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000454c:	8526                	mv	a0,s1
    8000454e:	ffffd097          	auipc	ra,0xffffd
    80004552:	84e080e7          	jalr	-1970(ra) # 80000d9c <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004556:	58dc                	lw	a5,52(s1)
    80004558:	06f04763          	bgtz	a5,800045c6 <end_op+0xbc>
    acquire(&log.lock);
    8000455c:	00021497          	auipc	s1,0x21
    80004560:	73448493          	addi	s1,s1,1844 # 80025c90 <log>
    80004564:	8526                	mv	a0,s1
    80004566:	ffffc097          	auipc	ra,0xffffc
    8000456a:	766080e7          	jalr	1894(ra) # 80000ccc <acquire>
    log.committing = 0;
    8000456e:	0204a623          	sw	zero,44(s1)
    wakeup(&log);
    80004572:	8526                	mv	a0,s1
    80004574:	ffffe097          	auipc	ra,0xffffe
    80004578:	132080e7          	jalr	306(ra) # 800026a6 <wakeup>
    release(&log.lock);
    8000457c:	8526                	mv	a0,s1
    8000457e:	ffffd097          	auipc	ra,0xffffd
    80004582:	81e080e7          	jalr	-2018(ra) # 80000d9c <release>
}
    80004586:	a03d                	j	800045b4 <end_op+0xaa>
    panic("log.committing");
    80004588:	00004517          	auipc	a0,0x4
    8000458c:	11850513          	addi	a0,a0,280 # 800086a0 <syscalls+0x1e8>
    80004590:	ffffc097          	auipc	ra,0xffffc
    80004594:	fba080e7          	jalr	-70(ra) # 8000054a <panic>
    wakeup(&log);
    80004598:	00021497          	auipc	s1,0x21
    8000459c:	6f848493          	addi	s1,s1,1784 # 80025c90 <log>
    800045a0:	8526                	mv	a0,s1
    800045a2:	ffffe097          	auipc	ra,0xffffe
    800045a6:	104080e7          	jalr	260(ra) # 800026a6 <wakeup>
  release(&log.lock);
    800045aa:	8526                	mv	a0,s1
    800045ac:	ffffc097          	auipc	ra,0xffffc
    800045b0:	7f0080e7          	jalr	2032(ra) # 80000d9c <release>
}
    800045b4:	70e2                	ld	ra,56(sp)
    800045b6:	7442                	ld	s0,48(sp)
    800045b8:	74a2                	ld	s1,40(sp)
    800045ba:	7902                	ld	s2,32(sp)
    800045bc:	69e2                	ld	s3,24(sp)
    800045be:	6a42                	ld	s4,16(sp)
    800045c0:	6aa2                	ld	s5,8(sp)
    800045c2:	6121                	addi	sp,sp,64
    800045c4:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800045c6:	00021a97          	auipc	s5,0x21
    800045ca:	702a8a93          	addi	s5,s5,1794 # 80025cc8 <log+0x38>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800045ce:	00021a17          	auipc	s4,0x21
    800045d2:	6c2a0a13          	addi	s4,s4,1730 # 80025c90 <log>
    800045d6:	020a2583          	lw	a1,32(s4)
    800045da:	012585bb          	addw	a1,a1,s2
    800045de:	2585                	addiw	a1,a1,1
    800045e0:	030a2503          	lw	a0,48(s4)
    800045e4:	fffff097          	auipc	ra,0xfffff
    800045e8:	b7a080e7          	jalr	-1158(ra) # 8000315e <bread>
    800045ec:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800045ee:	000aa583          	lw	a1,0(s5)
    800045f2:	030a2503          	lw	a0,48(s4)
    800045f6:	fffff097          	auipc	ra,0xfffff
    800045fa:	b68080e7          	jalr	-1176(ra) # 8000315e <bread>
    800045fe:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004600:	40000613          	li	a2,1024
    80004604:	05850593          	addi	a1,a0,88
    80004608:	05848513          	addi	a0,s1,88
    8000460c:	ffffd097          	auipc	ra,0xffffd
    80004610:	afc080e7          	jalr	-1284(ra) # 80001108 <memmove>
    bwrite(to);  // write the log
    80004614:	8526                	mv	a0,s1
    80004616:	fffff097          	auipc	ra,0xfffff
    8000461a:	d5e080e7          	jalr	-674(ra) # 80003374 <bwrite>
    brelse(from);
    8000461e:	854e                	mv	a0,s3
    80004620:	fffff097          	auipc	ra,0xfffff
    80004624:	d92080e7          	jalr	-622(ra) # 800033b2 <brelse>
    brelse(to);
    80004628:	8526                	mv	a0,s1
    8000462a:	fffff097          	auipc	ra,0xfffff
    8000462e:	d88080e7          	jalr	-632(ra) # 800033b2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004632:	2905                	addiw	s2,s2,1
    80004634:	0a91                	addi	s5,s5,4
    80004636:	034a2783          	lw	a5,52(s4)
    8000463a:	f8f94ee3          	blt	s2,a5,800045d6 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000463e:	00000097          	auipc	ra,0x0
    80004642:	c6a080e7          	jalr	-918(ra) # 800042a8 <write_head>
    install_trans(0); // Now install writes to home locations
    80004646:	4501                	li	a0,0
    80004648:	00000097          	auipc	ra,0x0
    8000464c:	cda080e7          	jalr	-806(ra) # 80004322 <install_trans>
    log.lh.n = 0;
    80004650:	00021797          	auipc	a5,0x21
    80004654:	6607aa23          	sw	zero,1652(a5) # 80025cc4 <log+0x34>
    write_head();    // Erase the transaction from the log
    80004658:	00000097          	auipc	ra,0x0
    8000465c:	c50080e7          	jalr	-944(ra) # 800042a8 <write_head>
    80004660:	bdf5                	j	8000455c <end_op+0x52>

0000000080004662 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004662:	1101                	addi	sp,sp,-32
    80004664:	ec06                	sd	ra,24(sp)
    80004666:	e822                	sd	s0,16(sp)
    80004668:	e426                	sd	s1,8(sp)
    8000466a:	e04a                	sd	s2,0(sp)
    8000466c:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000466e:	00021717          	auipc	a4,0x21
    80004672:	65672703          	lw	a4,1622(a4) # 80025cc4 <log+0x34>
    80004676:	47f5                	li	a5,29
    80004678:	08e7c063          	blt	a5,a4,800046f8 <log_write+0x96>
    8000467c:	84aa                	mv	s1,a0
    8000467e:	00021797          	auipc	a5,0x21
    80004682:	6367a783          	lw	a5,1590(a5) # 80025cb4 <log+0x24>
    80004686:	37fd                	addiw	a5,a5,-1
    80004688:	06f75863          	bge	a4,a5,800046f8 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000468c:	00021797          	auipc	a5,0x21
    80004690:	62c7a783          	lw	a5,1580(a5) # 80025cb8 <log+0x28>
    80004694:	06f05a63          	blez	a5,80004708 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004698:	00021917          	auipc	s2,0x21
    8000469c:	5f890913          	addi	s2,s2,1528 # 80025c90 <log>
    800046a0:	854a                	mv	a0,s2
    800046a2:	ffffc097          	auipc	ra,0xffffc
    800046a6:	62a080e7          	jalr	1578(ra) # 80000ccc <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800046aa:	03492603          	lw	a2,52(s2)
    800046ae:	06c05563          	blez	a2,80004718 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800046b2:	44cc                	lw	a1,12(s1)
    800046b4:	00021717          	auipc	a4,0x21
    800046b8:	61470713          	addi	a4,a4,1556 # 80025cc8 <log+0x38>
  for (i = 0; i < log.lh.n; i++) {
    800046bc:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800046be:	4314                	lw	a3,0(a4)
    800046c0:	04b68d63          	beq	a3,a1,8000471a <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800046c4:	2785                	addiw	a5,a5,1
    800046c6:	0711                	addi	a4,a4,4
    800046c8:	fec79be3          	bne	a5,a2,800046be <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800046cc:	0631                	addi	a2,a2,12
    800046ce:	060a                	slli	a2,a2,0x2
    800046d0:	00021797          	auipc	a5,0x21
    800046d4:	5c078793          	addi	a5,a5,1472 # 80025c90 <log>
    800046d8:	963e                	add	a2,a2,a5
    800046da:	44dc                	lw	a5,12(s1)
    800046dc:	c61c                	sw	a5,8(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800046de:	8526                	mv	a0,s1
    800046e0:	fffff097          	auipc	ra,0xfffff
    800046e4:	d6a080e7          	jalr	-662(ra) # 8000344a <bpin>
    log.lh.n++;
    800046e8:	00021717          	auipc	a4,0x21
    800046ec:	5a870713          	addi	a4,a4,1448 # 80025c90 <log>
    800046f0:	5b5c                	lw	a5,52(a4)
    800046f2:	2785                	addiw	a5,a5,1
    800046f4:	db5c                	sw	a5,52(a4)
    800046f6:	a83d                	j	80004734 <log_write+0xd2>
    panic("too big a transaction");
    800046f8:	00004517          	auipc	a0,0x4
    800046fc:	fb850513          	addi	a0,a0,-72 # 800086b0 <syscalls+0x1f8>
    80004700:	ffffc097          	auipc	ra,0xffffc
    80004704:	e4a080e7          	jalr	-438(ra) # 8000054a <panic>
    panic("log_write outside of trans");
    80004708:	00004517          	auipc	a0,0x4
    8000470c:	fc050513          	addi	a0,a0,-64 # 800086c8 <syscalls+0x210>
    80004710:	ffffc097          	auipc	ra,0xffffc
    80004714:	e3a080e7          	jalr	-454(ra) # 8000054a <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004718:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    8000471a:	00c78713          	addi	a4,a5,12
    8000471e:	00271693          	slli	a3,a4,0x2
    80004722:	00021717          	auipc	a4,0x21
    80004726:	56e70713          	addi	a4,a4,1390 # 80025c90 <log>
    8000472a:	9736                	add	a4,a4,a3
    8000472c:	44d4                	lw	a3,12(s1)
    8000472e:	c714                	sw	a3,8(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004730:	faf607e3          	beq	a2,a5,800046de <log_write+0x7c>
  }
  release(&log.lock);
    80004734:	00021517          	auipc	a0,0x21
    80004738:	55c50513          	addi	a0,a0,1372 # 80025c90 <log>
    8000473c:	ffffc097          	auipc	ra,0xffffc
    80004740:	660080e7          	jalr	1632(ra) # 80000d9c <release>
}
    80004744:	60e2                	ld	ra,24(sp)
    80004746:	6442                	ld	s0,16(sp)
    80004748:	64a2                	ld	s1,8(sp)
    8000474a:	6902                	ld	s2,0(sp)
    8000474c:	6105                	addi	sp,sp,32
    8000474e:	8082                	ret

0000000080004750 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004750:	1101                	addi	sp,sp,-32
    80004752:	ec06                	sd	ra,24(sp)
    80004754:	e822                	sd	s0,16(sp)
    80004756:	e426                	sd	s1,8(sp)
    80004758:	e04a                	sd	s2,0(sp)
    8000475a:	1000                	addi	s0,sp,32
    8000475c:	84aa                	mv	s1,a0
    8000475e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004760:	00004597          	auipc	a1,0x4
    80004764:	f8858593          	addi	a1,a1,-120 # 800086e8 <syscalls+0x230>
    80004768:	0521                	addi	a0,a0,8
    8000476a:	ffffc097          	auipc	ra,0xffffc
    8000476e:	6de080e7          	jalr	1758(ra) # 80000e48 <initlock>
  lk->name = name;
    80004772:	0324b423          	sd	s2,40(s1)
  lk->locked = 0;
    80004776:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000477a:	0204a823          	sw	zero,48(s1)
}
    8000477e:	60e2                	ld	ra,24(sp)
    80004780:	6442                	ld	s0,16(sp)
    80004782:	64a2                	ld	s1,8(sp)
    80004784:	6902                	ld	s2,0(sp)
    80004786:	6105                	addi	sp,sp,32
    80004788:	8082                	ret

000000008000478a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000478a:	1101                	addi	sp,sp,-32
    8000478c:	ec06                	sd	ra,24(sp)
    8000478e:	e822                	sd	s0,16(sp)
    80004790:	e426                	sd	s1,8(sp)
    80004792:	e04a                	sd	s2,0(sp)
    80004794:	1000                	addi	s0,sp,32
    80004796:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004798:	00850913          	addi	s2,a0,8
    8000479c:	854a                	mv	a0,s2
    8000479e:	ffffc097          	auipc	ra,0xffffc
    800047a2:	52e080e7          	jalr	1326(ra) # 80000ccc <acquire>
  while (lk->locked) {
    800047a6:	409c                	lw	a5,0(s1)
    800047a8:	cb89                	beqz	a5,800047ba <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800047aa:	85ca                	mv	a1,s2
    800047ac:	8526                	mv	a0,s1
    800047ae:	ffffe097          	auipc	ra,0xffffe
    800047b2:	d78080e7          	jalr	-648(ra) # 80002526 <sleep>
  while (lk->locked) {
    800047b6:	409c                	lw	a5,0(s1)
    800047b8:	fbed                	bnez	a5,800047aa <acquiresleep+0x20>
  }
  lk->locked = 1;
    800047ba:	4785                	li	a5,1
    800047bc:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800047be:	ffffd097          	auipc	ra,0xffffd
    800047c2:	554080e7          	jalr	1364(ra) # 80001d12 <myproc>
    800047c6:	413c                	lw	a5,64(a0)
    800047c8:	d89c                	sw	a5,48(s1)
  release(&lk->lk);
    800047ca:	854a                	mv	a0,s2
    800047cc:	ffffc097          	auipc	ra,0xffffc
    800047d0:	5d0080e7          	jalr	1488(ra) # 80000d9c <release>
}
    800047d4:	60e2                	ld	ra,24(sp)
    800047d6:	6442                	ld	s0,16(sp)
    800047d8:	64a2                	ld	s1,8(sp)
    800047da:	6902                	ld	s2,0(sp)
    800047dc:	6105                	addi	sp,sp,32
    800047de:	8082                	ret

00000000800047e0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800047e0:	1101                	addi	sp,sp,-32
    800047e2:	ec06                	sd	ra,24(sp)
    800047e4:	e822                	sd	s0,16(sp)
    800047e6:	e426                	sd	s1,8(sp)
    800047e8:	e04a                	sd	s2,0(sp)
    800047ea:	1000                	addi	s0,sp,32
    800047ec:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047ee:	00850913          	addi	s2,a0,8
    800047f2:	854a                	mv	a0,s2
    800047f4:	ffffc097          	auipc	ra,0xffffc
    800047f8:	4d8080e7          	jalr	1240(ra) # 80000ccc <acquire>
  lk->locked = 0;
    800047fc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004800:	0204a823          	sw	zero,48(s1)
  wakeup(lk);
    80004804:	8526                	mv	a0,s1
    80004806:	ffffe097          	auipc	ra,0xffffe
    8000480a:	ea0080e7          	jalr	-352(ra) # 800026a6 <wakeup>
  release(&lk->lk);
    8000480e:	854a                	mv	a0,s2
    80004810:	ffffc097          	auipc	ra,0xffffc
    80004814:	58c080e7          	jalr	1420(ra) # 80000d9c <release>
}
    80004818:	60e2                	ld	ra,24(sp)
    8000481a:	6442                	ld	s0,16(sp)
    8000481c:	64a2                	ld	s1,8(sp)
    8000481e:	6902                	ld	s2,0(sp)
    80004820:	6105                	addi	sp,sp,32
    80004822:	8082                	ret

0000000080004824 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004824:	7179                	addi	sp,sp,-48
    80004826:	f406                	sd	ra,40(sp)
    80004828:	f022                	sd	s0,32(sp)
    8000482a:	ec26                	sd	s1,24(sp)
    8000482c:	e84a                	sd	s2,16(sp)
    8000482e:	e44e                	sd	s3,8(sp)
    80004830:	1800                	addi	s0,sp,48
    80004832:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004834:	00850913          	addi	s2,a0,8
    80004838:	854a                	mv	a0,s2
    8000483a:	ffffc097          	auipc	ra,0xffffc
    8000483e:	492080e7          	jalr	1170(ra) # 80000ccc <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004842:	409c                	lw	a5,0(s1)
    80004844:	ef99                	bnez	a5,80004862 <holdingsleep+0x3e>
    80004846:	4481                	li	s1,0
  release(&lk->lk);
    80004848:	854a                	mv	a0,s2
    8000484a:	ffffc097          	auipc	ra,0xffffc
    8000484e:	552080e7          	jalr	1362(ra) # 80000d9c <release>
  return r;
}
    80004852:	8526                	mv	a0,s1
    80004854:	70a2                	ld	ra,40(sp)
    80004856:	7402                	ld	s0,32(sp)
    80004858:	64e2                	ld	s1,24(sp)
    8000485a:	6942                	ld	s2,16(sp)
    8000485c:	69a2                	ld	s3,8(sp)
    8000485e:	6145                	addi	sp,sp,48
    80004860:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004862:	0304a983          	lw	s3,48(s1)
    80004866:	ffffd097          	auipc	ra,0xffffd
    8000486a:	4ac080e7          	jalr	1196(ra) # 80001d12 <myproc>
    8000486e:	4124                	lw	s1,64(a0)
    80004870:	413484b3          	sub	s1,s1,s3
    80004874:	0014b493          	seqz	s1,s1
    80004878:	bfc1                	j	80004848 <holdingsleep+0x24>

000000008000487a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000487a:	1141                	addi	sp,sp,-16
    8000487c:	e406                	sd	ra,8(sp)
    8000487e:	e022                	sd	s0,0(sp)
    80004880:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004882:	00004597          	auipc	a1,0x4
    80004886:	e7658593          	addi	a1,a1,-394 # 800086f8 <syscalls+0x240>
    8000488a:	00021517          	auipc	a0,0x21
    8000488e:	55650513          	addi	a0,a0,1366 # 80025de0 <ftable>
    80004892:	ffffc097          	auipc	ra,0xffffc
    80004896:	5b6080e7          	jalr	1462(ra) # 80000e48 <initlock>
}
    8000489a:	60a2                	ld	ra,8(sp)
    8000489c:	6402                	ld	s0,0(sp)
    8000489e:	0141                	addi	sp,sp,16
    800048a0:	8082                	ret

00000000800048a2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800048a2:	1101                	addi	sp,sp,-32
    800048a4:	ec06                	sd	ra,24(sp)
    800048a6:	e822                	sd	s0,16(sp)
    800048a8:	e426                	sd	s1,8(sp)
    800048aa:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800048ac:	00021517          	auipc	a0,0x21
    800048b0:	53450513          	addi	a0,a0,1332 # 80025de0 <ftable>
    800048b4:	ffffc097          	auipc	ra,0xffffc
    800048b8:	418080e7          	jalr	1048(ra) # 80000ccc <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048bc:	00021497          	auipc	s1,0x21
    800048c0:	54448493          	addi	s1,s1,1348 # 80025e00 <ftable+0x20>
    800048c4:	00022717          	auipc	a4,0x22
    800048c8:	4dc70713          	addi	a4,a4,1244 # 80026da0 <ftable+0xfc0>
    if(f->ref == 0){
    800048cc:	40dc                	lw	a5,4(s1)
    800048ce:	cf99                	beqz	a5,800048ec <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048d0:	02848493          	addi	s1,s1,40
    800048d4:	fee49ce3          	bne	s1,a4,800048cc <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800048d8:	00021517          	auipc	a0,0x21
    800048dc:	50850513          	addi	a0,a0,1288 # 80025de0 <ftable>
    800048e0:	ffffc097          	auipc	ra,0xffffc
    800048e4:	4bc080e7          	jalr	1212(ra) # 80000d9c <release>
  return 0;
    800048e8:	4481                	li	s1,0
    800048ea:	a819                	j	80004900 <filealloc+0x5e>
      f->ref = 1;
    800048ec:	4785                	li	a5,1
    800048ee:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800048f0:	00021517          	auipc	a0,0x21
    800048f4:	4f050513          	addi	a0,a0,1264 # 80025de0 <ftable>
    800048f8:	ffffc097          	auipc	ra,0xffffc
    800048fc:	4a4080e7          	jalr	1188(ra) # 80000d9c <release>
}
    80004900:	8526                	mv	a0,s1
    80004902:	60e2                	ld	ra,24(sp)
    80004904:	6442                	ld	s0,16(sp)
    80004906:	64a2                	ld	s1,8(sp)
    80004908:	6105                	addi	sp,sp,32
    8000490a:	8082                	ret

000000008000490c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000490c:	1101                	addi	sp,sp,-32
    8000490e:	ec06                	sd	ra,24(sp)
    80004910:	e822                	sd	s0,16(sp)
    80004912:	e426                	sd	s1,8(sp)
    80004914:	1000                	addi	s0,sp,32
    80004916:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004918:	00021517          	auipc	a0,0x21
    8000491c:	4c850513          	addi	a0,a0,1224 # 80025de0 <ftable>
    80004920:	ffffc097          	auipc	ra,0xffffc
    80004924:	3ac080e7          	jalr	940(ra) # 80000ccc <acquire>
  if(f->ref < 1)
    80004928:	40dc                	lw	a5,4(s1)
    8000492a:	02f05263          	blez	a5,8000494e <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000492e:	2785                	addiw	a5,a5,1
    80004930:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004932:	00021517          	auipc	a0,0x21
    80004936:	4ae50513          	addi	a0,a0,1198 # 80025de0 <ftable>
    8000493a:	ffffc097          	auipc	ra,0xffffc
    8000493e:	462080e7          	jalr	1122(ra) # 80000d9c <release>
  return f;
}
    80004942:	8526                	mv	a0,s1
    80004944:	60e2                	ld	ra,24(sp)
    80004946:	6442                	ld	s0,16(sp)
    80004948:	64a2                	ld	s1,8(sp)
    8000494a:	6105                	addi	sp,sp,32
    8000494c:	8082                	ret
    panic("filedup");
    8000494e:	00004517          	auipc	a0,0x4
    80004952:	db250513          	addi	a0,a0,-590 # 80008700 <syscalls+0x248>
    80004956:	ffffc097          	auipc	ra,0xffffc
    8000495a:	bf4080e7          	jalr	-1036(ra) # 8000054a <panic>

000000008000495e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000495e:	7139                	addi	sp,sp,-64
    80004960:	fc06                	sd	ra,56(sp)
    80004962:	f822                	sd	s0,48(sp)
    80004964:	f426                	sd	s1,40(sp)
    80004966:	f04a                	sd	s2,32(sp)
    80004968:	ec4e                	sd	s3,24(sp)
    8000496a:	e852                	sd	s4,16(sp)
    8000496c:	e456                	sd	s5,8(sp)
    8000496e:	0080                	addi	s0,sp,64
    80004970:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004972:	00021517          	auipc	a0,0x21
    80004976:	46e50513          	addi	a0,a0,1134 # 80025de0 <ftable>
    8000497a:	ffffc097          	auipc	ra,0xffffc
    8000497e:	352080e7          	jalr	850(ra) # 80000ccc <acquire>
  if(f->ref < 1)
    80004982:	40dc                	lw	a5,4(s1)
    80004984:	06f05163          	blez	a5,800049e6 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004988:	37fd                	addiw	a5,a5,-1
    8000498a:	0007871b          	sext.w	a4,a5
    8000498e:	c0dc                	sw	a5,4(s1)
    80004990:	06e04363          	bgtz	a4,800049f6 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004994:	0004a903          	lw	s2,0(s1)
    80004998:	0094ca83          	lbu	s5,9(s1)
    8000499c:	0104ba03          	ld	s4,16(s1)
    800049a0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800049a4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800049a8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800049ac:	00021517          	auipc	a0,0x21
    800049b0:	43450513          	addi	a0,a0,1076 # 80025de0 <ftable>
    800049b4:	ffffc097          	auipc	ra,0xffffc
    800049b8:	3e8080e7          	jalr	1000(ra) # 80000d9c <release>

  if(ff.type == FD_PIPE){
    800049bc:	4785                	li	a5,1
    800049be:	04f90d63          	beq	s2,a5,80004a18 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800049c2:	3979                	addiw	s2,s2,-2
    800049c4:	4785                	li	a5,1
    800049c6:	0527e063          	bltu	a5,s2,80004a06 <fileclose+0xa8>
    begin_op();
    800049ca:	00000097          	auipc	ra,0x0
    800049ce:	ac0080e7          	jalr	-1344(ra) # 8000448a <begin_op>
    iput(ff.ip);
    800049d2:	854e                	mv	a0,s3
    800049d4:	fffff097          	auipc	ra,0xfffff
    800049d8:	2a0080e7          	jalr	672(ra) # 80003c74 <iput>
    end_op();
    800049dc:	00000097          	auipc	ra,0x0
    800049e0:	b2e080e7          	jalr	-1234(ra) # 8000450a <end_op>
    800049e4:	a00d                	j	80004a06 <fileclose+0xa8>
    panic("fileclose");
    800049e6:	00004517          	auipc	a0,0x4
    800049ea:	d2250513          	addi	a0,a0,-734 # 80008708 <syscalls+0x250>
    800049ee:	ffffc097          	auipc	ra,0xffffc
    800049f2:	b5c080e7          	jalr	-1188(ra) # 8000054a <panic>
    release(&ftable.lock);
    800049f6:	00021517          	auipc	a0,0x21
    800049fa:	3ea50513          	addi	a0,a0,1002 # 80025de0 <ftable>
    800049fe:	ffffc097          	auipc	ra,0xffffc
    80004a02:	39e080e7          	jalr	926(ra) # 80000d9c <release>
  }
}
    80004a06:	70e2                	ld	ra,56(sp)
    80004a08:	7442                	ld	s0,48(sp)
    80004a0a:	74a2                	ld	s1,40(sp)
    80004a0c:	7902                	ld	s2,32(sp)
    80004a0e:	69e2                	ld	s3,24(sp)
    80004a10:	6a42                	ld	s4,16(sp)
    80004a12:	6aa2                	ld	s5,8(sp)
    80004a14:	6121                	addi	sp,sp,64
    80004a16:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a18:	85d6                	mv	a1,s5
    80004a1a:	8552                	mv	a0,s4
    80004a1c:	00000097          	auipc	ra,0x0
    80004a20:	372080e7          	jalr	882(ra) # 80004d8e <pipeclose>
    80004a24:	b7cd                	j	80004a06 <fileclose+0xa8>

0000000080004a26 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004a26:	715d                	addi	sp,sp,-80
    80004a28:	e486                	sd	ra,72(sp)
    80004a2a:	e0a2                	sd	s0,64(sp)
    80004a2c:	fc26                	sd	s1,56(sp)
    80004a2e:	f84a                	sd	s2,48(sp)
    80004a30:	f44e                	sd	s3,40(sp)
    80004a32:	0880                	addi	s0,sp,80
    80004a34:	84aa                	mv	s1,a0
    80004a36:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004a38:	ffffd097          	auipc	ra,0xffffd
    80004a3c:	2da080e7          	jalr	730(ra) # 80001d12 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004a40:	409c                	lw	a5,0(s1)
    80004a42:	37f9                	addiw	a5,a5,-2
    80004a44:	4705                	li	a4,1
    80004a46:	04f76763          	bltu	a4,a5,80004a94 <filestat+0x6e>
    80004a4a:	892a                	mv	s2,a0
    ilock(f->ip);
    80004a4c:	6c88                	ld	a0,24(s1)
    80004a4e:	fffff097          	auipc	ra,0xfffff
    80004a52:	06c080e7          	jalr	108(ra) # 80003aba <ilock>
    stati(f->ip, &st);
    80004a56:	fb840593          	addi	a1,s0,-72
    80004a5a:	6c88                	ld	a0,24(s1)
    80004a5c:	fffff097          	auipc	ra,0xfffff
    80004a60:	2e8080e7          	jalr	744(ra) # 80003d44 <stati>
    iunlock(f->ip);
    80004a64:	6c88                	ld	a0,24(s1)
    80004a66:	fffff097          	auipc	ra,0xfffff
    80004a6a:	116080e7          	jalr	278(ra) # 80003b7c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004a6e:	46e1                	li	a3,24
    80004a70:	fb840613          	addi	a2,s0,-72
    80004a74:	85ce                	mv	a1,s3
    80004a76:	05893503          	ld	a0,88(s2)
    80004a7a:	ffffd097          	auipc	ra,0xffffd
    80004a7e:	f8a080e7          	jalr	-118(ra) # 80001a04 <copyout>
    80004a82:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004a86:	60a6                	ld	ra,72(sp)
    80004a88:	6406                	ld	s0,64(sp)
    80004a8a:	74e2                	ld	s1,56(sp)
    80004a8c:	7942                	ld	s2,48(sp)
    80004a8e:	79a2                	ld	s3,40(sp)
    80004a90:	6161                	addi	sp,sp,80
    80004a92:	8082                	ret
  return -1;
    80004a94:	557d                	li	a0,-1
    80004a96:	bfc5                	j	80004a86 <filestat+0x60>

0000000080004a98 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004a98:	7179                	addi	sp,sp,-48
    80004a9a:	f406                	sd	ra,40(sp)
    80004a9c:	f022                	sd	s0,32(sp)
    80004a9e:	ec26                	sd	s1,24(sp)
    80004aa0:	e84a                	sd	s2,16(sp)
    80004aa2:	e44e                	sd	s3,8(sp)
    80004aa4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004aa6:	00854783          	lbu	a5,8(a0)
    80004aaa:	c3d5                	beqz	a5,80004b4e <fileread+0xb6>
    80004aac:	84aa                	mv	s1,a0
    80004aae:	89ae                	mv	s3,a1
    80004ab0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ab2:	411c                	lw	a5,0(a0)
    80004ab4:	4705                	li	a4,1
    80004ab6:	04e78963          	beq	a5,a4,80004b08 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004aba:	470d                	li	a4,3
    80004abc:	04e78d63          	beq	a5,a4,80004b16 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ac0:	4709                	li	a4,2
    80004ac2:	06e79e63          	bne	a5,a4,80004b3e <fileread+0xa6>
    ilock(f->ip);
    80004ac6:	6d08                	ld	a0,24(a0)
    80004ac8:	fffff097          	auipc	ra,0xfffff
    80004acc:	ff2080e7          	jalr	-14(ra) # 80003aba <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004ad0:	874a                	mv	a4,s2
    80004ad2:	5094                	lw	a3,32(s1)
    80004ad4:	864e                	mv	a2,s3
    80004ad6:	4585                	li	a1,1
    80004ad8:	6c88                	ld	a0,24(s1)
    80004ada:	fffff097          	auipc	ra,0xfffff
    80004ade:	294080e7          	jalr	660(ra) # 80003d6e <readi>
    80004ae2:	892a                	mv	s2,a0
    80004ae4:	00a05563          	blez	a0,80004aee <fileread+0x56>
      f->off += r;
    80004ae8:	509c                	lw	a5,32(s1)
    80004aea:	9fa9                	addw	a5,a5,a0
    80004aec:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004aee:	6c88                	ld	a0,24(s1)
    80004af0:	fffff097          	auipc	ra,0xfffff
    80004af4:	08c080e7          	jalr	140(ra) # 80003b7c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004af8:	854a                	mv	a0,s2
    80004afa:	70a2                	ld	ra,40(sp)
    80004afc:	7402                	ld	s0,32(sp)
    80004afe:	64e2                	ld	s1,24(sp)
    80004b00:	6942                	ld	s2,16(sp)
    80004b02:	69a2                	ld	s3,8(sp)
    80004b04:	6145                	addi	sp,sp,48
    80004b06:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004b08:	6908                	ld	a0,16(a0)
    80004b0a:	00000097          	auipc	ra,0x0
    80004b0e:	3fe080e7          	jalr	1022(ra) # 80004f08 <piperead>
    80004b12:	892a                	mv	s2,a0
    80004b14:	b7d5                	j	80004af8 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b16:	02451783          	lh	a5,36(a0)
    80004b1a:	03079693          	slli	a3,a5,0x30
    80004b1e:	92c1                	srli	a3,a3,0x30
    80004b20:	4725                	li	a4,9
    80004b22:	02d76863          	bltu	a4,a3,80004b52 <fileread+0xba>
    80004b26:	0792                	slli	a5,a5,0x4
    80004b28:	00021717          	auipc	a4,0x21
    80004b2c:	21870713          	addi	a4,a4,536 # 80025d40 <devsw>
    80004b30:	97ba                	add	a5,a5,a4
    80004b32:	639c                	ld	a5,0(a5)
    80004b34:	c38d                	beqz	a5,80004b56 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004b36:	4505                	li	a0,1
    80004b38:	9782                	jalr	a5
    80004b3a:	892a                	mv	s2,a0
    80004b3c:	bf75                	j	80004af8 <fileread+0x60>
    panic("fileread");
    80004b3e:	00004517          	auipc	a0,0x4
    80004b42:	bda50513          	addi	a0,a0,-1062 # 80008718 <syscalls+0x260>
    80004b46:	ffffc097          	auipc	ra,0xffffc
    80004b4a:	a04080e7          	jalr	-1532(ra) # 8000054a <panic>
    return -1;
    80004b4e:	597d                	li	s2,-1
    80004b50:	b765                	j	80004af8 <fileread+0x60>
      return -1;
    80004b52:	597d                	li	s2,-1
    80004b54:	b755                	j	80004af8 <fileread+0x60>
    80004b56:	597d                	li	s2,-1
    80004b58:	b745                	j	80004af8 <fileread+0x60>

0000000080004b5a <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004b5a:	00954783          	lbu	a5,9(a0)
    80004b5e:	14078563          	beqz	a5,80004ca8 <filewrite+0x14e>
{
    80004b62:	715d                	addi	sp,sp,-80
    80004b64:	e486                	sd	ra,72(sp)
    80004b66:	e0a2                	sd	s0,64(sp)
    80004b68:	fc26                	sd	s1,56(sp)
    80004b6a:	f84a                	sd	s2,48(sp)
    80004b6c:	f44e                	sd	s3,40(sp)
    80004b6e:	f052                	sd	s4,32(sp)
    80004b70:	ec56                	sd	s5,24(sp)
    80004b72:	e85a                	sd	s6,16(sp)
    80004b74:	e45e                	sd	s7,8(sp)
    80004b76:	e062                	sd	s8,0(sp)
    80004b78:	0880                	addi	s0,sp,80
    80004b7a:	892a                	mv	s2,a0
    80004b7c:	8aae                	mv	s5,a1
    80004b7e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b80:	411c                	lw	a5,0(a0)
    80004b82:	4705                	li	a4,1
    80004b84:	02e78263          	beq	a5,a4,80004ba8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b88:	470d                	li	a4,3
    80004b8a:	02e78563          	beq	a5,a4,80004bb4 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b8e:	4709                	li	a4,2
    80004b90:	10e79463          	bne	a5,a4,80004c98 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004b94:	0ec05e63          	blez	a2,80004c90 <filewrite+0x136>
    int i = 0;
    80004b98:	4981                	li	s3,0
    80004b9a:	6b05                	lui	s6,0x1
    80004b9c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004ba0:	6b85                	lui	s7,0x1
    80004ba2:	c00b8b9b          	addiw	s7,s7,-1024
    80004ba6:	a851                	j	80004c3a <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004ba8:	6908                	ld	a0,16(a0)
    80004baa:	00000097          	auipc	ra,0x0
    80004bae:	25e080e7          	jalr	606(ra) # 80004e08 <pipewrite>
    80004bb2:	a85d                	j	80004c68 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004bb4:	02451783          	lh	a5,36(a0)
    80004bb8:	03079693          	slli	a3,a5,0x30
    80004bbc:	92c1                	srli	a3,a3,0x30
    80004bbe:	4725                	li	a4,9
    80004bc0:	0ed76663          	bltu	a4,a3,80004cac <filewrite+0x152>
    80004bc4:	0792                	slli	a5,a5,0x4
    80004bc6:	00021717          	auipc	a4,0x21
    80004bca:	17a70713          	addi	a4,a4,378 # 80025d40 <devsw>
    80004bce:	97ba                	add	a5,a5,a4
    80004bd0:	679c                	ld	a5,8(a5)
    80004bd2:	cff9                	beqz	a5,80004cb0 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004bd4:	4505                	li	a0,1
    80004bd6:	9782                	jalr	a5
    80004bd8:	a841                	j	80004c68 <filewrite+0x10e>
    80004bda:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004bde:	00000097          	auipc	ra,0x0
    80004be2:	8ac080e7          	jalr	-1876(ra) # 8000448a <begin_op>
      ilock(f->ip);
    80004be6:	01893503          	ld	a0,24(s2)
    80004bea:	fffff097          	auipc	ra,0xfffff
    80004bee:	ed0080e7          	jalr	-304(ra) # 80003aba <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004bf2:	8762                	mv	a4,s8
    80004bf4:	02092683          	lw	a3,32(s2)
    80004bf8:	01598633          	add	a2,s3,s5
    80004bfc:	4585                	li	a1,1
    80004bfe:	01893503          	ld	a0,24(s2)
    80004c02:	fffff097          	auipc	ra,0xfffff
    80004c06:	264080e7          	jalr	612(ra) # 80003e66 <writei>
    80004c0a:	84aa                	mv	s1,a0
    80004c0c:	02a05f63          	blez	a0,80004c4a <filewrite+0xf0>
        f->off += r;
    80004c10:	02092783          	lw	a5,32(s2)
    80004c14:	9fa9                	addw	a5,a5,a0
    80004c16:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c1a:	01893503          	ld	a0,24(s2)
    80004c1e:	fffff097          	auipc	ra,0xfffff
    80004c22:	f5e080e7          	jalr	-162(ra) # 80003b7c <iunlock>
      end_op();
    80004c26:	00000097          	auipc	ra,0x0
    80004c2a:	8e4080e7          	jalr	-1820(ra) # 8000450a <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004c2e:	049c1963          	bne	s8,s1,80004c80 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004c32:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004c36:	0349d663          	bge	s3,s4,80004c62 <filewrite+0x108>
      int n1 = n - i;
    80004c3a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004c3e:	84be                	mv	s1,a5
    80004c40:	2781                	sext.w	a5,a5
    80004c42:	f8fb5ce3          	bge	s6,a5,80004bda <filewrite+0x80>
    80004c46:	84de                	mv	s1,s7
    80004c48:	bf49                	j	80004bda <filewrite+0x80>
      iunlock(f->ip);
    80004c4a:	01893503          	ld	a0,24(s2)
    80004c4e:	fffff097          	auipc	ra,0xfffff
    80004c52:	f2e080e7          	jalr	-210(ra) # 80003b7c <iunlock>
      end_op();
    80004c56:	00000097          	auipc	ra,0x0
    80004c5a:	8b4080e7          	jalr	-1868(ra) # 8000450a <end_op>
      if(r < 0)
    80004c5e:	fc04d8e3          	bgez	s1,80004c2e <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004c62:	8552                	mv	a0,s4
    80004c64:	033a1863          	bne	s4,s3,80004c94 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004c68:	60a6                	ld	ra,72(sp)
    80004c6a:	6406                	ld	s0,64(sp)
    80004c6c:	74e2                	ld	s1,56(sp)
    80004c6e:	7942                	ld	s2,48(sp)
    80004c70:	79a2                	ld	s3,40(sp)
    80004c72:	7a02                	ld	s4,32(sp)
    80004c74:	6ae2                	ld	s5,24(sp)
    80004c76:	6b42                	ld	s6,16(sp)
    80004c78:	6ba2                	ld	s7,8(sp)
    80004c7a:	6c02                	ld	s8,0(sp)
    80004c7c:	6161                	addi	sp,sp,80
    80004c7e:	8082                	ret
        panic("short filewrite");
    80004c80:	00004517          	auipc	a0,0x4
    80004c84:	aa850513          	addi	a0,a0,-1368 # 80008728 <syscalls+0x270>
    80004c88:	ffffc097          	auipc	ra,0xffffc
    80004c8c:	8c2080e7          	jalr	-1854(ra) # 8000054a <panic>
    int i = 0;
    80004c90:	4981                	li	s3,0
    80004c92:	bfc1                	j	80004c62 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004c94:	557d                	li	a0,-1
    80004c96:	bfc9                	j	80004c68 <filewrite+0x10e>
    panic("filewrite");
    80004c98:	00004517          	auipc	a0,0x4
    80004c9c:	aa050513          	addi	a0,a0,-1376 # 80008738 <syscalls+0x280>
    80004ca0:	ffffc097          	auipc	ra,0xffffc
    80004ca4:	8aa080e7          	jalr	-1878(ra) # 8000054a <panic>
    return -1;
    80004ca8:	557d                	li	a0,-1
}
    80004caa:	8082                	ret
      return -1;
    80004cac:	557d                	li	a0,-1
    80004cae:	bf6d                	j	80004c68 <filewrite+0x10e>
    80004cb0:	557d                	li	a0,-1
    80004cb2:	bf5d                	j	80004c68 <filewrite+0x10e>

0000000080004cb4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004cb4:	7179                	addi	sp,sp,-48
    80004cb6:	f406                	sd	ra,40(sp)
    80004cb8:	f022                	sd	s0,32(sp)
    80004cba:	ec26                	sd	s1,24(sp)
    80004cbc:	e84a                	sd	s2,16(sp)
    80004cbe:	e44e                	sd	s3,8(sp)
    80004cc0:	e052                	sd	s4,0(sp)
    80004cc2:	1800                	addi	s0,sp,48
    80004cc4:	84aa                	mv	s1,a0
    80004cc6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004cc8:	0005b023          	sd	zero,0(a1)
    80004ccc:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004cd0:	00000097          	auipc	ra,0x0
    80004cd4:	bd2080e7          	jalr	-1070(ra) # 800048a2 <filealloc>
    80004cd8:	e088                	sd	a0,0(s1)
    80004cda:	c551                	beqz	a0,80004d66 <pipealloc+0xb2>
    80004cdc:	00000097          	auipc	ra,0x0
    80004ce0:	bc6080e7          	jalr	-1082(ra) # 800048a2 <filealloc>
    80004ce4:	00aa3023          	sd	a0,0(s4)
    80004ce8:	c92d                	beqz	a0,80004d5a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004cea:	ffffc097          	auipc	ra,0xffffc
    80004cee:	e80080e7          	jalr	-384(ra) # 80000b6a <kalloc>
    80004cf2:	892a                	mv	s2,a0
    80004cf4:	c125                	beqz	a0,80004d54 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004cf6:	4985                	li	s3,1
    80004cf8:	23352423          	sw	s3,552(a0)
  pi->writeopen = 1;
    80004cfc:	23352623          	sw	s3,556(a0)
  pi->nwrite = 0;
    80004d00:	22052223          	sw	zero,548(a0)
  pi->nread = 0;
    80004d04:	22052023          	sw	zero,544(a0)
  initlock(&pi->lock, "pipe");
    80004d08:	00004597          	auipc	a1,0x4
    80004d0c:	a4058593          	addi	a1,a1,-1472 # 80008748 <syscalls+0x290>
    80004d10:	ffffc097          	auipc	ra,0xffffc
    80004d14:	138080e7          	jalr	312(ra) # 80000e48 <initlock>
  (*f0)->type = FD_PIPE;
    80004d18:	609c                	ld	a5,0(s1)
    80004d1a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004d1e:	609c                	ld	a5,0(s1)
    80004d20:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004d24:	609c                	ld	a5,0(s1)
    80004d26:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d2a:	609c                	ld	a5,0(s1)
    80004d2c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004d30:	000a3783          	ld	a5,0(s4)
    80004d34:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d38:	000a3783          	ld	a5,0(s4)
    80004d3c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d40:	000a3783          	ld	a5,0(s4)
    80004d44:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d48:	000a3783          	ld	a5,0(s4)
    80004d4c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004d50:	4501                	li	a0,0
    80004d52:	a025                	j	80004d7a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004d54:	6088                	ld	a0,0(s1)
    80004d56:	e501                	bnez	a0,80004d5e <pipealloc+0xaa>
    80004d58:	a039                	j	80004d66 <pipealloc+0xb2>
    80004d5a:	6088                	ld	a0,0(s1)
    80004d5c:	c51d                	beqz	a0,80004d8a <pipealloc+0xd6>
    fileclose(*f0);
    80004d5e:	00000097          	auipc	ra,0x0
    80004d62:	c00080e7          	jalr	-1024(ra) # 8000495e <fileclose>
  if(*f1)
    80004d66:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004d6a:	557d                	li	a0,-1
  if(*f1)
    80004d6c:	c799                	beqz	a5,80004d7a <pipealloc+0xc6>
    fileclose(*f1);
    80004d6e:	853e                	mv	a0,a5
    80004d70:	00000097          	auipc	ra,0x0
    80004d74:	bee080e7          	jalr	-1042(ra) # 8000495e <fileclose>
  return -1;
    80004d78:	557d                	li	a0,-1
}
    80004d7a:	70a2                	ld	ra,40(sp)
    80004d7c:	7402                	ld	s0,32(sp)
    80004d7e:	64e2                	ld	s1,24(sp)
    80004d80:	6942                	ld	s2,16(sp)
    80004d82:	69a2                	ld	s3,8(sp)
    80004d84:	6a02                	ld	s4,0(sp)
    80004d86:	6145                	addi	sp,sp,48
    80004d88:	8082                	ret
  return -1;
    80004d8a:	557d                	li	a0,-1
    80004d8c:	b7fd                	j	80004d7a <pipealloc+0xc6>

0000000080004d8e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004d8e:	1101                	addi	sp,sp,-32
    80004d90:	ec06                	sd	ra,24(sp)
    80004d92:	e822                	sd	s0,16(sp)
    80004d94:	e426                	sd	s1,8(sp)
    80004d96:	e04a                	sd	s2,0(sp)
    80004d98:	1000                	addi	s0,sp,32
    80004d9a:	84aa                	mv	s1,a0
    80004d9c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004d9e:	ffffc097          	auipc	ra,0xffffc
    80004da2:	f2e080e7          	jalr	-210(ra) # 80000ccc <acquire>
  if(writable){
    80004da6:	04090263          	beqz	s2,80004dea <pipeclose+0x5c>
    pi->writeopen = 0;
    80004daa:	2204a623          	sw	zero,556(s1)
    wakeup(&pi->nread);
    80004dae:	22048513          	addi	a0,s1,544
    80004db2:	ffffe097          	auipc	ra,0xffffe
    80004db6:	8f4080e7          	jalr	-1804(ra) # 800026a6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004dba:	2284b783          	ld	a5,552(s1)
    80004dbe:	ef9d                	bnez	a5,80004dfc <pipeclose+0x6e>
    release(&pi->lock);
    80004dc0:	8526                	mv	a0,s1
    80004dc2:	ffffc097          	auipc	ra,0xffffc
    80004dc6:	fda080e7          	jalr	-38(ra) # 80000d9c <release>
#ifdef LAB_LOCK
    freelock(&pi->lock);
    80004dca:	8526                	mv	a0,s1
    80004dcc:	ffffc097          	auipc	ra,0xffffc
    80004dd0:	018080e7          	jalr	24(ra) # 80000de4 <freelock>
#endif    
    kfree((char*)pi);
    80004dd4:	8526                	mv	a0,s1
    80004dd6:	ffffc097          	auipc	ra,0xffffc
    80004dda:	c44080e7          	jalr	-956(ra) # 80000a1a <kfree>
  } else
    release(&pi->lock);
}
    80004dde:	60e2                	ld	ra,24(sp)
    80004de0:	6442                	ld	s0,16(sp)
    80004de2:	64a2                	ld	s1,8(sp)
    80004de4:	6902                	ld	s2,0(sp)
    80004de6:	6105                	addi	sp,sp,32
    80004de8:	8082                	ret
    pi->readopen = 0;
    80004dea:	2204a423          	sw	zero,552(s1)
    wakeup(&pi->nwrite);
    80004dee:	22448513          	addi	a0,s1,548
    80004df2:	ffffe097          	auipc	ra,0xffffe
    80004df6:	8b4080e7          	jalr	-1868(ra) # 800026a6 <wakeup>
    80004dfa:	b7c1                	j	80004dba <pipeclose+0x2c>
    release(&pi->lock);
    80004dfc:	8526                	mv	a0,s1
    80004dfe:	ffffc097          	auipc	ra,0xffffc
    80004e02:	f9e080e7          	jalr	-98(ra) # 80000d9c <release>
}
    80004e06:	bfe1                	j	80004dde <pipeclose+0x50>

0000000080004e08 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e08:	711d                	addi	sp,sp,-96
    80004e0a:	ec86                	sd	ra,88(sp)
    80004e0c:	e8a2                	sd	s0,80(sp)
    80004e0e:	e4a6                	sd	s1,72(sp)
    80004e10:	e0ca                	sd	s2,64(sp)
    80004e12:	fc4e                	sd	s3,56(sp)
    80004e14:	f852                	sd	s4,48(sp)
    80004e16:	f456                	sd	s5,40(sp)
    80004e18:	f05a                	sd	s6,32(sp)
    80004e1a:	ec5e                	sd	s7,24(sp)
    80004e1c:	e862                	sd	s8,16(sp)
    80004e1e:	1080                	addi	s0,sp,96
    80004e20:	84aa                	mv	s1,a0
    80004e22:	8b2e                	mv	s6,a1
    80004e24:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004e26:	ffffd097          	auipc	ra,0xffffd
    80004e2a:	eec080e7          	jalr	-276(ra) # 80001d12 <myproc>
    80004e2e:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004e30:	8526                	mv	a0,s1
    80004e32:	ffffc097          	auipc	ra,0xffffc
    80004e36:	e9a080e7          	jalr	-358(ra) # 80000ccc <acquire>
  for(i = 0; i < n; i++){
    80004e3a:	09505763          	blez	s5,80004ec8 <pipewrite+0xc0>
    80004e3e:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004e40:	22048a13          	addi	s4,s1,544
      sleep(&pi->nwrite, &pi->lock);
    80004e44:	22448993          	addi	s3,s1,548
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e48:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004e4a:	2204a783          	lw	a5,544(s1)
    80004e4e:	2244a703          	lw	a4,548(s1)
    80004e52:	2007879b          	addiw	a5,a5,512
    80004e56:	02f71b63          	bne	a4,a5,80004e8c <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004e5a:	2284a783          	lw	a5,552(s1)
    80004e5e:	c3d1                	beqz	a5,80004ee2 <pipewrite+0xda>
    80004e60:	03892783          	lw	a5,56(s2)
    80004e64:	efbd                	bnez	a5,80004ee2 <pipewrite+0xda>
      wakeup(&pi->nread);
    80004e66:	8552                	mv	a0,s4
    80004e68:	ffffe097          	auipc	ra,0xffffe
    80004e6c:	83e080e7          	jalr	-1986(ra) # 800026a6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004e70:	85a6                	mv	a1,s1
    80004e72:	854e                	mv	a0,s3
    80004e74:	ffffd097          	auipc	ra,0xffffd
    80004e78:	6b2080e7          	jalr	1714(ra) # 80002526 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004e7c:	2204a783          	lw	a5,544(s1)
    80004e80:	2244a703          	lw	a4,548(s1)
    80004e84:	2007879b          	addiw	a5,a5,512
    80004e88:	fcf709e3          	beq	a4,a5,80004e5a <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e8c:	4685                	li	a3,1
    80004e8e:	865a                	mv	a2,s6
    80004e90:	faf40593          	addi	a1,s0,-81
    80004e94:	05893503          	ld	a0,88(s2)
    80004e98:	ffffd097          	auipc	ra,0xffffd
    80004e9c:	bf8080e7          	jalr	-1032(ra) # 80001a90 <copyin>
    80004ea0:	03850563          	beq	a0,s8,80004eca <pipewrite+0xc2>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ea4:	2244a783          	lw	a5,548(s1)
    80004ea8:	0017871b          	addiw	a4,a5,1
    80004eac:	22e4a223          	sw	a4,548(s1)
    80004eb0:	1ff7f793          	andi	a5,a5,511
    80004eb4:	97a6                	add	a5,a5,s1
    80004eb6:	faf44703          	lbu	a4,-81(s0)
    80004eba:	02e78023          	sb	a4,32(a5)
  for(i = 0; i < n; i++){
    80004ebe:	2b85                	addiw	s7,s7,1
    80004ec0:	0b05                	addi	s6,s6,1
    80004ec2:	f97a94e3          	bne	s5,s7,80004e4a <pipewrite+0x42>
    80004ec6:	a011                	j	80004eca <pipewrite+0xc2>
    80004ec8:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004eca:	22048513          	addi	a0,s1,544
    80004ece:	ffffd097          	auipc	ra,0xffffd
    80004ed2:	7d8080e7          	jalr	2008(ra) # 800026a6 <wakeup>
  release(&pi->lock);
    80004ed6:	8526                	mv	a0,s1
    80004ed8:	ffffc097          	auipc	ra,0xffffc
    80004edc:	ec4080e7          	jalr	-316(ra) # 80000d9c <release>
  return i;
    80004ee0:	a039                	j	80004eee <pipewrite+0xe6>
        release(&pi->lock);
    80004ee2:	8526                	mv	a0,s1
    80004ee4:	ffffc097          	auipc	ra,0xffffc
    80004ee8:	eb8080e7          	jalr	-328(ra) # 80000d9c <release>
        return -1;
    80004eec:	5bfd                	li	s7,-1
}
    80004eee:	855e                	mv	a0,s7
    80004ef0:	60e6                	ld	ra,88(sp)
    80004ef2:	6446                	ld	s0,80(sp)
    80004ef4:	64a6                	ld	s1,72(sp)
    80004ef6:	6906                	ld	s2,64(sp)
    80004ef8:	79e2                	ld	s3,56(sp)
    80004efa:	7a42                	ld	s4,48(sp)
    80004efc:	7aa2                	ld	s5,40(sp)
    80004efe:	7b02                	ld	s6,32(sp)
    80004f00:	6be2                	ld	s7,24(sp)
    80004f02:	6c42                	ld	s8,16(sp)
    80004f04:	6125                	addi	sp,sp,96
    80004f06:	8082                	ret

0000000080004f08 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f08:	715d                	addi	sp,sp,-80
    80004f0a:	e486                	sd	ra,72(sp)
    80004f0c:	e0a2                	sd	s0,64(sp)
    80004f0e:	fc26                	sd	s1,56(sp)
    80004f10:	f84a                	sd	s2,48(sp)
    80004f12:	f44e                	sd	s3,40(sp)
    80004f14:	f052                	sd	s4,32(sp)
    80004f16:	ec56                	sd	s5,24(sp)
    80004f18:	e85a                	sd	s6,16(sp)
    80004f1a:	0880                	addi	s0,sp,80
    80004f1c:	84aa                	mv	s1,a0
    80004f1e:	892e                	mv	s2,a1
    80004f20:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f22:	ffffd097          	auipc	ra,0xffffd
    80004f26:	df0080e7          	jalr	-528(ra) # 80001d12 <myproc>
    80004f2a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f2c:	8526                	mv	a0,s1
    80004f2e:	ffffc097          	auipc	ra,0xffffc
    80004f32:	d9e080e7          	jalr	-610(ra) # 80000ccc <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f36:	2204a703          	lw	a4,544(s1)
    80004f3a:	2244a783          	lw	a5,548(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f3e:	22048993          	addi	s3,s1,544
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f42:	02f71463          	bne	a4,a5,80004f6a <piperead+0x62>
    80004f46:	22c4a783          	lw	a5,556(s1)
    80004f4a:	c385                	beqz	a5,80004f6a <piperead+0x62>
    if(pr->killed){
    80004f4c:	038a2783          	lw	a5,56(s4)
    80004f50:	ebc1                	bnez	a5,80004fe0 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f52:	85a6                	mv	a1,s1
    80004f54:	854e                	mv	a0,s3
    80004f56:	ffffd097          	auipc	ra,0xffffd
    80004f5a:	5d0080e7          	jalr	1488(ra) # 80002526 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f5e:	2204a703          	lw	a4,544(s1)
    80004f62:	2244a783          	lw	a5,548(s1)
    80004f66:	fef700e3          	beq	a4,a5,80004f46 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f6a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f6c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f6e:	05505363          	blez	s5,80004fb4 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004f72:	2204a783          	lw	a5,544(s1)
    80004f76:	2244a703          	lw	a4,548(s1)
    80004f7a:	02f70d63          	beq	a4,a5,80004fb4 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004f7e:	0017871b          	addiw	a4,a5,1
    80004f82:	22e4a023          	sw	a4,544(s1)
    80004f86:	1ff7f793          	andi	a5,a5,511
    80004f8a:	97a6                	add	a5,a5,s1
    80004f8c:	0207c783          	lbu	a5,32(a5)
    80004f90:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f94:	4685                	li	a3,1
    80004f96:	fbf40613          	addi	a2,s0,-65
    80004f9a:	85ca                	mv	a1,s2
    80004f9c:	058a3503          	ld	a0,88(s4)
    80004fa0:	ffffd097          	auipc	ra,0xffffd
    80004fa4:	a64080e7          	jalr	-1436(ra) # 80001a04 <copyout>
    80004fa8:	01650663          	beq	a0,s6,80004fb4 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fac:	2985                	addiw	s3,s3,1
    80004fae:	0905                	addi	s2,s2,1
    80004fb0:	fd3a91e3          	bne	s5,s3,80004f72 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004fb4:	22448513          	addi	a0,s1,548
    80004fb8:	ffffd097          	auipc	ra,0xffffd
    80004fbc:	6ee080e7          	jalr	1774(ra) # 800026a6 <wakeup>
  release(&pi->lock);
    80004fc0:	8526                	mv	a0,s1
    80004fc2:	ffffc097          	auipc	ra,0xffffc
    80004fc6:	dda080e7          	jalr	-550(ra) # 80000d9c <release>
  return i;
}
    80004fca:	854e                	mv	a0,s3
    80004fcc:	60a6                	ld	ra,72(sp)
    80004fce:	6406                	ld	s0,64(sp)
    80004fd0:	74e2                	ld	s1,56(sp)
    80004fd2:	7942                	ld	s2,48(sp)
    80004fd4:	79a2                	ld	s3,40(sp)
    80004fd6:	7a02                	ld	s4,32(sp)
    80004fd8:	6ae2                	ld	s5,24(sp)
    80004fda:	6b42                	ld	s6,16(sp)
    80004fdc:	6161                	addi	sp,sp,80
    80004fde:	8082                	ret
      release(&pi->lock);
    80004fe0:	8526                	mv	a0,s1
    80004fe2:	ffffc097          	auipc	ra,0xffffc
    80004fe6:	dba080e7          	jalr	-582(ra) # 80000d9c <release>
      return -1;
    80004fea:	59fd                	li	s3,-1
    80004fec:	bff9                	j	80004fca <piperead+0xc2>

0000000080004fee <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004fee:	de010113          	addi	sp,sp,-544
    80004ff2:	20113c23          	sd	ra,536(sp)
    80004ff6:	20813823          	sd	s0,528(sp)
    80004ffa:	20913423          	sd	s1,520(sp)
    80004ffe:	21213023          	sd	s2,512(sp)
    80005002:	ffce                	sd	s3,504(sp)
    80005004:	fbd2                	sd	s4,496(sp)
    80005006:	f7d6                	sd	s5,488(sp)
    80005008:	f3da                	sd	s6,480(sp)
    8000500a:	efde                	sd	s7,472(sp)
    8000500c:	ebe2                	sd	s8,464(sp)
    8000500e:	e7e6                	sd	s9,456(sp)
    80005010:	e3ea                	sd	s10,448(sp)
    80005012:	ff6e                	sd	s11,440(sp)
    80005014:	1400                	addi	s0,sp,544
    80005016:	892a                	mv	s2,a0
    80005018:	dea43423          	sd	a0,-536(s0)
    8000501c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005020:	ffffd097          	auipc	ra,0xffffd
    80005024:	cf2080e7          	jalr	-782(ra) # 80001d12 <myproc>
    80005028:	84aa                	mv	s1,a0

  begin_op();
    8000502a:	fffff097          	auipc	ra,0xfffff
    8000502e:	460080e7          	jalr	1120(ra) # 8000448a <begin_op>

  if((ip = namei(path)) == 0){
    80005032:	854a                	mv	a0,s2
    80005034:	fffff097          	auipc	ra,0xfffff
    80005038:	23a080e7          	jalr	570(ra) # 8000426e <namei>
    8000503c:	c93d                	beqz	a0,800050b2 <exec+0xc4>
    8000503e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005040:	fffff097          	auipc	ra,0xfffff
    80005044:	a7a080e7          	jalr	-1414(ra) # 80003aba <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005048:	04000713          	li	a4,64
    8000504c:	4681                	li	a3,0
    8000504e:	e4840613          	addi	a2,s0,-440
    80005052:	4581                	li	a1,0
    80005054:	8556                	mv	a0,s5
    80005056:	fffff097          	auipc	ra,0xfffff
    8000505a:	d18080e7          	jalr	-744(ra) # 80003d6e <readi>
    8000505e:	04000793          	li	a5,64
    80005062:	00f51a63          	bne	a0,a5,80005076 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005066:	e4842703          	lw	a4,-440(s0)
    8000506a:	464c47b7          	lui	a5,0x464c4
    8000506e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005072:	04f70663          	beq	a4,a5,800050be <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005076:	8556                	mv	a0,s5
    80005078:	fffff097          	auipc	ra,0xfffff
    8000507c:	ca4080e7          	jalr	-860(ra) # 80003d1c <iunlockput>
    end_op();
    80005080:	fffff097          	auipc	ra,0xfffff
    80005084:	48a080e7          	jalr	1162(ra) # 8000450a <end_op>
  }
  return -1;
    80005088:	557d                	li	a0,-1
}
    8000508a:	21813083          	ld	ra,536(sp)
    8000508e:	21013403          	ld	s0,528(sp)
    80005092:	20813483          	ld	s1,520(sp)
    80005096:	20013903          	ld	s2,512(sp)
    8000509a:	79fe                	ld	s3,504(sp)
    8000509c:	7a5e                	ld	s4,496(sp)
    8000509e:	7abe                	ld	s5,488(sp)
    800050a0:	7b1e                	ld	s6,480(sp)
    800050a2:	6bfe                	ld	s7,472(sp)
    800050a4:	6c5e                	ld	s8,464(sp)
    800050a6:	6cbe                	ld	s9,456(sp)
    800050a8:	6d1e                	ld	s10,448(sp)
    800050aa:	7dfa                	ld	s11,440(sp)
    800050ac:	22010113          	addi	sp,sp,544
    800050b0:	8082                	ret
    end_op();
    800050b2:	fffff097          	auipc	ra,0xfffff
    800050b6:	458080e7          	jalr	1112(ra) # 8000450a <end_op>
    return -1;
    800050ba:	557d                	li	a0,-1
    800050bc:	b7f9                	j	8000508a <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800050be:	8526                	mv	a0,s1
    800050c0:	ffffd097          	auipc	ra,0xffffd
    800050c4:	d16080e7          	jalr	-746(ra) # 80001dd6 <proc_pagetable>
    800050c8:	8b2a                	mv	s6,a0
    800050ca:	d555                	beqz	a0,80005076 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050cc:	e6842783          	lw	a5,-408(s0)
    800050d0:	e8045703          	lhu	a4,-384(s0)
    800050d4:	c735                	beqz	a4,80005140 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800050d6:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050d8:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800050dc:	6a05                	lui	s4,0x1
    800050de:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800050e2:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    800050e6:	6d85                	lui	s11,0x1
    800050e8:	7d7d                	lui	s10,0xfffff
    800050ea:	ac1d                	j	80005320 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800050ec:	00003517          	auipc	a0,0x3
    800050f0:	66450513          	addi	a0,a0,1636 # 80008750 <syscalls+0x298>
    800050f4:	ffffb097          	auipc	ra,0xffffb
    800050f8:	456080e7          	jalr	1110(ra) # 8000054a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800050fc:	874a                	mv	a4,s2
    800050fe:	009c86bb          	addw	a3,s9,s1
    80005102:	4581                	li	a1,0
    80005104:	8556                	mv	a0,s5
    80005106:	fffff097          	auipc	ra,0xfffff
    8000510a:	c68080e7          	jalr	-920(ra) # 80003d6e <readi>
    8000510e:	2501                	sext.w	a0,a0
    80005110:	1aa91863          	bne	s2,a0,800052c0 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80005114:	009d84bb          	addw	s1,s11,s1
    80005118:	013d09bb          	addw	s3,s10,s3
    8000511c:	1f74f263          	bgeu	s1,s7,80005300 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80005120:	02049593          	slli	a1,s1,0x20
    80005124:	9181                	srli	a1,a1,0x20
    80005126:	95e2                	add	a1,a1,s8
    80005128:	855a                	mv	a0,s6
    8000512a:	ffffc097          	auipc	ra,0xffffc
    8000512e:	318080e7          	jalr	792(ra) # 80001442 <walkaddr>
    80005132:	862a                	mv	a2,a0
    if(pa == 0)
    80005134:	dd45                	beqz	a0,800050ec <exec+0xfe>
      n = PGSIZE;
    80005136:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005138:	fd49f2e3          	bgeu	s3,s4,800050fc <exec+0x10e>
      n = sz - i;
    8000513c:	894e                	mv	s2,s3
    8000513e:	bf7d                	j	800050fc <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005140:	4481                	li	s1,0
  iunlockput(ip);
    80005142:	8556                	mv	a0,s5
    80005144:	fffff097          	auipc	ra,0xfffff
    80005148:	bd8080e7          	jalr	-1064(ra) # 80003d1c <iunlockput>
  end_op();
    8000514c:	fffff097          	auipc	ra,0xfffff
    80005150:	3be080e7          	jalr	958(ra) # 8000450a <end_op>
  p = myproc();
    80005154:	ffffd097          	auipc	ra,0xffffd
    80005158:	bbe080e7          	jalr	-1090(ra) # 80001d12 <myproc>
    8000515c:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000515e:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    80005162:	6785                	lui	a5,0x1
    80005164:	17fd                	addi	a5,a5,-1
    80005166:	94be                	add	s1,s1,a5
    80005168:	77fd                	lui	a5,0xfffff
    8000516a:	8fe5                	and	a5,a5,s1
    8000516c:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005170:	6609                	lui	a2,0x2
    80005172:	963e                	add	a2,a2,a5
    80005174:	85be                	mv	a1,a5
    80005176:	855a                	mv	a0,s6
    80005178:	ffffc097          	auipc	ra,0xffffc
    8000517c:	63c080e7          	jalr	1596(ra) # 800017b4 <uvmalloc>
    80005180:	8c2a                	mv	s8,a0
  ip = 0;
    80005182:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005184:	12050e63          	beqz	a0,800052c0 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005188:	75f9                	lui	a1,0xffffe
    8000518a:	95aa                	add	a1,a1,a0
    8000518c:	855a                	mv	a0,s6
    8000518e:	ffffd097          	auipc	ra,0xffffd
    80005192:	844080e7          	jalr	-1980(ra) # 800019d2 <uvmclear>
  stackbase = sp - PGSIZE;
    80005196:	7afd                	lui	s5,0xfffff
    80005198:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    8000519a:	df043783          	ld	a5,-528(s0)
    8000519e:	6388                	ld	a0,0(a5)
    800051a0:	c925                	beqz	a0,80005210 <exec+0x222>
    800051a2:	e8840993          	addi	s3,s0,-376
    800051a6:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    800051aa:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800051ac:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800051ae:	ffffc097          	auipc	ra,0xffffc
    800051b2:	082080e7          	jalr	130(ra) # 80001230 <strlen>
    800051b6:	0015079b          	addiw	a5,a0,1
    800051ba:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800051be:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800051c2:	13596363          	bltu	s2,s5,800052e8 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800051c6:	df043d83          	ld	s11,-528(s0)
    800051ca:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800051ce:	8552                	mv	a0,s4
    800051d0:	ffffc097          	auipc	ra,0xffffc
    800051d4:	060080e7          	jalr	96(ra) # 80001230 <strlen>
    800051d8:	0015069b          	addiw	a3,a0,1
    800051dc:	8652                	mv	a2,s4
    800051de:	85ca                	mv	a1,s2
    800051e0:	855a                	mv	a0,s6
    800051e2:	ffffd097          	auipc	ra,0xffffd
    800051e6:	822080e7          	jalr	-2014(ra) # 80001a04 <copyout>
    800051ea:	10054363          	bltz	a0,800052f0 <exec+0x302>
    ustack[argc] = sp;
    800051ee:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800051f2:	0485                	addi	s1,s1,1
    800051f4:	008d8793          	addi	a5,s11,8
    800051f8:	def43823          	sd	a5,-528(s0)
    800051fc:	008db503          	ld	a0,8(s11)
    80005200:	c911                	beqz	a0,80005214 <exec+0x226>
    if(argc >= MAXARG)
    80005202:	09a1                	addi	s3,s3,8
    80005204:	fb3c95e3          	bne	s9,s3,800051ae <exec+0x1c0>
  sz = sz1;
    80005208:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000520c:	4a81                	li	s5,0
    8000520e:	a84d                	j	800052c0 <exec+0x2d2>
  sp = sz;
    80005210:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005212:	4481                	li	s1,0
  ustack[argc] = 0;
    80005214:	00349793          	slli	a5,s1,0x3
    80005218:	f9040713          	addi	a4,s0,-112
    8000521c:	97ba                	add	a5,a5,a4
    8000521e:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd3ed0>
  sp -= (argc+1) * sizeof(uint64);
    80005222:	00148693          	addi	a3,s1,1
    80005226:	068e                	slli	a3,a3,0x3
    80005228:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000522c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005230:	01597663          	bgeu	s2,s5,8000523c <exec+0x24e>
  sz = sz1;
    80005234:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005238:	4a81                	li	s5,0
    8000523a:	a059                	j	800052c0 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000523c:	e8840613          	addi	a2,s0,-376
    80005240:	85ca                	mv	a1,s2
    80005242:	855a                	mv	a0,s6
    80005244:	ffffc097          	auipc	ra,0xffffc
    80005248:	7c0080e7          	jalr	1984(ra) # 80001a04 <copyout>
    8000524c:	0a054663          	bltz	a0,800052f8 <exec+0x30a>
  p->trapframe->a1 = sp;
    80005250:	060bb783          	ld	a5,96(s7) # 1060 <_entry-0x7fffefa0>
    80005254:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005258:	de843783          	ld	a5,-536(s0)
    8000525c:	0007c703          	lbu	a4,0(a5)
    80005260:	cf11                	beqz	a4,8000527c <exec+0x28e>
    80005262:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005264:	02f00693          	li	a3,47
    80005268:	a039                	j	80005276 <exec+0x288>
      last = s+1;
    8000526a:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000526e:	0785                	addi	a5,a5,1
    80005270:	fff7c703          	lbu	a4,-1(a5)
    80005274:	c701                	beqz	a4,8000527c <exec+0x28e>
    if(*s == '/')
    80005276:	fed71ce3          	bne	a4,a3,8000526e <exec+0x280>
    8000527a:	bfc5                	j	8000526a <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    8000527c:	4641                	li	a2,16
    8000527e:	de843583          	ld	a1,-536(s0)
    80005282:	160b8513          	addi	a0,s7,352
    80005286:	ffffc097          	auipc	ra,0xffffc
    8000528a:	f78080e7          	jalr	-136(ra) # 800011fe <safestrcpy>
  oldpagetable = p->pagetable;
    8000528e:	058bb503          	ld	a0,88(s7)
  p->pagetable = pagetable;
    80005292:	056bbc23          	sd	s6,88(s7)
  p->sz = sz;
    80005296:	058bb823          	sd	s8,80(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000529a:	060bb783          	ld	a5,96(s7)
    8000529e:	e6043703          	ld	a4,-416(s0)
    800052a2:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800052a4:	060bb783          	ld	a5,96(s7)
    800052a8:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800052ac:	85ea                	mv	a1,s10
    800052ae:	ffffd097          	auipc	ra,0xffffd
    800052b2:	bc4080e7          	jalr	-1084(ra) # 80001e72 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800052b6:	0004851b          	sext.w	a0,s1
    800052ba:	bbc1                	j	8000508a <exec+0x9c>
    800052bc:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    800052c0:	df843583          	ld	a1,-520(s0)
    800052c4:	855a                	mv	a0,s6
    800052c6:	ffffd097          	auipc	ra,0xffffd
    800052ca:	bac080e7          	jalr	-1108(ra) # 80001e72 <proc_freepagetable>
  if(ip){
    800052ce:	da0a94e3          	bnez	s5,80005076 <exec+0x88>
  return -1;
    800052d2:	557d                	li	a0,-1
    800052d4:	bb5d                	j	8000508a <exec+0x9c>
    800052d6:	de943c23          	sd	s1,-520(s0)
    800052da:	b7dd                	j	800052c0 <exec+0x2d2>
    800052dc:	de943c23          	sd	s1,-520(s0)
    800052e0:	b7c5                	j	800052c0 <exec+0x2d2>
    800052e2:	de943c23          	sd	s1,-520(s0)
    800052e6:	bfe9                	j	800052c0 <exec+0x2d2>
  sz = sz1;
    800052e8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052ec:	4a81                	li	s5,0
    800052ee:	bfc9                	j	800052c0 <exec+0x2d2>
  sz = sz1;
    800052f0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052f4:	4a81                	li	s5,0
    800052f6:	b7e9                	j	800052c0 <exec+0x2d2>
  sz = sz1;
    800052f8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052fc:	4a81                	li	s5,0
    800052fe:	b7c9                	j	800052c0 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005300:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005304:	e0843783          	ld	a5,-504(s0)
    80005308:	0017869b          	addiw	a3,a5,1
    8000530c:	e0d43423          	sd	a3,-504(s0)
    80005310:	e0043783          	ld	a5,-512(s0)
    80005314:	0387879b          	addiw	a5,a5,56
    80005318:	e8045703          	lhu	a4,-384(s0)
    8000531c:	e2e6d3e3          	bge	a3,a4,80005142 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005320:	2781                	sext.w	a5,a5
    80005322:	e0f43023          	sd	a5,-512(s0)
    80005326:	03800713          	li	a4,56
    8000532a:	86be                	mv	a3,a5
    8000532c:	e1040613          	addi	a2,s0,-496
    80005330:	4581                	li	a1,0
    80005332:	8556                	mv	a0,s5
    80005334:	fffff097          	auipc	ra,0xfffff
    80005338:	a3a080e7          	jalr	-1478(ra) # 80003d6e <readi>
    8000533c:	03800793          	li	a5,56
    80005340:	f6f51ee3          	bne	a0,a5,800052bc <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80005344:	e1042783          	lw	a5,-496(s0)
    80005348:	4705                	li	a4,1
    8000534a:	fae79de3          	bne	a5,a4,80005304 <exec+0x316>
    if(ph.memsz < ph.filesz)
    8000534e:	e3843603          	ld	a2,-456(s0)
    80005352:	e3043783          	ld	a5,-464(s0)
    80005356:	f8f660e3          	bltu	a2,a5,800052d6 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000535a:	e2043783          	ld	a5,-480(s0)
    8000535e:	963e                	add	a2,a2,a5
    80005360:	f6f66ee3          	bltu	a2,a5,800052dc <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005364:	85a6                	mv	a1,s1
    80005366:	855a                	mv	a0,s6
    80005368:	ffffc097          	auipc	ra,0xffffc
    8000536c:	44c080e7          	jalr	1100(ra) # 800017b4 <uvmalloc>
    80005370:	dea43c23          	sd	a0,-520(s0)
    80005374:	d53d                	beqz	a0,800052e2 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80005376:	e2043c03          	ld	s8,-480(s0)
    8000537a:	de043783          	ld	a5,-544(s0)
    8000537e:	00fc77b3          	and	a5,s8,a5
    80005382:	ff9d                	bnez	a5,800052c0 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005384:	e1842c83          	lw	s9,-488(s0)
    80005388:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000538c:	f60b8ae3          	beqz	s7,80005300 <exec+0x312>
    80005390:	89de                	mv	s3,s7
    80005392:	4481                	li	s1,0
    80005394:	b371                	j	80005120 <exec+0x132>

0000000080005396 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005396:	7179                	addi	sp,sp,-48
    80005398:	f406                	sd	ra,40(sp)
    8000539a:	f022                	sd	s0,32(sp)
    8000539c:	ec26                	sd	s1,24(sp)
    8000539e:	e84a                	sd	s2,16(sp)
    800053a0:	1800                	addi	s0,sp,48
    800053a2:	892e                	mv	s2,a1
    800053a4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800053a6:	fdc40593          	addi	a1,s0,-36
    800053aa:	ffffe097          	auipc	ra,0xffffe
    800053ae:	a22080e7          	jalr	-1502(ra) # 80002dcc <argint>
    800053b2:	04054063          	bltz	a0,800053f2 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800053b6:	fdc42703          	lw	a4,-36(s0)
    800053ba:	47bd                	li	a5,15
    800053bc:	02e7ed63          	bltu	a5,a4,800053f6 <argfd+0x60>
    800053c0:	ffffd097          	auipc	ra,0xffffd
    800053c4:	952080e7          	jalr	-1710(ra) # 80001d12 <myproc>
    800053c8:	fdc42703          	lw	a4,-36(s0)
    800053cc:	01a70793          	addi	a5,a4,26
    800053d0:	078e                	slli	a5,a5,0x3
    800053d2:	953e                	add	a0,a0,a5
    800053d4:	651c                	ld	a5,8(a0)
    800053d6:	c395                	beqz	a5,800053fa <argfd+0x64>
    return -1;
  if(pfd)
    800053d8:	00090463          	beqz	s2,800053e0 <argfd+0x4a>
    *pfd = fd;
    800053dc:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800053e0:	4501                	li	a0,0
  if(pf)
    800053e2:	c091                	beqz	s1,800053e6 <argfd+0x50>
    *pf = f;
    800053e4:	e09c                	sd	a5,0(s1)
}
    800053e6:	70a2                	ld	ra,40(sp)
    800053e8:	7402                	ld	s0,32(sp)
    800053ea:	64e2                	ld	s1,24(sp)
    800053ec:	6942                	ld	s2,16(sp)
    800053ee:	6145                	addi	sp,sp,48
    800053f0:	8082                	ret
    return -1;
    800053f2:	557d                	li	a0,-1
    800053f4:	bfcd                	j	800053e6 <argfd+0x50>
    return -1;
    800053f6:	557d                	li	a0,-1
    800053f8:	b7fd                	j	800053e6 <argfd+0x50>
    800053fa:	557d                	li	a0,-1
    800053fc:	b7ed                	j	800053e6 <argfd+0x50>

00000000800053fe <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800053fe:	1101                	addi	sp,sp,-32
    80005400:	ec06                	sd	ra,24(sp)
    80005402:	e822                	sd	s0,16(sp)
    80005404:	e426                	sd	s1,8(sp)
    80005406:	1000                	addi	s0,sp,32
    80005408:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000540a:	ffffd097          	auipc	ra,0xffffd
    8000540e:	908080e7          	jalr	-1784(ra) # 80001d12 <myproc>
    80005412:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005414:	0d850793          	addi	a5,a0,216
    80005418:	4501                	li	a0,0
    8000541a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000541c:	6398                	ld	a4,0(a5)
    8000541e:	cb19                	beqz	a4,80005434 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005420:	2505                	addiw	a0,a0,1
    80005422:	07a1                	addi	a5,a5,8
    80005424:	fed51ce3          	bne	a0,a3,8000541c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005428:	557d                	li	a0,-1
}
    8000542a:	60e2                	ld	ra,24(sp)
    8000542c:	6442                	ld	s0,16(sp)
    8000542e:	64a2                	ld	s1,8(sp)
    80005430:	6105                	addi	sp,sp,32
    80005432:	8082                	ret
      p->ofile[fd] = f;
    80005434:	01a50793          	addi	a5,a0,26
    80005438:	078e                	slli	a5,a5,0x3
    8000543a:	963e                	add	a2,a2,a5
    8000543c:	e604                	sd	s1,8(a2)
      return fd;
    8000543e:	b7f5                	j	8000542a <fdalloc+0x2c>

0000000080005440 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005440:	715d                	addi	sp,sp,-80
    80005442:	e486                	sd	ra,72(sp)
    80005444:	e0a2                	sd	s0,64(sp)
    80005446:	fc26                	sd	s1,56(sp)
    80005448:	f84a                	sd	s2,48(sp)
    8000544a:	f44e                	sd	s3,40(sp)
    8000544c:	f052                	sd	s4,32(sp)
    8000544e:	ec56                	sd	s5,24(sp)
    80005450:	0880                	addi	s0,sp,80
    80005452:	89ae                	mv	s3,a1
    80005454:	8ab2                	mv	s5,a2
    80005456:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005458:	fb040593          	addi	a1,s0,-80
    8000545c:	fffff097          	auipc	ra,0xfffff
    80005460:	e30080e7          	jalr	-464(ra) # 8000428c <nameiparent>
    80005464:	892a                	mv	s2,a0
    80005466:	12050e63          	beqz	a0,800055a2 <create+0x162>
    return 0;

  ilock(dp);
    8000546a:	ffffe097          	auipc	ra,0xffffe
    8000546e:	650080e7          	jalr	1616(ra) # 80003aba <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005472:	4601                	li	a2,0
    80005474:	fb040593          	addi	a1,s0,-80
    80005478:	854a                	mv	a0,s2
    8000547a:	fffff097          	auipc	ra,0xfffff
    8000547e:	b22080e7          	jalr	-1246(ra) # 80003f9c <dirlookup>
    80005482:	84aa                	mv	s1,a0
    80005484:	c921                	beqz	a0,800054d4 <create+0x94>
    iunlockput(dp);
    80005486:	854a                	mv	a0,s2
    80005488:	fffff097          	auipc	ra,0xfffff
    8000548c:	894080e7          	jalr	-1900(ra) # 80003d1c <iunlockput>
    ilock(ip);
    80005490:	8526                	mv	a0,s1
    80005492:	ffffe097          	auipc	ra,0xffffe
    80005496:	628080e7          	jalr	1576(ra) # 80003aba <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000549a:	2981                	sext.w	s3,s3
    8000549c:	4789                	li	a5,2
    8000549e:	02f99463          	bne	s3,a5,800054c6 <create+0x86>
    800054a2:	04c4d783          	lhu	a5,76(s1)
    800054a6:	37f9                	addiw	a5,a5,-2
    800054a8:	17c2                	slli	a5,a5,0x30
    800054aa:	93c1                	srli	a5,a5,0x30
    800054ac:	4705                	li	a4,1
    800054ae:	00f76c63          	bltu	a4,a5,800054c6 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800054b2:	8526                	mv	a0,s1
    800054b4:	60a6                	ld	ra,72(sp)
    800054b6:	6406                	ld	s0,64(sp)
    800054b8:	74e2                	ld	s1,56(sp)
    800054ba:	7942                	ld	s2,48(sp)
    800054bc:	79a2                	ld	s3,40(sp)
    800054be:	7a02                	ld	s4,32(sp)
    800054c0:	6ae2                	ld	s5,24(sp)
    800054c2:	6161                	addi	sp,sp,80
    800054c4:	8082                	ret
    iunlockput(ip);
    800054c6:	8526                	mv	a0,s1
    800054c8:	fffff097          	auipc	ra,0xfffff
    800054cc:	854080e7          	jalr	-1964(ra) # 80003d1c <iunlockput>
    return 0;
    800054d0:	4481                	li	s1,0
    800054d2:	b7c5                	j	800054b2 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800054d4:	85ce                	mv	a1,s3
    800054d6:	00092503          	lw	a0,0(s2)
    800054da:	ffffe097          	auipc	ra,0xffffe
    800054de:	448080e7          	jalr	1096(ra) # 80003922 <ialloc>
    800054e2:	84aa                	mv	s1,a0
    800054e4:	c521                	beqz	a0,8000552c <create+0xec>
  ilock(ip);
    800054e6:	ffffe097          	auipc	ra,0xffffe
    800054ea:	5d4080e7          	jalr	1492(ra) # 80003aba <ilock>
  ip->major = major;
    800054ee:	05549723          	sh	s5,78(s1)
  ip->minor = minor;
    800054f2:	05449823          	sh	s4,80(s1)
  ip->nlink = 1;
    800054f6:	4a05                	li	s4,1
    800054f8:	05449923          	sh	s4,82(s1)
  iupdate(ip);
    800054fc:	8526                	mv	a0,s1
    800054fe:	ffffe097          	auipc	ra,0xffffe
    80005502:	4f2080e7          	jalr	1266(ra) # 800039f0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005506:	2981                	sext.w	s3,s3
    80005508:	03498a63          	beq	s3,s4,8000553c <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000550c:	40d0                	lw	a2,4(s1)
    8000550e:	fb040593          	addi	a1,s0,-80
    80005512:	854a                	mv	a0,s2
    80005514:	fffff097          	auipc	ra,0xfffff
    80005518:	c98080e7          	jalr	-872(ra) # 800041ac <dirlink>
    8000551c:	06054b63          	bltz	a0,80005592 <create+0x152>
  iunlockput(dp);
    80005520:	854a                	mv	a0,s2
    80005522:	ffffe097          	auipc	ra,0xffffe
    80005526:	7fa080e7          	jalr	2042(ra) # 80003d1c <iunlockput>
  return ip;
    8000552a:	b761                	j	800054b2 <create+0x72>
    panic("create: ialloc");
    8000552c:	00003517          	auipc	a0,0x3
    80005530:	24450513          	addi	a0,a0,580 # 80008770 <syscalls+0x2b8>
    80005534:	ffffb097          	auipc	ra,0xffffb
    80005538:	016080e7          	jalr	22(ra) # 8000054a <panic>
    dp->nlink++;  // for ".."
    8000553c:	05295783          	lhu	a5,82(s2)
    80005540:	2785                	addiw	a5,a5,1
    80005542:	04f91923          	sh	a5,82(s2)
    iupdate(dp);
    80005546:	854a                	mv	a0,s2
    80005548:	ffffe097          	auipc	ra,0xffffe
    8000554c:	4a8080e7          	jalr	1192(ra) # 800039f0 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005550:	40d0                	lw	a2,4(s1)
    80005552:	00003597          	auipc	a1,0x3
    80005556:	22e58593          	addi	a1,a1,558 # 80008780 <syscalls+0x2c8>
    8000555a:	8526                	mv	a0,s1
    8000555c:	fffff097          	auipc	ra,0xfffff
    80005560:	c50080e7          	jalr	-944(ra) # 800041ac <dirlink>
    80005564:	00054f63          	bltz	a0,80005582 <create+0x142>
    80005568:	00492603          	lw	a2,4(s2)
    8000556c:	00003597          	auipc	a1,0x3
    80005570:	21c58593          	addi	a1,a1,540 # 80008788 <syscalls+0x2d0>
    80005574:	8526                	mv	a0,s1
    80005576:	fffff097          	auipc	ra,0xfffff
    8000557a:	c36080e7          	jalr	-970(ra) # 800041ac <dirlink>
    8000557e:	f80557e3          	bgez	a0,8000550c <create+0xcc>
      panic("create dots");
    80005582:	00003517          	auipc	a0,0x3
    80005586:	20e50513          	addi	a0,a0,526 # 80008790 <syscalls+0x2d8>
    8000558a:	ffffb097          	auipc	ra,0xffffb
    8000558e:	fc0080e7          	jalr	-64(ra) # 8000054a <panic>
    panic("create: dirlink");
    80005592:	00003517          	auipc	a0,0x3
    80005596:	20e50513          	addi	a0,a0,526 # 800087a0 <syscalls+0x2e8>
    8000559a:	ffffb097          	auipc	ra,0xffffb
    8000559e:	fb0080e7          	jalr	-80(ra) # 8000054a <panic>
    return 0;
    800055a2:	84aa                	mv	s1,a0
    800055a4:	b739                	j	800054b2 <create+0x72>

00000000800055a6 <sys_dup>:
{
    800055a6:	7179                	addi	sp,sp,-48
    800055a8:	f406                	sd	ra,40(sp)
    800055aa:	f022                	sd	s0,32(sp)
    800055ac:	ec26                	sd	s1,24(sp)
    800055ae:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800055b0:	fd840613          	addi	a2,s0,-40
    800055b4:	4581                	li	a1,0
    800055b6:	4501                	li	a0,0
    800055b8:	00000097          	auipc	ra,0x0
    800055bc:	dde080e7          	jalr	-546(ra) # 80005396 <argfd>
    return -1;
    800055c0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800055c2:	02054363          	bltz	a0,800055e8 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800055c6:	fd843503          	ld	a0,-40(s0)
    800055ca:	00000097          	auipc	ra,0x0
    800055ce:	e34080e7          	jalr	-460(ra) # 800053fe <fdalloc>
    800055d2:	84aa                	mv	s1,a0
    return -1;
    800055d4:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800055d6:	00054963          	bltz	a0,800055e8 <sys_dup+0x42>
  filedup(f);
    800055da:	fd843503          	ld	a0,-40(s0)
    800055de:	fffff097          	auipc	ra,0xfffff
    800055e2:	32e080e7          	jalr	814(ra) # 8000490c <filedup>
  return fd;
    800055e6:	87a6                	mv	a5,s1
}
    800055e8:	853e                	mv	a0,a5
    800055ea:	70a2                	ld	ra,40(sp)
    800055ec:	7402                	ld	s0,32(sp)
    800055ee:	64e2                	ld	s1,24(sp)
    800055f0:	6145                	addi	sp,sp,48
    800055f2:	8082                	ret

00000000800055f4 <sys_read>:
{
    800055f4:	7179                	addi	sp,sp,-48
    800055f6:	f406                	sd	ra,40(sp)
    800055f8:	f022                	sd	s0,32(sp)
    800055fa:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055fc:	fe840613          	addi	a2,s0,-24
    80005600:	4581                	li	a1,0
    80005602:	4501                	li	a0,0
    80005604:	00000097          	auipc	ra,0x0
    80005608:	d92080e7          	jalr	-622(ra) # 80005396 <argfd>
    return -1;
    8000560c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000560e:	04054163          	bltz	a0,80005650 <sys_read+0x5c>
    80005612:	fe440593          	addi	a1,s0,-28
    80005616:	4509                	li	a0,2
    80005618:	ffffd097          	auipc	ra,0xffffd
    8000561c:	7b4080e7          	jalr	1972(ra) # 80002dcc <argint>
    return -1;
    80005620:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005622:	02054763          	bltz	a0,80005650 <sys_read+0x5c>
    80005626:	fd840593          	addi	a1,s0,-40
    8000562a:	4505                	li	a0,1
    8000562c:	ffffd097          	auipc	ra,0xffffd
    80005630:	7c2080e7          	jalr	1986(ra) # 80002dee <argaddr>
    return -1;
    80005634:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005636:	00054d63          	bltz	a0,80005650 <sys_read+0x5c>
  return fileread(f, p, n);
    8000563a:	fe442603          	lw	a2,-28(s0)
    8000563e:	fd843583          	ld	a1,-40(s0)
    80005642:	fe843503          	ld	a0,-24(s0)
    80005646:	fffff097          	auipc	ra,0xfffff
    8000564a:	452080e7          	jalr	1106(ra) # 80004a98 <fileread>
    8000564e:	87aa                	mv	a5,a0
}
    80005650:	853e                	mv	a0,a5
    80005652:	70a2                	ld	ra,40(sp)
    80005654:	7402                	ld	s0,32(sp)
    80005656:	6145                	addi	sp,sp,48
    80005658:	8082                	ret

000000008000565a <sys_write>:
{
    8000565a:	7179                	addi	sp,sp,-48
    8000565c:	f406                	sd	ra,40(sp)
    8000565e:	f022                	sd	s0,32(sp)
    80005660:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005662:	fe840613          	addi	a2,s0,-24
    80005666:	4581                	li	a1,0
    80005668:	4501                	li	a0,0
    8000566a:	00000097          	auipc	ra,0x0
    8000566e:	d2c080e7          	jalr	-724(ra) # 80005396 <argfd>
    return -1;
    80005672:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005674:	04054163          	bltz	a0,800056b6 <sys_write+0x5c>
    80005678:	fe440593          	addi	a1,s0,-28
    8000567c:	4509                	li	a0,2
    8000567e:	ffffd097          	auipc	ra,0xffffd
    80005682:	74e080e7          	jalr	1870(ra) # 80002dcc <argint>
    return -1;
    80005686:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005688:	02054763          	bltz	a0,800056b6 <sys_write+0x5c>
    8000568c:	fd840593          	addi	a1,s0,-40
    80005690:	4505                	li	a0,1
    80005692:	ffffd097          	auipc	ra,0xffffd
    80005696:	75c080e7          	jalr	1884(ra) # 80002dee <argaddr>
    return -1;
    8000569a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000569c:	00054d63          	bltz	a0,800056b6 <sys_write+0x5c>
  return filewrite(f, p, n);
    800056a0:	fe442603          	lw	a2,-28(s0)
    800056a4:	fd843583          	ld	a1,-40(s0)
    800056a8:	fe843503          	ld	a0,-24(s0)
    800056ac:	fffff097          	auipc	ra,0xfffff
    800056b0:	4ae080e7          	jalr	1198(ra) # 80004b5a <filewrite>
    800056b4:	87aa                	mv	a5,a0
}
    800056b6:	853e                	mv	a0,a5
    800056b8:	70a2                	ld	ra,40(sp)
    800056ba:	7402                	ld	s0,32(sp)
    800056bc:	6145                	addi	sp,sp,48
    800056be:	8082                	ret

00000000800056c0 <sys_close>:
{
    800056c0:	1101                	addi	sp,sp,-32
    800056c2:	ec06                	sd	ra,24(sp)
    800056c4:	e822                	sd	s0,16(sp)
    800056c6:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800056c8:	fe040613          	addi	a2,s0,-32
    800056cc:	fec40593          	addi	a1,s0,-20
    800056d0:	4501                	li	a0,0
    800056d2:	00000097          	auipc	ra,0x0
    800056d6:	cc4080e7          	jalr	-828(ra) # 80005396 <argfd>
    return -1;
    800056da:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800056dc:	02054463          	bltz	a0,80005704 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800056e0:	ffffc097          	auipc	ra,0xffffc
    800056e4:	632080e7          	jalr	1586(ra) # 80001d12 <myproc>
    800056e8:	fec42783          	lw	a5,-20(s0)
    800056ec:	07e9                	addi	a5,a5,26
    800056ee:	078e                	slli	a5,a5,0x3
    800056f0:	97aa                	add	a5,a5,a0
    800056f2:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    800056f6:	fe043503          	ld	a0,-32(s0)
    800056fa:	fffff097          	auipc	ra,0xfffff
    800056fe:	264080e7          	jalr	612(ra) # 8000495e <fileclose>
  return 0;
    80005702:	4781                	li	a5,0
}
    80005704:	853e                	mv	a0,a5
    80005706:	60e2                	ld	ra,24(sp)
    80005708:	6442                	ld	s0,16(sp)
    8000570a:	6105                	addi	sp,sp,32
    8000570c:	8082                	ret

000000008000570e <sys_fstat>:
{
    8000570e:	1101                	addi	sp,sp,-32
    80005710:	ec06                	sd	ra,24(sp)
    80005712:	e822                	sd	s0,16(sp)
    80005714:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005716:	fe840613          	addi	a2,s0,-24
    8000571a:	4581                	li	a1,0
    8000571c:	4501                	li	a0,0
    8000571e:	00000097          	auipc	ra,0x0
    80005722:	c78080e7          	jalr	-904(ra) # 80005396 <argfd>
    return -1;
    80005726:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005728:	02054563          	bltz	a0,80005752 <sys_fstat+0x44>
    8000572c:	fe040593          	addi	a1,s0,-32
    80005730:	4505                	li	a0,1
    80005732:	ffffd097          	auipc	ra,0xffffd
    80005736:	6bc080e7          	jalr	1724(ra) # 80002dee <argaddr>
    return -1;
    8000573a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000573c:	00054b63          	bltz	a0,80005752 <sys_fstat+0x44>
  return filestat(f, st);
    80005740:	fe043583          	ld	a1,-32(s0)
    80005744:	fe843503          	ld	a0,-24(s0)
    80005748:	fffff097          	auipc	ra,0xfffff
    8000574c:	2de080e7          	jalr	734(ra) # 80004a26 <filestat>
    80005750:	87aa                	mv	a5,a0
}
    80005752:	853e                	mv	a0,a5
    80005754:	60e2                	ld	ra,24(sp)
    80005756:	6442                	ld	s0,16(sp)
    80005758:	6105                	addi	sp,sp,32
    8000575a:	8082                	ret

000000008000575c <sys_link>:
{
    8000575c:	7169                	addi	sp,sp,-304
    8000575e:	f606                	sd	ra,296(sp)
    80005760:	f222                	sd	s0,288(sp)
    80005762:	ee26                	sd	s1,280(sp)
    80005764:	ea4a                	sd	s2,272(sp)
    80005766:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005768:	08000613          	li	a2,128
    8000576c:	ed040593          	addi	a1,s0,-304
    80005770:	4501                	li	a0,0
    80005772:	ffffd097          	auipc	ra,0xffffd
    80005776:	69e080e7          	jalr	1694(ra) # 80002e10 <argstr>
    return -1;
    8000577a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000577c:	10054e63          	bltz	a0,80005898 <sys_link+0x13c>
    80005780:	08000613          	li	a2,128
    80005784:	f5040593          	addi	a1,s0,-176
    80005788:	4505                	li	a0,1
    8000578a:	ffffd097          	auipc	ra,0xffffd
    8000578e:	686080e7          	jalr	1670(ra) # 80002e10 <argstr>
    return -1;
    80005792:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005794:	10054263          	bltz	a0,80005898 <sys_link+0x13c>
  begin_op();
    80005798:	fffff097          	auipc	ra,0xfffff
    8000579c:	cf2080e7          	jalr	-782(ra) # 8000448a <begin_op>
  if((ip = namei(old)) == 0){
    800057a0:	ed040513          	addi	a0,s0,-304
    800057a4:	fffff097          	auipc	ra,0xfffff
    800057a8:	aca080e7          	jalr	-1334(ra) # 8000426e <namei>
    800057ac:	84aa                	mv	s1,a0
    800057ae:	c551                	beqz	a0,8000583a <sys_link+0xde>
  ilock(ip);
    800057b0:	ffffe097          	auipc	ra,0xffffe
    800057b4:	30a080e7          	jalr	778(ra) # 80003aba <ilock>
  if(ip->type == T_DIR){
    800057b8:	04c49703          	lh	a4,76(s1)
    800057bc:	4785                	li	a5,1
    800057be:	08f70463          	beq	a4,a5,80005846 <sys_link+0xea>
  ip->nlink++;
    800057c2:	0524d783          	lhu	a5,82(s1)
    800057c6:	2785                	addiw	a5,a5,1
    800057c8:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    800057cc:	8526                	mv	a0,s1
    800057ce:	ffffe097          	auipc	ra,0xffffe
    800057d2:	222080e7          	jalr	546(ra) # 800039f0 <iupdate>
  iunlock(ip);
    800057d6:	8526                	mv	a0,s1
    800057d8:	ffffe097          	auipc	ra,0xffffe
    800057dc:	3a4080e7          	jalr	932(ra) # 80003b7c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800057e0:	fd040593          	addi	a1,s0,-48
    800057e4:	f5040513          	addi	a0,s0,-176
    800057e8:	fffff097          	auipc	ra,0xfffff
    800057ec:	aa4080e7          	jalr	-1372(ra) # 8000428c <nameiparent>
    800057f0:	892a                	mv	s2,a0
    800057f2:	c935                	beqz	a0,80005866 <sys_link+0x10a>
  ilock(dp);
    800057f4:	ffffe097          	auipc	ra,0xffffe
    800057f8:	2c6080e7          	jalr	710(ra) # 80003aba <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800057fc:	00092703          	lw	a4,0(s2)
    80005800:	409c                	lw	a5,0(s1)
    80005802:	04f71d63          	bne	a4,a5,8000585c <sys_link+0x100>
    80005806:	40d0                	lw	a2,4(s1)
    80005808:	fd040593          	addi	a1,s0,-48
    8000580c:	854a                	mv	a0,s2
    8000580e:	fffff097          	auipc	ra,0xfffff
    80005812:	99e080e7          	jalr	-1634(ra) # 800041ac <dirlink>
    80005816:	04054363          	bltz	a0,8000585c <sys_link+0x100>
  iunlockput(dp);
    8000581a:	854a                	mv	a0,s2
    8000581c:	ffffe097          	auipc	ra,0xffffe
    80005820:	500080e7          	jalr	1280(ra) # 80003d1c <iunlockput>
  iput(ip);
    80005824:	8526                	mv	a0,s1
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	44e080e7          	jalr	1102(ra) # 80003c74 <iput>
  end_op();
    8000582e:	fffff097          	auipc	ra,0xfffff
    80005832:	cdc080e7          	jalr	-804(ra) # 8000450a <end_op>
  return 0;
    80005836:	4781                	li	a5,0
    80005838:	a085                	j	80005898 <sys_link+0x13c>
    end_op();
    8000583a:	fffff097          	auipc	ra,0xfffff
    8000583e:	cd0080e7          	jalr	-816(ra) # 8000450a <end_op>
    return -1;
    80005842:	57fd                	li	a5,-1
    80005844:	a891                	j	80005898 <sys_link+0x13c>
    iunlockput(ip);
    80005846:	8526                	mv	a0,s1
    80005848:	ffffe097          	auipc	ra,0xffffe
    8000584c:	4d4080e7          	jalr	1236(ra) # 80003d1c <iunlockput>
    end_op();
    80005850:	fffff097          	auipc	ra,0xfffff
    80005854:	cba080e7          	jalr	-838(ra) # 8000450a <end_op>
    return -1;
    80005858:	57fd                	li	a5,-1
    8000585a:	a83d                	j	80005898 <sys_link+0x13c>
    iunlockput(dp);
    8000585c:	854a                	mv	a0,s2
    8000585e:	ffffe097          	auipc	ra,0xffffe
    80005862:	4be080e7          	jalr	1214(ra) # 80003d1c <iunlockput>
  ilock(ip);
    80005866:	8526                	mv	a0,s1
    80005868:	ffffe097          	auipc	ra,0xffffe
    8000586c:	252080e7          	jalr	594(ra) # 80003aba <ilock>
  ip->nlink--;
    80005870:	0524d783          	lhu	a5,82(s1)
    80005874:	37fd                	addiw	a5,a5,-1
    80005876:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    8000587a:	8526                	mv	a0,s1
    8000587c:	ffffe097          	auipc	ra,0xffffe
    80005880:	174080e7          	jalr	372(ra) # 800039f0 <iupdate>
  iunlockput(ip);
    80005884:	8526                	mv	a0,s1
    80005886:	ffffe097          	auipc	ra,0xffffe
    8000588a:	496080e7          	jalr	1174(ra) # 80003d1c <iunlockput>
  end_op();
    8000588e:	fffff097          	auipc	ra,0xfffff
    80005892:	c7c080e7          	jalr	-900(ra) # 8000450a <end_op>
  return -1;
    80005896:	57fd                	li	a5,-1
}
    80005898:	853e                	mv	a0,a5
    8000589a:	70b2                	ld	ra,296(sp)
    8000589c:	7412                	ld	s0,288(sp)
    8000589e:	64f2                	ld	s1,280(sp)
    800058a0:	6952                	ld	s2,272(sp)
    800058a2:	6155                	addi	sp,sp,304
    800058a4:	8082                	ret

00000000800058a6 <sys_unlink>:
{
    800058a6:	7151                	addi	sp,sp,-240
    800058a8:	f586                	sd	ra,232(sp)
    800058aa:	f1a2                	sd	s0,224(sp)
    800058ac:	eda6                	sd	s1,216(sp)
    800058ae:	e9ca                	sd	s2,208(sp)
    800058b0:	e5ce                	sd	s3,200(sp)
    800058b2:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800058b4:	08000613          	li	a2,128
    800058b8:	f3040593          	addi	a1,s0,-208
    800058bc:	4501                	li	a0,0
    800058be:	ffffd097          	auipc	ra,0xffffd
    800058c2:	552080e7          	jalr	1362(ra) # 80002e10 <argstr>
    800058c6:	18054163          	bltz	a0,80005a48 <sys_unlink+0x1a2>
  begin_op();
    800058ca:	fffff097          	auipc	ra,0xfffff
    800058ce:	bc0080e7          	jalr	-1088(ra) # 8000448a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800058d2:	fb040593          	addi	a1,s0,-80
    800058d6:	f3040513          	addi	a0,s0,-208
    800058da:	fffff097          	auipc	ra,0xfffff
    800058de:	9b2080e7          	jalr	-1614(ra) # 8000428c <nameiparent>
    800058e2:	84aa                	mv	s1,a0
    800058e4:	c979                	beqz	a0,800059ba <sys_unlink+0x114>
  ilock(dp);
    800058e6:	ffffe097          	auipc	ra,0xffffe
    800058ea:	1d4080e7          	jalr	468(ra) # 80003aba <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800058ee:	00003597          	auipc	a1,0x3
    800058f2:	e9258593          	addi	a1,a1,-366 # 80008780 <syscalls+0x2c8>
    800058f6:	fb040513          	addi	a0,s0,-80
    800058fa:	ffffe097          	auipc	ra,0xffffe
    800058fe:	688080e7          	jalr	1672(ra) # 80003f82 <namecmp>
    80005902:	14050a63          	beqz	a0,80005a56 <sys_unlink+0x1b0>
    80005906:	00003597          	auipc	a1,0x3
    8000590a:	e8258593          	addi	a1,a1,-382 # 80008788 <syscalls+0x2d0>
    8000590e:	fb040513          	addi	a0,s0,-80
    80005912:	ffffe097          	auipc	ra,0xffffe
    80005916:	670080e7          	jalr	1648(ra) # 80003f82 <namecmp>
    8000591a:	12050e63          	beqz	a0,80005a56 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000591e:	f2c40613          	addi	a2,s0,-212
    80005922:	fb040593          	addi	a1,s0,-80
    80005926:	8526                	mv	a0,s1
    80005928:	ffffe097          	auipc	ra,0xffffe
    8000592c:	674080e7          	jalr	1652(ra) # 80003f9c <dirlookup>
    80005930:	892a                	mv	s2,a0
    80005932:	12050263          	beqz	a0,80005a56 <sys_unlink+0x1b0>
  ilock(ip);
    80005936:	ffffe097          	auipc	ra,0xffffe
    8000593a:	184080e7          	jalr	388(ra) # 80003aba <ilock>
  if(ip->nlink < 1)
    8000593e:	05291783          	lh	a5,82(s2)
    80005942:	08f05263          	blez	a5,800059c6 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005946:	04c91703          	lh	a4,76(s2)
    8000594a:	4785                	li	a5,1
    8000594c:	08f70563          	beq	a4,a5,800059d6 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005950:	4641                	li	a2,16
    80005952:	4581                	li	a1,0
    80005954:	fc040513          	addi	a0,s0,-64
    80005958:	ffffb097          	auipc	ra,0xffffb
    8000595c:	754080e7          	jalr	1876(ra) # 800010ac <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005960:	4741                	li	a4,16
    80005962:	f2c42683          	lw	a3,-212(s0)
    80005966:	fc040613          	addi	a2,s0,-64
    8000596a:	4581                	li	a1,0
    8000596c:	8526                	mv	a0,s1
    8000596e:	ffffe097          	auipc	ra,0xffffe
    80005972:	4f8080e7          	jalr	1272(ra) # 80003e66 <writei>
    80005976:	47c1                	li	a5,16
    80005978:	0af51563          	bne	a0,a5,80005a22 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000597c:	04c91703          	lh	a4,76(s2)
    80005980:	4785                	li	a5,1
    80005982:	0af70863          	beq	a4,a5,80005a32 <sys_unlink+0x18c>
  iunlockput(dp);
    80005986:	8526                	mv	a0,s1
    80005988:	ffffe097          	auipc	ra,0xffffe
    8000598c:	394080e7          	jalr	916(ra) # 80003d1c <iunlockput>
  ip->nlink--;
    80005990:	05295783          	lhu	a5,82(s2)
    80005994:	37fd                	addiw	a5,a5,-1
    80005996:	04f91923          	sh	a5,82(s2)
  iupdate(ip);
    8000599a:	854a                	mv	a0,s2
    8000599c:	ffffe097          	auipc	ra,0xffffe
    800059a0:	054080e7          	jalr	84(ra) # 800039f0 <iupdate>
  iunlockput(ip);
    800059a4:	854a                	mv	a0,s2
    800059a6:	ffffe097          	auipc	ra,0xffffe
    800059aa:	376080e7          	jalr	886(ra) # 80003d1c <iunlockput>
  end_op();
    800059ae:	fffff097          	auipc	ra,0xfffff
    800059b2:	b5c080e7          	jalr	-1188(ra) # 8000450a <end_op>
  return 0;
    800059b6:	4501                	li	a0,0
    800059b8:	a84d                	j	80005a6a <sys_unlink+0x1c4>
    end_op();
    800059ba:	fffff097          	auipc	ra,0xfffff
    800059be:	b50080e7          	jalr	-1200(ra) # 8000450a <end_op>
    return -1;
    800059c2:	557d                	li	a0,-1
    800059c4:	a05d                	j	80005a6a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800059c6:	00003517          	auipc	a0,0x3
    800059ca:	dea50513          	addi	a0,a0,-534 # 800087b0 <syscalls+0x2f8>
    800059ce:	ffffb097          	auipc	ra,0xffffb
    800059d2:	b7c080e7          	jalr	-1156(ra) # 8000054a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059d6:	05492703          	lw	a4,84(s2)
    800059da:	02000793          	li	a5,32
    800059de:	f6e7f9e3          	bgeu	a5,a4,80005950 <sys_unlink+0xaa>
    800059e2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059e6:	4741                	li	a4,16
    800059e8:	86ce                	mv	a3,s3
    800059ea:	f1840613          	addi	a2,s0,-232
    800059ee:	4581                	li	a1,0
    800059f0:	854a                	mv	a0,s2
    800059f2:	ffffe097          	auipc	ra,0xffffe
    800059f6:	37c080e7          	jalr	892(ra) # 80003d6e <readi>
    800059fa:	47c1                	li	a5,16
    800059fc:	00f51b63          	bne	a0,a5,80005a12 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a00:	f1845783          	lhu	a5,-232(s0)
    80005a04:	e7a1                	bnez	a5,80005a4c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a06:	29c1                	addiw	s3,s3,16
    80005a08:	05492783          	lw	a5,84(s2)
    80005a0c:	fcf9ede3          	bltu	s3,a5,800059e6 <sys_unlink+0x140>
    80005a10:	b781                	j	80005950 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a12:	00003517          	auipc	a0,0x3
    80005a16:	db650513          	addi	a0,a0,-586 # 800087c8 <syscalls+0x310>
    80005a1a:	ffffb097          	auipc	ra,0xffffb
    80005a1e:	b30080e7          	jalr	-1232(ra) # 8000054a <panic>
    panic("unlink: writei");
    80005a22:	00003517          	auipc	a0,0x3
    80005a26:	dbe50513          	addi	a0,a0,-578 # 800087e0 <syscalls+0x328>
    80005a2a:	ffffb097          	auipc	ra,0xffffb
    80005a2e:	b20080e7          	jalr	-1248(ra) # 8000054a <panic>
    dp->nlink--;
    80005a32:	0524d783          	lhu	a5,82(s1)
    80005a36:	37fd                	addiw	a5,a5,-1
    80005a38:	04f49923          	sh	a5,82(s1)
    iupdate(dp);
    80005a3c:	8526                	mv	a0,s1
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	fb2080e7          	jalr	-78(ra) # 800039f0 <iupdate>
    80005a46:	b781                	j	80005986 <sys_unlink+0xe0>
    return -1;
    80005a48:	557d                	li	a0,-1
    80005a4a:	a005                	j	80005a6a <sys_unlink+0x1c4>
    iunlockput(ip);
    80005a4c:	854a                	mv	a0,s2
    80005a4e:	ffffe097          	auipc	ra,0xffffe
    80005a52:	2ce080e7          	jalr	718(ra) # 80003d1c <iunlockput>
  iunlockput(dp);
    80005a56:	8526                	mv	a0,s1
    80005a58:	ffffe097          	auipc	ra,0xffffe
    80005a5c:	2c4080e7          	jalr	708(ra) # 80003d1c <iunlockput>
  end_op();
    80005a60:	fffff097          	auipc	ra,0xfffff
    80005a64:	aaa080e7          	jalr	-1366(ra) # 8000450a <end_op>
  return -1;
    80005a68:	557d                	li	a0,-1
}
    80005a6a:	70ae                	ld	ra,232(sp)
    80005a6c:	740e                	ld	s0,224(sp)
    80005a6e:	64ee                	ld	s1,216(sp)
    80005a70:	694e                	ld	s2,208(sp)
    80005a72:	69ae                	ld	s3,200(sp)
    80005a74:	616d                	addi	sp,sp,240
    80005a76:	8082                	ret

0000000080005a78 <sys_open>:

uint64
sys_open(void)
{
    80005a78:	7131                	addi	sp,sp,-192
    80005a7a:	fd06                	sd	ra,184(sp)
    80005a7c:	f922                	sd	s0,176(sp)
    80005a7e:	f526                	sd	s1,168(sp)
    80005a80:	f14a                	sd	s2,160(sp)
    80005a82:	ed4e                	sd	s3,152(sp)
    80005a84:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a86:	08000613          	li	a2,128
    80005a8a:	f5040593          	addi	a1,s0,-176
    80005a8e:	4501                	li	a0,0
    80005a90:	ffffd097          	auipc	ra,0xffffd
    80005a94:	380080e7          	jalr	896(ra) # 80002e10 <argstr>
    return -1;
    80005a98:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a9a:	0c054163          	bltz	a0,80005b5c <sys_open+0xe4>
    80005a9e:	f4c40593          	addi	a1,s0,-180
    80005aa2:	4505                	li	a0,1
    80005aa4:	ffffd097          	auipc	ra,0xffffd
    80005aa8:	328080e7          	jalr	808(ra) # 80002dcc <argint>
    80005aac:	0a054863          	bltz	a0,80005b5c <sys_open+0xe4>

  begin_op();
    80005ab0:	fffff097          	auipc	ra,0xfffff
    80005ab4:	9da080e7          	jalr	-1574(ra) # 8000448a <begin_op>

  if(omode & O_CREATE){
    80005ab8:	f4c42783          	lw	a5,-180(s0)
    80005abc:	2007f793          	andi	a5,a5,512
    80005ac0:	cbdd                	beqz	a5,80005b76 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005ac2:	4681                	li	a3,0
    80005ac4:	4601                	li	a2,0
    80005ac6:	4589                	li	a1,2
    80005ac8:	f5040513          	addi	a0,s0,-176
    80005acc:	00000097          	auipc	ra,0x0
    80005ad0:	974080e7          	jalr	-1676(ra) # 80005440 <create>
    80005ad4:	892a                	mv	s2,a0
    if(ip == 0){
    80005ad6:	c959                	beqz	a0,80005b6c <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005ad8:	04c91703          	lh	a4,76(s2)
    80005adc:	478d                	li	a5,3
    80005ade:	00f71763          	bne	a4,a5,80005aec <sys_open+0x74>
    80005ae2:	04e95703          	lhu	a4,78(s2)
    80005ae6:	47a5                	li	a5,9
    80005ae8:	0ce7ec63          	bltu	a5,a4,80005bc0 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005aec:	fffff097          	auipc	ra,0xfffff
    80005af0:	db6080e7          	jalr	-586(ra) # 800048a2 <filealloc>
    80005af4:	89aa                	mv	s3,a0
    80005af6:	10050263          	beqz	a0,80005bfa <sys_open+0x182>
    80005afa:	00000097          	auipc	ra,0x0
    80005afe:	904080e7          	jalr	-1788(ra) # 800053fe <fdalloc>
    80005b02:	84aa                	mv	s1,a0
    80005b04:	0e054663          	bltz	a0,80005bf0 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b08:	04c91703          	lh	a4,76(s2)
    80005b0c:	478d                	li	a5,3
    80005b0e:	0cf70463          	beq	a4,a5,80005bd6 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b12:	4789                	li	a5,2
    80005b14:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b18:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b1c:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b20:	f4c42783          	lw	a5,-180(s0)
    80005b24:	0017c713          	xori	a4,a5,1
    80005b28:	8b05                	andi	a4,a4,1
    80005b2a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b2e:	0037f713          	andi	a4,a5,3
    80005b32:	00e03733          	snez	a4,a4
    80005b36:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b3a:	4007f793          	andi	a5,a5,1024
    80005b3e:	c791                	beqz	a5,80005b4a <sys_open+0xd2>
    80005b40:	04c91703          	lh	a4,76(s2)
    80005b44:	4789                	li	a5,2
    80005b46:	08f70f63          	beq	a4,a5,80005be4 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005b4a:	854a                	mv	a0,s2
    80005b4c:	ffffe097          	auipc	ra,0xffffe
    80005b50:	030080e7          	jalr	48(ra) # 80003b7c <iunlock>
  end_op();
    80005b54:	fffff097          	auipc	ra,0xfffff
    80005b58:	9b6080e7          	jalr	-1610(ra) # 8000450a <end_op>

  return fd;
}
    80005b5c:	8526                	mv	a0,s1
    80005b5e:	70ea                	ld	ra,184(sp)
    80005b60:	744a                	ld	s0,176(sp)
    80005b62:	74aa                	ld	s1,168(sp)
    80005b64:	790a                	ld	s2,160(sp)
    80005b66:	69ea                	ld	s3,152(sp)
    80005b68:	6129                	addi	sp,sp,192
    80005b6a:	8082                	ret
      end_op();
    80005b6c:	fffff097          	auipc	ra,0xfffff
    80005b70:	99e080e7          	jalr	-1634(ra) # 8000450a <end_op>
      return -1;
    80005b74:	b7e5                	j	80005b5c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005b76:	f5040513          	addi	a0,s0,-176
    80005b7a:	ffffe097          	auipc	ra,0xffffe
    80005b7e:	6f4080e7          	jalr	1780(ra) # 8000426e <namei>
    80005b82:	892a                	mv	s2,a0
    80005b84:	c905                	beqz	a0,80005bb4 <sys_open+0x13c>
    ilock(ip);
    80005b86:	ffffe097          	auipc	ra,0xffffe
    80005b8a:	f34080e7          	jalr	-204(ra) # 80003aba <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005b8e:	04c91703          	lh	a4,76(s2)
    80005b92:	4785                	li	a5,1
    80005b94:	f4f712e3          	bne	a4,a5,80005ad8 <sys_open+0x60>
    80005b98:	f4c42783          	lw	a5,-180(s0)
    80005b9c:	dba1                	beqz	a5,80005aec <sys_open+0x74>
      iunlockput(ip);
    80005b9e:	854a                	mv	a0,s2
    80005ba0:	ffffe097          	auipc	ra,0xffffe
    80005ba4:	17c080e7          	jalr	380(ra) # 80003d1c <iunlockput>
      end_op();
    80005ba8:	fffff097          	auipc	ra,0xfffff
    80005bac:	962080e7          	jalr	-1694(ra) # 8000450a <end_op>
      return -1;
    80005bb0:	54fd                	li	s1,-1
    80005bb2:	b76d                	j	80005b5c <sys_open+0xe4>
      end_op();
    80005bb4:	fffff097          	auipc	ra,0xfffff
    80005bb8:	956080e7          	jalr	-1706(ra) # 8000450a <end_op>
      return -1;
    80005bbc:	54fd                	li	s1,-1
    80005bbe:	bf79                	j	80005b5c <sys_open+0xe4>
    iunlockput(ip);
    80005bc0:	854a                	mv	a0,s2
    80005bc2:	ffffe097          	auipc	ra,0xffffe
    80005bc6:	15a080e7          	jalr	346(ra) # 80003d1c <iunlockput>
    end_op();
    80005bca:	fffff097          	auipc	ra,0xfffff
    80005bce:	940080e7          	jalr	-1728(ra) # 8000450a <end_op>
    return -1;
    80005bd2:	54fd                	li	s1,-1
    80005bd4:	b761                	j	80005b5c <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005bd6:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005bda:	04e91783          	lh	a5,78(s2)
    80005bde:	02f99223          	sh	a5,36(s3)
    80005be2:	bf2d                	j	80005b1c <sys_open+0xa4>
    itrunc(ip);
    80005be4:	854a                	mv	a0,s2
    80005be6:	ffffe097          	auipc	ra,0xffffe
    80005bea:	fe2080e7          	jalr	-30(ra) # 80003bc8 <itrunc>
    80005bee:	bfb1                	j	80005b4a <sys_open+0xd2>
      fileclose(f);
    80005bf0:	854e                	mv	a0,s3
    80005bf2:	fffff097          	auipc	ra,0xfffff
    80005bf6:	d6c080e7          	jalr	-660(ra) # 8000495e <fileclose>
    iunlockput(ip);
    80005bfa:	854a                	mv	a0,s2
    80005bfc:	ffffe097          	auipc	ra,0xffffe
    80005c00:	120080e7          	jalr	288(ra) # 80003d1c <iunlockput>
    end_op();
    80005c04:	fffff097          	auipc	ra,0xfffff
    80005c08:	906080e7          	jalr	-1786(ra) # 8000450a <end_op>
    return -1;
    80005c0c:	54fd                	li	s1,-1
    80005c0e:	b7b9                	j	80005b5c <sys_open+0xe4>

0000000080005c10 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c10:	7175                	addi	sp,sp,-144
    80005c12:	e506                	sd	ra,136(sp)
    80005c14:	e122                	sd	s0,128(sp)
    80005c16:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c18:	fffff097          	auipc	ra,0xfffff
    80005c1c:	872080e7          	jalr	-1934(ra) # 8000448a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c20:	08000613          	li	a2,128
    80005c24:	f7040593          	addi	a1,s0,-144
    80005c28:	4501                	li	a0,0
    80005c2a:	ffffd097          	auipc	ra,0xffffd
    80005c2e:	1e6080e7          	jalr	486(ra) # 80002e10 <argstr>
    80005c32:	02054963          	bltz	a0,80005c64 <sys_mkdir+0x54>
    80005c36:	4681                	li	a3,0
    80005c38:	4601                	li	a2,0
    80005c3a:	4585                	li	a1,1
    80005c3c:	f7040513          	addi	a0,s0,-144
    80005c40:	00000097          	auipc	ra,0x0
    80005c44:	800080e7          	jalr	-2048(ra) # 80005440 <create>
    80005c48:	cd11                	beqz	a0,80005c64 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c4a:	ffffe097          	auipc	ra,0xffffe
    80005c4e:	0d2080e7          	jalr	210(ra) # 80003d1c <iunlockput>
  end_op();
    80005c52:	fffff097          	auipc	ra,0xfffff
    80005c56:	8b8080e7          	jalr	-1864(ra) # 8000450a <end_op>
  return 0;
    80005c5a:	4501                	li	a0,0
}
    80005c5c:	60aa                	ld	ra,136(sp)
    80005c5e:	640a                	ld	s0,128(sp)
    80005c60:	6149                	addi	sp,sp,144
    80005c62:	8082                	ret
    end_op();
    80005c64:	fffff097          	auipc	ra,0xfffff
    80005c68:	8a6080e7          	jalr	-1882(ra) # 8000450a <end_op>
    return -1;
    80005c6c:	557d                	li	a0,-1
    80005c6e:	b7fd                	j	80005c5c <sys_mkdir+0x4c>

0000000080005c70 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005c70:	7135                	addi	sp,sp,-160
    80005c72:	ed06                	sd	ra,152(sp)
    80005c74:	e922                	sd	s0,144(sp)
    80005c76:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005c78:	fffff097          	auipc	ra,0xfffff
    80005c7c:	812080e7          	jalr	-2030(ra) # 8000448a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c80:	08000613          	li	a2,128
    80005c84:	f7040593          	addi	a1,s0,-144
    80005c88:	4501                	li	a0,0
    80005c8a:	ffffd097          	auipc	ra,0xffffd
    80005c8e:	186080e7          	jalr	390(ra) # 80002e10 <argstr>
    80005c92:	04054a63          	bltz	a0,80005ce6 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005c96:	f6c40593          	addi	a1,s0,-148
    80005c9a:	4505                	li	a0,1
    80005c9c:	ffffd097          	auipc	ra,0xffffd
    80005ca0:	130080e7          	jalr	304(ra) # 80002dcc <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ca4:	04054163          	bltz	a0,80005ce6 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005ca8:	f6840593          	addi	a1,s0,-152
    80005cac:	4509                	li	a0,2
    80005cae:	ffffd097          	auipc	ra,0xffffd
    80005cb2:	11e080e7          	jalr	286(ra) # 80002dcc <argint>
     argint(1, &major) < 0 ||
    80005cb6:	02054863          	bltz	a0,80005ce6 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005cba:	f6841683          	lh	a3,-152(s0)
    80005cbe:	f6c41603          	lh	a2,-148(s0)
    80005cc2:	458d                	li	a1,3
    80005cc4:	f7040513          	addi	a0,s0,-144
    80005cc8:	fffff097          	auipc	ra,0xfffff
    80005ccc:	778080e7          	jalr	1912(ra) # 80005440 <create>
     argint(2, &minor) < 0 ||
    80005cd0:	c919                	beqz	a0,80005ce6 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cd2:	ffffe097          	auipc	ra,0xffffe
    80005cd6:	04a080e7          	jalr	74(ra) # 80003d1c <iunlockput>
  end_op();
    80005cda:	fffff097          	auipc	ra,0xfffff
    80005cde:	830080e7          	jalr	-2000(ra) # 8000450a <end_op>
  return 0;
    80005ce2:	4501                	li	a0,0
    80005ce4:	a031                	j	80005cf0 <sys_mknod+0x80>
    end_op();
    80005ce6:	fffff097          	auipc	ra,0xfffff
    80005cea:	824080e7          	jalr	-2012(ra) # 8000450a <end_op>
    return -1;
    80005cee:	557d                	li	a0,-1
}
    80005cf0:	60ea                	ld	ra,152(sp)
    80005cf2:	644a                	ld	s0,144(sp)
    80005cf4:	610d                	addi	sp,sp,160
    80005cf6:	8082                	ret

0000000080005cf8 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005cf8:	7135                	addi	sp,sp,-160
    80005cfa:	ed06                	sd	ra,152(sp)
    80005cfc:	e922                	sd	s0,144(sp)
    80005cfe:	e526                	sd	s1,136(sp)
    80005d00:	e14a                	sd	s2,128(sp)
    80005d02:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d04:	ffffc097          	auipc	ra,0xffffc
    80005d08:	00e080e7          	jalr	14(ra) # 80001d12 <myproc>
    80005d0c:	892a                	mv	s2,a0
  
  begin_op();
    80005d0e:	ffffe097          	auipc	ra,0xffffe
    80005d12:	77c080e7          	jalr	1916(ra) # 8000448a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d16:	08000613          	li	a2,128
    80005d1a:	f6040593          	addi	a1,s0,-160
    80005d1e:	4501                	li	a0,0
    80005d20:	ffffd097          	auipc	ra,0xffffd
    80005d24:	0f0080e7          	jalr	240(ra) # 80002e10 <argstr>
    80005d28:	04054b63          	bltz	a0,80005d7e <sys_chdir+0x86>
    80005d2c:	f6040513          	addi	a0,s0,-160
    80005d30:	ffffe097          	auipc	ra,0xffffe
    80005d34:	53e080e7          	jalr	1342(ra) # 8000426e <namei>
    80005d38:	84aa                	mv	s1,a0
    80005d3a:	c131                	beqz	a0,80005d7e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005d3c:	ffffe097          	auipc	ra,0xffffe
    80005d40:	d7e080e7          	jalr	-642(ra) # 80003aba <ilock>
  if(ip->type != T_DIR){
    80005d44:	04c49703          	lh	a4,76(s1)
    80005d48:	4785                	li	a5,1
    80005d4a:	04f71063          	bne	a4,a5,80005d8a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005d4e:	8526                	mv	a0,s1
    80005d50:	ffffe097          	auipc	ra,0xffffe
    80005d54:	e2c080e7          	jalr	-468(ra) # 80003b7c <iunlock>
  iput(p->cwd);
    80005d58:	15893503          	ld	a0,344(s2)
    80005d5c:	ffffe097          	auipc	ra,0xffffe
    80005d60:	f18080e7          	jalr	-232(ra) # 80003c74 <iput>
  end_op();
    80005d64:	ffffe097          	auipc	ra,0xffffe
    80005d68:	7a6080e7          	jalr	1958(ra) # 8000450a <end_op>
  p->cwd = ip;
    80005d6c:	14993c23          	sd	s1,344(s2)
  return 0;
    80005d70:	4501                	li	a0,0
}
    80005d72:	60ea                	ld	ra,152(sp)
    80005d74:	644a                	ld	s0,144(sp)
    80005d76:	64aa                	ld	s1,136(sp)
    80005d78:	690a                	ld	s2,128(sp)
    80005d7a:	610d                	addi	sp,sp,160
    80005d7c:	8082                	ret
    end_op();
    80005d7e:	ffffe097          	auipc	ra,0xffffe
    80005d82:	78c080e7          	jalr	1932(ra) # 8000450a <end_op>
    return -1;
    80005d86:	557d                	li	a0,-1
    80005d88:	b7ed                	j	80005d72 <sys_chdir+0x7a>
    iunlockput(ip);
    80005d8a:	8526                	mv	a0,s1
    80005d8c:	ffffe097          	auipc	ra,0xffffe
    80005d90:	f90080e7          	jalr	-112(ra) # 80003d1c <iunlockput>
    end_op();
    80005d94:	ffffe097          	auipc	ra,0xffffe
    80005d98:	776080e7          	jalr	1910(ra) # 8000450a <end_op>
    return -1;
    80005d9c:	557d                	li	a0,-1
    80005d9e:	bfd1                	j	80005d72 <sys_chdir+0x7a>

0000000080005da0 <sys_exec>:

uint64
sys_exec(void)
{
    80005da0:	7145                	addi	sp,sp,-464
    80005da2:	e786                	sd	ra,456(sp)
    80005da4:	e3a2                	sd	s0,448(sp)
    80005da6:	ff26                	sd	s1,440(sp)
    80005da8:	fb4a                	sd	s2,432(sp)
    80005daa:	f74e                	sd	s3,424(sp)
    80005dac:	f352                	sd	s4,416(sp)
    80005dae:	ef56                	sd	s5,408(sp)
    80005db0:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005db2:	08000613          	li	a2,128
    80005db6:	f4040593          	addi	a1,s0,-192
    80005dba:	4501                	li	a0,0
    80005dbc:	ffffd097          	auipc	ra,0xffffd
    80005dc0:	054080e7          	jalr	84(ra) # 80002e10 <argstr>
    return -1;
    80005dc4:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005dc6:	0c054a63          	bltz	a0,80005e9a <sys_exec+0xfa>
    80005dca:	e3840593          	addi	a1,s0,-456
    80005dce:	4505                	li	a0,1
    80005dd0:	ffffd097          	auipc	ra,0xffffd
    80005dd4:	01e080e7          	jalr	30(ra) # 80002dee <argaddr>
    80005dd8:	0c054163          	bltz	a0,80005e9a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ddc:	10000613          	li	a2,256
    80005de0:	4581                	li	a1,0
    80005de2:	e4040513          	addi	a0,s0,-448
    80005de6:	ffffb097          	auipc	ra,0xffffb
    80005dea:	2c6080e7          	jalr	710(ra) # 800010ac <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005dee:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005df2:	89a6                	mv	s3,s1
    80005df4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005df6:	02000a13          	li	s4,32
    80005dfa:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005dfe:	00391793          	slli	a5,s2,0x3
    80005e02:	e3040593          	addi	a1,s0,-464
    80005e06:	e3843503          	ld	a0,-456(s0)
    80005e0a:	953e                	add	a0,a0,a5
    80005e0c:	ffffd097          	auipc	ra,0xffffd
    80005e10:	f26080e7          	jalr	-218(ra) # 80002d32 <fetchaddr>
    80005e14:	02054a63          	bltz	a0,80005e48 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005e18:	e3043783          	ld	a5,-464(s0)
    80005e1c:	c3b9                	beqz	a5,80005e62 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e1e:	ffffb097          	auipc	ra,0xffffb
    80005e22:	d4c080e7          	jalr	-692(ra) # 80000b6a <kalloc>
    80005e26:	85aa                	mv	a1,a0
    80005e28:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e2c:	cd11                	beqz	a0,80005e48 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e2e:	6605                	lui	a2,0x1
    80005e30:	e3043503          	ld	a0,-464(s0)
    80005e34:	ffffd097          	auipc	ra,0xffffd
    80005e38:	f50080e7          	jalr	-176(ra) # 80002d84 <fetchstr>
    80005e3c:	00054663          	bltz	a0,80005e48 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005e40:	0905                	addi	s2,s2,1
    80005e42:	09a1                	addi	s3,s3,8
    80005e44:	fb491be3          	bne	s2,s4,80005dfa <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e48:	10048913          	addi	s2,s1,256
    80005e4c:	6088                	ld	a0,0(s1)
    80005e4e:	c529                	beqz	a0,80005e98 <sys_exec+0xf8>
    kfree(argv[i]);
    80005e50:	ffffb097          	auipc	ra,0xffffb
    80005e54:	bca080e7          	jalr	-1078(ra) # 80000a1a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e58:	04a1                	addi	s1,s1,8
    80005e5a:	ff2499e3          	bne	s1,s2,80005e4c <sys_exec+0xac>
  return -1;
    80005e5e:	597d                	li	s2,-1
    80005e60:	a82d                	j	80005e9a <sys_exec+0xfa>
      argv[i] = 0;
    80005e62:	0a8e                	slli	s5,s5,0x3
    80005e64:	fc040793          	addi	a5,s0,-64
    80005e68:	9abe                	add	s5,s5,a5
    80005e6a:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd3e58>
  int ret = exec(path, argv);
    80005e6e:	e4040593          	addi	a1,s0,-448
    80005e72:	f4040513          	addi	a0,s0,-192
    80005e76:	fffff097          	auipc	ra,0xfffff
    80005e7a:	178080e7          	jalr	376(ra) # 80004fee <exec>
    80005e7e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e80:	10048993          	addi	s3,s1,256
    80005e84:	6088                	ld	a0,0(s1)
    80005e86:	c911                	beqz	a0,80005e9a <sys_exec+0xfa>
    kfree(argv[i]);
    80005e88:	ffffb097          	auipc	ra,0xffffb
    80005e8c:	b92080e7          	jalr	-1134(ra) # 80000a1a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e90:	04a1                	addi	s1,s1,8
    80005e92:	ff3499e3          	bne	s1,s3,80005e84 <sys_exec+0xe4>
    80005e96:	a011                	j	80005e9a <sys_exec+0xfa>
  return -1;
    80005e98:	597d                	li	s2,-1
}
    80005e9a:	854a                	mv	a0,s2
    80005e9c:	60be                	ld	ra,456(sp)
    80005e9e:	641e                	ld	s0,448(sp)
    80005ea0:	74fa                	ld	s1,440(sp)
    80005ea2:	795a                	ld	s2,432(sp)
    80005ea4:	79ba                	ld	s3,424(sp)
    80005ea6:	7a1a                	ld	s4,416(sp)
    80005ea8:	6afa                	ld	s5,408(sp)
    80005eaa:	6179                	addi	sp,sp,464
    80005eac:	8082                	ret

0000000080005eae <sys_pipe>:

uint64
sys_pipe(void)
{
    80005eae:	7139                	addi	sp,sp,-64
    80005eb0:	fc06                	sd	ra,56(sp)
    80005eb2:	f822                	sd	s0,48(sp)
    80005eb4:	f426                	sd	s1,40(sp)
    80005eb6:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005eb8:	ffffc097          	auipc	ra,0xffffc
    80005ebc:	e5a080e7          	jalr	-422(ra) # 80001d12 <myproc>
    80005ec0:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005ec2:	fd840593          	addi	a1,s0,-40
    80005ec6:	4501                	li	a0,0
    80005ec8:	ffffd097          	auipc	ra,0xffffd
    80005ecc:	f26080e7          	jalr	-218(ra) # 80002dee <argaddr>
    return -1;
    80005ed0:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005ed2:	0e054063          	bltz	a0,80005fb2 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005ed6:	fc840593          	addi	a1,s0,-56
    80005eda:	fd040513          	addi	a0,s0,-48
    80005ede:	fffff097          	auipc	ra,0xfffff
    80005ee2:	dd6080e7          	jalr	-554(ra) # 80004cb4 <pipealloc>
    return -1;
    80005ee6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ee8:	0c054563          	bltz	a0,80005fb2 <sys_pipe+0x104>
  fd0 = -1;
    80005eec:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ef0:	fd043503          	ld	a0,-48(s0)
    80005ef4:	fffff097          	auipc	ra,0xfffff
    80005ef8:	50a080e7          	jalr	1290(ra) # 800053fe <fdalloc>
    80005efc:	fca42223          	sw	a0,-60(s0)
    80005f00:	08054c63          	bltz	a0,80005f98 <sys_pipe+0xea>
    80005f04:	fc843503          	ld	a0,-56(s0)
    80005f08:	fffff097          	auipc	ra,0xfffff
    80005f0c:	4f6080e7          	jalr	1270(ra) # 800053fe <fdalloc>
    80005f10:	fca42023          	sw	a0,-64(s0)
    80005f14:	06054863          	bltz	a0,80005f84 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f18:	4691                	li	a3,4
    80005f1a:	fc440613          	addi	a2,s0,-60
    80005f1e:	fd843583          	ld	a1,-40(s0)
    80005f22:	6ca8                	ld	a0,88(s1)
    80005f24:	ffffc097          	auipc	ra,0xffffc
    80005f28:	ae0080e7          	jalr	-1312(ra) # 80001a04 <copyout>
    80005f2c:	02054063          	bltz	a0,80005f4c <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f30:	4691                	li	a3,4
    80005f32:	fc040613          	addi	a2,s0,-64
    80005f36:	fd843583          	ld	a1,-40(s0)
    80005f3a:	0591                	addi	a1,a1,4
    80005f3c:	6ca8                	ld	a0,88(s1)
    80005f3e:	ffffc097          	auipc	ra,0xffffc
    80005f42:	ac6080e7          	jalr	-1338(ra) # 80001a04 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005f46:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f48:	06055563          	bgez	a0,80005fb2 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005f4c:	fc442783          	lw	a5,-60(s0)
    80005f50:	07e9                	addi	a5,a5,26
    80005f52:	078e                	slli	a5,a5,0x3
    80005f54:	97a6                	add	a5,a5,s1
    80005f56:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005f5a:	fc042503          	lw	a0,-64(s0)
    80005f5e:	0569                	addi	a0,a0,26
    80005f60:	050e                	slli	a0,a0,0x3
    80005f62:	9526                	add	a0,a0,s1
    80005f64:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005f68:	fd043503          	ld	a0,-48(s0)
    80005f6c:	fffff097          	auipc	ra,0xfffff
    80005f70:	9f2080e7          	jalr	-1550(ra) # 8000495e <fileclose>
    fileclose(wf);
    80005f74:	fc843503          	ld	a0,-56(s0)
    80005f78:	fffff097          	auipc	ra,0xfffff
    80005f7c:	9e6080e7          	jalr	-1562(ra) # 8000495e <fileclose>
    return -1;
    80005f80:	57fd                	li	a5,-1
    80005f82:	a805                	j	80005fb2 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005f84:	fc442783          	lw	a5,-60(s0)
    80005f88:	0007c863          	bltz	a5,80005f98 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005f8c:	01a78513          	addi	a0,a5,26
    80005f90:	050e                	slli	a0,a0,0x3
    80005f92:	9526                	add	a0,a0,s1
    80005f94:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005f98:	fd043503          	ld	a0,-48(s0)
    80005f9c:	fffff097          	auipc	ra,0xfffff
    80005fa0:	9c2080e7          	jalr	-1598(ra) # 8000495e <fileclose>
    fileclose(wf);
    80005fa4:	fc843503          	ld	a0,-56(s0)
    80005fa8:	fffff097          	auipc	ra,0xfffff
    80005fac:	9b6080e7          	jalr	-1610(ra) # 8000495e <fileclose>
    return -1;
    80005fb0:	57fd                	li	a5,-1
}
    80005fb2:	853e                	mv	a0,a5
    80005fb4:	70e2                	ld	ra,56(sp)
    80005fb6:	7442                	ld	s0,48(sp)
    80005fb8:	74a2                	ld	s1,40(sp)
    80005fba:	6121                	addi	sp,sp,64
    80005fbc:	8082                	ret
	...

0000000080005fc0 <kernelvec>:
    80005fc0:	7111                	addi	sp,sp,-256
    80005fc2:	e006                	sd	ra,0(sp)
    80005fc4:	e40a                	sd	sp,8(sp)
    80005fc6:	e80e                	sd	gp,16(sp)
    80005fc8:	ec12                	sd	tp,24(sp)
    80005fca:	f016                	sd	t0,32(sp)
    80005fcc:	f41a                	sd	t1,40(sp)
    80005fce:	f81e                	sd	t2,48(sp)
    80005fd0:	fc22                	sd	s0,56(sp)
    80005fd2:	e0a6                	sd	s1,64(sp)
    80005fd4:	e4aa                	sd	a0,72(sp)
    80005fd6:	e8ae                	sd	a1,80(sp)
    80005fd8:	ecb2                	sd	a2,88(sp)
    80005fda:	f0b6                	sd	a3,96(sp)
    80005fdc:	f4ba                	sd	a4,104(sp)
    80005fde:	f8be                	sd	a5,112(sp)
    80005fe0:	fcc2                	sd	a6,120(sp)
    80005fe2:	e146                	sd	a7,128(sp)
    80005fe4:	e54a                	sd	s2,136(sp)
    80005fe6:	e94e                	sd	s3,144(sp)
    80005fe8:	ed52                	sd	s4,152(sp)
    80005fea:	f156                	sd	s5,160(sp)
    80005fec:	f55a                	sd	s6,168(sp)
    80005fee:	f95e                	sd	s7,176(sp)
    80005ff0:	fd62                	sd	s8,184(sp)
    80005ff2:	e1e6                	sd	s9,192(sp)
    80005ff4:	e5ea                	sd	s10,200(sp)
    80005ff6:	e9ee                	sd	s11,208(sp)
    80005ff8:	edf2                	sd	t3,216(sp)
    80005ffa:	f1f6                	sd	t4,224(sp)
    80005ffc:	f5fa                	sd	t5,232(sp)
    80005ffe:	f9fe                	sd	t6,240(sp)
    80006000:	bfffc0ef          	jal	ra,80002bfe <kerneltrap>
    80006004:	6082                	ld	ra,0(sp)
    80006006:	6122                	ld	sp,8(sp)
    80006008:	61c2                	ld	gp,16(sp)
    8000600a:	7282                	ld	t0,32(sp)
    8000600c:	7322                	ld	t1,40(sp)
    8000600e:	73c2                	ld	t2,48(sp)
    80006010:	7462                	ld	s0,56(sp)
    80006012:	6486                	ld	s1,64(sp)
    80006014:	6526                	ld	a0,72(sp)
    80006016:	65c6                	ld	a1,80(sp)
    80006018:	6666                	ld	a2,88(sp)
    8000601a:	7686                	ld	a3,96(sp)
    8000601c:	7726                	ld	a4,104(sp)
    8000601e:	77c6                	ld	a5,112(sp)
    80006020:	7866                	ld	a6,120(sp)
    80006022:	688a                	ld	a7,128(sp)
    80006024:	692a                	ld	s2,136(sp)
    80006026:	69ca                	ld	s3,144(sp)
    80006028:	6a6a                	ld	s4,152(sp)
    8000602a:	7a8a                	ld	s5,160(sp)
    8000602c:	7b2a                	ld	s6,168(sp)
    8000602e:	7bca                	ld	s7,176(sp)
    80006030:	7c6a                	ld	s8,184(sp)
    80006032:	6c8e                	ld	s9,192(sp)
    80006034:	6d2e                	ld	s10,200(sp)
    80006036:	6dce                	ld	s11,208(sp)
    80006038:	6e6e                	ld	t3,216(sp)
    8000603a:	7e8e                	ld	t4,224(sp)
    8000603c:	7f2e                	ld	t5,232(sp)
    8000603e:	7fce                	ld	t6,240(sp)
    80006040:	6111                	addi	sp,sp,256
    80006042:	10200073          	sret
    80006046:	00000013          	nop
    8000604a:	00000013          	nop
    8000604e:	0001                	nop

0000000080006050 <timervec>:
    80006050:	34051573          	csrrw	a0,mscratch,a0
    80006054:	e10c                	sd	a1,0(a0)
    80006056:	e510                	sd	a2,8(a0)
    80006058:	e914                	sd	a3,16(a0)
    8000605a:	6d0c                	ld	a1,24(a0)
    8000605c:	7110                	ld	a2,32(a0)
    8000605e:	6194                	ld	a3,0(a1)
    80006060:	96b2                	add	a3,a3,a2
    80006062:	e194                	sd	a3,0(a1)
    80006064:	4589                	li	a1,2
    80006066:	14459073          	csrw	sip,a1
    8000606a:	6914                	ld	a3,16(a0)
    8000606c:	6510                	ld	a2,8(a0)
    8000606e:	610c                	ld	a1,0(a0)
    80006070:	34051573          	csrrw	a0,mscratch,a0
    80006074:	30200073          	mret
	...

000000008000607a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000607a:	1141                	addi	sp,sp,-16
    8000607c:	e422                	sd	s0,8(sp)
    8000607e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006080:	0c0007b7          	lui	a5,0xc000
    80006084:	4705                	li	a4,1
    80006086:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006088:	c3d8                	sw	a4,4(a5)
}
    8000608a:	6422                	ld	s0,8(sp)
    8000608c:	0141                	addi	sp,sp,16
    8000608e:	8082                	ret

0000000080006090 <plicinithart>:

void
plicinithart(void)
{
    80006090:	1141                	addi	sp,sp,-16
    80006092:	e406                	sd	ra,8(sp)
    80006094:	e022                	sd	s0,0(sp)
    80006096:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006098:	ffffc097          	auipc	ra,0xffffc
    8000609c:	c4e080e7          	jalr	-946(ra) # 80001ce6 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800060a0:	0085171b          	slliw	a4,a0,0x8
    800060a4:	0c0027b7          	lui	a5,0xc002
    800060a8:	97ba                	add	a5,a5,a4
    800060aa:	40200713          	li	a4,1026
    800060ae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800060b2:	00d5151b          	slliw	a0,a0,0xd
    800060b6:	0c2017b7          	lui	a5,0xc201
    800060ba:	953e                	add	a0,a0,a5
    800060bc:	00052023          	sw	zero,0(a0)
}
    800060c0:	60a2                	ld	ra,8(sp)
    800060c2:	6402                	ld	s0,0(sp)
    800060c4:	0141                	addi	sp,sp,16
    800060c6:	8082                	ret

00000000800060c8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800060c8:	1141                	addi	sp,sp,-16
    800060ca:	e406                	sd	ra,8(sp)
    800060cc:	e022                	sd	s0,0(sp)
    800060ce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060d0:	ffffc097          	auipc	ra,0xffffc
    800060d4:	c16080e7          	jalr	-1002(ra) # 80001ce6 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800060d8:	00d5179b          	slliw	a5,a0,0xd
    800060dc:	0c201537          	lui	a0,0xc201
    800060e0:	953e                	add	a0,a0,a5
  return irq;
}
    800060e2:	4148                	lw	a0,4(a0)
    800060e4:	60a2                	ld	ra,8(sp)
    800060e6:	6402                	ld	s0,0(sp)
    800060e8:	0141                	addi	sp,sp,16
    800060ea:	8082                	ret

00000000800060ec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800060ec:	1101                	addi	sp,sp,-32
    800060ee:	ec06                	sd	ra,24(sp)
    800060f0:	e822                	sd	s0,16(sp)
    800060f2:	e426                	sd	s1,8(sp)
    800060f4:	1000                	addi	s0,sp,32
    800060f6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800060f8:	ffffc097          	auipc	ra,0xffffc
    800060fc:	bee080e7          	jalr	-1042(ra) # 80001ce6 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006100:	00d5151b          	slliw	a0,a0,0xd
    80006104:	0c2017b7          	lui	a5,0xc201
    80006108:	97aa                	add	a5,a5,a0
    8000610a:	c3c4                	sw	s1,4(a5)
}
    8000610c:	60e2                	ld	ra,24(sp)
    8000610e:	6442                	ld	s0,16(sp)
    80006110:	64a2                	ld	s1,8(sp)
    80006112:	6105                	addi	sp,sp,32
    80006114:	8082                	ret

0000000080006116 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006116:	1141                	addi	sp,sp,-16
    80006118:	e406                	sd	ra,8(sp)
    8000611a:	e022                	sd	s0,0(sp)
    8000611c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000611e:	479d                	li	a5,7
    80006120:	06a7c963          	blt	a5,a0,80006192 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006124:	00021797          	auipc	a5,0x21
    80006128:	edc78793          	addi	a5,a5,-292 # 80027000 <disk>
    8000612c:	00a78733          	add	a4,a5,a0
    80006130:	6789                	lui	a5,0x2
    80006132:	97ba                	add	a5,a5,a4
    80006134:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006138:	e7ad                	bnez	a5,800061a2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000613a:	00451793          	slli	a5,a0,0x4
    8000613e:	00023717          	auipc	a4,0x23
    80006142:	ec270713          	addi	a4,a4,-318 # 80029000 <disk+0x2000>
    80006146:	6314                	ld	a3,0(a4)
    80006148:	96be                	add	a3,a3,a5
    8000614a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000614e:	6314                	ld	a3,0(a4)
    80006150:	96be                	add	a3,a3,a5
    80006152:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006156:	6314                	ld	a3,0(a4)
    80006158:	96be                	add	a3,a3,a5
    8000615a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000615e:	6318                	ld	a4,0(a4)
    80006160:	97ba                	add	a5,a5,a4
    80006162:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006166:	00021797          	auipc	a5,0x21
    8000616a:	e9a78793          	addi	a5,a5,-358 # 80027000 <disk>
    8000616e:	97aa                	add	a5,a5,a0
    80006170:	6509                	lui	a0,0x2
    80006172:	953e                	add	a0,a0,a5
    80006174:	4785                	li	a5,1
    80006176:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000617a:	00023517          	auipc	a0,0x23
    8000617e:	e9e50513          	addi	a0,a0,-354 # 80029018 <disk+0x2018>
    80006182:	ffffc097          	auipc	ra,0xffffc
    80006186:	524080e7          	jalr	1316(ra) # 800026a6 <wakeup>
}
    8000618a:	60a2                	ld	ra,8(sp)
    8000618c:	6402                	ld	s0,0(sp)
    8000618e:	0141                	addi	sp,sp,16
    80006190:	8082                	ret
    panic("free_desc 1");
    80006192:	00002517          	auipc	a0,0x2
    80006196:	65e50513          	addi	a0,a0,1630 # 800087f0 <syscalls+0x338>
    8000619a:	ffffa097          	auipc	ra,0xffffa
    8000619e:	3b0080e7          	jalr	944(ra) # 8000054a <panic>
    panic("free_desc 2");
    800061a2:	00002517          	auipc	a0,0x2
    800061a6:	65e50513          	addi	a0,a0,1630 # 80008800 <syscalls+0x348>
    800061aa:	ffffa097          	auipc	ra,0xffffa
    800061ae:	3a0080e7          	jalr	928(ra) # 8000054a <panic>

00000000800061b2 <virtio_disk_init>:
{
    800061b2:	1101                	addi	sp,sp,-32
    800061b4:	ec06                	sd	ra,24(sp)
    800061b6:	e822                	sd	s0,16(sp)
    800061b8:	e426                	sd	s1,8(sp)
    800061ba:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800061bc:	00002597          	auipc	a1,0x2
    800061c0:	65458593          	addi	a1,a1,1620 # 80008810 <syscalls+0x358>
    800061c4:	00023517          	auipc	a0,0x23
    800061c8:	f6450513          	addi	a0,a0,-156 # 80029128 <disk+0x2128>
    800061cc:	ffffb097          	auipc	ra,0xffffb
    800061d0:	c7c080e7          	jalr	-900(ra) # 80000e48 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061d4:	100017b7          	lui	a5,0x10001
    800061d8:	4398                	lw	a4,0(a5)
    800061da:	2701                	sext.w	a4,a4
    800061dc:	747277b7          	lui	a5,0x74727
    800061e0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800061e4:	0ef71163          	bne	a4,a5,800062c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800061e8:	100017b7          	lui	a5,0x10001
    800061ec:	43dc                	lw	a5,4(a5)
    800061ee:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061f0:	4705                	li	a4,1
    800061f2:	0ce79a63          	bne	a5,a4,800062c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061f6:	100017b7          	lui	a5,0x10001
    800061fa:	479c                	lw	a5,8(a5)
    800061fc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800061fe:	4709                	li	a4,2
    80006200:	0ce79363          	bne	a5,a4,800062c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006204:	100017b7          	lui	a5,0x10001
    80006208:	47d8                	lw	a4,12(a5)
    8000620a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000620c:	554d47b7          	lui	a5,0x554d4
    80006210:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006214:	0af71963          	bne	a4,a5,800062c6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006218:	100017b7          	lui	a5,0x10001
    8000621c:	4705                	li	a4,1
    8000621e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006220:	470d                	li	a4,3
    80006222:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006224:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006226:	c7ffe737          	lui	a4,0xc7ffe
    8000622a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd3737>
    8000622e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006230:	2701                	sext.w	a4,a4
    80006232:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006234:	472d                	li	a4,11
    80006236:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006238:	473d                	li	a4,15
    8000623a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000623c:	6705                	lui	a4,0x1
    8000623e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006240:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006244:	5bdc                	lw	a5,52(a5)
    80006246:	2781                	sext.w	a5,a5
  if(max == 0)
    80006248:	c7d9                	beqz	a5,800062d6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000624a:	471d                	li	a4,7
    8000624c:	08f77d63          	bgeu	a4,a5,800062e6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006250:	100014b7          	lui	s1,0x10001
    80006254:	47a1                	li	a5,8
    80006256:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006258:	6609                	lui	a2,0x2
    8000625a:	4581                	li	a1,0
    8000625c:	00021517          	auipc	a0,0x21
    80006260:	da450513          	addi	a0,a0,-604 # 80027000 <disk>
    80006264:	ffffb097          	auipc	ra,0xffffb
    80006268:	e48080e7          	jalr	-440(ra) # 800010ac <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000626c:	00021717          	auipc	a4,0x21
    80006270:	d9470713          	addi	a4,a4,-620 # 80027000 <disk>
    80006274:	00c75793          	srli	a5,a4,0xc
    80006278:	2781                	sext.w	a5,a5
    8000627a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000627c:	00023797          	auipc	a5,0x23
    80006280:	d8478793          	addi	a5,a5,-636 # 80029000 <disk+0x2000>
    80006284:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006286:	00021717          	auipc	a4,0x21
    8000628a:	dfa70713          	addi	a4,a4,-518 # 80027080 <disk+0x80>
    8000628e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006290:	00022717          	auipc	a4,0x22
    80006294:	d7070713          	addi	a4,a4,-656 # 80028000 <disk+0x1000>
    80006298:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000629a:	4705                	li	a4,1
    8000629c:	00e78c23          	sb	a4,24(a5)
    800062a0:	00e78ca3          	sb	a4,25(a5)
    800062a4:	00e78d23          	sb	a4,26(a5)
    800062a8:	00e78da3          	sb	a4,27(a5)
    800062ac:	00e78e23          	sb	a4,28(a5)
    800062b0:	00e78ea3          	sb	a4,29(a5)
    800062b4:	00e78f23          	sb	a4,30(a5)
    800062b8:	00e78fa3          	sb	a4,31(a5)
}
    800062bc:	60e2                	ld	ra,24(sp)
    800062be:	6442                	ld	s0,16(sp)
    800062c0:	64a2                	ld	s1,8(sp)
    800062c2:	6105                	addi	sp,sp,32
    800062c4:	8082                	ret
    panic("could not find virtio disk");
    800062c6:	00002517          	auipc	a0,0x2
    800062ca:	55a50513          	addi	a0,a0,1370 # 80008820 <syscalls+0x368>
    800062ce:	ffffa097          	auipc	ra,0xffffa
    800062d2:	27c080e7          	jalr	636(ra) # 8000054a <panic>
    panic("virtio disk has no queue 0");
    800062d6:	00002517          	auipc	a0,0x2
    800062da:	56a50513          	addi	a0,a0,1386 # 80008840 <syscalls+0x388>
    800062de:	ffffa097          	auipc	ra,0xffffa
    800062e2:	26c080e7          	jalr	620(ra) # 8000054a <panic>
    panic("virtio disk max queue too short");
    800062e6:	00002517          	auipc	a0,0x2
    800062ea:	57a50513          	addi	a0,a0,1402 # 80008860 <syscalls+0x3a8>
    800062ee:	ffffa097          	auipc	ra,0xffffa
    800062f2:	25c080e7          	jalr	604(ra) # 8000054a <panic>

00000000800062f6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800062f6:	7119                	addi	sp,sp,-128
    800062f8:	fc86                	sd	ra,120(sp)
    800062fa:	f8a2                	sd	s0,112(sp)
    800062fc:	f4a6                	sd	s1,104(sp)
    800062fe:	f0ca                	sd	s2,96(sp)
    80006300:	ecce                	sd	s3,88(sp)
    80006302:	e8d2                	sd	s4,80(sp)
    80006304:	e4d6                	sd	s5,72(sp)
    80006306:	e0da                	sd	s6,64(sp)
    80006308:	fc5e                	sd	s7,56(sp)
    8000630a:	f862                	sd	s8,48(sp)
    8000630c:	f466                	sd	s9,40(sp)
    8000630e:	f06a                	sd	s10,32(sp)
    80006310:	ec6e                	sd	s11,24(sp)
    80006312:	0100                	addi	s0,sp,128
    80006314:	8aaa                	mv	s5,a0
    80006316:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006318:	00c52c83          	lw	s9,12(a0)
    8000631c:	001c9c9b          	slliw	s9,s9,0x1
    80006320:	1c82                	slli	s9,s9,0x20
    80006322:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006326:	00023517          	auipc	a0,0x23
    8000632a:	e0250513          	addi	a0,a0,-510 # 80029128 <disk+0x2128>
    8000632e:	ffffb097          	auipc	ra,0xffffb
    80006332:	99e080e7          	jalr	-1634(ra) # 80000ccc <acquire>
  for(int i = 0; i < 3; i++){
    80006336:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006338:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000633a:	00021c17          	auipc	s8,0x21
    8000633e:	cc6c0c13          	addi	s8,s8,-826 # 80027000 <disk>
    80006342:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006344:	4b0d                	li	s6,3
    80006346:	a0ad                	j	800063b0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006348:	00fc0733          	add	a4,s8,a5
    8000634c:	975e                	add	a4,a4,s7
    8000634e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006352:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006354:	0207c563          	bltz	a5,8000637e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006358:	2905                	addiw	s2,s2,1
    8000635a:	0611                	addi	a2,a2,4
    8000635c:	19690d63          	beq	s2,s6,800064f6 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006360:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006362:	00023717          	auipc	a4,0x23
    80006366:	cb670713          	addi	a4,a4,-842 # 80029018 <disk+0x2018>
    8000636a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000636c:	00074683          	lbu	a3,0(a4)
    80006370:	fee1                	bnez	a3,80006348 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006372:	2785                	addiw	a5,a5,1
    80006374:	0705                	addi	a4,a4,1
    80006376:	fe979be3          	bne	a5,s1,8000636c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000637a:	57fd                	li	a5,-1
    8000637c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000637e:	01205d63          	blez	s2,80006398 <virtio_disk_rw+0xa2>
    80006382:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006384:	000a2503          	lw	a0,0(s4)
    80006388:	00000097          	auipc	ra,0x0
    8000638c:	d8e080e7          	jalr	-626(ra) # 80006116 <free_desc>
      for(int j = 0; j < i; j++)
    80006390:	2d85                	addiw	s11,s11,1
    80006392:	0a11                	addi	s4,s4,4
    80006394:	ffb918e3          	bne	s2,s11,80006384 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006398:	00023597          	auipc	a1,0x23
    8000639c:	d9058593          	addi	a1,a1,-624 # 80029128 <disk+0x2128>
    800063a0:	00023517          	auipc	a0,0x23
    800063a4:	c7850513          	addi	a0,a0,-904 # 80029018 <disk+0x2018>
    800063a8:	ffffc097          	auipc	ra,0xffffc
    800063ac:	17e080e7          	jalr	382(ra) # 80002526 <sleep>
  for(int i = 0; i < 3; i++){
    800063b0:	f8040a13          	addi	s4,s0,-128
{
    800063b4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800063b6:	894e                	mv	s2,s3
    800063b8:	b765                	j	80006360 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800063ba:	00023697          	auipc	a3,0x23
    800063be:	c466b683          	ld	a3,-954(a3) # 80029000 <disk+0x2000>
    800063c2:	96ba                	add	a3,a3,a4
    800063c4:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800063c8:	00021817          	auipc	a6,0x21
    800063cc:	c3880813          	addi	a6,a6,-968 # 80027000 <disk>
    800063d0:	00023697          	auipc	a3,0x23
    800063d4:	c3068693          	addi	a3,a3,-976 # 80029000 <disk+0x2000>
    800063d8:	6290                	ld	a2,0(a3)
    800063da:	963a                	add	a2,a2,a4
    800063dc:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    800063e0:	0015e593          	ori	a1,a1,1
    800063e4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800063e8:	f8842603          	lw	a2,-120(s0)
    800063ec:	628c                	ld	a1,0(a3)
    800063ee:	972e                	add	a4,a4,a1
    800063f0:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800063f4:	20050593          	addi	a1,a0,512
    800063f8:	0592                	slli	a1,a1,0x4
    800063fa:	95c2                	add	a1,a1,a6
    800063fc:	577d                	li	a4,-1
    800063fe:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006402:	00461713          	slli	a4,a2,0x4
    80006406:	6290                	ld	a2,0(a3)
    80006408:	963a                	add	a2,a2,a4
    8000640a:	03078793          	addi	a5,a5,48
    8000640e:	97c2                	add	a5,a5,a6
    80006410:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006412:	629c                	ld	a5,0(a3)
    80006414:	97ba                	add	a5,a5,a4
    80006416:	4605                	li	a2,1
    80006418:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000641a:	629c                	ld	a5,0(a3)
    8000641c:	97ba                	add	a5,a5,a4
    8000641e:	4809                	li	a6,2
    80006420:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006424:	629c                	ld	a5,0(a3)
    80006426:	973e                	add	a4,a4,a5
    80006428:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000642c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006430:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006434:	6698                	ld	a4,8(a3)
    80006436:	00275783          	lhu	a5,2(a4)
    8000643a:	8b9d                	andi	a5,a5,7
    8000643c:	0786                	slli	a5,a5,0x1
    8000643e:	97ba                	add	a5,a5,a4
    80006440:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006444:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006448:	6698                	ld	a4,8(a3)
    8000644a:	00275783          	lhu	a5,2(a4)
    8000644e:	2785                	addiw	a5,a5,1
    80006450:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006454:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006458:	100017b7          	lui	a5,0x10001
    8000645c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006460:	004aa783          	lw	a5,4(s5)
    80006464:	02c79163          	bne	a5,a2,80006486 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006468:	00023917          	auipc	s2,0x23
    8000646c:	cc090913          	addi	s2,s2,-832 # 80029128 <disk+0x2128>
  while(b->disk == 1) {
    80006470:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006472:	85ca                	mv	a1,s2
    80006474:	8556                	mv	a0,s5
    80006476:	ffffc097          	auipc	ra,0xffffc
    8000647a:	0b0080e7          	jalr	176(ra) # 80002526 <sleep>
  while(b->disk == 1) {
    8000647e:	004aa783          	lw	a5,4(s5)
    80006482:	fe9788e3          	beq	a5,s1,80006472 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006486:	f8042903          	lw	s2,-128(s0)
    8000648a:	20090793          	addi	a5,s2,512
    8000648e:	00479713          	slli	a4,a5,0x4
    80006492:	00021797          	auipc	a5,0x21
    80006496:	b6e78793          	addi	a5,a5,-1170 # 80027000 <disk>
    8000649a:	97ba                	add	a5,a5,a4
    8000649c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800064a0:	00023997          	auipc	s3,0x23
    800064a4:	b6098993          	addi	s3,s3,-1184 # 80029000 <disk+0x2000>
    800064a8:	00491713          	slli	a4,s2,0x4
    800064ac:	0009b783          	ld	a5,0(s3)
    800064b0:	97ba                	add	a5,a5,a4
    800064b2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800064b6:	854a                	mv	a0,s2
    800064b8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800064bc:	00000097          	auipc	ra,0x0
    800064c0:	c5a080e7          	jalr	-934(ra) # 80006116 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800064c4:	8885                	andi	s1,s1,1
    800064c6:	f0ed                	bnez	s1,800064a8 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800064c8:	00023517          	auipc	a0,0x23
    800064cc:	c6050513          	addi	a0,a0,-928 # 80029128 <disk+0x2128>
    800064d0:	ffffb097          	auipc	ra,0xffffb
    800064d4:	8cc080e7          	jalr	-1844(ra) # 80000d9c <release>
}
    800064d8:	70e6                	ld	ra,120(sp)
    800064da:	7446                	ld	s0,112(sp)
    800064dc:	74a6                	ld	s1,104(sp)
    800064de:	7906                	ld	s2,96(sp)
    800064e0:	69e6                	ld	s3,88(sp)
    800064e2:	6a46                	ld	s4,80(sp)
    800064e4:	6aa6                	ld	s5,72(sp)
    800064e6:	6b06                	ld	s6,64(sp)
    800064e8:	7be2                	ld	s7,56(sp)
    800064ea:	7c42                	ld	s8,48(sp)
    800064ec:	7ca2                	ld	s9,40(sp)
    800064ee:	7d02                	ld	s10,32(sp)
    800064f0:	6de2                	ld	s11,24(sp)
    800064f2:	6109                	addi	sp,sp,128
    800064f4:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800064f6:	f8042503          	lw	a0,-128(s0)
    800064fa:	20050793          	addi	a5,a0,512
    800064fe:	0792                	slli	a5,a5,0x4
  if(write)
    80006500:	00021817          	auipc	a6,0x21
    80006504:	b0080813          	addi	a6,a6,-1280 # 80027000 <disk>
    80006508:	00f80733          	add	a4,a6,a5
    8000650c:	01a036b3          	snez	a3,s10
    80006510:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006514:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006518:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000651c:	7679                	lui	a2,0xffffe
    8000651e:	963e                	add	a2,a2,a5
    80006520:	00023697          	auipc	a3,0x23
    80006524:	ae068693          	addi	a3,a3,-1312 # 80029000 <disk+0x2000>
    80006528:	6298                	ld	a4,0(a3)
    8000652a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000652c:	0a878593          	addi	a1,a5,168
    80006530:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006532:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006534:	6298                	ld	a4,0(a3)
    80006536:	9732                	add	a4,a4,a2
    80006538:	45c1                	li	a1,16
    8000653a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000653c:	6298                	ld	a4,0(a3)
    8000653e:	9732                	add	a4,a4,a2
    80006540:	4585                	li	a1,1
    80006542:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006546:	f8442703          	lw	a4,-124(s0)
    8000654a:	628c                	ld	a1,0(a3)
    8000654c:	962e                	add	a2,a2,a1
    8000654e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd2fe6>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006552:	0712                	slli	a4,a4,0x4
    80006554:	6290                	ld	a2,0(a3)
    80006556:	963a                	add	a2,a2,a4
    80006558:	058a8593          	addi	a1,s5,88
    8000655c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000655e:	6294                	ld	a3,0(a3)
    80006560:	96ba                	add	a3,a3,a4
    80006562:	40000613          	li	a2,1024
    80006566:	c690                	sw	a2,8(a3)
  if(write)
    80006568:	e40d19e3          	bnez	s10,800063ba <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000656c:	00023697          	auipc	a3,0x23
    80006570:	a946b683          	ld	a3,-1388(a3) # 80029000 <disk+0x2000>
    80006574:	96ba                	add	a3,a3,a4
    80006576:	4609                	li	a2,2
    80006578:	00c69623          	sh	a2,12(a3)
    8000657c:	b5b1                	j	800063c8 <virtio_disk_rw+0xd2>

000000008000657e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000657e:	1101                	addi	sp,sp,-32
    80006580:	ec06                	sd	ra,24(sp)
    80006582:	e822                	sd	s0,16(sp)
    80006584:	e426                	sd	s1,8(sp)
    80006586:	e04a                	sd	s2,0(sp)
    80006588:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000658a:	00023517          	auipc	a0,0x23
    8000658e:	b9e50513          	addi	a0,a0,-1122 # 80029128 <disk+0x2128>
    80006592:	ffffa097          	auipc	ra,0xffffa
    80006596:	73a080e7          	jalr	1850(ra) # 80000ccc <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000659a:	10001737          	lui	a4,0x10001
    8000659e:	533c                	lw	a5,96(a4)
    800065a0:	8b8d                	andi	a5,a5,3
    800065a2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800065a4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800065a8:	00023797          	auipc	a5,0x23
    800065ac:	a5878793          	addi	a5,a5,-1448 # 80029000 <disk+0x2000>
    800065b0:	6b94                	ld	a3,16(a5)
    800065b2:	0207d703          	lhu	a4,32(a5)
    800065b6:	0026d783          	lhu	a5,2(a3)
    800065ba:	06f70163          	beq	a4,a5,8000661c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800065be:	00021917          	auipc	s2,0x21
    800065c2:	a4290913          	addi	s2,s2,-1470 # 80027000 <disk>
    800065c6:	00023497          	auipc	s1,0x23
    800065ca:	a3a48493          	addi	s1,s1,-1478 # 80029000 <disk+0x2000>
    __sync_synchronize();
    800065ce:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800065d2:	6898                	ld	a4,16(s1)
    800065d4:	0204d783          	lhu	a5,32(s1)
    800065d8:	8b9d                	andi	a5,a5,7
    800065da:	078e                	slli	a5,a5,0x3
    800065dc:	97ba                	add	a5,a5,a4
    800065de:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800065e0:	20078713          	addi	a4,a5,512
    800065e4:	0712                	slli	a4,a4,0x4
    800065e6:	974a                	add	a4,a4,s2
    800065e8:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800065ec:	e731                	bnez	a4,80006638 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800065ee:	20078793          	addi	a5,a5,512
    800065f2:	0792                	slli	a5,a5,0x4
    800065f4:	97ca                	add	a5,a5,s2
    800065f6:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800065f8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800065fc:	ffffc097          	auipc	ra,0xffffc
    80006600:	0aa080e7          	jalr	170(ra) # 800026a6 <wakeup>

    disk.used_idx += 1;
    80006604:	0204d783          	lhu	a5,32(s1)
    80006608:	2785                	addiw	a5,a5,1
    8000660a:	17c2                	slli	a5,a5,0x30
    8000660c:	93c1                	srli	a5,a5,0x30
    8000660e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006612:	6898                	ld	a4,16(s1)
    80006614:	00275703          	lhu	a4,2(a4)
    80006618:	faf71be3          	bne	a4,a5,800065ce <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000661c:	00023517          	auipc	a0,0x23
    80006620:	b0c50513          	addi	a0,a0,-1268 # 80029128 <disk+0x2128>
    80006624:	ffffa097          	auipc	ra,0xffffa
    80006628:	778080e7          	jalr	1912(ra) # 80000d9c <release>
}
    8000662c:	60e2                	ld	ra,24(sp)
    8000662e:	6442                	ld	s0,16(sp)
    80006630:	64a2                	ld	s1,8(sp)
    80006632:	6902                	ld	s2,0(sp)
    80006634:	6105                	addi	sp,sp,32
    80006636:	8082                	ret
      panic("virtio_disk_intr status");
    80006638:	00002517          	auipc	a0,0x2
    8000663c:	24850513          	addi	a0,a0,584 # 80008880 <syscalls+0x3c8>
    80006640:	ffffa097          	auipc	ra,0xffffa
    80006644:	f0a080e7          	jalr	-246(ra) # 8000054a <panic>

0000000080006648 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    80006648:	1141                	addi	sp,sp,-16
    8000664a:	e422                	sd	s0,8(sp)
    8000664c:	0800                	addi	s0,sp,16
  return -1;
}
    8000664e:	557d                	li	a0,-1
    80006650:	6422                	ld	s0,8(sp)
    80006652:	0141                	addi	sp,sp,16
    80006654:	8082                	ret

0000000080006656 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    80006656:	7179                	addi	sp,sp,-48
    80006658:	f406                	sd	ra,40(sp)
    8000665a:	f022                	sd	s0,32(sp)
    8000665c:	ec26                	sd	s1,24(sp)
    8000665e:	e84a                	sd	s2,16(sp)
    80006660:	e44e                	sd	s3,8(sp)
    80006662:	e052                	sd	s4,0(sp)
    80006664:	1800                	addi	s0,sp,48
    80006666:	892a                	mv	s2,a0
    80006668:	89ae                	mv	s3,a1
    8000666a:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    8000666c:	00024517          	auipc	a0,0x24
    80006670:	99450513          	addi	a0,a0,-1644 # 8002a000 <stats>
    80006674:	ffffa097          	auipc	ra,0xffffa
    80006678:	658080e7          	jalr	1624(ra) # 80000ccc <acquire>

  if(stats.sz == 0) {
    8000667c:	00025797          	auipc	a5,0x25
    80006680:	9a47a783          	lw	a5,-1628(a5) # 8002b020 <stats+0x1020>
    80006684:	cbb5                	beqz	a5,800066f8 <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    80006686:	00025797          	auipc	a5,0x25
    8000668a:	97a78793          	addi	a5,a5,-1670 # 8002b000 <stats+0x1000>
    8000668e:	53d8                	lw	a4,36(a5)
    80006690:	539c                	lw	a5,32(a5)
    80006692:	9f99                	subw	a5,a5,a4
    80006694:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    80006698:	06d05e63          	blez	a3,80006714 <statsread+0xbe>
    if(m > n)
    8000669c:	8a3e                	mv	s4,a5
    8000669e:	00d4d363          	bge	s1,a3,800066a4 <statsread+0x4e>
    800066a2:	8a26                	mv	s4,s1
    800066a4:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    800066a8:	86a6                	mv	a3,s1
    800066aa:	00024617          	auipc	a2,0x24
    800066ae:	97660613          	addi	a2,a2,-1674 # 8002a020 <stats+0x20>
    800066b2:	963a                	add	a2,a2,a4
    800066b4:	85ce                	mv	a1,s3
    800066b6:	854a                	mv	a0,s2
    800066b8:	ffffc097          	auipc	ra,0xffffc
    800066bc:	0c8080e7          	jalr	200(ra) # 80002780 <either_copyout>
    800066c0:	57fd                	li	a5,-1
    800066c2:	00f50a63          	beq	a0,a5,800066d6 <statsread+0x80>
      stats.off += m;
    800066c6:	00025717          	auipc	a4,0x25
    800066ca:	93a70713          	addi	a4,a4,-1734 # 8002b000 <stats+0x1000>
    800066ce:	535c                	lw	a5,36(a4)
    800066d0:	014787bb          	addw	a5,a5,s4
    800066d4:	d35c                	sw	a5,36(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    800066d6:	00024517          	auipc	a0,0x24
    800066da:	92a50513          	addi	a0,a0,-1750 # 8002a000 <stats>
    800066de:	ffffa097          	auipc	ra,0xffffa
    800066e2:	6be080e7          	jalr	1726(ra) # 80000d9c <release>
  return m;
}
    800066e6:	8526                	mv	a0,s1
    800066e8:	70a2                	ld	ra,40(sp)
    800066ea:	7402                	ld	s0,32(sp)
    800066ec:	64e2                	ld	s1,24(sp)
    800066ee:	6942                	ld	s2,16(sp)
    800066f0:	69a2                	ld	s3,8(sp)
    800066f2:	6a02                	ld	s4,0(sp)
    800066f4:	6145                	addi	sp,sp,48
    800066f6:	8082                	ret
    stats.sz = statslock(stats.buf, BUFSZ);
    800066f8:	6585                	lui	a1,0x1
    800066fa:	00024517          	auipc	a0,0x24
    800066fe:	92650513          	addi	a0,a0,-1754 # 8002a020 <stats+0x20>
    80006702:	ffffa097          	auipc	ra,0xffffa
    80006706:	7f4080e7          	jalr	2036(ra) # 80000ef6 <statslock>
    8000670a:	00025797          	auipc	a5,0x25
    8000670e:	90a7ab23          	sw	a0,-1770(a5) # 8002b020 <stats+0x1020>
    80006712:	bf95                	j	80006686 <statsread+0x30>
    stats.sz = 0;
    80006714:	00025797          	auipc	a5,0x25
    80006718:	8ec78793          	addi	a5,a5,-1812 # 8002b000 <stats+0x1000>
    8000671c:	0207a023          	sw	zero,32(a5)
    stats.off = 0;
    80006720:	0207a223          	sw	zero,36(a5)
    m = -1;
    80006724:	54fd                	li	s1,-1
    80006726:	bf45                	j	800066d6 <statsread+0x80>

0000000080006728 <statsinit>:

void
statsinit(void)
{
    80006728:	1141                	addi	sp,sp,-16
    8000672a:	e406                	sd	ra,8(sp)
    8000672c:	e022                	sd	s0,0(sp)
    8000672e:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    80006730:	00002597          	auipc	a1,0x2
    80006734:	16858593          	addi	a1,a1,360 # 80008898 <syscalls+0x3e0>
    80006738:	00024517          	auipc	a0,0x24
    8000673c:	8c850513          	addi	a0,a0,-1848 # 8002a000 <stats>
    80006740:	ffffa097          	auipc	ra,0xffffa
    80006744:	708080e7          	jalr	1800(ra) # 80000e48 <initlock>

  devsw[STATS].read = statsread;
    80006748:	0001f797          	auipc	a5,0x1f
    8000674c:	5f878793          	addi	a5,a5,1528 # 80025d40 <devsw>
    80006750:	00000717          	auipc	a4,0x0
    80006754:	f0670713          	addi	a4,a4,-250 # 80006656 <statsread>
    80006758:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    8000675a:	00000717          	auipc	a4,0x0
    8000675e:	eee70713          	addi	a4,a4,-274 # 80006648 <statswrite>
    80006762:	f798                	sd	a4,40(a5)
}
    80006764:	60a2                	ld	ra,8(sp)
    80006766:	6402                	ld	s0,0(sp)
    80006768:	0141                	addi	sp,sp,16
    8000676a:	8082                	ret

000000008000676c <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    8000676c:	1101                	addi	sp,sp,-32
    8000676e:	ec22                	sd	s0,24(sp)
    80006770:	1000                	addi	s0,sp,32
    80006772:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    80006774:	c299                	beqz	a3,8000677a <sprintint+0xe>
    80006776:	0805c163          	bltz	a1,800067f8 <sprintint+0x8c>
    x = -xx;
  else
    x = xx;
    8000677a:	2581                	sext.w	a1,a1
    8000677c:	4301                	li	t1,0

  i = 0;
    8000677e:	fe040713          	addi	a4,s0,-32
    80006782:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    80006784:	2601                	sext.w	a2,a2
    80006786:	00002697          	auipc	a3,0x2
    8000678a:	11a68693          	addi	a3,a3,282 # 800088a0 <digits>
    8000678e:	88aa                	mv	a7,a0
    80006790:	2505                	addiw	a0,a0,1
    80006792:	02c5f7bb          	remuw	a5,a1,a2
    80006796:	1782                	slli	a5,a5,0x20
    80006798:	9381                	srli	a5,a5,0x20
    8000679a:	97b6                	add	a5,a5,a3
    8000679c:	0007c783          	lbu	a5,0(a5)
    800067a0:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    800067a4:	0005879b          	sext.w	a5,a1
    800067a8:	02c5d5bb          	divuw	a1,a1,a2
    800067ac:	0705                	addi	a4,a4,1
    800067ae:	fec7f0e3          	bgeu	a5,a2,8000678e <sprintint+0x22>

  if(sign)
    800067b2:	00030b63          	beqz	t1,800067c8 <sprintint+0x5c>
    buf[i++] = '-';
    800067b6:	ff040793          	addi	a5,s0,-16
    800067ba:	97aa                	add	a5,a5,a0
    800067bc:	02d00713          	li	a4,45
    800067c0:	fee78823          	sb	a4,-16(a5)
    800067c4:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    800067c8:	02a05c63          	blez	a0,80006800 <sprintint+0x94>
    800067cc:	fe040793          	addi	a5,s0,-32
    800067d0:	00a78733          	add	a4,a5,a0
    800067d4:	87c2                	mv	a5,a6
    800067d6:	0805                	addi	a6,a6,1
    800067d8:	fff5061b          	addiw	a2,a0,-1
    800067dc:	1602                	slli	a2,a2,0x20
    800067de:	9201                	srli	a2,a2,0x20
    800067e0:	9642                	add	a2,a2,a6
  *s = c;
    800067e2:	fff74683          	lbu	a3,-1(a4)
    800067e6:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    800067ea:	177d                	addi	a4,a4,-1
    800067ec:	0785                	addi	a5,a5,1
    800067ee:	fec79ae3          	bne	a5,a2,800067e2 <sprintint+0x76>
    n += sputc(s+n, buf[i]);
  return n;
}
    800067f2:	6462                	ld	s0,24(sp)
    800067f4:	6105                	addi	sp,sp,32
    800067f6:	8082                	ret
    x = -xx;
    800067f8:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    800067fc:	4305                	li	t1,1
    x = -xx;
    800067fe:	b741                	j	8000677e <sprintint+0x12>
  while(--i >= 0)
    80006800:	4501                	li	a0,0
    80006802:	bfc5                	j	800067f2 <sprintint+0x86>

0000000080006804 <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    80006804:	7135                	addi	sp,sp,-160
    80006806:	f486                	sd	ra,104(sp)
    80006808:	f0a2                	sd	s0,96(sp)
    8000680a:	eca6                	sd	s1,88(sp)
    8000680c:	e8ca                	sd	s2,80(sp)
    8000680e:	e4ce                	sd	s3,72(sp)
    80006810:	e0d2                	sd	s4,64(sp)
    80006812:	fc56                	sd	s5,56(sp)
    80006814:	f85a                	sd	s6,48(sp)
    80006816:	f45e                	sd	s7,40(sp)
    80006818:	f062                	sd	s8,32(sp)
    8000681a:	ec66                	sd	s9,24(sp)
    8000681c:	e86a                	sd	s10,16(sp)
    8000681e:	1880                	addi	s0,sp,112
    80006820:	e414                	sd	a3,8(s0)
    80006822:	e818                	sd	a4,16(s0)
    80006824:	ec1c                	sd	a5,24(s0)
    80006826:	03043023          	sd	a6,32(s0)
    8000682a:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    8000682e:	c61d                	beqz	a2,8000685c <snprintf+0x58>
    80006830:	8baa                	mv	s7,a0
    80006832:	89ae                	mv	s3,a1
    80006834:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    80006836:	00840793          	addi	a5,s0,8
    8000683a:	f8f43c23          	sd	a5,-104(s0)
  int off = 0;
    8000683e:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006840:	4901                	li	s2,0
    80006842:	02b05563          	blez	a1,8000686c <snprintf+0x68>
    if(c != '%'){
    80006846:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    8000684a:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    8000684e:	02800d13          	li	s10,40
    switch(c){
    80006852:	07800c93          	li	s9,120
    80006856:	06400c13          	li	s8,100
    8000685a:	a01d                	j	80006880 <snprintf+0x7c>
    panic("null fmt");
    8000685c:	00001517          	auipc	a0,0x1
    80006860:	7cc50513          	addi	a0,a0,1996 # 80008028 <etext+0x28>
    80006864:	ffffa097          	auipc	ra,0xffffa
    80006868:	ce6080e7          	jalr	-794(ra) # 8000054a <panic>
  int off = 0;
    8000686c:	4481                	li	s1,0
    8000686e:	a86d                	j	80006928 <snprintf+0x124>
  *s = c;
    80006870:	009b8733          	add	a4,s7,s1
    80006874:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006878:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    8000687a:	2905                	addiw	s2,s2,1
    8000687c:	0b34d663          	bge	s1,s3,80006928 <snprintf+0x124>
    80006880:	012a07b3          	add	a5,s4,s2
    80006884:	0007c783          	lbu	a5,0(a5)
    80006888:	0007871b          	sext.w	a4,a5
    8000688c:	cfd1                	beqz	a5,80006928 <snprintf+0x124>
    if(c != '%'){
    8000688e:	ff5711e3          	bne	a4,s5,80006870 <snprintf+0x6c>
    c = fmt[++i] & 0xff;
    80006892:	2905                	addiw	s2,s2,1
    80006894:	012a07b3          	add	a5,s4,s2
    80006898:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    8000689c:	c7d1                	beqz	a5,80006928 <snprintf+0x124>
    switch(c){
    8000689e:	05678c63          	beq	a5,s6,800068f6 <snprintf+0xf2>
    800068a2:	02fb6763          	bltu	s6,a5,800068d0 <snprintf+0xcc>
    800068a6:	0b578663          	beq	a5,s5,80006952 <snprintf+0x14e>
    800068aa:	0b879a63          	bne	a5,s8,8000695e <snprintf+0x15a>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    800068ae:	f9843783          	ld	a5,-104(s0)
    800068b2:	00878713          	addi	a4,a5,8
    800068b6:	f8e43c23          	sd	a4,-104(s0)
    800068ba:	4685                	li	a3,1
    800068bc:	4629                	li	a2,10
    800068be:	438c                	lw	a1,0(a5)
    800068c0:	009b8533          	add	a0,s7,s1
    800068c4:	00000097          	auipc	ra,0x0
    800068c8:	ea8080e7          	jalr	-344(ra) # 8000676c <sprintint>
    800068cc:	9ca9                	addw	s1,s1,a0
      break;
    800068ce:	b775                	j	8000687a <snprintf+0x76>
    switch(c){
    800068d0:	09979763          	bne	a5,s9,8000695e <snprintf+0x15a>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    800068d4:	f9843783          	ld	a5,-104(s0)
    800068d8:	00878713          	addi	a4,a5,8
    800068dc:	f8e43c23          	sd	a4,-104(s0)
    800068e0:	4685                	li	a3,1
    800068e2:	4641                	li	a2,16
    800068e4:	438c                	lw	a1,0(a5)
    800068e6:	009b8533          	add	a0,s7,s1
    800068ea:	00000097          	auipc	ra,0x0
    800068ee:	e82080e7          	jalr	-382(ra) # 8000676c <sprintint>
    800068f2:	9ca9                	addw	s1,s1,a0
      break;
    800068f4:	b759                	j	8000687a <snprintf+0x76>
      if((s = va_arg(ap, char*)) == 0)
    800068f6:	f9843783          	ld	a5,-104(s0)
    800068fa:	00878713          	addi	a4,a5,8
    800068fe:	f8e43c23          	sd	a4,-104(s0)
    80006902:	639c                	ld	a5,0(a5)
    80006904:	c3a9                	beqz	a5,80006946 <snprintf+0x142>
      for(; *s && off < sz; s++)
    80006906:	0007c703          	lbu	a4,0(a5)
    8000690a:	db25                	beqz	a4,8000687a <snprintf+0x76>
    8000690c:	0134de63          	bge	s1,s3,80006928 <snprintf+0x124>
    80006910:	009b86b3          	add	a3,s7,s1
  *s = c;
    80006914:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    80006918:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    8000691a:	0785                	addi	a5,a5,1
    8000691c:	0007c703          	lbu	a4,0(a5)
    80006920:	df29                	beqz	a4,8000687a <snprintf+0x76>
    80006922:	0685                	addi	a3,a3,1
    80006924:	fe9998e3          	bne	s3,s1,80006914 <snprintf+0x110>
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    80006928:	8526                	mv	a0,s1
    8000692a:	70a6                	ld	ra,104(sp)
    8000692c:	7406                	ld	s0,96(sp)
    8000692e:	64e6                	ld	s1,88(sp)
    80006930:	6946                	ld	s2,80(sp)
    80006932:	69a6                	ld	s3,72(sp)
    80006934:	6a06                	ld	s4,64(sp)
    80006936:	7ae2                	ld	s5,56(sp)
    80006938:	7b42                	ld	s6,48(sp)
    8000693a:	7ba2                	ld	s7,40(sp)
    8000693c:	7c02                	ld	s8,32(sp)
    8000693e:	6ce2                	ld	s9,24(sp)
    80006940:	6d42                	ld	s10,16(sp)
    80006942:	610d                	addi	sp,sp,160
    80006944:	8082                	ret
        s = "(null)";
    80006946:	00001797          	auipc	a5,0x1
    8000694a:	6da78793          	addi	a5,a5,1754 # 80008020 <etext+0x20>
      for(; *s && off < sz; s++)
    8000694e:	876a                	mv	a4,s10
    80006950:	bf75                	j	8000690c <snprintf+0x108>
  *s = c;
    80006952:	009b87b3          	add	a5,s7,s1
    80006956:	01578023          	sb	s5,0(a5)
      off += sputc(buf+off, '%');
    8000695a:	2485                	addiw	s1,s1,1
      break;
    8000695c:	bf39                	j	8000687a <snprintf+0x76>
  *s = c;
    8000695e:	009b8733          	add	a4,s7,s1
    80006962:	01570023          	sb	s5,0(a4)
      off += sputc(buf+off, c);
    80006966:	0014871b          	addiw	a4,s1,1
  *s = c;
    8000696a:	975e                	add	a4,a4,s7
    8000696c:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006970:	2489                	addiw	s1,s1,2
      break;
    80006972:	b721                	j	8000687a <snprintf+0x76>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
