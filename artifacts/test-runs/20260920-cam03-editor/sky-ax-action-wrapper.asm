1006e6cbc:	mov	x0, x24
1006e6cc0:	mov	x1, x23
1006e6cc4:	bl	0x100fe94c8
1006e6cc8:	mov	x23, x0
1006e6ccc:	mov	x0, x20
1006e6cd0:	mov	x1, x23
1006e6cd4:	bl	0x100fec558 ; symbol stub for: _AXUIElementPerformAction
1006e6cd8:	mov	x20, x0
1006e6cdc:	mov	x0, x23
1006e6ce0:	bl	0x100fed7d0 ; symbol stub for: _objc_release
1006e6ce4:	cbz	w20, 0x1006e6d3c
1006e6ce8:	adrp	x8, 3259 ; 0x1013a1000
1006e6cec:	add	x8, x8, #0x1c8
1006e6cf0:	ldr	w9, [x8]
1006e6cf4:	cmp	w9, w20
1006e6cf8:	b.eq	0x1006e6d3c
1006e6cfc:	ldr	w8, [x8, #0x4]
1006e6d00:	cmp	w8, w20
1006e6d04:	b.eq	0x1006e6d3c
1006e6d08:	mov	w20, w20
1006e6d0c:	bl	0x1006d7b14
1006e6d10:	mov	x1, x0
1006e6d14:	adrp	x0, 3068 ; 0x1012e2000
1006e6d18:	add	x0, x0, #0x2f0
1006e6d1c:	mov	x2, #0x0
1006e6d20:	mov	w3, #0x0
1006e6d24:	bl	0x100fedb60 ; symbol stub for: _swift_allocError
1006e6d28:	mov	x19, x0
1006e6d2c:	stp	x20, xzr, [x1]
1006e6d30:	strb	wzr, [x1, #0x10]
1006e6d34:	mov	x21, x0
1006e6d38:	bl	0x100fee2d4 ; symbol stub for: _swift_willThrow
1006e6d3c:	mov	x0, x22
1006e6d40:	bl	0x100fedfec ; symbol stub for: _swift_release
1006e6d44:	b	0x1006e6dcc
1006e6d48:	adrp	x1, 3261 ; 0x1013a3000
1006e6d4c:	add	x1, x1, #0x500
1006e6d50:	adrp	x2, 3181 ; 0x101353000
1006e6d54:	add	x2, x2, #0xc98 ; Objc class ref: _OBJC_CLASS_$_OS_dispatch_queue
1006e6d58:	mov	x0, #0x0
1006e6d5c:	bl	0x10002eac8
1006e6d60:	mov	x20, x0
1006e6d64:	bl	0x100fea5d8
1006e6d68:	mov	x20, x0
1006e6d6c:	mov	x23, sp
1006e6d70:	mov	w9, #0x20
1006e6d74:	adrp	x16, 3009 ; 0x1012a7000
1006e6d78:	ldr	x16, [x16, #0xa78] ; literal pool symbol address: ___chkstk_darwin
1006e6d7c:	blr	x16
1006e6d80:	mov	x8, sp
1006e6d84:	sub	x1, x8, #0x20
1006e6d88:	mov	sp, x1
1006e6d8c:	adrp	x9, 2 ; 0x1006e8000
1006e6d90:	add	x9, x9, #0xaac
1006e6d94:	stp	x9, x22, [x8, #-0x10]
1006e6d98:	adrp	x8, 3014 ; 0x1012ac000
1006e6d9c:	ldr	x8, [x8, #0x688]
1006e6da0:	adrp	x0, 3 ; 0x1006e9000
1006e6da4:	add	x0, x0, #0x1a8
1006e6da8:	add	x2, x8, #0x8
1006e6dac:	mov	x21, x19
1006e6db0:	bl	0x100fea5f0
1006e6db4:	mov	x19, x21
1006e6db8:	mov	x0, x20
1006e6dbc:	bl	0x100fed7d0 ; symbol stub for: _objc_release
1006e6dc0:	mov	x0, x22
1006e6dc4:	bl	0x100fedfec ; symbol stub for: _swift_release
1006e6dc8:	mov	sp, x23
1006e6dcc:	mov	x21, x19
1006e6dd0:	sub	sp, x29, #0x40
1006e6dd4:	ldp	x29, x30, [sp, #0x40]
1006e6dd8:	ldp	x20, x19, [sp, #0x30]
1006e6ddc:	ldp	x23, x22, [sp, #0x20]
1006e6de0:	ldp	x25, x24, [sp, #0x10]
1006e6de4:	ldr	x26, [sp], #0x50
1006e6de8:	ret
1006e6dec:	adrp	x0, 3258 ; 0x1013a0000
1006e6df0:	add	x0, x0, #0x778
1006e6df4:	adrp	x1, 1 ; 0x1006e7000
1006e6df8:	add	x1, x1, #0xc98
1006e6dfc:	bl	0x100fedfc8 ; symbol stub for: _swift_once
1006e6e00:	b	0x1006e6b98
1006e6e04:	str	x22, [sp, #-0x30]!
1006e6e08:	stp	x20, x19, [sp, #0x10]
1006e6e0c:	stp	x29, x30, [sp, #0x20]
1006e6e10:	add	x29, sp, #0x20
1006e6e14:	mov	x19, x21
1006e6e18:	mov	x20, x0
1006e6e1c:	mov	x0, x1
1006e6e20:	mov	x1, x2
1006e6e24:	bl	0x100fe94c8
1006e6e28:	mov	x22, x0
1006e6e2c:	mov	x0, x20
1006e6e30:	mov	x1, x22
1006e6e34:	bl	0x100fec558 ; symbol stub for: _AXUIElementPerformAction
1006e6e38:	mov	x20, x0
1006e6e3c:	mov	x0, x22
1006e6e40:	bl	0x100fed7d0 ; symbol stub for: _objc_release
1006e6e44:	cbz	w20, 0x1006e6e94
1006e6e48:	adrp	x8, 3259 ; 0x1013a1000
1006e6e4c:	add	x8, x8, #0x1f8
1006e6e50:	ldp	w9, w8, [x8]
1006e6e54:	cmp	w9, w20
1006e6e58:	ccmp	w8, w20, #0x4, ne
1006e6e5c:	b.eq	0x1006e6e94
1006e6e60:	mov	w20, w20
1006e6e64:	bl	0x1006d7b14
1006e6e68:	mov	x1, x0
1006e6e6c:	adrp	x0, 3068 ; 0x1012e2000
1006e6e70:	add	x0, x0, #0x2f0
1006e6e74:	mov	x2, #0x0
1006e6e78:	mov	w3, #0x0
1006e6e7c:	bl	0x100fedb60 ; symbol stub for: _swift_allocError
1006e6e80:	mov	x19, x0
1006e6e84:	stp	x20, xzr, [x1]
1006e6e88:	strb	wzr, [x1, #0x10]
1006e6e8c:	mov	x21, x0
1006e6e90:	bl	0x100fee2d4 ; symbol stub for: _swift_willThrow
1006e6e94:	mov	x21, x19
1006e6e98:	ldp	x29, x30, [sp, #0x20]
1006e6e9c:	ldp	x20, x19, [sp, #0x10]
1006e6ea0:	ldr	x22, [sp], #0x30
1006e6ea4:	ret
