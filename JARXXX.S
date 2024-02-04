CJarID		equ	'CJar'		; $434A6172
JAR		equ	$5A0
JAR_VER		equ	$1
t14		equ	$b8
CJ_xbios	equ	'CJ'
CJ_OK		equ	'ar'
_longframe	equ	$59e

fdst:   movea.l 4(a7), a6
        movea.l 24(a6), a3
        adda.l  28(a6), a3	; find end of memory usage
        pea	intro(pc)
        move	#9, -(sp)	; Cconws opening message
        trap	#1
        addq	#6, sp
        move	#$27, -(sp)
        pea	search(pc)
        move	#$4E, -(sp)
        trap	#1		; Fsfirst, search AUTO folder
        tst	d0
        beq.b	fsok
        lea	search+6(pc), a0
        move.l	a0, 2(sp)	; redo it, searching current folder
        trap	#1
        tst	d0
        bne 	fserr
fsok:   addq	#8, sp
        move	#$2f, -(sp)
        trap	#1		; Fgetdta
        addq	#2, sp
        move.l	d0, a0
        lea	33(a0), a0
        moveq	#2, d1
        clr	d7
        clr	d2
getnum: move.b	(a0)+, d2
        beq.b	getnx
        cmpi.b	#'.', d2
        beq.b	getnx
        cmpi.b	#'0', d2
        blt	numerr
        cmpi.b	#'9', d2
        bgt	numerr
        mulu	#10, d7
        sub 	#'0', d2
        add	d2, d7
        dbra	d1, getnum
getnx:	cmpi	#8190, d7
	bhi 	numerr
	move	d7, d2		; number of user entries (.b) into d2
	cmpi	#$100, d2
	blo.b	gn1
	clr.b	d2
gn1:	move.b	d2, my_cook+1	; store for later use
	addq	#1, d7		; add one for my cookie
	pea	0.w
	move	#32, -(sp)
	trap	#1		; Super(0L)
        addq	#6, sp
        moveq	#0, d6
	move.l	JAR.w, d0
	beq.b	nojar
	move.l	d0, a0
jcnt:	tst.l	(a0)
	beq.b	jcend
	addq	#1, d6		; get index of current count in jar
	addq	#8, a0
	bra.b	jcnt
jcend:	move.w	6(a0), d0	; get current jar's count
	sub	d6, d0		; current count - number of entries used
	sub	d7, d0		; minus extra specified by user
nojar:	add	d6, d7		; number to allocate
	cmpi	#8191, d7
	bhi.b	numerr
	move	d7, d2		; total number of entries (.b) into d2
	cmpi	#$100, d2
	blo.b	gn2
	clr.b	d2
gn2:	move.b	d2, my_cook+2
	tst	d0
	bgt.b	nomore		; already enough?
	moveq	#0, d0
	move	d7, d0
	add.l	d0, d0
	add.l	d0, d0
	add.l	d0, d0		; * 8
	move.l	a3, a1		; new jar goes here
	move.l	a3, d1
	adda.l	d0, a3		; add onto end
	move.l	JAR.w, d0
	beq.b	nojar2
	move.l	d0, a0
	bra.b	cpyjar2
cpyjar:	move.l	(a0)+, (a1)+	; copy the old jar
	move.l	(a0)+, (a1)+
cpyjar2:dbra	d6, cpyjar
	bra.b	cj3
nojar2:	bsr	unjar		; new jar, so install reset vector
cj3:	clr.l	(a1)+		; size cookie
	clr.w	(a1)+
	move	d7, (a1)	; size of jar
	move.l	d1, JAR.w	; set new jar
nomore:	move.l	t14.w, old_t14	; install trap 14 handler
	move.l	#my_t14, t14.w
	lea	my_cook(pc), a0
	move.l	#CJarID, d1
	bsr.b	new_cookie	; assume this always works
	suba.l  (a6), a3
        clr	-(sp)
        move.l  a3, -(sp)
        move.w  #49, -(sp)	; Ptermres
        trap    #1

numerr:	pea	bad_number(pc)
	bra.b	error
fserr:	pea	not_found(pc)
error:	move	#9, -(sp)
	trap	#1		; Cconws
	move	#1, (sp)
	trap	#1		; Cconin
	clr	(sp)
	trap	#1		; Pterm0

new_cookie:		; takes d1 with cookie, (a0) with value
	bsr.b	find_cookie
	bne.b	already
nc1:	tst.l	(a1)
	beq.b	nc_end
	addq	#8, a1
	addq	#1, d2
	bra.b	nc1
nc_end: cmp	6(a1), d2
	bcc.b	nc4
	clr.l	8(a1)			; move size cookie
	move.l	4(a1), 12(a1)		; copy size
	move.l	d1, (a1)
already:clr.l	4(a1)
	move.l	a0, d1
	beq.b	nc3
	move.l	(a0), 4(a1)
nc3:	bsr.b	set_mycookie
	move.l	#CJ_OK, d0
	rts
nc4:	moveq	#-1, d0
	rts

find_cookie:		; d1 has cookie to look for
	move.l	JAR.w, a1
	clr	d0
	clr	d2
fc1:	tst.l	(a1)
	beq.b	notfnd
	cmp.l	(a1), d1
	beq.b	found
	addq	#1, d2
	addq	#8, a1
	bra.b	fc1
found:	move.l	#CJ_OK, d0
notfnd:	rts

set_mycookie:		; set the number of cookies in use
	move.l	d0, -(sp)
	move.l	#CJarID, d1
	bsr.b	find_cookie
	move.l	a1, a0
sm2:	tst.l	(a1)
	beq.b	sm1
	addq	#8, a1
	addq	#1, d2
	bra.b	sm2
sm1:	move.b	d2, 7(a0)
	cmpi	#$100, d2
	blo.b	sm3
	clr.b	7(a0)
sm3:	move.l	(sp)+, d0
	rts

get_cookie:			; d1 is cookie, (a0) points to value
	move.l	a0, -(sp)
	move.l	d1, -(sp)
	bsr.b	set_mycookie
	move.l	(sp)+, d1
	move.l	(sp)+, a0
	bsr.b	find_cookie
	beq.b	gc1
	move.l	a0, d1
	beq.b	gc1
	move.l	4(a1), (a0)
gc1:	rts

jarx:	move	2(a0), d0
	bne.b	jx1
	move.l	4(a0), d1
	move.l	8(a0), a0
	bsr.b	get_cookie
	rte
jx1:	subq	#1, d0
	bne.b	mt2
	move.l	4(a0), d1
	move.l	8(a0), a0
	bsr 	new_cookie
	rte
	
	.ascii	'XBRA'
	dc.l	CJarID
old_t14:ds.l	1
my_t14: move.l  usp, a0         ; set a0 to the usp
        btst    #$5, (sp)       ; is caller in supervisor mode?
        beq.b   mt1             ; no, use the usp for a0
        lea     6(sp), a0       ; yes, set a0 to sp+6
        tst     _longframe.w    ; is it a 68000?
        beq.b   mt1
        addq    #2, a0          ; no, go another 2
mt1:	cmp	#CJ_xbios, (a0)
	beq.b	jarx
mt2:	move.l	old_t14(pc), a0
	jmp	(a0)

    RESMAGIC   equ $31415926
    _resvalid  equ $426
    _resvector equ $42a
    _p_cookies equ $5a0

    unjar:       move.l   _resvalid.w,valsave     ; save old valid
                 move.l   _resvector.w,vecsave    ; ... and vector
                 move.l   #reshand,_resvector.w   ; install new vector
                 move.l   #RESMAGIC,_resvalid.w   ; ... and validate it
                 rts

    reshand:
                 clr.l    JAR.w         ; clobber cookie jar pointer
                 move.l   vecsave(pc),_resvector.w ; restore old vector
                 move.l   valsave(pc),_resvalid.w ; restore old valid
                 jmp      (a6)                  ; return to ROMs

vecsave:     ds.l     1
valsave:     ds.l     1
	
my_cook:	dc.b	JAR_VER, 0, 0, 0
intro:		dc.b	$d, $a, "      JARxxx by Dan Wilga"
		dc.b	$d, $a, "Copyright 1992, Gribnif Software", $d, $a, $a, 0
search:		dc.b	"\AUTO\JAR*.PRG", 0
not_found:	dc.b	7, "JARxxx was not found. Please make", $d, $a
		dc.b	"sure the file's name is correct.", $d, $a, 0
bad_number:	dc.b	7, "Bad number of jar entries requested", $d, $a, 0
