GOTO_XY		MACRO	POSX,POSY
			MOV	AH,02H
			MOV	BH,0
			MOV	DL,POSX
			MOV	DH,POSY
			INT	10H
ENDM



; MOSTRA - Faz o display de uma string terminada em $
;---------------------------------------------------------------------------
MOSTRA MACRO STR
MOV AH,09H
LEA DX,STR
INT 21H
ENDM
; FIM DAS MACROS


;---------------------------------------------------------------------------


.8086
.model small
.stack 2048h

PILHA	SEGMENT PARA STACK 'STACK'
		db 2048 dup(?)
PILHA	ENDS


DSEG    SEGMENT PARA PUBLIC 'DATA'


		POSy	db	10	; a linha pode ir de [1 .. 25]
		POSx	db	40	; POSx pode ir [1..80]
		POSya		db	5	; Posi��o anterior de y
		POSxa		db	10	; Posi��o anterior de x

                linha		db	0	; Define o n�mero da linha que est� a ser desenhada
		nlinhas		db	0


		PASSA_T		dw	0
		PASSA_T_ant	dw	0
		direccao	db	3

		Centesimos	dw 	0
		FACTOR		db	100
		metade_FACTOR	db	?
		resto		db	0

		Erro_Open       db      'Erro ao tentar abrir o ficheiro$'
		Erro_Ler_Msg    db      'Erro ao tentar ler do ficheiro$'
		Erro_Close      db      'Erro ao tentar fechar o ficheiro$'
		Fich         	db      'moldura.TXT',0
		HandleFich      dw      0
		car_fich        db      ?
                ultimo_num_aleat dw     0
                Car		db	32	; Guarda um caracter do Ecran

DSEG    ENDS

CSEG    SEGMENT PARA PUBLIC 'CODE'
	ASSUME  CS:CSEG, DS:DSEG, SS:PILHA



;********************************************************************************



PASSA_TEMPO PROC


		MOV AH, 2CH             ; Buscar a hORAS
		INT 21H

 		XOR AX,AX
		MOV AL, DL              ; centesimos de segundo para ax
		mov Centesimos, AX

		mov bl, factor		; define velocidade da snake (100; 50; 33; 25; 20; 10)
		div bl
		mov resto, AH
		mov AL, FACTOR
		mov AH, 0
		mov bl, 2
		div bl
		mov metade_FACTOR, AL
		mov AL, resto
		mov AH, 0
		mov BL, metade_FACTOR	; deve ficar sempre com metade do valor inicial
		mov AH, 0
		cmp AX, BX
		jbe Menor
		mov AX, 1
		mov PASSA_T, AX
		jmp fim_passa

Menor:		mov AX,0
		mov PASSA_T, AX

fim_passa:

 		RET
PASSA_TEMPO   ENDP




;********************************************************************************



Imp_Fich	PROC

;abre ficheiro

        mov     ah,3dh			; vamos abrir ficheiro para leitura
        mov     al,0			; tipo de ficheiro
        lea     dx,Fich			; nome do ficheiro
        int     21h			; abre para leitura
        jc      erro_abrir		; pode aconter erro a abrir o ficheiro
        mov     HandleFich,ax		; ax devolve o Handle para o ficheiro
        jmp     ler_ciclo		; depois de aberto vamos ler o ficheiro

erro_abrir:
        mov     ah,09h
        lea     dx,Erro_Open
        int     21h
        jmp     sai

ler_ciclo:
        mov     ah,3fh			; indica que vai ser lido um ficheiro
        mov     bx,HandleFich		; bx deve conter o Handle do ficheiro previamente aberto
        mov     cx,1			; numero de bytes a ler
        lea     dx,car_fich		; vai ler para o local de memoria apontado por dx (car_fich)
        int     21h			; faz efectivamente a leitura
	jc	    erro_ler		; se carry � porque aconteceu um erro
	cmp	    ax,0		;EOF?	verifica se j� estamos no fim do ficheiro
	je	    fecha_ficheiro	; se EOF fecha o ficheiro
        mov     ah,02h			; coloca o caracter no ecran
	mov	    dl,car_fich		; este � o caracter a enviar para o ecran
	int	    21h			; imprime no ecran
	jmp	    ler_ciclo		; continua a ler o ficheiro

erro_ler:
        mov     ah,09h
        lea     dx,Erro_Ler_Msg
        int     21h

fecha_ficheiro:					; vamos fechar o ficheiro
        mov     ah,3eh
        mov     bx,HandleFich
        int     21h
        jnc     sai

        mov     ah,09h			; o ficheiro pode n�o fechar correctamente
        lea     dx,Erro_Close
        Int     21h
sai:	  RET
Imp_Fich	endp

;########################################################################

;********************************************************************************
;ROTINA PARA APAGAR ECRAN

APAGA_ECRAN	PROC
		PUSH BX
		PUSH AX
		PUSH CX
		PUSH SI
		XOR	BX,BX
		MOV	CX,24*80
		mov bx,160
		MOV SI,BX
APAGA:
		MOV	AL,' '
		MOV	BYTE PTR ES:[BX],AL
		MOV	BYTE PTR ES:[BX+1],7
		INC	BX
		INC BX
		INC SI
		LOOP	APAGA
		POP SI
		POP CX
		POP AX
		POP BX
		RET
APAGA_ECRAN	ENDP

;********************************************************************************
; LEITURA DE UMA TECLA DO TECLADO    (ALTERADO)
; LE UMA TECLA	E DEVOLVE VALOR EM AH E AL
; SE ah=0 � UMA TECLA NORMAL
; SE ah=1 � UMA TECLA EXTENDIDA
; AL DEVOLVE O C�DIGO DA TECLA PREMIDA
; Se n�o foi premida tecla, devolve ah=0 e al = 0
;********************************************************************************
LE_TECLA_0	PROC

		;call 	Trata_Horas
		MOV	AH,0BH
		INT 	21h
		cmp 	AL,0
		jne	com_tecla
		mov	AH, 0
		mov	AL, 0
		jmp	SAI_TECLA
com_tecla:
		MOV	AH,08H
		INT	21H
		MOV	AH,0
		CMP	AL,0
		JNE	SAI_TECLA
		MOV	AH, 08H
		INT	21H
		MOV	AH,1
SAI_TECLA:
		RET
LE_TECLA_0	ENDP





;#############################################################################
move_snake PROC

CICLO:
		goto_xy		POSx,POSy	; Vai para nova posi��o
		mov 		ah, 08h	; Guarda o Caracter que est� na posi��o do Cursor
		mov		bh,0		; numero da p�gina
		int		10h
		cmp 		al,'#'	;  na posi��o do Cursor
		je		fim
                cmp             al,'&'
                je              trocaletra
                cmp             al, 05
                je              trocaletra

		goto_xy		POSxa,POSya		; Vai para a posi��o anterior do cursor
		mov		ah, 02h
		mov		dl, ' ' 	; Coloca ESPA�O
		int		21H

		inc		POSxa
		goto_xy		POSxa,POSya
		mov		ah, 02h
		mov		dl, ' '		;  Coloca ESPA�O
		int		21H
		dec 		POSxa





		goto_xy		POSx,POSy	; Vai para posi��o do cursor
IMPRIME:	mov		ah, 02h
		mov		dl, '('	; Coloca AVATAR1
		int		21H

		inc		POSx
		goto_xy		POSx,POSy
		mov		ah, 02h
		mov		dl, ')'	; Coloca AVATAR2
		int		21H
		dec		POSx

		goto_xy		POSx,POSy	; Vai para posi��o do cursor

		mov		al, POSx	; Guarda a posi��o do cursor
		mov		POSxa, al
		mov		al, POSy	; Guarda a posi��o do cursor
		mov 		POSya, al
                jmp             LER_SETA
;altera�ao

trocaletra:

goto_xy		POSxa,POSya		; Vai para a posi��o anterior do cursor
		mov		ah, 02h
		mov		dl, ' ' 	; Coloca ESPA�O
		int		21H

		inc		POSxa
		goto_xy		POSxa,POSya
		mov		ah, 02h
		mov		dl, ' '		;  Coloca ESPA�O
		int		21H
		dec 		POSxa





		goto_xy		POSx,POSy	; Vai para posi��o do cursor
        	mov		ah, 02h
		mov		dl, '('	; Coloca AVATAR1
		int		21H

		inc		POSx
		goto_xy		POSx,POSy
		mov		ah, 02h
		mov		dl, ')'	; Coloca AVATAR2
		int		21H
		dec		POSx

		goto_xy		POSx,POSy	; Vai para posi��o do cursor

		mov		al, POSx	; Guarda a posi��o do cursor
		mov		POSxa, al
		mov		al, POSy	; Guarda a posi��o do cursor
		mov 		POSya, al


		mov	linha, dh	; O Tabuleiro vai come�ar a ser desenhado na linha 8
		mov	nlinhas,al	; O Tabuleiro vai ter 6 linhas



		mov	al, 150
		mov	ah, linha
		mul	ah
		add	ax, 55
		mov 	bx, ax		; Determina Endere�o onde come�a a "linha". bx = 160*linha + 60
                inc     ah
		mov	cx, 9   	; S�o 9 colunas

		 ;mov 	dh,	car	; vai imprimir o caracter "SAPCE"
		 ;mov	es:[bx],dh	;

novacor:
		call	CalcAleat	; Calcula pr�ximo aleat�rio que � colocado na pilha
		pop	ax		; Vai buscar 'a pilha o n�mero aleat�rio
                mov     ax,05
		and 	ah,01110000b	; posi��o do ecran com cor de fundo aleat�rio e caracter a preto
                ;cmp     al,05
                ;je      novacor
                
                

		 ;mov 	dh,	   car	; Repete mais uma vez porque cada pe�a do tabuleiro ocupa dois caracteres de ecran
		 ;mov	es:[bx],   dh

		mov	es:[bx+1], al	; Coloca as caracter�sticas de cor da posi��o atual
              
		inc	bx
		inc	bx		; pr�xima posi��o e ecran dois bytes � frente

		; mov 	dh,	   car	; Repete mais uma vez porque cada pe�a do tabuleiro ocupa dois carecteres de ecran
		; mov	es:[bx],   dh
		mov	es:[bx+1], al
		inc	bx
		inc	bx


;altera�ao




LER_SETA:	call 		LE_TECLA_0
		cmp		ah, 1
		je		ESTEND
		CMP 		AL, 27	; ESCAPE
		JE		FIM
		CMP		AL, '1'
		JNE		TESTE_2
		MOV		FACTOR, 100
TESTE_2:	CMP		AL, '2'
		JNE		TESTE_3
		MOV		FACTOR, 50
TESTE_3:	CMP		AL, '3'
		JNE		TESTE_4
		MOV		FACTOR, 25
TESTE_4:	CMP		AL, '4'
		JNE		TESTE_END
		MOV		FACTOR, 10
TESTE_END:
		CALL		PASSA_TEMPO
		mov		AX, PASSA_T_ant
		CMP		AX, PASSA_T
		je		LER_SETA
		mov		AX, PASSA_T
		mov		PASSA_T_ant, AX

verifica_0:	mov		al, direccao
		cmp 		al, 0
		jne		verifica_1
		inc		POSx		;Direita
		inc		POSx		;Direita
		jmp		CICLO

verifica_1:	mov 		al, direccao
		cmp		al, 1
		jne		verifica_2
		dec		POSy		;cima
		jmp		CICLO

verifica_2:	mov 		al, direccao
		cmp		al, 2
		jne		verifica_3
		dec		POSx		;Esquerda
		dec		POSx		;Esquerda
		jmp		CICLO

verifica_3:	mov 		al, direccao
		cmp		al, 3
		jne		CICLO
		inc		POSy		;BAIXO
		jmp		CICLO

ESTEND:		cmp 		al,48h
		jne		BAIXO
		mov		direccao, 1
		jmp		CICLO

BAIXO:		cmp		al,50h
		jne		ESQUERDA
		mov		direccao, 3
		jmp		CICLO

ESQUERDA:
		cmp		al,4Bh
		jne		DIREITA
		mov		direccao, 2
		jmp		CICLO

DIREITA:
		cmp		al,4Dh
		jne		LER_SETA
		mov		direccao, 0
		jmp		CICLO

fim:		goto_xy		40,23
		RET

move_snake ENDP

;CalcAleat - calcula um numero aleatorio de 16 bits
;Parametros passados pela pilha
;entrada:
;n�o tem parametros de entrada
;saida:
;param1 - 16 bits - numero aleatorio calculado
;notas adicionais:
; deve estar definida uma variavel => ultimo_num_aleat dw 0
; assume-se que DS esta a apontar para o segmento onde esta armazenada ultimo_num_aleat
CalcAleat proc near

	sub	sp,2		;
	push	bp
	mov	bp,sp
	push	ax
	push	cx
	push	dx
	mov	ax,[bp+4]
	mov	[bp+2],ax

	mov	ah,00h
	int	1ah

	add	dx,ultimo_num_aleat	; vai buscar o aleat�rio anterior
	add	cx,dx
	mov	ax,65521
	push	dx
	mul	cx
	pop	dx
	xchg	dl,dh
	add	dx,32749
	add	dx,ax

	mov	ultimo_num_aleat,dx	; guarda o novo numero aleat�rio

	mov	[BP+4],dx		; o aleat�rio � passado por pilha

	pop	dx
	pop	cx
	pop	ax
	pop	bp
	ret
CalcAleat endp


;#############################################################################
;             MAIN
;#############################################################################
MENU    Proc
		MOV     	AX,DSEG
		MOV     	DS,AX
		MOV		AX,0B800H
		MOV		ES,AX		; ES indica segmento de mem�ria de VIDEO
		CALL 		APAGA_ECRAN
		CALL		Imp_Fich
                call		move_snake






  fim:          MOV		AH,4Ch
		INT		21h
MENU    endp
cseg	ends
end     MENU
