; //////////////////////////////////////////
; //////////////////////////////////////////
; //////////////////////////////////////////
; ///                                    ///
; ///   >>> STARS MOVING SHELL III <<<   ///
; ///       Falcon030 Version 3.00       ///
; ///     Written In 1997 By Kochise     ///
; ///                                    ///
; /// New Version Designed For Falcon030 ///
; ///                                    ///
; //////////////////////////////////////////
; //////////////////////////////////////////
; //////////////////////////////////////////

; /// INITIALISATION DE LA MEMOIRE ///

Init_Prg_Mem	movea.l	4(SP),A6		; Adresse de la BASEPAGE
	move.l	$C(A6),D0		; Taille du programme
	add.l	$14(A6),D0		; Additionne la taille du SEGMENT DATA … D0
	add.l	$1C(A6),D0		; Additionne la taille du SEGMENT BSS … D0
	addi.l	#$100,D0		; Additionne la taille de la BASEPAGE … D0
	addi.l	#$400,D0		; Additionne la taille de la future PILE (Ici, 256 positions longues (1024 OCTETS))
	move.l	D0,D1		; Copie D0 dans D1 (Taille … r‚server)
	add.l	A6,D1		; Additionne l'adresse du d‚but du programme avec D1 (La taille … r‚server)
	andi.l	#-2,D1		; Rend D1 pair (Au cas o— il ne l'‚tait pas)
	move.l	SP,Old_Stack
	movea.l	D1,SP		; Installe l'adresse de fin du programme+place nouvelle PILE dans la PILE
	move.l	D0,-(SP)		; EmPILE la taille … reserver	\
	move.l	A6,-(SP)		; EmPILE l'adresse du programme |-> Rend le reste de la m‚moire au systŠme
	clr.w	-(SP)		; R‚serv‚                       |
	move.w	#$4A,-(SP)		; - M_SHRINK -                  |
	trap	#1		; *** GEMDOS ***                /
	lea	12(SP),SP
	tst	D0		; Si D0<>0, problŠme grave
	BNE	Exit

Main_Rout	nop


Escaping	move.b	#0,Esc_Asked
	BSR	Free_Mouse
	BSR	Mem_Free
	BSR	Restore_Video
	BRA	Exit
	
Running	move.b	#0,Run_Asked
	
	BSR	Test_Prog_Ok
	tst.b	D6
	BNE	End_Run
	
	BSR	Free_Mouse
	BSR	Run_Progs
	
	BSR	Stop_Mouse
	move.b	#1,From_Progs
	BSR	Install_Video
	BSR	Field_Load
	BSR	Star_FCreat
	move.b	#1,Change_Asked
	move.b	#1,First_Pass
	
End_Run	BRA	Main_Rout

Test_Prog_Ok	lea	Field_Bnk,A6
	clr.l	D0
	move.b	Actual_Field,D0
	subq.b	#1,D0
	mulu.l	#4,D0
	add.l	D0,A6
	move.l	(A6),A6
	
	move.w	(A6)+,D0
	cmpi.w	#1,D0
	BNE	Run_Escape
	
	move.w	(A6)+,D0
	mulu.l	#4,D0
	add.l	D0,A6
	
	move.l	(A6),D0		; R‚so + Prog_Txt
	tst.l	D0
	BEQ	No_Prog
	
	clr.b	D6
	BRA	End_Test
	
No_Prog	move.b	#1,D6

End_Test	RTS

Run_Escape	lea	Escaping,(SP)

	RTS

; /// ALLOCATION MEMOIRE ///

Mem_Alloc	clr.w	-(SP)		; System RAM only
	move.l	#339878,-(SP)		; Les deux ‚crans plus les FIELDs
	move.w	#$44,-(SP)		; - M_XALLOC -
	trap	#1		; *** GEMDOS ***
	addq.l	#8,SP
	tst.l	D0
	BEQ	Exit
	lea	Both_Screen,A0
	move.l	D0,(A0)+		; Premier ‚cran
	add.l	#153600,D0
	move.l	D0,(A0)+		; Deuxieme ‚cran
	add.l	#153600,D0
	move.l	D0,(A0)+		; D‚but des FIELDs

	RTS
	
; /// CHARGEMENT DES FIELDS ///

Field_Load	lea	Field_Name,A6
	lea	Field_Bnk,A5
	move.l	(A5),D0
	add.l	#4,A5
	move.l	D0,(A5)
	clr.b	D4
Look_For	move.b	(A6)+,D0
	tst.b	D0
	BEQ	End_Of		; Si trouve 0 ...
	BRA	Look_For
End_Of	move.b	(A6),D0
	tst.b	D0		; Deuxieme 0 ...
	BEQ	End_Load		; ... fin de chargement
File_Load	clr.w	-(SP)
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
	BNE	Escaping
	add.l	D6,D5		; Adresse du prochain FIELD
	move.l	D5,(A5)
	
	move.w	D7,-(SP)
	move.w	#$3E,-(SP)		; - F_CLOSE -
	trap	#1		; *** GEMDOS ***
	addq.l	#4,SP
	
	addq.b	#1,D4
	BRA	Look_For

End_Load	addq.b	#1,D4		; + le STAR FIELD
	move.b	D4,Nb_Field
	move.l	(A5)+,D0		; Buffer des points affich‚s
	clr.l	(A5)		; Fin des FIELDs
	move.l	D0,A5
	move.w	#2,(A5)+

	lea	Field_Bnk,A6
	add.l	#4,A6
	move.l	(A6),A6
	move.w	(A6)+,D1
	cmpi.w	#1,D1
	BNE	Escaping
	clr.l	D1
	move.w	(A6),D1
	move.w	D1,(A5)
	
	subq.l	#2,A5
	move.l	A5,D0
	mulu.l	#6,D1
	addq.l	#4,D1
	add.l	D1,A5
	
	lea	Field_Bnk,A6
	move.l	A5,(A6)		; STAR FIELD

	RTS
			
; /// CREATION DU FIELD AUX ETOILES ///

Star_FCreat	lea	Field_Bnk,A6
	move.l	A6,A5
	add.l	#4,A6
	move.l	(A6),A6
	move.l	(A5),A5
	
	move.w	(A6),D1
	cmpi.w	#1,D1
	BNE	Escaping
	move.l	(A6),D2
	move.l	D2,(A5)+
	andi.l	#-1,D2		; Efface NB Version ...
	subq.l	#1,D2

Coord_Star	move.w	#$11,-(SP)		; - RANDOM -
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
	
	dbf	D2,Coord_Star
	
	clr.l	(A5)+		; Pas de prog

	RTS

; /// ATTENTE DU CLAVIER ///

Keyb_Wait	move.w	#2,-(SP)		; Console
	move.w	#2,-(SP)		; - BCONIN -
	trap	#13		; *** BIOS ***
	addq.l	#4,SP
	
	move.l	D0,D1
	swap	D1

	cmpi.b	#$48,D1		; Fleche HAUT
	BEQ	F_Haut
	cmpi.b	#$50,D1		; Fleche BAS
	BEQ	F_Bas
	cmpi.b	#$39,D1		; Barre d'ESPACE
	BEQ	Space
	cmpi.b	#$5D,D1		; F20
	BEQ	Escape
	BRA	Out_Keyb
F_Haut	move.b	Actual_Field,D0
	cmpi.b	#1,D0		; Si FIELD 1 ...
	BEQ	Field_Max		; ... FIELD MAX
	move.b	D0,Last_Field
	subq.b	#1,D0
	move.b	D0,Actual_Field
	move.b	#1,Change_Asked		; Demande d'actualiser l'‚cran
	BRA	Out_Keyb
F_Bas	move.b	Actual_Field,D0
	move.b	Nb_Field,D1
	cmp.b	D0,D1		; Si FIELD MAX ...
	BEQ	Field_Min		; ... FIELD 1
	move.b	D0,Last_Field
	addq.b	#1,D0
	move.b	D0,Actual_Field
	move.b	#1,Change_Asked		; Demande d'actualiser l'‚cran
	BRA	Out_Keyb
Field_Max	move.b	Nb_Field,D1
	move.b	D0,Last_Field
	move.b	D1,Actual_Field
	move.b	#1,Change_Asked
	BRA	Out_Keyb
Field_Min	move.b	D1,Last_Field
	move.b	#1,Actual_Field
	move.b	#1,Change_Asked
	BRA	Out_Keyb
Escape	move.b	#1,Esc_Asked		; Demande de sortie
	BRA	Out_Keyb
Space	move.b	#1,Run_Asked		; Demande de lancement

Out_Keyb	RTS

; /// LANCEMENT DES PROGRAMMES ///

Run_Progs	lea	Field_Bnk,A6
	clr.l	D5
	move.b	Actual_Field,D5
	subq.b	#1,D5
	mulu.l	#4,D5
	adda.l	D5,A6
	move.l	(A6),A6
	move.w	(A6)+,D0
	cmpi.w	#1,D0
	bne	Escaping
	clr.l	D0
	move.w	(A6)+,D0
	mulu.l	#4,D0
	adda.l	D0,A6
	move.b	#0,From_Progs		; Video dans le mode du programme
	
	bsr	Install_Video
	
	pea	Environment
	pea	Command_Line
	move.l	Prog_Locat,-(SP)
	clr.w	-(SP)		; Charge et execute
	move.w	#$4B,-(SP)		; - P_EXEC -
	trap	#1		; *** GEMDOS ***
	lea	16(SP),SP
	tst.w	D0
	bne	Exit
	
	RTS
	
Environment	dc.b	0
Command_Line	dc.b	0	
	
; /// ARRETE LA SOURIS ///

Stop_Mouse	move.w	#18,-(SP)
	move.w	#4,-(SP)
	move.w	#3,-(SP)		; - BCONOUT -
	trap	#13		; *** BIOS ***
	addq.l	#6,SP
	
	RTS

; /// LIBERE LA SOURIS ///

Free_Mouse	move.w	#8,-(SP)
	move.w	#4,-(SP)
	move.w	#3,-(SP)		; - BCONOUT -
	trap	#13		; *** BIOS ***
	addq.l	#6,SP
	
	RTS

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
