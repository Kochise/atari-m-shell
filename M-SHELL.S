; //////////////////////////////////////////
; ///                                    ///
; ///  >>> STARS MOVING SHELL V3.00 <<<  ///
; ///                 BY                 ///
; ///    KOCHISE OF STALLION SOFTWARE    ///
; ///                                    ///
; //////////////////////////////////////////
;

; /// INITIALISATION DE LA MEMOIRE ///

INIT_PRG_MEM	movea.l	4(SP),A6		; Adresse de la BASEPAGE
	move.l	$C(A6),D0		; Taille du programme
	add.l	$14(A6),D0		; Additionne la taille du SEGMENT DATA … D0
	add.l	$1C(A6),D0		; Additionne la taille du SEGMENT BSS … D0
	addi.l	#$100,D0		; Additionne la taille de la BASEPAGE … D0
	addi.l	#$400,D0		; Additionne la taille de la future PILE (Ici, 256 positions longues (1024 OCTETS))
	move.l	D0,D1		; Copie D0 dans D1 (Taille … r‚server)
	add.l	A6,D1		; Additionne l'adresse du d‚but du programme avec D1 (La taille … r‚server)
	andi.l	#-2,D1		; Rend D1 pair (Au cas o— il ne l'‚tait pas)
	move.l	SP,OLD_STACK
	movea.l	D1,SP		; Installe l'adresse de fin du programme+place nouvelle PILE dans la PILE
	move.l	D0,-(SP)		; EmPILE la taille … reserver	\
	move.l	A6,-(SP)		; EmPILE l'adresse du programme |-> Rend le reste de la m‚moire au systŠme
	clr.w	-(SP)		; R‚serv‚                       |
	move.w	#$4A,-(SP)		; - M_SHRINK -                  |
	trap	#1		; *** GEMDOS ***                /
	lea	12(SP),SP
	tst	D0		; Si D0<>0, problŠme grave
	bne	SYS_ERROR

; /// GESTION DU PROGRAMME ///

MAIN_CONTROL	bsr	STOP_MOUSE
	bsr	SAVE_VIDEO
	move.b	#1,FROM_PROGS
	bsr	INSTALL_VIDEO
	bsr	FIELD_LOAD
	bsr	STAR_FCREAT
	move.b	#1,ACTUAL_FIELD
	move.b	#1,CHANGE_ASKED
	move.b	#1,FIRST_PASS
MAIN_LOOP	bsr	STAR_MORPH
	bsr	KEYB_WAIT
	move.b	ESC_ASKED,D2
	tst.b	D2
	bne	ESCAPING
	move.b	RUN_ASKED,D2
	tst.b	D2
	bne	RUNNING

	bra	MAIN_LOOP

ESCAPING	move.b	#0,ESC_ASKED
	bsr	FREE_MOUSE
	bsr	MEM_FREE
	bsr	RESTORE_VIDEO
	bra	SYS_ERROR

RUNNING	move.b	#0,RUN_ASKED
	
	bsr	TEST_PROG_OK
	tst.b	D6
	bne	END_RUN
	
	bsr	FREE_MOUSE
	bsr	RUN_PROGS
	
	bsr	STOP_MOUSE
	move.b	#1,FROM_PROGS
	bsr	INSTALL_VIDEO
	bsr	FIELD_LOAD
	bsr	STAR_FCREAT
	move.b	#1,CHANGE_ASKED
	move.b	#1,FIRST_PASS
		
END_RUN	bra	MAIN_LOOP

TEST_PROG_OK	lea	FIELD_BNK,A6
	clr.l	D0
	move.b	ACTUAL_FIELD,D0
	subq.b	#1,D0
	mulu.l	#4,D0
	add.l	D0,A6
	move.l	(A6),A6
	
	move.w	(A6)+,D0
	cmpi.w	#1,D0
	bne	ESCAPING
	
	move.w	(A6)+,D0
	mulu.l	#4,D0
	add.l	D0,A6
	
	move.l	(A6),D0		; R‚so + prog_txt
	tst.l	D0
	beq	NO_PROG
	
	clr.b	D6
	bra	END_TEST
	
NO_PROG	move.b	#1,D6

END_TEST	rts

; /// ALLOCATION MEMOIRE ///

MEM_ALLOC	clr.w	-(SP)		; System RAM only
	move.l	#339878,-(SP)		; Les deux ecrans plus les FIELDs
	move.w	#$44,-(SP)		; - M_XALLOC -
	trap	#1		; *** GEMDOS ***
	addq.l	#8,SP
	tst.l	D0
	beq	SYS_ERROR
	lea	BOTH_SCREEN,A0
	move.l	D0,(A0)+		; Premier ‚cran
	add.l	#153600,D0
	move.l	D0,(A0)+		; Deuxieme ‚cran
	add.l	#153600,D0
	move.l	D0,(A0)+		; D‚but des FIELDs

	rts
	
; /// CHARGEMENT DES FIELDS ///

FIELD_LOAD	lea	FIELD_NAME,A6
	lea	FIELD_BNK,A5
	move.l	(A5),D0
	add.l	#4,A5
	move.l	D0,(A5)
	clr.b	D4
LOOK_FOR	move.b	(A6)+,D0
	tst.b	D0
	beq	END_OF		; Si trouve 0 ...
	bra	LOOK_FOR
END_OF	move.b	(A6),D0
	tst.b	D0		; Deuxieme 0 ...
	beq	END_LOAD		; ... fin de chargement
FILE_LOAD	clr.w	-(SP)
	move.l	A6,-(SP)
	move.w	#$3D,-(SP)		; - F_OPEN -
	trap	#1		; *** GEMDOS ***
	addq.l	#8,SP
	move.w	D0,D7
	
	move.w	#2,-(SP)		; Fin
	move.w	D0,-(SP)
	clr.l	-(SP)		; Fin du fichier
	move.w	#$42,-(SP)		; - F_SEEK -
	trap	#1		; *** GEMDOS ***
	lea	10(SP),SP
	move.l	D0,D6

	clr.w	-(SP)		; D‚but
	move.w	D7,-(SP)
	clr.l	-(SP)		; D‚but du fichier
	move.w	#$42,-(SP)		; - F_SEEK -
	trap	#1		; *** GEMDOS ***
	lea	10(SP),SP

	move.l	(A5)+,D5
	move.l	D5,-(SP)		; Adresse du FIELD
	move.l	D6,-(SP)		; Taille du fichier
	move.w	D7,-(SP)		; Handle
	move.w	#$3F,-(SP)		; - F_READ -
	trap	#1		; *** GEMDOS ***
	lea	12(SP),SP

	cmp.l	D0,D6
	bne	ESCAPING
	add.l	D6,D5		; Adresse du prochain FIELD
	move.l	D5,(A5)
	
	move.w	D7,-(SP)
	move.w	#$3E,-(SP)		; - F_CLOSE -
	trap	#1		; *** GEMDOS ***
	addq.l	#4,SP
	
	addq.b	#1,D4
	bra	LOOK_FOR
END_LOAD	addq.b	#1,D4		; + le STAR FIELD
	move.b	D4,NB_FIELD
	move.l	(A5)+,D0		; Buffer des points affich‚s
	clr.l	(A5)		; Fin des FIELDs
	move.l	D0,A5
	move.w	#2,(A5)+

	lea	FIELD_BNK,A6
	add.l	#4,A6
	move.l	(A6),A6
	move.w	(A6)+,D1
	cmpi.w	#1,D1
	bne	ESCAPING
	clr.l	D1
	move.w	(A6),D1
	move.w	D1,(A5)
	
	subq.l	#2,A5
	move.l	A5,D0
	mulu.l	#6,D1
	addq.l	#4,D1
	add.l	D1,A5
	
	lea	FIELD_BNK,A6
	move.l	A5,(A6)		; STAR FIELD

	rts
			
; /// CREATION DU FIELD AUX ETOILES ///

STAR_FCREAT	lea	FIELD_BNK,A6
	move.l	A6,A5
	add.l	#4,A6
	move.l	(A6),A6
	move.l	(A5),A5
	
	move.w	(A6),D1
	cmpi.w	#1,D1
	bne	ESCAPING
	move.l	(A6),D2
	move.l	D2,(A5)+
	andi.l	#65535,D2		; Efface NB Version ...
	subq.l	#1,D2

COORD_STAR	move.w	#$11,-(SP)		; - RANDOM -
	trap	#14		; *** XBIOS ***
	addq.l	#2,SP
	
	fmove.l	D0,FP0
	fmove.l	#16777215,FP2
	fmove.w	#320,FP3
	fmove.w	#240,FP4
	
	fdiv.x	FP2,FP0
	fmul.x	FP3,FP0
	
	move.w	#$11,-(SP)		; - RANDOM -
	trap	#14		; *** XBIOS ***
	addq.l	#2,SP

	fmove.l	D0,FP1
	fdiv.x	FP2,FP1
	fmul.x	FP4,FP1
	
	fmove.w	FP0,D0
	fmove.w	FP1,D1
	
	move.w	D0,(A5)+
	move.w	D1,(A5)+
	
	dbf	D2,COORD_STAR
	
	clr.l	(A5)+		; Pas de prog

	rts

; /// ATTENTE DU CLAVIER ///

KEYB_WAIT	move.w	#2,-(SP)		; Console
	move.w	#2,-(SP)		; - BCONIN -
	trap	#13		; *** BIOS ***
	addq.l	#4,SP
	
	move.l	D0,D1
	swap	D1

	cmpi.b	#$48,D1		; Fleche HAUT
	beq	F_HAUT
	cmpi.b	#$50,D1		; Fleche BAS
	beq	F_BAS
	cmpi.b	#$39,D1		; Barre d'ESPACE
	beq	SPACE
	cmpi.b	#$5D,D1		; F20
	beq	ESCAPE
	bra	OUT_KEYB
F_HAUT	move.b	ACTUAL_FIELD,D0
	cmpi.b	#1,D0		; Si FIELD 1 ...
	beq	FIELD_MAX		; ... FIELD MAX
	move.b	D0,LAST_FIELD
	subq.b	#1,D0
	move.b	D0,ACTUAL_FIELD
	move.b	#1,CHANGE_ASKED		; Demande d'actualiser l'‚cran
	bra	OUT_KEYB
F_BAS	move.b	ACTUAL_FIELD,D0
	move.b	NB_FIELD,D1
	cmp.b	D0,D1		; Si FIELD MAX ...
	beq	FIELD_MIN		; ... FIELD 1
	move.b	D0,LAST_FIELD
	addq.b	#1,D0
	move.b	D0,ACTUAL_FIELD
	move.b	#1,CHANGE_ASKED		; Demande d'actualiser l'‚cran
	bra	OUT_KEYB
FIELD_MAX	move.b	NB_FIELD,D1
	move.b	D0,LAST_FIELD
	move.b	D1,ACTUAL_FIELD
	move.b	#1,CHANGE_ASKED
	bra	OUT_KEYB
FIELD_MIN	move.b	D1,LAST_FIELD
	move.b	#1,ACTUAL_FIELD
	move.b	#1,CHANGE_ASKED
	bra	OUT_KEYB
ESCAPE	move.b	#1,ESC_ASKED		; Demande de sortie
	bra	OUT_KEYB
SPACE	move.b	#1,RUN_ASKED		; Demande de lancement

OUT_KEYB	rts

; /// MORPHING LINEAIRE DES ETOILES ///

STAR_MORPH	move.b	CHANGE_ASKED,D1
	tst.b	D1
	beq	END_GRAPH
	move.b	#0,CHANGE_ASKED

	move.b	LAST_FIELD,D1
	move.b	ACTUAL_FIELD,D0
	tst.b	D1
	beq	FIRST_SAVE
	cmp.b	D1,D0
	beq	ESCAPING
	
	move.b	FIRST_PASS,D1
	tst.b	D1
	bne	FIRST_SAVE

PIC_MORPH	clr.l	D0
	clr.l	D1
	clr.l	D2
	move.b	LAST_FIELD,D0
	subq.b	#1,D0
	mulu.w	#4,D0
	move.b	ACTUAL_FIELD,D1
	subq.b	#1,D1
	mulu.w	#4,D1
	move.b	NB_FIELD,D2
	mulu.w	#4,D2
	
	lea	FIELD_BNK,A6
	move.l	A6,A5
	move.l	A6,A4
	
	add.l	D0,A4
	add.l	D1,A5
	add.l	D2,A6
	
	move.l	(A4),A4		; D‚part
	move.l	(A5),A5		; Arriv‚e
	move.l	(A6),A6		; Buffer

	move.b	MORPH_PASS,D0
	tst.b	D0
	bne	NEXT1_MORPH

	move.w	(A4)+,D4
	cmpi.w	#1,D4
	bne	ESCAPING		; Pas Version 1 ...
	move.w	(A5)+,D5
	cmpi.w	#1,D5		; Idem ...
	bne	ESCAPING

	move.w	(A4)+,D4		; A4 = D‚but des points
	move.w	(A5)+,D5		; A5 = Idem ...
	cmp.w	D4,D5		; Mˆme NB de points ?
	bne	ESCAPING
	
	move.w	(A6)+,D4
	cmpi.w	#2,D4		; Pas Version 2 ...
	bne	ESCAPING
	
	move.w	(A6),D4
	cmp.w	D4,D5		; D‚j… pass‚ ...
	beq	NEXT_MORPH
	move.w	D5,(A6)+		; NB points
	bra	NEXT_MORPH
	
FIRST_SAVE	move.b	#0,FIRST_PASS
	lea	FIELD_BNK,A6
	clr.l	D0
	move.b	NB_FIELD,D0
	mulu.w	#4,D0
	add.l	D0,A6
	move.l	(A6),A6
	add.l	#4,A6
	lea	FIELD_BNK,A5
	clr.l	D0
	move.b	ACTUAL_FIELD,D0
	subq.b	#1,D0
	mulu.l	#4,D0
	add.l	D0,A5
	move.l	(A5),A5
	move.l	(A5)+,D0
	andi.l	#65535,D0		; Efface le NB Version
	subq.w	#1,D0
	move.w	D0,D2
	move.l	A5,A4
	
FIRST_COPY	move.l	(A5)+,(A6)+
	clr.w	(A6)+		; Noir
	dbf	D0,FIRST_COPY
	
	lea	BOTH_SCREEN,A6
	move.l	(A6),A6

FIRST_GRAPH	clr.l	D0
	clr.l	D1
	move.w	(A4)+,D0
	move.w	(A4)+,D1
	mulu.l	#2,D0		; X
	mulu.l	#640,D1		; Y
	add.l	D1,D0		; Adresse du point
	move.l	A6,A5
	add.l	D0,A5
	move.w	#65535,(A5)		; Blanc
	dbf	D2,FIRST_GRAPH

	lea	BOTH_SCREEN,A6
	move.l	4(A6),A5
	move.l	(A6),A6
	move.w	#38399,D0		; 153600 OCTETs
	
COPY_SCREEN	move.l	(A6)+,(A5)+
	dbf	D0,COPY_SCREEN
	
	bra	END_GRAPH

NEXT_MORPH	move.b	#1,MORPH_PASS
	bra	PIC_MORPH
NEXT1_MORPH	move.b	#0,MORPH_PASS
	add.l	#4,A4
	add.l	#4,A5
	add.l	#2,A6
	
	move.b	NB_PICT,D7
	addq.b	#1,D7
	clr.b	D6
	
MORPHING	movem.l	A4-A6,-(SP)
	move.w	(A6)+,D3
	subq.w	#1,D3
	lea	BOTH_SCREEN,A3
	move.l	4(A3),A3

	move.l	A6,-(SP)
				
CLR_OLD_PTS	clr.l	D0
	clr.l	D1
	move.w	(A6)+,D0
	move.w	(A6)+,D1
	mulu.l	#2,D0		; X
	mulu.l	#640,D1		; Y
	add.l	D1,D0		; Adresse du point
	move.l	A3,A2
	add.l	D0,A2
	move.w	(A6)+,(A2)
	
	dbf	D3,CLR_OLD_PTS

	move.l	(SP)+,A6
	sub.l	#2,A6
	swap	D6
	move.w	(A6)+,D6
	subq.w	#1,D6
	
MOVE_PTS	move.b	NB_PICT,D5		; NB d‚compositions
	fmove.b	D5,FP6
	swap	D6
	fmove.b	D6,FP7		; NB phase
	swap	D6
	
	move.w	(A4)+,D5		; X d‚part
	fmove.w	D5,FP0
	move.w	(A4)+,D5		; Y d‚part
	fmove.w	D5,FP1
	move.w	(A5)+,D5		; X fin
	fmove.w	D5,FP2
	move.w	(A5)+,D5		; Y fin
	fmove.w	D5,FP3
	
	fmove.x	FP0,FP4
	fsub.x	FP2,FP4
	fdiv.x	FP6,FP4
	fmul.x	FP7,FP4
	fsub.x	FP4,FP0		; Nouveau X
	
	fmove.x	FP1,FP4
	fsub.x	FP3,FP4
	fdiv.x	FP6,FP4
	fmul.x	FP7,FP4
	fsub.x	FP4,FP1		; Nouveau Y
	
	clr.l	D0
	clr.l	D1
	fmove.w	FP0,D0
	fmove.w	FP1,D1
	move.w	D0,(A6)+
	move.w	D1,(A6)+
	mulu.l	#2,D0
	mulu.l	#640,D1
	add.l	D1,D0
	move.l	A3,A2
	add.l	D0,A2
	move.w	(A2),D2
	tst.w	D2
	bne	AL_COLORED
	move.w	(A2),(A6)+
	bra	NEXT_NEW_STAR
AL_COLORED	move.w	#0,(A6)+
NEXT_NEW_STAR	move.w	#65535,(A2)		; Blanc

	dbf	D6,MOVE_PTS
	swap	D6
		
	lea	BOTH_SCREEN,A6
	
	move.w	#$25,-(SP)		; - VSYNC -
	trap	#14		; *** XBIOS ***
	addq.l	#2,SP
	
	move.w	#-1,-(SP)
	move.l	4(A6),-(SP)
	move.l	(SP),-(SP)
	move.w	#5,-(SP)		; - SETSCREEN -
	trap	#14		; *** XBIOS ***
	lea	12(SP),SP
	
	move.l	4(A6),A5
	move.l	(A6),4(A6)
	move.l	A5,(A6)
	move.l	4(A6),A6
	
	move.w	#38399,D0
COPY_STAR_SCR	move.l	(A5)+,(A6)+
	dbf	D0,COPY_STAR_SCR
	
	movem.l	(SP)+,A4-A6
	
	addq.b	#1,D6
	cmp.b	D6,D7
	bne	MORPHING	

END_GRAPH	rts

; /// LANCEMENT DES PROGRAMMES ///

RUN_PROGS	lea	FIELD_BNK,A6
	clr.l	D5
	move.b	ACTUAL_FIELD,D5
	subq.b	#1,D5
	mulu.l	#4,D5
	adda.l	D5,A6
	move.l	(A6),A6
	move.w	(A6)+,D0
	cmpi.w	#1,D0
	bne	ESCAPING
	clr.l	D0
	move.w	(A6)+,D0
	mulu.l	#4,D0
	adda.l	D0,A6
	move.b	#0,FROM_PROGS		; Video dans le mode du programme
	
	bsr	INSTALL_VIDEO
	
	pea	ENVIRONMENT
	pea	COMMAND_LINE
	move.l	PROG_LOCAT,-(SP)
	clr.w	-(SP)		; Charge et execute
	move.w	#$4B,-(SP)		; - P_EXEC -
	trap	#1		; *** GEMDOS ***
	lea	16(SP),SP
	tst.w	D0
	bne	SYS_ERROR
	
	rts
	
ENVIRONMENT	dc.b	0
COMMAND_LINE	dc.b	0	
	
; /// ARRETE LA SOURIS ///

STOP_MOUSE	move.w	#18,-(SP)
	move.w	#4,-(SP)
	move.w	#3,-(SP)		; - BCONOUT -
	trap	#13		; *** BIOS ***
	addq.l	#6,SP
	
	rts

; /// LIBERE LA SOURIS ///

FREE_MOUSE	move.w	#8,-(SP)
	move.w	#4,-(SP)
	move.w	#3,-(SP)		; - BCONOUT -
	trap	#13		; *** BIOS ***
	addq.l	#6,SP
	
	rts

; /// LIBERATION DE LA MEMOIRE ///

MEM_FREE	lea	BOTH_SCREEN,A6
	move.l	(A6)+,D0
	move.l	(A6),D1
	cmp.l	D0,D1
	bgt	SECOND_START
	move.l	D1,-(SP)
	bra	FREE
SECOND_START	move.l	D0,-(SP)
FREE	move.w	#$49,-(SP)		; - M_FREE -
	trap	#1		; *** GEMDOS ***
	addq.l	#6,SP
	tst.w	D0
	bne	SYS_ERROR
	
	rts

; /// INSTALLE LE NOUVEAU MODE VIDEO ///

INSTALL_VIDEO	move.b	FROM_PROGS,D0
	tst.b	D0
	bne	SMS_MODE
	clr.l	D0
	move.w	(A6)+,D0		; Le mode du programme
	cmpi.w	#3,D0
	bne	CHANGE_ST
	swap	D0
	move.w	(A6)+,D0
	move.l	D0,PROG_MODE
	move.l	A6,PROG_LOCAT
		
	bsr	MEM_FREE
	
	move.l	PROG_MODE,D0
	move.w	D0,-(SP)
	move.w	#$5B,-(SP)		; - VGETSIZE -
	trap	#14		; *** XBIOS ***
	addq.l	#4,SP
	
	move.l	D0,D5
	
	bsr	RESERVE_SCREEN
	
	move.l	PROG_MODE,D0
	move.l	D0,-(SP)
	move.b	#1,D6
	bra	NEW_MODE
CHANGE_ST	move.l	D0,PROG_MODE
	move.l	A6,PROG_LOCAT
	
	bsr	MEM_FREE

	move.l	#32000,D5
	
	bsr	RESERVE_SCREEN
	
	move.l	PROG_MODE,D0
	move.w	D0,-(SP)
	clr.b	D6
	bra	NEW_MODE
SMS_MODE	bsr	MEM_ALLOC
	move.w	#3,D0
	swap	D0
	move.w	#%100010100,D0
	move.l	D0,-(SP)
	move.b	#1,D6
NEW_MODE	lea	BOTH_SCREEN,A6
	move.l	(A6),-(SP)
	move.l	(SP),-(SP)
	move.w	#5,-(SP)		; - SETSCREEN -
	trap	#14		; *** XBIOS ***
	tst.b	D6
	bne	RESTORE_FALCON
	lea	12(SP),SP
	bra	END_CHANGE_MODE
RESTORE_FALCON	lea	14(SP),SP

	move.b	FROM_PROGS,D0
	tst.b	D0

	beq	END_CHANGE_MODE

KILL_SCREEN	lea	BOTH_SCREEN,A6
	move.l	(A6),A6
	move.l	#76799,D0
BLACK_SCREEN	clr.l	(A6)+
	subq.l	#1,D0
	tst.l	D0
	bpl	BLACK_SCREEN

END_CHANGE_MODE	rts

RESERVE_SCREEN	clr.w	-(SP)		; System RAM only
	move.l	D5,-(SP)
	move.w	#$44,-(SP)		; - M_XALLOC -
	trap	#1		; *** GEMDOS ***
	addq.l	#8,SP
	tst.l	D0
	beq	SYS_ERROR
	lea	BOTH_SCREEN,A6
	move.l	D0,(A6)+
	move.l	D0,(A6)+
	
	rts

; /// SAUVE L'ANCIEN MODE VIDEO ///

SAVE_VIDEO	move.w	#-1,-(SP)		; Mode actuel
	move.w	#$58,-(SP)		; - VSETMODE -
	trap	#14		; *** XBIOS ***
	addq.l	#4,SP
	
	move.w	D0,OLD_MODE
	
	rts

; /// RESTAURE LE MODE VIDEO ///

RESTORE_VIDEO	move.w	OLD_MODE,-(SP)
	move.w	#$5B,-(SP)		; - VGETSIZE -
	trap	#14		; *** XBIOS ***
	addq.l	#4,SP
	
	clr.w	-(SP)		; System RAM only
	move.l	D0,-(SP)
	move.w	#$44,-(SP)		; - M_XALLOC -
	trap	#1		; *** GEMDOS ***
	addq.l	#8,SP
	tst.l	D0
	beq	SYS_ERROR
	move.l	D0,D7
	
	move.w	OLD_MODE,-(SP)		; Ancien mode
	move.w	#3,-(SP)
	move.l	D7,-(SP)
	move.l	D7,-(SP)
	move.w	#5,-(SP)		; - SETSCREEN -
	trap	#14		; *** XBIOS ***
	lea	14(SP),SP
	
	rts

; /// SORTIE DU SHELL ///

SYS_ERROR	move.l	OLD_STACK,SP		; Restaure l'ancienne PILE
EXIT_PROG	move.w	D0,-(SP)		; EmPILE le code de l'erreur \
	move.w	#$4C,-(SP)		; - P_TERM -                 |-> Quitte proprement
	trap	#1		; *** GEMDOS ***             /

; /// VARIABLES ///

OLD_STACK	ds.l	1		; Ancienne PILE
OLD_MODE	ds.w	1		; Ancien mode
FROM_PROGS	ds.b	1		; Changement occasionel
BOTH_SCREEN	ds.l	2		; L'adresse des deux ‚crans
FIELD_BNK	ds.l	16		; Pointeurs des FIELDs
NB_FIELD	ds.b	1		; Nombre de ...
ACTUAL_FIELD	ds.b	1		; FIELD en utilisation
NB_POINTS	ds.b	1		; Nombre de points par FIELD
LAST_FIELD	ds.b	1		; Num‚ro de l'ancien FIELD
CHANGE_ASKED	ds.b	1		; Demande d'actualisation
ESC_ASKED	ds.b	1		; Demande de sortie
RUN_ASKED	ds.b	1		; Demande de lancement
PROG_MODE	ds.l	1		; Mode du programme
PROG_LOCAT	ds.l	1		; Adresse du programme
MORPH_PASS	ds.b	1		; Passage
FIRST_PASS	ds.b	1		; R‚-actualisation

FIELD_NAME	dc.b	0,"I:\M-SHELL\COPERNIC.SMS",0	; Le FIELD de COPERNIC
	dc.b	"I:\M-SHELL\STARGIDE.SMS",0,0	; Le FIELD de STARGUIDE
NB_PICT	dc.b	19		; 20 images
