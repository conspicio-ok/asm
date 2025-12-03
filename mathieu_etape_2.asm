extern XOpenDisplay
extern XDisplayName
extern XCloseDisplay
extern XCreateSimpleWindow
extern XMapWindow
extern XRootWindow
extern XSelectInput
extern XFlush
extern XCreateGC
extern XSetForeground
extern XDrawLine
extern XDrawPoint
extern XDrawArc
extern XFillArc
extern XNextEvent
extern exit

%define	StructureNotifyMask	131072
%define KeyPressMask		1
%define ButtonPressMask		4
%define MapNotify		19
%define KeyPress		2
%define ButtonPress		4
%define Expose			12
%define ConfigureNotify		22
%define CreateNotify 16
%define QWORD	8
%define DWORD	4
%define WORD	2
%define BYTE	1
%define NBTRI	100 ; nombre de triangles à générer
%define	LARGEUR 400	; largeur en pixels de la fenêtre
%define HAUTEUR 400	; hauteur en pixels de la fenêtre

global main

section .bss
display_name:	resq	1
screen:			resd	1
window:			resq	1
gc:				resq	1

section .data
event:		times	24 dq 0

; Coordonnées des triangles (tableaux de NBTRI éléments)
triangles_x1:	times NBTRI dd 0
triangles_y1:	times NBTRI dd 0
triangles_x2:	times NBTRI dd 0
triangles_y2:	times NBTRI dd 0
triangles_x3:	times NBTRI dd 0
triangles_y3:	times NBTRI dd 0

triangles_generes:	dd	0

; Tableau de couleurs pour les triangles
couleurs:
    dd 0xFF0000     ; Triangle 0 : Rouge
    dd 0x00FF00     ; Triangle 1 : Vert
    dd 0x0000FF     ; Triangle 2 : Bleu
    dd 0xFFFF00     ; Triangle 3 : Jaune
    dd 0xFF00FF     ; Triangle 4 : Magenta
    dd 0x00FFFF     ; Triangle 5 : Cyan

section .text

;##################################################
;########### FONCTION RANDOM_RANGE ################
;##################################################
; Génère un nombre aléatoire entre 0 et max (inclus)
; Entrée : EDI = valeur maximale
; Sortie : EAX = valeur aléatoire générée

random_range:
    push rbx
    mov ebx, edi        ; Sauvegarde max dans ebx
    inc ebx             ; ebx = max + 1 (pour l'opération modulo)
    
.retry:
    ; Génère un nombre aléatoire sur 16 bits
    rdrand ax           ; Génère nombre aléatoire dans ax (16 bits)
    jnc .retry          ; Si CF=0 (échec), recommence
    
    ; Calcule random_value % (max + 1)
    xor edx, edx        ; Mise à zéro de edx pour la division
    movzx eax, ax       ; Étend ax (16 bits) à eax (32 bits)
    div ebx             ; edx:eax / ebx, reste dans edx
    mov eax, edx        ; Retourne le reste (valeur entre 0 et max)
    
    pop rbx
    ret

;##################################################
;########### FONCTION GENERER_TRIANGLES ###########
;##################################################
; Génère les coordonnées aléatoires de NBTRI triangles

generer_triangles:
    push rbp
    mov rbp, rsp
    push r12        ; compteur
    push r13        ; adresse de base
    
    xor r12, r12    ; compteur de triangles = 0
    
.loop_triangles:
    cmp r12, NBTRI
    jge .fin        ; Si r12 >= NBTRI on arrête
    
    ; === Génère x1 pour le triangle r12 ===
    mov edi, LARGEUR - 1
    call random_range
    mov r13, triangles_x1
    mov rcx, r12
    shl rcx, 2
    add r13, rcx
    mov [r13], eax
    
    ; === Génère y1 pour le triangle r12 ===
    mov edi, HAUTEUR - 1
    call random_range
    mov r13, triangles_y1
    mov rcx, r12
    shl rcx, 2
    add r13, rcx
    mov [r13], eax
    
    ; === Génère x2 pour le triangle r12 ===
    mov edi, LARGEUR - 1
    call random_range
    mov r13, triangles_x2
    mov rcx, r12
    shl rcx, 2
    add r13, rcx
    mov [r13], eax
    
    ; === Génère y2 pour le triangle r12 ===
    mov edi, HAUTEUR - 1
    call random_range
    mov r13, triangles_y2
    mov rcx, r12
    shl rcx, 2
    add r13, rcx
    mov [r13], eax
    
    ; === Génère x3 pour le triangle r12 ===
    mov edi, LARGEUR - 1
    call random_range
    mov r13, triangles_x3
    mov rcx, r12
    shl rcx, 2
    add r13, rcx
    mov [r13], eax
    
    ; === Génère y3 pour le triangle r12 ===
    mov edi, HAUTEUR - 1
    call random_range
    mov r13, triangles_y3
    mov rcx, r12
    shl rcx, 2
    add r13, rcx
    mov [r13], eax
    
    inc r12
    jmp .loop_triangles
    
.fin:
    pop r13
    pop r12
    pop rbp
    ret

;##################################################
;########### FONCTION CALCULER_ORIENTATION ########
;##################################################
; Calcule l'orientation de 3 points (A, B, C)
; Paramètres : 
;   EDI = Ax, ESI = Ay, EDX = Bx, ECX = By, R8D = Cx, R9D = Cy
; Retourne dans EAX : 
;   > 0 si sens direct (antihoraire)
;   < 0 si sens indirect (horaire)
;   = 0 si points alignés
; Formule : (Bx-Ax)*(Cy-Ay) - (By-Ay)*(Cx-Ax)

calculer_orientation:
    ; Calcule (Bx - Ax)
    sub edx, edi        ; edx = Bx - Ax
    
    ; Calcule (By - Ay)
    sub ecx, esi        ; ecx = By - Ay
    
    ; Calcule (Cx - Ax)
    sub r8d, edi        ; r8d = Cx - Ax
    
    ; Calcule (Cy - Ay)
    sub r9d, esi        ; r9d = Cy - Ay
    
    ; Calcule (Bx-Ax) * (Cy-Ay)
    movsx rdx, edx   
    movsx rbx, r9d
    imul rdx, rbx
    
    ; Calcule (By-Ay) * (Cx-Ax)
    movsx rsi, ecx
    movsx rcx, r8d
    imul rcx, rsi
    
    ; Calcule le résultat final : (Bx-Ax)*(Cy-Ay) - (By-Ay)*(Cx-Ax)
    sub rdx, rcx
    mov eax, edx        ; Résultat dans eax
    
    ret

;##################################################
;########### FONCTION REMPLIR_TRIANGLE_I ##########
;##################################################
; Remplit le triangle d'indice i
; Paramètre : R12D = indice du triangle (i)

remplir_triangle_i:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    
    ; Sauvegarde r12
    mov [rbp-44], r12d
    
    ; === Charge les coordonnées du triangle i ===
    ; x1[i]
    mov rbx, triangles_x1
    mov ecx, r12d
    shl ecx, 2
    add rbx, rcx
    mov eax, [rbx]
    mov [rbp-24], eax   ; x1 stocké
    
    ; y1[i]
    mov rbx, triangles_y1
    mov ecx, r12d
    shl ecx, 2
    add rbx, rcx
    mov eax, [rbx]
    mov [rbp-28], eax   ; y1 stocké
    
    ; x2[i]
    mov rbx, triangles_x2
    mov ecx, r12d
    shl ecx, 2
    add rbx, rcx
    mov eax, [rbx]
    mov [rbp-32], eax   ; x2 stocké
    
    ; y2[i]
    mov rbx, triangles_y2
    mov ecx, r12d
    shl ecx, 2
    add rbx, rcx
    mov eax, [rbx]
    mov [rbp-36], eax   ; y2 stocké
    
    ; x3[i]
    mov rbx, triangles_x3
    mov ecx, r12d
    shl ecx, 2
    add rbx, rcx
    mov eax, [rbx]
    mov [rbp-40], eax   ; x3 stocké
    
    ; y3[i]
    mov rbx, triangles_y3
    mov ecx, r12d
    shl ecx, 2
    add rbx, rcx
    mov eax, [rbx]
    mov [rbp-48], eax   ; y3 stocké
    
    ; === Calcule xmin, xmax, ymin, ymax ===
    
    ; ymin = min(y1, y2, y3)
    mov eax, [rbp-28]   ; y1
    mov ebx, [rbp-36]   ; y2
    mov ecx, [rbp-48]   ; y3
    cmp eax, ebx
    jle .y1_le_y2_min
    xor eax, ebx
    xor ebx, eax
    xor eax, ebx
.y1_le_y2_min:
    cmp eax, ecx
    jle .ymin_ok
    xor eax, ecx
    xor ecx, eax
    xor eax, ecx
.ymin_ok:
    mov [rbp-4], eax    ; ymin
    
    ; ymax = max(y1, y2, y3)
    mov eax, [rbp-28]   ; y1
    mov ebx, [rbp-36]   ; y2
    mov ecx, [rbp-48]   ; y3
    cmp eax, ebx
    jge .y1_ge_y2_max
    xor eax, ebx
    xor ebx, eax
    xor eax, ebx
.y1_ge_y2_max:
    cmp eax, ecx
    jge .ymax_ok
    xor eax, ecx
    xor ecx, eax
    xor eax, ecx
.ymax_ok:
    mov [rbp-8], eax    ; ymax
    
    ; xmin = min(x1, x2, x3)
    mov eax, [rbp-24]   ; x1
    mov ebx, [rbp-32]   ; x2
    mov ecx, [rbp-40]   ; x3
    cmp eax, ebx
    jle .x1_le_x2_min
    xor eax, ebx
    xor ebx, eax
    xor eax, ebx
.x1_le_x2_min:
    cmp eax, ecx
    jle .xmin_ok
    xor eax, ecx
    xor ecx, eax
    xor eax, ecx
.xmin_ok:
    mov [rbp-12], eax   ; xmin
    
    ; xmax = max(x1, x2, x3)
    mov eax, [rbp-24]   ; x1
    mov ebx, [rbp-32]   ; x2
    mov ecx, [rbp-40]   ; x3
    cmp eax, ebx
    jge .x1_ge_x2_max
    xor eax, ebx
    xor ebx, eax
    xor eax, ebx
.x1_ge_x2_max:
    cmp eax, ecx
    jge .xmax_ok
    xor eax, ecx
    xor ecx, eax
    xor eax, ecx
.xmax_ok:
    mov [rbp-16], eax   ; xmax
    
    ; === Boucle sur chaque pixel ===
.loop_y:
    mov eax, [rbp-4]    ; y actuel (commence à ymin)
    cmp eax, [rbp-8]    ; compare à ymax
    jg .fin
    
    mov [rbp-20], eax   ; Sauvegarde y actuel
    mov ebx, [rbp-12]   ; x = xmin
    
.loop_x:
    cmp ebx, [rbp-16]   ; compare x à xmax
    jg .next_y
    
    ; === Teste si le point (ebx, [rbp-20]) est dans le triangle ===
    
    ; Orientation 1 : (x1,y1), (x2,y2), (px,py)
    mov edi, [rbp-24]   ; x1
    mov esi, [rbp-28]   ; y1
    mov edx, [rbp-32]   ; x2
    mov ecx, [rbp-36]   ; y2
    mov r8d, ebx        ; px
    mov r9d, [rbp-20]   ; py
    push rbx
    push rax
    call calculer_orientation
    mov r10d, eax       ; Sauvegarde orientation1
    pop rax
    pop rbx
    
    ; Orientation 2 : (x2,y2), (x3,y3), (px,py)
    mov edi, [rbp-32]   ; x2
    mov esi, [rbp-36]   ; y2
    mov edx, [rbp-40]   ; x3
    mov ecx, [rbp-48]   ; y3
    mov r8d, ebx        ; px
    mov r9d, [rbp-20]   ; py
    push rbx
    push rax
    call calculer_orientation
    mov r11d, eax       ; Sauvegarde orientation2
    pop rax
    pop rbx
    
    ; Vérifie que orientation1 et orientation2 ont le même signe
    test r10d, r10d
    js .orient1_negatif
    test r11d, r11d
    js .next_x
    jmp .check_orient3
.orient1_negatif:
    test r11d, r11d
    jns .next_x
    
.check_orient3:
    ; Orientation 3 : (x3,y3), (x1,y1), (px,py)
    mov edi, [rbp-40]   ; x3
    mov esi, [rbp-48]   ; y3
    mov edx, [rbp-24]   ; x1
    mov ecx, [rbp-28]   ; y1
    mov r8d, ebx        ; px
    mov r9d, [rbp-20]   ; py
    push rbx
    push rax
    call calculer_orientation
    mov r10d, eax
    pop rax
    pop rbx
    
    ; Vérifie le signe avec orientation2
    test r11d, r11d
    js .orient2_negatif
    test r10d, r10d
    js .next_x
    jmp .dessiner_point
.orient2_negatif:
    test r10d, r10d
    jns .next_x
    
.dessiner_point:
    ; Dessine le point (ebx, [rbp-20])
    push rbx
    push rax
    mov rdi, qword[display_name]
    mov rsi, qword[window]
    mov rdx, qword[gc]
    mov ecx, ebx
    mov r8d, [rbp-20]
    call XDrawPoint
    pop rax
    pop rbx
    
.next_x:
    inc ebx
    jmp .loop_x
    
.next_y:
    inc dword[rbp-4]    ; ymin++
    jmp .loop_y
    
.fin:
    add rsp, 48
    pop rbp
    ret

;##################################################
;########### FONCTION DESSINER_CONTOURS_I #########
;##################################################
; Dessine les contours du triangle d'indice i
; Paramètre : R12D = indice du triangle (i)

dessiner_contours_triangle_i:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Sauvegarde r12
    mov [rbp-4], r12d
    
    ; === Charge les coordonnées du triangle i ===
    ; x1[i]
    mov rbx, triangles_x1
    mov ecx, r12d
    shl ecx, 2
    add rbx, rcx
    mov eax, [rbx]
    mov [rbp-8], eax
    
    ; y1[i]
    mov rbx, triangles_y1
    mov ecx, r12d
    shl ecx, 2
    add rbx, rcx
    mov eax, [rbx]
    mov [rbp-12], eax
    
    ; x2[i]
    mov rbx, triangles_x2
    mov ecx, r12d
    shl ecx, 2
    add rbx, rcx
    mov eax, [rbx]
    mov [rbp-16], eax
    
    ; y2[i]
    mov rbx, triangles_y2
    mov ecx, r12d
    shl ecx, 2
    add rbx, rcx
    mov eax, [rbx]
    mov [rbp-20], eax
    
    ; x3[i]
    mov rbx, triangles_x3
    mov ecx, r12d
    shl ecx, 2
    add rbx, rcx
    mov eax, [rbx]
    mov [rbp-24], eax
    
    ; y3[i]
    mov rbx, triangles_y3
    mov ecx, r12d
    shl ecx, 2
    add rbx, rcx
    mov eax, [rbx]
    mov [rbp-28], eax
    
    ; === Dessine le côté 1 : (x1,y1) -> (x2,y2) ===
    mov rdi, qword[display_name]
    mov rsi, qword[window]
    mov rdx, qword[gc]
    mov ecx, [rbp-8]    ; x1
    mov r8d, [rbp-12]   ; y1
    mov r9d, [rbp-16]   ; x2
    push qword[rbp-20]  ; y2
    call XDrawLine
    add rsp, 8
    
    ; === Dessine le côté 2 : (x2,y2) -> (x3,y3) ===
    mov rdi, qword[display_name]
    mov rsi, qword[window]
    mov rdx, qword[gc]
    mov ecx, [rbp-16]   ; x2
    mov r8d, [rbp-20]   ; y2
    mov r9d, [rbp-24]   ; x3
    push qword[rbp-28]  ; y3
    call XDrawLine
    add rsp, 8
    
    ; === Dessine le côté 3 : (x3,y3) -> (x1,y1) ===
    mov rdi, qword[display_name]
    mov rsi, qword[window]
    mov rdx, qword[gc]
    mov ecx, [rbp-24]   ; x3
    mov r8d, [rbp-28]   ; y3
    mov r9d, [rbp-8]    ; x1
    push qword[rbp-12]  ; y1
    call XDrawLine
    add rsp, 8
    
    add rsp, 32
    pop rbp
    ret

;##################################################
;########### FONCTION DESSINER_TRIANGLES ##########
;##################################################
; Dessine tous les triangles avec leurs couleurs

dessiner_triangles:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    push r14
    push r15
    
    xor r12, r12        ; compteur
    
.loop_triangles:
    cmp r12, NBTRI
    jge .fin
    
    ; === Calcule l'index de couleur : i % 6 ===
    mov rax, r12        ; rax = i
    xor rdx, rdx        ; rdx = 0 (pour la division)
    mov rcx, 6          ; nombre de couleurs
    div rcx             ; rax = i / 6, rdx = i % 6
    mov r15, rdx        ; r15 = index de couleur (i % 6)
    
    ; === Charge la couleur[i % 6] ===
    mov r13, couleurs
    shl r15, 2          ; r15 = r15 * 4 (taille d'un dword)
    add r13, r15
    mov r14d, [r13]     ; r14d = couleur[i % 6]
    
    ; === change la couleur ===
    mov rdi, qword[display_name]
    mov rsi, qword[gc]
    mov edx, r14d
    call XSetForeground
    
    ; === Remplit le triangle i ===
    call remplir_triangle_i
    
    ; === Change la couleur de contour ===
    mov rdi, qword[display_name]
    mov rsi, qword[gc]
    mov edx, 0x000000   ; Noir
    call XSetForeground
    
    ; === Dessine les contours du triangle i ===
    call dessiner_contours_triangle_i
    
    inc r12
    jmp .loop_triangles
    
.fin:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

;##################################################
;########### PROGRAMME PRINCIPAL ##################
;##################################################

main:
 ; Sauvegarde du registre de base pour préparer les appels à printf
    push    rbp
    mov     rbp, rsp
	
    ; Récupère le nom du display par défaut (en passant NULL)
    xor     rdi, rdi          ; rdi = 0 (NULL)
    call    XDisplayName      ; Appel de la fonction XDisplayName
    ; Vérifie si le display est valide
    test    rax, rax          ; Teste si rax est NULL
    jz      closeDisplay      ; Si NULL, ferme le display et quitte

    ; Ouvre le display par défaut
    xor     rdi, rdi          ; rdi = 0 (NULL pour le display par défaut)
    call    XOpenDisplay      ; Appel de XOpenDisplay
    test    rax, rax          ; Vérifie si l'ouverture a réussi
    jz      closeDisplay      ; Si échec, ferme le display et quitte

    ; Stocke le display ouvert dans la variable globale display_name
    mov     [display_name], rax

    ; Récupère la fenêtre racine (root window) du display
    mov     rdi,qword[display_name]   ; Place le display dans rdi
    mov     esi,dword[screen]         ; Place le numéro d'écran dans esi
    call XRootWindow                ; Appel de XRootWindow pour obtenir la fenêtre racine
    mov     rbx,rax               ; Stocke la root window dans rbx

    ; Création d'une fenêtre simple
    mov     rdi,qword[display_name]   ; display
    mov     rsi,rbx                   ; parent = root window
    mov     rdx,10                    ; position x de la fenêtre
    mov     rcx,10                    ; position y de la fenêtre
    mov     r8,LARGEUR                ; largeur de la fenêtre
    mov     r9,HAUTEUR           	; hauteur de la fenêtre
    push 0xFFFFFF               ; couleur du fond (noir, 0x000000)
    push 0x00FF00                     ; couleur de fond (vert, 0x00FF00)
    push 1                          ; épaisseur du bord
    call XCreateSimpleWindow        ; Appel de XCreateSimpleWindow
	add rsp,24
	mov qword[window],rax           ; Stocke l'identifiant de la fenêtre créée dans window

    ; Sélection des événements à écouter sur la fenêtre
    mov rdi,qword[display_name]
    mov rsi,qword[window]
    mov rdx,131077                 ; Masque d'événements (ex. StructureNotifyMask + autres)
    call XSelectInput

    ; Affichage (mapping) de la fenêtre
    mov rdi,qword[display_name]
    mov rsi,qword[window]
    call XMapWindow

    ; Création du contexte graphique (GC) avec vérification d'erreur
    mov rdi, qword[display_name]
    test rdi, rdi                ; Vérifie que display n'est pas NULL
    jz closeDisplay

    mov rsi, qword[window]
    test rsi, rsi                ; Vérifie que window n'est pas NULL
    jz closeDisplay

    xor rdx, rdx                 ; Aucun masque particulier
    xor rcx, rcx                 ; Aucune valeur particulière
    call XCreateGC               ; Appel de XCreateGC pour créer le contexte graphique
    test rax, rax                ; Vérifie la création du GC
    jz closeDisplay              ; Si échec, quitte
    mov qword[gc], rax           ; Stocke le GC dans la variable gc
	
boucle: ; Boucle de gestion des événements
    mov     rdi, qword[display_name]
    cmp     rdi, 0              ; Vérifie que le display est toujours valide
    je      closeDisplay        ; Si non, quitte
    mov     rsi, event          ; Passe l'adresse de la structure d'événement
    call    XNextEvent          ; Attend et récupère le prochain événement

    cmp     dword[event], ConfigureNotify ; Si l'événement est ConfigureNotify (ex: redimensionnement)
    je      dessin                        ; Passe à la phase de dessin

    cmp     dword[event], KeyPress        ; Si une touche est pressée
    je      closeDisplay                  ; Quitte le programme
    jmp     boucle                        ; Sinon, recommence la boucle

;#########################################
;#		DEBUT DE LA ZONE DE DESSIN		 #
;#########################################
dessin:
    ; Vérifie si les triangles ont déjà été générés
    cmp dword[triangles_generes], 0
    jne .deja_genere
    
    ; Génère les coordonnées des triangles (une seule fois)
    call generer_triangles
    mov dword[triangles_generes], 1
    
.deja_genere:
    ; Dessine tous les triangles (à chaque fois)
    call dessiner_triangles

flush:
    mov rdi,qword[display_name]
    call XFlush
    jmp boucle
    mov rax,34
    syscall

closeDisplay:
    mov     rax,qword[display_name]
    mov     rdi,rax
    call    XCloseDisplay
    xor	    rdi,rdi
    call    exit
