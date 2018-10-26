
// PRESENT in ARM64 assembly
// 208 bytes

    .arch armv8-a
    .text
    .global present

    #define k  x0
    #define x  x1
    #define r  w2
    #define p  x3
    #define t  x4
    #define k0 x5
    #define k1 x6
    #define i  x7
    #define j  x8
    #define s  x9
    
present:
    str     lr, [sp, -16]!
    
    // k0=k[0];k1=k[1];t=x[0];
    ldp     k0, k1, [k]
    ldr     t, [x]
    
    mov     i, 0
    adr     s, sbox
L0:
    // p=t^k1;
    eor     p, t, k1
    
    // F(j,8)((B*)&p)[j]=S(((B*)&p)[j]);
    mov     j, 8
L1:
    bl      S
    subs    j, j, 1
    bne     L1

    // t=0;r=0x0030002000100000;
    mov     t, 0
    ldr     r, =0x30201000
    // F(j,64)
    mov     j, 0
L2:
    // t|=((p>>j)&1)<<(r&255),
    lsr     x10, p, j         // x10 = (p >> j) & 1
    and     x10, x10, 1       // 
    lsl     x10, x10, x2      // x10 << r
    orr     t, t, x10         // t |= x10
    
    // r=R(r+1,16);
    add     r, r, 1           // r = R(r+1, 8)
    ror     r, r, 8
    
    add     j, j, 1           // j++
    cmp     j, 64             // j < 64
    bne     L2

    // k0^=(i+i)+2;
    add     x10, i, i         // x10 = i + i
    add     x10, x10, 2       // x10 += 2
    eor     k0, k0, x10
    
    // p =(k1<<61)|(k0>>3);
    lsr     p, k0, 3
    orr     p, p, k1, lsl 61
    
    // k0=(k0<<61)|(k1>>3);
    lsr     k1, k1, 3
    orr     k0, k1, k0, lsl 61
    
    // p=R(p,56);
    ror     p, p, 56
    bl      S
    mov     k1, p
 
    // i++
    add     i, i, 1
    // i < 31
    cmp     i, 31
    bne     L0
    
    // x[0] = t ^= k1
    eor     p, t, k1    
    str     p, [x]
    
    ldr     lr, [sp], 16
    ret 

S:
    ubfx    x10, p, 0, 4              // x10 = (p & 0x0F)
    ubfx    x11, p, 4, 4              // x11 = (p & 0xF0) >> 4
    
    ldrb    w10, [s, w10, uxtw 0]     // w10 = s[w10]
    ldrb    w11, [s, w11, uxtw 0]     // w11 = s[w11]
    
    bfi     p, x10, 0, 4              // p[0] = ((x11 << 4) | x10)
    bfi     p, x11, 4, 4
    
    ror     p, p, 8                   // p = R(p, 8)
    ret
sbox:
    .byte 0xc, 0x5, 0x6, 0xb, 0x9, 0x0, 0xa, 0xd
    .byte 0x3, 0xe, 0xf, 0x8, 0x4, 0x7, 0x1, 0x2

