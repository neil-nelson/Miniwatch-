#!/bin/bash

if [ -z "$1" ]; then
   Fichier="donnees/application.log"
else
   Fichier="$1"
fi

if [ ! -f "$Fichier" ]; then
    echo "Erreur: Le fichier $Fichier n'existe pas." >&2
    exit 1
fi

VALIDES=$(awk -F'|' 'NF == 4' "$Fichier")
MAL_FORMEES=$(awk -F'|' 'NF != 4' "$Fichier" | wc -l)


ERREURS=$(echo "$VALIDES" | awk -F'|' '$2 == "ERROR"')
NB_ERREURS=$(echo "$ERREURS" | grep -c 'ERROR')

echo "== Lignes par niveau =="
echo "$VALIDES" | cut -d'|' -f2 | sort | uniq -c
echo "Lignes mal formées : $MAL_FORMEES"

echo "== Erreurs par service =="
echo "$ERREURS" | cut -d'|' -f3 | sort | uniq -c | sort -rn
echo "== 5 erreurs les plus récentes =="
echo "$ERREURS" | sort | tail -n 5
echo "== Services en erreur =="
echo "$ERREURS" | cut -d'|' -f3 | sort -u

if [ "$NB_ERREURS" -gt 5 ]; then
    echo "ALERTE : $NB_ERREURS erreurs (plus de 5)"
fi
