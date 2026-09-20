100729f30:	sub	sp, sp, #0xc0
100729f34:	str	d14, [sp, #0x30]
100729f38:	stp	d13, d12, [sp, #0x40]
100729f3c:	stp	d11, d10, [sp, #0x50]
100729f40:	stp	d9, d8, [sp, #0x60]
100729f44:	stp	x27, x26, [sp, #0x70]
100729f48:	stp	x25, x24, [sp, #0x80]
100729f4c:	stp	x23, x22, [sp, #0x90]
100729f50:	stp	x20, x19, [sp, #0xa0]
100729f54:	stp	x29, x30, [sp, #0xb0]
100729f58:	add	x29, sp, #0xb0
100729f5c:	mov	x19, x21
100729f60:	mov	x22, x4
100729f64:	mov	x24, x3
100729f68:	mov	x25, x2
100729f6c:	mov	x26, x1
100729f70:	mov	x23, x0
100729f74:	fmov	d8, d1
100729f78:	fmov	d9, d0
100729f7c:	mov	w27, #0x1
100729f80:	mov	w0, #0x1
100729f84:	bl	0x100248438
100729f88:	cbz	x0, 0x10072a014
100729f8c:	mov	w8, #0x7fffffff
100729f90:	cmp	x26, x8
100729f94:	b.gt	0x10072a1d4
100729f98:	mov	x8, #-0x80000000
100729f9c:	cmp	x23, x8
100729fa0:	b.lt	0x10072a1d8
100729fa4:	cmp	x26, x8
100729fa8:	b.lt	0x10072a1d8
100729fac:	mov	w8, #0x7fffffff
100729fb0:	cmp	x23, x8
100729fb4:	b.gt	0x10072a1dc
100729fb8:	mov	x20, x0
100729fbc:	mov	w1, #0x0
100729fc0:	mov	w2, #0x1
100729fc4:	mov	x3, x26
100729fc8:	mov	x4, x23
100729fcc:	mov	w5, #0x0
100729fd0:	bl	0x100247f38
100729fd4:	cbz	x0, 0x10072a044
100729fd8:	mov	x23, x0
100729fdc:	fmov	d0, d9
100729fe0:	fmov	d1, d8
100729fe4:	bl	0x1002482f0
100729fe8:	tbnz	x25, #0x20, 0x10072a164
100729fec:	adrp	x8, 3191 ; 0x1013a0000
100729ff0:	ldr	x8, [x8, #0x830]
100729ff4:	cmn	x8, #0x1
100729ff8:	b.ne	0x10072a1e0
100729ffc:	adrp	x8, 3532 ; 0x1014f5000
10072a000:	ldrb	w8, [x8, #0x734]
10072a004:	cmp	w8, #0x1
10072a008:	b.ne	0x10072a07c
10072a00c:	mov	w25, w25
10072a010:	b	0x10072a094
10072a014:	bl	0x10072bdc8
10072a018:	mov	x1, x0
10072a01c:	adrp	x0, 2998 ; 0x1012e0000
10072a020:	add	x0, x0, #0xed8
10072a024:	mov	x2, #0x0
10072a028:	mov	w3, #0x0
10072a02c:	bl	0x100fedb60 ; symbol stub for: _swift_allocError
10072a030:	mov	x19, x0
10072a034:	strb	w27, [x1]
10072a038:	mov	x21, x0
10072a03c:	bl	0x100fee2d4 ; symbol stub for: _swift_willThrow
10072a040:	b	0x10072a078
10072a044:	bl	0x10071b614
10072a048:	mov	x1, x0
10072a04c:	adrp	x0, 2998 ; 0x1012e0000
10072a050:	add	x0, x0, #0x6e0
10072a054:	mov	x2, #0x0
10072a058:	mov	w3, #0x0
10072a05c:	bl	0x100fedb60 ; symbol stub for: _swift_allocError
10072a060:	mov	x19, x0
10072a064:	strb	wzr, [x1]
10072a068:	mov	x21, x0
10072a06c:	bl	0x100fee2d4 ; symbol stub for: _swift_willThrow
10072a070:	mov	x0, x20
10072a074:	bl	0x100fed7d0 ; symbol stub for: _objc_release
10072a078:	b	0x10072a1a0
10072a07c:	adrp	x8, 3531 ; 0x1014f5000
10072a080:	ldr	w1, [x8, #0x730]
10072a084:	mov	w25, w25
10072a088:	mov	x0, x23
10072a08c:	mov	x2, x25
10072a090:	bl	0x100248280
10072a094:	mov	x0, x23
10072a098:	mov	w1, #0x5b
10072a09c:	mov	x2, x25
10072a0a0:	bl	0x100248280
10072a0a4:	mov	x0, x23
10072a0a8:	mov	w1, #0x5c
10072a0ac:	mov	x2, x25
10072a0b0:	bl	0x100248280
10072a0b4:	ldrb	w8, [x24, #0x20]
10072a0b8:	tbnz	w8, #0x0, 0x10072a164
10072a0bc:	ldp	d9, d8, [x24, #0x10]
10072a0c0:	ldp	d11, d10, [x24]
10072a0c4:	mov	x0, x23
10072a0c8:	bl	0x100248034
10072a0cc:	fmov	d12, d0
10072a0d0:	fmov	d13, d1
10072a0d4:	fmov	d0, d11
10072a0d8:	fmov	d1, d10
10072a0dc:	fmov	d2, d9
10072a0e0:	fmov	d3, d8
10072a0e4:	bl	0x100fec9f0 ; symbol stub for: _CGRectGetMinX
10072a0e8:	fneg	d14, d0
10072a0ec:	fmov	d0, d11
10072a0f0:	fmov	d1, d10
10072a0f4:	fmov	d2, d9
10072a0f8:	fmov	d3, d8
10072a0fc:	bl	0x100fec9fc ; symbol stub for: _CGRectGetMinY
10072a100:	fneg	d1, d0
10072a104:	mov	x8, sp
10072a108:	fmov	d0, d14
10072a10c:	bl	0x100fec768 ; symbol stub for: _CGAffineTransformMakeTranslation
10072a110:	ldp	q0, q1, [sp]
10072a114:	ldr	q2, [sp, #0x20]
10072a118:	stp	q0, q1, [sp]
10072a11c:	str	q2, [sp, #0x20]
10072a120:	mov	x0, sp
10072a124:	fmov	d0, d12
10072a128:	fmov	d1, d13
10072a12c:	bl	0x100fec978 ; symbol stub for: _CGPointApplyAffineTransform
10072a130:	tbz	w22, #0x0, 0x10072a15c
10072a134:	fmov	d12, d0
10072a138:	fmov	d0, d11
10072a13c:	fmov	d11, d1
10072a140:	fmov	d1, d10
10072a144:	fmov	d2, d9
10072a148:	fmov	d3, d8
10072a14c:	bl	0x100fec9b4 ; symbol stub for: _CGRectGetHeight
10072a150:	fmov	d2, d0
10072a154:	fmov	d0, d12
10072a158:	fsub	d1, d2, d11
10072a15c:	mov	x0, x23
10072a160:	bl	0x100259ac0
10072a164:	adrp	x0, 3194 ; 0x1013a4000
10072a168:	add	x0, x0, #0x888
10072a16c:	adrp	x1, 2307 ; 0x10102d000
10072a170:	add	x1, x1, #0x750
10072a174:	bl	0x100003250
10072a178:	mov	w1, #0x28
10072a17c:	mov	w2, #0x7
10072a180:	bl	0x100fedb6c ; symbol stub for: _swift_allocObject
10072a184:	mov	x22, x0
10072a188:	adrp	x8, 2250 ; 0x100ff4000
10072a18c:	ldr	q0, [x8, #0x710]
10072a190:	str	q0, [x0, #0x10]
10072a194:	str	x23, [x0, #0x20]
10072a198:	mov	x0, x20
10072a19c:	bl	0x100fed7d0 ; symbol stub for: _objc_release
10072a1a0:	mov	x0, x22
10072a1a4:	mov	x21, x19
10072a1a8:	ldp	x29, x30, [sp, #0xb0]
10072a1ac:	ldp	x20, x19, [sp, #0xa0]
10072a1b0:	ldp	x23, x22, [sp, #0x90]
10072a1b4:	ldp	x25, x24, [sp, #0x80]
10072a1b8:	ldp	x27, x26, [sp, #0x70]
10072a1bc:	ldp	d9, d8, [sp, #0x60]
10072a1c0:	ldp	d11, d10, [sp, #0x50]
10072a1c4:	ldp	d13, d12, [sp, #0x40]
10072a1c8:	ldr	d14, [sp, #0x30]
10072a1cc:	add	sp, sp, #0xc0
10072a1d0:	ret
10072a1d4:	brk	#0x1
10072a1d8:	brk	#0x1
10072a1dc:	brk	#0x1
10072a1e0:	adrp	x0, 3190 ; 0x1013a0000
10072a1e4:	add	x0, x0, #0x830
10072a1e8:	adrp	x1, -15 ; 0x10071b000
10072a1ec:	add	x1, x1, #0x654
10072a1f0:	bl	0x100fedfc8 ; symbol stub for: _swift_once
10072a1f4:	b	0x100729ffc
10071b654:	adrp	x8, 3546 ; 0x1014f5000
10071b658:	add	x8, x8, #0x730
10071b65c:	mov	w9, #0x33
10071b660:	str	w9, [x8]
10071b664:	strb	wzr, [x8, #0x4]
10071b668:	ret
