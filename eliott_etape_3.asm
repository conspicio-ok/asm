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
%define NBTRI	3
%define BYTE	1
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

; ==========================
; = ANCIEN SYSTÈME (1 triangle) =
; ==========================
; On garde ces variables pour que le code actuel fonctionne
triangle_x1:	dd	0
triangle_y1:	dd	0
triangle_x2:	dd	0
triangle_y2:	dd	0
triangle_x3:	dd	0
triangle_y3:	dd	0
triangle_genere:	dd	0

; ==========================
; = NOUVEAU SYSTÈME (N triangles) =
; ==========================
; On ajoute les nouveaux tableaux pour l'étape 3

; Coordonnées des triangles (tableau de NBTRI éléments)
triangles_x1:	times NBTRI dd 0
triangles_y1:	times NBTRI dd 0
triangles_x2:	times NBTRI dd 0
triangles_y2:	times NBTRI dd 0
triangles_x3:	times NBTRI dd 0
triangles_y3:	times NBTRI dd 0

triangles_generes:	dd	0

; ============
; = COULEURS =
; ============
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
;########### FONCTION GENERER_TRIANGLE ############
;##################################################
; Génère les coordonnées aléatoires du triangle

generer_triangle:
    push rbp
    mov rbp, rsp
    
    ; Génère x1
    mov edi, LARGEUR - 1
    call random_range
    mov [triangle_x1], eax
    
    ; Génère y1
    mov edi, HAUTEUR - 1
    call random_range
    mov [triangle_y1], eax
    
    ; Génère x2
    mov edi, LARGEUR - 1
    call random_range
    mov [triangle_x2], eax
    
    ; Génère y2
    mov edi, HAUTEUR - 1
    call random_range
    mov [triangle_y2], eax
    
    ; Génère x3
    mov edi, LARGEUR - 1
    call random_range
    mov [triangle_x3], eax
    
    ; Génère y3
    mov edi, HAUTEUR - 1
    call random_range
    mov [triangle_y3], eax
    
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
;########### FONCTION REMPLIR_TRIANGLE ############
;##################################################
; Remplit le triangle pixel par pixel en testant l'orientation
; Pour chaque pixel, teste s'il est à l'intérieur du triangle
; en vérifiant que l'orientation est cohérente pour les 3 côtés

remplir_triangle:
    push rbp     ; Sauvegarde l'ancien RBP
    mov rbp, rsp ; RBP pointe maintenant sur le sommet de la pile
    sub rsp, 16  ; Espace local

;   [ancien RBP]     ← RBP pointe ici
;   [espace libre]   ← RBP-4  (ymin)
;   [espace libre]   ← RBP-8  (ymax)
;   [espace libre]   ← RBP-12 (xmin)
;   [espace libre]   ← RBP-16 (xmax) ← RSP pointe ici
    
    ; Détermine ymin et ymax du triangle
    mov eax, dword[triangle_y1]
    mov ebx, dword[triangle_y2]
    mov ecx, dword[triangle_y3]
    
    ; ymin = min(y1, y2, y3)
    cmp eax, ebx
    jle .y1_le_y2
    xor eax, ebx
    xor ebx, eax
    xor eax, ebx
.y1_le_y2:
    cmp eax, ecx
    jle .min_y_ok
    xor eax, ecx
    xor ecx, eax
    xor eax, ecx
.min_y_ok:
    mov [rbp-4], eax  ; ymin
    
    ; ymax = max(y1, y2, y3)
    mov eax, dword[triangle_y1]
    mov ebx, dword[triangle_y2]
    mov ecx, dword[triangle_y3]
    cmp eax, ebx
    jge .y1_ge_y2
    xor eax, ebx
    xor ebx, eax
    xor eax, ebx
.y1_ge_y2:
    cmp eax, ecx
    jge .max_y_ok
    xor eax, ecx
    xor ecx, eax
    xor eax, ecx
.max_y_ok:
    mov [rbp-8], eax  ; ymax
    
    ; Détermine xmin et xmax du triangle
    mov eax, dword[triangle_x1]
    mov ebx, dword[triangle_x2]
    mov ecx, dword[triangle_x3]
    
    ; xmin = min(x1, x2, x3)
    cmp eax, ebx
    jle .x1_le_y2
    xor eax, ebx
    xor ebx, eax
    xor eax, ebx
.x1_le_y2:
    cmp eax, ecx
    jle .min_x_ok
    xor eax, ecx
    xor ecx, eax
    xor eax, ecx
.min_x_ok:
    mov [rbp-12], eax  ; xmin
    
    ; xmax = max(x1, x2, x3)
    mov eax, dword[triangle_x1]
    mov ebx, dword[triangle_x2]
    mov ecx, dword[triangle_x3]
    cmp eax, ebx
    jge .x1_ge_y2
    xor eax, ebx
    xor ebx, eax
    xor eax, ebx
.x1_ge_y2:
    cmp eax, ecx
    jge .max_x_ok
    xor eax, ecx
    xor ecx, eax
    xor eax, ecx
.max_x_ok:
    mov [rbp-16], eax  ; xmax
    
    ; Boucle sur chaque ligne y
.loop_y:
    mov eax, [rbp-4]
    cmp eax, [rbp-8]
    jg .fin
    
    ; Boucle sur chaque pixel x de la ligne
    mov ebx, [rbp-12]  ; x = xmin
    
.loop_x:
    cmp ebx, [rbp-16]
    jg .next_y
    
    ; Teste si le point (ebx, eax) est dans le triangle
    ; On calcule les 3 orientations et vérifie qu'elles ont le même signe
    ; Orientation 1 : (x1,y1), (x2,y2), (px,py)
    push rax
    push rbx
    mov edi, dword[triangle_x1]
    mov esi, dword[triangle_y1]
    mov edx, dword[triangle_x2]
    mov ecx, dword[triangle_y2]
    mov r8d, ebx  ; px
    mov r9d, eax  ; py
    call calculer_orientation
    mov r10d, eax  ; Sauvegarde orientation1
    pop rbx
    pop rax
    
    ; Orientation 2 : (x2,y2), (x3,y3), (px,py)
    push rax
    push rbx
    mov edi, dword[triangle_x2]
    mov esi, dword[triangle_y2]
    mov edx, dword[triangle_x3]
    mov ecx, dword[triangle_y3]
    mov r8d, ebx  ; px
    mov r9d, eax  ; py
    call calculer_orientation
    mov r11d, eax  ; Sauvegarde orientation2
    pop rbx
    pop rax
    
    ; Vérifie que orientation1 et orientation2 ont le même signe
    test r10d, r10d
    js .orient1_negatif
    ; orient1 positif
    test r11d, r11d
    js .next_x  ; orient1 positif, orient2 négatif -> hors triangle
    jmp .check_orient3
.orient1_negatif:
    ; orient1 négatif
    test r11d, r11d
    jns .next_x  ; orient1 négatif, orient2 positif -> hors triangle
    
.check_orient3:
    ; Orientation 3 : (x3,y3), (x1,y1), (px,py)
    push rax
    push rbx
    mov edi, dword[triangle_x3]
    mov esi, dword[triangle_y3]
    mov edx, dword[triangle_x1]
    mov ecx, dword[triangle_y1]
    mov r8d, ebx  ; px
    mov r9d, eax  ; py
    call calculer_orientation
    mov r10d, eax  ; Sauvegarde orientation3
    pop rbx
    pop rax
    
    ; Vérifie que orientation3 a le même signe que orientation2
    test r11d, r11d
    js .orient2_negatif
    ; orient2 positif
    test r10d, r10d
    js .next_x  ; orient2 positif, orient3 négatif -> hors triangle
    jmp .dessiner_point
.orient2_negatif:
    ; orient2 négatif
    test r10d, r10d
    jns .next_x  ; orient2 négatif, orient3 positif -> hors triangle
    
.dessiner_point:
    ; Si on arrive ici, le point est dans le triangle, on le dessine
    push rax
    push rbx
    mov rdi, qword[display_name]
    mov rsi, qword[window]
    mov rdx, qword[gc]
    mov ecx, ebx  ; x
    mov r8d, eax  ; y
    call XDrawPoint
    pop rbx
    pop rax
    
.next_x:
    inc ebx
    jmp .loop_x
    
.next_y:
    inc dword[rbp-4]
    jmp .loop_y
    
.fin:
    add rsp, 16 ; Libère les 16 octets réservés
    pop rbp     ; Restaure l'ancien RBP
    ret         ; Retour

;##################################################
;########### FONCTION DESSINER_TRIANGLE ###########
;##################################################
dessiner_triangle:
    push rbp
    mov rbp, rsp
    
    ; Remplit le triangle en noir
    mov rdi, qword[display_name]
    mov rsi, qword[gc]
    mov edx, 0xFFFFFF  ; Blanc
    call XSetForeground
    
    call remplir_triangle
    
    ; Change la couleur pour les contours en rouge
    mov rdi, qword[display_name]
    mov rsi, qword[gc]
    mov edx, 0xFF0000  ; Rouge
    call XSetForeground
    
    ; Dessine le côté 1 : (x1,y1) -> (x2,y2)
    mov rdi, qword[display_name]
    mov rsi, qword[window]
    mov rdx, qword[gc]
    mov ecx, dword[triangle_x1]
    mov r8d, dword[triangle_y1]
    mov r9d, dword[triangle_x2]
    mov r14d, dword[triangle_y2]
    push r14
    call XDrawLine
    add rsp, 8
    
    ; Dessine le côté 2 : (x2,y2) -> (x3,y3)
    mov rdi, qword[display_name]
    mov rsi, qword[window]
    mov rdx, qword[gc]
    mov ecx, dword[triangle_x2]
    mov r8d, dword[triangle_y2]
    mov r9d, dword[triangle_x3]
    mov r14d, dword[triangle_y3]
    push r14
    call XDrawLine
    add rsp, 8
    
    ; Dessine le côté 3 : (x3,y3) -> (x1,y1)
    mov rdi, qword[display_name]
    mov rsi, qword[window]
    mov rdx, qword[gc]
    mov ecx, dword[triangle_x3]
    mov r8d, dword[triangle_y3]
    mov r9d, dword[triangle_x1]
    mov r14d, dword[triangle_y1]
    push r14
    call XDrawLine
    add rsp, 8
    
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
    push 0x000000                     ; couleur du fond (noir, 0x000000)
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
    ; Vérifie si le triangle a déjà été généré
    cmp dword[triangle_genere], 0
    jne .deja_genere
    
    ; Génère les coordonnées du triangle (une seule fois)
    call generer_triangle
    mov dword[triangle_genere], 1
    
.deja_genere:
    ; Dessine le triangle (à chaque fois)
    call dessiner_triangle

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
