# Projet Assembleur x86-64

## Compilation et exécution

### Tout compiler
```bash
make
```

### Mathieu - Triangle rempli avec X11 (mathieu_etape_2.asm)
Génère et dessine un triangle aléatoire rempli avec contours rouges.

```bash
make mathieu        # Compile
make run-mathieu    # Compile et exécute
```

### Raphael - Calcul d'orientation (diondi.asm)
Calcule l'orientation d'un triangle (direct/indirect).

```bash
make raphael        # Compile
make run-raphael    # Compile et exécute
```

### Nettoyage
```bash
make clean
```

---

## Notes sur le code diondi.asm

### .data

variable du sujet

### .text

obligatoire mais je sais pas pourquoi sinon segmentation fault

### main

#### 15 - 18, 21 - 22

recuperation des var pour les points

#### 19 - 20, 23 - 31

Commande vu en cours pour effectuer :
(𝒙𝑩𝑨 × 𝒚𝑩𝑪) − (𝒙𝑩𝑪 × 𝒚𝑩𝑨)
Soit le calcule qui defini si le triangle ABC est direct ou indirect

/!\ Resultat stocker dans dx ! /!\
- Si dx >= 0 : indirect
- Si dx < 0 : direct

#### 33 - fin

printf pour verifier le resultat, inutile au code, exit propre vu en cours, etc
